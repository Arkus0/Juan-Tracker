import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/training/database/database.dart' show AppDatabase;
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/repositories/repositories.dart';
import 'package:juan_tracker/diet/repositories/drift_diet_repositories.dart';

// Database provider
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// Repository providers
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

// UI State Providers
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

final foodSearchQueryProvider = NotifierProvider<FoodSearchQueryNotifier, String>(
  FoodSearchQueryNotifier.new,
);

class FoodSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  set query(String q) => state = q;
}

final selectedFoodProvider = NotifierProvider<SelectedFoodNotifier, FoodModel?>(
  SelectedFoodNotifier.new,
);

class SelectedFoodNotifier extends Notifier<FoodModel?> {
  @override
  FoodModel? build() => null;

  set selected(FoodModel? f) => state = f;
}

final editingEntryProvider = NotifierProvider<EditingEntryNotifier, DiaryEntryModel?>(
  EditingEntryNotifier.new,
);

class EditingEntryNotifier extends Notifier<DiaryEntryModel?> {
  @override
  DiaryEntryModel? build() => null;

  set editing(DiaryEntryModel? e) => state = e;
}

final selectedMealTypeProvider = NotifierProvider<SelectedMealTypeNotifier, MealType>(
  SelectedMealTypeNotifier.new,
);

class SelectedMealTypeNotifier extends Notifier<MealType> {
  @override
  MealType build() => MealType.snack;

  set meal(MealType m) => state = m;
}

// UI State Notifiers
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = DateTime(date.year, date.month, date.day);
  void goToToday() => state = DateTime.now();
  void previousDay() => state = state.subtract(const Duration(days: 1));
  void nextDay() => state = state.add(const Duration(days: 1));
}

// Stream Providers
final dayEntriesStreamProvider = StreamProvider.autoDispose<List<DiaryEntryModel>>((ref) {
  return ref.watch(diaryRepositoryProvider).watchByDate(ref.watch(selectedDateProvider));
});

final dailyTotalsProvider = StreamProvider.autoDispose<DailyTotals>((ref) {
  return ref.watch(diaryRepositoryProvider).watchDailyTotals(ref.watch(selectedDateProvider));
});

final foodSearchResultsProvider = FutureProvider.autoDispose<List<FoodModel>>((ref) async {
  final query = ref.watch(foodSearchQueryProvider);
  if (query.trim().isEmpty) return ref.watch(foodRepositoryProvider).getAll();
  return ref.watch(foodRepositoryProvider).search(query);
});

// Weight Providers
final latestWeightProvider = FutureProvider<WeighInModel?>((ref) {
  return ref.watch(weighInRepositoryProvider).getLatest();
});

final weightStreamProvider = StreamProvider<List<WeighInModel>>((ref) {
  final from = DateTime.now().subtract(const Duration(days: 90));
  return ref.watch(weighInRepositoryProvider).watchByDateRange(from, DateTime.now());
});
