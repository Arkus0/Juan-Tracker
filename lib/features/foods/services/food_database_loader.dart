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
/// 2. Batches dinámicos basados en memoria disponible
/// 3. Inserción sin verificación de duplicados (más rápido)
/// 4. Una sola transacción por batch
/// 5. Descompresión en memoria eficiente
class FoodDatabaseLoader {
  static const String _assetPath = 'assets/data/foods.jsonl.gz';
  static const String _dbVersionKey = 'food_db_version';
  static const int _currentDbVersion = 1;
  
  /// Batch size base - se ajusta dinámicamente según memoria disponible
  static const int _defaultBatchSize = 5000;
  static const int _minBatchSize = 1000;  // Para dispositivos low-end
  static const int _maxBatchSize = 8000;  // Para dispositivos high-end

  final AppDatabase _db;
  
  FoodDatabaseLoader(this._db);
  
  /// Calcula el batch size óptimo basado en la memoria disponible del dispositivo
  /// para evitar OOM en dispositivos con poca RAM
  int _calculateOptimalBatchSize() {
    try {
      // Obtener memoria disponible aproximada
      final memInfo = PlatformDispatcher.instance.views.first.devicePixelRatio;
      // Usar devicePixelRatio como proxy (no hay API directa de memoria en Dart)
      // En la práctica, dispositivos con pixel ratio más alto suelen tener más RAM
      
      if (memInfo >= 3.0) {
        return _maxBatchSize; // High-end devices
      } else if (memInfo >= 2.0) {
        return _defaultBatchSize; // Mid-range
      } else {
        return _minBatchSize; // Low-end devices
      }
    } catch (e) {
      // Fallback seguro
      return _defaultBatchSize;
    }
  }

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
      debugPrint('[FoodDatabaseLoader] Starting loadDatabase...');

      // Verificar si la base de datos ya está cargada pero el índice necesita reconstrucción
      final foodsCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM foods WHERE user_created = 0 LIMIT 1'
      ).getSingle();
      final hasFoods = (foodsCount.data['count'] as int) > 10000;
      debugPrint('[FoodDatabaseLoader] Current foods count: ${foodsCount.data['count']}, hasFoods: $hasFoods');
      
      final ftsCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM foods_fts LIMIT 1'
      ).getSingle();
      final hasFts = (ftsCount.data['count'] as int) > 0;
      debugPrint('[FoodDatabaseLoader] FTS count: ${ftsCount.data['count']}, hasFts: $hasFts');

      if (hasFoods && !hasFts) {
        // La base de datos está cargada pero el índice FTS está vacío
        // Solo reconstruir el índice sin recargar todo
        debugPrint('[FoodDatabaseLoader] Foods exist but FTS empty - rebuilding index only');
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
      
      // 3. Procesar en batches dinámicos según memoria disponible
      final batchSize = _calculateOptimalBatchSize();
      debugPrint('[FoodDatabaseLoader] Using batch size: $batchSize');
      
      int loadedCount = 0;
      final totalBatches = (totalLines / batchSize).ceil();
      
      for (var batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
        final start = batchIndex * batchSize;
        final end = (start + batchSize < totalLines) ? start + batchSize : totalLines;
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
      debugPrint('[FoodDatabaseLoader] Rebuilding FTS index after inserting $loadedCount foods...');
      onProgress?.call(0.98, loadedCount);
      await _db.rebuildFtsIndex();

      // Sanity checks after loading
      final finalFoodsCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM foods'
      ).getSingle();
      final finalFtsCount = await _db.customSelect(
        'SELECT COUNT(*) as count FROM foods_fts'
      ).getSingle();
      debugPrint('[FoodDatabaseLoader] ✅ Final foods count: ${finalFoodsCount.data['count']}');
      debugPrint('[FoodDatabaseLoader] ✅ Final FTS count: ${finalFtsCount.data['count']}');

      // Test search to verify FTS works
      final testResults = await _db.customSelect(
        "SELECT food_id, name FROM foods_fts WHERE foods_fts MATCH 'leche*' LIMIT 3"
      ).get();
      debugPrint('[FoodDatabaseLoader] 🔍 Test search "leche*": ${testResults.length} results');
      for (final row in testResults) {
        debugPrint('  - ${row.data['name']}');
      }

      // 5. Marcar como cargada
      await _markDatabaseAsLoaded();
      debugPrint('[FoodDatabaseLoader] ✅ Database marked as loaded');

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
    final name = _sanitizeName(json['name'] as String? ?? 'Sin nombre');
    final brand = json['brands'] as String?;

    return FoodsCompanion(
      id: Value(json['code'] as String? ?? const Uuid().v4()),
      name: Value(name),
      // normalizedName is critical for LIKE fallback search
      normalizedName: Value(name.toLowerCase()),
      brand: Value(brand),
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

/// Diagnostic info for debugging database issues
class FoodDatabaseDiagnostics {
  final int totalFoods;
  final int systemFoods;
  final int userFoods;
  final int ftsEntries;
  final int foodsWithNormalizedName;
  final List<String> sampleNames;
  final int sampleSearchResults;

  const FoodDatabaseDiagnostics({
    required this.totalFoods,
    required this.systemFoods,
    required this.userFoods,
    required this.ftsEntries,
    required this.foodsWithNormalizedName,
    required this.sampleNames,
    required this.sampleSearchResults,
  });

  bool get isHealthy =>
      totalFoods > 10000 &&
      ftsEntries > 10000 &&
      sampleSearchResults > 0;

  @override
  String toString() {
    return '''
FoodDatabaseDiagnostics:
  Total foods: $totalFoods
  System foods: $systemFoods
  User foods: $userFoods
  FTS entries: $ftsEntries
  Foods with normalizedName: $foodsWithNormalizedName
  Sample names: ${sampleNames.take(3).join(', ')}
  Sample search results: $sampleSearchResults
  Is healthy: $isHealthy
''';
  }
}

/// Provider for database diagnostics
final foodDatabaseDiagnosticsProvider = FutureProvider<FoodDatabaseDiagnostics>((ref) async {
  final db = ref.watch(appDatabaseProvider);

  final totalFoods = await db.customSelect('SELECT COUNT(*) as count FROM foods').getSingle();
  final systemFoods = await db.customSelect('SELECT COUNT(*) as count FROM foods WHERE user_created = 0').getSingle();
  final userFoods = await db.customSelect('SELECT COUNT(*) as count FROM foods WHERE user_created = 1').getSingle();
  final ftsEntries = await db.customSelect('SELECT COUNT(*) as count FROM foods_fts').getSingle();
  final withNormalized = await db.customSelect('SELECT COUNT(*) as count FROM foods WHERE normalized_name IS NOT NULL').getSingle();
  final sampleFoods = await db.customSelect('SELECT name FROM foods LIMIT 5').get();
  final searchTest = await db.customSelect("SELECT COUNT(*) as count FROM foods_fts WHERE foods_fts MATCH 'leche*'").getSingle();

  return FoodDatabaseDiagnostics(
    totalFoods: totalFoods.data['count'] as int,
    systemFoods: systemFoods.data['count'] as int,
    userFoods: userFoods.data['count'] as int,
    ftsEntries: ftsEntries.data['count'] as int,
    foodsWithNormalizedName: withNormalized.data['count'] as int,
    sampleNames: sampleFoods.map((r) => r.data['name'] as String).toList(),
    sampleSearchResults: searchTest.data['count'] as int,
  );
});
