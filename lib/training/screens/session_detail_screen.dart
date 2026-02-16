import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design_system/design_system.dart';
import '../../core/widgets/app_snackbar.dart';
import '../models/ejercicio.dart';
import '../models/sesion.dart';
import '../providers/training_provider.dart';
import '../widgets/common/skeleton_loaders.dart';

class SessionDetailScreen extends ConsumerWidget {
  final Sesion sesion;

  const SessionDetailScreen({super.key, required this.sesion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can fetch previous session from the history stream,
    // but calculating it here is simpler if we assume history is available.
    // Ideally, the repository should provide a method for comparison or we do it here.
    final sessionsAsync = ref.watch(sesionesHistoryStreamProvider);
    final rutinasAsync = ref.watch(rutinasStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('INFORME DE COMBATE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Eliminar sesión',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const TrainingSessionSkeleton(),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (sessions) {
          final previousSession = _findPreviousSession(sessions);
          final sessionPrs = _computeSessionPRs(sessions);

          return rutinasAsync.when(
            loading: () => const TrainingSessionSkeleton(),
            error: (err, stack) =>
                const SizedBox(), // Just don't show routine name if error
            data: (rutinas) {
              final rutinasMap = {for (final r in rutinas) r.id: r};
              final rutinaName =
                  rutinasMap[sesion.rutinaId]?.nombre ?? 'Rutina eliminada';

              final dateFormat = DateFormat('EEE, d MMM yyyy HH:mm', 'es_ES');
              final durationText = sesion.durationSeconds != null
                  ? '${(sesion.durationSeconds! / 60).toStringAsFixed(0)} MIN'
                  : 'N/A';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rutinaName.toUpperCase(),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dateFormat.format(sesion.fecha).toUpperCase(),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'DURACIÓN: $durationText',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSummaryCard(context, sessionPrs),

                    const SizedBox(height: 24),

                    // Exercises List
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        'EJERCICIOS EJECUTADOS',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...sesion.ejerciciosCompletados.map((ejercicio) {
                      return _buildExerciseCard(
                        context,
                        ejercicio,
                        _findExerciseById(
                          sesion.ejerciciosObjetivo,
                          ejercicio.id,
                        ),
                        previousSession != null
                            ? _findExerciseById(
                                previousSession.ejerciciosCompletados,
                                ejercicio.id,
                              )
                            : null,
                      );
                    }),

                    if (sesion.ejerciciosCompletados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No se registraron ejercicios en esta sesión.',
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Sesion? _findPreviousSession(List<Sesion> sessions) {
    // Filter by same routine and date strictly before current session
    final history = sessions
        .where(
          (s) =>
              s.rutinaId == sesion.rutinaId && s.fecha.isBefore(sesion.fecha),
        )
        .toList();

    if (history.isEmpty) return null;

    // Sort descending by date (newest first)
    history.sort((a, b) => b.fecha.compareTo(a.fecha));
    return history.first;
  }

  Ejercicio? _findExerciseById(List<Ejercicio> list, String id) {
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Ejercicio real,
    Ejercicio? target,
    Ejercicio? prev,
  ) {
    // Determine max sets to display rows
    final maxSets = [
      real.series,
      target?.series ?? 0,
      prev?.series ?? 0,
    ].reduce((curr, next) => curr > next ? curr : next);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              real.nombre.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(30), // Set #
                1: FlexColumnWidth(), // Target
                2: FlexColumnWidth(), // Real
                3: FlexColumnWidth(), // Prev
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Header
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                  children: [
                    _buildHeaderCell(context, '#'),
                    _buildHeaderCell(context, 'META'),
                    _buildHeaderCell(context, 'REAL'),
                    _buildHeaderCell(context, 'PREV'),
                  ],
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                    SizedBox(height: 8),
                  ],
                ),
                // Rows
                for (int i = 0; i < maxSets; i++)
                  TableRow(
                    children: [
                      _buildCell(context, '${i + 1}'),
                      // Target
                      _buildDataCell(context, target, i),
                      // Real
                      _buildDataCell(context, real, i, isReal: true),
                      // Prev
                      _buildDataCell(context, prev, i, isPrev: true),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<_SessionPr> prs) {
    final volume = sesion.totalVolume;
    final sets = sesion.completedSetsCount;
    final exercises = sesion.ejerciciosCompletados.length;
    final durationSeconds = sesion.durationSeconds;
    final durationText = durationSeconds != null
        ? '${(durationSeconds / 60).round()} min'
        : 'N/A';
    final volumePerMin = _formatVolumePerMinute(volume, durationSeconds);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  size: 18,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'RESUMEN DE SESION',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (prs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PRs ${prs.length}',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    icon: Icons.monitor_weight_outlined,
                    label: 'VOLUMEN',
                    value: _formatVolume(volume),
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    icon: Icons.check_circle_outline,
                    label: 'SERIES',
                    value: '$sets',
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    icon: Icons.fitness_center,
                    label: 'EJERCICIOS',
                    value: '$exercises',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    icon: Icons.timer_outlined,
                    label: 'DURACION',
                    value: durationText,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    icon: Icons.speed,
                    label: 'VOL/MIN',
                    value: volumePerMin,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            if (prs.isEmpty)
              Text(
                'Sin PRs en esta sesion',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: prs.map((pr) => _PrChip(pr: pr)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}t';
    }
    return '${volume.toStringAsFixed(0)}kg';
  }

  String _formatVolumePerMinute(double volume, int? durationSeconds) {
    if (durationSeconds == null || durationSeconds <= 0) return 'N/A';
    final minutes = durationSeconds / 60;
    if (minutes <= 0) return 'N/A';
    final perMin = volume / minutes;
    if (perMin >= 1000) {
      return '${(perMin / 1000).toStringAsFixed(2)}t/min';
    }
    return '${perMin.toStringAsFixed(0)}kg/min';
  }

  List<_SessionPr> _computeSessionPRs(List<Sesion> sessions) {
    final prs = <_SessionPr>[];
    final currentDate = sesion.fecha;

    for (final exercise in sesion.ejerciciosCompletados) {
      final currentBest = _bestSet(exercise);
      if (currentBest.weight <= 0) continue;

      var previousBest = 0.0;
      for (final history in sessions) {
        if (history.id == sesion.id) continue;
        if (!history.fecha.isBefore(currentDate)) continue;
        for (final other in history.ejerciciosCompletados) {
          if (other.historyKey != exercise.historyKey) continue;
          final historyBest = _bestSet(other);
          if (historyBest.weight > previousBest) {
            previousBest = historyBest.weight;
          }
        }
      }

      if (currentBest.weight > previousBest) {
        prs.add(
          _SessionPr(
            exerciseName: exercise.nombre,
            weight: currentBest.weight,
            reps: currentBest.reps,
            previousBest: previousBest,
          ),
        );
      }
    }

    prs.sort((a, b) => b.weight.compareTo(a.weight));
    return prs;
  }

  _BestSet _bestSet(Ejercicio exercise) {
    var bestWeight = 0.0;
    var bestReps = 0;
    for (final log in exercise.logs) {
      if (!log.completed) continue;
      if (log.peso > bestWeight ||
          (log.peso == bestWeight && log.reps > bestReps)) {
        bestWeight = log.peso;
        bestReps = log.reps;
      }
    }
    return _BestSet(weight: bestWeight, reps: bestReps);
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(
    BuildContext context,
    Ejercicio? ejercicio,
    int setIndex, {
    bool isReal = false,
    bool isPrev = false,
  }) {
    if (ejercicio == null || setIndex >= ejercicio.series) {
      return _buildCell(context, '-');
    }

    final logs = ejercicio.logs;
    final log = (setIndex < logs.length) ? logs[setIndex] : null;

    // Use logs if available, else fallback to session/reps (backward compatibility)
    // Actually, Session model has Ejercicio which has logs.
    // If logs are missing, fallback to peso/reps
    final weight = log?.peso ?? ejercicio.peso;
    final reps = log?.reps ?? ejercicio.reps;

    final text = '${weight}kg x $reps';

    // Highlight Real if it meets/exceeds Target (Logic simulation for visual polish)
    // Here we just style "Real" boldly
    if (isReal) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿ELIMINAR SESIÓN?',
                style: AppTypography.headlineSmall,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción no se puede deshacer.',
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sesion.dayName ?? 'Sesión',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(sesion.fecha),
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sesion.completedSetsCount} series • ${(sesion.totalVolume / 1000).toStringAsFixed(1)}t volumen',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.neonCyan,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'CANCELAR',
              style: AppTypography.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete, size: 18),
            label: Text(
              'ELIMINAR',
              style: AppTypography.labelLarge,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(trainingRepositoryProvider);
        await repository.deleteSesion(sesion.id);

        if (context.mounted) {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(); // Volver atrás tras eliminar
          AppSnackbar.show(context, message: 'Sesión eliminada');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al eliminar: $e',
                style: AppTypography.bodyMedium,
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrChip extends StatelessWidget {
  final _SessionPr pr;

  const _PrChip({required this.pr});

  String _formatWeight(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.tertiary.withAlpha(60)),
      ),
      child: Text(
        '${pr.exerciseName}: ${_formatWeight(pr.weight)}kg x ${pr.reps}',
        style: AppTypography.labelSmall.copyWith(
          color: colorScheme.tertiary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SessionPr {
  final String exerciseName;
  final double weight;
  final int reps;
  final double previousBest;

  const _SessionPr({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.previousBest,
  });
}

class _BestSet {
  final double weight;
  final int reps;

  const _BestSet({required this.weight, required this.reps});
}
