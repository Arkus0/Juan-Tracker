import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../diet/models/food_model.dart';
import '../../../../diet/providers/food_search_provider.dart';
import '../../../../diet/repositories/alimento_repository.dart';

/// Provider unificado para la búsqueda de alimentos en la pantalla unificada
/// 
/// Este provider adapta el FoodSearchState del provider original a una lista
/// de ScoredFood para la UI unificada.
final unifiedSearchProvider = Provider<AsyncValue<List<ScoredFood>>>((ref) {
  final searchState = ref.watch(foodSearchProvider);
  
  if (searchState.isLoading && searchState.results.isEmpty) {
    return const AsyncValue.loading();
  }
  
  if (searchState.hasError) {
    return AsyncValue.error(
      searchState.errorMessage ?? 'Error de búsqueda',
      StackTrace.current,
    );
  }
  
  return AsyncValue.data(searchState.results);
});

/// Provider para obtener alimentos recientes en formato para la UI unificada
final recentFoodsForUnifiedProvider = FutureProvider<List<Food>>((ref) async {
  final repository = ref.watch(alimentoRepositoryProvider);
  return repository.getRecentFoods(limit: 20);
});

/// Provider para buscar por código de barras
final barcodeSearchProvider = FutureProvider.family<Food?, String>((ref, barcode) async {
  final repository = ref.watch(alimentoRepositoryProvider);
  return repository.searchByBarcode(barcode);
});

/// Provider para búsqueda online por código de barras
final onlineBarcodeSearchProvider = FutureProvider.family<Food?, String>((ref, barcode) async {
  final repository = ref.watch(alimentoRepositoryProvider);
  return repository.searchByBarcodeOnline(barcode);
});
