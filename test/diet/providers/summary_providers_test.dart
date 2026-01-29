import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/providers/summary_providers.dart';
import 'package:juan_tracker/diet/services/day_summary_calculator.dart';

void main() {
  group('TargetsFormState', () {
    test('empty crea estado por defecto', () {
      final state = TargetsFormState.empty();

      expect(state.kcalTarget, equals(2000));
      expect(state.proteinTarget, isNull);
      expect(state.carbsTarget, isNull);
      expect(state.fatTarget, isNull);
      expect(state.isEditing, isFalse);
    });

    test('copyWith mantiene valores no especificados', () {
      final state = TargetsFormState.empty();
      final newState = state.copyWith(kcalTarget: 2500);

      expect(newState.kcalTarget, equals(2500));
      expect(newState.proteinTarget, equals(state.proteinTarget));
      expect(newState.carbsTarget, equals(state.carbsTarget));
    });

    test('kcalFromMacros calcula correctamente', () {
      final state = TargetsFormState(
        kcalTarget: 2000,
        proteinTarget: 150,
        carbsTarget: 200,
        fatTarget: 50,
        validFrom: DateTime.now(),
      );

      // 150*4 + 200*4 + 50*9 = 600 + 800 + 450 = 1850
      expect(state.kcalFromMacros, equals(1850));
    });

    test('kcalFromMacros retorna null cuando no hay macros', () {
      final state = TargetsFormState.empty();
      expect(state.kcalFromMacros, isNull);
    });

    test('kcalDifference calcula diferencia correctamente', () {
      final state = TargetsFormState(
        kcalTarget: 2000,
        proteinTarget: 150,
        carbsTarget: 200,
        fatTarget: 50,
        validFrom: DateTime.now(),
      );

      // 2000 - 1850 = 150
      expect(state.kcalDifference, equals(150));
    });
  });

  group('DaySummary', () {
    test('hasTargets es true cuando hay objetivo', () {
      final summary = DaySummary(
        date: DateTime.now(),
        consumed: DailyTotals.empty,
        targets: TargetsModel(
          id: '1',
          validFrom: DateTime.now(),
          kcalTarget: 2000,
        ),
        progress: TargetsProgress(kcalConsumed: 0, proteinConsumed: 0, carbsConsumed: 0, fatConsumed: 0),
      );

      expect(summary.hasTargets, isTrue);
    });

    test('hasTargets es false cuando no hay objetivo', () {
      final summary = DaySummary(
        date: DateTime.now(),
        consumed: DailyTotals.empty,
        targets: null,
        progress: TargetsProgress(kcalConsumed: 0, proteinConsumed: 0, carbsConsumed: 0, fatConsumed: 0),
      );

      expect(summary.hasTargets, isFalse);
    });

    test('hasConsumption es true cuando hay consumo', () {
      final summary = DaySummary(
        date: DateTime.now(),
        consumed: DailyTotals(
          kcal: 100,
          protein: 10,
          carbs: 10,
          fat: 5,
          byMeal: {},
        ),
        targets: null,
        progress: TargetsProgress(kcalConsumed: 100, proteinConsumed: 10, carbsConsumed: 10, fatConsumed: 5),
      );

      expect(summary.hasConsumption, isTrue);
    });

    test('hasConsumption es false cuando no hay consumo', () {
      final summary = DaySummary(
        date: DateTime.now(),
        consumed: DailyTotals.empty,
        targets: null,
        progress: TargetsProgress(kcalConsumed: 0, proteinConsumed: 0, carbsConsumed: 0, fatConsumed: 0),
      );

      expect(summary.hasConsumption, isFalse);
    });
  });

  group('DaySummaryCalculator - integration scenarios', () {
    late DaySummaryCalculator calculator;

    setUp(() {
      calculator = const DaySummaryCalculator();
    });

    test('escenario: cambio de objetivo a mitad de semana', () {
      // Semana del 12-18 de enero 2026
      // Bulk hasta el miércoles 14, cut desde el jueves 15
      final bulkTarget = TargetsModel(
        id: 'bulk',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 3000,
        proteinTarget: 180,
        carbsTarget: 350,
        fatTarget: 100,
      );

      final cutTarget = TargetsModel(
        id: 'cut',
        validFrom: DateTime(2026, 1, 15),
        kcalTarget: 2200,
        proteinTarget: 160,
        carbsTarget: 200,
        fatTarget: 60,
      );

      final allTargets = [bulkTarget, cutTarget];

      // Lunes 12 - debería usar bulk
      final mondayResult = calculator.findActiveTargetForDate(
        allTargets,
        DateTime(2026, 1, 12),
      );
      expect(mondayResult?.id, equals('bulk'));

      // Miércoles 14 - último día de bulk
      final wednesdayResult = calculator.findActiveTargetForDate(
        allTargets,
        DateTime(2026, 1, 14),
      );
      expect(wednesdayResult?.id, equals('bulk'));

      // Jueves 15 - primer día de cut
      final thursdayResult = calculator.findActiveTargetForDate(
        allTargets,
        DateTime(2026, 1, 15),
      );
      expect(thursdayResult?.id, equals('cut'));

      // Domingo 18 - cut
      final sundayResult = calculator.findActiveTargetForDate(
        allTargets,
        DateTime(2026, 1, 18),
      );
      expect(sundayResult?.id, equals('cut'));
    });

    test('escenario: día sin entradas mantiene objetivo histórico', () {
      final date = DateTime(2026, 1, 10);
      final targets = TargetsModel(
        id: '1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2500,
      );
      final consumed = DailyTotals.empty;

      final summary = calculator.calculate(
        date: date,
        consumed: consumed,
        targets: targets,
      );

      // Debería mantener el objetivo aunque no haya consumo
      expect(summary.hasTargets, isTrue);
      expect(summary.targets?.kcalTarget, equals(2500));
      expect(summary.progress.kcalRemaining, equals(2500));
    });

    test('escenario: objetivo solo con calorías (sin macros)', () {
      final date = DateTime(2026, 1, 15);
      final targets = TargetsModel(
        id: '1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
        // Sin macros especificados
      );
      final consumed = DailyTotals(
        kcal: 1800,
        protein: 100,
        carbs: 150,
        fat: 60,
        byMeal: {},
      );

      final summary = calculator.calculate(
        date: date,
        consumed: consumed,
        targets: targets,
      );

      // Progreso de calorías debería funcionar
      expect(summary.progress.kcalPercent, equals(0.9));

      // Pero progreso de macros debería ser null
      expect(summary.progress.proteinPercent, isNull);
      expect(summary.progress.carbsPercent, isNull);
      expect(summary.progress.fatPercent, isNull);
    });

    test('escenario: progreso excedido en todos los macros', () {
      final date = DateTime(2026, 1, 15);
      final targets = TargetsModel(
        id: '1',
        validFrom: DateTime(2026, 1, 1),
        kcalTarget: 2000,
        proteinTarget: 150,
        carbsTarget: 200,
        fatTarget: 60,
      );
      final consumed = DailyTotals(
        kcal: 2500,
        protein: 180,
        carbs: 280,
        fat: 90,
        byMeal: {},
      );

      final summary = calculator.calculate(
        date: date,
        consumed: consumed,
        targets: targets,
      );

      // Todos los porcentajes deberían ser > 100%
      expect(summary.progress.kcalPercent, greaterThan(1.0));
      expect(summary.progress.proteinPercent, greaterThan(1.0));
      expect(summary.progress.carbsPercent, greaterThan(1.0));
      expect(summary.progress.fatPercent, greaterThan(1.0));

      // Remaining debería ser negativo
      expect(summary.progress.kcalRemaining, lessThan(0));
      expect(summary.progress.proteinRemaining, lessThan(0));
    });

    test('escenario: múltiples cambios de objetivo históricos', () {
      // Historial de 6 meses con múltiples cambios
      final targets = [
        TargetsModel(
          id: 'maintain',
          validFrom: DateTime(2025, 7, 1),
          kcalTarget: 2500,
        ),
        TargetsModel(
          id: 'bulk1',
          validFrom: DateTime(2025, 9, 1),
          kcalTarget: 3000,
        ),
        TargetsModel(
          id: 'cut1',
          validFrom: DateTime(2025, 11, 1),
          kcalTarget: 2200,
        ),
        TargetsModel(
          id: 'bulk2',
          validFrom: DateTime(2026, 1, 1),
          kcalTarget: 3200,
        ),
      ];

      // Agosto 2025 - maintain
      final augResult = calculator.findActiveTargetForDate(
        targets,
        DateTime(2025, 8, 15),
      );
      expect(augResult?.id, equals('maintain'));

      // Octubre 2025 - bulk1
      final octResult = calculator.findActiveTargetForDate(
        targets,
        DateTime(2025, 10, 15),
      );
      expect(octResult?.id, equals('bulk1'));

      // Diciembre 2025 - cut1
      final decResult = calculator.findActiveTargetForDate(
        targets,
        DateTime(2025, 12, 15),
      );
      expect(decResult?.id, equals('cut1'));

      // Enero 2026 - bulk2
      final janResult = calculator.findActiveTargetForDate(
        targets,
        DateTime(2026, 1, 15),
      );
      expect(janResult?.id, equals('bulk2'));
    });
  });
}
