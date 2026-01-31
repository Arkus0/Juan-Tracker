import 'dart:math' as math;

import '../../domain/services/food_scoring_service.dart';

/// Implementación del scoring de alimentos con disponibilidad España
/// 
/// Prioriza productos que:
/// 1. Coinciden bien con el texto de búsqueda
/// 2. Se venden en supermercados españoles
/// 3. Tienen buena calidad nutricional
/// 4. Tienen datos frescos
class FoodScoringServiceImpl implements FoodScoringService {
  // Pesos configurables (suman 1.0)
  static const double _textWeight = 0.40;
  static const double _availabilityWeight = 0.30;
  static const double _qualityWeight = 0.20;
  static const double _freshnessWeight = 0.10;

  // Supermercados españoles (ordenados por popularidad)
  static const Map<String, double> _spanishStores = {
    // Grandes cadenas (máximo bonus)
    'mercadona': 1.0,
    'carrefour': 1.0,
    'lidl': 1.0,
    'dia': 1.0,
    'aldi': 1.0,
    'eroski': 1.0,
    'caprabo': 1.0,
    'consum': 1.0,
    'masymas': 0.9,
    'bm': 0.9,
    'froiz': 0.9,
    'el corte ingles': 0.9,
    'hipercor': 0.9,
    'alcampo': 0.9,
    'auchan': 0.9,
    'supercor': 0.9,
    // Regionales
    'bonpreu': 0.8,
    'esclat': 0.8,
    'sorli': 0.8,
    'condis': 0.8,
    'coviran': 0.8,
    'spar': 0.8,
    'lupa': 0.7,
    ' Gadis': 0.7,
  };

  @override
  double calculateScore({
    required String query,
    required String name,
    required String? brand,
    required List<String> countriesTags,
    required List<String> storesTags,
    required String? nutriScore,
    required int? novaGroup,
    required DateTime fetchedAt,
  }) {
    final queryLower = query.toLowerCase().trim();
    final nameLower = name.toLowerCase();
    final brandLower = brand?.toLowerCase() ?? '';

    // 1. Text match score (0-1)
    final textScore = _calculateTextScore(queryLower, nameLower, brandLower);

    // 2. Availability score (0-1) - ¿Se vende en España?
    final availabilityScore = _calculateAvailabilityScore(
      countriesTags,
      storesTags,
    );

    // 3. Quality score (0-1) - Nutri-Score y Nova
    final qualityScore = _calculateQualityScore(nutriScore, novaGroup);

    // 4. Freshness score (0-1) - ¿Qué tan reciente es el dato?
    final freshnessScore = _calculateFreshnessScore(fetchedAt);

    // Score ponderado final
    return (textScore * _textWeight) +
           (availabilityScore * _availabilityWeight) +
           (qualityScore * _qualityWeight) +
           (freshnessScore * _freshnessWeight);
  }

  /// Calcula score de coincidencia de texto (0-1)
  double _calculateTextScore(String query, String name, String brand) {
    
    // Coincidencia exacta del nombre completo
    if (name == query) return 1.0;
    
    // El nombre empieza con la query
    if (name.startsWith(query)) return 0.9;
    
    // La query está contenida en el nombre
    if (name.contains(query)) return 0.8;
    
    // Coincidencia por palabras individuales
    final queryWords = query.split(RegExp(r'\s+'));
    final nameWords = name.split(RegExp(r'\s+'));
    final brandWords = brand.split(RegExp(r'\s+'));
    final allWords = {...nameWords, ...brandWords};
    
    int matches = 0;
    for (final qw in queryWords) {
      if (qw.length < 2) continue;
      for (final word in allWords) {
        if (word.startsWith(qw)) {
          matches++;
          break;
        }
      }
    }
    
    if (queryWords.isEmpty) return 0.0;
    final matchRatio = matches / queryWords.length;
    
    // Mínimo 0.3 si hay alguna coincidencia parcial
    if (matchRatio > 0) {
      return 0.3 + (matchRatio * 0.4); // 0.3 - 0.7
    }
    
    return 0.0;
  }

  /// Calcula score de disponibilidad en España (0-1)
  /// 
  /// Prioriza productos que:
  /// - Se venden en España (countries_tags contiene 'en:spain')
  /// - Están disponibles en supermercados españoles conocidos
  double _calculateAvailabilityScore(
    List<String> countriesTags,
    List<String> storesTags,
  ) {
    // Normalizar tags
    final normalizedCountries = countriesTags
        .map((t) => t.toLowerCase().replaceAll('en:', ''))
        .toSet();
    final normalizedStores = storesTags
        .map((t) => t.toLowerCase().replaceAll('en:', ''))
        .toSet();
    
    // ¿Se vende en España?
    final isSoldInSpain = normalizedCountries.contains('spain') ||
                          normalizedCountries.contains('españa');
    
    if (!isSoldInSpain) {
      // Producto no vendido en España - penalización suave
      // (puede ser importado o estar mal etiquetado)
      return 0.3;
    }
    
    // ¿En qué supermercados está disponible?
    double maxStoreScore = 0.0;
    for (final store in normalizedStores) {
      final score = _spanishStores[store] ?? 0.0;
      if (score > maxStoreScore) {
        maxStoreScore = score;
      }
    }
    
    // Bonus por estar en supermercados españoles
    if (maxStoreScore > 0) {
      return 0.7 + (maxStoreScore * 0.3); // 0.7 - 1.0
    }
    
    // Se vende en España pero no sabemos dónde
    return 0.6;
  }

  /// Calcula score de calidad nutricional (0-1)
  double _calculateQualityScore(String? nutriScore, int? novaGroup) {
    double score = 0.5; // Base neutral
    
    // Nutri-Score: A=mejor, E=peor
    if (nutriScore != null) {
      switch (nutriScore.toLowerCase()) {
        case 'a': score += 0.25; break;
        case 'b': score += 0.15; break;
        case 'c': score += 0.05; break;
        case 'd': score -= 0.10; break;
        case 'e': score -= 0.20; break;
      }
    }
    
    // Nova Group: 1=natural, 4=ultra-procesado
    if (novaGroup != null) {
      switch (novaGroup) {
        case 1: score += 0.20; break;
        case 2: score += 0.10; break;
        case 3: score -= 0.05; break;
        case 4: score -= 0.15; break;
      }
    }
    
    return math.max(0.0, math.min(1.0, score));
  }

  /// Calcula score de frescura de datos (0-1)
  double _calculateFreshnessScore(DateTime fetchedAt) {
    final age = DateTime.now().difference(fetchedAt);
    
    // Datos muy recientes
    if (age.inDays < 7) return 1.0;
    // Datos del último mes
    if (age.inDays < 30) return 0.9;
    // Datos de 1-3 meses
    if (age.inDays < 90) return 0.7;
    // Datos de 3-6 meses
    if (age.inDays < 180) return 0.5;
    // Datos antiguos
    return 0.3;
  }

  @override
  List<ScoredFood> rankProducts(List<ScorableFood> products, String query) {
    if (products.isEmpty || query.trim().isEmpty) {
      return products.map((p) => ScoredFood(
        food: p,
        score: 0.0,
        breakdown: const ScoreBreakdown(
          textMatch: 0,
          availability: 0,
          quality: 0,
          freshness: 0,
          total: 0,
        ),
      )).toList();
    }

    final scored = <ScoredFood>[];
    
    for (final product in products) {
      final score = calculateScore(
        query: query,
        name: product.name,
        brand: product.brand,
        countriesTags: product.countriesTags,
        storesTags: product.storesTags,
        nutriScore: product.nutriScore,
        novaGroup: product.novaGroup,
        fetchedAt: product.fetchedAt,
      );

      // Calcular breakdown individual
      final textScore = _calculateTextScore(
        query.toLowerCase(),
        product.name.toLowerCase(),
        product.brand?.toLowerCase() ?? '',
      );
      final availabilityScore = _calculateAvailabilityScore(
        product.countriesTags,
        product.storesTags,
      );
      final qualityScore = _calculateQualityScore(
        product.nutriScore,
        product.novaGroup,
      );
      final freshnessScore = _calculateFreshnessScore(product.fetchedAt);

      scored.add(ScoredFood(
        food: product,
        score: score,
        breakdown: ScoreBreakdown(
          textMatch: textScore,
          availability: availabilityScore,
          quality: qualityScore,
          freshness: freshnessScore,
          total: score,
        ),
      ));
    }

    // Ordenar por score descendente
    scored.sort((a, b) => b.score.compareTo(a.score));
    
    return scored;
  }
}
