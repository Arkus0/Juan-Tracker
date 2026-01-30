import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_model.dart';
import '../models/open_food_facts_model.dart';
import '../services/food_cache_service.dart';
import '../services/food_search_expander.dart';
import '../services/food_search_index.dart';
import '../services/open_food_facts_service.dart';

/// Clase auxiliar para resultados con scoring
class _ScoredResult {
  final OpenFoodFactsResult result;
  final double score;
  
  _ScoredResult(this.result, this.score);
}

/// Estados posibles de la búsqueda
enum ExternalSearchStatus {
  idle,
  loading,
  loadingMore,
  success,
  error,
  offline,
  empty,
}

/// Estado completo de la búsqueda externa
class ExternalSearchState {
  final ExternalSearchStatus status;
  final List<OpenFoodFactsResult> results;
  final String? errorMessage;
  final String query;
  final int page;
  final bool hasMore;
  final bool isOnline;
  final List<String> recentSearches;
  final List<OpenFoodFactsResult> offlineSuggestions;

  const ExternalSearchState({
    this.status = ExternalSearchStatus.idle,
    this.results = const [],
    this.errorMessage,
    this.query = '',
    this.page = 1,
    this.hasMore = false,
    this.isOnline = true,
    this.recentSearches = const [],
    this.offlineSuggestions = const [],
  });

  ExternalSearchState copyWith({
    ExternalSearchStatus? status,
    List<OpenFoodFactsResult>? results,
    String? errorMessage,
    String? query,
    int? page,
    bool? hasMore,
    bool? isOnline,
    List<String>? recentSearches,
    List<OpenFoodFactsResult>? offlineSuggestions,
  }) {
    return ExternalSearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: errorMessage,
      query: query ?? this.query,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isOnline: isOnline ?? this.isOnline,
      recentSearches: recentSearches ?? this.recentSearches,
      offlineSuggestions: offlineSuggestions ?? this.offlineSuggestions,
    );
  }

  bool get isLoading => status == ExternalSearchStatus.loading;
  bool get isLoadingMore => status == ExternalSearchStatus.loadingMore;
  bool get hasError => status == ExternalSearchStatus.error;
  bool get isOfflineMode => status == ExternalSearchStatus.offline;
  bool get isEmpty => status == ExternalSearchStatus.empty;
  bool get isSuccess => status == ExternalSearchStatus.success;
}

/// Notifier que maneja la búsqueda de alimentos externos
/// 
/// Flujo:
/// 1. Verifica conectividad
/// 2. Si online: busca en API + guarda en cache
/// 3. Si offline: busca en cache local
/// 4. Muestra estados apropiados en UI
class ExternalFoodSearchNotifier extends Notifier<ExternalSearchState> {
  late final OpenFoodFactsService _apiService;
  late final FoodCacheService _cacheService;
  late final Connectivity _connectivity;
  late final FoodSearchExpander _searchExpander;
  late final FoodSearchIndex _searchIndex;

  @override
  ExternalSearchState build() {
    _apiService = ref.read(openFoodFactsServiceProvider);
    _cacheService = ref.read(foodCacheServiceProvider);
    _connectivity = Connectivity();
    _searchExpander = FoodSearchExpander();
    _searchIndex = FoodSearchIndex();

    // Inicializar en background
    _init();

    return const ExternalSearchState();
  }

  Future<void> _init() async {
    await _cacheService.initialize();
    await _loadRecentSearches();
    await _checkConnectivity();
    await _rebuildSearchIndex();
  }

  /// Reconstruye el índice de búsqueda local
  Future<void> _rebuildSearchIndex() async {
    // Indexar alimentos guardados
    final savedFoods = await _cacheService.getSavedExternalFoods();
    _searchIndex.indexLocalFoods(savedFoods);

    // Indexar cache de búsquedas
    final recentSearches = await _cacheService.getRecentSearches();
    final allCached = <OpenFoodFactsResult>[];
    for (final query in recentSearches.take(10)) {
      final results = await _cacheService.getCachedSearchResults(query);
      if (results != null) {
        allCached.addAll(results);
      }
    }
    _searchIndex.indexCachedExternalFoods(allCached);
  }

  /// Verifica el estado de conectividad
  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    // En connectivity_plus 6.x, checkConnectivity retorna List<ConnectivityResult>
    final isOnline = result.isNotEmpty && 
        !result.every((r) => r == ConnectivityResult.none);
    state = state.copyWith(isOnline: isOnline);
  }

  /// Carga los términos de búsqueda recientes
  Future<void> _loadRecentSearches() async {
    final recent = await _cacheService.getRecentSearches();
    state = state.copyWith(recentSearches: recent);
  }

  /// Realiza una búsqueda nueva
  Future<void> search(String query, {bool forceOffline = false}) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        status: ExternalSearchStatus.idle,
        results: const [],
        query: '',
        errorMessage: null,
      );
      return;
    }

    // Verificar conectividad
    await _checkConnectivity();
    final isOnline = state.isOnline && !forceOffline;

    // Establecer estado de carga
    state = state.copyWith(
      status: ExternalSearchStatus.loading,
      query: query.trim(),
      page: 1,
      errorMessage: null,
    );

    try {
      if (isOnline) {
        await _searchOnline(query.trim());
      } else {
        await _searchOffline(query.trim());
      }
    } on OpenFoodFactsException catch (e) {
      // Error de API - intentar fallback offline
      final offlineResults = await _cacheService.searchOffline(query.trim());
      
      if (offlineResults.isNotEmpty) {
        state = state.copyWith(
          status: ExternalSearchStatus.offline,
          results: offlineResults,
          offlineSuggestions: offlineResults,
          errorMessage: '${e.message}\nMostrando resultados guardados.',
        );
      } else {
        state = state.copyWith(
          status: ExternalSearchStatus.error,
          errorMessage: e.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ExternalSearchStatus.error,
        errorMessage: 'Error inesperado: $e',
      );
    }
  }

  /// Búsqueda híbrida: local primero, API después
  Future<void> _searchOnline(String query) async {
    // PASO 1: Búsqueda INSTANTÁNEA en índice local
    final localResults = _searchIndex.search(query, maxResults: 10);
    
    if (localResults.isNotEmpty) {
      // Convertir a OpenFoodFactsResult para mostrar inmediatamente
      final instantResults = localResults
          .where((r) => r.externalFood != null)
          .map((r) => r.externalFood!)
          .toList();
      
      if (instantResults.isNotEmpty) {
        state = state.copyWith(
          status: ExternalSearchStatus.loading,
          results: instantResults,
        );
      }
    }

    // PASO 2: Verificar cache persistente
    final cachedResults = await _cacheService.getCachedSearchResults(query);
    if (cachedResults != null && cachedResults.isNotEmpty) {
      // Merge con resultados locales y mostrar
      final mergedResults = _mergeResults(
        state.results,
        cachedResults,
        query,
      );
      
      state = state.copyWith(
        status: ExternalSearchStatus.loading,
        results: mergedResults,
      );
    }

    // PASO 3: Llamar a API Open Food Facts
    final response = await _apiService.searchProducts(query, page: 1);

    // PASO 4: Filtrar y ordenar resultados
    final filteredProducts = _filterRelevantResults(response.products, query);

    // PASO 5: Merge final (API + local + cache)
    final finalResults = _mergeResults(
      state.results,
      filteredProducts,
      query,
    );

    // PASO 6: Guardar en cache y actualizar índice
    if (filteredProducts.isNotEmpty) {
      await _cacheService.cacheSearchResults(query, filteredProducts);
      for (final product in filteredProducts.take(10)) {
        _searchIndex.addExternalFood(product);
      }
    }

    // PASO 7: Actualizar estado final
    if (finalResults.isEmpty) {
      state = state.copyWith(
        status: ExternalSearchStatus.empty,
        results: const [],
        hasMore: false,
      );
    } else {
      state = state.copyWith(
        status: ExternalSearchStatus.success,
        results: finalResults,
        hasMore: response.hasMore,
        page: 1,
      );
    }

    await _loadRecentSearches();
  }

  /// Combina resultados de múltiples fuentes sin duplicados
  List<OpenFoodFactsResult> _mergeResults(
    List<OpenFoodFactsResult> existing,
    List<OpenFoodFactsResult> newResults,
    String query,
  ) {
    final seenCodes = <String>{};
    final merged = <OpenFoodFactsResult>[];
    
    // Primero añadir existentes
    for (final r in existing) {
      if (!seenCodes.contains(r.code)) {
        seenCodes.add(r.code);
        merged.add(r);
      }
    }
    
    // Luego nuevos resultados
    for (final r in newResults) {
      if (!seenCodes.contains(r.code)) {
        seenCodes.add(r.code);
        merged.add(r);
      }
    }
    
    // Reordenar por relevancia
    return _filterRelevantResults(merged, query);
  }

  /// Búsqueda offline (cache local)
  Future<void> _searchOffline(String query) async {
    final results = await _cacheService.searchOffline(query);

    if (results.isEmpty) {
      state = state.copyWith(
        status: ExternalSearchStatus.offline,
        results: const [],
        errorMessage: 'Sin conexión y no hay resultados guardados para "$query"',
      );
    } else {
      state = state.copyWith(
        status: ExternalSearchStatus.offline,
        results: results,
        offlineSuggestions: results,
        hasMore: false,
      );
    }
  }

  /// Carga más resultados (paginación)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || !state.isOnline) {
      return;
    }

    state = state.copyWith(status: ExternalSearchStatus.loadingMore);

    try {
      final nextPage = state.page + 1;
      final response = await _apiService.searchProducts(
        state.query,
        page: nextPage,
      );

      final allResults = [...state.results, ...response.products];

      state = state.copyWith(
        status: ExternalSearchStatus.success,
        results: allResults,
        page: nextPage,
        hasMore: response.hasMore,
      );
    } on OpenFoodFactsException {
      state = state.copyWith(
        status: ExternalSearchStatus.success, // Mantener resultados actuales
        hasMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: ExternalSearchStatus.success,
        hasMore: false,
      );
    }
  }

  /// Busca por código de barras
  Future<OpenFoodFactsResult?> searchByBarcode(String barcode) async {
    await _checkConnectivity();

    if (!state.isOnline) {
      // Buscar en cache local
      final offlineResults = await _cacheService.searchOffline(barcode);
      for (final r in offlineResults) {
        if (r.code == barcode) {
          return r;
        }
      }
      return null;
    }

    try {
      final result = await _apiService.searchByBarcode(barcode);
      if (result != null) {
        // Guardar en cache
        await _cacheService.cacheSearchResults(barcode, [result]);
      }
      return result;
    } on OpenFoodFactsException {
      // Fallback a cache
      final offlineResults = await _cacheService.searchOffline(barcode);
      for (final r in offlineResults) {
        if (r.code == barcode) {
          return r;
        }
      }
      return null;
    }
  }

  /// Guarda un alimento externo en la biblioteca local
  /// Retorna el FoodModel creado
  Future<FoodModel> saveToLocalLibrary(OpenFoodFactsResult result) async {
    // Guardar en cache permanente
    final food = await _cacheService.saveExternalFood(result);

    return food;
  }

  /// Selecciona un alimento reciente
  void selectRecentSearch(String query) {
    search(query);
  }

  /// Limpia la búsqueda actual
  void clear() {
    state = const ExternalSearchState();
    _loadRecentSearches();
  }

  /// Establece el estado a loading (para casos como búsqueda por barcode)
  void setLoading(String query) {
    state = state.copyWith(
      status: ExternalSearchStatus.loading,
      query: query,
      errorMessage: null,
    );
  }

  /// Limpia el historial de búsquedas
  Future<void> clearHistory() async {
    await _cacheService.clearRecentSearches();
    await _cacheService.clearSearchCache();
    await _loadRecentSearches();
  }

  /// Filtra y ordena resultados por relevancia usando scoring
  /// 
  /// Algoritmo tipo "search engine":
  /// - Cada resultado recibe un score basado en coincidencias
  /// - Resultados se ordenan por score descendente
  /// - Mantiene todos los resultados relevantes, no limita artificialmente
  List<OpenFoodFactsResult> _filterRelevantResults(
    List<OpenFoodFactsResult> results,
    String query,
  ) {
    final queryLower = query.toLowerCase().trim();
    final queryWords = queryLower
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toList();
    
    // Si no hay palabras significativas, devolver todo sin ordenar
    if (queryWords.isEmpty) return results;
    
    // Scoring de resultados
    final scoredResults = <_ScoredResult>[];
    
    for (final product in results) {
      final nameLower = product.name.toLowerCase();
      final brandLower = (product.brand ?? '').toLowerCase();
      final nameWords = nameLower.split(RegExp(r'\s+'));

      // Calcular relevancia española (bonus por marcas españolas, penalización procesados)
      final spanishScore = _searchExpander.calculateSpanishRelevance(
        product.name,
        product.brand,
        query,
      );

      double score = spanishScore;
      int matchedWords = 0;
      
      for (final queryWord in queryWords) {
        // Coincidencia exacta del nombre completo (máximo puntaje)
        if (nameLower == queryLower) {
          score += 1000;
          matchedWords++;
          continue;
        }
        
        // Coincidencia exacta de una palabra
        if (nameWords.contains(queryWord)) {
          score += 100;
          matchedWords++;
          continue;
        }
        
        // Coincidencia al inicio del nombre
        if (nameLower.startsWith(queryWord)) {
          score += 80;
          matchedWords++;
          continue;
        }
        
        // Coincidencia al inicio de alguna palabra del nombre
        if (nameWords.any((w) => w.startsWith(queryWord))) {
          score += 60;
          matchedWords++;
          continue;
        }
        
        // Coincidencia parcial en el nombre
        if (nameLower.contains(queryWord)) {
          score += 40;
          matchedWords++;
          continue;
        }
        
        // Coincidencia en la marca
        if (brandLower.contains(queryWord)) {
          score += 30;
          matchedWords++;
          continue;
        }
        
        // Fuzzy matching: distancia de edición <= 1 para palabras cortas
        if (queryWord.length <= 5) {
          for (final nameWord in nameWords) {
            if (_levenshteinDistance(queryWord, nameWord) <= 1) {
              score += 20;
              matchedWords++;
              break;
            }
          }
        }
      }
      
      // Bonus por múltiples coincidencias
      if (matchedWords > 1) {
        score *= (1 + (matchedWords - 1) * 0.5); // +50% por cada palabra extra
      }
      
      // Bonus por datos nutricionales completos
      if (product.hasValidNutrition) {
        score *= 1.1;
      }

      // Bonus por tener imagen
      if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        score *= 1.05;
      }

      // Solo incluir si tiene alguna coincidencia significativa
      if (score > 10) {
        scoredResults.add(_ScoredResult(product, score));
      }
    }
    
    // Ordenar por score descendente
    scoredResults.sort((a, b) => b.score.compareTo(a.score));
    
    return scoredResults.map((s) => s.result).toList();
  }
  
  /// Calcula la distancia de Levenshtein entre dos strings
  /// Usado para fuzzy matching (detectar errores ortográficos simples)
  int _levenshteinDistance(String s1, String s2) {
    if (s1.length < s2.length) return _levenshteinDistance(s2, s1);
    if (s2.isEmpty) return s1.length;
    
    List<int> prev = List.generate(s2.length + 1, (i) => i);
    List<int> curr = List.filled(s2.length + 1, 0);
    
    for (int i = 0; i < s1.length; i++) {
      curr[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final cost = (s1[i] == s2[j]) ? 0 : 1;
        curr[j + 1] = [
          curr[j] + 1,      // inserción
          prev[j + 1] + 1,  // eliminación
          prev[j] + cost,   // sustitución
        ].reduce((a, b) => a < b ? a : b);
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    
    return prev[s2.length];
  }
  
  /// Obtiene sugerencias offline basadas en búsquedas previas
  Future<void> loadOfflineSuggestions() async {
    final allCached = <OpenFoodFactsResult>[];
    final seenCodes = <String>{};

    // Obtener todas las búsquedas cacheadas
    final recent = await _cacheService.getRecentSearches();
    for (final query in recent.take(5)) {
      final results = await _cacheService.getCachedSearchResults(query);
      if (results != null) {
        for (final r in results) {
          if (!seenCodes.contains(r.code)) {
            allCached.add(r);
            seenCodes.add(r.code);
          }
        }
      }
    }

    // Obtener alimentos guardados
    final saved = await _cacheService.getSavedExternalFoods();
    for (final food in saved) {
      if (food.barcode != null && !seenCodes.contains(food.barcode)) {
        allCached.add(OpenFoodFactsResult(
          code: food.barcode!,
          name: food.name,
          brand: food.brand,
          kcalPer100g: food.kcalPer100g.toDouble(),
          proteinPer100g: food.proteinPer100g,
          carbsPer100g: food.carbsPer100g,
          fatPer100g: food.fatPer100g,
          portionName: food.portionName,
          portionGrams: food.portionGrams,
          fetchedAt: food.updatedAt,
        ));
        seenCodes.add(food.barcode!);
      }
    }

    state = state.copyWith(offlineSuggestions: allCached.take(20).toList());
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider del servicio de API
final openFoodFactsServiceProvider = Provider<OpenFoodFactsService>((ref) {
  return OpenFoodFactsService();
});

/// Provider del servicio de cache
final foodCacheServiceProvider = Provider<FoodCacheService>((ref) {
  return FoodCacheService();
});

/// Provider del notifier de búsqueda externa
final externalFoodSearchProvider =
    NotifierProvider<ExternalFoodSearchNotifier, ExternalSearchState>(
  ExternalFoodSearchNotifier.new,
);
