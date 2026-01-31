import '../../data/datasources/food_search_local_datasource.dart';
import '../../data/datasources/food_search_remote_datasource.dart';
import '../../data/models/cached_search_result.dart';
import '../../domain/repositories/food_search_repository.dart';
import '../../domain/services/food_scoring_service.dart';

/// Implementación híbrida del repositorio de búsqueda
/// 
/// Estrategia de búsqueda:
/// 1. Buscar en alimentos locales (Drift) - instantáneo
/// 2. Buscar en cache de búsquedas - rápido
/// 3. Si online, buscar en API y actualizar cache
/// 4. Combinar, scorar y ordenar resultados
class FoodSearchRepositoryImpl implements FoodSearchRepository {
  final FoodSearchLocalDataSource _local;
  final FoodSearchRemoteDataSource _remote;
  final FoodScoringService _scoring;

  FoodSearchRepositoryImpl({
    required FoodSearchLocalDataSource local,
    required FoodSearchRemoteDataSource remote,
    required FoodScoringService scoring,
  })  : _local = local,
        _remote = remote,
        _scoring = scoring;

  @override
  Future<FoodSearchResult> search(
    String query, {
    int page = 1,
    int pageSize = 24,
    bool forceOffline = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final normalizedQuery = query.toLowerCase().trim();
    
    if (normalizedQuery.isEmpty) {
      return FoodSearchResult(
        items: const [],
        query: query,
        page: page,
        hasMore: false,
        source: SearchSource.local,
        searchTime: stopwatch.elapsed,
      );
    }

    // Fase 1: Búsqueda local (siempre)
    final localResults = await _searchLocal(normalizedQuery);
    
    // Fase 2: Buscar en cache
    final cachedResult = await _local.getCachedSearch(normalizedQuery);
    
    // Si estamos offline o forzamos offline, retornar solo cache
    if (forceOffline || !await isOnline) {
      final offlineItems = cachedResult?.items ?? [];
      final allItems = <CachedFoodItem>[];
      for (final item in localResults) {
        allItems.add(CachedFoodItem(
          code: item.id,
          name: item.name,
          brand: item.brand,
          kcalPer100g: 0, // Los locales no tienen este dato aquí
          fetchedAt: DateTime.now(),
        ));
      }
      allItems.addAll(offlineItems);
      final scored = _scoreAndRank(allItems, normalizedQuery);
      
      return FoodSearchResult(
        items: scored,
        query: query,
        page: page,
        hasMore: false,
        source: cachedResult != null ? SearchSource.cache : SearchSource.local,
        searchTime: stopwatch.elapsed,
      );
    }

    // Fase 3: Búsqueda en API (solo si page == 1 o no hay cache)
    List<CachedFoodItem> apiResults = [];
    bool hasMore = false;
    
    if (page == 1 || cachedResult == null) {
      try {
        final apiResult = await _remote.searchProducts(
          normalizedQuery,
          page: page,
          pageSize: pageSize,
          countryCode: 'es',
        );
        apiResults = apiResult.items;
        hasMore = apiResult.totalCount > (page * pageSize);
        
        // Guardar en cache
        await _local.cacheSearchResults(apiResult);
      } on NetworkException {
        // Fallback a cache si falla la API
        apiResults = cachedResult?.items ?? [];
        hasMore = false;
      }
    } else {
      // Usar cache existente
      apiResults = cachedResult.items;
      hasMore = cachedResult.totalCount > (page * pageSize);
    }

    // Fase 4: Combinar y scorar
    // Convertir locales a CachedFoodItem temporalmente
    final localItems = localResults.map((f) => CachedFoodItem(
      code: f.id,
      name: f.name,
      brand: f.brand,
      kcalPer100g: 0,
      fetchedAt: DateTime.now(),
    )).toList();
    final allItems = [...localItems, ...apiResults];
    final scored = _scoreAndRank(allItems, normalizedQuery);
    
    // Eliminar duplicados por código
    final seenCodes = <String>{};
    final uniqueItems = <ScoredFood>[];
    for (final item in scored) {
      if (!seenCodes.contains(item.food.id)) {
        seenCodes.add(item.food.id);
        uniqueItems.add(item);
      }
    }

    // Determinar fuente
    final source = cachedResult == null && apiResults.isNotEmpty
        ? SearchSource.api
        : SearchSource.hybrid;

    stopwatch.stop();
    
    return FoodSearchResult(
      items: uniqueItems.take(pageSize).toList(),
      query: query,
      page: page,
      hasMore: hasMore,
      source: source,
      searchTime: stopwatch.elapsed,
    );
  }

  /// Busca en alimentos locales y convierte a ScorableFood
  Future<List<ScorableFood>> _searchLocal(String query) async {
    final foods = await _local.searchLocalFoods(query, limit: 10);
    return foods.map((f) => ScorableFood(
      id: f.id,
      name: f.name,
      brand: f.brand,
      fetchedAt: f.updatedAt,
      // Los alimentos locales no tienen metadatos de OFF
      countriesTags: const [],
      storesTags: const [],
      metadata: {'source': 'local'},
    )).toList();
  }

  /// Convierte CachedFoodItem a ScorableFood y scora
  /// 
  /// Filtra productos con textScore < 0.3 (umbral mínimo de relevancia)
  List<ScoredFood> _scoreAndRank(List<CachedFoodItem> items, String query) {
    final scorable = items.map((item) => ScorableFood(
      id: item.code,
      name: item.name,
      brand: item.brand,
      countriesTags: item.countriesTags,
      storesTags: item.storesTags,
      nutriScore: item.nutriScore,
      novaGroup: item.novaGroup,
      fetchedAt: item.fetchedAt,
      metadata: {
        'imageUrl': item.imageUrl,
        'kcalPer100g': item.kcalPer100g,
        'proteinPer100g': item.proteinPer100g,
        'carbsPer100g': item.carbsPer100g,
        'fatPer100g': item.fatPer100g,
      },
    )).toList();

    final ranked = _scoring.rankProducts(scorable, query);
    
    // Filtrar por umbral mínimo de relevancia (textScore >= 0.3)
    // Esto elimina resultados irrelevantes que pueda devolver la API
    return ranked.where((scored) => scored.breakdown.textMatch >= 0.3).toList();
  }

  @override
  Future<ScoredFood?> searchByBarcode(String barcode) async {
    // Primero buscar en local
    final local = await _local.searchLocalFoods(barcode, limit: 1);
    if (local.isNotEmpty) {
      final food = local.first;
      return ScoredFood(
        food: ScorableFood(
          id: food.id,
          name: food.name,
          brand: food.brand,
          fetchedAt: food.updatedAt,
          metadata: {'source': 'local'},
        ),
        score: 1.0,
        breakdown: const ScoreBreakdown(
          textMatch: 1.0,
          availability: 1.0,
          quality: 0.5,
          freshness: 1.0,
          total: 1.0,
        ),
      );
    }

    // Buscar en API
    try {
      final item = await _remote.searchByBarcode(barcode);
      if (item == null) return null;

      final scorable = ScorableFood(
        id: item.code,
        name: item.name,
        brand: item.brand,
        countriesTags: item.countriesTags,
        storesTags: item.storesTags,
        nutriScore: item.nutriScore,
        novaGroup: item.novaGroup,
        fetchedAt: item.fetchedAt,
        metadata: {
          'imageUrl': item.imageUrl,
          'kcalPer100g': item.kcalPer100g,
        },
      );

      return _scoring.rankProducts([scorable], item.name).first;
    } on NetworkException {
      return null;
    }
  }

  @override
  Future<List<String>> getSuggestions(String prefix, {int maxResults = 8}) async {
    if (prefix.length < 2) return [];
    
    // Sugerencias de historial
    final recent = await _local.getRecentSearches(limit: maxResults);
    final suggestions = recent
        .where((s) => s.toLowerCase().startsWith(prefix.toLowerCase()))
        .toList();
    
    // Completar con populares si hace falta
    if (suggestions.length < maxResults) {
      final populares = _getPopularSuggestions(prefix);
      for (final p in populares) {
        if (!suggestions.contains(p) && suggestions.length < maxResults) {
          suggestions.add(p);
        }
      }
    }
    
    return suggestions;
  }

  List<String> _getPopularSuggestions(String prefix) {
    // Términos populares predefinidos
    final populares = [
      'pollo', 'arroz', 'pasta', 'yogur', 'leche', 'huevo',
      'manzana', 'plátano', 'pollo a la plancha', 'atún',
      'pan integral', 'avena', 'aceite de oliva',
    ];
    
    return populares
        .where((t) => t.toLowerCase().startsWith(prefix.toLowerCase()))
        .toList();
  }

  @override
  Future<List<String>> getRecentSearches({int limit = 10}) {
    return _local.getRecentSearches(limit: limit);
  }

  @override
  Future<void> saveSearch(String query) {
    return _local.saveSearch(query);
  }

  @override
  Future<void> clearHistory() {
    return _local.clearHistory();
  }

  @override
  Future<bool> get isOnline async {
    // TODO: Integrar con connectivity_plus para verificación real
    // Por ahora asumimos online, el fallback maneja errores de red
    return true;
  }
}
