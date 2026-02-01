import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/goal_projection_model.dart';
import 'package:juan_tracker/diet/services/adaptive_coach_service.dart';
import 'package:juan_tracker/diet/services/weight_trend_calculator.dart';
import 'package:juan_tracker/diet/models/weighin_model.dart';

void main() {
  group('GoalProjection', () {
    group('ETA calculations', () {
      test('calculates days to goal for weight loss', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.5,
          dailyTrendRate: -0.1, // Losing 0.1 kg/day = 0.7 kg/week
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 14)),
          daysSinceStart: 14,
        );

        // 5 kg to lose at 0.1 kg/day = 50 days
        expect(projection.estimatedDaysToGoal, 50);
        expect(projection.isOnTrack, isTrue);
        expect(projection.goalReached, isFalse);
      });

      test('calculates days to goal for weight gain', () {
        final projection = GoalProjection(
          goalWeightKg: 80.0,
          currentTrendWeight: 75.0,
          latestWeight: 74.8,
          dailyTrendRate: 0.05, // Gaining 0.05 kg/day = 0.35 kg/week
          goal: WeightGoal.gain,
          targetWeeklyRateKg: 0.3,
          planStartDate: DateTime.now().subtract(const Duration(days: 30)),
          daysSinceStart: 30,
        );

        // 5 kg to gain at 0.05 kg/day = 100 days
        expect(projection.estimatedDaysToGoal, 100);
        expect(projection.isOnTrack, isTrue);
      });

      test('returns null ETA when moving wrong direction for loss', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.5,
          dailyTrendRate: 0.05, // Gaining instead of losing
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 7)),
          daysSinceStart: 7,
        );

        expect(projection.estimatedDaysToGoal, isNull);
        expect(projection.isOnTrack, isFalse);
      });

      test('returns null ETA when moving wrong direction for gain', () {
        final projection = GoalProjection(
          goalWeightKg: 80.0,
          currentTrendWeight: 75.0,
          latestWeight: 74.8,
          dailyTrendRate: -0.05, // Losing instead of gaining
          goal: WeightGoal.gain,
          targetWeeklyRateKg: 0.3,
          planStartDate: DateTime.now().subtract(const Duration(days: 7)),
          daysSinceStart: 7,
        );

        expect(projection.estimatedDaysToGoal, isNull);
        expect(projection.isOnTrack, isFalse);
      });

      test('returns 0 days when goal is reached', () {
        final projection = GoalProjection(
          goalWeightKg: 75.0,
          currentTrendWeight: 75.2, // Within 0.5 kg tolerance
          latestWeight: 75.0,
          dailyTrendRate: -0.05,
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 30)),
          daysSinceStart: 30,
        );

        expect(projection.goalReached, isTrue);
        expect(projection.estimatedDaysToGoal, 0);
      });

      test('returns null ETA when trend is zero', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.0,
          dailyTrendRate: 0.0,
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 7)),
          daysSinceStart: 7,
        );

        expect(projection.estimatedDaysToGoal, isNull);
      });

      test('caps ETA at 2 years (730 days)', () {
        final projection = GoalProjection(
          goalWeightKg: 60.0,
          currentTrendWeight: 100.0,
          latestWeight: 100.0,
          dailyTrendRate: -0.01, // Very slow: 40 kg / 0.01 = 4000 days
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 7)),
          daysSinceStart: 7,
        );

        expect(projection.estimatedDaysToGoal, isNull);
      });
    });

    group('progress calculations', () {
      test('calculates progress percentage correctly', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 72.5, // Halfway from 75 to 70
          latestWeight: 72.5,
          dailyTrendRate: -0.1,
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 25)),
          daysSinceStart: 25,
        );

        // Started at 75 (72.5 - (-0.1 * 25) = 72.5 + 2.5 = 75)
        // Target is 70, current is 72.5
        // Progress = (75 - 72.5) / (75 - 70) = 2.5 / 5 = 50%
        expect(projection.progressPercentage, closeTo(50.0, 1.0));
      });

      test('weekly rate calculation is correct', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.0,
          dailyTrendRate: -0.0714, // ~0.5 kg/week
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 7)),
          daysSinceStart: 7,
        );

        expect(projection.currentWeeklyRate, closeTo(-0.5, 0.01));
      });

      test('pace ratio is 1.0 when on target', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.0,
          dailyTrendRate: -0.0714, // 0.5 kg/week
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 7)),
          daysSinceStart: 7,
        );

        expect(projection.paceRatio, closeTo(1.0, 0.05));
      });

      test('pace ratio is less than 1 when slower than target', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.0,
          dailyTrendRate: -0.03, // ~0.21 kg/week (slower than 0.5)
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 7)),
          daysSinceStart: 7,
        );

        expect(projection.paceRatio, lessThan(1.0));
      });
    });

    group('weight prediction', () {
      test('predicts weight correctly at future dates', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.5,
          dailyTrendRate: -0.1, // Losing 0.1 kg/day
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 14)),
          daysSinceStart: 14,
        );

        // After 10 days: 75 - (0.1 * 10) = 74 kg
        expect(projection.predictWeightInDays(10), closeTo(74.0, 0.01));

        // After 30 days: 75 - (0.1 * 30) = 72 kg
        expect(projection.predictWeightInDays(30), closeTo(72.0, 0.01));
      });

      test('returns current weight for 0 or negative days', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.5,
          dailyTrendRate: -0.1,
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 14)),
          daysSinceStart: 14,
        );

        expect(projection.predictWeightInDays(0), 75.0);
        expect(projection.predictWeightInDays(-5), 75.0);
      });
    });

    group('goal chart points generation', () {
      test('generates goal line points', () {
        final projection = GoalProjection(
          goalWeightKg: 70.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.5,
          dailyTrendRate: -0.1,
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 14)),
          daysSinceStart: 14,
        );

        final points = projection.generateGoalLine(maxDays: 30);

        expect(points, isNotEmpty);
        expect(points.first.projectedWeight, closeTo(75.0, 0.1));
        expect(points.every((p) => p.goalWeight == 70.0), isTrue);
      });
    });

    group('UI messages', () {
      test('shows achievement message when goal reached', () {
        final projection = GoalProjection(
          goalWeightKg: 75.0,
          currentTrendWeight: 75.2,
          latestWeight: 75.0,
          dailyTrendRate: -0.05,
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 30)),
          daysSinceStart: 30,
        );

        expect(projection.progressMessage, contains('Meta alcanzada'));
      });

      test('shows days for short ETA', () {
        final projection = GoalProjection(
          goalWeightKg: 74.0, // Need more distance to not trigger goalReached
          currentTrendWeight: 75.0,
          latestWeight: 75.0,
          dailyTrendRate: -0.2, // 5 days to goal (1 kg at 0.2 kg/day = 5 days)
          goal: WeightGoal.lose,
          targetWeeklyRateKg: 0.5,
          planStartDate: DateTime.now().subtract(const Duration(days: 7)),
          daysSinceStart: 7,
        );

        expect(projection.goalReached, isFalse);
        expect(projection.progressMessage, contains('días'));
      });

      test('maintain goal shows stable message', () {
        final projection = GoalProjection(
          goalWeightKg: 75.0,
          currentTrendWeight: 75.0,
          latestWeight: 75.0,
          dailyTrendRate: 0.01,
          goal: WeightGoal.maintain,
          targetWeeklyRateKg: 0.0,
          planStartDate: DateTime.now().subtract(const Duration(days: 7)),
          daysSinceStart: 7,
        );

        expect(projection.isOnTrack, isTrue); // Maintain is always on track
      });
    });
  });

  group('GoalProjectionCalculator', () {
    test('creates projection from CoachPlan and WeightTrendResult', () {
      const calculator = GoalProjectionCalculator();

      final plan = CoachPlan(
        id: 'test-plan',
        goal: WeightGoal.lose,
        weeklyRateKg: 0.5,
        initialTdeeEstimate: 2000,
        startingWeight: 80.0,
        startDate: DateTime.now().subtract(const Duration(days: 14)),
      );

      // Create weighIns for trend calculation
      final weighIns = List.generate(10, (i) {
        return WeighInModel(
          id: 'wi-$i',
          dateTime: DateTime.now().subtract(Duration(days: 10 - i)),
          weightKg: 78.0 - (i * 0.1), // Gradual loss
        );
      });

      const trendCalculator = WeightTrendCalculator();
      final trend = trendCalculator.calculate(weighIns);

      final projection = calculator.calculate(plan: plan, trend: trend);

      expect(projection, isNotNull);
      expect(projection!.goal, WeightGoal.lose);
      expect(projection.currentTrendWeight, closeTo(trend.trendWeight, 0.1));
      expect(projection.dailyTrendRate, closeTo(trend.hwTrend, 0.01));
    });

    test('returns null when plan is null', () {
      const calculator = GoalProjectionCalculator();

      // Create minimal trend
      final weighIns = [
        WeighInModel(
          id: 'wi-1',
          dateTime: DateTime.now().subtract(const Duration(days: 7)),
          weightKg: 75.0,
        ),
        WeighInModel(
          id: 'wi-2',
          dateTime: DateTime.now(),
          weightKg: 74.5,
        ),
      ];
      const trendCalculator = WeightTrendCalculator();
      final trend = trendCalculator.calculate(weighIns);

      final projection = calculator.calculate(plan: null, trend: trend);
      expect(projection, isNull);
    });

    test('returns null when trend is null', () {
      const calculator = GoalProjectionCalculator();

      final plan = CoachPlan(
        id: 'test-plan',
        goal: WeightGoal.lose,
        weeklyRateKg: 0.5,
        initialTdeeEstimate: 2000,
        startingWeight: 80.0,
        startDate: DateTime.now(),
      );

      final projection = calculator.calculate(plan: plan, trend: null);
      expect(projection, isNull);
    });

    test('calculates goal weight based on goal type', () {
      const calculator = GoalProjectionCalculator();

      // Create weighIns for trend
      final weighIns = [
        WeighInModel(
          id: 'wi-1',
          dateTime: DateTime.now().subtract(const Duration(days: 7)),
          weightKg: 75.0,
        ),
        WeighInModel(
          id: 'wi-2',
          dateTime: DateTime.now(),
          weightKg: 74.5,
        ),
      ];
      const trendCalculator = WeightTrendCalculator();
      final trend = trendCalculator.calculate(weighIns);

      // Test loss goal
      final lossPlan = CoachPlan(
        id: 'test-loss',
        goal: WeightGoal.lose,
        weeklyRateKg: 0.5,
        initialTdeeEstimate: 2000,
        startingWeight: 80.0,
        startDate: DateTime.now(),
      );
      final lossProjection = calculator.calculate(plan: lossPlan, trend: trend);
      expect(lossProjection!.goalWeightKg, lessThan(80.0));

      // Test gain goal
      final gainPlan = CoachPlan(
        id: 'test-gain',
        goal: WeightGoal.gain,
        weeklyRateKg: 0.3,
        initialTdeeEstimate: 2500,
        startingWeight: 65.0,
        startDate: DateTime.now(),
      );
      final gainProjection = calculator.calculate(plan: gainPlan, trend: trend);
      expect(gainProjection!.goalWeightKg, greaterThan(65.0));

      // Test maintain goal
      final maintainPlan = CoachPlan(
        id: 'test-maintain',
        goal: WeightGoal.maintain,
        weeklyRateKg: 0.0,
        initialTdeeEstimate: 2200,
        startingWeight: 72.0,
        startDate: DateTime.now(),
      );
      final maintainProjection =
          calculator.calculate(plan: maintainPlan, trend: trend);
      expect(maintainProjection!.goalWeightKg, 72.0); // Same as starting
    });
  });
}
