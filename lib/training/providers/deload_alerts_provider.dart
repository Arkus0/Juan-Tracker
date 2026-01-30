import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/progression_engine_extensions.dart';
import '../services/progression_engine.dart';
import '../models/analysis_models.dart';
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
      final alerts = <DeloadAlert>[];
      
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
          final analysis = ProgressionEngine.instance.analyzeStrengthTrend(dataPoints);
          
          if (analysis.isStalled) {
            alerts.add(DeloadAlert(
              exerciseName: exerciseName,
              message: 'Estancado por ${dataPoints.length} semanas',
              recommendation: 'Considera reducir volumen 20% o cambiar ejercicio',
              severity: AlertSeverity.warning,
            ));
          }
          
          if (analysis.phase == StrengthTrendPhase.declining) {
            alerts.add(DeloadAlert(
              exerciseName: exerciseName,
              message: 'Fuerza en descenso',
              recommendation: 'Deload urgente: descansa o reduce carga',
              severity: AlertSeverity.critical,
            ));
          }
        }
      }
      
      return alerts;
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
  List<dynamic> sessions,
  String exerciseName,
) {
  final points = <StrengthDataPoint>[];
  
  for (final session in sessions) {
    for (final ex in session.ejercicios) {
      if (ex.nombre == exerciseName && ex.logs.isNotEmpty) {
        // Calcular 1RM estimado
        final maxSet = ex.logs.reduce((a, b) => 
          (a.peso * a.reps) > (b.peso * b.reps) ? a : b
        );
        
        // Fórmula de Brzycki para estimar 1RM
        final estimated1RM = maxSet.peso / (1.0278 - 0.0278 * maxSet.reps);
        
        points.add(StrengthDataPoint(
          date: session.fecha,
          estimated1RM: estimated1RM,
          actualMax: maxSet.peso,
          repsAtMax: maxSet.reps,
        ));
      }
    }
  }
  
  return points;
}
