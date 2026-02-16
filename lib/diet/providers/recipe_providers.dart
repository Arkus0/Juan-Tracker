import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recipe_model.dart';
import '../models/food_model.dart';
import '../models/diary_entry_model.dart' show ServingUnit;
import '../repositories/recipe_repository.dart';

/// Stream de todas las recetas (reactivo)
final recipesStreamProvider = StreamProvider<List<RecipeModel>>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  return repo.watchAll();
});

/// Obtener receta por ID
final recipeByIdProvider =
    FutureProvider.family<RecipeModel?, String>((ref, id) {
  final repo = ref.watch(recipeRepositoryProvider);
  return repo.getById(id);
});

/// Buscar recetas por nombre
final recipeSearchProvider =
    FutureProvider.family<List<RecipeModel>, String>((ref, query) {
  final repo = ref.watch(recipeRepositoryProvider);
  return repo.search(query);
});

// ============================================================================
// EDITOR STATE
// ============================================================================

/// Estado del editor de recetas
class RecipeEditorState {
  final String? id; // null = nueva receta
  final String name;
  final String? description;
  final int servings;
  final String? servingName;
  final List<RecipeItemModel> items;
  final bool isSaving;
  final String? errorMessage;

  const RecipeEditorState({
    this.id,
    this.name = '',
    this.description,
    this.servings = 1,
    this.servingName,
    this.items = const [],
    this.isSaving = false,
    this.errorMessage,
  });

  bool get isEditing => id != null;
  bool get isValid => name.trim().isNotEmpty && items.isNotEmpty;

  /// Totales calculados en vivo
  int get totalKcal =>
      items.fold(0, (sum, item) => sum + item.calculatedKcal);
  double get totalProtein =>
      items.fold(0.0, (sum, item) => sum + (item.calculatedProtein ?? 0));
  double get totalCarbs =>
      items.fold(0.0, (sum, item) => sum + (item.calculatedCarbs ?? 0));
  double get totalFat =>
      items.fold(0.0, (sum, item) => sum + (item.calculatedFat ?? 0));
  double get totalGrams =>
      items.fold(0.0, (sum, item) => sum + item.amountInGrams);

  /// Valores por porción
  int get _safeServings => servings > 0 ? servings : 1;
  int get kcalPerServing => (totalKcal / _safeServings).round();
  double get proteinPerServing => totalProtein / _safeServings;
  double get carbsPerServing => totalCarbs / _safeServings;
  double get fatPerServing => totalFat / _safeServings;

  RecipeEditorState copyWith({
    String? id,
    String? name,
    String? description,
    int? servings,
    String? servingName,
    List<RecipeItemModel>? items,
    bool? isSaving,
    String? errorMessage,
  }) {
    return RecipeEditorState(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      servingName: servingName ?? this.servingName,
      items: items ?? this.items,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier para el editor de recetas (crear/editar)
class RecipeEditorNotifier extends Notifier<RecipeEditorState> {
  @override
  RecipeEditorState build() => const RecipeEditorState();

  /// Inicializa para nueva receta
  void initNew() {
    state = const RecipeEditorState();
  }

  /// Inicializa para editar una receta existente
  void initFromRecipe(RecipeModel recipe) {
    state = RecipeEditorState(
      id: recipe.id,
      name: recipe.name,
      description: recipe.description,
      servings: recipe.servings,
      servingName: recipe.servingName,
      items: List.from(recipe.items),
    );
  }

  void setName(String name) => state = state.copyWith(name: name);
  void setDescription(String? desc) =>
      state = state.copyWith(description: desc);
  void setServings(int servings) =>
      state = state.copyWith(servings: servings.clamp(1, 99));
  void setServingName(String? name) =>
      state = state.copyWith(servingName: name);

  /// Añade un ingrediente desde un FoodModel
  void addIngredient(FoodModel food, double amount, ServingUnit unit) {
    final recipeId = state.id ?? 'new';
    final item = RecipeItemModel.fromFood(
      id: '${recipeId}_${DateTime.now().millisecondsSinceEpoch}',
      recipeId: recipeId,
      food: food,
      amount: amount,
      unit: unit,
      sortOrder: state.items.length,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  /// Actualiza la cantidad de un ingrediente
  void updateIngredientAmount(int index, double amount) {
    if (index < 0 || index >= state.items.length) return;
    final updated = List<RecipeItemModel>.from(state.items);
    final old = updated[index];
    updated[index] = RecipeItemModel(
      id: old.id,
      recipeId: old.recipeId,
      foodId: old.foodId,
      amount: amount,
      unit: old.unit,
      foodNameSnapshot: old.foodNameSnapshot,
      kcalPer100gSnapshot: old.kcalPer100gSnapshot,
      proteinPer100gSnapshot: old.proteinPer100gSnapshot,
      carbsPer100gSnapshot: old.carbsPer100gSnapshot,
      fatPer100gSnapshot: old.fatPer100gSnapshot,
      fiberPer100gSnapshot: old.fiberPer100gSnapshot,
      sugarPer100gSnapshot: old.sugarPer100gSnapshot,
      saturatedFatPer100gSnapshot: old.saturatedFatPer100gSnapshot,
      sodiumPer100gSnapshot: old.sodiumPer100gSnapshot,
      portionGramsSnapshot: old.portionGramsSnapshot,
      sortOrder: old.sortOrder,
    );
    state = state.copyWith(items: updated);
  }

  /// Elimina un ingrediente
  void removeIngredient(int index) {
    if (index < 0 || index >= state.items.length) return;
    final updated = List<RecipeItemModel>.from(state.items)..removeAt(index);
    state = state.copyWith(items: updated);
  }

  /// Reordena ingredientes
  void reorderIngredients(int oldIndex, int newIndex) {
    final updated = List<RecipeItemModel>.from(state.items);
    if (newIndex > oldIndex) newIndex--;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = state.copyWith(items: updated);
  }

  /// Guarda la receta (crear o actualizar)
  Future<RecipeModel?> save() async {
    if (!state.isValid) {
      state = state.copyWith(
        errorMessage: 'Nombre y al menos un ingrediente son requeridos',
      );
      return null;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final repo = ref.read(recipeRepositoryProvider);

      RecipeModel result;
      if (state.isEditing) {
        result = await repo.update(
          id: state.id!,
          name: state.name.trim(),
          description: state.description?.trim(),
          servings: state.servings,
          servingName: state.servingName?.trim(),
          items: state.items,
        );
      } else {
        result = await repo.create(
          name: state.name.trim(),
          description: state.description?.trim(),
          servings: state.servings,
          servingName: state.servingName?.trim(),
          items: state.items,
        );
      }

      // Invalidar streams
      ref.invalidate(recipesStreamProvider);

      state = state.copyWith(isSaving: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar: $e',
      );
      return null;
    }
  }

  /// Guarda la receta como alimento (Food) para uso en diario
  Future<FoodModel?> saveAsFood() async {
    if (!state.isValid) return null;

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final repo = ref.read(recipeRepositoryProvider);

      // Primero guardar la receta si es nueva
      RecipeModel recipe;
      if (state.isEditing) {
        recipe = await repo.update(
          id: state.id!,
          name: state.name.trim(),
          description: state.description?.trim(),
          servings: state.servings,
          servingName: state.servingName?.trim(),
          items: state.items,
        );
      } else {
        recipe = await repo.create(
          name: state.name.trim(),
          description: state.description?.trim(),
          servings: state.servings,
          servingName: state.servingName?.trim(),
          items: state.items,
        );
      }

      // Guardar como food
      final food = await repo.saveAsFood(recipe);

      ref.invalidate(recipesStreamProvider);
      state = state.copyWith(isSaving: false);
      return food;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error al guardar como alimento: $e',
      );
      return null;
    }
  }
}

final recipeEditorProvider =
    NotifierProvider<RecipeEditorNotifier, RecipeEditorState>(
  RecipeEditorNotifier.new,
);

/// Provider para eliminar una receta
final deleteRecipeProvider =
    FutureProvider.family<void, String>((ref, id) async {
  final repo = ref.read(recipeRepositoryProvider);
  await repo.delete(id);
  ref.invalidate(recipesStreamProvider);
});
