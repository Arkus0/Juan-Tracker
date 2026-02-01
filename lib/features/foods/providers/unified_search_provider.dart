import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../diet/providers/food_search_provider.dart';
import '../../../diet/repositories/alimento_repository.dart';
import '../../../training/database/database.dart';

/// Provider unificado para la búsqueda de alimentos en la pantalla unificada
///
/// Usa AlimentoRepository con búsqueda híbrida (FTS5 local + Open Food Facts).
final unifiedSearchProvider = Provider<AsyncValue<List<ScoredFood>>>((ref) {
  final searchState = ref.watch(foodSearchProvider);

  if (searchState.isLoading && searchState.results.isEmpty) {
    return const AsyncValue.loading();
  }

  // Solo error si no hay resultados Y hay mensaje de error
  if (searchState.status == SearchStatus.error && searchState.results.isEmpty) {
    return AsyncValue.error(
      searchState.errorMessage ?? 'Error de búsqueda',
      StackTrace.current,
    );
  }

  return AsyncValue.data(searchState.results);
});

/// Provider de alimentos recientes (usados por el usuario)
final recentFoodsForUnifiedProvider = FutureProvider<List<Food>>((ref) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.getRecentlyUsed(limit: 20);
});

/// Provider para buscar por código de barras (local + OFF)
/// 
/// Busca primero en local, si no encuentra busca en Open Food Facts.
final barcodeSearchProvider = FutureProvider.family<Food?, String>((ref, barcode) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.searchByBarcode(barcode);
});

/// Provider para búsqueda online por código de barras
/// 
/// Ahora es un alias de barcodeSearchProvider ya que AlimentoRepository
/// incluye búsqueda en OFF automáticamente.
final onlineBarcodeSearchProvider = FutureProvider.family<Food?, String>((ref, barcode) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.searchByBarcode(barcode);
});

/// Provider de alimentos favoritos
final favoriteFoodsForUnifiedProvider = FutureProvider<List<Food>>((ref) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.getFavorites(limit: 50);
});
