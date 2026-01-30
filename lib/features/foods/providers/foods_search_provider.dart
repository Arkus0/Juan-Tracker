import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';

/// Estado de búsqueda de alimentos en la biblioteca local
class FoodsSearchState {
  final String query;
  final List<FoodModel> foods;
  final bool isLoading;
  final String? error;

  const FoodsSearchState({
    this.query = '',
    this.foods = const [],
    this.isLoading = false,
    this.error,
  });

  FoodsSearchState copyWith({
    String? query,
    List<FoodModel>? foods,
    bool? isLoading,
    String? error,
  }) {
    return FoodsSearchState(
      query: query ?? this.query,
      foods: foods ?? this.foods,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier para gestionar la búsqueda de alimentos en la biblioteca local
class FoodsSearchNotifier extends AutoDisposeAsyncNotifier<FoodsSearchState> {
  @override
  Future<FoodsSearchState> build() async {
    // Cargar todos los alimentos inicialmente
    final foods = await _loadFoods('');
    return FoodsSearchState(foods: foods);
  }

  /// Busca alimentos con debounce integrado
  Future<void> search(String query) async {
    final trimmedQuery = query.trim();

    // Actualizar estado con loading
    state = AsyncData(
      state.valueOrNull?.copyWith(query: trimmedQuery, isLoading: true) ??
          FoodsSearchState(query: trimmedQuery, isLoading: true),
    );

    try {
      final foods = await _loadFoods(trimmedQuery);
      state = AsyncData(FoodsSearchState(
        query: trimmedQuery,
        foods: foods,
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncData(FoodsSearchState(
        query: trimmedQuery,
        foods: [],
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Limpia la búsqueda y recarga todos los alimentos
  Future<void> clearSearch() async {
    await search('');
  }

  /// Refresca la lista de alimentos (útil después de añadir/eliminar)
  Future<void> refresh() async {
    final currentQuery = state.valueOrNull?.query ?? '';
    await search(currentQuery);
  }

  Future<List<FoodModel>> _loadFoods(String query) async {
    final repo = ref.read(foodRepositoryProvider);
    if (query.isEmpty) {
      return repo.getAll();
    }
    return repo.search(query);
  }
}

/// Provider para la búsqueda de alimentos en la biblioteca local
final foodsSearchProvider =
    AsyncNotifierProvider.autoDispose<FoodsSearchNotifier, FoodsSearchState>(
  FoodsSearchNotifier.new,
);
