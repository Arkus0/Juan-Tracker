import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/training_exercise.dart';
import '../../../core/models/training_sesion.dart';
import '../../../core/providers/exercise_providers.dart';
import '../../../core/providers/training_providers.dart';
import '../../../core/providers/training_session_controller.dart';
import '../../../core/providers/database_provider.dart';
import 'history_grouping.dart';
import 'external_session_sheet.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(trainingSessionControllerProvider);

    return Scaffold(
      body: const HistoryContent(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_external_session',
            onPressed: () => _addExternalSession(context, ref),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Sesion externa'),
          ),
          const SizedBox(height: 12),
          if (!sessionState.isActive)
            FloatingActionButton(
              heroTag: 'start_session',
              onPressed: () => _startSession(ref),
              child: const Icon(Icons.play_arrow),
            ),
        ],
      ),
    );
  }

  void _startSession(WidgetRef ref) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    ref.read(trainingSessionControllerProvider.notifier).startSession(id: id);
  }

  Future<void> _addExternalSession(BuildContext context, WidgetRef ref) async {
    final sesion = await showExternalSessionSheet(context);
    if (sesion == null) return;
    await ref
        .read(trainingSessionControllerProvider.notifier)
        .addExternalSession(sesion);
    if (context.mounted) {
      _showUndoSnack(context, ref, sesion.id);
    }
  }
}

class HistoryContent extends ConsumerWidget {
  final bool showHeader;

  const HistoryContent({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(trainingSessionsProvider);
    final sessionState = ref.watch(trainingSessionControllerProvider);
    final exercisesAsync = ref.watch(exerciseLibraryProvider);

    final library = exercisesAsync.maybeWhen(
      data: (items) => items,
      orElse: () => <TrainingExercise>[],
    );

    return sessionsAsync.when(
      data: (sessions) {
        final groups = groupSessionsByPeriod(sessions, DateTime.now());
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (showHeader)
              _HeaderRow(
                onExportAllText: () =>
                    _exportAll(context, sessions, asJson: false),
                onExportAllJson: () =>
                    _exportAll(context, sessions, asJson: true),
              ),
            if (sessionState.isActive)
              _ActiveSessionCard(
                session: sessionState.activeSession!,
                isSaving: sessionState.isSaving,
                onAddSet: () =>
                    _showAddSetDialog(context, ref, library: library),
                onUndo: () => ref
                    .read(trainingSessionControllerProvider.notifier)
                    .undoLastSet(),
                onFinish: () async {
                  await ref
                      .read(trainingSessionControllerProvider.notifier)
                      .finishSession();
                  HapticFeedback.mediumImpact();
                  final saved = ref
                      .read(trainingSessionControllerProvider)
                      .lastSession;
                  if (context.mounted && saved != null) {
                    _showUndoSnack(context, ref, saved.id);
                  }
                },
              )
            else
              _EmptyActiveSession(onStart: () => _startSession(ref)),
            const SizedBox(height: 16),
            if (groups.isEmpty)
              const Text('Sin sesiones aun')
            else
              for (final group in groups) ...[
                Text(
                  group.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final sesion in group.sesiones)
                  Card(
                    child: ListTile(
                      title: Text(_formatSessionTitle(sesion)),
                      subtitle: Text(_formatSessionSubtitle(sesion)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SessionDetailScreen(session: sesion),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  void _startSession(WidgetRef ref) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    ref.read(trainingSessionControllerProvider.notifier).startSession(id: id);
  }

  Future<void> _showAddSetDialog(
    BuildContext context,
    WidgetRef ref, {
    required List<TrainingExercise> library,
  }) async {
    final ejercicioCtl = TextEditingController();
    final pesoCtl = TextEditingController();
    final repsCtl = TextEditingController();
    final rpeCtl = TextEditingController();
    String? selectedId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Agregar serie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedId,
                  items: library
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedId = value);
                    final exercise = library.firstWhere((e) => e.id == value);
                    ejercicioCtl.text = exercise.nombre;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Ejercicio (biblioteca)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ejercicioCtl,
                  decoration: const InputDecoration(
                    labelText: 'Ejercicio (manual)',
                  ),
                ),
                TextField(
                  controller: pesoCtl,
                  decoration: const InputDecoration(labelText: 'Peso'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: repsCtl,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: rpeCtl,
                  decoration: const InputDecoration(
                    labelText: 'RPE (opcional)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final ejercicioNombre = ejercicioCtl.text.trim().isEmpty
                    ? 'Ejercicio'
                    : ejercicioCtl.text.trim();
                final ejercicioId = selectedId ?? ejercicioNombre;
                final peso = double.tryParse(pesoCtl.text) ?? 0.0;
                final reps = int.tryParse(repsCtl.text) ?? 0;
                final rpe = int.tryParse(rpeCtl.text);
                if (peso < 0 || reps <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Peso debe ser >= 0 y reps > 0'),
                    ),
                  );
                  return;
                }
                ref
                    .read(trainingSessionControllerProvider.notifier)
                    .addSet(
                      ejercicioId: ejercicioId,
                      ejercicioNombre: ejercicioNombre,
                      peso: peso,
                      reps: reps,
                      rpe: rpe,
                    );
                HapticFeedback.lightImpact();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Serie agregada'),
                    action: SnackBarAction(
                      label: 'DESHACER',
                      onPressed: () => ref
                          .read(trainingSessionControllerProvider.notifier)
                          .undoLastSet(),
                    ),
                  ),
                );
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAll(
    BuildContext context,
    List<Sesion> sesiones, {
    required bool asJson,
  }) async {
    if (sesiones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay sesiones para exportar')),
      );
      return;
    }

    final content = asJson
        ? const JsonEncoder.withIndent(
            '  ',
          ).convert(sesiones.map((s) => s.toMap()).toList())
        : sesiones.map(_exportSessionText).join('\n\n');

    await _showExportDialog(
      context,
      title: asJson
          ? 'Exportar historial (JSON)'
          : 'Exportar historial (Texto)',
      content: content,
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final VoidCallback onExportAllText;
  final VoidCallback onExportAllJson;

  const _HeaderRow({
    required this.onExportAllText,
    required this.onExportAllJson,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Historial', style: Theme.of(context).textTheme.headlineSmall),
        const Spacer(),
        IconButton(
          onPressed: onExportAllText,
          icon: const Icon(Icons.description_outlined),
          tooltip: 'Exportar texto',
        ),
        IconButton(
          onPressed: onExportAllJson,
          icon: const Icon(Icons.data_object),
          tooltip: 'Exportar JSON',
        ),
      ],
    );
  }
}

class _EmptyActiveSession extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyActiveSession({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesion activa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('No hay sesion en curso'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onStart,
              child: const Text('Iniciar sesion'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final Sesion session;
  final bool isSaving;
  final VoidCallback onAddSet;
  final VoidCallback onUndo;
  final VoidCallback onFinish;

  const _ActiveSessionCard({
    required this.session,
    required this.isSaving,
    required this.onAddSet,
    required this.onUndo,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sesion activa',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (isSaving)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Series: ${session.completedSetsCount}'),
            Text('Volumen: ${session.totalVolume.toStringAsFixed(1)}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onAddSet,
                  child: const Text('Agregar serie'),
                ),
                OutlinedButton(
                  onPressed: onUndo,
                  child: const Text('Deshacer'),
                ),
                OutlinedButton(
                  onPressed: onFinish,
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatSessionTitle(Sesion sesion) {
  final date = sesion.fecha;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return 'Sesion $day/$month/${date.year}';
}

String _formatSessionSubtitle(Sesion sesion) {
  final sets = sesion.completedSetsCount;
  final volume = sesion.totalVolume.toStringAsFixed(1);
  final duration = sesion.durationSeconds != null
      ? '${(sesion.durationSeconds! / 60).round()} min'
      : 'sin duracion';
  return '$sets series - $volume kg - $duration';
}

String _exportSessionText(Sesion sesion) {
  final buffer = StringBuffer();
  buffer.writeln(_formatSessionTitle(sesion));
  buffer.writeln('Duracion: ${sesion.formattedDuration}');
  buffer.writeln('Volumen total: ${sesion.totalVolume.toStringAsFixed(1)}');
  for (final ejercicio in sesion.ejerciciosCompletados) {
    buffer.writeln('- ${ejercicio.nombre}:');
    for (final log in ejercicio.logs) {
      final rpe = log.rpe != null ? ' rpe ${log.rpe}' : '';
      buffer.writeln('  ${log.peso} x ${log.reps}$rpe');
    }
  }
  return buffer.toString().trim();
}

Future<void> _showExportDialog(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: SelectableText(content)),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: content));
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          child: const Text('Copiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

void _showUndoSnack(BuildContext context, WidgetRef ref, String sessionId) {
  final repo = ref.read(trainingRepositoryProvider);
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Sesion guardada'),
      duration: const Duration(seconds: 10),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'DESHACER',
        onPressed: () => repo.deleteSession(sessionId),
      ),
    ),
  );
}
