import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

/// Resultado de parsear una receta desde URL
class ParsedRecipe {
  final String name;
  final String? description;
  final int? servings;
  final String? servingSize;
  final List<String> ingredients;
  final List<String>? instructions;
  final String? imageUrl;
  final String sourceUrl;

  /// Nutrición total estimada (si disponible en JSON-LD)
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

/// Servicio para importar recetas desde URLs
///
/// Estrategia de parseo:
/// 1. JSON-LD con schema.org/Recipe (más fiable)
/// 2. Microdata schema.org/Recipe
/// 3. Metadatos Open Graph como fallback
class RecipeUrlImporter {
  final Dio _dio;

  RecipeUrlImporter({Dio? dio}) : _dio = dio ?? Dio();

  /// Importa una receta desde una URL
  Future<ParsedRecipe> importFromUrl(String url) async {
    final response = await _dio.get(
      url,
      options: Options(
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Juan-Tracker/1.0',
          'Accept': 'text/html,application/xhtml+xml',
        },
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    final document = html_parser.parse(response.data as String);

    // Estrategia 1: JSON-LD
    final jsonLd = _parseJsonLd(document);
    if (jsonLd != null) {
      return _recipeFromJsonLd(jsonLd, url);
    }

    // Estrategia 2: Microdata
    final microdata = _parseMicrodata(document);
    if (microdata != null) {
      return microdata.copyWithUrl(url);
    }

    // Estrategia 3: Fallback con metadatos OG + listas de ingredientes
    return _parseFallback(document, url);
  }

  /// Busca JSON-LD con @type Recipe en el documento
  Map<String, dynamic>? _parseJsonLd(Document document) {
    final scripts = document.querySelectorAll(
      'script[type="application/ld+json"]',
    );

    for (final script in scripts) {
      try {
        final content = script.text.trim();
        if (content.isEmpty) continue;

        final decoded = jsonDecode(content);

        // Puede ser un solo objeto o un array
        if (decoded is Map<String, dynamic>) {
          final recipe = _findRecipeInJsonLd(decoded);
          if (recipe != null) return recipe;
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final recipe = _findRecipeInJsonLd(item);
              if (recipe != null) return recipe;
            }
          }
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Busca recursivamente un objeto @type Recipe en JSON-LD
  Map<String, dynamic>? _findRecipeInJsonLd(Map<String, dynamic> data) {
    final type = data['@type'];
    if (type == 'Recipe' ||
        (type is List && type.contains('Recipe'))) {
      return data;
    }

    // Buscar en @graph
    if (data.containsKey('@graph')) {
      final graph = data['@graph'];
      if (graph is List) {
        for (final item in graph) {
          if (item is Map<String, dynamic>) {
            final recipe = _findRecipeInJsonLd(item);
            if (recipe != null) return recipe;
          }
        }
      }
    }

    return null;
  }

  ParsedRecipe _recipeFromJsonLd(Map<String, dynamic> json, String url) {
    final name = _extractString(json['name']) ?? 'Receta sin nombre';
    final description = _extractString(json['description']);

    // Servings
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

    // Ingredientes
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

    // Instrucciones
    final instructions = <String>[];
    final rawInstructions = json['recipeInstructions'];
    if (rawInstructions is List) {
      for (final item in rawInstructions) {
        if (item is String) {
          instructions.add(item.trim());
        } else if (item is Map<String, dynamic>) {
          final text = _extractString(item['text']);
          if (text != null) instructions.add(text);
        }
      }
    }

    // Imagen
    final imageUrl = _extractImageUrl(json['image']);

    // Nutrición
    int? totalKcal;
    double? totalProtein, totalCarbs, totalFat;
    final nutrition = json['nutrition'];
    if (nutrition is Map<String, dynamic>) {
      totalKcal = _extractNumericValue(nutrition['calories'])?.toInt();
      totalProtein = _extractNumericValue(nutrition['proteinContent']);
      totalCarbs = _extractNumericValue(nutrition['carbohydrateContent']);
      totalFat = _extractNumericValue(nutrition['fatContent']);
    }

    return ParsedRecipe(
      name: name,
      description: description,
      servings: servings,
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

  /// Parseo de Microdata
  ParsedRecipe? _parseMicrodata(Document document) {
    final recipeElement = document.querySelector(
      '[itemtype*="schema.org/Recipe"]',
    );
    if (recipeElement == null) return null;

    final name = recipeElement
            .querySelector('[itemprop="name"]')
            ?.text
            .trim() ??
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
    final yieldEl = recipeElement.querySelector('[itemprop="recipeYield"]');
    if (yieldEl != null) {
      servings = int.tryParse(
        yieldEl.text.replaceAll(RegExp(r'[^\d]'), ''),
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

  /// Fallback: metadatos OG + heurísticas
  ParsedRecipe _parseFallback(Document document, String url) {
    // Nombre desde OG o <title>
    final name = document
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

    // Heurística para encontrar ingredientes
    final ingredients = <String>[];

    // Buscar listas dentro de secciones con texto "ingrediente"
    for (final heading in document.querySelectorAll('h2, h3, h4')) {
      if (heading.text.toLowerCase().contains('ingrediente')) {
        // Buscar la siguiente lista <ul> o <ol>
        var sibling = heading.nextElementSibling;
        for (int i = 0; i < 5 && sibling != null; i++) {
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

  String? _extractString(dynamic value) {
    if (value is String) return value.trim();
    if (value is List && value.isNotEmpty) return value.first.toString().trim();
    return null;
  }

  String? _extractImageUrl(dynamic value) {
    if (value is String) return value;
    if (value is Map<String, dynamic>) return value['url'] as String?;
    if (value is List && value.isNotEmpty) return _extractImageUrl(value.first);
    return null;
  }

  double? _extractNumericValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
    }
    return null;
  }

  String _cleanIngredientText(String text) {
    // Quitar HTML residual y normalizar espacios
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
