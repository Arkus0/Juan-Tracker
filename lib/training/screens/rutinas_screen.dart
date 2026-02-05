import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import '../providers/training_provider.dart';
import '../widgets/routine_template_sheet.dart';

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
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: HomeButton(),
            ),
            title: const Text('Mis Rutinas'),
            centerTitle: true,
            actions: [
              // 🆕 Botón de plantillas predefinidas
              IconButton(
                icon: const Icon(Icons.library_books_outlined),
                tooltip: 'Usar plantilla',
                onPressed: () => _showTemplates(context, ref),
              ),
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
                // 🎯 MED-006: Empty state educativo con plantillas
                if (rutinas.isEmpty) {
                  return _EmptyRoutinesState(
                    onCreateNew: () => _navigateToCreate(context),
                    onUseTemplate: () => _showTemplates(context, ref),
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

  Future<void> _showTemplates(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final rutina = await RoutineTemplateSheet.show(context);
    
    if (rutina != null && context.mounted) {
      // Guardar la rutina en el repositorio
      await ref.read(trainingRepositoryProvider).saveRutina(rutina);
      
      // Mostrar confirmación
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: '✓ Rutina "${rutina.nombre}" añadida',
        );
      }
    }
  }

  Future<void> _showImportFlow(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    // Implementation would go here
  }
}

/// Empty state con dos CTAs: crear nueva o usar plantilla
class _EmptyRoutinesState extends StatelessWidget {
  final VoidCallback onCreateNew;
  final VoidCallback onUseTemplate;

  const _EmptyRoutinesState({
    required this.onCreateNew,
    required this.onUseTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          Icon(
            Icons.fitness_center_outlined,
            size: 72,
            color: colors.onSurfaceVariant.withAlpha((0.5 * 255).round()),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tu primer paso hacia la consistencia',
            style: AppTypography.headlineSmall.copyWith(
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Elige una plantilla probada o crea tu propia rutina personalizada',
            style: AppTypography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // CTA Principal: Usar plantilla (más rápido)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onUseTemplate,
              icon: const Icon(Icons.library_books_rounded),
              label: const Text('USAR PLANTILLA'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Texto informativo
          Text(
            '+68 rutinas probadas • Clásicas, PPL, Full Body y más',
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Separador
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: colors.outline.withAlpha((0.5 * 255).round()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'o',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: colors.outline.withAlpha((0.5 * 255).round()),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // CTA Secundario: Crear desde cero
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.add_rounded),
              label: const Text('CREAR DESDE CERO'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
            ),
          ),
        ],
      ),
    );
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
