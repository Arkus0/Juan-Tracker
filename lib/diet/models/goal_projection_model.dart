/// Modelo para proyección de peso hacia objetivo (Goal Forecasting)
///
/// Combina datos de CoachPlan (objetivo del usuario) con WeightTrendResult
/// (tendencia actual) para calcular ETA y mostrar línea de objetivo.
library;

import '../services/weight_trend_calculator.dart';
import '../services/adaptive_coach_service.dart';

/// Proyección de peso hacia el objetivo del usuario
class GoalProjection {
  /// Peso objetivo del usuario (kg)
  final double goalWeightKg;

  /// Peso tendencia actual (kg) - suavizado
  final double currentTrendWeight;

  /// Peso más reciente registrado (kg)
  final double latestWeight;

  /// Trend diario actual (kg/día) - positivo = ganando, negativo = perdiendo
  final double dailyTrendRate;

  /// Objetivo del usuario
  final WeightGoal goal;

  /// Ritmo semanal objetivo (kg/semana) del CoachPlan
  final double targetWeeklyRateKg;

  /// Fecha de inicio del plan
  final DateTime planStartDate;

  /// Días transcurridos desde inicio del plan
  final int daysSinceStart;

  const GoalProjection({
    required this.goalWeightKg,
    required this.currentTrendWeight,
    required this.latestWeight,
    required this.dailyTrendRate,
    required this.goal,
    required this.targetWeeklyRateKg,
    required this.planStartDate,
    required this.daysSinceStart,
  });

  // ============================================================================
  // CÁLCULOS DE ETA
  // ============================================================================

  /// Diferencia entre peso actual y objetivo (kg)
  /// Positivo = por encima del objetivo
  /// Negativo = por debajo del objetivo
  double get weightDelta => currentTrendWeight - goalWeightKg;

  /// ¿Se está moviendo en la dirección correcta?
  bool get isOnTrack {
    if (goal == WeightGoal.maintain) return true;
    if (goal == WeightGoal.lose) return dailyTrendRate < 0;
    if (goal == WeightGoal.gain) return dailyTrendRate > 0;
    return false;
  }

  /// ¿Ya alcanzó el objetivo?
  bool get goalReached {
    const tolerance = 0.5; // ±0.5 kg de tolerancia
    return weightDelta.abs() <= tolerance;
  }

  /// Días estimados para alcanzar el objetivo basado en trend actual
  /// Retorna null si:
  /// - No se está moviendo hacia el objetivo
  /// - Ya se alcanzó el objetivo
  /// - El trend es cero
  int? get estimatedDaysToGoal {
    if (goalReached) return 0;
    if (dailyTrendRate.abs() < 0.001) return null; // Trend ~0

    // Para perder peso: delta > 0, trend debe ser < 0
    // Para ganar peso: delta < 0, trend debe ser > 0
    final daysNeeded = (weightDelta / dailyTrendRate).abs();

    // Validar dirección correcta
    if (goal == WeightGoal.lose && dailyTrendRate >= 0) return null;
    if (goal == WeightGoal.gain && dailyTrendRate <= 0) return null;

    // Limitar a máximo 2 años (para evitar números absurdos)
    if (daysNeeded > 730) return null;

    return daysNeeded.round();
  }

  /// Fecha estimada para alcanzar el objetivo
  DateTime? get estimatedGoalDate {
    final days = estimatedDaysToGoal;
    if (days == null) return null;
    return DateTime.now().add(Duration(days: days));
  }

  /// Peso proyectado para una fecha específica (basado en trend actual)
  double predictWeightAt(DateTime date) {
    final daysFromNow = date.difference(DateTime.now()).inDays;
    if (daysFromNow <= 0) return currentTrendWeight;
    return currentTrendWeight + (dailyTrendRate * daysFromNow);
  }

  /// Peso proyectado en N días
  double predictWeightInDays(int days) {
    if (days <= 0) return currentTrendWeight;
    return currentTrendWeight + (dailyTrendRate * days);
  }

  // ============================================================================
  // PROGRESO
  // ============================================================================

  /// Peso inicial del plan
  double get startWeight {
    // Calcular peso inicial basado en trend y días transcurridos
    // startWeight = currentTrend - (dailyRate * days)
    return currentTrendWeight - (dailyTrendRate * daysSinceStart);
  }

  /// Cambio total desde inicio (kg)
  double get totalWeightChange => currentTrendWeight - startWeight;

  /// Cambio objetivo total (kg) desde peso inicial
  double get targetTotalChange => goalWeightKg - startWeight;

  /// Porcentaje de progreso hacia el objetivo (0-100)
  /// Puede ser >100 si superó la meta
  double get progressPercentage {
    if (targetTotalChange.abs() < 0.1) return 100.0; // Ya en objetivo
    final progress = (totalWeightChange / targetTotalChange) * 100;
    return progress.clamp(0.0, 150.0); // Permitir hasta 150% para over-achievers
  }

  /// Ritmo semanal actual (kg/semana)
  double get currentWeeklyRate => dailyTrendRate * 7;

  /// Ratio entre ritmo actual y objetivo
  /// 1.0 = exactamente en target
  /// <1.0 = más lento que objetivo
  /// >1.0 = más rápido que objetivo
  double get paceRatio {
    if (targetWeeklyRateKg.abs() < 0.01) return 1.0;
    return (currentWeeklyRate.abs() / targetWeeklyRateKg.abs()).clamp(0.0, 3.0);
  }

  // ============================================================================
  // MENSAJES PARA UI
  // ============================================================================

  /// Mensaje corto de progreso
  String get progressMessage {
    if (goalReached) {
      return '¡Meta alcanzada! 🎉';
    }

    final days = estimatedDaysToGoal;
    if (days == null) {
      if (!isOnTrack) {
        return goal == WeightGoal.lose
            ? 'Ajusta para empezar a perder'
            : 'Ajusta para empezar a ganar';
      }
      return 'Calculando proyección...';
    }

    if (days == 0) return '¡Meta alcanzada! 🎉';

    if (days < 7) return '~$days días para tu meta';
    if (days < 30) {
      final weeks = (days / 7).round();
      return '~$weeks ${weeks == 1 ? 'semana' : 'semanas'} para tu meta';
    }
    if (days < 365) {
      final months = (days / 30).round();
      return '~$months ${months == 1 ? 'mes' : 'meses'} para tu meta';
    }
    return 'Meta a largo plazo';
  }

  /// Mensaje de ritmo actual vs objetivo
  String get paceMessage {
    if (goal == WeightGoal.maintain) {
      return currentWeeklyRate.abs() < 0.1
          ? 'Peso estable ✓'
          : 'Fluctuación: ${_formatWeeklyRate(currentWeeklyRate)}';
    }

    final currentRateStr = _formatWeeklyRate(currentWeeklyRate);
    final targetRateStr = _formatWeeklyRate(
      goal == WeightGoal.lose ? -targetWeeklyRateKg : targetWeeklyRateKg,
    );

    if (paceRatio < 0.5) {
      return 'Ritmo: $currentRateStr (objetivo: $targetRateStr)';
    } else if (paceRatio > 1.2) {
      return 'Ritmo: $currentRateStr — más rápido que objetivo';
    } else {
      return 'Ritmo: $currentRateStr — en objetivo ✓';
    }
  }

  String _formatWeeklyRate(double rate) {
    final sign = rate >= 0 ? '+' : '';
    return '$sign${rate.toStringAsFixed(2)} kg/sem';
  }

  // ============================================================================
  // DATOS PARA GRÁFICOS
  // ============================================================================

  /// Genera puntos de la línea de objetivo para el chart
  /// Retorna lista de (día, peso) desde hoy hasta goalDate o 90 días
  List<GoalChartPoint> generateGoalLine({int maxDays = 90}) {
    final points = <GoalChartPoint>[];
    final today = DateTime.now();
    final endDays = estimatedDaysToGoal ?? maxDays;
    final daysToPlot = endDays.clamp(7, maxDays);

    // Punto inicial: hoy con trend weight actual
    points.add(GoalChartPoint(
      date: today,
      projectedWeight: currentTrendWeight,
      goalWeight: goalWeightKg,
      isGoalReached: goalReached,
    ));

    // Puntos intermedios (cada 7 días)
    for (int day = 7; day <= daysToPlot; day += 7) {
      final date = today.add(Duration(days: day));
      final projected = predictWeightInDays(day);
      
      // No proyectar más allá del objetivo
      final double clampedProjected = goal == WeightGoal.lose
          ? projected.clamp(goalWeightKg, double.infinity)
          : goal == WeightGoal.gain
              ? projected.clamp(0.0, goalWeightKg)
              : projected;

      points.add(GoalChartPoint(
        date: date,
        projectedWeight: clampedProjected,
        goalWeight: goalWeightKg,
        isGoalReached: (clampedProjected - goalWeightKg).abs() < 0.5,
      ));
    }

    return points;
  }

  @override
  String toString() => 'GoalProjection('
      'goal: $goalWeightKg kg, '
      'current: ${currentTrendWeight.toStringAsFixed(1)} kg, '
      'eta: ${estimatedDaysToGoal ?? "?"} days, '
      'progress: ${progressPercentage.toStringAsFixed(0)}%'
      ')';
}

/// Punto de datos para gráfico de proyección
class GoalChartPoint {
  final DateTime date;
  final double projectedWeight;
  final double goalWeight;
  final bool isGoalReached;

  const GoalChartPoint({
    required this.date,
    required this.projectedWeight,
    required this.goalWeight,
    required this.isGoalReached,
  });
}

/// Factory para crear GoalProjection desde CoachPlan y WeightTrendResult
class GoalProjectionCalculator {
  const GoalProjectionCalculator();

  /// Calcula la proyección de objetivo
  /// Retorna null si no hay plan o datos de tendencia
  GoalProjection? calculate({
    required CoachPlan? plan,
    required WeightTrendResult? trend,
  }) {
    if (plan == null || trend == null) return null;

    // El goal weight se deriva del plan
    // Para pérdida: startWeight - (rate * tiempo_esperado)
    // Para ganancia: startWeight + (rate * tiempo_esperado)
    // Para mantenimiento: startWeight
    final goalWeight = _calculateGoalWeight(plan, trend);

    return GoalProjection(
      goalWeightKg: goalWeight,
      currentTrendWeight: trend.trendWeight,
      latestWeight: trend.latestWeight,
      dailyTrendRate: trend.hwTrend, // Holt-Winters trend kg/día
      goal: plan.goal,
      targetWeeklyRateKg: plan.weeklyRateKg,
      planStartDate: plan.startDate,
      daysSinceStart: DateTime.now().difference(plan.startDate).inDays,
    );
  }

  /// Calcula el peso objetivo basado en el plan
  double _calculateGoalWeight(CoachPlan plan, WeightTrendResult trend) {
    switch (plan.goal) {
      case WeightGoal.maintain:
        // Para mantenimiento, el objetivo es el peso inicial
        return plan.startingWeight;

      case WeightGoal.lose:
        // Objetivo = peso inicial - X kg
        // Por ahora, usamos un objetivo razonable basado en el ritmo
        // Ejemplo: Si pierdes 0.5 kg/sem, objetivo a 12 semanas = -6kg
        // Pero si el usuario no definió un peso objetivo específico,
        // usamos el peso actual menos un delta razonable (ej: -5 kg)
        final defaultGoal = plan.startingWeight - 5.0;
        return defaultGoal.clamp(40.0, 200.0);

      case WeightGoal.gain:
        // Similar para ganancia
        final defaultGoal = plan.startingWeight + 5.0;
        return defaultGoal.clamp(40.0, 200.0);
    }
  }
}
