import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/design_system/design_system.dart' as core show AppTypography;
import '../models/ejercicio.dart';
import '../models/sesion.dart';
import '../providers/training_provider.dart';
import '../utils/design_system.dart';

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (sessions) {
          final previousSession = _findPreviousSession(sessions);

          return rutinasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
        style: core.AppTypography.bodyMedium.copyWith(
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
          style: core.AppTypography.bodyMedium.copyWith(
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
        style: core.AppTypography.bodySmall.copyWith(
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
                style: core.AppTypography.headlineSmall,
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
              style: core.AppTypography.bodyMedium.copyWith(
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
                    style: core.AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(sesion.fecha),
                    style: core.AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sesion.completedSetsCount} series • ${(sesion.totalVolume / 1000).toStringAsFixed(1)}t volumen',
                    style: core.AppTypography.bodySmall.copyWith(
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
              style: core.AppTypography.labelMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete, size: 18),
            label: Text(
              'ELIMINAR',
              style: core.AppTypography.labelLarge,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sesión eliminada',
                style: core.AppTypography.bodyMedium,
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al eliminar: $e',
                style: core.AppTypography.bodyMedium,
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
