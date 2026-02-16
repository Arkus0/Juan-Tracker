/// Bridge provider que conecta el módulo de entrenamiento con el de dieta.
///
/// Permite al módulo de dieta saber si el usuario entrenó en una fecha
/// determinada, sin importar directamente los modelos de entrenamiento.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../training/models/analysis_models.dart' show normalizeMuscleGroup;
import '../../training/providers/training_provider.dart';
import '../models/training_day_info.dart';

/// Provider que detecta si el usuario entrenó en una fecha determinada.
///
/// Consulta la base de datos de sesiones de entrenamiento y retorna
/// un [TrainingDayInfo] con los detalles relevantes.
final trainingDayInfoProvider =
    FutureProvider.family<TrainingDayInfo, DateTime>((ref, date) async {
  final repo = ref.watch(trainingRepositoryProvider);
  final sessions = await repo.getSessionsForDate(date);

  if (sessions.isEmpty) return const TrainingDayInfo.rest();

  // Agregar grupos musculares de todos los ejercicios
  final muscles = <String>{};
  double totalVol = 0;
  int totalDuration = 0;

  for (final session in sessions) {
    totalDuration += session.durationSeconds ?? 0;

    for (final exercise in session.ejerciciosCompletados) {
      for (final muscle in exercise.musculosPrincipales) {
        muscles.add(normalizeMuscleGroup(muscle));
      }
      for (final log in exercise.logs) {
        if (log.completed) {
          totalVol += log.peso * log.reps;
        }
      }
    }
  }

  return TrainingDayInfo(
    didTrain: true,
    muscleGroups: muscles.toList()..sort(),
    durationMinutes: totalDuration > 0 ? totalDuration ~/ 60 : null,
    totalVolume: totalVol > 0 ? totalVol : null,
    sessionsCount: sessions.length,
    dayName: sessions.first.dayName,
  );
});

/// Provider que indica si el usuario entrenó hoy
final didTrainTodayProvider = FutureProvider<bool>((ref) async {
  final today = DateTime.now();
  final info = await ref.watch(
    trainingDayInfoProvider(DateTime(today.year, today.month, today.day))
        .future,
  );
  return info.didTrain;
});
