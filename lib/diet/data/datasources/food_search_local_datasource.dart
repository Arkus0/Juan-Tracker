import '../../data/models/cached_search_result.dart';
import '../../models/food_model.dart';

/// Contrato para el datasource local de búsqueda
abstract class FoodSearchLocalDataSource {
  /// Busca en alimentos locales (Drift)
  Future<List<FoodModel>> searchLocalFoods(String query, {int limit = 20});
  
  /// Busca en el cache de búsquedas
  Future<CachedSearchResult?> getCachedSearch(String query);
  
  /// Guarda resultados en cache
  Future<void> cacheSearchResults(CachedSearchResult result);
  
  /// Busca en cache offline (búsqueda difusa)
  Future<List<CachedFoodItem>> searchOffline(String query);
  
  /// Obtiene historial de búsquedas
  Future<List<String>> getRecentSearches({int limit = 10});
  
  /// Guarda búsqueda en historial
  Future<void> saveSearch(String query);
  
  /// Limpia historial
  Future<void> clearHistory();
  
  /// Obtiene todas las búsquedas cacheadas
  Future<List<String>> getCachedQueries();
  
  /// Elimina entradas de cache expiradas
  Future<int> cleanupExpiredCache();
}
