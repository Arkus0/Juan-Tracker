/// Modelo de datos para cache de búsquedas
/// 
/// Almacena resultados de búsqueda en SQLite con TTL y metadatos
class CachedSearchResult {
  final String query;
  final List<CachedFoodItem> items;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final int totalCount;
  final String source; // 'api', 'local', 'hybrid'

  const CachedSearchResult({
    required this.query,
    required this.items,
    required this.cachedAt,
    required this.expiresAt,
    required this.totalCount,
    required this.source,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'query': query,
    'items': items.map((i) => i.toJson()).toList(),
    'cachedAt': cachedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'totalCount': totalCount,
    'source': source,
  };

  factory CachedSearchResult.fromJson(Map<String, dynamic> json) {
    return CachedSearchResult(
      query: json['query'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => CachedFoodItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      totalCount: json['totalCount'] as int,
      source: json['source'] as String,
    );
  }
}

/// Item individual cacheado (versión ligera de OpenFoodFactsResult)
class CachedFoodItem {
  final String code;
  final String name;
  final String? brand;
  final String? imageUrl;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final String? nutriScore;
  final int? novaGroup;
  
  // Metadatos de disponibilidad
  final List<String> countriesTags;
  final List<String> storesTags;
  final DateTime fetchedAt;

  const CachedFoodItem({
    required this.code,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.nutriScore,
    this.novaGroup,
    this.countriesTags = const [],
    this.storesTags = const [],
    required this.fetchedAt,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'brand': brand,
    'imageUrl': imageUrl,
    'kcalPer100g': kcalPer100g,
    'proteinPer100g': proteinPer100g,
    'carbsPer100g': carbsPer100g,
    'fatPer100g': fatPer100g,
    'nutriScore': nutriScore,
    'novaGroup': novaGroup,
    'countriesTags': countriesTags,
    'storesTags': storesTags,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory CachedFoodItem.fromJson(Map<String, dynamic> json) {
    return CachedFoodItem(
      code: json['code'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      imageUrl: json['imageUrl'] as String?,
      kcalPer100g: (json['kcalPer100g'] as num).toDouble(),
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble(),
      carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble(),
      fatPer100g: (json['fatPer100g'] as num?)?.toDouble(),
      nutriScore: json['nutriScore'] as String?,
      novaGroup: json['novaGroup'] as int?,
      countriesTags: (json['countriesTags'] as List<dynamic>?)?.cast<String>() ?? const [],
      storesTags: (json['storesTags'] as List<dynamic>?)?.cast<String>() ?? const [],
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }
}
