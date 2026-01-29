import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_model.dart';
import '../models/open_food_facts_model.dart';
import '../services/food_cache_service.dart';
import '../services/open_food_facts_service.dart';

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

  @override
  ExternalSearchState build() {
    _apiService = ref.read(openFoodFactsServiceProvider);
    _cacheService = ref.read(foodCacheServiceProvider);
    _connectivity = Connectivity();
    
    // Inicializar en background
    _init();
    
    return const ExternalSearchState();
  }

  Future<void> _init() async {
    await _cacheService.initialize();
    await _loadRecentSearches();
    await _checkConnectivity();
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

  /// Búsqueda online (API)
  Future<void> _searchOnline(String query) async {
    // Intentar obtener de cache primero para mostrar rápido
    final cachedResults = await _cacheService.getCachedSearchResults(query);
    if (cachedResults != null && cachedResults.isNotEmpty) {
      // Mostrar cache mientras se actualiza
      state = state.copyWith(
        status: ExternalSearchStatus.loading,
        results: cachedResults,
      );
    }

    // Hacer petición a API
    final response = await _apiService.searchProducts(query, page: 1);

    // Guardar en cache
    if (response.products.isNotEmpty) {
      await _cacheService.cacheSearchResults(query, response.products);
    }

    // Actualizar estado
    if (response.products.isEmpty) {
      state = state.copyWith(
        status: ExternalSearchStatus.empty,
        results: const [],
        hasMore: false,
      );
    } else {
      state = state.copyWith(
        status: ExternalSearchStatus.success,
        results: response.products,
        hasMore: response.hasMore,
        page: 1,
      );
    }

    // Actualizar recientes
    await _loadRecentSearches();
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
