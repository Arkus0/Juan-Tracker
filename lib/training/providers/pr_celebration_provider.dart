import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analysis_provider.dart';
import 'training_provider.dart';

/// Evento de PR detectado durante la sesión.
class PrEvent {
  final String exerciseName;
  final double weight;
  final int reps;
  final DateTime timestamp;

  const PrEvent({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.timestamp,
  });
}

/// Provider que mantiene el último PR detectado.
/// Se resetea (null) después de que la UI muestra la celebración.
final prCelebrationProvider =
    NotifierProvider<PrCelebrationNotifier, PrEvent?>(
  PrCelebrationNotifier.new,
);

class PrCelebrationNotifier extends Notifier<PrEvent?> {
  @override
  PrEvent? build() => null;

  /// Chequea si el set recién completado bate el PR existente.
  ///
  /// Llama a esto DESPUÉS de `updateLog(..., completed: true)`.
  Future<void> checkForPr({
    required int exerciseIndex,
    required int setIndex,
  }) async {
    final session = ref.read(trainingSessionProvider);
    if (exerciseIndex < 0 || exerciseIndex >= session.exercises.length) return;

    final exercise = session.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.logs.length) return;

    final log = exercise.logs[setIndex];
    if (!log.completed || log.isWarmup) return;
    if (log.peso <= 0 || log.reps <= 0) return;

    // Obtener PR actual del repositorio
    final prAsync = await ref.read(
      personalRecordForExerciseProvider(exercise.nombre).future,
    );

    bool isNewPr = false;
    if (prAsync == null) {
      // Primer registro = PR automático (solo si peso significativo)
      isNewPr = log.peso >= 20; // Mínimo 20kg para considerar PR inicial
    } else {
      // Comparar contra el mejor histórico
      if (log.peso > prAsync.maxWeight) {
        isNewPr = true;
      } else if (log.peso == prAsync.maxWeight &&
          log.reps > prAsync.repsAtMax) {
        isNewPr = true;
      }
    }

    // También verificar contra otros sets completados EN ESTA MISMA sesión
    // (evita celebrar el mismo PR dos veces si se sube peso progresivamente)
    if (isNewPr) {
      for (var i = 0; i < exercise.logs.length; i++) {
        if (i == setIndex) continue;
        final other = exercise.logs[i];
        if (!other.completed || other.isWarmup) continue;
        if (other.peso > log.peso) {
          isNewPr = false;
          break;
        }
        if (other.peso == log.peso && other.reps >= log.reps) {
          isNewPr = false;
          break;
        }
      }
    }

    if (isNewPr) {
      state = PrEvent(
        exerciseName: exercise.nombre,
        weight: log.peso,
        reps: log.reps,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Resetea el evento para que la UI deje de mostrar la celebración.
  void dismiss() => state = null;
}
