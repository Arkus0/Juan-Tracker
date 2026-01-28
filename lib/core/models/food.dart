class Food {
  final String id;
  final String name;
  final String? brand;
  final String? barcode;
  final int kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final DateTime createdAt;

  Food({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
