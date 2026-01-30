import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diet/models/models.dart' as diet;
import '../../diet/repositories/repositories.dart';
import '../../diet/repositories/drift_diet_repositories.dart';
import '../../training/database/database.dart';
import '../repositories/i_training_repository.dart';
import '../repositories/in_memory_training_repository.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/local_exercise_repository.dart';
import '../repositories/routine_repository.dart';
import '../repositories/in_memory_routine_repository.dart';

// ============================================================================
// DATABASE & REPOSITORIES
// ============================================================================

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final foodRepositoryProvider = Provider<IFoodRepository>((ref) {
  return DriftFoodRepository(ref.watch(appDatabaseProvider));
});

final diaryRepositoryProvider = Provider<IDiaryRepository>((ref) {
  return DriftDiaryRepository(ref.watch(appDatabaseProvider));
});

final weighInRepositoryProvider = Provider<IWeighInRepository>((ref) {
  return DriftWeighInRepository(ref.watch(appDatabaseProvider));
});

final targetsRepositoryProvider = Provider<ITargetsRepository>((ref) {
  return DriftTargetsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(diaryRepositoryProvider),
  );
});

// ============================================================================
// UI STATE - DATE
// ============================================================================

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = DateTime(date.year, date.month, date.day);
  void goToToday() => state = DateTime.now();
  void previousDay() => state = state.subtract(const Duration(days: 1));
  void nextDay() => state = state.add(const Duration(days: 1));
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

// ============================================================================
// UI STATE - STREAMS
// ============================================================================

final dayEntriesStreamProvider = StreamProvider.autoDispose<List<diet.DiaryEntryModel>>((ref) {
  return ref.watch(diaryRepositoryProvider).watchByDate(ref.watch(selectedDateProvider));
});

final dailyTotalsProvider = StreamProvider.autoDispose<diet.DailyTotals>((ref) {
  return ref.watch(diaryRepositoryProvider).watchDailyTotals(ref.watch(selectedDateProvider));
});

final foodSearchResultsProvider = FutureProvider.autoDispose<List<diet.FoodModel>>((ref) async {
  final query = ref.watch(foodSearchQueryProvider);
  if (query.trim().isEmpty) return ref.watch(foodRepositoryProvider).getAll();
  return ref.watch(foodRepositoryProvider).search(query);
});

final latestWeightProvider = FutureProvider<diet.WeighInModel?>((ref) {
  return ref.watch(weighInRepositoryProvider).getLatest();
});

final weightStreamProvider = StreamProvider<List<diet.WeighInModel>>((ref) {
  final from = DateTime.now().subtract(const Duration(days: 90));
  return ref.watch(weighInRepositoryProvider).watchByDateRange(from, DateTime.now());
});

// ============================================================================
// UI STATE - SIMPLE STATE (migrado a Notifier para compatibilidad con Riverpod 3)
// ============================================================================

final foodSearchQueryProvider = NotifierProvider<FoodSearchQueryNotifier, String>(
  FoodSearchQueryNotifier.new,
);

class FoodSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  set query(String q) => state = q;
}

final selectedFoodProvider = NotifierProvider<SelectedFoodNotifier, diet.FoodModel?>(
  SelectedFoodNotifier.new,
);

class SelectedFoodNotifier extends Notifier<diet.FoodModel?> {
  @override
  diet.FoodModel? build() => null;

  set selected(diet.FoodModel? f) => state = f;
}

final editingEntryProvider = NotifierProvider<EditingEntryNotifier, diet.DiaryEntryModel?>(
  EditingEntryNotifier.new,
);

class EditingEntryNotifier extends Notifier<diet.DiaryEntryModel?> {
  @override
  diet.DiaryEntryModel? build() => null;

  set editing(diet.DiaryEntryModel? e) => state = e;
}

final selectedMealTypeProvider = NotifierProvider<SelectedMealTypeNotifier, diet.MealType>(
  SelectedMealTypeNotifier.new,
);

class SelectedMealTypeNotifier extends Notifier<diet.MealType> {
  @override
  diet.MealType build() => diet.MealType.snack;

  set meal(diet.MealType m) => state = m;
}

// ============================================================================
// RECENT FOODS - Para Quick Add (UX optimization)
// ============================================================================

/// Provider de comidas recientes para quick-add
/// Retorna las últimas 5 comidas únicas registradas (por foodId)
final recentFoodsProvider = FutureProvider<List<diet.DiaryEntryModel>>((ref) async {
  final repo = ref.read(diaryRepositoryProvider);
  return repo.getRecentUniqueEntries(limit: 5);
});

// ============================================================================
// 🎯 HIGH-003: SMART FOOD SUGGESTIONS - Sugerencias por hora/historial
// ============================================================================

/// Determina el MealType sugerido basado en la hora actual
diet.MealType _getMealTypeForTime(DateTime time) {
  final hour = time.hour;
  if (hour >= 6 && hour < 11) return diet.MealType.breakfast;
  if (hour >= 11 && hour < 15) return diet.MealType.lunch;
  if (hour >= 15 && hour < 18) return diet.MealType.snack;
  if (hour >= 18 && hour < 22) return diet.MealType.dinner;
  return diet.MealType.snack; // Default para madrugada/noche
}

/// Modelo de sugerencia de comida con contexto
class SmartFoodSuggestion {
  final String foodName;
  final String? foodId;
  final String? brand;
  final int kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double amount;
  final diet.ServingUnit unit;
  final int timesEaten;
  final diet.MealType suggestedMealType;
  final String reason;

  const SmartFoodSuggestion({
    required this.foodName,
    this.foodId,
    this.brand,
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    required this.amount,
    required this.unit,
    required this.timesEaten,
    required this.suggestedMealType,
    required this.reason,
  });

  /// Crea una entrada de diario a partir de la sugerencia
  diet.DiaryEntryModel toEntry({
    required String id,
    required DateTime date,
    diet.MealType? mealType,
  }) {
    return diet.DiaryEntryModel(
      id: id,
      date: date,
      mealType: mealType ?? suggestedMealType,
      foodId: foodId,
      foodName: foodName,
      foodBrand: brand,
      amount: amount,
      unit: unit,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }
}

/// Provider que detecta el MealType actual basado en la hora
final currentMealTypeProvider = Provider<diet.MealType>((ref) {
  return _getMealTypeForTime(DateTime.now());
});

/// Provider de sugerencias inteligentes de comida basadas en:
/// 1. Hora del día (desayuno, almuerzo, cena, snack)
/// 2. Historial del usuario para esa comida
/// 3. Frecuencia de consumo
final smartFoodSuggestionsProvider = FutureProvider<List<SmartFoodSuggestion>>((ref) async {
  final repo = ref.read(diaryRepositoryProvider);
  final suggestedMeal = ref.watch(currentMealTypeProvider);

  // Obtener historial para este tipo de comida (últimas 50 entradas)
  final history = await repo.getHistoryByMealType(suggestedMeal, limit: 50);

  if (history.isEmpty) {
    // Sin historial: retornar lista vacía (el UI mostrará un mensaje educativo)
    return [];
  }

  // Contar frecuencia de cada alimento
  final frequencyMap = <String, _FoodFrequency>{};

  for (final entry in history) {
    final key = entry.foodId ?? entry.foodName;
    if (frequencyMap.containsKey(key)) {
      frequencyMap[key]!.count++;
    } else {
      frequencyMap[key] = _FoodFrequency(entry: entry, count: 1);
    }
  }

  // Ordenar por frecuencia y tomar los top 5
  final sorted = frequencyMap.values.toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  final topFoods = sorted.take(5).toList();

  // Convertir a SmartFoodSuggestion
  return topFoods.map((freq) {
    final entry = freq.entry;
    String reason;
    if (freq.count >= 5) {
      reason = 'Tu favorito (${freq.count}x)';
    } else if (freq.count >= 3) {
      reason = 'Comes seguido (${freq.count}x)';
    } else {
      reason = 'Reciente';
    }

    return SmartFoodSuggestion(
      foodName: entry.foodName,
      foodId: entry.foodId,
      brand: entry.foodBrand,
      kcal: entry.kcal,
      protein: entry.protein,
      carbs: entry.carbs,
      fat: entry.fat,
      amount: entry.amount,
      unit: entry.unit,
      timesEaten: freq.count,
      suggestedMealType: suggestedMeal,
      reason: reason,
    );
  }).toList();
});

/// Helper class para contar frecuencia
class _FoodFrequency {
  final diet.DiaryEntryModel entry;
  int count;

  _FoodFrequency({required this.entry, required this.count});
}

/// Provider de mensaje contextual para el tipo de comida actual
final mealContextMessageProvider = Provider<String>((ref) {
  final mealType = ref.watch(currentMealTypeProvider);
  final hour = DateTime.now().hour;

  switch (mealType) {
    case diet.MealType.breakfast:
      if (hour < 8) return '¡Buenos días! ¿Qué desayunas?';
      return '¿Ya desayunaste?';
    case diet.MealType.lunch:
      if (hour < 13) return 'Se acerca la hora de comer';
      return '¿Qué hay para el almuerzo?';
    case diet.MealType.snack:
      if (hour >= 15 && hour < 18) return '¿Hora de merendar?';
      return '¿Un snack?';
    case diet.MealType.dinner:
      if (hour < 20) return '¿Planificando la cena?';
      return '¿Qué cenaste?';
  }
});

// ============================================================================
// TRAINING REPOSITORIES (sin cambios)
// ============================================================================

final trainingRepositoryProvider = Provider<ITrainingRepository>(
  (ref) => InMemoryTrainingRepository(),
);
final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => LocalExerciseRepository(),
);
final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => InMemoryRoutineRepository(),
);
