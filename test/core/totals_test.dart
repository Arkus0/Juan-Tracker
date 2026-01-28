import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/core/repositories/diary_repository.dart';
import 'package:juan_tracker/core/models/diary_entry.dart';

void main() {
  test('daily totals sum kcal', () async {
    final repo = InMemoryDiaryRepository();
    final day = DateTime.now();
    await repo.add(DiaryEntry(id: 'e1', date: day, mealType: MealType.breakfast, grams: 100, kcal: 100));
    await repo.add(DiaryEntry(id: 'e2', date: day, mealType: MealType.lunch, grams: 200, kcal: 300));

    final totals = await repo.totalsForDay(day);
    expect(totals.kcal, 400);
  });
}
