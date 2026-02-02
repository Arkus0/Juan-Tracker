import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/database_provider.dart';
import '../../training/database/database.dart' as db;
import '../models/diary_entry_model.dart' as diary;
import '../models/meal_template.dart';
import '../repositories/meal_template_repository.dart';

// ============================================================================
// MEAL TEMPLATES PROVIDERS
// ============================================================================

/// Provider para obtener todas las plantillas de comidas
final mealTemplatesProvider = FutureProvider<List<MealTemplateModel>>((ref) {
  final repository = ref.watch(mealTemplateRepositoryProvider);
  return repository.getAll();
});

/// Provider para obtener las plantillas más usadas (para Quick Actions)
final topMealTemplatesProvider = FutureProvider<List<MealTemplateModel>>((ref) {
  final repository = ref.watch(mealTemplateRepositoryProvider);
  return repository.getTopUsed(limit: 4);
});

/// Provider para obtener plantillas por tipo de comida
final mealTemplatesByTypeProvider = FutureProvider.family<List<MealTemplateModel>, db.MealType>((ref, mealType) {
  final repository = ref.watch(mealTemplateRepositoryProvider);
  return repository.getByMealType(mealType);
});

/// Provider para guardar la comida actual como plantilla
/// 
/// Uso:
/// ```dart
/// ref.read(saveMealAsTemplateProvider.notifier).save(
///   name: 'Desayuno típico',
///   mealType: db.MealType.breakfast,
///   entries: entries,
/// );
/// ```
final saveMealAsTemplateProvider = AsyncNotifierProvider<SaveMealAsTemplateNotifier, void>(
  SaveMealAsTemplateNotifier.new,
);

class SaveMealAsTemplateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Guarda las entradas dadas como una nueva plantilla
  Future<MealTemplateModel?> save({
    required String name,
    required db.MealType mealType,
    required List<db.DiaryEntry> entries,
  }) async {
    if (entries.isEmpty) return null;
    if (name.trim().isEmpty) return null;

    state = const AsyncLoading();
    
    try {
      final repository = ref.read(mealTemplateRepositoryProvider);
      final template = await repository.createFromDiaryEntries(
        name: name.trim(),
        mealType: mealType,
        entries: entries,
      );

      // Invalidar providers para refrescar listas
      ref.invalidate(mealTemplatesProvider);
      ref.invalidate(topMealTemplatesProvider);

      state = const AsyncData(null);
      return template;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

/// Provider para usar (aplicar) una plantilla de comida
/// 
/// Crea entradas en el diario para la fecha y tipo de comida especificados.
/// 
/// Uso:
/// ```dart
/// await ref.read(useMealTemplateProvider.notifier).apply(
///   templateId: template.id,
///   date: selectedDate,
///   mealType: db.MealType.breakfast,
/// );
/// ```
final useMealTemplateProvider = AsyncNotifierProvider<UseMealTemplateNotifier, void>(
  UseMealTemplateNotifier.new,
);

class UseMealTemplateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Aplica una plantilla creando entradas en el diario
  Future<bool> apply({
    required String templateId,
    required DateTime date,
    required db.MealType mealType,
  }) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(mealTemplateRepositoryProvider);
      final diaryRepository = ref.read(diaryRepositoryProvider);
      
      final template = await repository.getById(templateId);
      if (template == null) {
        state = AsyncError('Plantilla no encontrada', StackTrace.current);
        return false;
      }

      // Crear una entrada por cada item de la plantilla
      for (final item in template.items) {
        final entry = diary.DiaryEntryModel(
          id: const Uuid().v4(),
          date: date,
          mealType: _convertMealType(mealType),
          foodId: item.foodId,
          foodName: item.foodName,
          amount: item.amount,
          unit: _convertServingUnit(item.unit),
          kcal: item.kcal,
          protein: item.protein,
          carbs: item.carbs,
          fat: item.fat,
        );

        await diaryRepository.insert(entry);
      }

      // Marcar la plantilla como usada
      await repository.markAsUsed(templateId);

      // Invalidar providers para refrescar
      ref.invalidate(mealTemplatesProvider);
      ref.invalidate(topMealTemplatesProvider);
      
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

/// Provider para eliminar una plantilla
final deleteMealTemplateProvider = AsyncNotifierProvider<DeleteMealTemplateNotifier, void>(
  DeleteMealTemplateNotifier.new,
);

class DeleteMealTemplateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> delete(String templateId) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(mealTemplateRepositoryProvider);
      await repository.delete(templateId);

      // Invalidar providers para refrescar
      ref.invalidate(mealTemplatesProvider);
      ref.invalidate(topMealTemplatesProvider);

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ============================================================================
// HELPERS
// ============================================================================

/// Convierte MealType de database.dart a MealType de diary_entry_model.dart
diary.MealType _convertMealType(db.MealType dbType) => switch (dbType) {
  db.MealType.breakfast => diary.MealType.breakfast,
  db.MealType.lunch => diary.MealType.lunch,
  db.MealType.dinner => diary.MealType.dinner,
  db.MealType.snack => diary.MealType.snack,
};

/// Convierte ServingUnit de database.dart a ServingUnit de diary_entry_model.dart
diary.ServingUnit _convertServingUnit(db.ServingUnit dbUnit) => switch (dbUnit) {
  db.ServingUnit.grams => diary.ServingUnit.grams,
  db.ServingUnit.portion => diary.ServingUnit.portion,
  db.ServingUnit.milliliter => diary.ServingUnit.milliliter,
};
