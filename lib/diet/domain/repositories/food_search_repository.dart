import '../services/food_scoring_service.dart';

/// Excepciones de búsqueda
sealed class FoodSearchException implements Exception {
  final String message;
  const FoodSearchException(this.message);
}

class NetworkException extends FoodSearchException {
  const NetworkException(super.message);
}

class RateLimitException extends NetworkException {
  const RateLimitException() : super('Demasiadas peticiones');
}

class TimeoutException extends NetworkException {
  const TimeoutException() : super('Tiempo de espera agotado');
}

class CacheException extends FoodSearchException {
  const CacheException(super.message);
}

class NotFoundException extends FoodSearchException {
  const NotFoundException() : super('Producto no encontrado');
}

/// Resultado de búsqueda con metadata
class FoodSearchResult {
  final List<ScoredFood> items;
  final String query;
  final int page;
  final bool hasMore;
  final SearchSource source;
  final Duration searchTime;

  const FoodSearchResult({
    required this.items,
    required this.query,
    required this.page,
    required this.hasMore,
    required this.source,
    required this.searchTime,
  });

  FoodSearchResult copyWith({
    List<ScoredFood>? items,
    String? query,
    int? page,
    bool? hasMore,
    SearchSource? source,
    Duration? searchTime,
  }) {
    return FoodSearchResult(
      items: items ?? this.items,
      query: query ?? this.query,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      source: source ?? this.source,
      searchTime: searchTime ?? this.searchTime,
    );
  }
}

/// Fuente de los resultados
enum SearchSource {
  local,      // Solo datos locales (Drift)
  cache,      // Cache de búsquedas previas
  api,        // API de Open Food Facts
  hybrid,     // Combinación de local + API
  offline,    // Modo offline (cache forzado)
}

/// Contrato para el repositorio de búsqueda de alimentos
abstract class FoodSearchRepository {
  /// Busca alimentos por texto
  /// 
  /// Busca en: local → cache → API (si online)
  Future<FoodSearchResult> search(
    String query, {
    int page = 1,
    int pageSize = 24,
    bool forceOffline = false,
  });

  /// Busca un producto por código de barras
  Future<ScoredFood?> searchByBarcode(String barcode);

  /// Obtiene sugerencias de autocompletar
  Future<List<String>> getSuggestions(String prefix, {int maxResults = 8});

  /// Obtiene búsquedas recientes del usuario
  Future<List<String>> getRecentSearches({int limit = 10});

  /// Guarda una búsqueda en el historial
  Future<void> saveSearch(String query);

  /// Limpia el historial de búsquedas
  Future<void> clearHistory();

  /// Verifica si hay conectividad
  Future<bool> get isOnline;
}
