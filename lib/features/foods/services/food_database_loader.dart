import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/providers/database_provider.dart';
import '../../../training/database/database.dart';

/// Servicio para cargar la base de datos de alimentos desde el asset comprimido
/// 
/// Proceso:
/// 1. Verifica si la base de datos ya está cargada
/// 2. Si no, descomprime el archivo .gz desde assets
/// 3. Parsea el JSONL línea por línea
/// 4. Inserta en Drift en batches para mejor rendimiento
class FoodDatabaseLoader {
  static const String _assetPath = 'assets/data/foods.jsonl.gz';
  static const String _dbVersionKey = 'food_db_version';
  static const int _currentDbVersion = 1; // Incrementar cuando se actualice la base
  static const int _batchSize = 1000; // Insertar en batches de 1000

  final AppDatabase _db;
  
  FoodDatabaseLoader(this._db);

  /// Verifica si la base de datos de alimentos ya está cargada
  Future<bool> isDatabaseLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_dbVersionKey);
    
    if (version != _currentDbVersion) {
      return false;
    }
    
    // Verificar si hay alimentos en la base
    final count = await _db.select(_db.foods).get();
    return count.isNotEmpty;
  }

  /// Carga la base de datos desde el asset
  /// 
  /// Retorna el número de alimentos cargados
  Future<int> loadDatabase({void Function(double progress)? onProgress}) async {
    try {
      // Cargar el archivo comprimido desde assets
      final byteData = await rootBundle.load(_assetPath);
      final bytes = byteData.buffer.asUint8List();
      
      // Descomprimir
      final decodedBytes = gzip.decode(bytes);
      final jsonlString = utf8.decode(decodedBytes);
      
      // Parsear línea por línea
      final lines = const LineSplitter().convert(jsonlString);
      final totalLines = lines.length;
      int loadedCount = 0;
      
      // Procesar en batches
      final batch = <FoodsCompanion>[];
      
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;
        
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final companion = _parseFoodCompanion(json);
          batch.add(companion);
          
          // Insertar batch cuando alcance el tamaño
          if (batch.length >= _batchSize) {
            await _insertBatch(batch);
            loadedCount += batch.length;
            batch.clear();
            
            // Reportar progreso
            onProgress?.call(loadedCount / totalLines);
          }
        } catch (e) {
          // Log error pero continuar con el siguiente
          print('Error parseando línea $i: $e');
        }
      }
      
      // Insertar batch final
      if (batch.isNotEmpty) {
        await _insertBatch(batch);
        loadedCount += batch.length;
      }
      
      // Marcar como cargada
      await _markDatabaseAsLoaded();
      
      return loadedCount;
    } catch (e) {
      throw Exception('Error cargando base de datos: $e');
    }
  }

  /// Parsea un JSON de Open Food Facts a FoodsCompanion
  FoodsCompanion _parseFoodCompanion(Map<String, dynamic> json) {
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

  /// Inserta un batch de alimentos
  Future<void> _insertBatch(List<FoodsCompanion> batch) async {
    await _db.batch((b) {
      b.insertAll(_db.foods, batch, mode: InsertMode.insertOrReplace);
    });
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
  String _sanitizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Parsea un double de varios formatos posibles
  double? _parseDouble(dynamic value) {
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
