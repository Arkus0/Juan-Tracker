import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/database/database.dart';
import 'package:drift/drift.dart' hide isNotNull;

/// Tests for the food database FTS search functionality.
///
/// These tests verify that:
/// 1. The FTS5 table is created correctly
/// 2. Foods are inserted and the FTS index is populated
/// 3. FTS search returns correct results
/// 4. Fallback LIKE search works when FTS fails
void main() {
  group('Food Database FTS Search', () {
    late AppDatabase db;

    setUp(() async {
      // Create in-memory database for tests
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('FTS table is created on database init', () async {
      // Verify the FTS table exists
      final result = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='foods_fts'",
          )
          .get();

      expect(result, isNotEmpty, reason: 'FTS5 table foods_fts should exist');
    });

    test('Insert foods and verify FTS index is populated', () async {
      // Insert some test foods
      final testFoods = [
        FoodsCompanion(
          id: const Value('food-1'),
          name: const Value('Leche entera'),
          brand: const Value('Hacendado'),
          kcalPer100g: const Value(65),
          proteinPer100g: const Value(3.2),
          carbsPer100g: const Value(4.8),
          fatPer100g: const Value(3.5),
          userCreated: const Value(false),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        FoodsCompanion(
          id: const Value('food-2'),
          name: const Value('Leche de almendras'),
          brand: const Value('Alpro'),
          kcalPer100g: const Value(24),
          proteinPer100g: const Value(0.5),
          carbsPer100g: const Value(2.9),
          fatPer100g: const Value(1.1),
          userCreated: const Value(false),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        FoodsCompanion(
          id: const Value('food-3'),
          name: const Value('Yogurt griego'),
          brand: const Value('Fage'),
          kcalPer100g: const Value(97),
          proteinPer100g: const Value(9.0),
          carbsPer100g: const Value(3.0),
          fatPer100g: const Value(5.0),
          userCreated: const Value(false),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        FoodsCompanion(
          id: const Value('food-4'),
          name: const Value('Pollo asado'),
          brand: const Value('Carrefour'),
          kcalPer100g: const Value(165),
          proteinPer100g: const Value(31.0),
          carbsPer100g: const Value(0.0),
          fatPer100g: const Value(3.6),
          userCreated: const Value(false),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
        FoodsCompanion(
          id: const Value('food-5'),
          name: const Value('Arroz blanco'),
          brand: const Value('Brillante'),
          kcalPer100g: const Value(130),
          proteinPer100g: const Value(2.7),
          carbsPer100g: const Value(28.0),
          fatPer100g: const Value(0.3),
          userCreated: const Value(false),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      ];

      // Insert foods in batch
      await db.batch((batch) {
        batch.insertAll(db.foods, testFoods, mode: InsertMode.insertOrReplace);
      });

      // Verify foods are inserted
      final foodsCountResult = await db
          .customSelect('SELECT COUNT(*) as count FROM foods')
          .getSingle();
      expect(foodsCountResult.data['count'], 5);

      // Rebuild FTS index
      await db.rebuildFtsIndex();

      // Verify FTS index is populated
      final ftsCountResult = await db
          .customSelect('SELECT COUNT(*) as count FROM foods_fts')
          .getSingle();
      expect(
        ftsCountResult.data['count'],
        5,
        reason: 'FTS index should have 5 entries after rebuild',
      );
    });

    test('FTS search returns matching results for "leche"', () async {
      // Insert test foods
      await _insertTestFoods(db);
      await db.rebuildFtsIndex();

      // Search for "leche"
      final results = await db.searchFoodsFTS('leche');

      expect(
        results,
        isNotEmpty,
        reason: 'Search for "leche" should return results',
      );
      expect(results.length, 2, reason: 'Should find 2 items with "leche"');
      expect(results.map((f) => f.name).toSet(), {
        'Leche entera',
        'Leche de almendras',
      });
    });

    test(
      'FTS search returns matching results for partial prefix "lech"',
      () async {
        await _insertTestFoods(db);
        await db.rebuildFtsIndex();

        final results = await db.searchFoodsFTS('lech');

        expect(
          results,
          isNotEmpty,
          reason: 'Prefix search "lech" should return results',
        );
        expect(results.length, 2);
      },
    );

    test('FTS search supports offset pagination without duplicates', () async {
      final now = DateTime.now();
      await db.batch((batch) {
        batch.insertAll(db.foods, [
          FoodsCompanion.insert(
            id: 'pollo-1',
            name: 'Pollo plancha 1',
            kcalPer100g: 100,
            userCreated: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
          FoodsCompanion.insert(
            id: 'pollo-2',
            name: 'Pollo plancha 2',
            kcalPer100g: 101,
            userCreated: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
          FoodsCompanion.insert(
            id: 'pollo-3',
            name: 'Pollo plancha 3',
            kcalPer100g: 102,
            userCreated: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
          FoodsCompanion.insert(
            id: 'pollo-4',
            name: 'Pollo plancha 4',
            kcalPer100g: 103,
            userCreated: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
        ]);
      });
      await db.rebuildFtsIndex();

      final page1 = await db.searchFoodsFTS('pollo', limit: 2, offset: 0);
      final page2 = await db.searchFoodsFTS('pollo', limit: 2, offset: 2);

      expect(page1.length, 2);
      expect(page2.length, 2);

      final page1Ids = page1.map((f) => f.id).toSet();
      final page2Ids = page2.map((f) => f.id).toSet();
      expect(page1Ids.intersection(page2Ids), isEmpty);
    });

    test('FTS search returns matching results for brand', () async {
      await _insertTestFoods(db);
      await db.rebuildFtsIndex();

      final results = await db.searchFoodsFTS('hacendado');

      expect(
        results,
        isNotEmpty,
        reason: 'Search for brand should return results',
      );
      expect(results.first.brand, 'Hacendado');
    });

    test('FTS search returns empty for non-matching query', () async {
      await _insertTestFoods(db);
      await db.rebuildFtsIndex();

      final results = await db.searchFoodsFTS('chocolate');

      expect(results, isEmpty, reason: 'No foods match "chocolate"');
    });

    test('FTS search with multiple terms matches all', () async {
      await _insertTestFoods(db);
      await db.rebuildFtsIndex();

      final results = await db.searchFoodsFTS('leche almendras');

      expect(
        results.length,
        1,
        reason: 'Only "Leche de almendras" matches both terms',
      );
      expect(results.first.name, 'Leche de almendras');
    });

    test('FTS search is case-insensitive', () async {
      await _insertTestFoods(db);
      await db.rebuildFtsIndex();

      final resultsLower = await db.searchFoodsFTS('leche');
      final resultsUpper = await db.searchFoodsFTS('LECHE');
      final resultsMixed = await db.searchFoodsFTS('LeCHe');

      expect(resultsLower.length, resultsUpper.length);
      expect(resultsUpper.length, resultsMixed.length);
    });

    test('FTS fallback to LIKE works when searching normalizedName', () async {
      // Insert food with normalizedName set
      await db
          .into(db.foods)
          .insert(
            FoodsCompanion(
              id: const Value('food-test'),
              name: const Value('Test Food'),
              normalizedName: const Value('test food'),
              kcalPer100g: const Value(100),
              userCreated: const Value(false),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );

      // Don't rebuild FTS - so fallback will be used
      // But first make sure FTS has an entry or error will trigger fallback
      final results = await db.searchFoodsOffline('test');

      expect(results, isNotEmpty);
      expect(results.first.name, 'Test Food');
    });

    test('Direct FTS query works correctly', () async {
      await _insertTestFoods(db);
      await db.rebuildFtsIndex();

      // Test direct FTS query
      final results = await db
          .customSelect(
            "SELECT food_id, name FROM foods_fts WHERE foods_fts MATCH 'leche*'",
          )
          .get();

      expect(
        results,
        isNotEmpty,
        reason: 'Direct FTS MATCH query should return results',
      );
      expect(results.length, 2);
    });

    test('FTS query with 2-step approach returns complete food data', () async {
      await _insertTestFoods(db);
      await db.rebuildFtsIndex();

      // Test the CORRECT 2-step approach used in searchFoodsFTS
      // Step 1: Get IDs from FTS
      final ftsResults = await db
          .customSelect(
            "SELECT food_id FROM foods_fts WHERE foods_fts MATCH 'leche*' LIMIT 50",
          )
          .get();

      expect(ftsResults, isNotEmpty);

      // Step 2: Get full food data by IDs
      final foodIds = ftsResults
          .map((r) => r.data['food_id'] as String)
          .toList();
      final placeholders = List.filled(foodIds.length, '?').join(',');

      final results = await db
          .customSelect(
            'SELECT id, name, brand, kcal_per100g FROM foods WHERE id IN ($placeholders)',
            variables: foodIds.map((id) => Variable(id)).toList(),
          )
          .get();

      expect(results, isNotEmpty);
      expect(results.length, 2);
      expect(results.first.data['brand'], isNotNull);
    });

    test('searchFoodsByPrefix returns foods starting with prefix', () async {
      // Insert with normalizedName for prefix search
      await db
          .into(db.foods)
          .insert(
            FoodsCompanion(
              id: const Value('food-1'),
              name: const Value('Arroz blanco'),
              normalizedName: const Value('arroz blanco'),
              kcalPer100g: const Value(130),
              userCreated: const Value(false),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
      await db
          .into(db.foods)
          .insert(
            FoodsCompanion(
              id: const Value('food-2'),
              name: const Value('Arroz integral'),
              normalizedName: const Value('arroz integral'),
              kcalPer100g: const Value(111),
              userCreated: const Value(false),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );

      final results = await db.searchFoodsByPrefix('arr');

      expect(results.length, 2);
    });
  });

  group('FTS Index Rebuild', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('rebuildFtsIndex populates FTS from foods table', () async {
      // Insert foods
      await db
          .into(db.foods)
          .insert(
            FoodsCompanion(
              id: const Value('test-1'),
              name: const Value('Test Food'),
              kcalPer100g: const Value(100),
              userCreated: const Value(false),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );

      // FTS should be empty before rebuild (just created)
      // Actually, onCreate already calls rebuildFtsIndex, but let's test explicit rebuild
      await db.customStatement('DELETE FROM foods_fts');

      var ftsCount = await db
          .customSelect('SELECT COUNT(*) as count FROM foods_fts')
          .getSingle();
      expect(ftsCount.data['count'], 0);

      // Rebuild
      await db.rebuildFtsIndex();

      // Verify FTS now has entries
      ftsCount = await db
          .customSelect('SELECT COUNT(*) as count FROM foods_fts')
          .getSingle();
      expect(ftsCount.data['count'], 1);
    });

    test('insertFoodFts adds single food to FTS', () async {
      await db.insertFoodFts('new-id', 'New Food Name', 'New Brand');

      final results = await db
          .customSelect("SELECT * FROM foods_fts WHERE foods_fts MATCH 'new*'")
          .get();

      expect(results, isNotEmpty);
    });
  });
}

/// Helper function to insert test foods
Future<void> _insertTestFoods(AppDatabase db) async {
  final testFoods = [
    FoodsCompanion(
      id: const Value('food-1'),
      name: const Value('Leche entera'),
      brand: const Value('Hacendado'),
      kcalPer100g: const Value(65),
      userCreated: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
    FoodsCompanion(
      id: const Value('food-2'),
      name: const Value('Leche de almendras'),
      brand: const Value('Alpro'),
      kcalPer100g: const Value(24),
      userCreated: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
    FoodsCompanion(
      id: const Value('food-3'),
      name: const Value('Yogurt griego'),
      brand: const Value('Fage'),
      kcalPer100g: const Value(97),
      userCreated: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
    FoodsCompanion(
      id: const Value('food-4'),
      name: const Value('Pollo asado'),
      brand: const Value('Carrefour'),
      kcalPer100g: const Value(165),
      userCreated: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
    FoodsCompanion(
      id: const Value('food-5'),
      name: const Value('Arroz blanco'),
      brand: const Value('Brillante'),
      kcalPer100g: const Value(130),
      userCreated: const Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ),
  ];

  await db.batch((batch) {
    batch.insertAll(db.foods, testFoods, mode: InsertMode.insertOrReplace);
  });
}
