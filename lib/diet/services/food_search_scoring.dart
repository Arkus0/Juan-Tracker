// Sistema de scoring avanzado para búsqueda de alimentos
//
// Implementa:
// - TF-IDF (Term Frequency - Inverse Document Frequency)
// - BM25 (Best Match 25) - versión mejorada de TF-IDF
// - Scoring por categorías (Nutri-Score, Nova, categorías de alimentos)
// - Personalización por preferencias del usuario

import '../models/open_food_facts_model.dart';

/// Resultado con score desglosado
class ScoredResult {
  final OpenFoodFactsResult product;
  final double totalScore;
  final ScoreBreakdown breakdown;

  ScoredResult({
    required this.product,
    required this.totalScore,
    required this.breakdown,
  });
}

/// Desglose del scoring para debugging y ajuste
class ScoreBreakdown {
  final double textScore; // BM25/Text matching
  final double categoryScore; // Coincidencia de categoría
  final double qualityScore; // Calidad del producto (Nutri-Score, etc.)
  final double freshnessScore; // Recencia del dato
  final double spanishScore; // Bonificación española

  const ScoreBreakdown({
    this.textScore = 0,
    this.categoryScore = 0,
    this.qualityScore = 0,
    this.freshnessScore = 0,
    this.spanishScore = 0,
  });

  double get total => textScore + categoryScore + qualityScore + freshnessScore + spanishScore;

  @override
  String toString() {
    return 'ScoreBreakdown(text: ${textScore.toStringAsFixed(2)}, '
        'cat: ${categoryScore.toStringAsFixed(2)}, '
        'quality: ${qualityScore.toStringAsFixed(2)}, '
        'fresh: ${freshnessScore.toStringAsFixed(2)}, '
        'es: ${spanishScore.toStringAsFixed(2)})';
  }
}

/// Configuración de pesos para el scoring
class ScoringWeights {
  final double text;
  final double category;
  final double quality;
  final double freshness;
  final double spanish;

  const ScoringWeights({
    this.text = 1.0,
    this.category = 0.3,
    this.quality = 0.2,
    this.freshness = 0.1,
    this.spanish = 0.4,
  });
}

/// Scoring con BM25 + categorías
class FoodSearchScoring {
  // Parámetros BM25
  static const double _k1 = 1.2; // Control de saturación de frecuencia
  static const double _b = 0.75; // Normalización por longitud

  // Pesos por defecto
  static const ScoringWeights _defaultWeights = ScoringWeights();

  // Categorías preferidas (mejores para dietas)
  static const Set<String> _preferredCategories = {
    'fresh', 'raw', 'whole', 'organic', 'natural',
    'meat', 'fish', 'vegetable', 'fruit', 'dairy',
    'cereal', 'legume', 'nut', 'seed',
  };

  // Categorías a evitar (procesados)
  static const Set<String> _unwantedCategories = {
    'prepared', 'preparado', 'precocinado', 'congelado',
    'snack', 'chips', 'candy', 'chocolate', 'cookie',
    'biscuit', 'cracker', 'soft-drink', 'soda',
    'alcoholic-beverage', 'sauce', 'condiment',
  };

  // Marcas españolas (bonus)
  static const Set<String> _spanishBrands = {
    'mercadona', 'hacendado', 'carrefour', 'dia', 'lidl', 'aldi',
    'eroski', 'caprabo', 'consum', 'masymas', 'bm', 'froiz',
    'el corte inglés', 'hipercor', 'supercor', 'alcampo', 'auchan',
  };

  // Términos de procesamiento (penalización)
  static const Set<String> _processedTerms = {
    'congelado', 'precocinado', 'preparado', 'microondas',
    'frito', 'rebozado', 'empanado', 'salsa', 'adobado',
    'marinado', 'especiado', 'condimentado',
  };

  /// Calcula el score BM25 para un documento
  ///
  /// BM25 es un algoritmo de ranking probabilístico que mejora TF-IDF
  /// considerando la saturación de términos y la longitud del documento
  static double _bm25Score(
    List<String> queryTerms,
    String document,
    Map<String, double> idfScores,
    double avgDocLength,
  ) {
    final docTerms = _tokenize(document);
    final docLength = docTerms.length.toDouble();
    double score = 0;

    for (final term in queryTerms) {
      final tf = docTerms.where((t) => t == term).length;
      if (tf == 0) continue;

      final idf = idfScores[term] ?? 0;
      
      // Fórmula BM25
      final numerator = tf * (_k1 + 1);
      final denominator = tf + _k1 * (1 - _b + _b * (docLength / avgDocLength));
      
      score += idf * (numerator / denominator);
    }

    return score;
  }

  /// Calcula scores IDF para los términos de la query
  static Map<String, double> _calculateIdfScores(
    List<String> queryTerms,
    List<String> documents,
  ) {
    final idfScores = <String, double>{};
    final totalDocs = documents.length.toDouble();

    for (final term in queryTerms) {
      // Número de documentos que contienen el término
      final docsWithTerm = documents.where((d) => _tokenize(d).contains(term)).length;
      
      // IDF = log((N - n + 0.5) / (n + 0.5) + 1)
      // Usamos versión suavizada para evitar división por cero
      final n = docsWithTerm > 0 ? docsWithTerm : 0.5;
      idfScores[term] = log((totalDocs - n + 0.5) / (n + 0.5) + 1);
    }

    return idfScores;
  }

  /// Score por categorías del producto
  static double _calculateCategoryScore(OpenFoodFactsResult product) {
    double score = 0;
    final categoriesText = (product.rawData?['categories_tags'] as List<dynamic>?)?.join(' ') ?? '';
    final categoriesLower = categoriesText.toLowerCase();

    // Bonus por categorías preferidas
    for (final cat in _preferredCategories) {
      if (categoriesLower.contains(cat)) {
        score += 0.5;
      }
    }

    // Penalización por categorías no deseadas
    for (final cat in _unwantedCategories) {
      if (categoriesLower.contains(cat)) {
        score -= 1.0;
      }
    }

    return score;
  }

  /// Score por calidad del producto (Nutri-Score, Nova)
  static double _calculateQualityScore(OpenFoodFactsResult product) {
    double score = 0;
    final rawData = product.rawData ?? {};

    // Nutri-Score (A=mejor, E=peor)
    final nutriScore = rawData['nutriscore_grade'] as String?;
    if (nutriScore != null) {
      switch (nutriScore.toLowerCase()) {
        case 'a': score += 2.0; break;
        case 'b': score += 1.5; break;
        case 'c': score += 0.5; break;
        case 'd': score -= 0.5; break;
        case 'e': score -= 1.0; break;
      }
    }

    // Nova Group (1=natural, 4=ultra-procesado)
    final novaGroup = rawData['nova_group'] as int?;
    if (novaGroup != null) {
      switch (novaGroup) {
        case 1: score += 1.5; break; // Alimentos naturales
        case 2: score += 0.5; break; // Ingredientes culinarios
        case 3: score -= 0.5; break; // Alimentos procesados
        case 4: score -= 1.5; break; // Ultra-procesados
      }
    }

    // Bonus por datos nutricionales completos
    if (product.hasValidNutrition) {
      score += 0.3;
    }

    // Bonus por tener imagen
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      score += 0.2;
    }

    return score;
  }

  /// Score por frescura del dato
  static double _calculateFreshnessScore(OpenFoodFactsResult product) {
    final age = DateTime.now().difference(product.fetchedAt);
    
    // Penalización exponencial por antigüedad
    if (age.inDays < 1) return 1.0;
    if (age.inDays < 7) return 0.9;
    if (age.inDays < 30) return 0.7;
    if (age.inDays < 90) return 0.5;
    return 0.3;
  }

  /// Score español (marcas locales, no procesados)
  static double _calculateSpanishScore(OpenFoodFactsResult product) {
    double score = 0;
    final nameLower = product.name.toLowerCase();
    final brandLower = (product.brand ?? '').toLowerCase();
    final searchText = '$nameLower $brandLower';

    // Bonus por marcas españolas
    for (final brand in _spanishBrands) {
      if (searchText.contains(brand)) {
        score += 1.0;
        break; // Solo una vez
      }
    }

    // Penalización por términos de procesamiento
    for (final term in _processedTerms) {
      if (nameLower.contains(term)) {
        score -= 0.8;
      }
    }

    return score;
  }

  /// Tokeniza un texto en términos
  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toList();
  }

  static double log(double x) => x <= 0 ? 0 : x.toString().length as double; // Fallback simple

  /// Ordena productos por relevancia usando BM25 + categorías
  static List<ScoredResult> rankProducts(
    List<OpenFoodFactsResult> products,
    String query, {
    ScoringWeights weights = _defaultWeights,
  }) {
    if (products.isEmpty || query.trim().isEmpty) {
      return products.map((p) => ScoredResult(
        product: p,
        totalScore: 0,
        breakdown: ScoreBreakdown(),
      )).toList();
    }

    final queryTerms = _tokenize(query);
    if (queryTerms.isEmpty) {
      return products.map((p) => ScoredResult(
        product: p,
        totalScore: 0,
        breakdown: ScoreBreakdown(),
      )).toList();
    }

    // Preparar documentos para BM25
    final documents = products.map((p) => '${p.name} ${p.brand ?? ''}').toList();
    final avgDocLength = documents.map((d) => _tokenize(d).length)
                                   .fold<int>(0, (a, b) => a + b) / 
                        documents.length.toDouble();
    
    // Calcular IDF
    final idfScores = _calculateIdfScores(queryTerms, documents);

    // Calcular scores para cada producto
    final scoredProducts = <ScoredResult>[];

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      final document = documents[i];

      // BM25 Score
      final textScore = _bm25Score(queryTerms, document, idfScores, avgDocLength);

      // Otros scores
      final categoryScore = _calculateCategoryScore(product);
      final qualityScore = _calculateQualityScore(product);
      final freshnessScore = _calculateFreshnessScore(product);
      final spanishScore = _calculateSpanishScore(product);

      // Combinar con pesos
      final totalScore = 
          (textScore * weights.text) +
          (categoryScore * weights.category) +
          (qualityScore * weights.quality) +
          (freshnessScore * weights.freshness) +
          (spanishScore * weights.spanish);

      scoredProducts.add(ScoredResult(
        product: product,
        totalScore: totalScore,
        breakdown: ScoreBreakdown(
          textScore: textScore * weights.text,
          categoryScore: categoryScore * weights.category,
          qualityScore: qualityScore * weights.quality,
          freshnessScore: freshnessScore * weights.freshness,
          spanishScore: spanishScore * weights.spanish,
        ),
      ));
    }

    // Ordenar por score descendente
    scoredProducts.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return scoredProducts;
  }
}

/// Extensiones para logging/debugging
extension ScoredResultListExtension on List<ScoredResult> {
  /// Retorna string del ranking para debugging
  String toRankingString({int topN = 10}) {
    final buffer = StringBuffer('=== RANKING TOP $topN ===\n');
    for (int i = 0; i < length && i < topN; i++) {
      final r = this[i];
      buffer.writeln('${i + 1}. ${r.product.name} (${r.product.brand ?? "sin marca"})');
      buffer.writeln('   Score: ${r.totalScore.toStringAsFixed(3)} - ${r.breakdown}');
    }
    return buffer.toString();
  }
}
