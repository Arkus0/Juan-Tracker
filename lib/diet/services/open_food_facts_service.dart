import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/open_food_facts_model.dart';

/// Excepciones específicas del servicio de Open Food Facts
sealed class OpenFoodFactsException implements Exception {
  final String message;
  const OpenFoodFactsException(this.message);
  @override
  String toString() => message;
}

class NetworkException extends OpenFoodFactsException {
  const NetworkException(super.message);
}

class TimeoutException extends OpenFoodFactsException {
  const TimeoutException() : super('Tiempo de espera agotado');
}

class RateLimitException extends OpenFoodFactsException {
  const RateLimitException() : super('Demasiadas peticiones. Espera un momento.');
}

class NotFoundException extends OpenFoodFactsException {
  const NotFoundException() : super('Producto no encontrado');
}

/// Servicio para interactuar con la API de Open Food Facts
///
/// Características:
/// - Timeout configurable (default: 10 segundos)
/// - Rate limiting: máximo 100 peticiones/minuto (límite conservador de OFF)
/// - User-Agent personalizado para identificación
/// - Retry pattern: 3 intentos con backoff exponencial
/// - Manejo de errores limpio
/// - Cache en memoria de últimos 20 resultados
class OpenFoodFactsService {
  final http.Client _client;
  final Duration _timeout;

  // Rate limiting
  final List<DateTime> _requestTimestamps = [];
  static const int _maxRequestsPerMinute = 60; // Conservador
  static const int _maxRequestsBurst = 10; // Máximo en ventana corta

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  // In-memory cache (últimos 20 resultados)
  final Map<String, _CachedResponse> _memoryCache = {};
  static const int _maxMemoryCacheSize = 20;
  static const Duration _memoryCacheTTL = Duration(minutes: 5);

  // URLs base
  static const String baseUrl = 'https://world.openfoodfacts.org';
  static const String apiUrl = '$baseUrl/api/v2';

  // User-Agent personalizado (requerido por OFF)
  static const String _userAgent = 'JuanTracker/1.0 (contact@juantracker.app)';

  OpenFoodFactsService({
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 10);

  /// Verifica si podemos hacer una petición (rate limiting)
  bool get canMakeRequest {
    final now = DateTime.now();
    
    // Limpiar timestamps antiguos (> 1 minuto)
    _requestTimestamps.removeWhere(
      (ts) => now.difference(ts).inMinutes >= 1,
    );
    
    // Verificar límite por minuto
    if (_requestTimestamps.length >= _maxRequestsPerMinute) {
      return false;
    }
    
    // Verificar burst (últimos 5 segundos)
    final recentRequests = _requestTimestamps
        .where((ts) => now.difference(ts).inSeconds <= 5)
        .length;
    if (recentRequests >= _maxRequestsBurst) {
      return false;
    }
    
    return true;
  }

  /// Registra una petición para rate limiting
  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }

  /// Espera hasta que se pueda hacer otra petición
  Future<void> _waitForRateLimit() async {
    while (!canMakeRequest) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Headers comunes para todas las peticiones
  Map<String, String> get _headers => {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      };

  /// Log de debug para desarrollo
  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[OpenFoodFacts] $message');
    }
  }

  /// Ejecuta una petición HTTP con retry pattern
  Future<http.Response> _executeWithRetry(
    Uri uri, {
    int attempt = 1,
  }) async {
    try {
      _debugLog('Request (attempt $attempt): $uri');
      _recordRequest();

      final response = await _client.get(uri, headers: _headers).timeout(_timeout);

      _debugLog('Response: ${response.statusCode} (${response.body.length} bytes)');

      // Si es error de servidor y aún tenemos reintentos, intentar de nuevo
      if (response.statusCode >= 500 && attempt < _maxRetries) {
        final delay = _initialRetryDelay * (1 << (attempt - 1)); // Exponential backoff
        _debugLog('Server error ${response.statusCode}, retrying in ${delay.inMilliseconds}ms...');
        await Future<void>.delayed(delay);
        return _executeWithRetry(uri, attempt: attempt + 1);
      }

      return response;
    } on SocketException catch (e) {
      if (attempt < _maxRetries) {
        final delay = _initialRetryDelay * (1 << (attempt - 1));
        _debugLog('Network error: $e, retrying in ${delay.inMilliseconds}ms...');
        await Future<void>.delayed(delay);
        return _executeWithRetry(uri, attempt: attempt + 1);
      }
      rethrow;
    } on http.ClientException catch (e) {
      if (attempt < _maxRetries) {
        final delay = _initialRetryDelay * (1 << (attempt - 1));
        _debugLog('Client error: $e, retrying in ${delay.inMilliseconds}ms...');
        await Future<void>.delayed(delay);
        return _executeWithRetry(uri, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  /// Genera clave de cache para una búsqueda
  String _cacheKey(String query, int page, int pageSize, String country) =>
      '${query.toLowerCase().trim()}:$page:$pageSize:$country';

  /// Obtiene resultado de cache en memoria si es válido
  OpenFoodFactsSearchResponse? _getFromMemoryCache(String key) {
    final cached = _memoryCache[key];
    if (cached == null) return null;

    if (DateTime.now().difference(cached.timestamp) > _memoryCacheTTL) {
      _memoryCache.remove(key);
      return null;
    }

    _debugLog('Cache hit for: $key');
    return cached.response;
  }

  /// Guarda resultado en cache en memoria
  void _saveToMemoryCache(String key, OpenFoodFactsSearchResponse response) {
    // Limpiar cache si excede límite
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      // Eliminar la entrada más antigua
      final oldestKey = _memoryCache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[key] = _CachedResponse(response, DateTime.now());
    _debugLog('Cached response for: $key');
  }

  /// Busca productos por texto
  ///
  /// Parámetros:
  /// - [query]: Término de búsqueda
  /// - [page]: Página de resultados (1-based)
  /// - [pageSize]: Cantidad de resultados por página (max 100)
  /// - [country]: Código de país para preferencia de resultados (default: 'es')
  /// - [withFallback]: Si es true y hay pocos resultados, busca sin restricciones
  Future<OpenFoodFactsSearchResponse> searchProducts(
    String query, {
    int page = 1,
    int pageSize = 50,
    String country = 'es',
    bool withFallback = true,
  }) async {
    if (query.trim().isEmpty) {
      return const OpenFoodFactsSearchResponse.empty();
    }

    final trimmedQuery = query.trim();
    final cacheKey = _cacheKey(trimmedQuery, page, pageSize, country);

    // Verificar cache en memoria primero
    final cachedResponse = _getFromMemoryCache(cacheKey);
    if (cachedResponse != null) {
      return cachedResponse;
    }

    await _waitForRateLimit();

    // FASE 1: Búsqueda abierta (sin filtros restrictivos de país/idioma)
    // Usamos cc= para indicar preferencia de país, pero no filtramos
    // Esto permite que OFF priorice productos españoles sin excluir otros
    final result = await _executeSearch(
      trimmedQuery,
      page: page,
      pageSize: pageSize,
      countryCode: country,
    );

    // FASE 2: Fallback si hay muy pocos resultados
    // Si obtuvimos menos de 5 productos y es primera página, intentar búsqueda global
    if (withFallback && page == 1 && result.products.length < 5) {
      _debugLog('Pocos resultados (${result.products.length}), buscando sin restricciones...');

      await _waitForRateLimit();
      final globalResult = await _executeSearch(
        trimmedQuery,
        page: page,
        pageSize: pageSize,
        countryCode: null, // Sin preferencia de país
      );

      // Combinar resultados (primero locales, luego globales)
      final combined = _combineResults(result.products, globalResult.products);

      final combinedResponse = OpenFoodFactsSearchResponse(
        products: combined,
        count: result.count + globalResult.count,
        page: page,
        pageSize: pageSize,
        hasMore: result.hasMore || globalResult.hasMore,
      );

      _saveToMemoryCache(cacheKey, combinedResponse);
      return combinedResponse;
    }

    // Guardar en cache en memoria
    _saveToMemoryCache(cacheKey, result);
    return result;
  }

  /// Combina resultados de dos búsquedas eliminando duplicados
  List<OpenFoodFactsResult> _combineResults(
    List<OpenFoodFactsResult> primary,
    List<OpenFoodFactsResult> secondary,
  ) {
    final seenCodes = <String>{};
    final combined = <OpenFoodFactsResult>[];

    // Primero los resultados primarios (locales/preferidos)
    for (final p in primary) {
      if (!seenCodes.contains(p.code)) {
        seenCodes.add(p.code);
        combined.add(p);
      }
    }

    // Luego los secundarios (globales)
    for (final p in secondary) {
      if (!seenCodes.contains(p.code)) {
        seenCodes.add(p.code);
        combined.add(p);
      }
    }

    return combined;
  }

  /// Ejecuta una búsqueda individual contra la API
  Future<OpenFoodFactsSearchResponse> _executeSearch(
    String query, {
    required int page,
    required int pageSize,
    String? countryCode,
  }) async {
    // Construir parámetros de búsqueda optimizados
    // Documentación: https://openfoodfacts.github.io/openfoodfacts-server/reference/api-v3.html
    final queryParams = <String, String>{
      // Términos de búsqueda (obligatorio)
      'search_terms': query,

      // Paginación - pageSize aumentado de 20 a 50 para más candidatos
      'page': page.toString(),
      'page_size': pageSize.toString(),

      // CAMPOS A RETORNAR (optimizado para nuestra app)
      'fields':
          'code,'
          'product_name,'
          'generic_name,'
          'brands,'
          'image_url,'
          'image_small_url,'
          'ingredients_text,'
          'serving_size,'
          'product_quantity,'
          'nutriments,'
          'nutriscore_grade,'
          'nutriscore_score,'
          'nova_group,'
          'categories_tags,'
          'labels_tags,'
          'origins_tags,'
          'countries_tags,'
          'states_tags',

      // ORDENAMIENTO: unique_scans_n (escaneos) es más relevante que popularity_key
      // popularity_key prioriza productos globales muy conocidos
      // unique_scans_n prioriza productos realmente usados
      'sort_by': 'unique_scans_n',
      'sort_direction': 'desc',
    };

    // Si hay preferencia de país, usar cc= (country code)
    // Esto influye en el ranking sin filtrar estrictamente
    if (countryCode != null) {
      queryParams['cc'] = countryCode;
      queryParams['lc'] = countryCode; // Idioma preferido para nombres
    }

    final uri = Uri.parse('$apiUrl/search').replace(queryParameters: queryParams);

    _debugLog('Search query: "$query" (page $page, size $pageSize, cc=$countryCode)');
    _debugLog('Full URL: $uri');

    try {
      final response = await _executeWithRetry(uri);

      if (response.statusCode == 429) {
        throw const RateLimitException();
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final result = OpenFoodFactsSearchResponse.fromApiJson(json);

        _debugLog(
            'Found ${result.products.length} valid products (total: ${result.count})');

        return result;
      }

      if (response.statusCode >= 500) {
        throw NetworkException('Error del servidor (${response.statusCode})');
      }

      throw NetworkException('Error HTTP ${response.statusCode}');
    } on FormatException catch (_) {
      throw const NetworkException('Respuesta inválida del servidor');
    } on IOException catch (e) {
      throw NetworkException('Error de conexión: $e');
    } on TimeoutException {
      rethrow;
    } on OpenFoodFactsException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error inesperado: $e');
    }
  }

  /// Busca un producto por código de barras
  Future<OpenFoodFactsResult?> searchByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) {
      return null;
    }

    await _waitForRateLimit();

    final cleanBarcode = barcode.trim();

    // Verificar cache en memoria
    final cacheKey = 'barcode:$cleanBarcode';
    final cached = _memoryCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) <= _memoryCacheTTL) {
      _debugLog('Cache hit for barcode: $cleanBarcode');
      return cached.response.products.isNotEmpty
          ? cached.response.products.first
          : null;
    }

    final uri = Uri.parse('$apiUrl/product/$cleanBarcode').replace(
      queryParameters: {
        'fields': 'code,product_name,generic_name,brands,image_url,image_small_url,'
            'ingredients_text,serving_size,nutriments',
      },
    );

    _debugLog('Barcode search: $cleanBarcode');
    _debugLog('Full URL: $uri');

    try {
      final response = await _executeWithRetry(uri);

      if (response.statusCode == 429) {
        throw const RateLimitException();
      }

      if (response.statusCode == 404) {
        throw const NotFoundException();
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = json['status'] as int? ?? 0;

        if (status == 0) {
          _debugLog('Product not found for barcode: $cleanBarcode');
          throw const NotFoundException();
        }

        final result = OpenFoodFactsResult.fromApiJson(json);
        if (!result.hasValidNutrition) {
          _debugLog('Product has no valid nutrition data: $cleanBarcode');
          return null; // Producto sin datos nutricionales
        }

        // Cache el resultado
        _memoryCache[cacheKey] = _CachedResponse(
          OpenFoodFactsSearchResponse(
            products: [result],
            count: 1,
            page: 1,
            pageSize: 1,
          ),
          DateTime.now(),
        );

        _debugLog('Found product: ${result.name} (${result.brand ?? "sin marca"})');
        return result;
      }

      if (response.statusCode >= 500) {
        throw NetworkException('Error del servidor (${response.statusCode})');
      }

      throw NetworkException('Error HTTP ${response.statusCode}');
    } on FormatException catch (_) {
      throw const NetworkException('Respuesta inválida del servidor');
    } on IOException catch (e) {
      throw NetworkException('Error de conexión: $e');
    } on TimeoutException {
      rethrow;
    } on OpenFoodFactsException {
      rethrow;
    } catch (e) {
      throw NetworkException('Error inesperado: $e');
    }
  }

  /// Descarga una imagen (para cache local)
  Future<List<int>?> downloadImage(String url) async {
    if (url.isEmpty) return null;

    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Limpia el cache en memoria
  void clearMemoryCache() {
    _memoryCache.clear();
    _debugLog('Memory cache cleared');
  }

  /// Cierra el cliente HTTP
  void dispose() {
    _client.close();
    _memoryCache.clear();
  }
}

/// Entrada de cache en memoria
class _CachedResponse {
  final OpenFoodFactsSearchResponse response;
  final DateTime timestamp;

  _CachedResponse(this.response, this.timestamp);
}
