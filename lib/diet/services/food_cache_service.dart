import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_model.dart';
import '../models/open_food_facts_model.dart';

/// Entrada de cache para un término de búsqueda
class CachedSearchResult {
  final String query;
  final List<OpenFoodFactsResult> results;
  final DateTime cachedAt;
  final int ttlDays;

  const CachedSearchResult({
    required this.query,
    required this.results,
    required this.cachedAt,
    this.ttlDays = 7, // Cache válido por 7 días
  });

  bool get isExpired {
    final expiryDate = cachedAt.add(Duration(days: ttlDays));
    return DateTime.now().isAfter(expiryDate);
  }

  Map<String, dynamic> toJson() => {
    'query': query,
    'results': results.map((r) => r.toCacheJson()).toList(),
    'cachedAt': cachedAt.toIso8601String(),
    'ttlDays': ttlDays,
  };

  factory CachedSearchResult.fromJson(Map<String, dynamic> json) {
    return CachedSearchResult(
      query: json['query'] as String,
      results: (json['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((r) => OpenFoodFactsResult.fromCacheJson(r))
          .toList(),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      ttlDays: json['ttlDays'] as int? ?? 7,
    );
  }
}

/// Servicio de cache para búsquedas de alimentos externos
/// 
/// Características:
/// - Cache de términos de búsqueda (últimos N términos, TTL configurable)
/// - Cache de alimentos guardados (persistidos permanentemente)
/// - Cache de imágenes (archivos locales)
/// - Búsqueda offline en cache local
class FoodCacheService {
  static const String _searchCacheKey = 'food_search_cache_v1';
  static const String _savedFoodsKey = 'saved_external_foods_v1';
  static const String _recentSearchesKey = 'recent_search_terms_v1';
  static const int _maxCachedSearches = 20; // Máximo de términos en cache
  static const int _maxRecentSearches = 10; // Máximo de términos recientes

  SharedPreferences? _prefs;
  Directory? _imageCacheDir;

  // Singleton pattern con soporte para reset en tests
  static FoodCacheService? _instance;
  factory FoodCacheService() {
    _instance ??= FoodCacheService._internal();
    return _instance!;
  }
  FoodCacheService._internal();
  
  /// Solo para tests: resetea la instancia singleton
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  /// Inicializa el servicio (llamar antes de usar)
  /// 
  /// En tests, [imageCacheDir] puede ser null para evitar dependencias de path_provider
  Future<void> initialize({Directory? imageCacheDir}) async {
    _prefs ??= await SharedPreferences.getInstance();
    if (imageCacheDir != null) {
      _imageCacheDir = imageCacheDir;
    } else {
      try {
        _imageCacheDir ??= await _initImageCacheDir();
      } catch (_) {
        // Ignorar errores de path_provider (ej: en tests)
        _imageCacheDir = null;
      }
    }
  }

  Future<Directory> _initImageCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'food_images_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  // ============================================================================
  // CACHE DE BÚSQUEDAS
  // ============================================================================

  /// Guarda resultados de búsqueda en cache
  Future<void> cacheSearchResults(String query, List<OpenFoodFactsResult> results) async {
    await initialize();
    if (_prefs == null) return;

    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return;

    final cache = await _getSearchCache();
    
    // Crear nueva entrada
    final entry = CachedSearchResult(
      query: normalizedQuery,
      results: results,
      cachedAt: DateTime.now(),
    );

    // Actualizar cache (evitar duplicados, mantener límite)
    cache.removeWhere((c) => c.query == normalizedQuery);
    cache.insert(0, entry);
    
    // Mantener solo los N más recientes
    while (cache.length > _maxCachedSearches) {
      // Eliminar imágenes del entry más antiguo si no está en saved foods
      final oldest = cache.removeLast();
      await _cleanupOrphanedImages(oldest);
    }

    await _saveSearchCache(cache);
    
    // También actualizar términos recientes
    await _addToRecentSearches(normalizedQuery);
  }

  /// Obtiene resultados cacheados para un término
  Future<List<OpenFoodFactsResult>?> getCachedSearchResults(String query) async {
    await initialize();
    
    final normalizedQuery = query.toLowerCase().trim();
    final cache = await _getSearchCache();
    
    final entry = cache.cast<CachedSearchResult?>().firstWhere(
      (c) => c?.query == normalizedQuery,
      orElse: () => null,
    );
    
    if (entry == null || entry.isExpired) {
      return null;
    }
    
    return entry.results;
  }

  /// Busca en cache local (para modo offline)
  Future<List<OpenFoodFactsResult>> searchOffline(String query) async {
    await initialize();
    
    final normalizedQuery = query.toLowerCase().trim();
    final cache = await _getSearchCache();
    final savedFoods = await getSavedExternalFoods();
    
    final results = <OpenFoodFactsResult>[];
    final seenCodes = <String>{};
    
    // Buscar en cache de búsquedas
    for (final entry in cache) {
      if (!entry.isExpired) {
        for (final product in entry.results) {
          if (_matchesQuery(product, normalizedQuery) && !seenCodes.contains(product.code)) {
            results.add(product);
            seenCodes.add(product.code);
          }
        }
      }
    }
    
    // Buscar en alimentos guardados
    for (final food in savedFoods) {
      if (_matchesSavedFood(food, normalizedQuery)) {
        // Convertir FoodModel a OpenFoodFactsResult
        final converted = _convertToOpenFoodFactsResult(food);
        if (!seenCodes.contains(converted.code)) {
          results.add(converted);
          seenCodes.add(converted.code);
        }
      }
    }
    
    return results;
  }

  bool _matchesQuery(OpenFoodFactsResult product, String query) {
    return product.name.toLowerCase().contains(query) ||
        (product.brand?.toLowerCase().contains(query) ?? false);
  }

  bool _matchesSavedFood(FoodModel food, String query) {
    return food.name.toLowerCase().contains(query) ||
        (food.brand?.toLowerCase().contains(query) ?? false);
  }

  OpenFoodFactsResult _convertToOpenFoodFactsResult(FoodModel food) {
    return OpenFoodFactsResult(
      code: food.barcode ?? food.id,
      name: food.name,
      brand: food.brand,
      kcalPer100g: food.kcalPer100g.toDouble(),
      proteinPer100g: food.proteinPer100g,
      carbsPer100g: food.carbsPer100g,
      fatPer100g: food.fatPer100g,
      portionName: food.portionName,
      portionGrams: food.portionGrams,
      fetchedAt: food.updatedAt,
    );
  }

  // ============================================================================
  // TÉRMINOS RECIENTES
  // ============================================================================

  /// Obtiene los términos de búsqueda recientes
  Future<List<String>> getRecentSearches() async {
    await initialize();
    if (_prefs == null) return [];
    
    final json = _prefs!.getString(_recentSearchesKey);
    if (json == null) return [];
    
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _addToRecentSearches(String query) async {
    if (_prefs == null) return;
    
    final recent = await getRecentSearches();
    recent.remove(query); // Eliminar si existe
    recent.insert(0, query); // Agregar al inicio
    
    // Mantener límite
    while (recent.length > _maxRecentSearches) {
      recent.removeLast();
    }
    
    await _prefs!.setString(_recentSearchesKey, jsonEncode(recent));
  }

  /// Limpia los términos de búsqueda recientes
  Future<void> clearRecentSearches() async {
    await initialize();
    await _prefs?.remove(_recentSearchesKey);
  }

  // ============================================================================
  // ALIMENTOS GUARDADOS (persistidos permanentemente)
  // ============================================================================

  /// Guarda un alimento externo como FoodModel local
  /// Retorna el FoodModel creado con ID generado
  Future<FoodModel> saveExternalFood(OpenFoodFactsResult result) async {
    await initialize();
    
    final food = FoodModel(
      id: 'off_${result.code}_${DateTime.now().millisecondsSinceEpoch}',
      name: result.name,
      brand: result.brand,
      barcode: result.code,
      kcalPer100g: result.kcalPer100g.round(),
      proteinPer100g: result.proteinPer100g,
      carbsPer100g: result.carbsPer100g,
      fatPer100g: result.fatPer100g,
      portionName: result.portionName,
      portionGrams: result.portionGrams,
      userCreated: false,
      verifiedSource: 'OFF',
      sourceMetadata: {
        'source': result.source,
        'fetchedAt': result.fetchedAt.toIso8601String(),
        'imageUrl': result.imageUrl,
        'ingredients': result.ingredientsText,
        'fiberPer100g': result.fiberPer100g,
        'sugarPer100g': result.sugarPer100g,
        'sodiumPer100g': result.sodiumPer100g,
      },
    );

    final savedFoods = await _getSavedFoodsRaw();
    savedFoods[result.code] = food.toDebugMap(); // Usar barcode como key
    await _saveFoodsRaw(savedFoods);

    return food;
  }

  /// Obtiene todos los alimentos externos guardados
  Future<List<FoodModel>> getSavedExternalFoods() async {
    await initialize();
    
    final raw = await _getSavedFoodsRaw();
    return raw.values.map((json) => _foodModelFromJson(json as Map<String, dynamic>)).toList();
  }

  /// Verifica si un alimento ya está guardado
  Future<bool> isFoodSaved(String barcode) async {
    await initialize();
    final savedFoods = await _getSavedFoodsRaw();
    return savedFoods.containsKey(barcode);
  }

  /// Elimina un alimento guardado
  Future<void> removeSavedFood(String barcode) async {
    await initialize();
    final savedFoods = await _getSavedFoodsRaw();
    savedFoods.remove(barcode);
    await _saveFoodsRaw(savedFoods);
  }

  // ============================================================================
  // CACHE DE IMÁGENES
  // ============================================================================

  /// Guarda una imagen en cache local
  Future<String?> cacheImage(String url, Uint8List bytes) async {
    await initialize();
    if (_imageCacheDir == null) return null;

    try {
      final filename = '${url.hashCode}.jpg';
      final file = File(path.join(_imageCacheDir!.path, filename));
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene la ruta de una imagen cacheada si existe
  Future<String?> getCachedImagePath(String url) async {
    await initialize();
    if (_imageCacheDir == null) return null;

    try {
      final filename = '${url.hashCode}.jpg';
      final file = File(path.join(_imageCacheDir!.path, filename));
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Limpia imágenes huérfanas (no referenciadas por alimentos guardados)
  Future<void> _cleanupOrphanedImages(CachedSearchResult entry) async {
    if (_imageCacheDir == null) return;

    final savedFoods = await getSavedExternalFoods();
    final savedBarcodes = savedFoods.map((f) => f.barcode).toSet();

    for (final product in entry.results) {
      // Solo eliminar si no está en alimentos guardados
      if (!savedBarcodes.contains(product.code) && product.imageUrl != null) {
        try {
          final filename = '${product.imageUrl.hashCode}.jpg';
          final file = File(path.join(_imageCacheDir!.path, filename));
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {
          // Ignorar errores de limpieza
        }
      }
    }
  }

  // ============================================================================
  // MÉTODOS PRIVADOS AUXILIARES
  // ============================================================================

  Future<List<CachedSearchResult>> _getSearchCache() async {
    if (_prefs == null) return [];
    
    final json = _prefs!.getString(_searchCacheKey);
    if (json == null) return [];
    
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map((j) => CachedSearchResult.fromJson(j))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveSearchCache(List<CachedSearchResult> cache) async {
    if (_prefs == null) return;
    final json = jsonEncode(cache.map((c) => c.toJson()).toList());
    await _prefs!.setString(_searchCacheKey, json);
  }

  Future<Map<String, dynamic>> _getSavedFoodsRaw() async {
    if (_prefs == null) return {};
    
    final json = _prefs!.getString(_savedFoodsKey);
    if (json == null) return {};
    
    try {
      return Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveFoodsRaw(Map<String, dynamic> foods) async {
    if (_prefs == null) return;
    await _prefs!.setString(_savedFoodsKey, jsonEncode(foods));
  }

  FoodModel _foodModelFromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      barcode: json['barcode'] as String?,
      kcalPer100g: json['kcalPer100g'] as int,
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble(),
      carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble(),
      fatPer100g: (json['fatPer100g'] as num?)?.toDouble(),
      portionName: json['portionName'] as String?,
      portionGrams: (json['portionGrams'] as num?)?.toDouble(),
      userCreated: json['userCreated'] as bool? ?? false,
      verifiedSource: json['verifiedSource'] as String?,
      sourceMetadata: json['sourceMetadata'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // ============================================================================
  // LIMPIEZA GENERAL
  // ============================================================================

  /// Limpia todo el cache (excepto alimentos guardados)
  Future<void> clearSearchCache() async {
    await initialize();
    await _prefs?.remove(_searchCacheKey);
  }

  /// Obtiene estadísticas del cache
  Future<Map<String, int>> getCacheStats() async {
    await initialize();
    
    final searchCache = await _getSearchCache();
    final savedFoods = await _getSavedFoodsRaw();
    final recent = await getRecentSearches();
    
    return {
      'cachedSearches': searchCache.length,
      'savedExternalFoods': savedFoods.length,
      'recentSearchTerms': recent.length,
    };
  }
}
