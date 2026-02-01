/// Providers para proyección de peso hacia objetivo (Goal Forecasting)
///
/// Combina CoachPlan (objetivo del usuario) con WeightTrendResult (tendencia actual)
/// para proporcionar proyecciones de ETA y línea de objetivo estilo Libra.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal_projection_model.dart';
import 'coach_providers.dart';
import 'weight_trend_providers.dart';

// ============================================================================
// CALCULATOR
// ============================================================================

/// Provider del calculador de proyecciones (singleton, sin estado)
final goalProjectionCalculatorProvider = Provider<GoalProjectionCalculator>(
  (_) => const GoalProjectionCalculator(),
);

// ============================================================================
// GOAL PROJECTION PROVIDER
// ============================================================================

/// Provider principal de proyección de objetivo
///
/// Combina:
/// - CoachPlan: objetivo del usuario (lose/gain/maintain + ritmo)
/// - WeightTrendResult: tendencia actual (EMA, Holt-Winters trend)
///
/// Retorna null si:
/// - No hay plan activo
/// - No hay datos suficientes de peso
final goalProjectionProvider = Provider<AsyncValue<GoalProjection?>>((ref) {
  // Watch del plan de coach
  final plan = ref.watch(coachPlanProvider);

  // Watch de la tendencia de peso
  final trendAsync = ref.watch(weightTrendProvider);

  return trendAsync.when(
    data: (trend) {
      if (plan == null || trend == null) {
        return const AsyncValue.data(null);
      }

      try {
        final calculator = ref.watch(goalProjectionCalculatorProvider);
        final projection = calculator.calculate(plan: plan, trend: trend);
        return AsyncValue.data(projection);
      } catch (e, st) {
        return AsyncValue.error(e, st);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// ============================================================================
// DERIVED PROVIDERS (para UI específica)
// ============================================================================

/// Provider del mensaje de progreso (para badges/cards)
final goalProgressMessageProvider = Provider<String?>((ref) {
  final projectionAsync = ref.watch(goalProjectionProvider);
  return projectionAsync.whenOrNull(
    data: (projection) => projection?.progressMessage,
  );
});

/// Provider de ETA en días (para cálculos)
final goalEtaDaysProvider = Provider<int?>((ref) {
  final projectionAsync = ref.watch(goalProjectionProvider);
  return projectionAsync.whenOrNull(
    data: (projection) => projection?.estimatedDaysToGoal,
  );
});

/// Provider de si está on track
final isOnTrackProvider = Provider<bool?>((ref) {
  final projectionAsync = ref.watch(goalProjectionProvider);
  return projectionAsync.whenOrNull(
    data: (projection) => projection?.isOnTrack,
  );
});

/// Provider del porcentaje de progreso (0-100+)
final goalProgressPercentageProvider = Provider<double?>((ref) {
  final projectionAsync = ref.watch(goalProjectionProvider);
  return projectionAsync.whenOrNull(
    data: (projection) => projection?.progressPercentage,
  );
});

/// Provider de puntos para la línea de objetivo en el chart
final goalChartLineProvider = Provider<List<GoalChartPoint>?>((ref) {
  final projectionAsync = ref.watch(goalProjectionProvider);
  return projectionAsync.whenOrNull(
    data: (projection) => projection?.generateGoalLine(maxDays: 90),
  );
});

// ============================================================================
// GOAL WEIGHT PROVIDER (configurable por usuario)
// ============================================================================

/// Notifier para el peso objetivo configurable por el usuario
class CustomGoalWeightNotifier extends Notifier<double?> {
  @override
  double? build() => null;

  void setGoalWeight(double? weight) => state = weight;
  void clear() => state = null;
}

/// Provider del peso objetivo configurable
///
/// Por defecto usa el valor calculado de CoachPlan, pero puede ser
/// sobreescrito por el usuario para mayor precisión.
final customGoalWeightProvider = NotifierProvider<CustomGoalWeightNotifier, double?>(
  CustomGoalWeightNotifier.new,
);

/// Provider del peso objetivo efectivo (custom o calculado)
final effectiveGoalWeightProvider = Provider<double?>((ref) {
  final custom = ref.watch(customGoalWeightProvider);
  if (custom != null) return custom;

  final projectionAsync = ref.watch(goalProjectionProvider);
  return projectionAsync.whenOrNull(
    data: (projection) => projection?.goalWeightKg,
  );
});
