import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/diary_entry_model.dart';
import 'package:juan_tracker/diet/models/targets_model.dart';
import 'package:juan_tracker/diet/providers/coach_nudge_providers.dart';
import 'package:juan_tracker/diet/services/adaptive_coach_service.dart';
import 'package:juan_tracker/diet/services/day_summary_calculator.dart';
import 'package:juan_tracker/diet/services/weight_trend_calculator.dart';

DaySummary _buildSummary({
  required int kcalConsumed,
  required double proteinConsumed,
  int kcalTarget = 2200,
  double proteinTarget = 150,
}) {
  final targets = TargetsModel(
    id: 't1',
    validFrom: DateTime(2026, 1, 1),
    kcalTarget: kcalTarget,
    proteinTarget: proteinTarget,
    carbsTarget: 200,
    fatTarget: 70,
  );

  final consumed = DailyTotals(
    kcal: kcalConsumed,
    protein: proteinConsumed,
    carbs: 150,
    fat: 50,
    byMeal: const {},
  );

  final progress = TargetsProgress(
    targets: targets,
    kcalConsumed: consumed.kcal,
    proteinConsumed: consumed.protein,
    carbsConsumed: consumed.carbs,
    fatConsumed: consumed.fat,
  );

  return DaySummary(
    date: DateTime(2026, 2, 10),
    consumed: consumed,
    targets: targets,
    progress: progress,
  );
}

CoachPlan _buildPlan({required WeightGoal goal}) {
  return CoachPlan(
    id: 'plan_1',
    goal: goal,
    weeklyRateKg: goal == WeightGoal.maintain ? 0 : 0.4,
    initialTdeeEstimate: 2300,
    startingWeight: 82,
    startDate: DateTime(2026, 1, 1),
  );
}

WeightTrendResult _buildMaintainingTrend({int daysInPhase = 21}) {
  return WeightTrendResult(
    emaWeight: 80.0,
    emaHistory: const [80.2, 80.1, 80.0],
    hwLevel: 80.0,
    hwTrend: 0.0,
    hwPrediction7d: 80.0,
    hwPrediction30d: 80.0,
    kalmanWeight: 80.0,
    kalmanConfidence: 0.8,
    regressionSlope: 0.0,
    regressionIntercept: 80.0,
    regressionR2: 0.9,
    phase: WeightPhase.maintaining,
    daysInPhase: daysInPhase,
    weeklyRate: 0.0,
    latestWeight: 80.1,
    entries: const [],
  );
}

void main() {
  group('generateCoachNudges', () {
    test(
      'includes plateau nudge when trend is maintaining and goal is not maintain',
      () {
        final nudges = generateCoachNudges(
          summary: _buildSummary(kcalConsumed: 2000, proteinConsumed: 130),
          plan: _buildPlan(goal: WeightGoal.lose),
          isCheckInDue: false,
          weightTrend: _buildMaintainingTrend(daysInPhase: 18),
          now: DateTime(2026, 2, 10, 16),
        );

        expect(nudges.any((n) => n.message.contains('estancado')), isTrue);
      },
    );

    test('does not include plateau nudge when goal is maintain', () {
      final nudges = generateCoachNudges(
        summary: _buildSummary(kcalConsumed: 2000, proteinConsumed: 130),
        plan: _buildPlan(goal: WeightGoal.maintain),
        isCheckInDue: false,
        weightTrend: _buildMaintainingTrend(daysInPhase: 25),
        now: DateTime(2026, 2, 10, 16),
      );

      expect(nudges.any((n) => n.message.contains('estancado')), isFalse);
    });

    test('returns at most two nudges to avoid saturation', () {
      final nudges = generateCoachNudges(
        summary: _buildSummary(kcalConsumed: 3000, proteinConsumed: 20),
        plan: _buildPlan(goal: WeightGoal.lose),
        isCheckInDue: true,
        weightTrend: _buildMaintainingTrend(daysInPhase: 30),
        now: DateTime(2026, 2, 10, 18),
      );

      expect(nudges.length, lessThanOrEqualTo(2));
    });

    test(
      'shows morning tracking nudge when day has no intake and no high-priority nudges',
      () {
        final nudges = generateCoachNudges(
          summary: _buildSummary(kcalConsumed: 0, proteinConsumed: 0),
          plan: _buildPlan(goal: WeightGoal.lose),
          isCheckInDue: false,
          weightTrend: null,
          now: DateTime(2026, 2, 10, 9),
        );

        expect(nudges, isNotEmpty);
        expect(nudges.first.message.toLowerCase().contains('desayuno'), isTrue);
      },
    );
  });
}
