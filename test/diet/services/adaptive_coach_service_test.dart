import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/services/adaptive_coach_service.dart';

void main() {
  group('AdaptiveCoachService', () {
    const service = AdaptiveCoachService();

    group('WeeklyData calculations', () {
      test('calculatedTdee with weight loss', () {
        // Si comes 2000 kcal y pierdes 0.5 kg en 7 días
        // TDEE = 2000 - (-0.5 * 7700 / 7) = 2000 + 550 = 2550
        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 8),
          avgDailyKcal: 2000,
          trendWeightStart: 80.0,
          trendWeightEnd: 79.5, // -0.5 kg
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        expect(weeklyData.calculatedTdee.round(), equals(2550));
      });

      test('calculatedTdee with weight gain', () {
        // Si comes 3000 kcal y ganas 0.3 kg en 7 días
        // TDEE = 3000 - (0.3 * 7700 / 7) = 3000 - 330 = 2670
        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 8),
          avgDailyKcal: 3000,
          trendWeightStart: 70.0,
          trendWeightEnd: 70.3, // +0.3 kg
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        expect(weeklyData.calculatedTdee.round(), equals(2670));
      });

      test('calculatedTdee with maintenance', () {
        // Peso estable
        // TDEE = 2500 - (0 * 7700 / 7) = 2500
        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 8),
          avgDailyKcal: 2500,
          trendWeightStart: 75.0,
          trendWeightEnd: 75.0,
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        expect(weeklyData.calculatedTdee.round(), equals(2500));
      });
    });

    group('Check-in with simulated scenarios', () {
      test('losing weight too fast - should reduce deficit', () {
        // Usuario quiere perder 0.5% (80kg * 0.005 = 0.4kg/semana)
        // Pero pierde 1.0 kg en una semana (doble de lo planeado)
        // Está comiendo 1500 kcal
        // TDEE = 1500 - (-1.0 * 7700 / 7) = 1500 + 1100 = 2600
        // Ajuste objetivo = 0.4kg * 7700 / 7 = 440 kcal déficit
        // Nuevo target = 2600 - 440 = 2160 kcal
        
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRatePercent: -0.005, // -0.5%
          initialTdeeEstimate: 2500,
          startingWeight: 80.0,
          startDate: DateTime(2026, 1, 1),
          currentTargetId: 'target_1',
          currentKcalTarget: 2000, // Target actual
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 1500,
          trendWeightStart: 78.0,
          trendWeightEnd: 77.0, // -1.0 kg (muy rápido)
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 77.0,
          checkInDate: DateTime(2026, 1, 22),
        );

        expect(result.status, equals(CheckInStatus.ready));
        expect(result.estimatedTdee, equals(2600)); // 1500 + 1100
        // Target = 2600 - 440 = 2160 (aprox)
        expect(result.proposedTargets.kcalTarget, lessThan(2500));
        expect(result.proposedTargets.kcalTarget, greaterThan(2000));
      });

      test('losing weight too slow - should increase deficit', () {
        // Usuario quiere perder 0.5% (peso actual ~77.9kg * 0.005 = 0.39kg/semana)
        // Pero solo pierde 0.1 kg en una semana
        // Está comiendo 2200 kcal
        // TDEE = 2200 - (-0.1 * 7700 / 7) = 2200 + 110 = 2310
        // Ajuste objetivo = 77.9 * 0.005 * 7700 / 7 = 428 kcal déficit
        // Nuevo target = 2310 - 428 = 1882 kcal
        
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRatePercent: -0.005,
          initialTdeeEstimate: 2500,
          startingWeight: 80.0,
          startDate: DateTime(2026, 1, 1),
          currentTargetId: 'target_1',
          currentKcalTarget: 2000, // Target actual
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 2200,
          trendWeightStart: 78.0,
          trendWeightEnd: 77.9, // -0.1 kg (muy lento)
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 77.9,
          checkInDate: DateTime(2026, 1, 22),
        );

        expect(result.status, equals(CheckInStatus.ready));
        expect(result.estimatedTdee, equals(2310)); // 2200 + 110
        // Target debería bajar para acelerar pérdida
        expect(result.proposedTargets.kcalTarget, closeTo(1882, 5));
      });

      test('maintenance goal - should match TDEE', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.maintain,
          weeklyRatePercent: 0.0,
          initialTdeeEstimate: 2500,
          startingWeight: 75.0,
          startDate: DateTime(2026, 1, 1),
          currentKcalTarget: 2500,
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 2400,
          trendWeightStart: 75.0,
          trendWeightEnd: 75.0, // Mantenimiento
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 75.0,
          checkInDate: DateTime(2026, 1, 22),
        );

        expect(result.status, equals(CheckInStatus.ready));
        expect(result.estimatedTdee, equals(2400));
        // Con mantenimiento, target = TDEE
        expect(result.proposedTargets.kcalTarget, equals(2400));
      });
    });

    group('Safety clamps', () {
      test('should clamp large increases', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.gain,
          weeklyRatePercent: 0.005,
          initialTdeeEstimate: 2000,
          startingWeight: 70.0,
          startDate: DateTime(2026, 1, 1),
          currentTargetId: 'target_1',
          currentKcalTarget: 2000,
        );

        // Usuario gana peso muy rápido, TDEE calculado = 3500
        // Sin clamps, el nuevo target podría ser 3500 + 350 = 3850
        // Con clamps: máximo 200 kcal más que el actual = 2200
        
        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 3500,
          trendWeightStart: 71.0,
          trendWeightEnd: 72.5, // +1.5 kg en una semana (extremo)
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 72.5,
          checkInDate: DateTime(2026, 1, 22),
        );

        expect(result.status, equals(CheckInStatus.ready));
        expect(result.wasClamped, isTrue);
        expect(result.proposedTargets.kcalTarget, equals(2200)); // 2000 + 200
      });

      test('should clamp large decreases', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRatePercent: -0.005,
          initialTdeeEstimate: 2500,
          startingWeight: 80.0,
          startDate: DateTime(2026, 1, 1),
          currentTargetId: 'target_1',
          currentKcalTarget: 2500,
        );

        // TDEE calculado muy bajo, sin clamps bajaría a 1200
        // Con clamps: mínimo 200 kcal menos que actual = 2300
        
        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 1200,
          trendWeightStart: 78.0,
          trendWeightEnd: 77.5, // -0.5 kg
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 77.5,
          checkInDate: DateTime(2026, 1, 22),
        );

        expect(result.status, equals(CheckInStatus.ready));
        expect(result.wasClamped, isTrue);
        expect(result.proposedTargets.kcalTarget, equals(2300)); // 2500 - 200
      });

      test('should enforce minimum 1200 kcal', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRatePercent: -0.01, // Agresivo -1%
          initialTdeeEstimate: 1500,
          startingWeight: 60.0,
          startDate: DateTime(2026, 1, 1),
          currentKcalTarget: 1400,
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 1000,
          trendWeightStart: 59.0,
          trendWeightEnd: 58.8,
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 58.8,
          checkInDate: DateTime(2026, 1, 22),
        );

        expect(result.proposedTargets.kcalTarget, greaterThanOrEqualTo(1200));
      });
    });

    group('Insufficient data handling', () {
      test('should return insufficientData when not enough diary entries', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRatePercent: -0.005,
          initialTdeeEstimate: 2500,
          startingWeight: 80.0,
          startDate: DateTime(2026, 1, 1),
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 2000,
          trendWeightStart: 78.0,
          trendWeightEnd: 77.5,
          daysWithDiaryEntries: 2, // Menos del mínimo (4)
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 77.5,
          checkInDate: DateTime(2026, 1, 22),
        );

        expect(result.status, equals(CheckInStatus.insufficientData));
        expect(result.errorMessage, contains('diario'));
      });

      test('should return insufficientData when not enough weigh-ins', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRatePercent: -0.005,
          initialTdeeEstimate: 2500,
          startingWeight: 80.0,
          startDate: DateTime(2026, 1, 1),
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 2000,
          trendWeightStart: 78.0,
          trendWeightEnd: 77.5,
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 1, // Menos del mínimo (3)
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 77.5,
          checkInDate: DateTime(2026, 1, 22),
        );

        expect(result.status, equals(CheckInStatus.insufficientData));
        expect(result.errorMessage, contains('pesajes'));
      });
    });

    group('Macro calculations', () {
      test('should calculate protein based on body weight', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.maintain,
          weeklyRatePercent: 0.0,
          initialTdeeEstimate: 2500,
          startingWeight: 80.0,
          startDate: DateTime(2026, 1, 1),
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 2500,
          trendWeightStart: 80.0,
          trendWeightEnd: 80.0,
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 80.0,
          checkInDate: DateTime(2026, 1, 22),
        );

        // Con proteinMultiplier = 2.0, 80kg * 2 = 160g de proteína
        expect(result.proposedTargets.proteinTarget, equals(160));
        expect(result.proposedTargets.fatTarget, isNotNull);
        expect(result.proposedTargets.carbsTarget, isNotNull);
      });
    });

    group('Explanation generation', () {
      test('should generate clear explanation lines', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRatePercent: -0.005,
          initialTdeeEstimate: 2500,
          startingWeight: 80.0,
          startDate: DateTime(2026, 1, 1),
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2026, 1, 15),
          endDate: DateTime(2026, 1, 22),
          avgDailyKcal: 2000,
          trendWeightStart: 78.0,
          trendWeightEnd: 77.5,
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 77.5,
          checkInDate: DateTime(2026, 1, 22),
        );

        expect(result.explanation.line1, contains('Ingesta'));
        expect(result.explanation.line2, contains('Cambio'));
        expect(result.explanation.line3, contains('TDEE'));
        expect(result.explanation.line4, contains('Ajuste'));
        expect(result.explanation.line5, contains('Nuevo target'));
      });
    });
  });

  group('Regression tests - Known scenarios', () {
    const service = AdaptiveCoachService();

    test('Scenario 1: Cutting plateau (user stuck)', () {
      // Usuario en déficit de 500 kcal pero no pierde peso
      // TDEE debe ser mayor de lo esperado
      final plan = CoachPlan(
        id: 'test',
        goal: WeightGoal.lose,
        weeklyRatePercent: -0.005,
        initialTdeeEstimate: 2500,
        startingWeight: 80.0,
        startDate: DateTime(2026, 1, 1),
        currentKcalTarget: 2000,
      );

      final weeklyData = WeeklyData(
        startDate: DateTime(2026, 1, 15),
        endDate: DateTime(2026, 1, 22),
        avgDailyKcal: 2000,
        trendWeightStart: 78.0,
        trendWeightEnd: 78.0, // Sin cambio (plateau)
        daysWithDiaryEntries: 7,
        daysWithWeighIns: 7,
      );

      final result = service.calculateCheckIn(
        plan: plan,
        weeklyData: weeklyData,
        currentWeight: 78.0,
        checkInDate: DateTime(2026, 1, 22),
      );

      // TDEE debe ser ~2000 (comiendo 2000 y manteniendo)
      expect(result.estimatedTdee, equals(2000));
      // Target debe bajar para romper plateau: 2000 - 440 = 1560
      // Pero con clamp: 2000 - 200 = 1800
      expect(result.proposedTargets.kcalTarget, equals(1800));
    });

    test('Scenario 2: Recomp (beginner gains)', () {
      // Usuario nuevo: pierde grasa y gana músculo simultáneamente
      // Peso estable pero probablemente en déficit calórico leve
      final plan = CoachPlan(
        id: 'test',
        goal: WeightGoal.maintain,
        weeklyRatePercent: 0.0,
        initialTdeeEstimate: 2800,
        startingWeight: 85.0,
        startDate: DateTime(2026, 1, 1),
        currentKcalTarget: 2600,
      );

      final weeklyData = WeeklyData(
        startDate: DateTime(2026, 1, 15),
        endDate: DateTime(2026, 1, 22),
        avgDailyKcal: 2400, // Ligero déficit
        trendWeightStart: 84.0,
        trendWeightEnd: 84.0, // Peso estable
        daysWithDiaryEntries: 7,
        daysWithWeighIns: 7,
      );

      final result = service.calculateCheckIn(
        plan: plan,
        weeklyData: weeklyData,
        currentWeight: 84.0,
        checkInDate: DateTime(2026, 1, 22),
      );

      // TDEE debe ser ~2400
      expect(result.estimatedTdee, equals(2400));
      // Con mantenimiento, target = TDEE = 2400
      expect(result.proposedTargets.kcalTarget, equals(2400));
    });

    test('Scenario 3: Bulking too fast', () {
      // Usuario quiere ganar 0.25% pero gana 1% (mayormente grasa)
      // Coach debe ajustar hacia arriba (más calorías) pero con cuidado
      final plan = CoachPlan(
        id: 'test',
        goal: WeightGoal.gain,
        weeklyRatePercent: 0.0025, // +0.25%
        initialTdeeEstimate: 3000,
        startingWeight: 70.0,
        startDate: DateTime(2026, 1, 1),
        currentKcalTarget: 3200,
      );

      final weeklyData = WeeklyData(
        startDate: DateTime(2026, 1, 15),
        endDate: DateTime(2026, 1, 22),
        avgDailyKcal: 3800,
        trendWeightStart: 71.0,
        trendWeightEnd: 71.7, // +0.7 kg = 1% del peso
        daysWithDiaryEntries: 7,
        daysWithWeighIns: 7,
      );

      final result = service.calculateCheckIn(
        plan: plan,
        weeklyData: weeklyData,
        currentWeight: 71.7,
        checkInDate: DateTime(2026, 1, 22),
      );

      // TDEE = 3800 - (0.7 * 7700 / 7) = 3800 - 770 = 3030
      expect(result.estimatedTdee, closeTo(3030, 1));
      
      // Ajuste objetivo = 71.7 * 0.0025 * 7700 / 7 = ~197 kcal
      // Target teórico = 3030 + 197 = 3227
      // Pero debería estar clamped a 3200 + 200 = 3400 (no aplica en este caso)
      // O si currentKcalTarget es 3200, 3227 está dentro del rango 3000-3400
      expect(result.proposedTargets.kcalTarget, closeTo(3227, 10));
    });
  });
}
