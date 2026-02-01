import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/diary_entry_model.dart';
import 'package:juan_tracker/diet/providers/quick_actions_provider.dart';

void main() {
  group('QuickRecentFood', () {
    test('debe crear instancia correctamente', () {
      final food = QuickRecentFood(
        id: 'food-1',
        name: 'Arroz blanco',
        brand: 'Genérico',
        kcal: 350,
        lastUsed: DateTime(2026, 2, 1),
        useCount: 5,
        lastAmount: 150.0,
        lastUnit: ServingUnit.grams,
      );

      expect(food.id, 'food-1');
      expect(food.name, 'Arroz blanco');
      expect(food.brand, 'Genérico');
      expect(food.kcal, 350);
      expect(food.lastUsed, DateTime(2026, 2, 1));
      expect(food.useCount, 5);
      expect(food.lastAmount, 150.0);
      expect(food.lastUnit, ServingUnit.grams);
    });

    test('brand puede ser null', () {
      final food = QuickRecentFood(
        id: 'food-2',
        name: 'Manzana',
        brand: null,
        kcal: 52,
        lastUsed: DateTime(2026, 2, 1),
        useCount: 3,
        lastAmount: 1.0,
        lastUnit: ServingUnit.portion,
      );

      expect(food.brand, isNull);
    });

    test('displayName incluye marca si existe', () {
      final foodWithBrand = QuickRecentFood(
        id: 'food-1',
        name: 'Yogur',
        brand: 'Danone',
        kcal: 90,
        lastUsed: DateTime(2026, 2, 1),
        useCount: 2,
        lastAmount: 1.0,
        lastUnit: ServingUnit.portion,
      );

      final foodWithoutBrand = QuickRecentFood(
        id: 'food-2',
        name: 'Manzana',
        brand: null,
        kcal: 52,
        lastUsed: DateTime(2026, 2, 1),
        useCount: 1,
        lastAmount: 1.0,
        lastUnit: ServingUnit.portion,
      );

      expect(foodWithBrand.displayName, 'Yogur (Danone)');
      expect(foodWithoutBrand.displayName, 'Manzana');
    });
  });

  group('YesterdayMeals', () {
    test('isEmpty devuelve true cuando no hay entradas', () {
      const meals = YesterdayMeals(
        breakfast: [],
        lunch: [],
        dinner: [],
        snack: [],
        totalKcal: 0,
        entryCount: 0,
      );

      expect(meals.isEmpty, isTrue);
    });

    test('isEmpty devuelve false cuando hay entradas', () {
      const meals = YesterdayMeals(
        breakfast: [],
        lunch: [],
        dinner: [],
        snack: [],
        totalKcal: 500,
        entryCount: 1,
      );

      expect(meals.isEmpty, isFalse);
    });

    test('hasBreakfast/hasLunch/etc responden correctamente', () {
      const meals = YesterdayMeals(
        breakfast: [],
        lunch: [],
        dinner: [],
        snack: [],
        totalKcal: 0,
        entryCount: 0,
      );

      expect(meals.hasBreakfast, isFalse);
      expect(meals.hasLunch, isFalse);
      expect(meals.hasDinner, isFalse);
      expect(meals.hasSnack, isFalse);
    });
  });
}
