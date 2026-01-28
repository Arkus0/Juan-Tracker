import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/training_exercise.dart';
import '../../../core/models/training_rutina.dart';
import '../../../core/providers/exercise_providers.dart';
import '../../../core/providers/routine_providers.dart';
import '../../../core/providers/training_session_controller.dart';
import '../../../core/providers/database_provider.dart';
import 'training_utils.dart';

class TrainingRoutinesScreen extends ConsumerWidget {
  const TrainingRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);
    final filtered = ref.watch(filteredRoutinesProvider);
    final library = ref.watch(filteredExercisesSourceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text('Rutinas', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddRoutineDialog(context, ref, library),
                icon: const Icon(Icons.add),
                label: const Text('Nueva'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar rutina',
            ),
            onChanged: (value) =>
                ref.read(routineNameFilterProvider.notifier).setQuery(value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: routinesAsync.when(
              data: (_) {
                if (filtered.isEmpty) {
                  return const Center(child: Text('Sin rutinas aun'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final rutina = filtered[i];
                    return Card(
                      child: ListTile(
                        title: Text(rutina.nombre),
                        subtitle: Text(
                          '${rutina.ejerciciosPlantilla.length} ejercicios',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Iniciar',
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () {
                                final ejercicios = buildEjerciciosFromIds(
                                  rutina.ejerciciosPlantilla,
                                  library,
                                );
                                final id = DateTime.now().millisecondsSinceEpoch
                                    .toString();
                                ref
                                    .read(
                                      trainingSessionControllerProvider
                                          .notifier,
                                    )
                                    .startSessionFromRoutine(
                                      id: id,
                                      rutinaId: rutina.id,
                                      ejerciciosBase: ejercicios,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Sesion iniciada desde ${rutina.nombre}',
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => ref
                                  .read(routineRepositoryProvider)
                                  .deleteRoutine(rutina.id),
                            ),
                          ],
                        ),
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

  Future<void> _showAddRoutineDialog(
    BuildContext context,
    WidgetRef ref,
    List<TrainingExercise> library,
  ) async {
    final nameCtl = TextEditingController();
    final selected = <String>{};

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nueva rutina'),
          content: SizedBox(
            width: 360,
            height: 360,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: library.length,
                    itemBuilder: (context, i) {
                      final ex = library[i];
                      final checked = selected.contains(ex.id);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(ex.nombre),
                        subtitle: Text(ex.grupoMuscular),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selected.add(ex.id);
                            } else {
                              selected.remove(ex.id);
                            }
                          });
                        },
                      );
                    },
                  ),
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
              onPressed: () async {
                final nombre = nameCtl.text.trim();
                if (nombre.isEmpty) return;
                final rutina = Rutina(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nombre: nombre,
                  ejerciciosPlantilla: selected.toList(),
                );
                await ref.read(routineRepositoryProvider).saveRoutine(rutina);
                if (context.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
