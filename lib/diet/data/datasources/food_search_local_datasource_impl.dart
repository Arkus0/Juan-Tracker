import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../data/datasources/food_search_local_datasource.dart';
import '../../data/models/cached_search_result.dart';
import '../../models/food_model.dart';

/// Implementación del datasource local usando SQLite + SharedPreferences
/// 
/// - SQLite: Cache persistente de búsquedas (más eficiente que SharedPreferences)
/// - SharedPreferences: Historial de búsquedas (pequeño dataset)
class FoodSearchLocalDataSourceImpl implements FoodSearchLocalDataSource {
  Database? _db;
  SharedPreferences? _prefs;
  
  static const String _dbName = 'food_search_cache.db';
  static const String _cacheTable = 'search_cache';
  static const String _historyKey = 'search_history_v1';
  static const int _maxHistorySize = 20;
  static const int _maxCacheSize = 50; // Máximo de queries cacheadas

  /// Inicializa la base de datos
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    if (_db == null) {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_cacheTable (
              query TEXT PRIMARY KEY,
              results TEXT NOT NULL,
              cached_at INTEGER NOT NULL,
              expires_at INTEGER NOT NULL,
              total_count INTEGER NOT NULL,
              source TEXT NOT NULL
            )
          ''');
          
          // Índice para limpieza por expiración
          await db.execute('''
            CREATE INDEX idx_expires ON $_cacheTable(expires_at)
          ''');
        },
      );
    }
  }

  @override
  Future<List<FoodModel>> searchLocalFoods(String query, {int limit = 20}) async {
    // Nota: La búsqueda de alimentos locales se maneja en AlimentoRepository
    // Este DataSource solo maneja cache de búsquedas externas
    return [];
  }

  @override
  Future<CachedSearchResult?> getCachedSearch(String query) async {
    await initialize();
    if (_db == null) return null;

    final normalizedQuery = query.toLowerCase().trim();
    
    final results = await _db!.query(
      _cacheTable,
      where: 'query = ? AND expires_at > ?',
      whereArgs: [normalizedQuery, DateTime.now().millisecondsSinceEpoch],
      limit: 1,
    );

    if (results.isEmpty) return null;

    try {
      final row = results.first;
      return CachedSearchResult(
        query: row['query'] as String,
        items: (jsonDecode(row['results'] as String) as List<dynamic>)
            .map((i) => CachedFoodItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        cachedAt: DateTime.fromMillisecondsSinceEpoch(row['cached_at'] as int),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(row['expires_at'] as int),
        totalCount: row['total_count'] as int,
        source: row['source'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheSearchResults(CachedSearchResult result) async {
    await initialize();
    if (_db == null) return;

    // Limpiar cache antiguo si es necesario
    await _enforceCacheLimit();

    final normalizedQuery = result.query.toLowerCase().trim();
    
    await _db!.insert(
      _cacheTable,
      {
        'query': normalizedQuery,
        'results': jsonEncode(result.items.map((i) => i.toJson()).toList()),
        'cached_at': result.cachedAt.millisecondsSinceEpoch,
        'expires_at': result.expiresAt.millisecondsSinceEpoch,
        'total_count': result.totalCount,
        'source': result.source,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<CachedFoodItem>> searchOffline(String query) async {
    await initialize();
    if (_db == null) return [];

    final normalizedQuery = query.toLowerCase();
    final allResults = <CachedFoodItem>[];
    final seenCodes = <String>{};

    // Buscar en todas las entradas de cache
    final rows = await _db!.query(
      _cacheTable,
      where: 'expires_at > ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );

    for (final row in rows) {
      try {
        final items = (jsonDecode(row['results'] as String) as List<dynamic>)
            .map((i) => CachedFoodItem.fromJson(i as Map<String, dynamic>))
            .toList();

        for (final item in items) {
          if (seenCodes.contains(item.code)) continue;
          
          // Búsqueda difusa simple
          if (_matchesQuery(item, normalizedQuery)) {
            allResults.add(item);
            seenCodes.add(item.code);
          }
        }
      } catch (_) {
        // Ignorar entradas corruptas
      }
    }

    return allResults;
  }

  bool _matchesQuery(CachedFoodItem item, String query) {
    final name = item.name.toLowerCase();
    final brand = item.brand?.toLowerCase() ?? '';
    
    return name.contains(query) || brand.contains(query);
  }

  @override
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    await initialize();
    
    final json = _prefs?.getString(_historyKey);
    if (json == null) return [];

    try {
      final list = (jsonDecode(json) as List<dynamic>).cast<String>();
      return list.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveSearch(String query) async {
    await initialize();
    if (_prefs == null) return;

    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.length < 2) return;

    var history = await getRecentSearches(limit: _maxHistorySize);
    
    // Eliminar si existe y agregar al principio
    history.remove(normalizedQuery);
    history.insert(0, normalizedQuery);
    
    // Mantener límite
    if (history.length > _maxHistorySize) {
      history = history.sublist(0, _maxHistorySize);
    }

    await _prefs!.setString(_historyKey, jsonEncode(history));
  }

  @override
  Future<void> clearHistory() async {
    await initialize();
    await _prefs?.remove(_historyKey);
  }

  @override
  Future<List<String>> getCachedQueries() async {
    await initialize();
    if (_db == null) return [];

    final rows = await _db!.query(
      _cacheTable,
      columns: ['query'],
      where: 'expires_at > ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );

    return rows.map((r) => r['query'] as String).toList();
  }

  @override
  Future<int> cleanupExpiredCache() async {
    await initialize();
    if (_db == null) return 0;

    return await _db!.delete(
      _cacheTable,
      where: 'expires_at <= ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }

  /// Mantiene el cache dentro del límite (LRU simple)
  Future<void> _enforceCacheLimit() async {
    if (_db == null) return;

    final count = Sqflite.firstIntValue(
      await _db!.rawQuery('SELECT COUNT(*) FROM $_cacheTable'),
    ) ?? 0;

    if (count >= _maxCacheSize) {
      // Eliminar las más antiguas
      final toDelete = count - _maxCacheSize + 1;
      await _db!.rawDelete('''
        DELETE FROM $_cacheTable 
        WHERE query IN (
          SELECT query FROM $_cacheTable 
          ORDER BY cached_at ASC 
          LIMIT $toDelete
        )
      ''');
    }
  }

  /// Cierra la base de datos (para tests)
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
