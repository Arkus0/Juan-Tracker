import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/models.dart';

void main() {
  group('FoodModel', () {
    test('macrosForGrams calcula correctamente', () {
      final food = FoodModel(
        id: 'f1',
        name: 'Avena',
        kcalPer100g: 389,
        proteinPer100g: 16.9,
        carbsPer100g: 66,
        fatPer100g: 6.9,
      );

      final macros = food.macrosForGrams(50); // 50g

      expect(macros.kcal, 195); // (50/100) * 389 = 194.5 → 195
      expect(macros.protein, closeTo(8.45, 0.01));
      expect(macros.carbs, closeTo(33.0, 0.01));
      expect(macros.fat, closeTo(3.45, 0.01));
    });

    test('copyWith crea copia con modificaciones', () {
      final food = FoodModel(
        id: 'f1',
        name: 'Pan',
        kcalPer100g: 250,
      );

      final copy = food.copyWith(name: 'Pan Integral', kcalPer100g: 247);

      expect(copy.id, food.id);
      expect(copy.name, 'Pan Integral');
      expect(copy.kcalPer100g, 247);
    });

    test('toDebugMap y toString funcionan', () {
      final food = FoodModel(
        id: 'f1',
        name: 'Test Food',
        kcalPer100g: 100,
        proteinPer100g: 10,
      );

      final debug = food.toDebugMap();
      expect(debug['id'], 'f1');
      expect(debug['name'], 'Test Food');

      expect(food.toString(), contains('Test Food'));
    });
  });

  group('Macros', () {
    test('operator + suma correctamente', () {
      const m1 = Macros(kcal: 100, protein: 10, carbs: 20, fat: 5);
      const m2 = Macros(kcal: 200, protein: 20, carbs: 30, fat: 10);

      final sum = m1 + m2;

      expect(sum.kcal, 300);
      expect(sum.protein, 30);
      expect(sum.carbs, 50);
      expect(sum.fat, 15);
    });

    test('zero es identidad de la suma', () {
      const m = Macros(kcal: 100, protein: 10, carbs: 20, fat: 5);
      final sum = m + Macros.zero;

      expect(sum.kcal, m.kcal);
      expect(sum.protein, m.protein);
    });
  });

  group('DiaryEntryModel', () {
    test('fromFood crea entrada desde alimento', () {
      final food = FoodModel(
        id: 'f1',
        name: 'Pollo',
        kcalPer100g: 165,
        proteinPer100g: 31,
        portionGrams: 150,
        portionName: 'pechuga',
      );

      final entry = DiaryEntryModel.fromFood(
        id: 'e1',
        date: DateTime(2026, 1, 15),
        mealType: MealType.lunch,
        food: food,
        amount: 1,
        unit: ServingUnit.portion,
      );

      expect(entry.foodId, 'f1');
      expect(entry.foodName, 'Pollo');
      expect(entry.kcal, 248); // 165 * 1.5
      expect(entry.unit, ServingUnit.portion);
      expect(entry.isQuickAdd, false);
    });

    test('fromFood con gramos calcula correctamente', () {
      final food = FoodModel(
        id: 'f1',
        name: 'Arroz',
        kcalPer100g: 130,
      );

      final entry = DiaryEntryModel.fromFood(
        id: 'e1',
        date: DateTime(2026, 1, 15),
        mealType: MealType.lunch,
        food: food,
        amount: 200,
        unit: ServingUnit.grams,
      );

      expect(entry.kcal, 260); // (200/100) * 130
    });

    test('quickAdd crea entrada libre', () {
      final entry = DiaryEntryModel.quickAdd(
        id: 'e1',
        date: DateTime(2026, 1, 15),
        mealType: MealType.snack,
        name: 'Galletas caseras',
        kcal: 150,
        protein: 3,
        carbs: 20,
      );

      expect(entry.foodId, isNull);
      expect(entry.isQuickAdd, true);
      expect(entry.foodName, 'Galletas caseras');
      expect(entry.fat, isNull);
    });

    test('copyWith crea copia con modificaciones', () {
      final entry = DiaryEntryModel.quickAdd(
        id: 'e1',
        date: DateTime(2026, 1, 15),
        mealType: MealType.breakfast,
        name: 'Tostadas',
        kcal: 200,
      );

      final copy = entry.copyWith(kcal: 250, amount: 2);

      expect(copy.id, entry.id);
      expect(copy.kcal, 250);
      expect(copy.amount, 2);
    });
  });

  group('DailyTotals', () {
    test('fromEntries calcula totales correctamente', () {
      final entries = [
        DiaryEntryModel.quickAdd(
          id: 'e1',
          date: DateTime(2026, 1, 15),
          mealType: MealType.breakfast,
          name: 'A',
          kcal: 300,
          protein: 15,
          carbs: 40,
          fat: 8,
        ),
        DiaryEntryModel.quickAdd(
          id: 'e2',
          date: DateTime(2026, 1, 15),
          mealType: MealType.lunch,
          name: 'B',
          kcal: 500,
          protein: 35,
          carbs: 50,
          fat: 15,
        ),
        DiaryEntryModel.quickAdd(
          id: 'e3',
          date: DateTime(2026, 1, 15),
          mealType: MealType.breakfast,
          name: 'C',
          kcal: 200,
          protein: 5,
        ),
      ];

      final totals = DailyTotals.fromEntries(entries);

      expect(totals.kcal, 1000);
      expect(totals.protein, 55);
      expect(totals.carbs, 90);
      expect(totals.fat, 23);

      // Por comida
      expect(totals.byMeal[MealType.breakfast]!.kcal, 500);
      expect(totals.byMeal[MealType.breakfast]!.entryCount, 2);
      expect(totals.byMeal[MealType.lunch]!.kcal, 500);
      expect(totals.byMeal[MealType.lunch]!.entryCount, 1);
      expect(totals.byMeal[MealType.dinner]!.kcal, 0);
    });

    test('empty tiene valores cero', () {
      expect(DailyTotals.empty.kcal, 0);
      expect(DailyTotals.empty.protein, 0);
      expect(DailyTotals.empty.byMeal, isEmpty);
    });

    test('fromEntries con lista vacía devuelve empty', () {
      final totals = DailyTotals.fromEntries([]);
      expect(totals, DailyTotals.empty);
    });
  });

  group('MealTypeExtension', () {
    test('displayName devuelve nombres en español', () {
      expect(MealType.breakfast.displayName, 'Desayuno');
      expect(MealType.lunch.displayName, 'Almuerzo');
      expect(MealType.dinner.displayName, 'Cena');
      expect(MealType.snack.displayName, 'Snack');
    });
  });

  group('WeighInModel', () {
    test('weightLbs convierte correctamente', () {
      final weighIn = WeighInModel(
        id: 'w1',
        dateTime: DateTime.now(),
        weightKg: 70,
      );

      expect(weighIn.weightLbs, closeTo(154.32, 0.01));
    });

    test('formatted devuelve string correcto', () {
      final weighIn = WeighInModel(
        id: 'w1',
        dateTime: DateTime.now(),
        weightKg: 75.5,
      );

      expect(weighIn.formatted(), '75.5 kg');
      expect(weighIn.formatted(useLbs: true), '166.4 lb');
    });

    test('copyWith crea copia con modificaciones', () {
      final weighIn = WeighInModel(
        id: 'w1',
        dateTime: DateTime(2026, 1, 15, 8, 0),
        weightKg: 75,
        note: 'Inicial',
      );

      final copy = weighIn.copyWith(weightKg: 74.5, note: 'Corregido');

      expect(copy.id, weighIn.id);
      expect(copy.weightKg, 74.5);
      expect(copy.note, 'Corregido');
    });
  });

  group('WeightTrend', () {
    test('fromEntries calcula trend correctamente', () {
      final now = DateTime.now();
      final entries = [
        WeighInModel(
          id: 'w1',
          dateTime: now,
          weightKg: 75,
        ),
        WeighInModel(
          id: 'w2',
          dateTime: now.subtract(const Duration(days: 1)),
          weightKg: 75.2,
        ),
        WeighInModel(
          id: 'w3',
          dateTime: now.subtract(const Duration(days: 5)),
          weightKg: 76,
        ),
        WeighInModel(
          id: 'w4',
          dateTime: now.subtract(const Duration(days: 10)),
          weightKg: 77,
        ),
      ];

      final trend = WeightTrend.fromEntries(entries);

      expect(trend.currentWeight, 75);
      expect(trend.previousWeight, 75.2);
    });

    test('fromEntries lanza error con lista vacía', () {
      expect(() => WeightTrend.fromEntries([]), throwsArgumentError);
    });
  });

  group('TargetsModel', () {
    test('kcalFromMacros calcula correctamente', () {
      final target = TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2500,
        proteinTarget: 200, // 800 kcal
        carbsTarget: 250,   // 1000 kcal
        fatTarget: 80,      // 720 kcal
      );

      expect(target.kcalFromMacros, 2520); // 800 + 1000 + 720
    });

    test('getActiveForDate devuelve objetivo correcto', () {
      final targets = [
        TargetsModel(
          id: 't1',
          validFrom: DateTime(2026, 1, 1),
          kcalTarget: 2000,
        ),
        TargetsModel(
          id: 't2',
          validFrom: DateTime(2026, 2, 1),
          kcalTarget: 2200,
        ),
      ];

      final activeJan = TargetsModel.getActiveForDate(
        targets,
        DateTime(2026, 1, 15),
      );
      expect(activeJan!.kcalTarget, 2000);

      final activeFeb = TargetsModel.getActiveForDate(
        targets,
        DateTime(2026, 2, 15),
      );
      expect(activeFeb!.kcalTarget, 2200);
    });

    test('copyWith crea copia con modificaciones', () {
      final target = TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
        proteinTarget: 150,
      );

      final copy = target.copyWith(kcalTarget: 2100);

      expect(copy.id, target.id);
      expect(copy.kcalTarget, 2100);
      expect(copy.proteinTarget, 150);
    });
  });

  group('TargetsProgress', () {
    test('porcentajes calculan correctamente', () {
      final target = TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
        proteinTarget: 150,
        carbsTarget: 200,
        fatTarget: 70,
      );

      final progress = TargetsProgress(
        targets: target,
        kcalConsumed: 1500,
        proteinConsumed: 120,
        carbsConsumed: 180,
        fatConsumed: 60,
      );

      expect(progress.kcalPercent, 0.75); // 1500/2000
      expect(progress.proteinPercent, 0.8); // 120/150
      expect(progress.kcalRemaining, 500); // 2000-1500
      expect(progress.proteinRemaining, 30); // 150-120
    });

    test('porcentajes son null sin targets', () {
      const progress = TargetsProgress(
        targets: null,
        kcalConsumed: 1500,
        proteinConsumed: 120,
        carbsConsumed: 180,
        fatConsumed: 60,
      );

      expect(progress.kcalPercent, isNull);
      expect(progress.proteinPercent, isNull);
      expect(progress.kcalRemaining, isNull);
    });
  });

  group('RecipeModel', () {
    test('fromItems calcula totales correctamente', () {
      final items = [
        RecipeItemModel(
          id: 'i1',
          recipeId: 'r1',
          foodId: 'f1',
          amount: 100,
          unit: ServingUnit.grams,
          foodNameSnapshot: 'Arroz',
          kcalPer100gSnapshot: 130,
          proteinPer100gSnapshot: 2.7,
          carbsPer100gSnapshot: 28,
        ),
        RecipeItemModel(
          id: 'i2',
          recipeId: 'r1',
          foodId: 'f2',
          amount: 150,
          unit: ServingUnit.grams,
          foodNameSnapshot: 'Pollo',
          kcalPer100gSnapshot: 165,
          proteinPer100gSnapshot: 31,
        ),
      ];

      final recipe = RecipeModel.fromItems(
        id: 'r1',
        name: 'Arroz con Pollo',
        servings: 2,
        items: items,
      );

      expect(recipe.totalKcal, 378); // 130 + 248
      expect(recipe.totalProtein, closeTo(49.2, 0.1)); // 2.7 + 46.5
      expect(recipe.totalGrams, 250); // 100 + 150
      expect(recipe.kcalPerServing, 189); // 378 / 2
    });

    test('toFoodModel convierte correctamente', () {
      final items = [
        RecipeItemModel(
          id: 'i1',
          recipeId: 'r1',
          foodId: 'f1',
          amount: 100,
          unit: ServingUnit.grams,
          foodNameSnapshot: 'Ingrediente',
          kcalPer100gSnapshot: 100,
        ),
      ];

      final recipe = RecipeModel.fromItems(
        id: 'r1',
        name: 'Receta Test',
        servings: 2,
        servingName: 'taza',
        items: items,
      );

      final food = recipe.toFoodModel();

      expect(food.name, 'Receta Test');
      expect(food.portionName, 'taza');
      expect(food.portionGrams, 50); // 100g total / 2 porciones
      expect(food.kcalPer100g, 100);
    });
  });

  group('RecipeItemModel', () {
    test('fromFood crea item desde alimento', () {
      final food = FoodModel(
        id: 'f1',
        name: 'Leche',
        kcalPer100g: 42,
        proteinPer100g: 3.4,
      );

      final item = RecipeItemModel.fromFood(
        id: 'i1',
        recipeId: 'r1',
        food: food,
        amount: 250,
        unit: ServingUnit.grams,
        sortOrder: 1,
      );

      expect(item.foodId, 'f1');
      expect(item.foodNameSnapshot, 'Leche');
      expect(item.kcalPer100gSnapshot, 42);
      expect(item.sortOrder, 1);
    });

    test('calculatedKcal calcula correctamente', () {
      final item = RecipeItemModel(
        id: 'i1',
        recipeId: 'r1',
        foodId: 'f1',
        amount: 150,
        unit: ServingUnit.grams,
        foodNameSnapshot: 'Arroz',
        kcalPer100gSnapshot: 130,
      );

      expect(item.calculatedKcal, 195); // (150/100) * 130
      expect(item.amountInGrams, 150);
    });

    test('amountInGrams convierte porciones', () {
      final item = RecipeItemModel(
        id: 'i1',
        recipeId: 'r1',
        foodId: 'f1',
        amount: 2,
        unit: ServingUnit.portion,
        foodNameSnapshot: 'Huevo',
        kcalPer100gSnapshot: 155,
      );

      // Asume 100g por porción si no hay info
      expect(item.amountInGrams, 200);
      expect(item.calculatedKcal, 310);
    });
  });
}
