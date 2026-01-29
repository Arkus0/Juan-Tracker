import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/database/database.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/repositories/drift_diet_repositories.dart';

void main() {
  group('DriftWeighInRepository', () {
    late AppDatabase db;
    late DriftWeighInRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftWeighInRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insert y getAll funcionan correctamente', () async {
      await repo.insert(WeighInModel(
        id: 'w1',
        dateTime: DateTime(2026, 1, 15, 8, 0),
        weightKg: 75.5,
      ));

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.weightKg, 75.5);
    });

    test('getAll ordena por fecha descendente', () async {
      await repo.insert(WeighInModel(
        id: 'w1',
        dateTime: DateTime(2026, 1, 10, 8, 0),
        weightKg: 76.0,
      ));
      await repo.insert(WeighInModel(
        id: 'w2',
        dateTime: DateTime(2026, 1, 15, 8, 0),
        weightKg: 75.5,
      ));
      await repo.insert(WeighInModel(
        id: 'w3',
        dateTime: DateTime(2026, 1, 5, 8, 0),
        weightKg: 77.0,
      ));

      final all = await repo.getAll();
      expect(all.length, 3);
      expect(all[0].dateTime.day, 15); // Más reciente primero
      expect(all[1].dateTime.day, 10);
      expect(all[2].dateTime.day, 5);
    });

    test('getLatest devuelve el registro más reciente', () async {
      await repo.insert(WeighInModel(
        id: 'w1',
        dateTime: DateTime(2026, 1, 10, 8, 0),
        weightKg: 76.0,
      ));
      await repo.insert(WeighInModel(
        id: 'w2',
        dateTime: DateTime(2026, 1, 15, 8, 0),
        weightKg: 75.5,
      ));

      final latest = await repo.getLatest();
      expect(latest, isNotNull);
      expect(latest!.weightKg, 75.5);
      expect(latest.dateTime.day, 15);
    });

    test('getByDateRange filtra correctamente', () async {
      await repo.insert(WeighInModel(
        id: 'w1',
        dateTime: DateTime(2026, 1, 5, 8, 0),
        weightKg: 77.0,
      ));
      await repo.insert(WeighInModel(
        id: 'w2',
        dateTime: DateTime(2026, 1, 10, 8, 0),
        weightKg: 76.0,
      ));
      await repo.insert(WeighInModel(
        id: 'w3',
        dateTime: DateTime(2026, 1, 15, 8, 0),
        weightKg: 75.5,
      ));

      final range = await repo.getByDateRange(
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 12),
      );

      expect(range.length, 1);
      expect(range.first.weightKg, 76.0);
    });

    test('update modifica un registro', () async {
      final weighIn = WeighInModel(
        id: 'w1',
        dateTime: DateTime(2026, 1, 15, 8, 0),
        weightKg: 75.5,
        note: 'Peso inicial',
      );
      await repo.insert(weighIn);

      final updated = weighIn.copyWith(weightKg: 75.2, note: 'Corregido');
      await repo.update(updated);

      final retrieved = await repo.getById('w1');
      expect(retrieved!.weightKg, 75.2);
      expect(retrieved.note, 'Corregido');
    });

    test('delete elimina un registro', () async {
      await repo.insert(WeighInModel(
        id: 'w1',
        dateTime: DateTime(2026, 1, 15, 8, 0),
        weightKg: 75.5,
      ));

      await repo.delete('w1');

      final retrieved = await repo.getById('w1');
      expect(retrieved, isNull);
    });

    test('weightLbs convierte correctamente', () {
      final weighIn = WeighInModel(
        id: 'w1',
        dateTime: DateTime.now(),
        weightKg: 75.0,
      );

      expect(weighIn.weightLbs, closeTo(165.35, 0.1));
    });

    test('formatted devuelve string formateado', () {
      final weighIn = WeighInModel(
        id: 'w1',
        dateTime: DateTime.now(),
        weightKg: 75.5,
      );

      expect(weighIn.formatted(), '75.5 kg');
      expect(weighIn.formatted(useLbs: true), '166.4 lb');
    });
  });
}
