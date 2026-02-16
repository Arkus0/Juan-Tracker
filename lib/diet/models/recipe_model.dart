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
  final double? totalFiber;
  final double? totalSugar;
  final double? totalSaturatedFat;
  final double? totalSodium;
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
    this.totalFiber,
    this.totalSugar,
    this.totalSaturatedFat,
    this.totalSodium,
    required this.totalGrams,
    this.servings = 1,
    this.servingName,
    this.userCreated = true,
    required this.items,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : assert(servings > 0, 'servings must be positive'),
        assert(totalGrams >= 0, 'totalGrams cannot be negative'),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Servings efectivos (mínimo 1 para evitar división por cero)
  int get _safeServings => servings > 0 ? servings : 1;

  /// Gramos totales efectivos (mínimo 1 para evitar división por cero)
  double get _safeTotalGrams => totalGrams > 0 ? totalGrams : 1;

  /// Valores por porción (usa _safeServings para evitar división por cero)
  double get servingGrams => totalGrams / _safeServings;
  int get kcalPerServing => (totalKcal / _safeServings).round();
  double? get proteinPerServing =>
      totalProtein != null ? totalProtein! / _safeServings : null;
  double? get carbsPerServing =>
      totalCarbs != null ? totalCarbs! / _safeServings : null;
  double? get fatPerServing =>
      totalFat != null ? totalFat! / _safeServings : null;
  double? get fiberPerServing =>
      totalFiber != null ? totalFiber! / _safeServings : null;
  double? get sugarPerServing =>
      totalSugar != null ? totalSugar! / _safeServings : null;
  double? get saturatedFatPerServing =>
      totalSaturatedFat != null ? totalSaturatedFat! / _safeServings : null;
  double? get sodiumPerServing =>
      totalSodium != null ? totalSodium! / _safeServings : null;

  /// Crea una receta a partir de items
  /// Valida que servings >= 1 para evitar división por cero
  factory RecipeModel.fromItems({
    required String id,
    required String name,
    String? description,
    int servings = 1,
    String? servingName,
    required List<RecipeItemModel> items,
  }) {
    // Asegurar servings >= 1
    final safeServings = servings > 0 ? servings : 1;

    int totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSaturatedFat = 0;
    double totalSodium = 0;
    double totalGrams = 0;

    for (final item in items) {
      totalKcal += item.calculatedKcal;
      totalProtein += item.calculatedProtein ?? 0;
      totalCarbs += item.calculatedCarbs ?? 0;
      totalFat += item.calculatedFat ?? 0;
      totalFiber += item.calculatedFiber ?? 0;
      totalSugar += item.calculatedSugar ?? 0;
      totalSaturatedFat += item.calculatedSaturatedFat ?? 0;
      totalSodium += item.calculatedSodium ?? 0;
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
      totalFiber: totalFiber > 0 ? totalFiber : null,
      totalSugar: totalSugar > 0 ? totalSugar : null,
      totalSaturatedFat: totalSaturatedFat > 0 ? totalSaturatedFat : null,
      totalSodium: totalSodium > 0 ? totalSodium : null,
      totalGrams: totalGrams,
      servings: safeServings,
      servingName: servingName,
      items: items,
    );
  }

  /// Convierte la receta a un FoodModel para usar en el diario
  /// Usa _safeTotalGrams para evitar división por cero
  FoodModel toFoodModel() => FoodModel(
        id: id,
        name: name,
        kcalPer100g: ((totalKcal / _safeTotalGrams) * 100).round(),
        proteinPer100g: totalProtein != null
            ? (totalProtein! / _safeTotalGrams) * 100
            : null,
        carbsPer100g:
            totalCarbs != null ? (totalCarbs! / _safeTotalGrams) * 100 : null,
        fatPer100g: totalFat != null ? (totalFat! / _safeTotalGrams) * 100 : null,
        fiberPer100g: totalFiber != null ? (totalFiber! / _safeTotalGrams) * 100 : null,
        sugarPer100g: totalSugar != null ? (totalSugar! / _safeTotalGrams) * 100 : null,
        saturatedFatPer100g: totalSaturatedFat != null ? (totalSaturatedFat! / _safeTotalGrams) * 100 : null,
        sodiumPer100g: totalSodium != null ? (totalSodium! / _safeTotalGrams) * 100 : null,
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
      fiber: macros.fiber,
      sugar: macros.sugar,
      saturatedFat: macros.saturatedFat,
      sodium: macros.sodium,
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
  final double? fiberPer100gSnapshot;
  final double? sugarPer100gSnapshot;
  final double? saturatedFatPer100gSnapshot;
  final double? sodiumPer100gSnapshot;
  final double? portionGramsSnapshot; // Gramos por porción del food original

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
    this.fiberPer100gSnapshot,
    this.sugarPer100gSnapshot,
    this.saturatedFatPer100gSnapshot,
    this.sodiumPer100gSnapshot,
    this.portionGramsSnapshot,
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
        fiberPer100gSnapshot: food.fiberPer100g,
        sugarPer100gSnapshot: food.sugarPer100g,
        saturatedFatPer100gSnapshot: food.saturatedFatPer100g,
        sodiumPer100gSnapshot: food.sodiumPer100g,
        portionGramsSnapshot: food.portionGrams,
        sortOrder: sortOrder,
      );

  /// Cantidad en gramos para cálculos
  /// Usa portionGramsSnapshot si está disponible, fallback a 100g
  double get amountInGrams {
    if (unit == ServingUnit.grams) return amount;
    if (unit == ServingUnit.portion) {
      // Usar el portionGrams real del food, fallback a 100g si no hay info
      final gramsPerPortion = portionGramsSnapshot ?? 100;
      return amount * gramsPerPortion;
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

  double? get calculatedFiber => fiberPer100gSnapshot != null
      ? amountInGrams / 100 * fiberPer100gSnapshot!
      : null;

  double? get calculatedSugar => sugarPer100gSnapshot != null
      ? amountInGrams / 100 * sugarPer100gSnapshot!
      : null;

  double? get calculatedSaturatedFat => saturatedFatPer100gSnapshot != null
      ? amountInGrams / 100 * saturatedFatPer100gSnapshot!
      : null;

  double? get calculatedSodium => sodiumPer100gSnapshot != null
      ? amountInGrams / 100 * sodiumPer100gSnapshot!
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
