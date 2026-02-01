import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../diet/presentation/providers/food_search_provider.dart' as presentation;
import '../../../../diet/providers/food_search_provider.dart';
import '../../../../diet/repositories/alimento_repository.dart';
import '../../../../training/database/database.dart';

/// Provider unificado para la búsqueda de alimentos en la pantalla unificada
///
/// Este provider adapta el FoodSearchState del provider local (FTS5) a una lista
/// de ScoredFood para la UI unificada.
///
/// NOTA: Usa AlimentoRepository (FTS5 local) como fuente principal.
/// Para búsqueda híbrida (local + OFF API), usar el foodSearchProvider
/// de diet/presentation/providers/ en lugar de este.
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
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.getRecentlyUsed(limit: 20);
});

/// Provider para buscar por código de barras (local)
/// 
/// Busca solo en la base de datos local.
final barcodeSearchProvider = FutureProvider.family<Food?, String>((ref, barcode) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.searchByBarcode(barcode);
});

/// Provider para búsqueda online por código de barras (Open Food Facts)
///
/// Realiza búsqueda híbrida: primero local, si no encuentra busca en Open Food Facts
/// y guarda el resultado en la base de datos local.
final onlineBarcodeSearchProvider = FutureProvider.family<Food?, String>((ref, barcode) async {
  // Primero intentar búsqueda local
  final alimentoRepo = ref.read(alimentoRepositoryProvider);
  final localResult = await alimentoRepo.searchByBarcode(barcode);
  if (localResult != null) return localResult;

  // Si no está en local, buscar en Open Food Facts via FoodSearchRepository
  final searchRepo = ref.read(presentation.foodSearchRepositoryProvider);
  final scoredFood = await searchRepo.searchByBarcode(barcode);

  if (scoredFood == null) return null;

  // Buscar el alimento recién guardado en la base de datos local
  // (el repositorio remoto guarda automáticamente en cache)
  final cachedFood = await alimentoRepo.getById(scoredFood.food.id);
  return cachedFood;
});

/// Provider para búsqueda online por texto (Open Food Facts)
///
/// Busca productos por nombre en Open Food Facts.
/// Retorna lista de Food ya convertidos para uso directo en UI.
final onlineTextSearchProvider = FutureProvider.family<List<Food>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];

  // Buscar en Open Food Facts via FoodSearchRepository
  final searchRepo = ref.read(presentation.foodSearchRepositoryProvider);
  final scoredFoods = await searchRepo.search(query, limit: 30, includeRemote: true);

  // Filtrar solo los resultados que vienen de remoto (no locales)
  // y convertir a Food
  return scoredFoods
      .where((sf) => sf.isFromRemote)
      .map((sf) => sf.food)
      .toList();
});
