// Providers para visualización de adherencia en el calendario
//
// Computa el estado de adherencia por día para el mes visible,
// permitiendo colorear los dots del calendario según cercanía
// al objetivo calórico.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../providers/coach_providers.dart';
import '../providers/summary_providers.dart' show daySummaryCalculatorProvider;

// ============================================================================
// MODELO
// ============================================================================

/// Estado de adherencia para un día individual
enum DayAdherenceStatus {
  /// Sin datos (sin entries o sin target)
  noData,

  /// Dentro del ±10% del target (excelente)
  onTarget,

  /// Entre 10-25% de desvío (aceptable)
  close,

  /// >25% de desvío (fuera de objetivo)
  offTarget,
}

/// Datos de adherencia para un mes completo
class MonthAdherenceData {
  /// Estado de adherencia por día (clave: DateTime normalizada)
  final Map<DateTime, DayAdherenceStatus> dayStatus;

  /// Target kcal usado para el cálculo
  final int? targetKcal;

  const MonthAdherenceData({
    required this.dayStatus,
    this.targetKcal,
  });

  static const empty = MonthAdherenceData(dayStatus: {});

  /// Color del dot según el estado de adherencia
  static Color colorForStatus(DayAdherenceStatus status, ColorScheme cs) {
    return switch (status) {
      DayAdherenceStatus.noData => cs.tertiary,
      DayAdherenceStatus.onTarget => Colors.green,
      DayAdherenceStatus.close => Colors.amber.shade600,
      DayAdherenceStatus.offTarget => Colors.red.shade400,
    };
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

/// Provider que calcula la adherencia para un mes dado.
///
/// Retorna un mapa de días con su estado de adherencia basado
/// en la cercanía al objetivo calórico del CoachPlan.
final monthAdherenceProvider = FutureProvider.family<MonthAdherenceData, DateTime>(
  (ref, month) async {
    final diaryRepo = ref.watch(diaryRepositoryProvider);
    final coachPlan = ref.watch(coachPlanProvider);

    // Si no hay coach plan, no podemos calcular adherencia
    if (coachPlan == null) {
      return MonthAdherenceData.empty;
    }

    // Calcular target kcal
    final calculator = ref.watch(daySummaryCalculatorProvider);
    final targetKcal = calculator.calculateTDEEFromCoachPlan(coachPlan).round();

    if (targetKcal <= 0) {
      return MonthAdherenceData.empty;
    }

    // Rango del mes
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final today = DateTime.now();

    // Obtener todas las entradas del mes
    final entries = await diaryRepo.getByDateRange(firstDay, lastDay);

    // Agrupar kcal por día
    final kcalByDay = <DateTime, int>{};
    for (final entry in entries) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      kcalByDay[day] = (kcalByDay[day] ?? 0) + entry.kcal;
    }

    // Calcular estado para cada día del mes
    final dayStatus = <DateTime, DayAdherenceStatus>{};

    for (var d = firstDay;
        !d.isAfter(lastDay) && !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      final day = DateTime(d.year, d.month, d.day);
      final kcal = kcalByDay[day];

      if (kcal == null || kcal == 0) {
        // No marcar días sin datos
        continue;
      }

      final deviation = (kcal - targetKcal).abs();
      final deviationPercent = deviation / targetKcal;

      if (deviationPercent <= 0.10) {
        dayStatus[day] = DayAdherenceStatus.onTarget;
      } else if (deviationPercent <= 0.25) {
        dayStatus[day] = DayAdherenceStatus.close;
      } else {
        dayStatus[day] = DayAdherenceStatus.offTarget;
      }
    }

    return MonthAdherenceData(
      dayStatus: dayStatus,
      targetKcal: targetKcal,
    );
  },
);
