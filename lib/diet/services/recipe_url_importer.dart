import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Resultado de parsear una receta desde URL.
class ParsedRecipe {
  final String name;
  final String? description;
  final int? servings;
  final String? servingSize;
  final List<String> ingredients;
  final List<String>? instructions;
  final String? imageUrl;
  final String sourceUrl;

  /// Nutricion total estimada (si disponible en JSON-LD).
  final int? totalKcal;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;

  const ParsedRecipe({
    required this.name,
    this.description,
    this.servings,
    this.servingSize,
    required this.ingredients,
    this.instructions,
    this.imageUrl,
    required this.sourceUrl,
    this.totalKcal,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
  });
}

enum RecipeImportErrorCode {
  invalidUrl,
  blockedHost,
  timeout,
  network,
  notFound,
  server,
  unsupportedContent,
  responseTooLarge,
  emptyResponse,
  parseFailed,
  unknown,
}

/// Excepcion de dominio para el flujo de importacion de recetas.
class RecipeImportException implements Exception {
  final RecipeImportErrorCode code;
  final String message;
  final Object? cause;

  const RecipeImportException({
    required this.code,
    required this.message,
    this.cause,
  });

  @override
  String toString() => message;
}

/// Servicio para importar recetas desde URLs.
///
/// Estrategia de parseo:
/// 1. JSON-LD con schema.org/Recipe (mas fiable)
/// 2. Microdata schema.org/Recipe
/// 3. Metadatos Open Graph como fallback
class RecipeUrlImporter {
  static const int _maxResponseBytes = 2 * 1024 * 1024;

  final Dio _dio;

  RecipeUrlImporter({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 10),
              followRedirects: true,
              maxRedirects: 5,
            ),
          );

  /// Importa una receta desde una URL.
  Future<ParsedRecipe> importFromUrl(String url) async {
    final normalizedUri = _validateUrl(url);

    try {
      final response = await _dio.get<String>(
        normalizedUri.toString(),
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Juan-Tracker/1.0',
            'Accept': 'text/html,application/xhtml+xml',
          },
          responseType: ResponseType.plain,
        ),
      );

      _validateResponseMetadata(response);

      final htmlData = response.data?.trim();
      if (htmlData == null || htmlData.isEmpty) {
        throw const RecipeImportException(
          code: RecipeImportErrorCode.emptyResponse,
          message: 'La pagina no devolvio contenido valido.',
        );
      }

      final responseBytes = utf8.encode(htmlData).length;
      if (responseBytes > _maxResponseBytes) {
        throw const RecipeImportException(
          code: RecipeImportErrorCode.responseTooLarge,
          message:
              'La receta es demasiado grande para importar en este dispositivo.',
        );
      }

      final document = html_parser.parse(htmlData);

      // Estrategia 1: JSON-LD.
      final jsonLd = _parseJsonLd(document);
      if (jsonLd != null) {
        return _recipeFromJsonLd(jsonLd, normalizedUri.toString());
      }

      // Estrategia 2: Microdata.
      final microdata = _parseMicrodata(document);
      if (microdata != null) {
        return microdata.copyWithUrl(normalizedUri.toString());
      }

      // Estrategia 3: fallback con metadatos OG + listas de ingredientes.
      final fallback = _parseFallback(document, normalizedUri.toString());
      if (fallback.name.trim().isEmpty && fallback.ingredients.isEmpty) {
        throw const RecipeImportException(
          code: RecipeImportErrorCode.parseFailed,
          message: 'No se pudo extraer informacion de receta desde la URL.',
        );
      }
      return fallback;
    } on RecipeImportException {
      rethrow;
    } on DioException catch (e) {
      throw _mapNetworkError(e);
    } catch (e) {
      throw RecipeImportException(
        code: RecipeImportErrorCode.unknown,
        message: 'No se pudo importar la receta en este momento.',
        cause: e,
      );
    }
  }

  Uri _validateUrl(String rawUrl) {
    final normalized = rawUrl.trim();
    final uri = Uri.tryParse(normalized);

    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const RecipeImportException(
        code: RecipeImportErrorCode.invalidUrl,
        message: 'Introduce una URL valida con http o https.',
      );
    }

    if (_isBlockedHost(uri.host)) {
      throw const RecipeImportException(
        code: RecipeImportErrorCode.blockedHost,
        message: 'Esta URL no se puede importar por seguridad.',
      );
    }

    return uri;
  }

  bool _isBlockedHost(String host) {
    final normalizedHost = host.trim().toLowerCase();
    if (normalizedHost == 'localhost' ||
        normalizedHost.endsWith('.local') ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '::1') {
      return true;
    }

    final parts = normalizedHost.split('.');
    if (parts.length != 4) return false;

    final octets = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) {
        return false;
      }
      octets.add(value);
    }

    if (octets[0] == 10) return true;
    if (octets[0] == 127) return true;
    if (octets[0] == 169 && octets[1] == 254) return true;
    if (octets[0] == 192 && octets[1] == 168) return true;
    if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) return true;

    return false;
  }

  void _validateResponseMetadata(Response<String> response) {
    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      if (statusCode == 404) {
        throw const RecipeImportException(
          code: RecipeImportErrorCode.notFound,
          message: 'No se encontro la receta en esa URL.',
        );
      }
      if (statusCode >= 500) {
        throw const RecipeImportException(
          code: RecipeImportErrorCode.server,
          message: 'El sitio devolvio un error. Intenta de nuevo mas tarde.',
        );
      }
      throw const RecipeImportException(
        code: RecipeImportErrorCode.network,
        message: 'No se pudo descargar la receta desde esa URL.',
      );
    }

    final contentTypeHeader = response.headers.value(Headers.contentTypeHeader);
    if (!_isSupportedContentType(contentTypeHeader)) {
      throw const RecipeImportException(
        code: RecipeImportErrorCode.unsupportedContent,
        message: 'La URL no parece ser una pagina HTML de receta.',
      );
    }

    final contentLengthHeader = response.headers.value(
      Headers.contentLengthHeader,
    );
    final contentLength = int.tryParse(contentLengthHeader ?? '');
    if (contentLength != null && contentLength > _maxResponseBytes) {
      throw const RecipeImportException(
        code: RecipeImportErrorCode.responseTooLarge,
        message:
            'La receta es demasiado grande para importar en este dispositivo.',
      );
    }
  }

  bool _isSupportedContentType(String? contentTypeHeader) {
    if (contentTypeHeader == null || contentTypeHeader.isEmpty) {
      // Muchos sitios omiten el content-type correcto.
      return true;
    }

    final value = contentTypeHeader.toLowerCase();
    return value.contains('text/html') ||
        value.contains('application/xhtml+xml') ||
        value.contains('text/plain');
  }

  RecipeImportException _mapNetworkError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 404) {
      return const RecipeImportException(
        code: RecipeImportErrorCode.notFound,
        message: 'No se encontro la receta en esa URL.',
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return const RecipeImportException(
        code: RecipeImportErrorCode.server,
        message: 'El sitio devolvio un error. Intenta de nuevo mas tarde.',
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RecipeImportException(
          code: RecipeImportErrorCode.timeout,
          message: 'La importacion tardo demasiado. Revisa tu conexion.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return const RecipeImportException(
          code: RecipeImportErrorCode.network,
          message: 'No hay conexion disponible para importar esta receta.',
        );
      case DioExceptionType.badResponse:
        return const RecipeImportException(
          code: RecipeImportErrorCode.network,
          message: 'La URL devolvio una respuesta no valida para receta.',
        );
    }
  }

  /// Busca JSON-LD con @type Recipe en el documento.
  Map<String, dynamic>? _parseJsonLd(Document document) {
    final scripts = document.querySelectorAll(
      'script[type="application/ld+json"]',
    );

    for (final script in scripts) {
      final content = script.text.trim();
      if (content.isEmpty) continue;

      try {
        final decoded = jsonDecode(content);
        final recipe = _extractRecipeNode(decoded);
        if (recipe != null) return recipe;
      } catch (_) {
        // Continuar con el siguiente script JSON-LD.
        continue;
      }
    }

    return null;
  }

  Map<String, dynamic>? _extractRecipeNode(dynamic node) {
    final mapNode = _asStringMap(node);
    if (mapNode != null) {
      final recipe = _findRecipeInJsonLd(mapNode);
      if (recipe != null) return recipe;
    }

    if (node is List) {
      for (final item in node) {
        final recipe = _extractRecipeNode(item);
        if (recipe != null) return recipe;
      }
    }

    return null;
  }

  /// Busca recursivamente un objeto @type Recipe en JSON-LD.
  Map<String, dynamic>? _findRecipeInJsonLd(Map<String, dynamic> data) {
    final type = data['@type'];
    if (type == 'Recipe' || (type is List && type.contains('Recipe'))) {
      return data;
    }

    final graph = data['@graph'];
    if (graph is List) {
      for (final item in graph) {
        final nested = _asStringMap(item);
        if (nested == null) continue;
        final recipe = _findRecipeInJsonLd(nested);
        if (recipe != null) return recipe;
      }
    }

    return null;
  }

  ParsedRecipe _recipeFromJsonLd(Map<String, dynamic> json, String url) {
    final name = _extractString(json['name']) ?? 'Receta sin nombre';
    final description = _extractString(json['description']);

    // Servings.
    int? servings;
    final recipeYield = json['recipeYield'];
    if (recipeYield is int) {
      servings = recipeYield;
    } else if (recipeYield is String) {
      servings = int.tryParse(recipeYield.replaceAll(RegExp(r'[^\d]'), ''));
    } else if (recipeYield is List && recipeYield.isNotEmpty) {
      servings = int.tryParse(
        recipeYield.first.toString().replaceAll(RegExp(r'[^\d]'), ''),
      );
    }

    // Ingredientes.
    final ingredients = <String>[];
    final rawIngredients = json['recipeIngredient'];
    if (rawIngredients is List) {
      for (final item in rawIngredients) {
        final text = _extractString(item);
        if (text != null && text.isNotEmpty) {
          ingredients.add(_cleanIngredientText(text));
        }
      }
    }

    // Instrucciones (soporta HowToStep y HowToSection).
    final instructions = _extractInstructionTexts(json['recipeInstructions']);

    // Imagen.
    final imageUrl = _extractImageUrl(json['image']);

    // Nutricion.
    int? totalKcal;
    double? totalProtein;
    double? totalCarbs;
    double? totalFat;
    final nutrition = _asStringMap(json['nutrition']);
    if (nutrition != null) {
      totalKcal = _extractNumericValue(nutrition['calories'])?.round();
      totalProtein = _extractNumericValue(nutrition['proteinContent']);
      totalCarbs = _extractNumericValue(nutrition['carbohydrateContent']);
      totalFat = _extractNumericValue(nutrition['fatContent']);
    }

    return ParsedRecipe(
      name: name,
      description: description,
      servings: servings,
      ingredients: ingredients,
      instructions: instructions.isEmpty ? null : instructions,
      imageUrl: imageUrl,
      sourceUrl: url,
      totalKcal: totalKcal,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
    );
  }

  List<String> _extractInstructionTexts(dynamic rawInstructions) {
    final instructions = <String>[];

    void collect(dynamic node) {
      if (node is String) {
        final cleaned = node.trim();
        if (cleaned.isNotEmpty) instructions.add(cleaned);
        return;
      }

      if (node is List) {
        for (final item in node) {
          collect(item);
        }
        return;
      }

      final mapNode = _asStringMap(node);
      if (mapNode == null) return;

      final text =
          _extractString(mapNode['text']) ?? _extractString(mapNode['name']);
      if (text != null && text.isNotEmpty) {
        instructions.add(text);
      }

      collect(mapNode['itemListElement']);
      collect(mapNode['steps']);
    }

    collect(rawInstructions);
    return instructions.toSet().toList();
  }

  /// Parseo de microdata.
  ParsedRecipe? _parseMicrodata(Document document) {
    final recipeElement = document.querySelector(
      '[itemtype*="schema.org/Recipe"]',
    );
    if (recipeElement == null) return null;

    final name =
        recipeElement.querySelector('[itemprop="name"]')?.text.trim() ??
        'Receta sin nombre';

    final description = recipeElement
        .querySelector('[itemprop="description"]')
        ?.text
        .trim();

    final ingredients = recipeElement
        .querySelectorAll('[itemprop="recipeIngredient"]')
        .map((e) => _cleanIngredientText(e.text.trim()))
        .where((t) => t.isNotEmpty)
        .toList();

    int? servings;
    final yieldElement = recipeElement.querySelector(
      '[itemprop="recipeYield"]',
    );
    if (yieldElement != null) {
      servings = int.tryParse(
        yieldElement.text.replaceAll(RegExp(r'[^\d]'), ''),
      );
    }

    return ParsedRecipe(
      name: name,
      description: description,
      servings: servings,
      ingredients: ingredients,
      sourceUrl: '',
    );
  }

  /// Fallback: metadatos OG + heuristicas.
  ParsedRecipe _parseFallback(Document document, String url) {
    final name =
        document
            .querySelector('meta[property="og:title"]')
            ?.attributes['content']
            ?.trim() ??
        document.querySelector('title')?.text.trim() ??
        'Receta importada';

    final description = document
        .querySelector('meta[property="og:description"]')
        ?.attributes['content']
        ?.trim();

    final imageUrl = document
        .querySelector('meta[property="og:image"]')
        ?.attributes['content'];

    final ingredients = <String>[];

    // Buscar listas dentro de secciones con texto "ingrediente".
    for (final heading in document.querySelectorAll('h2, h3, h4')) {
      if (!heading.text.toLowerCase().contains('ingrediente')) continue;

      var sibling = heading.nextElementSibling;
      for (var i = 0; i < 5 && sibling != null; i++) {
        if (sibling.localName == 'ul' || sibling.localName == 'ol') {
          for (final li in sibling.querySelectorAll('li')) {
            final text = _cleanIngredientText(li.text.trim());
            if (text.isNotEmpty) ingredients.add(text);
          }
          break;
        }
        sibling = sibling.nextElementSibling;
      }

      if (ingredients.isNotEmpty) break;
    }

    return ParsedRecipe(
      name: name,
      description: description,
      ingredients: ingredients,
      imageUrl: imageUrl,
      sourceUrl: url,
    );
  }

  // ---- Helpers ----

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is! Map) return null;
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }

  String? _extractString(dynamic value) {
    if (value is String) return value.trim();
    if (value is List && value.isNotEmpty) return _extractString(value.first);
    final mapValue = _asStringMap(value);
    if (mapValue != null) {
      return _extractString(mapValue['@value']) ??
          _extractString(mapValue['name']) ??
          _extractString(mapValue['text']);
    }
    return null;
  }

  String? _extractImageUrl(dynamic value) {
    if (value is String) return value.trim();
    final mapValue = _asStringMap(value);
    if (mapValue != null) {
      return _extractString(mapValue['url']) ??
          _extractString(mapValue['contentUrl']);
    }
    if (value is List && value.isNotEmpty) return _extractImageUrl(value.first);
    return null;
  }

  double? _extractNumericValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is! String) return null;

    final cleaned = value.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (cleaned.isEmpty) return null;

    final normalized = _normalizeNumericString(cleaned);
    return double.tryParse(normalized);
  }

  String _normalizeNumericString(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return value;

    final hasDot = value.contains('.');
    final hasComma = value.contains(',');

    if (hasDot && hasComma) {
      // Si la ultima coma aparece despues del ultimo punto, la coma es decimal.
      if (value.lastIndexOf(',') > value.lastIndexOf('.')) {
        value = value.replaceAll('.', '').replaceAll(',', '.');
      } else {
        value = value.replaceAll(',', '');
      }
      return value;
    }

    if (!hasDot && hasComma) {
      final parts = value.split(',');
      if (parts.length == 2 && parts[1].length == 3) {
        // "1,200" -> 1200
        value = '${parts[0]}${parts[1]}';
      } else {
        // "12,5" -> 12.5
        value = value.replaceAll(',', '.');
      }
      return value;
    }

    return value;
  }

  String _cleanIngredientText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();
  }
}

extension _ParsedRecipeCopy on ParsedRecipe {
  ParsedRecipe copyWithUrl(String url) => ParsedRecipe(
    name: name,
    description: description,
    servings: servings,
    servingSize: servingSize,
    ingredients: ingredients,
    instructions: instructions,
    imageUrl: imageUrl,
    sourceUrl: url,
    totalKcal: totalKcal,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
  );
}
