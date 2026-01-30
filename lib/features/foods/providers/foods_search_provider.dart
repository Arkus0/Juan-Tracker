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
class FoodsSearchNotifier extends Notifier<FoodsSearchState> {
  @override
  FoodsSearchState build() {
    // Cargar todos los alimentos inicialmente
    _loadFoods('');
    return const FoodsSearchState(isLoading: true);
  }

  /// Busca alimentos con debounce integrado
  Future<void> search(String query) async {
    final trimmedQuery = query.trim();

    // Actualizar estado con loading
    state = state.copyWith(query: trimmedQuery, isLoading: true, error: null);

    try {
      final foods = await _loadFoodsAsync(trimmedQuery);
      state = FoodsSearchState(
        query: trimmedQuery,
        foods: foods,
        isLoading: false,
      );
    } catch (e) {
      state = FoodsSearchState(
        query: trimmedQuery,
        foods: [],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Limpia la búsqueda y recarga todos los alimentos
  Future<void> clearSearch() async {
    await search('');
  }

  /// Refresca la lista de alimentos (útil después de añadir/eliminar)
  Future<void> refresh() async {
    final currentQuery = state.query;
    await search(currentQuery);
  }

  Future<List<FoodModel>> _loadFoodsAsync(String query) async {
    final repo = ref.read(foodRepositoryProvider);
    if (query.isEmpty) {
      return repo.getAll();
    }
    return repo.search(query);
  }

  void _loadFoods(String query) {
    search(query);
  }
}

/// Provider para la búsqueda de alimentos en la biblioteca local
final foodsSearchProvider =
    NotifierProvider.autoDispose<FoodsSearchNotifier, FoodsSearchState>(
  () => FoodsSearchNotifier(),
);
