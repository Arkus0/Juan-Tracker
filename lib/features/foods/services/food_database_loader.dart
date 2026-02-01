import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_provider.dart';
import '../../../training/database/database.dart';

/// Servicio para cargar la base de datos de alimentos desde el asset comprimido
/// 
/// Optimizaciones implementadas:
/// 1. Parseo en Isolate (no bloquea UI)
/// 2. Batches grandes (5000 registros)
/// 3. Inserción sin verificación de duplicados (más rápido)
/// 4. Una sola transacción por batch
/// 5. Descompresión en memoria eficiente
class FoodDatabaseLoader {
  static const String _assetPath = 'assets/data/foods.jsonl.gz';
  static const String _dbVersionKey = 'food_db_version';
  static const int _currentDbVersion = 1;
  static const int _batchSize = 5000; // Aumentado de 1000 a 5000

  final AppDatabase _db;
  
  FoodDatabaseLoader(this._db);

  /// Verifica si la base de datos de alimentos ya está cargada
  Future<bool> isDatabaseLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_dbVersionKey);
    
    if (version != _currentDbVersion) {
      return false;
    }
    
    // Verificar si hay alimentos en la base (muestra rápida)
    final count = await _db.customSelect(
      'SELECT COUNT(*) as count FROM foods WHERE user_created = 0 LIMIT 1'
    ).getSingle();
    
    final hasFoods = (count.data['count'] as int) > 10000;
    
    // Verificar integridad: si hay alimentos pero el índice FTS está vacío o no existe
    if (hasFoods) {
      try {
        final ftsCount = await _db.customSelect(
          'SELECT COUNT(*) as count FROM foods_fts LIMIT 1'
        ).getSingle();
        if ((ftsCount.data['count'] as int) == 0) {
          // El índice FTS está vacío, necesita reconstrucción
          return false;
        }
      } catch (e) {
        // La tabla foods_fts no existe o está corrupta
        debugPrint('FTS table check failed: $e');
        return false;
      }
    }
    
    return hasFoods;
  }

  /// Reconstruye solo el índice FTS5 (útil cuando la base de datos ya está cargada pero el índice está corrupto)
  Future<void> rebuildIndexOnly({void Function(double progress)? onProgress}) async {
    onProgress?.call(0.0);
    await _db.rebuildFtsIndex();
    onProgress?.call(1.0);
    await _markDatabaseAsLoaded();
  }

  /// Carga la base de datos desde el asset de forma optimizada
  /// 
  /// Retorna el número de alimentos cargados
  Future<int> loadDatabase({void Function(double progress, int loaded)? onProgress}) async {
    try {
      // Verificar si la base de datos ya está cargada pero el índice necesita reconstrucción
      final foodsCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM foods WHERE user_created = 0 LIMIT 1'
      ).getSingle();
      final hasFoods = (foodsCount.data['count'] as int) > 10000;
      
      final ftsCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM foods_fts LIMIT 1'
      ).getSingle();
      final hasFts = (ftsCount.data['count'] as int) > 0;
      
      if (hasFoods && !hasFts) {
        // La base de datos está cargada pero el índice FTS está vacío
        // Solo reconstruir el índice sin recargar todo
        onProgress?.call(0.5, foodsCount.data['count'] as int);
        await rebuildIndexOnly(onProgress: (p) => onProgress?.call(0.5 + p * 0.5, foodsCount.data['count'] as int));
        return foodsCount.data['count'] as int;
      }
      
      // 1. Cargar y descomprimir en isolate
      onProgress?.call(0.0, 0);
      
      final byteData = await rootBundle.load(_assetPath);
      final bytes = byteData.buffer.asUint8List();
      
      // Descompresión en isolate para no bloquear UI
      final jsonlString = await compute(_decompressGzip, bytes);
      
      // 2. Parsear en isolate
      onProgress?.call(0.05, 0);
      
      final lines = await compute(_splitLines, jsonlString);
      final totalLines = lines.length;
      
      // 3. Procesar en batches grandes con isolates
      int loadedCount = 0;
      final totalBatches = (totalLines / _batchSize).ceil();
      
      for (var batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
        final start = batchIndex * _batchSize;
        final end = (start + _batchSize < totalLines) ? start + _batchSize : totalLines;
        final batchLines = lines.sublist(start, end);
        
        // Parsear batch en isolate
        final companions = await compute(_parseBatch, batchLines);
        
        // Insertar en DB (esto sí debe ser en el isolate principal por drift)
        await _insertBatchOptimized(companions);
        
        loadedCount += companions.length;
        
        // Reportar progreso
        final progress = 0.05 + (0.95 * loadedCount / totalLines);
        onProgress?.call(progress, loadedCount);
      }
      
      // 4. Reconstruir índice FTS5 para búsqueda
      onProgress?.call(0.98, loadedCount);
      await _db.rebuildFtsIndex();
      
      // 5. Marcar como cargada
      await _markDatabaseAsLoaded();
      
      return loadedCount;
    } catch (e) {
      throw Exception('Error cargando base de datos: $e');
    }
  }

  /// Parsea un batch de líneas JSONL en un isolate
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

  /// Descomprime GZIP en isolate
  static String _decompressGzip(Uint8List bytes) {
    final decodedBytes = gzip.decode(bytes);
    return utf8.decode(decodedBytes);
  }

  /// Separa líneas en isolate
  static List<String> _splitLines(String text) {
    return const LineSplitter().convert(text);
  }

  /// Inserta un batch de alimentos de forma optimizada (una sola transacción)
  Future<void> _insertBatchOptimized(List<FoodsCompanion> batch) async {
    await _db.transaction(() async {
      await _db.batch((b) {
        b.insertAll(
          _db.foods, 
          batch, 
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  /// Parsea un JSON de Open Food Facts a FoodsCompanion
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
  Future<void> _markDatabaseAsLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dbVersionKey, _currentDbVersion);
  }

  /// Limpia la base de datos de alimentos
  Future<void> clearDatabase() async {
    await _db.delete(_db.foods).go();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dbVersionKey);
  }

  /// Sanitiza el nombre del alimento
  static String _sanitizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Parsea un double de varios formatos posibles
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

/// Provider para verificar estado de carga
final foodDatabaseLoadedProvider = FutureProvider<bool>((ref) async {
  final loader = ref.watch(foodDatabaseLoaderProvider);
  return loader.isDatabaseLoaded();
});
