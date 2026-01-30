import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import '../providers/training_provider.dart';

import 'create_edit_routine_screen.dart';

class RutinasScreen extends ConsumerWidget {
  const RutinasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinasAsync = ref.watch(rutinasStreamProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Mis Rutinas'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.download_outlined),
                onPressed: () => _showImportFlow(context, ref),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: rutinasAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AppLoading(message: 'Cargando rutinas...'),
              ),
              error: (err, stack) => AppError(
                message: 'Error al cargar rutinas',
                details: err.toString(),
                onRetry: () => ref.invalidate(rutinasStreamProvider),
              ),
              data: (rutinas) {
                // 🎯 MED-006: Empty state educativo
                if (rutinas.isEmpty) {
                  return AppEmpty(
                    icon: Icons.fitness_center_outlined,
                    title: 'Tu primer paso hacia la consistencia',
                    subtitle:
                        'Una rutina bien estructurada es la clave del progreso. '
                        'Organiza tus días de entrenamiento, añade ejercicios y '
                        'el sistema te guiará con sugerencias inteligentes.',
                    actionLabel: 'CREAR MI PRIMERA RUTINA',
                    onAction: () => _navigateToCreate(context),
                  );
                }
                return _RutinasGrid(rutinas: rutinas);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AppFAB(
        onPressed: () => _navigateToCreate(context),
        icon: Icons.add_rounded,
        label: 'Nueva Rutina',
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    HapticFeedback.mediumImpact();
    // Navegar a crear nueva rutina (sin parámetro = modo creación)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateEditRoutineScreen(),
      ),
    );
  }

  Future<void> _showImportFlow(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    // Implementation would go here
  }
}

class _RutinasGrid extends StatelessWidget {
  final List<dynamic> rutinas;

  const _RutinasGrid({required this.rutinas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: rutinas.map((rutina) {
          return _RutinaCard(
            rutina: rutina,
            onTap: () => _navigateToEdit(context, rutina),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, dynamic rutina) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateEditRoutineScreen(rutina: rutina),
      ),
    );
  }
}

class _RutinaCard extends StatelessWidget {
  final dynamic rutina;
  final VoidCallback onTap;

  const _RutinaCard({
    required this.rutina,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    int totalExercises = 0;
    for (final day in rutina.dias) {
      totalExercises += (day?.ejercicios?.length ?? 0) as int;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rutina.nombre,
                    style: AppTypography.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: '${rutina.dias.length} días',
                ),
                const SizedBox(width: AppSpacing.lg),
                _InfoChip(
                  icon: Icons.fitness_center_outlined,
                  label: '$totalExercises ejercicios',
                ),
              ],
            ),
            if (rutina.dias.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: rutina.dias.take(4).map<Widget>((dia) {
                  return Chip(
                    label: Text(
                      dia.nombre,
                      style: AppTypography.labelSmall,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
