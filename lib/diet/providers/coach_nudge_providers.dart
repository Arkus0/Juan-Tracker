import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/coach_providers.dart';
import '../providers/summary_providers.dart';
import '../providers/weight_trend_providers.dart';
import '../services/adaptive_coach_service.dart' show WeightGoal;
import '../services/weight_trend_calculator.dart' show WeightPhase;

// ============================================================================
// MODELO
// ============================================================================

/// Tipo de nudge para determinar estilo visual
enum NudgeType {
  /// Alerta importante (rojo/amber)
  warning,

  /// Información neutral (azul)
  info,

  /// Refuerzo positivo (verde)
  positive,

  /// Recordatorio suave (gris/morado)
  reminder,
}

/// Un nudge individual del coach
class CoachNudge {
  final String emoji;
  final String message;
  final NudgeType type;

  const CoachNudge({
    required this.emoji,
    required this.message,
    required this.type,
  });
}

// ============================================================================
// PROVIDER
// ============================================================================

/// Genera nudges inteligentes basados en el estado actual del día,
/// tendencia de peso, y adherencia.
///
/// Prioriza máximo 2 nudges para no saturar.
final coachNudgesProvider = Provider.autoDispose<List<CoachNudge>>((ref) {
  final summaryAsync = ref.watch(daySummaryProvider);
  final plan = ref.watch(coachPlanProvider);
  final isCheckInDue = ref.watch(isCheckInDueProvider);
  final weightTrendAsync = ref.watch(weightTrendProvider);

  final nudges = <CoachNudge>[];

  // Sin plan de coach, no hay nudges
  if (plan == null) return nudges;

  final summary = summaryAsync.whenOrNull(data: (s) => s);
  if (summary == null || !summary.hasTargets) return nudges;

  final targets = summary.targets;
  final consumed = summary.consumed;
  final progress = summary.progress;
  final hour = DateTime.now().hour;

  // ──────────────────────────────────────────────────
  // 1. Check-in semanal pendiente (prioridad alta)
  // ──────────────────────────────────────────────────
  if (isCheckInDue) {
    nudges.add(const CoachNudge(
      emoji: '📊',
      message: 'Tu check-in semanal está pendiente. ¡Revisa tu progreso!',
      type: NudgeType.reminder,
    ));
  }

  // ──────────────────────────────────────────────────
  // 2. Déficit de proteína (si es tarde y < 60% del target)
  // ──────────────────────────────────────────────────
  if (hour >= 15 && targets?.proteinTarget != null) {
    final proteinPct = progress.proteinPercent ?? 0;
    if (proteinPct < 0.60) {
      final remaining =
          (targets!.proteinTarget! - consumed.protein).clamp(0, 999).round();
      nudges.add(CoachNudge(
        emoji: '🥩',
        message: 'Llevas solo ${(proteinPct * 100).round()}% de proteína. '
            'Aún necesitas ~${remaining}g.',
        type: NudgeType.warning,
      ));
    }
  }

  // ──────────────────────────────────────────────────
  // 3. Exceso calórico significativo (>120% del target)
  // ──────────────────────────────────────────────────
  final kcalPct = progress.kcalPercent ?? 0;
  if (kcalPct > 1.20 && targets?.kcalTarget != null) {
    final excess = consumed.kcal - targets!.kcalTarget;
    nudges.add(CoachNudge(
      emoji: '⚠️',
      message: 'Llevas +$excess kcal sobre tu objetivo. '
          'Considera una cena más ligera.',
      type: NudgeType.warning,
    ));
  }

  // ──────────────────────────────────────────────────
  // 4. Peso estancado (plateau > 14 días)
  // ──────────────────────────────────────────────────
  weightTrendAsync.whenData((trend) {
    if (trend != null &&
        trend.phase == WeightPhase.maintaining &&
        trend.daysInPhase > 14 &&
        plan.goal != WeightGoal.maintain) {
      nudges.add(CoachNudge(
        emoji: '📉',
        message: 'Tu peso se ha estancado ${trend.daysInPhase} días. '
            'Considera revisar tu plan en el check-in.',
        type: NudgeType.info,
      ));
    }
  });

  // ──────────────────────────────────────────────────
  // 5. Refuerzo positivo: buen día
  // ──────────────────────────────────────────────────
  if (hour >= 19 &&
      kcalPct >= 0.85 &&
      kcalPct <= 1.10 &&
      nudges.isEmpty) {
    final proteinPct = progress.proteinPercent ?? 0;
    if (proteinPct >= 0.80) {
      nudges.add(const CoachNudge(
        emoji: '🎯',
        message: '¡Gran día! Calorías y proteína dentro del objetivo.',
        type: NudgeType.positive,
      ));
    } else {
      nudges.add(const CoachNudge(
        emoji: '✅',
        message: '¡Buen trabajo! Calorías controladas hoy.',
        type: NudgeType.positive,
      ));
    }
  }

  // ──────────────────────────────────────────────────
  // 6. Motivación matutina (sin excesos, buen momento)
  // ──────────────────────────────────────────────────
  if (hour < 12 &&
      consumed.kcal == 0 &&
      nudges.isEmpty) {
    nudges.add(const CoachNudge(
      emoji: '☀️',
      message: '¡Buenos días! Registra tu desayuno para mantener el tracking.',
      type: NudgeType.info,
    ));
  }

  // Limitar a 2 nudges máximo para no saturar
  return nudges.take(2).toList();
});
