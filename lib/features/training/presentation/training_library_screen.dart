import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/training_exercise.dart';
import '../../../core/providers/exercise_providers.dart';
import '../../../core/providers/training_session_controller.dart';
import '../../../core/providers/database_provider.dart';

class TrainingLibraryScreen extends ConsumerWidget {
  const TrainingLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncExercises = ref.watch(exerciseLibraryProvider);
    final filtered = ref.watch(filteredExercisesProvider);
    final muscleOptions = ref.watch(exerciseMuscleOptionsProvider);
    final equipmentOptions = ref.watch(exerciseEquipmentOptionsProvider);
    final sessionState = ref.watch(trainingSessionControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Biblioteca', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddExerciseSheet(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar ejercicio',
            ),
            onChanged: (value) =>
                ref.read(exerciseSearchQueryProvider.notifier).setQuery(value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: ref.watch(exerciseFilterMuscleProvider),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los grupos'),
                    ),
                    for (final m in muscleOptions)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: (value) => ref
                      .read(exerciseFilterMuscleProvider.notifier)
                      .setFilter(value),
                  decoration: const InputDecoration(labelText: 'Grupo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: ref.watch(exerciseFilterEquipmentProvider),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todo el equipo'),
                    ),
                    for (final e in equipmentOptions)
                      DropdownMenuItem(value: e, child: Text(e)),
                  ],
                  onChanged: (value) => ref
                      .read(exerciseFilterEquipmentProvider.notifier)
                      .setFilter(value),
                  decoration: const InputDecoration(labelText: 'Equipo'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Limpiar filtros',
                onPressed: () {
                  ref.read(exerciseFilterMuscleProvider.notifier).clear();
                  ref.read(exerciseFilterEquipmentProvider.notifier).clear();
                  ref.read(exerciseSearchQueryProvider.notifier).clear();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncExercises.when(
              data: (_) {
                if (filtered.isEmpty) {
                  return const Center(child: Text('Sin resultados'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final ex = filtered[i];
                    return Card(
                      child: ListTile(
                        title: Text(ex.nombre),
                        subtitle: Text(
                          '${ex.grupoMuscular} - ${ex.equipo} - ${ex.nivel}',
                        ),
                        trailing: sessionState.isActive
                            ? IconButton(
                                tooltip: 'Agregar serie',
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () =>
                                    _addSetForExercise(context, ref, ex),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSetForExercise(
    BuildContext context,
    WidgetRef ref,
    TrainingExercise ex,
  ) async {
    final pesoCtl = TextEditingController();
    final repsCtl = TextEditingController();
    final rpeCtl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Agregar serie: ${ex.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              decoration: const InputDecoration(labelText: 'RPE (opcional)'),
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
                    ejercicioId: ex.id,
                    ejercicioNombre: ex.nombre,
                    peso: peso,
                    reps: reps,
                    rpe: int.tryParse(rpeCtl.text),
                  );
              HapticFeedback.lightImpact();
              Navigator.of(ctx).pop();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddExerciseSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nombreCtl = TextEditingController();
    final grupoCtl = TextEditingController();
    final equipoCtl = TextEditingController();
    final nivelCtl = TextEditingController(text: 'basico');
    final descCtl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevo ejercicio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nombreCtl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: grupoCtl,
              decoration: const InputDecoration(labelText: 'Grupo muscular'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: equipoCtl,
              decoration: const InputDecoration(labelText: 'Equipo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nivelCtl,
              decoration: const InputDecoration(labelText: 'Nivel'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtl,
              decoration: const InputDecoration(labelText: 'Descripcion'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final nombre = nombreCtl.text.trim();
                      if (nombre.isEmpty) return;
                      final exercise = TrainingExercise(
                        id: _slugify(nombre),
                        nombre: nombre,
                        grupoMuscular: grupoCtl.text.trim(),
                        musculosSecundarios: const [],
                        equipo: equipoCtl.text.trim(),
                        nivel: nivelCtl.text.trim().isEmpty
                            ? 'basico'
                            : nivelCtl.text.trim(),
                        descripcion: descCtl.text.trim(),
                      );
                      await ref
                          .read(exerciseRepositoryProvider)
                          .addExercise(exercise);
                      if (context.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _slugify(String input) {
    final cleaned = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : cleaned;
  }
}
