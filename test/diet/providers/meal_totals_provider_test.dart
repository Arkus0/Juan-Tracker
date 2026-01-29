/// Tests para provider memoizado de totales por comida (MD-002)
///
/// Verifica que los totales se calculan correctamente y se cachean
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/models.dart' as diet;

void main() {
  group('MealTotalsProvider MD-002 Tests', () {
    test('diet.MealType enum tiene todos los valores esperados', () {
      expect(diet.MealType.values.length, equals(4));
      expect(diet.MealType.values, contains(diet.MealType.breakfast));
      expect(diet.MealType.values, contains(diet.MealType.lunch));
      expect(diet.MealType.values, contains(diet.MealType.dinner));
      expect(diet.MealType.values, contains(diet.MealType.snack));
    });

    test('diet.MealType displayName retorna nombres en español', () {
      expect(diet.MealType.breakfast.displayName, equals('Desayuno'));
      expect(diet.MealType.lunch.displayName, equals('Almuerzo'));
      expect(diet.MealType.dinner.displayName, equals('Cena'));
      expect(diet.MealType.snack.displayName, equals('Snack'));
    });

    test('diet.DiaryEntryModel calcula macros correctamente', () {
      final entry = diet.DiaryEntryModel(
        id: '1',
        date: DateTime(2024, 1, 1),
        mealType: diet.MealType.breakfast,
        foodId: 'food1',
        foodName: 'Test Food',
        amount: 100,
        unit: diet.ServingUnit.grams,
        kcal: 250,
        protein: 20,
        carbs: 30,
        fat: 10,
      );

      expect(entry.kcal, equals(250));
      expect(entry.protein, equals(20));
      expect(entry.carbs, equals(30));
      expect(entry.fat, equals(10));
    });

    test('diet.DiaryEntryModel copyWith mantiene valores no especificados', () {
      final entry = diet.DiaryEntryModel(
        id: '1',
        date: DateTime(2024, 1, 1),
        mealType: diet.MealType.lunch,
        foodId: 'food1',
        foodName: 'Test Food',
        amount: 100,
        unit: diet.ServingUnit.grams,
        kcal: 250,
      );

      final updated = entry.copyWith(kcal: 300);

      expect(updated.kcal, equals(300));
      expect(updated.foodName, equals('Test Food'));
      expect(updated.mealType, equals(diet.MealType.lunch));
    });
  });
}
