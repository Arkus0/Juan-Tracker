import 'package:dio/dio.dart';

import '../../data/datasources/food_search_remote_datasource.dart';
import '../../data/models/cached_search_result.dart';
import '../../domain/repositories/food_search_repository.dart' show NetworkException, RateLimitException, TimeoutException;

/// Implementación del datasource remoto para Open Food Facts
class FoodSearchRemoteDataSourceImpl implements FoodSearchRemoteDataSource {
  final Dio _dio;
  CancelToken? _cancelToken;

  // Configuración
  static const String _baseUrl = 'https://world.openfoodfacts.org';
  static const String _userAgent = 'JuanTracker/1.0 (Flutter; Android; es-ES)';
  static const Duration _timeout = Duration(seconds: 10);
  
  // Rate limiting - OFF API límite: 10 req/min para búsquedas (2026)
  final List<DateTime> _requestTimestamps = [];
  static const int _maxRequestsPerMinute = 10;
  static const int _maxBurstRequests = 5; // Máximo en ventana corta
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  FoodSearchRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    return Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    ));
  }

  @override
  Future<CachedSearchResult> searchProducts(
    String query, {
    int page = 1,
    int pageSize = 24,
    String? countryCode,
  }) async {
    return _executeWithRetry(
      () => _performSearch(query, page: page, pageSize: pageSize, countryCode: countryCode),
    );
  }
  
  /// Ejecuta la búsqueda real
  Future<CachedSearchResult> _performSearch(
    String query, {
    required int page,
    required int pageSize,
    String? countryCode,
  }) async {
    await _waitForRateLimit();
    
    _cancelToken = CancelToken();

    final queryParams = <String, dynamic>{
      'search_terms': query,
      'search_simple': '1',
      'json': '1',
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'fields': 'code,product_name,brands,image_url,nutriments,'
                'nutriscore_grade,nova_group,categories_tags,'
                'countries_tags,stores_tags',
      'sort_by': 'unique_scans_n',
    };

    if (countryCode != null) {
      queryParams['countries_tags'] = 'en:spain';
      queryParams['lc'] = countryCode;
    }

    _recordRequest(); // Registrar ANTES de la petición
    
    final response = await _dio.get<Map<String, dynamic>>(
      '/cgi/search.pl',
      queryParameters: queryParams,
      cancelToken: _cancelToken,
    );

    if (response.statusCode == 429) {
      throw RateLimitException();
    }
    
    if (response.statusCode == 503) {
      // Service unavailable - lanzar excepción para retry
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Service Unavailable',
      );
    }

    if (response.data == null) {
      throw NetworkException('Respuesta vacía');
    }

    return _parseResponse(response.data!, query);
  }
  
  /// Ejecuta con retry y backoff exponencial para errores 503
  Future<T> _executeWithRetry<T>(Future<T> Function() operation, {int attempt = 1}) async {
    try {
      return await operation();
    } on DioException catch (e) {
      // Manejar 503 Service Unavailable con retry
      if (e.response?.statusCode == 503 && attempt < _maxRetries) {
        final delay = _initialRetryDelay * (1 << (attempt - 1)); // Exponential backoff
        await Future.delayed(delay);
        return _executeWithRetry(operation, attempt: attempt + 1);
      }
      
      if (CancelToken.isCancel(e)) {
        throw NetworkException('Búsqueda cancelada');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw TimeoutException();
      }
      throw NetworkException('Error de red: ${e.message}');
    } on NetworkException {
      rethrow;
    }
  }

  @override
  Future<CachedFoodItem?> searchByBarcode(String barcode) async {
    return _executeWithRetry(
      () => _performBarcodeSearch(barcode),
    );
  }
  
  /// Ejecuta la búsqueda de barcode
  Future<CachedFoodItem?> _performBarcodeSearch(String barcode) async {
    await _waitForRateLimit();
    _recordRequest(); // Registrar ANTES
    
    _cancelToken = CancelToken();

    // El endpoint de producto sí está en api/v2
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v2/product/$barcode',
      queryParameters: {
        'fields': 'code,product_name,brands,image_url,nutriments,'
                 'nutriscore_grade,nova_group,countries_tags,stores_tags',
      },
      cancelToken: _cancelToken,
    );

    if (response.statusCode == 404) {
      return null;
    }
    
    if (response.statusCode == 503) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Service Unavailable',
      );
    }

    if (response.data == null) {
      throw NetworkException('Respuesta vacía');
    }

    // Verificar status_verbose si existe
    final statusVerbose = response.data!['status_verbose'] as String?;
    final status = response.data!['status'] as int? ?? 0;
    
    if (status == 0 || statusVerbose == 'product not found') {
      return null;
    }

    final product = response.data!['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    return _parseProduct(product);
  }

  @override
  void cancelPendingRequests() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }

  /// Parsea la respuesta de búsqueda
  CachedSearchResult _parseResponse(Map<String, dynamic> json, String query) {
    final products = json['products'] as List<dynamic>? ?? [];
    final count = json['count'] as int? ?? 0;

    final items = <CachedFoodItem>[];
    
    for (final p in products) {
      if (p is! Map<String, dynamic>) continue;
      
      final item = _parseProduct(p);
      if (item != null) {
        items.add(item);
      }
    }

    return CachedSearchResult(
      query: query,
      items: items,
      cachedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      totalCount: count,
      source: 'api',
    );
  }

  /// Parsea un producto individual
  CachedFoodItem? _parseProduct(Map<String, dynamic> product) {
    final name = product['product_name'] as String? ?? 
                 product['generic_name'] as String? ?? '';
    if (name.isEmpty) return null;

    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    
    // Extraer kcal con fallback
    double kcal = 0;
    var kcalValue = nutriments['energy-kcal_100g'] ?? nutriments['energy_100g'];
    if (kcalValue != null) {
      kcal = (kcalValue is num) ? kcalValue.toDouble() : 0;
      // Si viene de energy_100g probablemente sea kJ
      if (kcal > 500 && nutriments['energy-kcal_100g'] == null) {
        kcal = kcal / 4.184;
      }
    }

    if (kcal <= 0) return null; // Sin datos nutricionales válidos

    // Parsear tags
    List<String> parseTags(dynamic tags) {
      if (tags is List) {
        return tags.map((t) => t.toString()).toList();
      }
      return [];
    }

    var brand = product['brands'] as String?;
    if (brand != null && brand.contains(',')) {
      brand = brand.split(',').first.trim();
    }

    return CachedFoodItem(
      code: product['code']?.toString() ?? '',
      name: name.trim(),
      brand: brand,
      imageUrl: product['image_url'] as String?,
      kcalPer100g: kcal,
      proteinPer100g: _parseDouble(nutriments['proteins_100g']),
      carbsPer100g: _parseDouble(nutriments['carbohydrates_100g']),
      fatPer100g: _parseDouble(nutriments['fat_100g']),
      nutriScore: product['nutriscore_grade'] as String?,
      novaGroup: product['nova_group'] != null 
          ? int.tryParse(product['nova_group'].toString())
          : null,
      countriesTags: parseTags(product['countries_tags']),
      storesTags: parseTags(product['stores_tags']),
      fetchedAt: DateTime.now(),
    );
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }

  Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    
    // Limpiar timestamps antiguos (> 1 minuto)
    _requestTimestamps.removeWhere(
      (ts) => now.difference(ts).inMinutes >= 1,
    );
    
    // Verificar límite por minuto (10 req/min según docs OFF 2026)
    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      // Calcular tiempo hasta que el más antiguo expire
      final oldest = _requestTimestamps.first;
      final waitTime = const Duration(minutes: 1) - now.difference(oldest);
      await Future.delayed(waitTime > Duration.zero ? waitTime : const Duration(seconds: 6));
      return _waitForRateLimit(); // Recursivo para verificar de nuevo
    }
    
    // Verificar burst limit (máximo 5 requests en ventana de 10 segundos)
    final recentRequests = _requestTimestamps
        .where((ts) => now.difference(ts).inSeconds <= 10)
        .length;
    if (recentRequests >= _maxBurstRequests) {
      await Future.delayed(const Duration(seconds: 2));
      return _waitForRateLimit();
    }
  }
}
