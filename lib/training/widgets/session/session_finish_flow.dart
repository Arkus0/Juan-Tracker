import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../providers/training_provider.dart';

/// Datos del resumen al finalizar una sesión.
class SessionFinishSummary {
  final double totalVolume;
  final int completedSets;
  final int totalSets;
  final int durationSeconds;
  final int exercisesCount;
  final int prCount;

  const SessionFinishSummary({
    required this.totalVolume,
    required this.completedSets,
    required this.totalSets,
    required this.durationSeconds,
    required this.exercisesCount,
    required this.prCount,
  });
}

/// Construye el resumen de sesión a partir del estado actual.
Future<SessionFinishSummary> buildFinishSummary(
  TrainingState state,
  WidgetRef ref,
) async {
  var completedSets = 0;
  var totalSets = 0;
  var totalVolume = 0.0;
  final exerciseNames = <String>{};

  for (final exercise in state.exercises) {
    exerciseNames.add(exercise.nombre);
    for (final log in exercise.logs) {
      totalSets++;
      if (!log.completed) continue;
      if (log.isWarmup) continue;
      completedSets++;
      if (log.peso > 0 && log.reps > 0) {
        totalVolume += log.peso * log.reps;
      }
    }
  }

  final durationSeconds = state.startTime == null
      ? 0
      : DateTime.now().difference(state.startTime!).inSeconds;

  final repo = ref.read(trainingRepositoryProvider);
  final prRecords = await repo.getPersonalRecords(
    exerciseNames: exerciseNames.toList(),
  );
  final prByExercise = {
    for (final pr in prRecords) pr.exerciseName.toLowerCase(): pr,
  };
  final prExercises = <String>{};

  for (final exercise in state.exercises) {
    final pr = prByExercise[exercise.nombre.toLowerCase()];
    if (pr == null) continue;
    for (final log in exercise.logs) {
      if (!log.completed || log.isWarmup) continue;
      if (log.peso > pr.maxWeight ||
          (log.peso == pr.maxWeight && log.reps > pr.repsAtMax)) {
        prExercises.add(exercise.nombre);
        break;
      }
    }
  }

  return SessionFinishSummary(
    totalVolume: totalVolume,
    completedSets: completedSets,
    totalSets: totalSets,
    durationSeconds: durationSeconds,
    exercisesCount: state.exercises.length,
    prCount: prExercises.length,
  );
}

/// Muestra el bottom sheet con el resumen de la sesión terminada.
Future<void> showFinishSummarySheet(
  BuildContext context,
  SessionFinishSummary summary,
) async {
  final scheme = Theme.of(context).colorScheme;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.emoji_events, color: scheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'RESUMEN DE SESIÓN',
                  style: AppTypography.sectionTitle.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FinishMetric(
                  icon: Icons.scale_outlined,
                  label: 'VOLUMEN',
                  value: formatVolume(summary.totalVolume),
                ),
                const SizedBox(width: 12),
                FinishMetric(
                  icon: Icons.timer_outlined,
                  label: 'TIEMPO',
                  value: formatDuration(summary.durationSeconds),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FinishMetric(
                  icon: Icons.fact_check_outlined,
                  label: 'SERIES',
                  value: '${summary.completedSets}/${summary.totalSets}',
                ),
                const SizedBox(width: 12),
                FinishMetric(
                  icon: Icons.fitness_center,
                  label: 'EJERCICIOS',
                  value: '${summary.exercisesCount}',
                ),
              ],
            ),
            if (summary.prCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.tertiary.withAlpha(28),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.tertiary.withAlpha(60)),
                ),
                child: Text(
                  '🎉 ${summary.prCount} PR nuevo${summary.prCount == 1 ? '' : 's'}',
                  style: AppTypography.labelEmphasis.copyWith(
                    color: scheme.tertiary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('CERRAR'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Métrica individual del resumen de finalización.
class FinishMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const FinishMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatea volumen en formato legible (k/M).
String formatVolume(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toStringAsFixed(0);
}

/// Formatea duración en formato legible (Xh Xm).
String formatDuration(int seconds) {
  if (seconds <= 0) return '0m';
  final minutes = seconds ~/ 60;
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours > 0) return '${hours}h ${mins}m';
  return '${minutes}m';
}
