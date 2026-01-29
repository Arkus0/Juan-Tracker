import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/database/database.dart' hide MealType;
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/repositories/drift_diet_repositories.dart';

void main() {
  group('DriftTargetsRepository', () {
    late AppDatabase db;
    late DriftTargetsRepository repo;
    late DriftDiaryRepository diaryRepo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      diaryRepo = DriftDiaryRepository(db);
      repo = DriftTargetsRepository(db, diaryRepo);
    });

    tearDown(() async {
      await db.close();
    });

    test('insert y getAll funcionan correctamente', () async {
      final target = TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
        proteinTarget: 150,
        carbsTarget: 200,
        fatTarget: 70,
      );

      await repo.insert(target);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.kcalTarget, 2000);
      expect(all.first.proteinTarget, 150);
    });

    test('getAll ordena por validFrom descendente', () async {
      await repo.insert(TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
      ));
      await repo.insert(TargetsModel(
        id: 't2',
        validFrom: DateTime(2026, 2, 1),
        kcalTarget: 2200,
      ));
      await repo.insert(TargetsModel(
        id: 't3',
        validFrom: DateTime(2026, 1, 15),
        kcalTarget: 2100,
      ));

      final all = await repo.getAll();
      expect(all[0].kcalTarget, 2200); // Febrero primero
      expect(all[1].kcalTarget, 2100); // Enero 15 segundo
      expect(all[2].kcalTarget, 2000); // Enero 1 tercero
    });

    test('getActiveForDate devuelve el objetivo correcto', () async {
      await repo.insert(TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
      ));
      await repo.insert(TargetsModel(
        id: 't2',
        validFrom: DateTime(2026, 1, 15),
        kcalTarget: 2200,
      ));

      final targetJan10 = await repo.getActiveForDate(DateTime(2026, 1, 10));
      expect(targetJan10!.kcalTarget, 2000);

      final targetJan20 = await repo.getActiveForDate(DateTime(2026, 1, 20));
      expect(targetJan20!.kcalTarget, 2200);

      final targetJan15 = await repo.getActiveForDate(DateTime(2026, 1, 15));
      expect(targetJan15!.kcalTarget, 2200); // El nuevo aplica desde el 15
    });

    test('getActiveForDate devuelve null si no hay objetivos', () async {
      final target = await repo.getActiveForDate(DateTime(2026, 1, 10));
      expect(target, isNull);
    });

    test('update modifica un objetivo', () async {
      final target = TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
        proteinTarget: 150,
      );
      await repo.insert(target);

      final updated = target.copyWith(kcalTarget: 2100, proteinTarget: 160);
      await repo.update(updated);

      final retrieved = await repo.getActiveForDate(DateTime(2026, 1, 1));
      expect(retrieved!.kcalTarget, 2100);
      expect(retrieved.proteinTarget, 160);
    });

    test('delete elimina un objetivo', () async {
      await repo.insert(TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
      ));

      await repo.delete('t1');

      final all = await repo.getAll();
      expect(all, isEmpty);
    });

    test('kcalFromMacros calcula calorías de macros', () {
      final target = TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
        proteinTarget: 150, // 150 * 4 = 600
        carbsTarget: 200,   // 200 * 4 = 800
        fatTarget: 70,      // 70 * 9 = 630
      );

      expect(target.kcalFromMacros, 2030); // 600 + 800 + 630
    });

    test('TargetsModel.getActiveForDate funciona correctamente', () {
      final targets = [
        TargetsModel(
          id: 't1',
          validFrom: DateTime(2026, 1, 1),
          kcalTarget: 2000,
        ),
        TargetsModel(
          id: 't2',
          validFrom: DateTime(2026, 1, 15),
          kcalTarget: 2200,
        ),
        TargetsModel(
          id: 't3',
          validFrom: DateTime(2026, 2, 1),
          kcalTarget: 2100,
        ),
      ];

      final activeJan5 = TargetsModel.getActiveForDate(targets, DateTime(2026, 1, 5));
      expect(activeJan5!.kcalTarget, 2000);

      final activeJan20 = TargetsModel.getActiveForDate(targets, DateTime(2026, 1, 20));
      expect(activeJan20!.kcalTarget, 2200);

      final activeFeb10 = TargetsModel.getActiveForDate(targets, DateTime(2026, 2, 10));
      expect(activeFeb10!.kcalTarget, 2100);
    });

    test('getProgressForDate calcula progreso correctamente', () async {
      // Crear objetivo
      await repo.insert(TargetsModel(
        id: 't1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
        proteinTarget: 150,
        carbsTarget: 200,
        fatTarget: 70,
      ));

      // Crear entradas del diario
      final date = DateTime(2026, 1, 15);
      await diaryRepo.insert(DiaryEntryModel.quickAdd(
        id: 'e1',
        date: date,
        mealType: MealType.breakfast,
        name: 'Desayuno',
        kcal: 500,
        protein: 30,
        carbs: 60,
        fat: 15,
      ));
      await diaryRepo.insert(DiaryEntryModel.quickAdd(
        id: 'e2',
        date: date,
        mealType: MealType.lunch,
        name: 'Almuerzo',
        kcal: 700,
        protein: 50,
        carbs: 70,
        fat: 25,
      ));

      final progress = await repo.getProgressForDate(date);

      expect(progress.targets, isNotNull);
      expect(progress.kcalConsumed, 1200); // 500 + 700
      expect(progress.proteinConsumed, 80); // 30 + 50
      expect(progress.kcalPercent, 0.6); // 1200 / 2000
      expect(progress.proteinPercent, closeTo(0.533, 0.01)); // 80 / 150
      expect(progress.kcalRemaining, 800); // 2000 - 1200
    });

    test('TargetsProgress porcentajes funcionan sin targets', () {
      const progress = TargetsProgress(
        targets: null,
        kcalConsumed: 1500,
        proteinConsumed: 100,
        carbsConsumed: 150,
        fatConsumed: 50,
      );

      expect(progress.kcalPercent, isNull);
      expect(progress.proteinPercent, isNull);
      expect(progress.kcalRemaining, isNull);
    });
  });
}
