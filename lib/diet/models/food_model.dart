/// Modelo de dominio para Alimentos
/// Representa un alimento con sus valores nutricionales
class FoodModel {
  final String id;
  final String name;
  final String? brand;
  final String? barcode;

  // Valores por 100g
  final int kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;

  // Información de porción (opcional)
  final String? portionName;
  final double? portionGrams;

  // Flags
  final bool userCreated;
  final String? verifiedSource;
  final Map<String, dynamic>? sourceMetadata;

  final DateTime createdAt;
  final DateTime updatedAt;

  FoodModel({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.portionName,
    this.portionGrams,
    this.userCreated = true,
    this.verifiedSource,
    this.sourceMetadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calcula las calorías para una cantidad dada en gramos
  int kcalForGrams(double grams) =>
      (grams / 100 * kcalPer100g).round();

  /// Calcula las proteínas para una cantidad dada en gramos
  double? proteinForGrams(double grams) =>
      proteinPer100g != null ? grams / 100 * proteinPer100g! : null;

  /// Calcula los carbs para una cantidad dada en gramos
  double? carbsForGrams(double grams) =>
      carbsPer100g != null ? grams / 100 * carbsPer100g! : null;

  /// Calcula las grasas para una cantidad dada en gramos
  double? fatForGrams(double grams) =>
      fatPer100g != null ? grams / 100 * fatPer100g! : null;

  /// Calcula las macros para una cantidad dada
  Macros macrosForGrams(double grams) => Macros(
        kcal: kcalForGrams(grams),
        protein: proteinForGrams(grams),
        carbs: carbsForGrams(grams),
        fat: fatForGrams(grams),
      );

  /// Crea una copia con valores modificados
  FoodModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? barcode,
    int? kcalPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    String? portionName,
    double? portionGrams,
    bool? userCreated,
    String? verifiedSource,
    Map<String, dynamic>? sourceMetadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      FoodModel(
        id: id ?? this.id,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        barcode: barcode ?? this.barcode,
        kcalPer100g: kcalPer100g ?? this.kcalPer100g,
        proteinPer100g: proteinPer100g ?? this.proteinPer100g,
        carbsPer100g: carbsPer100g ?? this.carbsPer100g,
        fatPer100g: fatPer100g ?? this.fatPer100g,
        portionName: portionName ?? this.portionName,
        portionGrams: portionGrams ?? this.portionGrams,
        userCreated: userCreated ?? this.userCreated,
        verifiedSource: verifiedSource ?? this.verifiedSource,
        sourceMetadata: sourceMetadata ?? this.sourceMetadata,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Serialización mínima para debugging
  Map<String, dynamic> toDebugMap() => {
        'id': id,
        'name': name,
        'brand': brand,
        'kcalPer100g': kcalPer100g,
        'proteinPer100g': proteinPer100g,
        'carbsPer100g': carbsPer100g,
        'fatPer100g': fatPer100g,
      };

  @override
  String toString() => 'FoodModel(${toDebugMap()})';
}

/// Representa valores nutricionales calculados
class Macros {
  final int kcal;
  final double? protein;
  final double? carbs;
  final double? fat;

  const Macros({
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
  });

  /// Suma dos Macros
  Macros operator +(Macros other) => Macros(
        kcal: kcal + other.kcal,
        protein: (protein ?? 0) + (other.protein ?? 0),
        carbs: (carbs ?? 0) + (other.carbs ?? 0),
        fat: (fat ?? 0) + (other.fat ?? 0),
      );

  static const Macros zero = Macros(kcal: 0);

  Map<String, dynamic> toDebugMap() => {
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  @override
  String toString() => 'Macros(${toDebugMap()})';
}
