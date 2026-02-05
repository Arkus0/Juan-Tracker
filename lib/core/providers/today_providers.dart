import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/diet/providers/summary_providers.dart';
import 'package:juan_tracker/training/providers/training_provider.dart';

/// 🎯 FASE 4: Resumen unificado de "HOY" combinando nutrición y entrenamiento
///
/// Este provider combina:
/// - Sugerencia de entrenamiento del día
/// - Resumen nutricional con macros restantes
/// - Contexto temporal y motivacional
class TodaySummary {
  // Entrenamiento
  final bool isTrainingDay;
  final String? suggestedWorkout;
  final String? suggestedWorkoutName;
  final int? daysSinceLastSession;
  final DateTime? lastSessionDate;
  final bool isRestDaySuggested;
  final String? workoutMotivationalMessage;

  // Nutrición
  final int kcalRemaining;
  final int kcalTarget;
  final int kcalConsumed;
  final double kcalProgress;
  final double proteinRemaining;
  final double carbsRemaining;
  final double fatRemaining;
  final bool hasNutritionTargets;

  // Estado general
  final bool isLoading;
  final String? error;

  const TodaySummary({
    this.isTrainingDay = false,
    this.suggestedWorkout,
    this.suggestedWorkoutName,
    this.daysSinceLastSession,
    this.lastSessionDate,
    this.isRestDaySuggested = false,
    this.workoutMotivationalMessage,
    this.kcalRemaining = 0,
    this.kcalTarget = 0,
    this.kcalConsumed = 0,
    this.kcalProgress = 0.0,
    this.proteinRemaining = 0.0,
    this.carbsRemaining = 0.0,
    this.fatRemaining = 0.0,
    this.hasNutritionTargets = false,
    this.isLoading = false,
    this.error,
  });

  /// Factory para estado de carga
  factory TodaySummary.loading() => const TodaySummary(isLoading: true);

  /// Factory para error
  factory TodaySummary.error(String message) => TodaySummary(error: message);

  /// Versión vacía (sin datos)
  factory TodaySummary.empty() => const TodaySummary();

  /// Formato legible de calorías restantes
  String get kcalRemainingText => '$kcalRemaining kcal';

  /// Porcentaje como texto
  String get kcalProgressText => '${(kcalProgress * 100).toInt()}%';

  /// Indica si hay datos de entrenamiento disponibles
  bool get hasTrainingData => suggestedWorkout != null;

  /// Indica si hay datos de nutrición disponibles
  bool get hasNutritionData => hasNutritionTargets;
}

/// Provider del resumen de hoy - combina entrenamiento y nutrición
final todaySummaryProvider = FutureProvider<TodaySummary>((ref) async {
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);

  // Obtener datos de entrenamiento
  final training = await ref.watch(smartSuggestionProvider.future);

  // Obtener datos de nutrición (AsyncValue)
  final nutritionAsync = ref.watch(daySummaryForDateProvider(normalizedToday));
  final nutrition = nutritionAsync.whenOrNull(data: (d) => d);

  // Valores por defecto si no hay datos
  final hasTargets = nutrition?.hasTargets ?? false;
  final kcalTarget = nutrition?.targets?.kcalTarget ?? 0;
  final kcalConsumed = nutrition?.consumed.kcal ?? 0;
  final kcalRemaining = hasTargets
      ? (kcalTarget - kcalConsumed).clamp(0, double.infinity).toInt()
      : 0;
  final kcalProgress = hasTargets && kcalTarget > 0
      ? (kcalConsumed / kcalTarget).clamp(0.0, 2.0)
      : 0.0;

  // Calcular macros restantes
  final proteinTarget = nutrition?.targets?.proteinTarget ?? 0;
  final proteinRemaining = hasTargets && proteinTarget > 0
      ? (proteinTarget - (nutrition?.consumed.protein ?? 0))
            .clamp(0, double.infinity)
            .toDouble()
      : 0.0;

  final carbsTarget = nutrition?.targets?.carbsTarget ?? 0;
  final carbsRemaining = hasTargets && carbsTarget > 0
      ? (carbsTarget - (nutrition?.consumed.carbs ?? 0))
            .clamp(0, double.infinity)
            .toDouble()
      : 0.0;

  final fatTarget = nutrition?.targets?.fatTarget ?? 0;
  final fatRemaining = hasTargets && fatTarget > 0
      ? (fatTarget - (nutrition?.consumed.fat ?? 0))
            .clamp(0, double.infinity)
            .toDouble()
      : 0.0;

  return TodaySummary(
    // Entrenamiento
    isTrainingDay: training != null && !training.isRestDay,
    suggestedWorkout: training?.dayName,
    suggestedWorkoutName: training?.rutina.nombre,
    daysSinceLastSession: training?.timeSinceLastSession?.inDays,
    lastSessionDate: training?.lastSessionDate,
    isRestDaySuggested: training?.isRestDay ?? false,
    workoutMotivationalMessage: training?.motivationalMessage,

    // Nutrición
    kcalRemaining: kcalRemaining,
    kcalTarget: kcalTarget,
    kcalConsumed: kcalConsumed,
    kcalProgress: kcalProgress,
    proteinRemaining: proteinRemaining,
    carbsRemaining: carbsRemaining,
    fatRemaining: fatRemaining,
    hasNutritionTargets: hasTargets,
  );
});

/// Provider de stream para actualizaciones en tiempo real
final todaySummaryStreamProvider = StreamProvider<TodaySummary>((ref) async* {
  // Obtener valor inicial
  final initial = await ref.watch(todaySummaryProvider.future);
  yield initial;

  // Este provider se reconstruirá automáticamente cuando cambien las dependencias
  // gracias a la naturaleza reactiva de Riverpod
});
