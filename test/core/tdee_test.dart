import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/core/providers/database_provider.dart';
import 'package:juan_tracker/core/repositories/diary_repository.dart';
import 'package:juan_tracker/core/repositories/weight_repository.dart';
import 'package:juan_tracker/core/models/diary_entry.dart';
import 'package:juan_tracker/core/tdee/tdee_engine.dart';

void main() {
  test('tdee provider returns intake when no weight data', () async {
    final diary = InMemoryDiaryRepository();
    final weight = InMemoryWeightRepository();
    final day = DateTime.now();

    await diary.add(DiaryEntry(id: 'd1', date: day, mealType: MealType.lunch, grams: 100, kcal: 500));

    final container = ProviderContainer(overrides: [
      diaryRepositoryProvider.overrideWithValue(diary),
      weightRepositoryProvider.overrideWithValue(weight),
    ]);

    final est = await container.read(tdeeEstimateProvider(day).future);
    expect(est, 500);
  });
}
