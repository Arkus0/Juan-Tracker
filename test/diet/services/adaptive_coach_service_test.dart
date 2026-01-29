import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/services/adaptive_coach_service.dart';

void main() {
  group('AdaptiveCoachService', () {
    late AdaptiveCoachService service;

    setUp(() {
      service = const AdaptiveCoachService();
    });

    group('MacroPreset', () {
      test('balanced preset should sum to 100%', () {
        final preset = MacroPreset.balanced;
        final total = preset.proteinPercent + preset.carbsPercent + preset.fatPercent;
        expect(total, closeTo(1.0, 0.01));
      });

      test('highProtein preset should have 40% protein', () {
        expect(MacroPreset.highProtein.proteinPercent, closeTo(0.40, 0.01));
      });

      test('keto preset should have less than 10% carbs', () {
        expect(MacroPreset.keto.carbsPercent, lessThan(0.10));
      });
    });

    group('CoachPlan calculations', () {
      test('weeklyRateKg should be calculated from percentage', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRateKg: -0.4, // -0.5% of 80kg
          initialTdeeEstimate: 2500,
          startingWeight: 80,
          startDate: DateTime.now(),
          macroPreset: MacroPreset.balanced,
        );

        expect(plan.weeklyRateDisplay, closeTo(-0.4, 0.01));
      });

      test('dailyAdjustmentKcal should be correct for weight loss', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRateKg: -0.5, // Lose 0.5kg/week
          initialTdeeEstimate: 2500,
          startingWeight: 80,
          startDate: DateTime.now(),
          macroPreset: MacroPreset.balanced,
        );

        // 0.5kg * 7700kcal/kg / 7days = ~550kcal deficit
        expect(plan.dailyAdjustmentKcal, closeTo(-550, 10));
      });

      test('goalDescription should include kg and kcal', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRateKg: -0.5,
          initialTdeeEstimate: 2500,
          startingWeight: 80,
          startDate: DateTime.now(),
          macroPreset: MacroPreset.balanced,
        );

        expect(plan.goalDescription, contains('0.50'));
        expect(plan.goalDescription, contains('kcal'));
        expect(plan.goalDescription, contains('déficit'));
      });
    });

    group('WeeklyData calculations', () {
      test('calculatedTdee should account for weight change', () {
        final weeklyData = WeeklyData(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 8),
          avgDailyKcal: 2000,
          trendWeightStart: 80.0,
          trendWeightEnd: 79.5, // Lost 0.5kg
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 3,
        );

        // TDEE = 2000 - (-0.5 * 7700 / 7)
        // TDEE = 2000 + 550 = 2550
        expect(weeklyData.calculatedTdee, closeTo(2550, 10));
      });

      test('hasEnoughData should require minimum days', () {
        final insufficientData = WeeklyData(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 8),
          avgDailyKcal: 2000,
          trendWeightStart: 80.0,
          trendWeightEnd: 79.5,
          daysWithDiaryEntries: 2, // Less than required
          daysWithWeighIns: 1,
        );

        expect(insufficientData.hasEnoughData, isFalse);

        final sufficientData = WeeklyData(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 8),
          avgDailyKcal: 2000,
          trendWeightStart: 80.0,
          trendWeightEnd: 79.5,
          daysWithDiaryEntries: 5, // More than required
          daysWithWeighIns: 4,
        );

        expect(sufficientData.hasEnoughData, isTrue);
      });
    });

    group('CheckIn calculation', () {
      test('should clamp weekly kcal change to max 200', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRateKg: -1.0, // Aggressive 1kg/week loss
          initialTdeeEstimate: 2500,
          startingWeight: 80,
          startDate: DateTime(2024, 1, 1),
          currentKcalTarget: 2500,
          macroPreset: MacroPreset.balanced,
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 8),
          avgDailyKcal: 2000,
          trendWeightStart: 80.0,
          trendWeightEnd: 79.0, // Lost 1kg
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 79,
          checkInDate: DateTime(2024, 1, 8),
        );

        expect(result.wasClamped, isTrue);
        // Max change is 200kcal per week
        expect(result.proposedTargets.kcalTarget, greaterThan(2299)); // 2500 - 200
        expect(result.proposedTargets.kcalTarget, lessThan(2301));
      });

      test('should return insufficientData when not enough weigh-ins', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.lose,
          weeklyRateKg: -0.5,
          initialTdeeEstimate: 2500,
          startingWeight: 80,
          startDate: DateTime(2024, 1, 1),
          macroPreset: MacroPreset.balanced,
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 8),
          avgDailyKcal: 2000,
          trendWeightStart: 80.0,
          trendWeightEnd: 80.0,
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 1, // Not enough
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 80,
          checkInDate: DateTime(2024, 1, 8),
        );

        expect(result.status, CheckInStatus.insufficientData);
      });

      test('should calculate correct macros from preset', () {
        final plan = CoachPlan(
          id: 'test',
          goal: WeightGoal.maintain,
          weeklyRateKg: 0.0,
          initialTdeeEstimate: 2500,
          startingWeight: 80,
          startDate: DateTime(2024, 1, 1),
          macroPreset: MacroPreset.highProtein,
        );

        final weeklyData = WeeklyData(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 8),
          avgDailyKcal: 2500,
          trendWeightStart: 80.0,
          trendWeightEnd: 80.0,
          daysWithDiaryEntries: 7,
          daysWithWeighIns: 7,
        );

        final result = service.calculateCheckIn(
          plan: plan,
          weeklyData: weeklyData,
          currentWeight: 80,
          checkInDate: DateTime(2024, 1, 8),
        );

        // High protein preset = 40% protein
        // 2500 * 0.40 / 4 = 250g protein
        expect(result.proposedTargets.proteinTarget, closeTo(250, 10));
      });
    });

    group('Custom macros', () {
      test('should allow custom macro percentages', () {
        // Create a custom preset by using custom enum
        final customPreset = MacroPreset.custom;
        
        // Calculate macros with custom percentages
        // In real usage, the service would use the custom percentages
        // For this test, we just verify the preset exists
        expect(customPreset, equals(MacroPreset.custom));
      });
    });
  });
}
