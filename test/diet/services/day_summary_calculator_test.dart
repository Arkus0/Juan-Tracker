import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/services/day_summary_calculator.dart';

void main() {
  group('DaySummaryCalculator', () {
    late DaySummaryCalculator calculator;

    setUp(() {
      calculator = const DaySummaryCalculator();
    });

    group('calculate', () {
      test('calcula resumen con targets disponibles', () {
        final date = DateTime(2026, 1, 15);
        final targets = TargetsModel(
          id: '1',
          validFrom: DateTime(2026, 1, 1),
          kcalTarget: 2500,
          proteinTarget: 150,
          carbsTarget: 300,
          fatTarget: 80,
        );
        final consumed = DailyTotals(
          kcal: 2000,
          protein: 120,
          carbs: 250,
          fat: 60,
          byMeal: {},
        );

        final summary = calculator.calculate(
          date: date,
          consumed: consumed,
          targets: targets,
        );

        expect(summary.date, equals(DateTime(2026, 1, 15)));
        expect(summary.hasTargets, isTrue);
        expect(summary.consumed.kcal, equals(2000));
        expect(summary.targets?.kcalTarget, equals(2500));
        expect(summary.progress.kcalConsumed, equals(2000));
        expect(summary.progress.kcalPercent, equals(0.8));
        expect(summary.progress.kcalRemaining, equals(500));
      });

      test('calcula resumen sin targets', () {
        final date = DateTime(2026, 1, 15);
        final consumed = DailyTotals(
          kcal: 2000,
          protein: 120,
          carbs: 250,
          fat: 60,
          byMeal: {},
        );

        final summary = calculator.calculate(
          date: date,
          consumed: consumed,
          targets: null,
        );

        expect(summary.hasTargets, isFalse);
        expect(summary.progress.kcalPercent, isNull);
        expect(summary.progress.kcalRemaining, isNull);
      });

      test('calcula resumen con consumo vacío', () {
        final date = DateTime(2026, 1, 15);
        final targets = TargetsModel(
          id: '1',
          validFrom: DateTime(2026, 1, 1),
          kcalTarget: 2500,
        );
        const consumed = DailyTotals.empty;

        final summary = calculator.calculate(
          date: date,
          consumed: consumed,
          targets: targets,
        );

        expect(summary.hasConsumption, isFalse);
        expect(summary.progress.kcalPercent, equals(0.0));
        expect(summary.progress.kcalRemaining, equals(2500));
      });

      test('calcula progreso cuando se excede el objetivo', () {
        final date = DateTime(2026, 1, 15);
        final targets = TargetsModel(
          id: '1',
          validFrom: DateTime(2026, 1, 1),
          kcalTarget: 2000,
        );
        final consumed = DailyTotals(
          kcal: 2500,
          protein: 150,
          carbs: 300,
          fat: 80,
          byMeal: {},
        );

        final summary = calculator.calculate(
          date: date,
          consumed: consumed,
          targets: targets,
        );

        expect(summary.progress.kcalPercent, equals(1.25));
        expect(summary.progress.kcalRemaining, equals(-500));
      });

      test('calcula porcentajes de macros correctamente', () {
        final date = DateTime(2026, 1, 15);
        final targets = TargetsModel(
          id: '1',
          validFrom: DateTime(2026, 1, 1),
          kcalTarget: 2000,
          proteinTarget: 100,
          carbsTarget: 200,
          fatTarget: 50,
        );
        final consumed = DailyTotals(
          kcal: 1000,
          protein: 50,
          carbs: 100,
          fat: 25,
          byMeal: {},
        );

        final summary = calculator.calculate(
          date: date,
          consumed: consumed,
          targets: targets,
        );

        expect(summary.progress.proteinPercent, equals(0.5));
        expect(summary.progress.carbsPercent, equals(0.5));
        expect(summary.progress.fatPercent, equals(0.5));
      });
    });

    group('findActiveTargetForDate', () {
      test('retorna null cuando no hay targets', () {
        final date = DateTime(2026, 1, 15);
        final result = calculator.findActiveTargetForDate([], date);
        expect(result, isNull);
      });

      test('encuentra target activo para fecha dentro del rango', () {
        final date = DateTime(2026, 1, 15);
        final targets = [
          TargetsModel(
            id: '1',
            validFrom: DateTime(2026, 1, 1),
            kcalTarget: 2500,
          ),
        ];

        final result = calculator.findActiveTargetForDate(targets, date);
        expect(result?.id, equals('1'));
      });

      test('usa target más reciente cuando hay múltiples', () {
        final date = DateTime(2026, 1, 20);
        final targets = [
          TargetsModel(
            id: '1',
            validFrom: DateTime(2026, 1, 1),
            kcalTarget: 2500,
          ),
          TargetsModel(
            id: '2',
            validFrom: DateTime(2026, 1, 15),
            kcalTarget: 2300,
          ),
        ];

        final result = calculator.findActiveTargetForDate(targets, date);
        expect(result?.id, equals('2'));
        expect(result?.kcalTarget, equals(2300));
      });

      test('usa target anterior si la fecha es antes del nuevo target', () {
        final date = DateTime(2026, 1, 10);
        final targets = [
          TargetsModel(
            id: '1',
            validFrom: DateTime(2026, 1, 1),
            kcalTarget: 2500,
          ),
          TargetsModel(
            id: '2',
            validFrom: DateTime(2026, 1, 15),
            kcalTarget: 2300,
          ),
        ];

        final result = calculator.findActiveTargetForDate(targets, date);
        expect(result?.id, equals('1'));
      });

      test('ignora hora en la comparación de fechas', () {
        final date = DateTime(2026, 1, 15, 14, 30); // 2:30 PM
        final targets = [
          TargetsModel(
            id: '1',
            validFrom: DateTime(2026, 1, 15, 9, 0), // 9:00 AM mismo día
            kcalTarget: 2500,
          ),
        ];

        final result = calculator.findActiveTargetForDate(targets, date);
        expect(result?.id, equals('1'));
      });

      test('retorna null cuando todos los targets son futuros', () {
        final date = DateTime(2026, 1, 10);
        final targets = [
          TargetsModel(
            id: '1',
            validFrom: DateTime(2026, 1, 15),
            kcalTarget: 2500,
          ),
        ];

        final result = calculator.findActiveTargetForDate(targets, date);
        expect(result, isNull);
      });

      test('maneja cambio de target a mitad de semana', () {
        // Cambio de objetivo el miércoles
        final monday = DateTime(2026, 1, 12);
        final wednesday = DateTime(2026, 1, 14);
        final friday = DateTime(2026, 1, 16);

        final targets = [
          TargetsModel(
            id: 'bulk',
            validFrom: DateTime(2026, 1, 1),
            kcalTarget: 3000,
          ),
          TargetsModel(
            id: 'cut',
            validFrom: DateTime(2026, 1, 14),
            kcalTarget: 2200,
          ),
        ];

        final resultMonday = calculator.findActiveTargetForDate(targets, monday);
        final resultWednesday = calculator.findActiveTargetForDate(targets, wednesday);
        final resultFriday = calculator.findActiveTargetForDate(targets, friday);

        expect(resultMonday?.id, equals('bulk'));
        expect(resultMonday?.kcalTarget, equals(3000));
        expect(resultWednesday?.id, equals('cut'));
        expect(resultWednesday?.kcalTarget, equals(2200));
        expect(resultFriday?.id, equals('cut'));
        expect(resultFriday?.kcalTarget, equals(2200));
      });

      test('ordena correctamente targets desordenados', () {
        final date = DateTime(2026, 1, 20);
        final targets = [
          TargetsModel(
            id: '2',
            validFrom: DateTime(2026, 1, 15),
            kcalTarget: 2300,
          ),
          TargetsModel(
            id: '3',
            validFrom: DateTime(2026, 1, 20),
            kcalTarget: 2100,
          ),
          TargetsModel(
            id: '1',
            validFrom: DateTime(2026, 1, 1),
            kcalTarget: 2500,
          ),
        ];

        final result = calculator.findActiveTargetForDate(targets, date);
        expect(result?.id, equals('3'));
      });
    });

    group('edge cases', () {
      test('día sin entradas pero con objetivo configurado', () {
        final date = DateTime(2026, 1, 15);
        final targets = TargetsModel(
          id: '1',
          validFrom: DateTime(2026, 1, 1),
          kcalTarget: 2500,
        );
        const consumed = DailyTotals.empty;

        final summary = calculator.calculate(
          date: date,
          consumed: consumed,
          targets: targets,
        );

        expect(summary.hasTargets, isTrue);
        expect(summary.hasConsumption, isFalse);
        expect(summary.progress.kcalRemaining, equals(2500));
      });

      test('objetivo con macros nulos', () {
        final date = DateTime(2026, 1, 15);
        final targets = TargetsModel(
          id: '1',
          validFrom: DateTime(2026, 1, 1),
          kcalTarget: 2500,
          // proteinTarget, carbsTarget, fatTarget son null
        );
        final consumed = DailyTotals(
          kcal: 2000,
          protein: 100,
          carbs: 200,
          fat: 50,
          byMeal: {},
        );

        final summary = calculator.calculate(
          date: date,
          consumed: consumed,
          targets: targets,
        );

        expect(summary.progress.kcalPercent, equals(0.8));
        expect(summary.progress.proteinPercent, isNull);
        expect(summary.progress.carbsPercent, isNull);
        expect(summary.progress.fatPercent, isNull);
      });

      test('objetivo con fecha exacta de validez', () {
        final date = DateTime(2026, 1, 15);
        final targets = [
          TargetsModel(
            id: '1',
            validFrom: DateTime(2026, 1, 15), // Mismo día
            kcalTarget: 2500,
          ),
        ];

        final result = calculator.findActiveTargetForDate(targets, date);
        expect(result?.id, equals('1'));
      });
    });
  });
}
