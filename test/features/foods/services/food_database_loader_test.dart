import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:juan_tracker/features/foods/providers/market_providers.dart';
import 'package:juan_tracker/features/foods/services/food_database_loader.dart';
import 'package:juan_tracker/training/database/database.dart';

void main() {
  group('FoodDatabaseLoader', () {
    late AppDatabase db;
    late FoodDatabaseLoader loader;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'food_db_version_spain': 1});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      loader = FoodDatabaseLoader(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'clearDatabase elimina solo catálogo importado y preserva alimentos del usuario',
      () async {
        final now = DateTime.now();

        await db.batch((b) {
          b.insertAll(db.foods, [
            FoodsCompanion.insert(
              id: 'seed-food',
              name: 'Leche Seed',
              kcalPer100g: 60,
              userCreated: const Value(false),
              createdAt: now,
              updatedAt: now,
            ),
            FoodsCompanion.insert(
              id: 'user-food',
              name: 'Comida Usuario',
              kcalPer100g: 120,
              userCreated: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          ]);
        });

        await db.rebuildFtsIndex();

        await loader.clearDatabase(FoodMarket.spain);

        final remainingFoods = await db.select(db.foods).get();
        expect(remainingFoods.length, 1);
        expect(remainingFoods.single.id, 'user-food');
        expect(remainingFoods.single.userCreated, true);

        final ftsCount = await db
            .customSelect('SELECT COUNT(*) as cnt FROM foods_fts')
            .getSingle();
        expect(ftsCount.data['cnt'], 1);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('food_db_version_spain'), isFalse);
      },
    );
  });
}
