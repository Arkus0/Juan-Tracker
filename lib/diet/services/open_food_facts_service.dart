import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
/// - Manejo de errores limpio
class OpenFoodFactsService {
  final http.Client _client;
  final Duration _timeout;
  
  // Rate limiting
  final List<DateTime> _requestTimestamps = [];
  static const int _maxRequestsPerMinute = 60; // Conservador
  static const int _maxRequestsBurst = 10; // Máximo en ventana corta
  
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

  /// Busca productos por texto
  /// 
  /// Parámetros:
  /// - [query]: Término de búsqueda
  /// - [page]: Página de resultados (1-based)
  /// - [pageSize]: Cantidad de resultados por página (max 100)
  /// - [country]: Código de país para preferencia de resultados (default: 'es')
  Future<OpenFoodFactsSearchResponse> searchProducts(
    String query, {
    int page = 1,
    int pageSize = 24,
    String country = 'es',
  }) async {
    if (query.trim().isEmpty) {
      return const OpenFoodFactsSearchResponse.empty();
    }

    await _waitForRateLimit();

    final uri = Uri.parse('$apiUrl/search').replace(
      queryParameters: {
        'search_terms2': query.trim(), // Usar search_terms2 para mejor relevancia
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'countries_tags': country,
        'fields': 'code,product_name,brands,image_url,image_small_url,'
            'ingredients_text,serving_size,nutriments,product_quantity',
        // No usar sort_by para obtener resultados por relevancia de búsqueda
        'states_tags': 'en:complete', // Solo productos completos
      },
    );

    try {
      _recordRequest();
      
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 429) {
        throw const RateLimitException();
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return OpenFoodFactsSearchResponse.fromApiJson(json);
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
    final uri = Uri.parse('$apiUrl/product/$cleanBarcode').replace(
      queryParameters: {
        'fields': 'code,product_name,brands,image_url,image_small_url,'
            'ingredients_text,serving_size,nutriments',
      },
    );

    try {
      _recordRequest();
      
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);

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
          throw const NotFoundException();
        }

        final result = OpenFoodFactsResult.fromApiJson(json);
        if (!result.hasValidNutrition) {
          return null; // Producto sin datos nutricionales
        }
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

  /// Cierra el cliente HTTP
  void dispose() {
    _client.close();
  }
}
