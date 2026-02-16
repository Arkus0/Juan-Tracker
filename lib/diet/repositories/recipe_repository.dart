import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../training/database/database.dart';
import '../models/recipe_model.dart';
import '../models/food_model.dart';
import '../models/diary_entry_model.dart' as diary;

/// Convierte ServingUnit del modelo (diary) al de la DB
ServingUnit _modelUnitToDb(diary.ServingUnit unit) {
  return ServingUnit.values.firstWhere((e) => e.name == unit.name);
}

/// Convierte ServingUnit de la DB al del modelo (diary)
diary.ServingUnit _dbUnitToModel(ServingUnit unit) {
  return diary.ServingUnit.values.firstWhere((e) => e.name == unit.name);
}

/// Repositorio para gestionar recetas (comidas compuestas).
///
/// Permite crear, editar, eliminar y buscar recetas con sus ingredientes.
/// Cada receta se almacena con snapshots nutricionales de cada ingrediente
/// para que los cálculos no se vean afectados si se modifica el alimento original.
class RecipeRepository {
  final AppDatabase _db;

  RecipeRepository(this._db);

  // ============================================================================
  // LECTURA
  // ============================================================================

  /// Obtiene todas las recetas ordenadas por fecha de actualización (más recientes primero)
  Future<List<RecipeModel>> getAll() async {
    final rows = await (_db.select(_db.recipes)
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .get();

    return Future.wait(rows.map((r) => _loadRecipeWithItems(r)));
  }

  /// Stream de todas las recetas (reactivo)
  Stream<List<RecipeModel>> watchAll() {
    final query = _db.select(_db.recipes)
      ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]);

    return query.watch().asyncMap((rows) async {
      return Future.wait(rows.map((r) => _loadRecipeWithItems(r)));
    });
  }

  /// Obtiene una receta por ID
  Future<RecipeModel?> getById(String id) async {
    final row = await (_db.select(_db.recipes)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();

    if (row == null) return null;
    return _loadRecipeWithItems(row);
  }

  /// Busca recetas por nombre
  Future<List<RecipeModel>> search(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return getAll();

    final rows = await (_db.select(_db.recipes)
          ..where((r) => r.name.lower().contains(normalized))
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .get();

    return Future.wait(rows.map((r) => _loadRecipeWithItems(r)));
  }

  // ============================================================================
  // ESCRITURA
  // ============================================================================

  /// Crea una nueva receta con sus ingredientes en una transacción
  Future<RecipeModel> create({
    required String name,
    String? description,
    int servings = 1,
    String? servingName,
    required List<RecipeItemModel> items,
  }) async {
    final recipe = RecipeModel.fromItems(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      servings: servings,
      servingName: servingName,
      items: items,
    );

    await _db.transaction(() async {
      await _db.into(_db.recipes).insert(_recipeToCompanion(recipe));
      for (final item in recipe.items) {
        await _db.into(_db.recipeItems).insert(_itemToCompanion(item));
      }
    });

    return recipe;
  }

  /// Actualiza una receta existente: reemplaza todos los items
  Future<RecipeModel> update({
    required String id,
    required String name,
    String? description,
    int servings = 1,
    String? servingName,
    required List<RecipeItemModel> items,
  }) async {
    final recipe = RecipeModel.fromItems(
      id: id,
      name: name,
      description: description,
      servings: servings,
      servingName: servingName,
      items: items,
    );

    await _db.transaction(() async {
      // Eliminar items anteriores
      await (_db.delete(_db.recipeItems)
            ..where((ri) => ri.recipeId.equals(id)))
          .go();

      // Actualizar la receta
      await (_db.update(_db.recipes)..where((r) => r.id.equals(id)))
          .write(_recipeToCompanion(recipe));

      // Insertar nuevos items
      for (final item in recipe.items) {
        await _db.into(_db.recipeItems).insert(_itemToCompanion(item));
      }
    });

    return recipe;
  }

  /// Elimina una receta y sus items (CASCADE)
  Future<void> delete(String id) async {
    await (_db.delete(_db.recipes)..where((r) => r.id.equals(id))).go();
  }

  // ============================================================================
  // INTEGRACIÓN CON FOODS
  // ============================================================================

  /// Guarda la receta como un alimento (Food) para poder añadirla al diario
  /// Convierte los macros a per-100g y la inserta en la tabla foods + FTS5
  Future<FoodModel> saveAsFood(RecipeModel recipe) async {
    final food = recipe.toFoodModel();

    await _db.into(_db.foods).insertOnConflictUpdate(FoodsCompanion.insert(
      id: food.id,
      name: food.name,
      kcalPer100g: food.kcalPer100g,
      proteinPer100g: Value(food.proteinPer100g),
      carbsPer100g: Value(food.carbsPer100g),
      fatPer100g: Value(food.fatPer100g),
      fiberPer100g: Value(food.fiberPer100g),
      sugarPer100g: Value(food.sugarPer100g),
      saturatedFatPer100g: Value(food.saturatedFatPer100g),
      sodiumPer100g: Value(food.sodiumPer100g),
      portionName: Value(food.portionName),
      portionGrams: Value(food.portionGrams),
      userCreated: const Value(true),
      createdAt: food.createdAt,
      updatedAt: food.updatedAt,
    ));

    // Actualizar índice FTS5
    await _db.insertFoodFts(food.id, food.name, null);

    return food;
  }

  // ============================================================================
  // HELPERS PRIVADOS
  // ============================================================================

  Future<RecipeModel> _loadRecipeWithItems(Recipe row) async {
    final itemRows = await (_db.select(_db.recipeItems)
          ..where((ri) => ri.recipeId.equals(row.id))
          ..orderBy([(ri) => OrderingTerm.asc(ri.sortOrder)]))
        .get();

    final items = itemRows.map((ri) => _itemFromRow(ri, row.id)).toList();

    return RecipeModel(
      id: row.id,
      name: row.name,
      description: row.description,
      totalKcal: row.totalKcal,
      totalProtein: row.totalProtein,
      totalCarbs: row.totalCarbs,
      totalFat: row.totalFat,
      totalFiber: row.totalFiber,
      totalSugar: row.totalSugar,
      totalSaturatedFat: row.totalSaturatedFat,
      totalSodium: row.totalSodium,
      totalGrams: row.totalGrams,
      servings: row.servings,
      servingName: row.servingName,
      userCreated: row.userCreated,
      items: items,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  RecipeItemModel _itemFromRow(RecipeItem ri, String recipeId) {
    return RecipeItemModel(
      id: ri.id,
      recipeId: recipeId,
      foodId: ri.foodId,
      amount: ri.amount,
      unit: _dbUnitToModel(ri.unit),
      foodNameSnapshot: ri.foodNameSnapshot,
      kcalPer100gSnapshot: ri.kcalPer100gSnapshot,
      proteinPer100gSnapshot: ri.proteinPer100gSnapshot,
      carbsPer100gSnapshot: ri.carbsPer100gSnapshot,
      fatPer100gSnapshot: ri.fatPer100gSnapshot,
      fiberPer100gSnapshot: ri.fiberPer100gSnapshot,
      sugarPer100gSnapshot: ri.sugarPer100gSnapshot,
      saturatedFatPer100gSnapshot: ri.saturatedFatPer100gSnapshot,
      sodiumPer100gSnapshot: ri.sodiumPer100gSnapshot,
      portionGramsSnapshot: ri.portionGramsSnapshot,
      sortOrder: ri.sortOrder,
    );
  }

  RecipesCompanion _recipeToCompanion(RecipeModel recipe) {
    return RecipesCompanion(
      id: Value(recipe.id),
      name: Value(recipe.name),
      description: Value(recipe.description),
      totalKcal: Value(recipe.totalKcal),
      totalProtein: Value(recipe.totalProtein),
      totalCarbs: Value(recipe.totalCarbs),
      totalFat: Value(recipe.totalFat),
      totalFiber: Value(recipe.totalFiber),
      totalSugar: Value(recipe.totalSugar),
      totalSaturatedFat: Value(recipe.totalSaturatedFat),
      totalSodium: Value(recipe.totalSodium),
      totalGrams: Value(recipe.totalGrams),
      servings: Value(recipe.servings),
      servingName: Value(recipe.servingName),
      userCreated: Value(recipe.userCreated),
      createdAt: Value(recipe.createdAt),
      updatedAt: Value(recipe.updatedAt),
    );
  }

  RecipeItemsCompanion _itemToCompanion(RecipeItemModel item) {
    return RecipeItemsCompanion(
      id: Value(item.id),
      recipeId: Value(item.recipeId),
      foodId: Value(item.foodId),
      amount: Value(item.amount),
      unit: Value(_modelUnitToDb(item.unit)),
      foodNameSnapshot: Value(item.foodNameSnapshot),
      kcalPer100gSnapshot: Value(item.kcalPer100gSnapshot),
      proteinPer100gSnapshot: Value(item.proteinPer100gSnapshot),
      carbsPer100gSnapshot: Value(item.carbsPer100gSnapshot),
      fatPer100gSnapshot: Value(item.fatPer100gSnapshot),
      fiberPer100gSnapshot: Value(item.fiberPer100gSnapshot),
      sugarPer100gSnapshot: Value(item.sugarPer100gSnapshot),
      saturatedFatPer100gSnapshot: Value(item.saturatedFatPer100gSnapshot),
      sodiumPer100gSnapshot: Value(item.sodiumPer100gSnapshot),
      portionGramsSnapshot: Value(item.portionGramsSnapshot),
      sortOrder: Value(item.sortOrder),
    );
  }
}

/// Provider del repositorio de recetas
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecipeRepository(db);
});
