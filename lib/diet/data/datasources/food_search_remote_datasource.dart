import '../../data/models/cached_search_result.dart';

/// Contrato para el datasource remoto (Open Food Facts)
abstract class FoodSearchRemoteDataSource {
  /// Busca productos en la API
  Future<CachedSearchResult> searchProducts(
    String query, {
    int page = 1,
    int pageSize = 24,
    String? countryCode,
  });
  
  /// Busca un producto por barcode
  Future<CachedFoodItem?> searchByBarcode(String barcode);
  
  /// Cancela requests pendientes
  void cancelPendingRequests();
}
