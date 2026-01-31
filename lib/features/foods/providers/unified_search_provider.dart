import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../diet/providers/food_search_provider.dart';
import '../../../../diet/repositories/alimento_repository.dart';
import '../../../../training/database/database.dart';

/// Provider unificado para la búsqueda de alimentos en la pantalla unificada
/// 
/// Este provider adapta el FoodSearchState del provider original a una lista
/// de ScoredFood para la UI unificada.
final unifiedSearchProvider = Provider<AsyncValue<List<ScoredFood>>>((ref) {
  final searchState = ref.watch(foodSearchProvider);
  
  if (searchState.isLoading && searchState.results.isEmpty) {
    return const AsyncValue.loading();
  }
  
  if (searchState.errorMessage != null) {
    return AsyncValue.error(
      searchState.errorMessage ?? 'Error de búsqueda',
      StackTrace.current,
    );
  }
  
  return AsyncValue.data(searchState.results);
});

/// Provider de alimentos recientes (usados por el usuario)
final recentFoodsForUnifiedProvider = FutureProvider<List<Food>>((ref) async {
  // TODO: Implementar getRecentFoods en el repositorio
  return [];
});

/// Provider para buscar por código de barras
final barcodeSearchProvider = FutureProvider.family<Food?, String>((ref, barcode) async {
  // TODO: Implementar búsqueda por barcode
  return null;
});

/// Provider para búsqueda online por código de barras
final onlineBarcodeSearchProvider = FutureProvider.family<Food?, String>((ref, barcode) async {
  // TODO: Implementar búsqueda online por barcode
  return null;
});
