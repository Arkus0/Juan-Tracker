import 'food_model.dart';
import 'diary_entry_model.dart';

/// Modelo de dominio para Recetas (comidas compuestas)
class RecipeModel {
  final String id;
  final String name;
  final String? description;

  // Totales calculados
  final int totalKcal;
  final double? totalProtein;
  final double? totalCarbs;
  final double? totalFat;
  final double totalGrams;

  // Porciones
  final int servings;
  final String? servingName;

  final bool userCreated;
  final List<RecipeItemModel> items;

  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeModel({
    required this.id,
    required this.name,
    this.description,
    required this.totalKcal,
    this.totalProtein,
    this.totalCarbs,
    this.totalFat,
    required this.totalGrams,
    this.servings = 1,
    this.servingName,
    this.userCreated = true,
    required this.items,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Valores por porción
  double get servingGrams => totalGrams / servings;
  int get kcalPerServing => (totalKcal / servings).round();
  double? get proteinPerServing =>
      totalProtein != null ? totalProtein! / servings : null;
  double? get carbsPerServing =>
      totalCarbs != null ? totalCarbs! / servings : null;
  double? get fatPerServing =>
      totalFat != null ? totalFat! / servings : null;

  /// Crea una receta a partir de items
  factory RecipeModel.fromItems({
    required String id,
    required String name,
    String? description,
    int servings = 1,
    String? servingName,
    required List<RecipeItemModel> items,
  }) {
    int totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalGrams = 0;

    for (final item in items) {
      totalKcal += item.calculatedKcal;
      totalProtein += item.calculatedProtein ?? 0;
      totalCarbs += item.calculatedCarbs ?? 0;
      totalFat += item.calculatedFat ?? 0;
      totalGrams += item.amountInGrams;
    }

    return RecipeModel(
      id: id,
      name: name,
      description: description,
      totalKcal: totalKcal,
      totalProtein: totalProtein > 0 ? totalProtein : null,
      totalCarbs: totalCarbs > 0 ? totalCarbs : null,
      totalFat: totalFat > 0 ? totalFat : null,
      totalGrams: totalGrams,
      servings: servings,
      servingName: servingName,
      items: items,
    );
  }

  /// Convierte la receta a un FoodModel para usar en el diario
  FoodModel toFoodModel() => FoodModel(
        id: id,
        name: name,
        kcalPer100g: ((totalKcal / totalGrams) * 100).round(),
        proteinPer100g: totalProtein != null
            ? (totalProtein! / totalGrams) * 100
            : null,
        carbsPer100g:
            totalCarbs != null ? (totalCarbs! / totalGrams) * 100 : null,
        fatPer100g: totalFat != null ? (totalFat! / totalGrams) * 100 : null,
        portionName: servingName ?? 'porción',
        portionGrams: servingGrams,
        userCreated: userCreated,
      );

  /// Crea una DiaryEntryModel desde esta receta
  DiaryEntryModel toDiaryEntry({
    required String entryId,
    required DateTime date,
    required MealType mealType,
    double portions = 1,
    String? notes,
  }) {
    final macros = toFoodModel().macrosForGrams(servingGrams * portions);

    return DiaryEntryModel(
      id: entryId,
      date: date,
      mealType: mealType,
      foodId: id,
      foodName: name,
      foodBrand: null,
      amount: portions,
      unit: ServingUnit.portion,
      kcal: macros.kcal,
      protein: macros.protein,
      carbs: macros.carbs,
      fat: macros.fat,
      isQuickAdd: false,
      notes: notes,
    );
  }

  Map<String, dynamic> toDebugMap() => {
        'id': id,
        'name': name,
        'totalKcal': totalKcal,
        'servings': servings,
        'kcalPerServing': kcalPerServing,
        'itemCount': items.length,
      };

  @override
  String toString() => 'RecipeModel(${toDebugMap()})';
}

/// Modelo para ingredientes de una receta
class RecipeItemModel {
  final String id;
  final String recipeId;
  final String foodId;

  final double amount;
  final ServingUnit unit;

  // Snapshot del food en el momento de agregarlo
  final String foodNameSnapshot;
  final int kcalPer100gSnapshot;
  final double? proteinPer100gSnapshot;
  final double? carbsPer100gSnapshot;
  final double? fatPer100gSnapshot;

  final int sortOrder;

  RecipeItemModel({
    required this.id,
    required this.recipeId,
    required this.foodId,
    required this.amount,
    required this.unit,
    required this.foodNameSnapshot,
    required this.kcalPer100gSnapshot,
    this.proteinPer100gSnapshot,
    this.carbsPer100gSnapshot,
    this.fatPer100gSnapshot,
    this.sortOrder = 0,
  });

  /// Crea un item desde un FoodModel
  factory RecipeItemModel.fromFood({
    required String id,
    required String recipeId,
    required FoodModel food,
    required double amount,
    required ServingUnit unit,
    int sortOrder = 0,
  }) =>
      RecipeItemModel(
        id: id,
        recipeId: recipeId,
        foodId: food.id,
        amount: amount,
        unit: unit,
        foodNameSnapshot: food.name,
        kcalPer100gSnapshot: food.kcalPer100g,
        proteinPer100gSnapshot: food.proteinPer100g,
        carbsPer100gSnapshot: food.carbsPer100g,
        fatPer100gSnapshot: food.fatPer100g,
        sortOrder: sortOrder,
      );

  /// Cantidad en gramos para cálculos
  double get amountInGrams {
    if (unit == ServingUnit.grams) return amount;
    if (unit == ServingUnit.portion) {
      // Asumimos porción estándar de 100g si no hay info
      // En producción se usaría el portionGrams del food original
      return amount * 100;
    }
    // Para ml, asumimos densidad de agua (1g/ml)
    return amount;
  }

  /// Calorías calculadas para esta cantidad
  int get calculatedKcal =>
      (amountInGrams / 100 * kcalPer100gSnapshot).round();

  double? get calculatedProtein => proteinPer100gSnapshot != null
      ? amountInGrams / 100 * proteinPer100gSnapshot!
      : null;

  double? get calculatedCarbs => carbsPer100gSnapshot != null
      ? amountInGrams / 100 * carbsPer100gSnapshot!
      : null;

  double? get calculatedFat => fatPer100gSnapshot != null
      ? amountInGrams / 100 * fatPer100gSnapshot!
      : null;

  Map<String, dynamic> toDebugMap() => {
        'id': id,
        'foodName': foodNameSnapshot,
        'amount': amount,
        'unit': unit.name,
        'calculatedKcal': calculatedKcal,
      };

  @override
  String toString() => 'RecipeItemModel(${toDebugMap()})';
}
