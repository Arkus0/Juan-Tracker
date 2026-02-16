import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/coach_providers.dart';
import '../providers/summary_providers.dart';
import '../providers/weight_trend_providers.dart';
import '../services/adaptive_coach_service.dart' show CoachPlan, WeightGoal;
import '../services/day_summary_calculator.dart' show DaySummary;
import '../services/weight_trend_calculator.dart'
    show WeightPhase, WeightTrendResult;

// ============================================================================
// MODELO
// ============================================================================

enum NudgeType { warning, info, positive, reminder }

class CoachNudge {
  final String message;
  final NudgeType type;

  const CoachNudge({required this.message, required this.type});
}

// ============================================================================
// PROVIDER
// ============================================================================

/// Provider de nudges inteligentes del coach.
final coachNudgesProvider = Provider.autoDispose<List<CoachNudge>>((ref) {
  final summaryAsync = ref.watch(daySummaryProvider);
  final plan = ref.watch(coachPlanProvider);
  final isCheckInDue = ref.watch(isCheckInDueProvider);
  final weightTrendAsync = ref.watch(weightTrendProvider);

  final summary = summaryAsync.whenOrNull(data: (s) => s);
  final weightTrend = weightTrendAsync.whenOrNull(data: (t) => t);

  if (plan == null || summary == null || !summary.hasTargets) {
    return const [];
  }

  return generateCoachNudges(
    summary: summary,
    plan: plan,
    isCheckInDue: isCheckInDue,
    weightTrend: weightTrend,
    now: DateTime.now(),
  );
});

// ============================================================================
// LOGICA PURA
// ============================================================================

/// Genera nudges con reglas deterministas y maximo 2 items.
List<CoachNudge> generateCoachNudges({
  required DaySummary summary,
  required CoachPlan plan,
  required bool isCheckInDue,
  required WeightTrendResult? weightTrend,
  DateTime? now,
}) {
  if (!summary.hasTargets) return const [];

  final nudges = <CoachNudge>[];
  final targets = summary.targets;
  final consumed = summary.consumed;
  final progress = summary.progress;
  final hour = (now ?? DateTime.now()).hour;

  // 1) Check-in semanal pendiente (prioridad alta)
  if (isCheckInDue) {
    nudges.add(
      const CoachNudge(
        message: 'Tu check-in semanal está pendiente. Revisa tu progreso.',
        type: NudgeType.reminder,
      ),
    );
  }

  // 2) Deficit de proteina a partir de la tarde
  if (hour >= 15 && targets?.proteinTarget != null) {
    final proteinPct = progress.proteinPercent ?? 0;
    if (proteinPct < 0.60) {
      final remaining = (targets!.proteinTarget! - consumed.protein)
          .clamp(0, 999)
          .round();
      nudges.add(
        CoachNudge(
          message:
              'Llevas solo ${(proteinPct * 100).round()}% de proteína. '
              'Aún necesitas ~${remaining}g.',
          type: NudgeType.warning,
        ),
      );
    }
  }

  // 3) Exceso calorico significativo
  final kcalPct = progress.kcalPercent ?? 0;
  if (kcalPct > 1.20 && targets?.kcalTarget != null) {
    final excess = consumed.kcal - targets!.kcalTarget;
    nudges.add(
      CoachNudge(
        message:
            'Llevas +$excess kcal sobre tu objetivo. '
            'Considera una cena más ligera.',
        type: NudgeType.warning,
      ),
    );
  }

  // 4) Peso estancado (solo si el objetivo NO es mantenimiento)
  if (weightTrend != null &&
      weightTrend.phase == WeightPhase.maintaining &&
      weightTrend.daysInPhase > 14 &&
      plan.goal != WeightGoal.maintain) {
    nudges.add(
      CoachNudge(
        message:
            'Tu peso se ha estancado ${weightTrend.daysInPhase} días. '
            'Considera revisar tu plan en el check-in.',
        type: NudgeType.info,
      ),
    );
  }

  // 5) Refuerzo positivo
  if (hour >= 19 && kcalPct >= 0.85 && kcalPct <= 1.10 && nudges.isEmpty) {
    final proteinPct = progress.proteinPercent ?? 0;
    nudges.add(
      CoachNudge(
        message: proteinPct >= 0.80
            ? 'Gran día. Calorías y proteína dentro del objetivo.'
            : 'Buen trabajo. Calorías controladas hoy.',
        type: NudgeType.positive,
      ),
    );
  }

  // 6) Motivacion matutina
  if (hour < 12 && consumed.kcal == 0 && nudges.isEmpty) {
    nudges.add(
      const CoachNudge(
        message: 'Buenos días. Registra tu desayuno para mantener el tracking.',
        type: NudgeType.info,
      ),
    );
  }

  return nudges.take(2).toList();
}
