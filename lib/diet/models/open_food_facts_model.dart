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
  final double? saturatedFatPer100g;
  final double? sodiumPer100g;

  // Información de porción (si existe)
  final String? portionName;
  final double? portionGrams;

  // Scores de calidad
  final String? nutriScore; // 'a', 'b', 'c', 'd', 'e'
  final int? novaGroup; // 1, 2, 3, 4

  // Disponibilidad geográfica (para scoring España)
  final List<String> countriesTags;
  final List<String> storesTags;

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
    this.saturatedFatPer100g,
    this.sodiumPer100g,
    this.portionName,
    this.portionGrams,
    this.nutriScore,
    this.novaGroup,
    this.countriesTags = const [],
    this.storesTags = const [],
    this.source = 'OFF',
    required this.fetchedAt,
    this.rawData,
  });

  /// Verifica si el producto tiene datos nutricionales válidos
  bool get hasValidNutrition => kcalPer100g > 0 || (proteinPer100g != null && proteinPer100g! > 0);

  /// Crea un resultado a partir del JSON de la API de Open Food Facts
  factory OpenFoodFactsResult.fromApiJson(Map<String, dynamic> json) {
    final product = Map<String, dynamic>.from(json['product'] as Map? ?? {});
    final nutriments = Map<String, dynamic>.from(product['nutriments'] as Map? ?? {});

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
      saturatedFatPer100g: _extractDouble(nutriments, 'saturated-fat_100g'),
      sodiumPer100g: _extractDouble(nutriments, 'sodium_100g'),
      portionName: portionName,
      portionGrams: portionGrams,
      nutriScore: product['nutriscore_grade'] as String?,
      novaGroup: product['nova_group'] != null 
          ? int.tryParse(product['nova_group'].toString()) 
          : null,
      countriesTags: _parseStringList(product['countries_tags']),
      storesTags: _parseStringList(product['stores_tags']),
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

  /// Parsea una lista de strings desde la API
  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((v) => v.toString()).toList();
    }
    return [];
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
    'saturatedFatPer100g': saturatedFatPer100g,
    'sodiumPer100g': sodiumPer100g,
    'portionName': portionName,
    'portionGrams': portionGrams,
    'nutriScore': nutriScore,
    'novaGroup': novaGroup,
    'countriesTags': countriesTags,
    'storesTags': storesTags,
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
      saturatedFatPer100g: (json['saturatedFatPer100g'] as num?)?.toDouble(),
      sodiumPer100g: (json['sodiumPer100g'] as num?)?.toDouble(),
      portionName: json['portionName'] as String?,
      portionGrams: (json['portionGrams'] as num?)?.toDouble(),
      nutriScore: json['nutriScore'] as String?,
      novaGroup: json['novaGroup'] as int?,
      countriesTags: (json['countriesTags'] as List<dynamic>?)?.cast<String>() ?? const [],
      storesTags: (json['storesTags'] as List<dynamic>?)?.cast<String>() ?? const [],
      source: json['source'] as String,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }

  @override
  String toString() => 'OpenFoodFactsResult($name, ${brand ?? "sin marca"}, ${kcalPer100g}kcal/100g)';

  /// Convierte este resultado a un FoodModel
  /// 
  /// Nota: El id debe ser generado por el repositorio (uuid)
  Map<String, dynamic> toFoodModelJson() => {
    'name': name,
    'brand': brand,
    'barcode': code,
    'kcalPer100g': kcalPer100g.toInt(),
    'proteinPer100g': proteinPer100g,
    'carbsPer100g': carbsPer100g,
    'fatPer100g': fatPer100g,
    'fiberPer100g': fiberPer100g,
    'sugarPer100g': sugarPer100g,
    'saturatedFatPer100g': saturatedFatPer100g,
    'sodiumPer100g': sodiumPer100g,
    'portionName': portionName ?? 'Porción',
    'portionGrams': portionGrams ?? 100.0,
    'userCreated': false,
    'verifiedSource': source,
    'sourceMetadata': {
      'fetchedAt': fetchedAt.toIso8601String(),
      'imageUrl': imageUrl,
      'ingredientsText': ingredientsText,
    },
  };
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
    final rawProducts = json['products'] as List<dynamic>? ?? [];

    final products = <OpenFoodFactsResult>[];

    for (final p in rawProducts) {
      if (p is! Map) continue;

      final productMap = Map<String, dynamic>.from(p);

      // Filtrar productos sin nombre
      final productName = productMap['product_name'] as String?;
      final genericName = productMap['generic_name'] as String?;
      final hasValidName = (productName != null && productName.trim().isNotEmpty) ||
          (genericName != null && genericName.trim().isNotEmpty);

      if (!hasValidName) continue;

      // Filtrar productos sin nutriments
      final nutriments = productMap['nutriments'] as Map?;
      if (nutriments == null || nutriments.isEmpty) continue;

      // Parse el producto
      final result = OpenFoodFactsResult.fromApiJson({
        'product': productMap,
        'code': productMap['code'] ?? '',
      });

      // Filtrar productos sin datos nutricionales válidos
      if (!result.hasValidNutrition) continue;

      // Filtrar productos con nombre genérico "Producto sin nombre"
      if (result.name == 'Producto sin nombre') continue;

      products.add(result);
    }

    final count = json['count'] as int? ?? 0;
    final page = json['page'] as int? ?? 1;
    final pageSize = json['page_size'] as int? ?? 20;

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
