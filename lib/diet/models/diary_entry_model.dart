import 'food_model.dart';

/// Tipos de comida del día
enum MealType { breakfast, lunch, dinner, snack }

/// Unidades de medida para porciones
enum ServingUnit { grams, portion, milliliter }

/// Extensión para mostrar nombres en español
extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Desayuno';
      case MealType.lunch:
        return 'Almuerzo';
      case MealType.dinner:
        return 'Cena';
      case MealType.snack:
        return 'Snack';
    }
  }
}

/// Modelo de dominio para entradas del diario
class DiaryEntryModel {
  final String id;
  final DateTime date; // Truncado a día
  final MealType mealType;

  // Referencia opcional a Food
  final String? foodId;

  // Información del alimento (denormalizada)
  final String foodName;
  final String? foodBrand;

  // Cantidad
  final double amount;
  final ServingUnit unit;

  // Valores nutricionales calculados (desnormalizado)
  final int kcal;
  final double? protein;
  final double? carbs;
  final double? fat;

  // Micronutrientes
  final double? fiber;
  final double? sugar;
  final double? saturatedFat;
  final double? sodium;

  // Flags
  final bool isQuickAdd;
  final String? notes;

  final DateTime createdAt;

  DiaryEntryModel({
    required this.id,
    required this.date,
    required this.mealType,
    this.foodId,
    required this.foodName,
    this.foodBrand,
    required this.amount,
    required this.unit,
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.saturatedFat,
    this.sodium,
    this.isQuickAdd = false,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Crea una entrada a partir de un FoodModel
  factory DiaryEntryModel.fromFood({
    required String id,
    required DateTime date,
    required MealType mealType,
    required FoodModel food,
    required double amount,
    required ServingUnit unit,
    String? notes,
  }) {
    // Calcular gramos basado en la unidad
    final grams = unit == ServingUnit.portion && food.portionGrams != null
        ? amount * food.portionGrams!
        : amount;

    final macros = food.macrosForGrams(grams);

    return DiaryEntryModel(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      mealType: mealType,
      foodId: food.id,
      foodName: food.name,
      foodBrand: food.brand,
      amount: amount,
      unit: unit,
      kcal: macros.kcal,
      protein: macros.protein,
      carbs: macros.carbs,
      fat: macros.fat,
      fiber: macros.fiber,
      sugar: macros.sugar,
      saturatedFat: macros.saturatedFat,
      sodium: macros.sodium,
      isQuickAdd: false,
      notes: notes,
    );
  }

  /// Crea una entrada "quick add" sin referencia a Food
  factory DiaryEntryModel.quickAdd({
    required String id,
    required DateTime date,
    required MealType mealType,
    required String name,
    required int kcal,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? saturatedFat,
    double? sodium,
    String? notes,
  }) =>
      DiaryEntryModel(
        id: id,
        date: DateTime(date.year, date.month, date.day),
        mealType: mealType,
        foodId: null,
        foodName: name,
        foodBrand: null,
        amount: 1,
        unit: ServingUnit.portion,
        kcal: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        sugar: sugar,
        saturatedFat: saturatedFat,
        sodium: sodium,
        isQuickAdd: true,
        notes: notes,
      );

  /// Crea una copia con valores modificados
  DiaryEntryModel copyWith({
    String? id,
    DateTime? date,
    MealType? mealType,
    String? foodId,
    String? foodName,
    String? foodBrand,
    double? amount,
    ServingUnit? unit,
    int? kcal,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? saturatedFat,
    double? sodium,
    bool? isQuickAdd,
    String? notes,
    DateTime? createdAt,
  }) =>
      DiaryEntryModel(
        id: id ?? this.id,
        date: date ?? this.date,
        mealType: mealType ?? this.mealType,
        foodId: foodId ?? this.foodId,
        foodName: foodName ?? this.foodName,
        foodBrand: foodBrand ?? this.foodBrand,
        amount: amount ?? this.amount,
        unit: unit ?? this.unit,
        kcal: kcal ?? this.kcal,
        protein: protein ?? this.protein,
        carbs: carbs ?? this.carbs,
        fat: fat ?? this.fat,
        fiber: fiber ?? this.fiber,
        sugar: sugar ?? this.sugar,
        saturatedFat: saturatedFat ?? this.saturatedFat,
        sodium: sodium ?? this.sodium,
        isQuickAdd: isQuickAdd ?? this.isQuickAdd,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toDebugMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'mealType': mealType.name,
        'foodName': foodName,
        'amount': amount,
        'unit': unit.name,
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  @override
  String toString() => 'DiaryEntryModel(${toDebugMap()})';
}

/// Totales diarios calculados
class DailyTotals {
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double saturatedFat;
  final double sodium;
  final Map<MealType, MealTotals> byMeal;

  const DailyTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.saturatedFat = 0,
    this.sodium = 0,
    required this.byMeal,
  });

  static const DailyTotals empty = DailyTotals(
    kcal: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
    sugar: 0,
    saturatedFat: 0,
    sodium: 0,
    byMeal: {},
  );

  /// Calcula totales desde una lista de entradas
  factory DailyTotals.fromEntries(List<DiaryEntryModel> entries) {
    if (entries.isEmpty) return DailyTotals.empty;

    int totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSaturatedFat = 0;
    double totalSodium = 0;

    final mealMap = <MealType, List<DiaryEntryModel>>{};

    for (final entry in entries) {
      totalKcal += entry.kcal;
      totalProtein += entry.protein ?? 0;
      totalCarbs += entry.carbs ?? 0;
      totalFat += entry.fat ?? 0;
      totalFiber += entry.fiber ?? 0;
      totalSugar += entry.sugar ?? 0;
      totalSaturatedFat += entry.saturatedFat ?? 0;
      totalSodium += entry.sodium ?? 0;

      mealMap.putIfAbsent(entry.mealType, () => []).add(entry);
    }

    final byMeal = <MealType, MealTotals>{};
    for (final meal in MealType.values) {
      final mealEntries = mealMap[meal] ?? [];
      byMeal[meal] = MealTotals.fromEntries(mealEntries);
    }

    return DailyTotals(
      kcal: totalKcal,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sugar: totalSugar,
      saturatedFat: totalSaturatedFat,
      sodium: totalSodium,
      byMeal: byMeal,
    );
  }

  Map<String, dynamic> toDebugMap() => {
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'byMeal': byMeal.map((k, v) => MapEntry(k.name, v.toDebugMap())),
      };

  @override
  String toString() => 'DailyTotals(${toDebugMap()})';
}

/// Totales por tipo de comida
class MealTotals {
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double saturatedFat;
  final double sodium;
  final int entryCount;

  const MealTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.saturatedFat = 0,
    this.sodium = 0,
    required this.entryCount,
  });

  static const MealTotals empty = MealTotals(
    kcal: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    fiber: 0,
    sugar: 0,
    saturatedFat: 0,
    sodium: 0,
    entryCount: 0,
  );

  factory MealTotals.fromEntries(List<DiaryEntryModel> entries) {
    if (entries.isEmpty) return MealTotals.empty;

    int kcal = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;
    double sugar = 0;
    double saturatedFat = 0;
    double sodium = 0;

    for (final entry in entries) {
      kcal += entry.kcal;
      protein += entry.protein ?? 0;
      carbs += entry.carbs ?? 0;
      fat += entry.fat ?? 0;
      fiber += entry.fiber ?? 0;
      sugar += entry.sugar ?? 0;
      saturatedFat += entry.saturatedFat ?? 0;
      sodium += entry.sodium ?? 0;
    }

    return MealTotals(
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      saturatedFat: saturatedFat,
      sodium: sodium,
      entryCount: entries.length,
    );
  }

  Map<String, dynamic> toDebugMap() => {
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'entryCount': entryCount,
      };

  @override
  String toString() => 'MealTotals(${toDebugMap()})';
}
