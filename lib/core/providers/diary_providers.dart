import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diet/models/models.dart' as diet;
import '../models/diary_entry.dart' as old;
import 'database_provider.dart';

// Exportar solo el MealType antiguo para compatibilidad
export '../models/diary_entry.dart' show MealType;

// Provider de fecha seleccionada (delegado al nuevo provider)
final selectedDayProvider = Provider<DateTime>((ref) {
  return ref.watch(selectedDateProvider);
});

// Provider de entradas del dia (adaptador a modelos antiguos)
final dayEntriesProvider = StreamProvider.autoDispose<List<old.DiaryEntry>>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  final day = ref.watch(selectedDateProvider);
  
  return repo.watchByDate(day).map((entries) => 
    entries.map(_mapToOldEntry).toList()
  );
});

// Provider de totales del dia (adaptador a modelo antiguo)
final dayTotalsProvider = FutureProvider.autoDispose<_DailyTotals>((ref) async {
  final repo = ref.watch(diaryRepositoryProvider);
  final day = ref.watch(selectedDateProvider);
  final totals = await repo.getDailyTotals(day);
  
  return _DailyTotals(
    kcal: totals.kcal,
    protein: totals.protein,
    carbs: totals.carbs,
    fat: totals.fat,
  );
});

// Funcion de mapeo de modelo nuevo a antiguo
old.DiaryEntry _mapToOldEntry(diet.DiaryEntryModel entry) {
  return old.DiaryEntry(
    id: entry.id,
    date: entry.date,
    mealType: _convertMealType(entry.mealType),
    foodId: entry.foodId,
    customName: entry.isQuickAdd ? entry.foodName : null,
    grams: entry.amount,
    kcal: entry.kcal,
    protein: entry.protein,
    carbs: entry.carbs,
    fat: entry.fat,
    createdAt: entry.createdAt,
  );
}

// Conversor de MealType
old.MealType _convertMealType(diet.MealType type) {
  switch (type) {
    case diet.MealType.breakfast:
      return old.MealType.breakfast;
    case diet.MealType.lunch:
      return old.MealType.lunch;
    case diet.MealType.dinner:
      return old.MealType.dinner;
    case diet.MealType.snack:
      return old.MealType.snack;
  }
}

// Modelo local de totales
class _DailyTotals {
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;

  _DailyTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
