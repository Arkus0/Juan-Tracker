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
