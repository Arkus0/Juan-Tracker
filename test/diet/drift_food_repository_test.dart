import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/database/database.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/repositories/drift_diet_repositories.dart';

void main() {
  group('DriftFoodRepository', () {
    late AppDatabase db;
    late DriftFoodRepository repo;

    setUp(() {
      // Base de datos en memoria para tests
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftFoodRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insert y getById funcionan correctamente', () async {
      final food = FoodModel(
        id: 'food-1',
        name: 'Manzana',
        brand: 'Golden',
        kcalPer100g: 52,
        proteinPer100g: 0.3,
        carbsPer100g: 14,
        fatPer100g: 0.2,
      );

      await repo.insert(food);

      final retrieved = await repo.getById('food-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Manzana');
      expect(retrieved.kcalPer100g, 52);
      expect(retrieved.proteinPer100g, closeTo(0.3, 0.01));
    });

    test('getAll devuelve todos los alimentos', () async {
      await repo.insert(FoodModel(
        id: 'f1',
        name: 'Plátano',
        kcalPer100g: 89,
      ));
      await repo.insert(FoodModel(
        id: 'f2',
        name: 'Arroz',
        kcalPer100g: 130,
      ));

      final all = await repo.getAll();
      expect(all.length, 2);
      expect(all.map((f) => f.name).toSet(), {'Plátano', 'Arroz'});
    });

    test('update modifica un alimento existente', () async {
      final food = FoodModel(
        id: 'f1',
        name: 'Pan',
        kcalPer100g: 250,
      );
      await repo.insert(food);

      final updated = food.copyWith(kcalPer100g: 265, name: 'Pan Integral');
      await repo.update(updated);

      final retrieved = await repo.getById('f1');
      expect(retrieved!.name, 'Pan Integral');
      expect(retrieved.kcalPer100g, 265);
    });

    test('delete elimina un alimento', () async {
      await repo.insert(FoodModel(
        id: 'f1',
        name: 'Leche',
        kcalPer100g: 42,
      ));

      await repo.delete('f1');

      final retrieved = await repo.getById('f1');
      expect(retrieved, isNull);
    });

    test('search busca por nombre o marca', () async {
      await repo.insert(FoodModel(
        id: 'f1',
        name: 'Yogurt Griego',
        brand: 'Fage',
        kcalPer100g: 97,
      ));
      await repo.insert(FoodModel(
        id: 'f2',
        name: 'Yogurt Natural',
        brand: 'Danone',
        kcalPer100g: 62,
      ));
      await repo.insert(FoodModel(
        id: 'f3',
        name: 'Leche',
        kcalPer100g: 42,
      ));

      final results = await repo.search('yogurt');
      expect(results.length, 2);

      final fageResults = await repo.search('fage');
      expect(fageResults.length, 1);
      expect(fageResults.first.brand, 'Fage');
    });

    test('findByBarcode busca por código de barras', () async {
      await repo.insert(FoodModel(
        id: 'f1',
        name: 'Coca-Cola',
        barcode: '5449000000996',
        kcalPer100g: 42,
      ));

      final found = await repo.findByBarcode('5449000000996');
      expect(found, isNotNull);
      expect(found!.name, 'Coca-Cola');

      final notFound = await repo.findByBarcode('999999999');
      expect(notFound, isNull);
    });

    test('getUserCreated filtra por alimentos del usuario', () async {
      await repo.insert(FoodModel(
        id: 'f1',
        name: 'Mi Receta',
        userCreated: true,
        kcalPer100g: 200,
      ));
      await repo.insert(FoodModel(
        id: 'f2',
        name: 'Alimento USDA',
        verifiedSource: 'usda',
        userCreated: false,
        kcalPer100g: 100,
      ));

      final userFoods = await repo.getUserCreated();
      expect(userFoods.length, 1);
      expect(userFoods.first.name, 'Mi Receta');
    });

    test('watchAll emite stream de alimentos', () async {
      final stream = repo.watchAll();

      // Esperar el stream inicial (vacío)
      await expectLater(stream, emits(isEmpty));

      // Insertar y verificar que emite
      await repo.insert(FoodModel(
        id: 'f1',
        name: 'Test',
        kcalPer100g: 100,
      ));

      await expectLater(
        stream,
        emits(predicate<List<FoodModel>>((list) =>
            list.length == 1 && list.first.name == 'Test')),
      );
    });

    test('FoodModel macrosForGrams calcula correctamente', () {
      final food = FoodModel(
        id: 'f1',
        name: 'Pollo',
        kcalPer100g: 165,
        proteinPer100g: 31,
        carbsPer100g: 0,
        fatPer100g: 3.6,
      );

      final macros = food.macrosForGrams(150);

      expect(macros.kcal, 248); // (150/100) * 165 = 247.5 → 248
      expect(macros.protein, closeTo(46.5, 0.01)); // (150/100) * 31
      expect(macros.carbs, 0);
      expect(macros.fat, closeTo(5.4, 0.01)); // (150/100) * 3.6
    });
  });
}
