import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/food_search_local_datasource.dart';
import '../../data/datasources/food_search_local_datasource_impl.dart';
import '../../data/datasources/food_search_remote_datasource.dart';
import '../../data/datasources/food_search_remote_datasource_impl.dart';
import '../../data/repositories/food_search_repository_impl.dart';
import '../../data/services/food_scoring_service_impl.dart';
import '../../domain/repositories/food_search_repository.dart';
import '../../domain/services/food_scoring_service.dart';

// ============================================================================
// PROVIDERS DE DEPENDENCIAS
// ============================================================================

/// Provider del servicio de scoring
final foodScoringServiceProvider = Provider<FoodScoringService>((ref) {
  return FoodScoringServiceImpl();
});

/// Provider del datasource local
final foodSearchLocalDataSourceProvider = Provider<FoodSearchLocalDataSource>((ref) {
  return FoodSearchLocalDataSourceImpl();
});

/// Provider del datasource remoto
final foodSearchRemoteDataSourceProvider = Provider<FoodSearchRemoteDataSource>((ref) {
  return FoodSearchRemoteDataSourceImpl();
});

/// Provider del repositorio
final foodSearchRepositoryProvider = Provider<FoodSearchRepository>((ref) {
  return FoodSearchRepositoryImpl(
    local: ref.watch(foodSearchLocalDataSourceProvider),
    remote: ref.watch(foodSearchRemoteDataSourceProvider),
    scoring: ref.watch(foodScoringServiceProvider),
  );
});

// ============================================================================
// ESTADO
// ============================================================================

/// Estados posibles de búsqueda
enum FoodSearchStatus { idle, loading, success, error, offline }

/// Estado de búsqueda
class FoodSearchState {
  final FoodSearchStatus status;
  final List<ScoredFoodItem> items;
  final String? errorMessage;
  final String query;
  final int page;
  final bool hasMore;
  final SearchSource source;
  final Duration? searchTime;
  final List<String> suggestions;

  const FoodSearchState({
    this.status = FoodSearchStatus.idle,
    this.items = const [],
    this.errorMessage,
    this.query = '',
    this.page = 1,
    this.hasMore = false,
    this.source = SearchSource.local,
    this.searchTime,
    this.suggestions = const [],
  });

  FoodSearchState copyWith({
    FoodSearchStatus? status,
    List<ScoredFoodItem>? items,
    String? errorMessage,
    String? query,
    int? page,
    bool? hasMore,
    SearchSource? source,
    Duration? searchTime,
    List<String>? suggestions,
  }) {
    return FoodSearchState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      query: query ?? this.query,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      source: source ?? this.source,
      searchTime: searchTime ?? this.searchTime,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  bool get isLoading => status == FoodSearchStatus.loading;
  bool get hasError => status == FoodSearchStatus.error;
  bool get isEmpty => status == FoodSearchStatus.success && items.isEmpty;
}

/// Item scorado simplificado para UI
class ScoredFoodItem {
  final String id;
  final String name;
  final String? brand;
  final String? imageUrl;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final String? nutriScore;
  final int? novaGroup;
  final double score;
  final bool isLocal;

  const ScoredFoodItem({
    required this.id,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.nutriScore,
    this.novaGroup,
    required this.score,
    this.isLocal = false,
  });
}

// ============================================================================
// NOTIFIER
// ============================================================================

/// Notifier de búsqueda de alimentos
/// 
/// Características:
/// - Debounce de 300ms
/// - Cancelación de requests previos
/// - Cache automático
/// - Offline-first
class FoodSearchNotifier extends Notifier<FoodSearchState> {
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  FoodSearchRepository get _repository => ref.read(foodSearchRepositoryProvider);

  @override
  FoodSearchState build() {
    // Cleanup al dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const FoodSearchState();
  }

  /// Busca alimentos con debounce
  void search(String query, {bool forceOffline = false}) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      state = const FoodSearchState();
      return;
    }

    // Estado loading inmediato
    state = state.copyWith(
      status: FoodSearchStatus.loading,
      query: query.trim(),
      items: [],
      errorMessage: null,
    );

    // Debounce
    _debounceTimer = Timer(_debounceDuration, () async {
      await _performSearch(query.trim(), forceOffline: forceOffline);
    });
  }

  /// Ejecuta la búsqueda real
  Future<void> _performSearch(String query, {bool forceOffline = false}) async {
    try {
      final result = await _repository.search(
        query,
        page: 1,
        forceOffline: forceOffline,
      );

      // Mapear a items de UI
      final items = result.items.map((scored) => ScoredFoodItem(
        id: scored.food.id,
        name: scored.food.name,
        brand: scored.food.brand,
        imageUrl: scored.food.metadata['imageUrl'] as String?,
        kcalPer100g: (scored.food.metadata['kcalPer100g'] as num?)?.toDouble() ?? 0,
        proteinPer100g: (scored.food.metadata['proteinPer100g'] as num?)?.toDouble(),
        carbsPer100g: (scored.food.metadata['carbsPer100g'] as num?)?.toDouble(),
        fatPer100g: (scored.food.metadata['fatPer100g'] as num?)?.toDouble(),
        nutriScore: scored.food.nutriScore,
        novaGroup: scored.food.novaGroup,
        score: scored.score,
        isLocal: scored.food.metadata['source'] == 'local',
      )).toList();

      state = state.copyWith(
        status: result.source == SearchSource.offline
            ? FoodSearchStatus.offline
            : FoodSearchStatus.success,
        items: items,
        hasMore: result.hasMore,
        source: result.source,
        searchTime: result.searchTime,
      );

      // Guardar en historial
      await _repository.saveSearch(query);
    } on NetworkException catch (e) {
      state = state.copyWith(
        status: FoodSearchStatus.error,
        errorMessage: 'Error de red: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        status: FoodSearchStatus.error,
        errorMessage: 'Error inesperado: $e',
      );
    }
  }

  /// Carga más resultados (paginación)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(status: FoodSearchStatus.loading);

    try {
      final result = await _repository.search(
        state.query,
        page: state.page + 1,
      );

      final newItems = result.items.map((scored) => ScoredFoodItem(
        id: scored.food.id,
        name: scored.food.name,
        brand: scored.food.brand,
        imageUrl: scored.food.metadata['imageUrl'] as String?,
        kcalPer100g: (scored.food.metadata['kcalPer100g'] as num?)?.toDouble() ?? 0,
        proteinPer100g: (scored.food.metadata['proteinPer100g'] as num?)?.toDouble(),
        carbsPer100g: (scored.food.metadata['carbsPer100g'] as num?)?.toDouble(),
        fatPer100g: (scored.food.metadata['fatPer100g'] as num?)?.toDouble(),
        nutriScore: scored.food.nutriScore,
        novaGroup: scored.food.novaGroup,
        score: scored.score,
        isLocal: scored.food.metadata['source'] == 'local',
      )).toList();

      // Combinar con existentes
      final allItems = [...state.items, ...newItems];
      
      // Eliminar duplicados
      final seenIds = <String>{};
      final uniqueItems = <ScoredFoodItem>[];
      for (final item in allItems) {
        if (!seenIds.contains(item.id)) {
          seenIds.add(item.id);
          uniqueItems.add(item);
        }
      }

      state = state.copyWith(
        status: FoodSearchStatus.success,
        items: uniqueItems,
        page: state.page + 1,
        hasMore: result.hasMore,
      );
    } catch (e) {
      // Mantener resultados actuales en error
      state = state.copyWith(
        status: FoodSearchStatus.success,
        hasMore: false,
      );
    }
  }

  /// Obtiene sugerencias de autocompletar
  Future<List<String>> getSuggestions(String prefix) async {
    if (prefix.length < 2) return [];
    return await _repository.getSuggestions(prefix);
  }

  /// Limpia la búsqueda
  void clear() {
    _debounceTimer?.cancel();
    state = const FoodSearchState();
  }
}

// ============================================================================
// PROVIDER EXPORTADO
// ============================================================================

/// Provider del notifier de búsqueda
final foodSearchProvider = NotifierProvider<FoodSearchNotifier, FoodSearchState>(() {
  return FoodSearchNotifier();
});

/// Provider de sugerencias de búsqueda
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, prefix) async {
  if (prefix.length < 2) return [];
  final repository = ref.read(foodSearchRepositoryProvider);
  return await repository.getSuggestions(prefix);
});

/// Provider de búsquedas recientes
final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.read(foodSearchRepositoryProvider);
  return await repository.getRecentSearches();
});
