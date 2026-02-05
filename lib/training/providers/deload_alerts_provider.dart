import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/progression_engine_extensions.dart';
import '../services/progression_engine.dart';
import '../models/analysis_models.dart';
import '../models/sesion.dart';
import 'training_provider.dart';

/// 🎯 MED-005: Provider de alertas de deload/sobreentrenamiento
///
/// Monitorea el progreso del usuario y muestra alertas cuando:
/// - Lleva 3+ semanas sin progreso
/// - El RPE está aumentando
/// - Hay fallos repetidos
final deloadAlertsProvider = Provider<List<DeloadAlert>>((ref) {
  final sessionsAsync = ref.watch(sesionesHistoryStreamProvider);

  return sessionsAsync.when(
    data: (sessions) {
      final alertsByExercise = <String, DeloadAlert>{};

      // Analizar cada ejercicio único
      final exerciseNames = <String>{};
      for (final session in sessions) {
        for (final ex in session.ejerciciosCompletados) {
          exerciseNames.add(ex.nombre);
        }
      }

      for (final exerciseName in exerciseNames) {
        // Obtener datos de fuerza para este ejercicio
        final dataPoints = _extractStrengthDataPoints(sessions, exerciseName);

        if (dataPoints.length >= 4) {
          final analysis = ProgressionEngine.instance.analyzeStrengthTrend(
            dataPoints,
          );

          if (analysis.phase == StrengthTrendPhase.declining) {
            _upsertAlert(
              alertsByExercise,
              DeloadAlert(
                exerciseName: exerciseName,
                message: 'Fuerza en descenso',
                recommendation: 'Deload urgente: descansa o reduce carga',
                severity: AlertSeverity.critical,
              ),
            );
          } else if (analysis.isStalled) {
            _upsertAlert(
              alertsByExercise,
              DeloadAlert(
                exerciseName: exerciseName,
                message: 'Estancado por ${dataPoints.length} sesiones',
                recommendation:
                    'Considera reducir volumen 20% o cambiar ejercicio',
                severity: AlertSeverity.warning,
              ),
            );
          }
        }
      }

      final alerts = alertsByExercise.values.toList()
        ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

      // Evitar saturar la UI cuando hay muchas alertas a la vez.
      return alerts.take(4).toList();
    },
    loading: () => [],
    error: (err, stack) => [],
  );
});

/// Alerta de deload individual
class DeloadAlert {
  final String exerciseName;
  final String message;
  final String recommendation;
  final AlertSeverity severity;

  const DeloadAlert({
    required this.exerciseName,
    required this.message,
    required this.recommendation,
    required this.severity,
  });
}

enum AlertSeverity { info, warning, critical }

/// Extrae puntos de datos de fuerza de las sesiones
List<StrengthDataPoint> _extractStrengthDataPoints(
  List<Sesion> sessions,
  String exerciseName,
) {
  final points = <StrengthDataPoint>[];

  for (final session in sessions) {
    for (final ex in session.ejerciciosCompletados) {
      if (ex.nombre == exerciseName) {
        final completedSets = ex.logs
            .where((set) => set.completed && set.peso > 0 && set.reps > 0)
            .toList();
        if (completedSets.isEmpty) continue;

        // Set más demandante por volumen (kg x reps).
        final maxSet = completedSets.reduce(
          (a, b) => (a.peso * a.reps) > (b.peso * b.reps) ? a : b,
        );
        final estimated1RM = estimateOneRepMax(maxSet.peso, maxSet.reps);

        points.add(
          StrengthDataPoint(
            date: session.fecha,
            estimated1RM: estimated1RM,
            actualMax: maxSet.peso,
            repsAtMax: maxSet.reps,
          ),
        );
      }
    }
  }

  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

void _upsertAlert(
  Map<String, DeloadAlert> alertsByExercise,
  DeloadAlert alert,
) {
  final existing = alertsByExercise[alert.exerciseName];
  if (existing == null || alert.severity.index > existing.severity.index) {
    alertsByExercise[alert.exerciseName] = alert;
  }
}
