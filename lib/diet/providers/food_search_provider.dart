import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;

import '../../core/providers/database_provider.dart';
import '../../training/database/database.dart';
import '../repositories/alimento_repository.dart';
import 'habitual_food_provider.dart';

// ============================================================================
// ESTADO
// ============================================================================

/// Estados posibles de la búsqueda
enum SearchStatus { 
  idle,           // Sin búsqueda activa
  loading,        // Buscando (primera página)
  loadingMore,    // Cargando más resultados (paginación)
  success,        // Búsqueda exitosa con resultados
  error,          // Error en la búsqueda
  empty,          // Sin resultados (con sugerencias)
  offline,        // Modo offline con resultados locales
}

/// Estado completo de la búsqueda
class FoodSearchState {
  final SearchStatus status;
  final List<ScoredFood> results;
  final String? errorMessage;
  final String query;
  final int page;
  final bool hasMore;
  final bool isOnline;
  
  // Para estado "sin resultados" inteligente
  final List<String> suggestions;
  final List<Food> popularAlternatives;
  final bool showCreateCustom;

  const FoodSearchState({
    this.status = SearchStatus.idle,
    this.results = const [],
    this.errorMessage,
    this.query = '',
    this.page = 1,
    this.hasMore = true,
    this.isOnline = true,
    this.suggestions = const [],
    this.popularAlternatives = const [],
    this.showCreateCustom = false,
  });

  FoodSearchState copyWith({
    SearchStatus? status,
    List<ScoredFood>? results,
    String? errorMessage,
    String? query,
    int? page,
    bool? hasMore,
    bool? isOnline,
    List<String>? suggestions,
    List<Food>? popularAlternatives,
    bool? showCreateCustom,
  }) {
    return FoodSearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: errorMessage,
      query: query ?? this.query,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isOnline: isOnline ?? this.isOnline,
      suggestions: suggestions ?? this.suggestions,
      popularAlternatives: popularAlternatives ?? this.popularAlternatives,
      showCreateCustom: showCreateCustom ?? this.showCreateCustom,
    );
  }

  bool get isLoading => status == SearchStatus.loading;
  bool get isLoadingMore => status == SearchStatus.loadingMore;
  bool get hasResults => results.isNotEmpty;
  
  /// Obtiene los resultados como lista de Food (desempaqueta ScoredFood)
  List<Food> get foods => results.map((r) => r.food).toList();
}

// ============================================================================
// NOTIFIER PRINCIPAL
// ============================================================================

/// Notifier principal para búsqueda de alimentos
class FoodSearchNotifier extends rp.Notifier<FoodSearchState> {
  Timer? _debounceTimer;
  CancelToken? _cancelToken;
  
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  FoodSearchState build() {
    // Cleanup al dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _cancelToken?.cancel();
    });

    return const FoodSearchState();
  }

  /// Inicia una búsqueda con debounce
  void search(String query, {bool forceOffline = false}) {
    // Cancelar timer y request previos
    _debounceTimer?.cancel();
    _cancelToken?.cancel();

    if (query.trim().isEmpty) {
      state = const FoodSearchState();
      return;
    }

    // Estado de "escribiendo" inmediato
    state = state.copyWith(
      status: SearchStatus.loading,
      query: query.trim(),
      results: const [],
      suggestions: const [],
      popularAlternatives: const [],
      showCreateCustom: false,
      page: 1,
      hasMore: true,
    );

    // Debounce de 300ms con check de mounted para evitar crash si provider disposed
    _debounceTimer = Timer(_debounceDuration, () async {
      if (!ref.mounted) return; // Evitar acceso a provider disposed
      await _performSearch(query.trim(), forceOffline: forceOffline);
    });
  }

  /// Ejecuta la búsqueda real
  Future<void> _performSearch(String query, {bool forceOffline = false}) async {
    _cancelToken = CancelToken();
    
    try {
      final repository = ref.read(alimentoRepositoryProvider);
      
      // Realizar búsqueda híbrida
      final results = await repository.search(
        query,
        limit: 50,
        includeRemote: !forceOffline,
      );

      if (results.isEmpty) {
        // Sin resultados - generar sugerencias inteligentes
        await _handleEmptyResults(query);
      } else {
        state = state.copyWith(
          status: SearchStatus.success,
          results: results,
          hasMore: results.length >= 50,
          page: 1,
          suggestions: const [],
          popularAlternatives: const [],
          showCreateCustom: false,
        );
      }

      // Guardar en historial
      await repository.recordSearch(query, hasResults: results.isNotEmpty);
      
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // Fue cancelado, no hacer nada
        return;
      }
      
      // Error de red - intentar offline
      await _tryOfflineFallback(query);
    } catch (e) {
      // Error general - intentar offline
      await _tryOfflineFallback(query);
    }
  }

  /// Maneja el caso de búsqueda sin resultados
  Future<void> _handleEmptyResults(String query) async {
    final repository = ref.read(alimentoRepositoryProvider);
    
    // Generar sugerencias basadas en términos similares
    final suggestions = await _generateSuggestions(query);
    
    // Buscar alternativas populares
    final alternatives = await repository.getHabitualFoods(limit: 5);

    state = state.copyWith(
      status: SearchStatus.empty,
      results: const [],
      hasMore: false,
      suggestions: suggestions,
      popularAlternatives: alternatives,
      showCreateCustom: true,
    );
  }

  /// Intenta fallback offline cuando falla la búsqueda online
  Future<void> _tryOfflineFallback(String query) async {
    try {
      final repository = ref.read(alimentoRepositoryProvider);
      final offlineResults = await repository.searchOffline(query, limit: 50);
      
      if (offlineResults.isNotEmpty) {
        final scored = offlineResults.map((f) => ScoredFood(
          food: f, 
          score: 0,
          isFromCache: true,
        )).toList();
        
        state = state.copyWith(
          status: SearchStatus.offline,
          results: scored,
          errorMessage: 'Sin conexión. Mostrando resultados guardados.',
          showCreateCustom: true,
        );
      } else {
        state = state.copyWith(
          status: SearchStatus.error,
          errorMessage: 'Error de búsqueda. Sin resultados guardados.',
          showCreateCustom: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: 'Error de búsqueda: $e',
        showCreateCustom: true,
      );
    }
  }

  /// Genera sugerencias de queries similares
  Future<List<String>> _generateSuggestions(String query) async {
    final suggestions = <String>[];
    final lowerQuery = query.toLowerCase().trim();
    final terms = lowerQuery.split(' ');
    
    // Sugerir términos más genéricos
    if (terms.length > 1) {
      suggestions.add(terms.first);
    }
    
    // Buscar en historial queries similares
    final repository = ref.read(alimentoRepositoryProvider);
    final historySuggestions = await repository.getSuggestions(lowerQuery, limit: 3);
    suggestions.addAll(historySuggestions);
    
    return suggestions.take(3).toList();
  }

  /// Carga más resultados (paginación)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.query.isEmpty) {
      return;
    }

    state = state.copyWith(status: SearchStatus.loadingMore);

    try {
      final repository = ref.read(alimentoRepositoryProvider);
      
      // Nota: La paginación real requeriría offset en el repository
      // Por ahora simplemente indicamos que no hay más
      final moreResults = await repository.search(
        state.query,
        limit: 50,
        includeRemote: state.isOnline,
      );

      // Filtrar solo nuevos resultados
      final existingIds = state.results.map((r) => r.food.id).toSet();
      final newResults = moreResults.where((r) => !existingIds.contains(r.food.id)).toList();

      if (newResults.isEmpty) {
        state = state.copyWith(
          status: SearchStatus.success,
          hasMore: false,
        );
      } else {
        state = state.copyWith(
          status: SearchStatus.success,
          results: [...state.results, ...newResults],
          hasMore: newResults.length >= 50,
          page: state.page + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SearchStatus.success,
        hasMore: false,
      );
    }
  }

  /// Sugerencias de autocompletado (sin debounce, para UI responsiva)
  Future<List<String>> getAutocompleteSuggestions(String prefix) async {
    if (prefix.length < 2) return [];
    
    final repository = ref.read(alimentoRepositoryProvider);
    return repository.getSuggestions(prefix, limit: 8);
  }

  /// Seleccionar un alimento (actualiza estadísticas)
  Future<void> selectFood(String foodId, {MealType? mealType}) async {
    final repository = ref.read(alimentoRepositoryProvider);
    await repository.recordSelection(foodId, mealType: mealType);

    // Guardar en historial que se seleccionó este alimento para la query actual
    if (state.query.isNotEmpty) {
      await repository.recordSearch(state.query, selectedFoodId: foodId);
    }

    // Invalidar providers dependientes para refrescar sugerencias
    ref.invalidate(habitualFoodProvider);
  }

  /// Limpiar búsqueda actual
  void clear() {
    _debounceTimer?.cancel();
    _cancelToken?.cancel();
    state = const FoodSearchState();
  }

  /// Fuerza una búsqueda inmediata sin debounce
  Future<void> searchImmediate(String query) async {
    _debounceTimer?.cancel();
    await _performSearch(query);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider principal de búsqueda de alimentos
final foodSearchProvider = rp.NotifierProvider<FoodSearchNotifier, FoodSearchState>(
  FoodSearchNotifier.new,
);

/// Notifier simple para el query de búsqueda
class SearchQueryNotifier extends rp.Notifier<String> {
  @override
  String build() => '';
  void setQuery(String value) => state = value;
}

/// Provider del query de búsqueda (para sincronización con UI)
final searchQueryProvider = rp.NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Notifier simple para filtros
class SearchFiltersNotifier extends rp.Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();
  set filters(SearchFilters value) => state = value;
}

/// Provider de filtros de búsqueda
final searchFiltersProvider = rp.NotifierProvider<SearchFiltersNotifier, SearchFilters>(
  SearchFiltersNotifier.new,
);

/// Sugerencias predictivas basadas en hora/contexto
final predictiveFoodsProvider = rp.Provider<Future<List<Food>>>((ref) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.getHabitualFoods(
    dateTime: DateTime.now(),
    limit: 10,
  );
});

/// Historial de búsquedas recientes
final recentSearchesProvider = rp.Provider<Future<List<String>>>((ref) async {
  final db = ref.read(appDatabaseProvider);
  
  final historial = await (db.select(db.searchHistory)
    ..orderBy([(h) => OrderingTerm.desc(h.searchedAt)])
    ..limit(20))
    .get();
  
  // Eliminar duplicados manteniendo orden
  return historial.map((h) => h.query).toSet().toList();
});

/// Alimentos favoritos/más usados
final favoriteFoodsProvider = rp.Provider<Future<List<Food>>>((ref) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.getMostPopular(limit: 10);
});

// ============================================================================
// EXTENSIONES
// ============================================================================

/// Extensiones útiles para trabajar con SearchStatus
extension SearchStatusExtension on SearchStatus {
  bool get isLoading => this == SearchStatus.loading || this == SearchStatus.loadingMore;
  bool get hasError => this == SearchStatus.error;
  bool get isEmptyState => this == SearchStatus.empty;
  bool get isOffline => this == SearchStatus.offline;
}
