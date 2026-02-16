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

  // Micronutrientes por 100g
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? saturatedFatPer100g;
  final double? sodiumPer100g;

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
    this.fiberPer100g,
    this.sugarPer100g,
    this.saturatedFatPer100g,
    this.sodiumPer100g,
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

  /// Calcula la fibra para una cantidad dada en gramos
  double? fiberForGrams(double grams) =>
      fiberPer100g != null ? grams / 100 * fiberPer100g! : null;

  /// Calcula el azúcar para una cantidad dada en gramos
  double? sugarForGrams(double grams) =>
      sugarPer100g != null ? grams / 100 * sugarPer100g! : null;

  /// Calcula la grasa saturada para una cantidad dada en gramos
  double? saturatedFatForGrams(double grams) =>
      saturatedFatPer100g != null ? grams / 100 * saturatedFatPer100g! : null;

  /// Calcula el sodio para una cantidad dada en gramos
  double? sodiumForGrams(double grams) =>
      sodiumPer100g != null ? grams / 100 * sodiumPer100g! : null;

  /// Calcula las macros para una cantidad dada
  Macros macrosForGrams(double grams) => Macros(
        kcal: kcalForGrams(grams),
        protein: proteinForGrams(grams),
        carbs: carbsForGrams(grams),
        fat: fatForGrams(grams),
        fiber: fiberForGrams(grams),
        sugar: sugarForGrams(grams),
        saturatedFat: saturatedFatForGrams(grams),
        sodium: sodiumForGrams(grams),
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
    double? fiberPer100g,
    double? sugarPer100g,
    double? saturatedFatPer100g,
    double? sodiumPer100g,
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
        fiberPer100g: fiberPer100g ?? this.fiberPer100g,
        sugarPer100g: sugarPer100g ?? this.sugarPer100g,
        saturatedFatPer100g: saturatedFatPer100g ?? this.saturatedFatPer100g,
        sodiumPer100g: sodiumPer100g ?? this.sodiumPer100g,
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
  final double? fiber;
  final double? sugar;
  final double? saturatedFat;
  final double? sodium;

  const Macros({
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.saturatedFat,
    this.sodium,
  });

  /// Suma dos Macros preservando null cuando ambos son desconocidos
  /// - null + null = null (ambos desconocidos)
  /// - null + valor = valor (preserva lo conocido)
  /// - valor + valor = suma
  Macros operator +(Macros other) => Macros(
        kcal: kcal + other.kcal,
        protein: _sumNullable(protein, other.protein),
        carbs: _sumNullable(carbs, other.carbs),
        fat: _sumNullable(fat, other.fat),
        fiber: _sumNullable(fiber, other.fiber),
        sugar: _sumNullable(sugar, other.sugar),
        saturatedFat: _sumNullable(saturatedFat, other.saturatedFat),
        sodium: _sumNullable(sodium, other.sodium),
      );

  /// Helper para sumar valores nullable preservando semántica
  static double? _sumNullable(double? a, double? b) {
    if (a == null && b == null) return null;
    return (a ?? 0) + (b ?? 0);
  }

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
