import 'package:uuid/uuid.dart';

import '../../training/database/database.dart';

/// Modelo de dominio para una plantilla de comida
/// 
/// Permite guardar una comida completa (ej: "Desayuno típico") 
/// para añadirla al diario con 1 toque.
class MealTemplateModel {
  final String id;
  final String name;
  final MealType mealType;
  final int useCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MealTemplateItemModel> items;

  MealTemplateModel({
    required this.id,
    required this.name,
    required this.mealType,
    this.useCount = 0,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  /// Constructor para crear una nueva plantilla
  factory MealTemplateModel.create({
    required String name,
    required MealType mealType,
    List<MealTemplateItemModel> items = const [],
  }) {
    final now = DateTime.now();
    return MealTemplateModel(
      id: const Uuid().v4(),
      name: name,
      mealType: mealType,
      useCount: 0,
      lastUsedAt: null,
      createdAt: now,
      updatedAt: now,
      items: items,
    );
  }

  /// Total de calorías de la plantilla
  int get totalKcal {
    return items.fold(0, (sum, item) => sum + item.kcal);
  }

  /// Total de proteínas de la plantilla
  double get totalProtein {
    return items.fold(0.0, (sum, item) => sum + (item.protein ?? 0));
  }

  /// Total de carbohidratos de la plantilla
  double get totalCarbs {
    return items.fold(0.0, (sum, item) => sum + (item.carbs ?? 0));
  }

  /// Total de grasas de la plantilla
  double get totalFat {
    return items.fold(0.0, (sum, item) => sum + (item.fat ?? 0));
  }

  /// Número de items en la plantilla
  int get itemCount => items.length;

  /// Copia con modificaciones
  MealTemplateModel copyWith({
    String? id,
    String? name,
    MealType? mealType,
    int? useCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MealTemplateItemModel>? items,
  }) {
    return MealTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      useCount: useCount ?? this.useCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  /// Marca la plantilla como usada (incrementa contador y actualiza fecha)
  MealTemplateModel markAsUsed() {
    return copyWith(
      useCount: useCount + 1,
      lastUsedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() => 'MealTemplateModel($name, ${items.length} items, $totalKcal kcal)';
}

/// Modelo de dominio para un item de plantilla de comida
class MealTemplateItemModel {
  final String id;
  final String templateId;
  final String foodId;
  final double amount;
  final ServingUnit unit;
  final String foodName;
  final int kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? fiberPer100g;
  final double? sugarPer100g;
  final double? saturatedFatPer100g;
  final double? sodiumPer100g;
  final int sortOrder;

  MealTemplateItemModel({
    required this.id,
    required this.templateId,
    required this.foodId,
    required this.amount,
    required this.unit,
    required this.foodName,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.fiberPer100g,
    this.sugarPer100g,
    this.saturatedFatPer100g,
    this.sodiumPer100g,
    this.sortOrder = 0,
  });

  /// Constructor para crear un nuevo item desde un Food
  factory MealTemplateItemModel.fromFood({
    required String templateId,
    required Food food,
    required double amount,
    ServingUnit unit = ServingUnit.grams,
    int sortOrder = 0,
  }) {
    return MealTemplateItemModel(
      id: const Uuid().v4(),
      templateId: templateId,
      foodId: food.id,
      amount: amount,
      unit: unit,
      foodName: food.name,
      kcalPer100g: food.kcalPer100g,
      proteinPer100g: food.proteinPer100g,
      carbsPer100g: food.carbsPer100g,
      fatPer100g: food.fatPer100g,
      fiberPer100g: food.fiberPer100g,
      sugarPer100g: food.sugarPer100g,
      saturatedFatPer100g: food.saturatedFatPer100g,
      sodiumPer100g: food.sodiumPer100g,
      sortOrder: sortOrder,
    );
  }

  /// Calorías calculadas para esta cantidad
  int get kcal => (kcalPer100g * amount / 100).round();

  /// Proteína calculada para esta cantidad
  double? get protein => proteinPer100g != null 
      ? proteinPer100g! * amount / 100 
      : null;

  /// Carbohidratos calculados para esta cantidad
  double? get carbs => carbsPer100g != null 
      ? carbsPer100g! * amount / 100 
      : null;

  /// Grasa calculada para esta cantidad
  double? get fat => fatPer100g != null 
      ? fatPer100g! * amount / 100 
      : null;

  /// Fibra calculada para esta cantidad
  double? get fiber => fiberPer100g != null 
      ? fiberPer100g! * amount / 100 
      : null;

  /// Azúcar calculado para esta cantidad
  double? get sugar => sugarPer100g != null 
      ? sugarPer100g! * amount / 100 
      : null;

  /// Grasa saturada calculada para esta cantidad
  double? get saturatedFat => saturatedFatPer100g != null 
      ? saturatedFatPer100g! * amount / 100 
      : null;

  /// Sodio calculado para esta cantidad
  double? get sodium => sodiumPer100g != null 
      ? sodiumPer100g! * amount / 100 
      : null;

  /// Texto descriptivo del item
  String get description => '${amount.toStringAsFixed(0)}g $foodName';

  MealTemplateItemModel copyWith({
    String? id,
    String? templateId,
    String? foodId,
    double? amount,
    ServingUnit? unit,
    String? foodName,
    int? kcalPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? fiberPer100g,
    double? sugarPer100g,
    double? saturatedFatPer100g,
    double? sodiumPer100g,
    int? sortOrder,
  }) {
    return MealTemplateItemModel(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      foodId: foodId ?? this.foodId,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      foodName: foodName ?? this.foodName,
      kcalPer100g: kcalPer100g ?? this.kcalPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      sugarPer100g: sugarPer100g ?? this.sugarPer100g,
      saturatedFatPer100g: saturatedFatPer100g ?? this.saturatedFatPer100g,
      sodiumPer100g: sodiumPer100g ?? this.sodiumPer100g,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() => 'MealTemplateItemModel($foodName, ${amount}g)';
}
