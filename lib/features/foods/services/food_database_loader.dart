import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/telemetry_service.dart';
import '../../../training/database/database.dart';
import '../providers/market_providers.dart';

/// Servicio para cargar la base de datos de alimentos desde el asset comprimido
///
/// Soporta múltiples mercados (España, USA, etc.)
/// Optimizaciones: Parseo en isolates, batches grandes, transacciones por batch
class FoodDatabaseLoader {
  static const String _dbVersionKey = 'food_db_version';
  static const int _currentDbVersion = 1;
  static const int _batchSize = 5000;

  final AppDatabase _db;

  FoodDatabaseLoader(this._db);

  /// Obtiene el path del asset según el mercado seleccionado
  String _getAssetPath(FoodMarket market) => 'assets/data/${market.filename}';

  /// Verifica si la base de datos del mercado está cargada
  Future<bool> isDatabaseLoaded(FoodMarket market) async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt('${_dbVersionKey}_${market.name}');

    if (savedVersion != _currentDbVersion) {
      return false;
    }

    // Verificar si hay alimentos de este mercado
    final count = await _db
        .customSelect(
          "SELECT COUNT(*) as count FROM foods WHERE user_created = 0 LIMIT 1",
        )
        .getSingle();

    return (count.data['count'] as int) > 10000;
  }

  /// Carga la base de datos desde el asset
  Future<int> loadDatabase({
    required FoodMarket market,
    void Function(double progress, int loaded)? onProgress,
  }) async {
    final assetPath = _getAssetPath(market);

    return TelemetryService()
        .measureAsync(MetricNames.dbLoadFoods, () async {
          onProgress?.call(0.0, 0);

          // Verificar que el asset existe
          final byteData = await rootBundle.load(assetPath);
          final bytes = byteData.buffer.asUint8List();

          // Descompresión en isolate
          final jsonlString = await compute(_decompressGzip, bytes);
          onProgress?.call(0.05, 0);

          // Separar líneas en isolate
          final lines = await compute(_splitLines, jsonlString);
          final totalLines = lines.length;

          // Procesar en batches
          int loadedCount = 0;
          final totalBatches = (totalLines / _batchSize).ceil();

          for (var batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
            final start = batchIndex * _batchSize;
            final end = (start + _batchSize < totalLines)
                ? start + _batchSize
                : totalLines;
            final batchLines = lines.sublist(start, end);

            // Parsear batch en isolate
            final companions = await compute(_parseBatch, batchLines);

            // Insertar en DB
            await _insertBatchOptimized(companions);

            loadedCount += companions.length;

            final progress = 0.05 + (0.95 * loadedCount / totalLines);
            onProgress?.call(progress, loadedCount);
          }

          // Reconstruir FTS al final garantiza búsquedas rápidas sin depender
          // de sincronización por registro durante cargas masivas.
          await _db.rebuildFtsIndex();

          // Marcar como cargada
          await _markDatabaseAsLoaded(market);

          return loadedCount;
        }, tags: {'market': market.name})
        .catchError((Object e) {
          throw Exception(
            'Error cargando base de datos para ${market.displayName}: $e',
          );
        });
  }

  /// Parsea un batch de líneas JSONL
  static List<FoodsCompanion> _parseBatch(List<String> lines) {
    final companions = <FoodsCompanion>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        final companion = _parseFoodCompanion(json);
        companions.add(companion);
      } catch (_) {
        // Ignorar líneas malformadas
      }
    }

    return companions;
  }

  /// Descomprime GZIP
  static String _decompressGzip(Uint8List bytes) {
    final decodedBytes = gzip.decode(bytes);
    return utf8.decode(decodedBytes);
  }

  /// Separa líneas
  static List<String> _splitLines(String text) {
    return const LineSplitter().convert(text);
  }

  /// Inserta un batch de alimentos
  Future<void> _insertBatchOptimized(List<FoodsCompanion> batch) async {
    await _db.transaction(() async {
      await _db.batch((b) {
        b.insertAll(_db.foods, batch, mode: InsertMode.insertOrReplace);
      });
    });
  }

  /// Parsea un JSON a FoodsCompanion
  static FoodsCompanion _parseFoodCompanion(Map<String, dynamic> json) {
    final nutriments = json['nutriments'] as Map<String, dynamic>? ?? {};

    return FoodsCompanion(
      id: Value(json['code'] as String? ?? const Uuid().v4()),
      name: Value(_sanitizeName(json['name'] as String? ?? 'Sin nombre')),
      brand: Value(json['brands'] as String?),
      kcalPer100g: Value(_parseDouble(nutriments['energy_kcal'])?.round() ?? 0),
      proteinPer100g: Value(_parseDouble(nutriments['proteins'])),
      carbsPer100g: Value(_parseDouble(nutriments['carbohydrates'])),
      fatPer100g: Value(_parseDouble(nutriments['fat'])),
      nutriScore: Value(json['nutriscore'] as String?),
      sourceMetadata: Value(json),
      userCreated: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
  }

  /// Marca la base de datos como cargada
  Future<void> _markDatabaseAsLoaded(FoodMarket market) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_dbVersionKey}_${market.name}', _currentDbVersion);
  }

  /// Limpia la base de datos
  Future<void> clearDatabase(FoodMarket market) async {
    // Solo limpiar catálogo importado. Los alimentos creados por usuario se preservan.
    await _db.customStatement('DELETE FROM foods WHERE user_created = 0');
    await _db.rebuildFtsIndex();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_dbVersionKey}_${market.name}');
  }

  /// Cambia de mercado (limpia DB anterior y carga nueva)
  Future<int> switchMarket({
    required FoodMarket from,
    required FoodMarket to,
    void Function(double progress, int loaded)? onProgress,
  }) async {
    // Limpiar mercado anterior
    await clearDatabase(from);

    // Cargar nuevo mercado
    return loadDatabase(market: to, onProgress: onProgress);
  }

  static String _sanitizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }
}

/// Provider para el loader
final foodDatabaseLoaderProvider = Provider<FoodDatabaseLoader>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FoodDatabaseLoader(db);
});

/// Provider para verificar estado de carga del mercado actual
final foodDatabaseLoadedProvider = FutureProvider<bool>((ref) async {
  final market = ref.watch(selectedMarketProvider);
  if (market == null) return false;

  final loader = ref.watch(foodDatabaseLoaderProvider);
  return loader.isDatabaseLoaded(market);
});
