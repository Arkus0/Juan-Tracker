import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/core/providers/database_provider.dart';
import 'package:juan_tracker/core/repositories/diary_repository.dart';
import 'package:juan_tracker/core/repositories/weight_repository.dart';
import 'package:juan_tracker/core/models/diary_entry.dart' as core_models;
import 'package:juan_tracker/core/tdee/tdee_engine.dart';
import 'package:juan_tracker/diet/models/models.dart' as diet_models;
import 'package:juan_tracker/diet/repositories/diary_repository.dart' show IDiaryRepository;
import 'package:juan_tracker/diet/repositories/weighin_repository.dart' show IWeighInRepository;

void main() {
  test('tdee provider returns intake when no weight data', () async {
    final coreDiary = InMemoryDiaryRepository();
    final diary = _DiaryAdapter(coreDiary);
    final coreWeight = InMemoryWeightRepository();
    final weight = _WeightAdapter(coreWeight);
    final day = DateTime.now();

    await coreDiary.add(
      core_models.DiaryEntry(
        id: 'd1',
        date: day,
        mealType: core_models.MealType.lunch,
        grams: 100,
        kcal: 500,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(diary),
        weighInRepositoryProvider.overrideWithValue(weight),
      ],
    );

    // Adapters usados en el test
    // Implementación mínima que delega a la versión in-memory de core
    


    final est = await container.read(tdeeEstimateProvider(day).future);
    expect(est, 500);
  });
}

// Adaptadores para conectar los repos core con las interfaces diet
class _DiaryAdapter implements IDiaryRepository {
  final DiaryRepository _inner;
  _DiaryAdapter(this._inner);

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<List<diet_models.DiaryEntryModel>> getByDate(DateTime date) async {
    final list = await _inner.getDay(date);
    // map core DiaryEntry -> diet DiaryEntryModel (quickAdd)
    return list
        .map((e) => diet_models.DiaryEntryModel.quickAdd(
              id: e.id,
              date: e.date,
              mealType: _convertMealType(e.mealType),
              name: e.customName ?? e.id,
              kcal: e.kcal,
              protein: e.protein,
              carbs: e.carbs,
              fat: e.fat,
            ))
        .toList();
  }

  @override
  Future<void> insert(diet_models.DiaryEntryModel entry) async {
    // not needed for test
  }

  @override
  Future<void> update(diet_models.DiaryEntryModel entry) async {
    // not needed for test
  }

  @override
  Future<List<diet_models.DiaryEntryModel>> getByDateRange(DateTime from, DateTime to) async {
    // naive implementation
    final days = <diet_models.DiaryEntryModel>[];
    return days;
  }

  @override
  Future<diet_models.DiaryEntryModel?> getById(String id) async {
    // minimal for test
    return null;
  }

  @override
  Future<List<diet_models.DiaryEntryModel>> getHistoryByMealType(diet_models.MealType mealType, {int limit = 50}) async {
    return [];
  }

  @override
  Future<List<diet_models.DiaryEntryModel>> getRecentUniqueEntries({int limit = 50}) async {
    // Minimal stub for tests: return no recent unique entries.
    return [];
  }

  @override
  Stream<diet_models.DailyTotals> watchDailyTotals(DateTime date) {
    return Stream.value(diet_models.DailyTotals.empty);
  }

  @override
  Stream<List<diet_models.DiaryEntryModel>> watchByDate(DateTime date) {
    return _inner.watchDay(date).map((list) => list
        .map((e) => diet_models.DiaryEntryModel.quickAdd(
              id: e.id,
              date: e.date,
              mealType: _convertMealType(e.mealType),
              name: e.customName ?? e.id,
              kcal: e.kcal,
              protein: e.protein,
              carbs: e.carbs,
              fat: e.fat,
            ))
        .toList());
  }

  @override
  Future<diet_models.DailyTotals> getDailyTotals(DateTime date) async {
    final entries = await getByDate(date);
    return diet_models.DailyTotals.fromEntries(entries);
  }

  diet_models.MealType _convertMealType(core_models.MealType mt) {
    switch (mt) {
      case core_models.MealType.breakfast:
        return diet_models.MealType.breakfast;
      case core_models.MealType.lunch:
        return diet_models.MealType.lunch;
      case core_models.MealType.dinner:
        return diet_models.MealType.dinner;
      case core_models.MealType.snack:
        return diet_models.MealType.snack;
    }
  }
}

class _WeightAdapter implements IWeighInRepository {
  final WeightRepository _inner;
  _WeightAdapter(this._inner);

  @override
  Future<void> insert(diet_models.WeighInModel e) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<diet_models.WeighInModel>> getAll({int? limit}) async => [];

  @override
  Future<diet_models.WeighInModel?> getLatest() async {
    final latest = await _inner.latest();
    if (latest == null) return null;
    return diet_models.WeighInModel(id: latest.id, weightKg: latest.weightKg, dateTime: latest.date);
  }

  @override
  Future<List<diet_models.WeighInModel>> getByDateRange(DateTime from, DateTime to) async => [];

  @override
  Future<void> update(diet_models.WeighInModel e) async {}

  @override
  Stream<List<diet_models.WeighInModel>> watchAll() => Stream.value([]);

  @override
  Stream<List<diet_models.WeighInModel>> watchByDateRange(DateTime from, DateTime to) => Stream.value([]);

  @override
  Future<diet_models.WeighInModel?> getById(String id) async => null;

  @override
  Future<diet_models.WeightTrend?> calculateTrend({int days = 30}) async => null;
}

