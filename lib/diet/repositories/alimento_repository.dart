import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/database_provider.dart';
import '../../training/database/database.dart';
import '../models/food_model.dart';



/// Filtros avanzados para búsqueda de alimentos
class SearchFilters {
  final bool soloGenericos;
  final bool soloVerificados;
  final bool soloConImagen;
  final String? categoria;
  final String? minNutriScore; // 'a', 'b', 'c', 'd', 'e'
  final int? maxNovaGroup; // 1, 2, 3, 4
  final double? minProteinas;
  final double? maxCalorias;
  final List<String>? alergenosExcluir;
  final List<String>? preferenciasDieteticas; // 'vegano', 'keto', etc.

  const SearchFilters({
    this.soloGenericos = false,
    this.soloVerificados = false,
    this.soloConImagen = false,
    this.categoria,
    this.minNutriScore,
    this.maxNovaGroup,
    this.minProteinas,
    this.maxCalorias,
    this.alergenosExcluir,
    this.preferenciasDieteticas,
  });

  SearchFilters copyWith({
    bool? soloGenericos,
    bool? soloVerificados,
    bool? soloConImagen,
    String? categoria,
    String? minNutriScore,
    int? maxNovaGroup,
    double? minProteinas,
    double? maxCalorias,
    List<String>? alergenosExcluir,
    List<String>? preferenciasDieteticas,
  }) {
    return SearchFilters(
      soloGenericos: soloGenericos ?? this.soloGenericos,
      soloVerificados: soloVerificados ?? this.soloVerificados,
      soloConImagen: soloConImagen ?? this.soloConImagen,
      categoria: categoria ?? this.categoria,
      minNutriScore: minNutriScore ?? this.minNutriScore,
      maxNovaGroup: maxNovaGroup ?? this.maxNovaGroup,
      minProteinas: minProteinas ?? this.minProteinas,
      maxCalorias: maxCalorias ?? this.maxCalorias,
      alergenosExcluir: alergenosExcluir ?? this.alergenosExcluir,
      preferenciasDieteticas: preferenciasDieteticas ?? this.preferenciasDieteticas,
    );
  }
}

/// Modelo de resultado de búsqueda con score de relevancia
class ScoredFood {
  final Food food;
  final double score;
  final bool isFromCache;
  final bool isFromRemote;

  const ScoredFood({
    required this.food,
    required this.score,
    this.isFromCache = false,
    this.isFromRemote = false,
  });
}

/// Repository para operaciones de alimentos con Drift
/// 
/// Características:
/// - Búsqueda FTS5 nativa de SQLite
/// - Ranking inteligente con múltiples señales
/// - Búsqueda híbrida: local + Open Food Facts
class AlimentoRepository {
  final AppDatabase _db;
  final Dio _dio;
  CancelToken? _cancelToken;
  
  // Rate limiting para OFF API
  final List<DateTime> _requestTimestamps = [];
  static const int _maxRequestsPerMinute = 10;
  static const _uuid = Uuid();

  AlimentoRepository(this._db) : _dio = Dio(BaseOptions(
    baseUrl: 'https://world.openfoodfacts.org',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'User-Agent': 'JuanTracker/1.0 (Flutter; Android; es-ES)',
      'Accept': 'application/json',
    },
  ));

  // ============================================================================
  // BÚSQUEDA PRINCIPAL
  // ============================================================================

  /// Búsqueda LOCAL instantánea (FTS5)
  /// 
  /// Solo busca en la base de datos local. Para buscar en internet,
  /// usar `searchOnline()` por separado (decisión del usuario).
  /// 
  /// Esto garantiza respuestas instantáneas sin esperar a la red.
  Future<List<ScoredFood>> search(
    String query, {
    SearchFilters? filters,
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase().trim();
    
    // 1. Búsqueda FTS local (instantánea, ~1-5ms)
    var localResults = await _db.searchFoodsFTS(normalizedQuery, limit: limit);
    debugPrint('[AlimentoRepository] Local FTS results: ${localResults.length}');
    
    // 2. Aplicar filtros adicionales
    if (filters != null) {
      localResults = _applyFilters(localResults, filters);
    }
    
    // 3. Convertir a ScoredFood con score base
    final scoredResults = localResults.map((f) => ScoredFood(
      food: f,
      score: _calculateBaseScore(f, normalizedQuery),
      isFromCache: true,
    )).toList();
    
    // 4. Aplicar ranking final
    return _applyRanking(scoredResults, normalizedQuery).take(limit).toList();
  }

  /// Búsqueda ONLINE en Open Food Facts
  /// 
  /// Llamar solo cuando el usuario explícitamente quiere buscar en internet.
  /// Guarda los resultados en caché local para futuras búsquedas.
  Future<List<ScoredFood>> searchOnline(
    String query, {
    int limit = 30,
    CancelToken? cancelToken,
  }) async {
    if (query.trim().isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase().trim();
    final token = cancelToken ?? CancelToken();
    
    debugPrint('[AlimentoRepository] Searching OFF for: "$normalizedQuery"');
    
    try {
      final remoteResults = await _searchOpenFoodFacts(
        normalizedQuery, 
        limit: limit, 
        cancelToken: token,
      );
      
      debugPrint('[AlimentoRepository] OFF results: ${remoteResults.length}');
      return _applyRanking(remoteResults, normalizedQuery).take(limit).toList();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('[AlimentoRepository] OFF search cancelled');
        return [];
      }
      debugPrint('[AlimentoRepository] OFF search failed: $e');
      rethrow;
    }
  }

  /// Búsqueda rápida offline (solo local)
  Future<List<Food>> searchOffline(String query, {int limit = 50}) async {
    return _db.searchFoodsOffline(query, limit: limit);
  }

  /// Búsqueda por código de barras (local + OFF)
  Future<Food?> searchByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;
    
    final cleanBarcode = barcode.trim();
    
    // 1. Buscar localmente primero
    final local = await (_db.select(_db.foods)
      ..where((f) => f.barcode.equals(cleanBarcode)))
      .getSingleOrNull();
    
    if (local != null) {
      await _db.recordFoodUsage(local.id);
      return local;
    }
    
    // 2. Si no está local, buscar en OFF
    try {
      debugPrint('[AlimentoRepository] Barcode not local, searching OFF: $cleanBarcode');
      final remote = await _searchBarcodeInOFF(cleanBarcode);
      if (remote != null) {
        await _db.recordFoodUsage(remote.id);
        return remote;
      }
    } catch (e) {
      debugPrint('[AlimentoRepository] OFF barcode search failed: $e');
    }
    
    return null;
  }

  // ============================================================================
  // SUGERENCIAS Y PREDICCIONES
  // ============================================================================

  /// Sugerencias de autocompletado
  Future<List<String>> getSuggestions(String prefix, {int limit = 10}) async {
    if (prefix.length < 2) return [];
    return _db.getSearchSuggestions(prefix, limit: limit);
  }

  /// Alimentos habituales del usuario basados en contexto temporal
  Future<List<Food>> getHabitualFoods({
    DateTime? dateTime,
    int limit = 20,
  }) async {
    final dt = dateTime ?? DateTime.now();
    return _db.getHabitualFoods(
      hourOfDay: dt.hour,
      dayOfWeek: dt.weekday,
      limit: limit,
    );
  }

  /// Alimentos más usados recientemente
  Future<List<Food>> getRecentlyUsed({int limit = 20}) async {
    return (_db.select(_db.foods)
      ..where((f) => f.lastUsedAt.isNotNull())
      ..orderBy([(f) => OrderingTerm.desc(f.lastUsedAt)])
      ..limit(limit))
      .get();
  }

  /// Alimentos más populares (por useCount)
  Future<List<Food>> getMostPopular({int limit = 20}) async {
    return (_db.select(_db.foods)
      ..orderBy([(f) => OrderingTerm.desc(f.useCount)])
      ..limit(limit))
      .get();
  }

  /// Alimentos favoritos del usuario
  Future<List<Food>> getFavorites({int limit = 50}) async {
    return (_db.select(_db.foods)
      ..where((f) => f.isFavorite.equals(true))
      ..orderBy([(f) => OrderingTerm.desc(f.lastUsedAt)])
      ..limit(limit))
      .get();
  }

  /// Marcar/desmarcar alimento como favorito
  Future<void> setFavorite(String foodId, bool isFavorite) async {
    await (_db.update(_db.foods)
      ..where((f) => f.id.equals(foodId)))
      .write(FoodsCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ));
  }

  /// Alternar estado de favorito
  Future<bool> toggleFavorite(String foodId) async {
    final food = await getById(foodId);
    if (food == null) return false;
    
    final newState = !food.isFavorite;
    await setFavorite(foodId, newState);
    return newState;
  }

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  /// Insertar o actualizar un alimento
  Future<void> saveFood(FoodModel model) async {
    final companion = FoodsCompanion(
      id: Value(model.id),
      name: Value(model.name),
      normalizedName: Value(model.name.toLowerCase()),
      brand: Value(model.brand),
      barcode: Value(model.barcode),
      kcalPer100g: Value(model.kcalPer100g),
      proteinPer100g: Value(model.proteinPer100g ?? 0),
      carbsPer100g: Value(model.carbsPer100g ?? 0),
      fatPer100g: Value(model.fatPer100g ?? 0),
      portionName: Value(model.portionName),
      portionGrams: Value(model.portionGrams),
      userCreated: Value(model.userCreated),
      verifiedSource: Value(model.verifiedSource),
      sourceMetadata: Value(model.sourceMetadata),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
    
    await _db.into(_db.foods).insertOnConflictUpdate(companion);
    
    // Sincronizar con índice FTS5
    await _db.insertFoodFts(
      model.id,
      model.name,
      model.brand,
    );
  }

  /// Obtener un alimento por ID
  Future<Food?> getById(String id) async {
    return (_db.select(_db.foods)
      ..where((f) => f.id.equals(id)))
      .getSingleOrNull();
  }

  /// Eliminar un alimento
  Future<void> delete(String id) async {
    await (_db.delete(_db.foods)
      ..where((f) => f.id.equals(id)))
      .go();
  }

  /// Registrar selección de alimento (actualiza estadísticas)
  Future<void> recordSelection(String foodId, {MealType? mealType}) async {
    await _db.recordFoodUsage(foodId, mealType: mealType);
  }

  /// Guardar búsqueda en historial
  Future<void> recordSearch(String query, {String? selectedFoodId, bool hasResults = true}) async {
    await _db.saveSearchHistory(query, selectedFoodId: selectedFoodId, hasResults: hasResults);
  }

  // ============================================================================
  // MÉTODOS PRIVADOS
  // ============================================================================



  List<Food> _applyFilters(List<Food> foods, SearchFilters filters) {
    return foods.where((f) {
      if (filters.soloGenericos && !f.userCreated) return false;
      if (filters.soloVerificados && f.verifiedSource == null) return false;
      if (filters.minNutriScore != null && f.nutriScore != null) {
        // Nutri-Score: 'a' es mejor que 'e'
        final order = {'a': 5, 'b': 4, 'c': 3, 'd': 2, 'e': 1};
        final foodScore = order[f.nutriScore?.toLowerCase()] ?? 0;
        final minScore = order[filters.minNutriScore!.toLowerCase()] ?? 0;
        if (foodScore < minScore) return false;
      }
      if (filters.maxNovaGroup != null && f.novaGroup != null) {
        if (f.novaGroup! > filters.maxNovaGroup!) return false;
      }
      if (filters.minProteinas != null && (f.proteinPer100g ?? 0) < filters.minProteinas!) {
        return false;
      }
      if (filters.maxCalorias != null && f.kcalPer100g > filters.maxCalorias!) {
        return false;
      }
      return true;
    }).toList();
  }

  // ============================================================================
  // RANKING ALGORITHM
  // Score weights documented for tuning
  // ============================================================================
  
  /// Score weights for relevance ranking
  /// Higher = more important for ranking
  static const _kScoreExactStartMatch = 100.0;   // "lech" → "leche"
  static const _kScoreExactContains = 50.0;      // "desc" → "leche descremada"
  static const _kScoreWordStartMatch = 30.0;     // "desc" → "leche descremada"
  static const _kScorePopularityMultiplier = 5.0; // log(useCount) * this
  static const _kScoreRecencyBase = 30.0;        // Recent usage boost (was 20)
  static const _kScoreRecencyDecayDays = 14;     // Days until recency = 0 (was 20)
  static const _kScoreVerifiedBoost = 10.0;      // Verified sources
  static const _kScoreCompleteDataBoost = 5.0;   // Has all macros
  static const _kScoreFavoriteBoost = 25.0;      // User-favorited items
  static const _kScoreUsedTodayBoost = 15.0;     // Used within last 24h
  static const _kScoreGenericBoost = 40.0;       // Generic/natural products (sin marca)
  static const _kScoreProcessedPenalty = -30.0;  // Processed products (zumos, salsas, etc.)
  
  /// Keywords que indican producto procesado (zumos, bebidas, etc.)
  static const _processedKeywords = [
    'zumo', 'néctar', 'nectar', 'bebida', 'batido', 'refresco',
    'salsa', 'sirope', 'jarabe', 'concentrado',
  ];

  double _calculateBaseScore(Food food, String query) {
    var score = 0.0;
    final nameLower = food.name.toLowerCase();
    final queryLower = query.toLowerCase();
    
    // 1. Text matching (position-aware)
    if (nameLower.startsWith(queryLower)) {
      score += _kScoreExactStartMatch;
    } else if (nameLower.contains(queryLower)) {
      score += _kScoreExactContains;
    } else if (nameLower.split(' ').any((word) => word.startsWith(queryLower))) {
      score += _kScoreWordStartMatch;
    }
    
    // 2. Popularity (logarithmic to prevent domination by very popular items)
    score += math.log(food.useCount + 1) * _kScorePopularityMultiplier;
    
    // 3. Recency boost (linear decay over 14 days)
    if (food.lastUsedAt != null) {
      final daysSinceUse = DateTime.now().difference(food.lastUsedAt!).inDays;
      
      // Extra boost for used TODAY (within 24h)
      if (daysSinceUse == 0) {
        score += _kScoreUsedTodayBoost;
      }
      
      // Linear decay: full boost at day 0, zero at 14 days
      final recencyScore = math.max(
        0.0, 
        _kScoreRecencyBase * (1 - (daysSinceUse / _kScoreRecencyDecayDays)),
      );
      score += recencyScore;
    }
    
    // 4. Favorites boost
    if (food.isFavorite == true) {
      score += _kScoreFavoriteBoost;
    }
    
    // 5. Quality signals
    if (food.verifiedSource != null) {
      score += _kScoreVerifiedBoost;
    }
    
    final hasCompleteData = food.proteinPer100g != null && 
                           food.carbsPer100g != null && 
                           food.fatPer100g != null;
    if (hasCompleteData) {
      score += _kScoreCompleteDataBoost;
    }
    
    // 6. Generic/natural product boost (sin marca = producto natural)
    final brandLower = food.brand?.toLowerCase() ?? '';
    final isGeneric = brandLower.isEmpty || 
                      brandLower == 'generic' || 
                      brandLower == 'genérico';
    if (isGeneric) {
      score += _kScoreGenericBoost;
    }
    
    // 7. Processed product penalty (zumos, bebidas procesadas)
    final isProcessed = _processedKeywords.any((kw) => nameLower.contains(kw));
    if (isProcessed) {
      score += _kScoreProcessedPenalty;
    }
    
    return score;
  }

  List<ScoredFood> _applyRanking(List<ScoredFood> foods, String query) {
    // Sort by score descending, with deterministic tie-breaker (ID)
    // This ensures identical scores always produce the same order
    foods.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) return scoreComparison;
      // Tie-breaker: alphabetical by ID for consistency
      return a.food.id.compareTo(b.food.id);
    });
    return foods;
  }

  // ============================================================================
  // OPEN FOOD FACTS API
  // ============================================================================

  /// Busca productos en Open Food Facts
  Future<List<ScoredFood>> _searchOpenFoodFacts(String query, {int limit = 20, CancelToken? cancelToken}) async {
    await _waitForRateLimit();
    
    _recordRequest();
    
    final response = await _dio.get<Map<String, dynamic>>(
      '/cgi/search.pl',
      queryParameters: {
        'search_terms': query,
        'search_simple': '1',
        'json': '1',
        'page': '1',
        'page_size': limit.toString(),
        'fields': 'code,product_name,brands,image_url,nutriments,'
                  'nutriscore_grade,nova_group',
        'countries_tags': 'en:spain',
        'lc': 'es',
        'sort_by': 'unique_scans_n',
      },
      cancelToken: cancelToken,
    );
    
    if (response.data == null) return [];
    
    final products = response.data!['products'] as List<dynamic>? ?? [];
    final results = <ScoredFood>[];
    
    for (final p in products) {
      if (p is! Map<String, dynamic>) continue;
      
      final food = await _parseAndSaveProduct(p);
      if (food != null) {
        results.add(ScoredFood(
          food: food,
          score: _calculateBaseScore(food, query),
          isFromRemote: true,
        ));
      }
    }
    
    return results;
  }

  /// Busca un producto por código de barras en OFF
  Future<Food?> _searchBarcodeInOFF(String barcode) async {
    await _waitForRateLimit();
    _recordRequest();
    
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v2/product/$barcode',
      queryParameters: {
        'fields': 'code,product_name,brands,image_url,nutriments,'
                  'nutriscore_grade,nova_group',
      },
    );
    
    if (response.statusCode == 404 || response.data == null) return null;
    
    final status = response.data!['status'] as int? ?? 0;
    if (status == 0) return null;
    
    final product = response.data!['product'] as Map<String, dynamic>?;
    if (product == null) return null;
    
    return _parseAndSaveProduct(product);
  }

  /// Parsea un producto de OFF y lo guarda en la DB local
  Future<Food?> _parseAndSaveProduct(Map<String, dynamic> product) async {
    final name = product['product_name'] as String? ?? 
                 product['generic_name'] as String? ?? '';
    if (name.isEmpty) return null;
    
    final code = product['code']?.toString() ?? '';
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    
    // Extraer kcal
    double kcal = 0;
    var kcalValue = nutriments['energy-kcal_100g'] ?? nutriments['energy_100g'];
    if (kcalValue != null) {
      kcal = (kcalValue is num) ? kcalValue.toDouble() : 0;
      if (kcal > 500 && nutriments['energy-kcal_100g'] == null) {
        kcal = kcal / 4.184; // Convertir kJ a kcal
      }
    }
    
    // Permitir productos sin kcal (se pueden editar después)
    // if (kcal <= 0) return null; // DESACTIVADO: permitir edición manual
    
    var brand = product['brands'] as String?;
    if (brand != null && brand.contains(',')) {
      brand = brand.split(',').first.trim();
    }
    
    // Verificar si ya existe en DB (primero por barcode, luego por nombre+marca)
    Food? existing;
    if (code.isNotEmpty) {
      existing = await (_db.select(_db.foods)
        ..where((f) => f.barcode.equals(code)))
        .getSingleOrNull();
    }
    
    // Si no hay barcode o no se encontró, buscar por nombre+marca (prevenir duplicados)
    if (existing == null) {
      final normName = name.toLowerCase().trim();
      final normBrand = brand?.toLowerCase().trim() ?? '';
      
      final candidates = await (_db.select(_db.foods)
        ..where((f) => f.normalizedName.equals(normName)))
        .get();
      
      // Buscar coincidencia exacta de marca
      for (final candidate in candidates) {
        final candidateBrand = candidate.brand?.toLowerCase().trim() ?? '';
        if (candidateBrand == normBrand) {
          existing = candidate;
          break;
        }
      }
    }
    
    final foodId = existing?.id ?? _uuid.v4();
    
    final companion = FoodsCompanion(
      id: Value(foodId),
      name: Value(name.trim()),
      normalizedName: Value(name.toLowerCase().trim()),
      brand: Value(brand),
      barcode: Value(code.isNotEmpty ? code : null),
      kcalPer100g: Value(kcal.round()),
      proteinPer100g: Value(_parseDouble(nutriments['proteins_100g'])),
      carbsPer100g: Value(_parseDouble(nutriments['carbohydrates_100g'])),
      fatPer100g: Value(_parseDouble(nutriments['fat_100g'])),
      userCreated: const Value(false),
      verifiedSource: const Value('openfoodfacts'),
      nutriScore: Value(product['nutriscore_grade'] as String?),
      novaGroup: Value(product['nova_group'] != null 
          ? int.tryParse(product['nova_group'].toString()) 
          : null),
      createdAt: Value(existing?.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    
    await _db.into(_db.foods).insertOnConflictUpdate(companion);
    
    // Actualizar índice FTS
    await _db.insertFoodFts(foodId, name.trim(), brand);
    
    // Retornar el alimento guardado
    return (_db.select(_db.foods)
      ..where((f) => f.id.equals(foodId)))
      .getSingle();
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }

  Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    _requestTimestamps.removeWhere((ts) => now.difference(ts).inMinutes >= 1);
    
    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      final oldest = _requestTimestamps.first;
      final waitTime = const Duration(minutes: 1) - now.difference(oldest);
      if (waitTime > Duration.zero) {
        await Future.delayed(waitTime);
      }
      return _waitForRateLimit();
    }
  }

  /// Cancela requests pendientes
  void cancelPendingRequests() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider del AlimentoRepository (búsqueda híbrida local + OFF)
final alimentoRepositoryProvider = Provider<AlimentoRepository>((ref) {
  return AlimentoRepository(ref.watch(appDatabaseProvider));
});
