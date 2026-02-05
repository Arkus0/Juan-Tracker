import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
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
  idle, // Sin búsqueda activa
  loading, // Buscando (primera página)
  loadingMore, // Cargando más resultados (paginación)
  success, // Búsqueda exitosa con resultados
  error, // Error en la búsqueda
  empty, // Sin resultados (con sugerencias)
  offline, // Modo offline con resultados locales
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
  // OPT-1: Debounce solo para búsqueda online, no local
  // La búsqueda local FTS5 es ~5ms, no necesita debounce
  Timer? _onlineDebounceTimer;
  CancelToken? _cancelToken;
  int _searchVersion = 0;

  // Debounce solo aplicado a búsqueda online (más lenta)
  // ignore: unused_field - Reservado para implementación futura de debounce en searchOnline()
  static const _onlineDebounceDuration = Duration(milliseconds: 300);

  // Minimum query length for DB search (short queries show recents)
  static const _minQueryLength = 3;

  @override
  FoodSearchState build() {
    // Cleanup al dispose
    ref.onDispose(() {
      _onlineDebounceTimer?.cancel();
      _cancelToken?.cancel();
    });

    return const FoodSearchState();
  }

  /// Inicia una búsqueda LOCAL **instantánea** (sin debounce)
  ///
  /// OPT-1 PERFORMANCE: Búsqueda FTS5 es ~5ms, no necesita debounce.
  /// Esto reduce TTFR de ~160ms a ~30ms (6x más rápido).
  ///
  /// Para buscar en internet, usar `searchOnline()` después.
  ///
  /// OPTIMIZATION: Short queries (<3 chars) don't scan DB.
  /// Instead, we show recents/frequent foods.
  void search(String query) {
    // Cancelar request online previo si existe
    _cancelToken?.cancel();

    final trimmed = query.trim();
    final version = ++_searchVersion;

    if (trimmed.isEmpty) {
      state = const FoodSearchState();
      return;
    }

    // SHORT QUERY POLICY: < 3 chars → show recents, no DB scan
    // This is critical for performance on large DBs
    if (trimmed.length < _minQueryLength) {
      _handleShortQuery(trimmed, version);
      return;
    }

    // Estado de "buscando" inmediato
    state = state.copyWith(
      status: SearchStatus.loading,
      query: trimmed,
      suggestions: const [],
      popularAlternatives: const [],
      showCreateCustom: false,
      page: 1,
      hasMore: true,
    );

    // OPT-1: Ejecutar búsqueda local INMEDIATAMENTE (sin debounce)
    // FTS5 indexado es O(log n), ~5ms para 600k productos
    _performSearchImmediate(trimmed, version);
  }

  /// Ejecuta búsqueda local sin debounce (fire-and-forget async)
  void _performSearchImmediate(String query, int version) {
    // Usar unawaited para no bloquear, pero manejar errores
    Future(() async {
      if (!ref.mounted || version != _searchVersion) return;
      await _performSearch(query, version);
    });
  }

  /// Handles short queries (< 3 chars) by showing recents
  /// without scanning the full database
  Future<void> _handleShortQuery(String query, int version) async {
    if (!ref.mounted || version != _searchVersion) return;

    state = state.copyWith(
      query: query,
      status: SearchStatus.idle,
      results: const [],
      suggestions: const ['Escribe 3+ caracteres para buscar'],
      showCreateCustom: false,
    );

    // Show recent/frequent foods as alternatives
    try {
      final repository = ref.read(alimentoRepositoryProvider);
      final recents = await repository.getRecentlyUsed(limit: 10);

      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(popularAlternatives: recents);
    } catch (e) {
      debugPrint('[FoodSearch] Error loading recents for short query: $e');
    }
  }

  /// Ejecuta la búsqueda real (solo LOCAL - instantánea)
  Future<void> _performSearch(String query, int version) async {
    try {
      final repository = ref.read(alimentoRepositoryProvider);

      // Búsqueda LOCAL instantánea (FTS5)
      final results = await repository.search(query, limit: 50);
      if (!ref.mounted || version != _searchVersion) return;

      if (results.isEmpty) {
        // Sin resultados - generar sugerencias inteligentes
        await _handleEmptyResults(query, version);
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

      // Guardar en historial (fire-and-forget, no afecta la búsqueda)
      repository.recordSearch(query, hasResults: results.isNotEmpty).catchError(
        (e) {
          debugPrint('[FoodSearch] Error recording search: $e');
        },
      );
    } catch (e) {
      debugPrint('[FoodSearch] Search error: $e');
      state = state.copyWith(
        status: SearchStatus.error,
        errorMessage: 'Error de búsqueda: $e',
        showCreateCustom: true,
      );
    }
  }

  /// Búsqueda ONLINE en Open Food Facts (acción explícita del usuario)
  ///
  /// Llamar cuando el usuario pulsa "Buscar en internet"
  Future<void> searchOnline() async {
    final query = state.query;
    if (query.isEmpty) return;

    // Cancelar búsqueda anterior
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    // Marcar como cargando pero mantener resultados actuales
    state = state.copyWith(status: SearchStatus.loading);

    try {
      final repository = ref.read(alimentoRepositoryProvider);

      // Búsqueda en Open Food Facts
      final onlineResults = await repository.searchOnline(
        query,
        limit: 30,
        cancelToken: _cancelToken,
      );

      if (onlineResults.isEmpty) {
        // No encontró nada en OFF
        state = state.copyWith(
          status: state.results.isEmpty
              ? SearchStatus.empty
              : SearchStatus.success,
          showCreateCustom: true,
        );
      } else {
        // Combinar con resultados existentes (sin duplicados)
        final existingIds = state.results.map((r) => r.food.id).toSet();
        final newResults = onlineResults
            .where((r) => !existingIds.contains(r.food.id))
            .toList();

        state = state.copyWith(
          status: SearchStatus.success,
          results: [...state.results, ...newResults],
          hasMore: false,
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;

      state = state.copyWith(
        status: state.results.isEmpty
            ? SearchStatus.error
            : SearchStatus.success,
        errorMessage: 'Error de conexión',
      );
    } catch (e) {
      debugPrint('[FoodSearch] Online search error: $e');
      state = state.copyWith(
        status: state.results.isEmpty
            ? SearchStatus.error
            : SearchStatus.success,
        errorMessage: 'Error al buscar en internet',
      );
    }
  }

  /// Maneja el caso de búsqueda sin resultados
  Future<void> _handleEmptyResults(String query, int version) async {
    try {
      if (!ref.mounted || version != _searchVersion) return;

      final repository = ref.read(alimentoRepositoryProvider);

      // Generar sugerencias basadas en términos similares
      final suggestions = await _generateSuggestions(query);
      if (!ref.mounted || version != _searchVersion) return;

      // Buscar alternativas populares
      final alternatives = await repository.getHabitualFoods(limit: 5);
      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(
        status: SearchStatus.empty,
        results: const [],
        hasMore: false,
        suggestions: suggestions,
        popularAlternatives: alternatives,
        showCreateCustom: true,
      );
    } catch (e) {
      debugPrint('[FoodSearch] Error handling empty results: $e');
      // Simplemente mostrar vacío sin sugerencias
      state = state.copyWith(
        status: SearchStatus.empty,
        results: const [],
        hasMore: false,
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
    final historySuggestions = await repository.getSuggestions(
      lowerQuery,
      limit: 3,
    );
    suggestions.addAll(historySuggestions);

    return suggestions.take(3).toList();
  }

  /// Carga más resultados (paginación local)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.query.isEmpty) {
      return;
    }

    state = state.copyWith(status: SearchStatus.loadingMore);

    try {
      final repository = ref.read(alimentoRepositoryProvider);

      // Nota: La paginación real requeriría offset en el repository
      // Por ahora simplemente indicamos que no hay más
      final moreResults = await repository.search(state.query, limit: 50);

      // Filtrar solo nuevos resultados
      final existingIds = state.results.map((r) => r.food.id).toSet();
      final newResults = moreResults
          .where((r) => !existingIds.contains(r.food.id))
          .toList();

      if (newResults.isEmpty) {
        state = state.copyWith(status: SearchStatus.success, hasMore: false);
      } else {
        state = state.copyWith(
          status: SearchStatus.success,
          results: [...state.results, ...newResults],
          hasMore: newResults.length >= 50,
          page: state.page + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(status: SearchStatus.success, hasMore: false);
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
    _searchVersion++;
    _onlineDebounceTimer?.cancel();
    _cancelToken?.cancel();
    state = const FoodSearchState();
  }

  /// Fuerza una búsqueda inmediata (ya es el comportamiento por defecto)
  Future<void> searchImmediate(String query) async {
    final version = ++_searchVersion;
    _onlineDebounceTimer?.cancel();
    await _performSearch(query, version);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider principal de búsqueda de alimentos
final foodSearchProvider =
    rp.NotifierProvider<FoodSearchNotifier, FoodSearchState>(
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
final searchFiltersProvider =
    rp.NotifierProvider<SearchFiltersNotifier, SearchFilters>(
      SearchFiltersNotifier.new,
    );

/// Sugerencias predictivas basadas en hora/contexto
final predictiveFoodsProvider = rp.Provider<Future<List<Food>>>((ref) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.getHabitualFoods(dateTime: DateTime.now(), limit: 10);
});

/// Historial de búsquedas recientes
final recentSearchesProvider = rp.Provider<Future<List<String>>>((ref) async {
  final db = ref.read(appDatabaseProvider);

  final historial =
      await (db.select(db.searchHistory)
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
  bool get isLoading =>
      this == SearchStatus.loading || this == SearchStatus.loadingMore;
  bool get hasError => this == SearchStatus.error;
  bool get isEmptyState => this == SearchStatus.empty;
  bool get isOffline => this == SearchStatus.offline;
}
