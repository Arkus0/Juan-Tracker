import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/database/database.dart' hide MealType, ServingUnit;
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/repositories/drift_diet_repositories.dart';

void main() {
  group('DriftDiaryRepository', () {
    late AppDatabase db;
    late DriftDiaryRepository repo;
    late DriftFoodRepository foodRepo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftDiaryRepository(db);
      foodRepo = DriftFoodRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insert y getByDate funcionan correctamente', () async {
      final date = DateTime(2026, 1, 15);
      final entry = DiaryEntryModel.quickAdd(
        id: 'entry-1',
        date: date,
        mealType: MealType.lunch,
        name: 'Hamburguesa',
        kcal: 500,
        protein: 25,
        carbs: 40,
        fat: 20,
      );

      await repo.insert(entry);

      final retrieved = await repo.getByDate(date);
      expect(retrieved.length, 1);
      expect(retrieved.first.foodName, 'Hamburguesa');
      expect(retrieved.first.kcal, 500);
    });

    test('getByDate filtra correctamente por fecha', () async {
      final date1 = DateTime(2026, 1, 15);
      final date2 = DateTime(2026, 1, 16);

      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e1',
        date: date1,
        mealType: MealType.breakfast,
        name: 'Tostadas',
        kcal: 200,
      ));
      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e2',
        date: date2,
        mealType: MealType.breakfast,
        name: 'Cereal',
        kcal: 150,
      ));

      final day1Entries = await repo.getByDate(date1);
      expect(day1Entries.length, 1);
      expect(day1Entries.first.foodName, 'Tostadas');

      final day2Entries = await repo.getByDate(date2);
      expect(day2Entries.length, 1);
      expect(day2Entries.first.foodName, 'Cereal');
    });

    test('update modifica una entrada existente', () async {
      final entry = DiaryEntryModel.quickAdd(
        id: 'e1',
        date: DateTime(2026, 1, 15),
        mealType: MealType.snack,
        name: 'Manzana',
        kcal: 52,
      );
      await repo.insert(entry);

      final updated = entry.copyWith(kcal: 60, amount: 120);
      await repo.update(updated);

      final retrieved = await repo.getById('e1');
      expect(retrieved!.kcal, 60);
      expect(retrieved.amount, 120);
    });

    test('delete elimina una entrada', () async {
      final entry = DiaryEntryModel.quickAdd(
        id: 'e1',
        date: DateTime(2026, 1, 15),
        mealType: MealType.dinner,
        name: 'Pasta',
        kcal: 400,
      );
      await repo.insert(entry);

      await repo.delete('e1');

      final retrieved = await repo.getById('e1');
      expect(retrieved, isNull);
    });

    test('getDailyTotals calcula correctamente los totales', () async {
      final date = DateTime(2026, 1, 15);

      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e1',
        date: date,
        mealType: MealType.breakfast,
        name: 'Avena',
        kcal: 300,
        protein: 10,
        carbs: 50,
        fat: 5,
      ));
      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e2',
        date: date,
        mealType: MealType.lunch,
        name: 'Pollo',
        kcal: 400,
        protein: 40,
        carbs: 0,
        fat: 10,
      ));
      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e3',
        date: date,
        mealType: MealType.snack,
        name: 'Fruta',
        kcal: 100,
        protein: 1,
        carbs: 25,
        fat: 0,
      ));

      final totals = await repo.getDailyTotals(date);

      expect(totals.kcal, 800); // 300 + 400 + 100
      expect(totals.protein, closeTo(51, 0.01)); // 10 + 40 + 1
      expect(totals.carbs, closeTo(75, 0.01)); // 50 + 0 + 25
      expect(totals.fat, closeTo(15, 0.01)); // 5 + 10 + 0
    });

    test('getDailyTotals agrupa por tipo de comida', () async {
      final date = DateTime(2026, 1, 15);

      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e1',
        date: date,
        mealType: MealType.breakfast,
        name: 'Tostadas',
        kcal: 200,
      ));
      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e2',
        date: date,
        mealType: MealType.breakfast,
        name: 'Café',
        kcal: 50,
      ));
      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e3',
        date: date,
        mealType: MealType.lunch,
        name: 'Ensalada',
        kcal: 300,
      ));

      final totals = await repo.getDailyTotals(date);

      expect(totals.byMeal[MealType.breakfast]!.kcal, 250);
      expect(totals.byMeal[MealType.breakfast]!.entryCount, 2);
      expect(totals.byMeal[MealType.lunch]!.kcal, 300);
      expect(totals.byMeal[MealType.lunch]!.entryCount, 1);
      expect(totals.byMeal[MealType.dinner]!.kcal, 0);
    });

    test('insert desde FoodModel calcula macros correctamente', () async {
      final food = FoodModel(
        id: 'chicken-id',
        name: 'Pechuga de Pollo',
        kcalPer100g: 165,
        proteinPer100g: 31,
        carbsPer100g: 0,
        fatPer100g: 3.6,
        portionGrams: 150,
        portionName: 'pieza',
      );
      await foodRepo.insert(food);

      final entry = DiaryEntryModel.fromFood(
        id: 'entry-1',
        date: DateTime(2026, 1, 15),
        mealType: MealType.lunch,
        food: food,
        amount: 1,
        unit: ServingUnit.portion,
      );
      await repo.insert(entry);

      final retrieved = await repo.getById('entry-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.kcal, 248); // (150/100) * 165
      expect(retrieved.protein, closeTo(46.5, 0.01));
      expect(retrieved.amount, 1);
      expect(retrieved.unit, ServingUnit.portion);
    });

    test('watchByDate emite actualizaciones', () async {
      final date = DateTime(2026, 1, 15);
      final stream = repo.watchByDate(date);

      await expectLater(stream, emits(isEmpty));

      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e1',
        date: date,
        mealType: MealType.breakfast,
        name: 'Test',
        kcal: 100,
      ));

      await expectLater(
        stream,
        emits(predicate<List<DiaryEntryModel>>((list) =>
            list.length == 1 && list.first.foodName == 'Test')),
      );
    });

    test('getByDateRange devuelve entradas en rango', () async {
      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e1',
        date: DateTime(2026, 1, 10),
        mealType: MealType.breakfast,
        name: 'Día 10',
        kcal: 100,
      ));
      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e2',
        date: DateTime(2026, 1, 15),
        mealType: MealType.breakfast,
        name: 'Día 15',
        kcal: 200,
      ));
      await repo.insert(DiaryEntryModel.quickAdd(
        id: 'e3',
        date: DateTime(2026, 1, 20),
        mealType: MealType.breakfast,
        name: 'Día 20',
        kcal: 300,
      ));

      final range = await repo.getByDateRange(
        DateTime(2026, 1, 12),
        DateTime(2026, 1, 18),
      );

      expect(range.length, 1);
      expect(range.first.foodName, 'Día 15');
    });
  });
}
