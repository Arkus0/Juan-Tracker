/// Modelo para representar resultados de búsqueda de Open Food Facts
/// https://world.openfoodfacts.org/
class OpenFoodFactsResult {
  final String code;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String? ingredientsText;

  // Valores nutricionales por 100g (normalizados)
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? sodiumPer100g;

  // Información de porción (si existe)
  final String? portionName;
  final double? portionGrams;

  // Metadata
  final String source;
  final DateTime fetchedAt;
  final Map<String, dynamic>? rawData;

  const OpenFoodFactsResult({
    required this.code,
    required this.name,
    this.brand,
    this.imageUrl,
    this.ingredientsText,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.sodiumPer100g,
    this.portionName,
    this.portionGrams,
    this.source = 'OFF',
    required this.fetchedAt,
    this.rawData,
  });

  /// Verifica si el producto tiene datos nutricionales válidos
  bool get hasValidNutrition => kcalPer100g > 0 || (proteinPer100g != null && proteinPer100g! > 0);

  /// Crea un resultado a partir del JSON de la API de Open Food Facts
  factory OpenFoodFactsResult.fromApiJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>? ?? {};
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    // Extraer nombre (varias fuentes posibles)
    String name = product['product_name'] as String? ?? '';
    if (name.isEmpty) {
      name = product['generic_name'] as String? ?? '';
    }
    if (name.isEmpty) {
      name = 'Producto sin nombre';
    }

    // Extraer marca (varias fuentes posibles)
    String? brand = product['brands'] as String?;
    if (brand != null && brand.contains(',')) {
      brand = brand.split(',').first.trim();
    }

    // Extraer información de porción
    String? portionName;
    double? portionGrams;
    final servingSize = product['serving_size'] as String?;
    if (servingSize != null && servingSize.isNotEmpty) {
      portionName = servingSize;
      // Intentar extraer gramos del string (ej: "30g" o "1 porción (30g)")
      final gramMatch = RegExp(r'(\d+(?:\.\d+)?)\s*g').firstMatch(servingSize.toLowerCase());
      if (gramMatch != null) {
        portionGrams = double.tryParse(gramMatch.group(1)!);
      }
    }

    return OpenFoodFactsResult(
      code: json['code'] as String? ?? '',
      name: name.trim(),
      brand: brand?.trim(),
      imageUrl: product['image_url'] as String? ?? product['image_small_url'] as String?,
      ingredientsText: product['ingredients_text'] as String?,
      kcalPer100g: _extractKcal(nutriments),
      proteinPer100g: _extractDouble(nutriments, 'proteins_100g'),
      carbsPer100g: _extractDouble(nutriments, 'carbohydrates_100g'),
      fatPer100g: _extractDouble(nutriments, 'fat_100g'),
      fiberPer100g: _extractDouble(nutriments, 'fiber_100g'),
      sugarPer100g: _extractDouble(nutriments, 'sugars_100g'),
      sodiumPer100g: _extractDouble(nutriments, 'sodium_100g'),
      portionName: portionName,
      portionGrams: portionGrams,
      fetchedAt: DateTime.now(),
      rawData: product,
    );
  }

  /// Extrae calorías con múltiples estrategias de fallback
  static double _extractKcal(Map<String, dynamic> nutriments) {
    // Intentar kcal directo
    var value = _extractDouble(nutriments, 'energy-kcal_100g');
    if (value != null && value > 0) return value;

    // Fallback: convertir de kJ (1 kcal = 4.184 kJ)
    value = _extractDouble(nutriments, 'energy_100g');
    if (value != null && value > 0) {
      // Si el valor es muy alto (> 500), probablemente es kJ
      if (value > 500) {
        return (value / 4.184).roundToDouble();
      }
      return value;
    }

    // Fallback: energy-kj
    value = _extractDouble(nutriments, 'energy-kj_100g');
    if (value != null && value > 0) {
      return (value / 4.184).roundToDouble();
    }

    return 0;
  }

  /// Extrae un double de los nutriments con múltiples keys posibles
  static double? _extractDouble(Map<String, dynamic> nutriments, String key) {
    final value = nutriments[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Serializa a JSON para cache local
  Map<String, dynamic> toCacheJson() => {
    'code': code,
    'name': name,
    'brand': brand,
    'imageUrl': imageUrl,
    'ingredientsText': ingredientsText,
    'kcalPer100g': kcalPer100g,
    'proteinPer100g': proteinPer100g,
    'carbsPer100g': carbsPer100g,
    'fatPer100g': fatPer100g,
    'fiberPer100g': fiberPer100g,
    'sugarPer100g': sugarPer100g,
    'sodiumPer100g': sodiumPer100g,
    'portionName': portionName,
    'portionGrams': portionGrams,
    'source': source,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  /// Deserializa desde JSON de cache
  factory OpenFoodFactsResult.fromCacheJson(Map<String, dynamic> json) {
    return OpenFoodFactsResult(
      code: json['code'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      imageUrl: json['imageUrl'] as String?,
      ingredientsText: json['ingredientsText'] as String?,
      kcalPer100g: (json['kcalPer100g'] as num).toDouble(),
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble(),
      carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble(),
      fatPer100g: (json['fatPer100g'] as num?)?.toDouble(),
      fiberPer100g: (json['fiberPer100g'] as num?)?.toDouble(),
      sugarPer100g: (json['sugarPer100g'] as num?)?.toDouble(),
      sodiumPer100g: (json['sodiumPer100g'] as num?)?.toDouble(),
      portionName: json['portionName'] as String?,
      portionGrams: (json['portionGrams'] as num?)?.toDouble(),
      source: json['source'] as String,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }

  @override
  String toString() => 'OpenFoodFactsResult($name, ${brand ?? "sin marca"}, ${kcalPer100g}kcal/100g)';
}

/// Respuesta completa de búsqueda de Open Food Facts
class OpenFoodFactsSearchResponse {
  final List<OpenFoodFactsResult> products;
  final int count;
  final int page;
  final int pageSize;
  final bool hasMore;

  const OpenFoodFactsSearchResponse({
    required this.products,
    required this.count,
    required this.page,
    required this.pageSize,
    this.hasMore = false,
  });

  factory OpenFoodFactsSearchResponse.fromApiJson(Map<String, dynamic> json) {
    final products = (json['products'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((p) => OpenFoodFactsResult.fromApiJson({'product': p, 'code': p['code'] ?? ''}))
        .where((p) => p.hasValidNutrition) // Solo productos con datos válidos
        .toList();

    final count = json['count'] as int? ?? 0;
    final page = json['page'] as int? ?? 1;
    final pageSize = json['page_size'] as int? ?? 24;

    return OpenFoodFactsSearchResponse(
      products: products,
      count: count,
      page: page,
      pageSize: pageSize,
      hasMore: (page * pageSize) < count,
    );
  }

  const OpenFoodFactsSearchResponse.empty()
      : products = const [],
        count = 0,
        page = 1,
        pageSize = 24,
        hasMore = false;
}
