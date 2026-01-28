import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/training_exercise.dart';
import '../../../core/models/training_sesion.dart';
import '../../../core/providers/exercise_providers.dart';
import '../../../core/providers/training_providers.dart';
import '../../../core/providers/training_session_controller.dart';
import '../../../core/providers/database_provider.dart';
import 'history_screen.dart';
import 'rest_timer_dialog.dart';
import 'training_library_screen.dart';
import 'training_routines_screen.dart';

class TrainingHomeScreen extends StatelessWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Entrenamiento'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Inicio'),
              Tab(text: 'Biblioteca'),
              Tab(text: 'Rutinas'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TrainingDashboardView(),
            TrainingLibraryScreen(),
            TrainingRoutinesScreen(),
            HistoryContent(showHeader: false),
          ],
        ),
      ),
    );
  }
}

class TrainingDashboardView extends ConsumerWidget {
  const TrainingDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(trainingStatsProvider);
    final sessionsAsync = ref.watch(trainingSessionsProvider);
    final sessionState = ref.watch(trainingSessionControllerProvider);
    final library = ref
        .watch(exerciseLibraryProvider)
        .maybeWhen(data: (items) => items, orElse: () => <TrainingExercise>[]);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeroStatsCard(stats: stats),
        const SizedBox(height: 16),
        if (sessionState.isActive)
          _ActiveSessionPanel(
            session: sessionState.activeSession!,
            isSaving: sessionState.isSaving,
            onAddSet: () => _showQuickSetDialog(context, ref, library),
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
          _IdleSessionPanel(onStart: () => _startSession(ref)),
        const SizedBox(height: 16),
        _QuickActionsRow(
          onStart: () => _startSession(ref),
          onLibrary: () => _goToTab(context, 1),
          onHistory: () => _goToTab(context, 3),
          onTimer: () => _openTimer(context),
          onVoice: () => _showStub(context, 'Voz'),
          onOcr: () => _showStub(context, 'OCR'),
        ),
        const SizedBox(height: 24),
        Text(
          'Ultimas sesiones',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        sessionsAsync.when(
          data: (sessions) {
            final latest = sessions.take(3).toList();
            if (latest.isEmpty) {
              return const Text('Todavia no hay sesiones');
            }
            return Column(
              children: [
                for (final sesion in latest)
                  Card(
                    child: ListTile(
                      title: Text(_formatSessionTitle(sesion)),
                      subtitle: Text(_formatSessionSubtitle(sesion)),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Text('Error: $e'),
        ),
      ],
    );
  }

  void _startSession(WidgetRef ref) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    ref.read(trainingSessionControllerProvider.notifier).startSession(id: id);
  }

  void _goToTab(BuildContext context, int index) {
    final controller = DefaultTabController.of(context);
    controller.animateTo(index);
  }

  void _openTimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const RestTimerDialog(seconds: 90),
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

  void _showStub(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature no disponible en este MVP')),
    );
  }

  Future<void> _showQuickSetDialog(
    BuildContext context,
    WidgetRef ref,
    List<TrainingExercise> library,
  ) async {
    if (library.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biblioteca sin ejercicios')),
      );
      return;
    }
    TrainingExercise selected = library.first;
    final pesoCtl = TextEditingController();
    final repsCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Agregar serie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selected.id,
                items: library
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.id, child: Text(e.nombre)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selected = library.firstWhere((e) => e.id == value);
                  });
                },
                decoration: const InputDecoration(labelText: 'Ejercicio'),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final peso = double.tryParse(pesoCtl.text) ?? 0.0;
                final reps = int.tryParse(repsCtl.text) ?? 0;
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
                      ejercicioId: selected.id,
                      ejercicioNombre: selected.nombre,
                      peso: peso,
                      reps: reps,
                    );
                Navigator.of(ctx).pop();
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatsCard extends StatelessWidget {
  final TrainingStats stats;

  const _HeroStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semana en marcha',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: scheme.onPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: 'Sesiones',
                value: stats.sesionesSemana.toString(),
                color: scheme.onPrimary,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Series',
                value: stats.setsSemana.toString(),
                color: scheme.onPrimary,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Volumen',
                value: stats.volumenSemana.toStringAsFixed(0),
                color: scheme.onPrimary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stats.ultimaSesion != null
                ? 'Ultima sesion: ${_formatSessionTitle(stats.ultimaSesion!)}'
                : 'Aun no hay sesiones registradas',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleSessionPanel extends StatelessWidget {
  final VoidCallback onStart;

  const _IdleSessionPanel({required this.onStart});

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
            const Text('No hay sesion en curso. Inicia una ahora.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar sesion'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionPanel extends StatelessWidget {
  final Sesion session;
  final bool isSaving;
  final VoidCallback onAddSet;
  final VoidCallback onUndo;
  final VoidCallback onFinish;

  const _ActiveSessionPanel({
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

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onLibrary;
  final VoidCallback onHistory;
  final VoidCallback onTimer;
  final VoidCallback onVoice;
  final VoidCallback onOcr;

  const _QuickActionsRow({
    required this.onStart,
    required this.onLibrary,
    required this.onHistory,
    required this.onTimer,
    required this.onVoice,
    required this.onOcr,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 150,
          child: FilledButton(onPressed: onStart, child: const Text('Iniciar')),
        ),
        SizedBox(
          width: 150,
          child: OutlinedButton(
            onPressed: onLibrary,
            child: const Text('Biblioteca'),
          ),
        ),
        SizedBox(
          width: 150,
          child: OutlinedButton(
            onPressed: onHistory,
            child: const Text('Historial'),
          ),
        ),
        SizedBox(
          width: 150,
          child: OutlinedButton(onPressed: onTimer, child: const Text('Timer')),
        ),
        SizedBox(
          width: 150,
          child: OutlinedButton(onPressed: onVoice, child: const Text('Voz')),
        ),
        SizedBox(
          width: 150,
          child: OutlinedButton(onPressed: onOcr, child: const Text('OCR')),
        ),
      ],
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
  return '$sets series - $volume kg';
}
