import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/widgets/widgets.dart';
import '../models/routine_template.dart';
import '../models/rutina.dart';
import '../providers/routine_template_provider.dart';
import '../services/routine_template_service.dart';

/// Bottom sheet para explorar y seleccionar plantillas de rutinas.
/// 
/// Muestra las plantillas organizadas por categoría con filtros y búsqueda.
class RoutineTemplateSheet extends ConsumerStatefulWidget {
  const RoutineTemplateSheet({super.key});

  /// Muestra el bottom sheet y retorna la rutina seleccionada (o null)
  static Future<Rutina?> show(BuildContext context) {
    return showModalBottomSheet<Rutina>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RoutineTemplateSheet(),
    );
  }

  @override
  ConsumerState<RoutineTemplateSheet> createState() => _RoutineTemplateSheetState();
}

class _RoutineTemplateSheetState extends ConsumerState<RoutineTemplateSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final templatesAsync = ref.watch(filteredTemplatesProvider);
    final categories = ref.watch(templateCategoriesProvider);
    final filter = ref.watch(templateFilterProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.md),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Título
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      Icons.library_books_rounded,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plantillas de Rutinas',
                            style: AppTypography.titleLarge,
                          ),
                          Text(
                            'Elige una rutina y empieza a entrenar',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (filter.hasFilters)
                      IconButton(
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        onPressed: () {
                          ref.read(templateFilterProvider.notifier).clearFilters();
                          _searchController.clear();
                        },
                        tooltip: 'Limpiar filtros',
                      ),
                  ],
                ),
              ),

              // Búsqueda
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar rutinas...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(templateFilterProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onChanged: (value) {
                    ref.read(templateFilterProvider.notifier).setSearchQuery(value);
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Filtros de categoría
              categories.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (cats) => SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: cats.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = filter.categoryId == null;
                        return _FilterChip(
                          label: 'Todas',
                          isSelected: isSelected,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(templateFilterProvider.notifier).setCategory(null);
                          },
                        );
                      }
                      final cat = cats[index - 1];
                      final isSelected = filter.categoryId == cat.id;
                      final count = ref.watch(templateCountByCategoryProvider)[cat.id] ?? 0;
                      return _FilterChip(
                        label: '${cat.nombre} ($count)',
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(templateFilterProvider.notifier).setCategory(
                            isSelected ? null : cat.id,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Lista de plantillas
              Expanded(
                child: templatesAsync.when(
                  loading: () => const AppLoading(message: 'Cargando plantillas...'),
                  error: (err, _) => AppError(
                    message: 'Error al cargar plantillas',
                    details: err.toString(),
                    onRetry: () => ref.invalidate(routineTemplatesProvider),
                  ),
                  data: (templates) {
                    if (templates.isEmpty) {
                      return AppEmpty(
                        icon: Icons.search_off_rounded,
                        title: 'Sin resultados',
                        subtitle: 'No hay plantillas que coincidan con tu búsqueda',
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      itemCount: templates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return _TemplateCard(
                          template: template,
                          onTap: () => _selectTemplate(context, template),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectTemplate(BuildContext context, RoutineTemplate template) {
    HapticFeedback.mediumImpact();
    
    // Mostrar dialog de confirmación con preview
    showDialog(
      context: context,
      builder: (ctx) => _TemplatePreviewDialog(
        template: template,
        onConfirm: () {
          Navigator.pop(ctx); // Cerrar dialog
          final rutina = RoutineTemplateService.instance.convertToRutina(template);
          Navigator.pop(context, rutina); // Retornar rutina
        },
      ),
    );
  }
}

/// Chip de filtro
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colors.primaryContainer : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Card de plantilla
class _TemplateCard extends StatelessWidget {
  final RoutineTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final service = RoutineTemplateService.instance;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  template.nombre,
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _LevelBadge(level: template.nivel),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Descripción
          Text(
            template.descripcion,
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.md),

          // Stats
          Row(
            children: [
              _StatChip(
                icon: Icons.calendar_today_outlined,
                label: '${template.diasPorSemana} días/sem',
              ),
              const SizedBox(width: AppSpacing.md),
              _StatChip(
                icon: Icons.fitness_center_outlined,
                label: '${template.totalEjercicios} ejercicios',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  service.getCategoryName(template.categoria),
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge de nivel
class _LevelBadge extends StatelessWidget {
  final String level;

  const _LevelBadge({required this.level});

  Color _getColor(ColorScheme colors) {
    switch (level) {
      case 'principiante':
        return AppColors.success;
      case 'intermedio':
        return AppColors.warning;
      case 'avanzado':
        return colors.error;
      default:
        return colors.outline;
    }
  }

  String _getLabel() {
    switch (level) {
      case 'principiante':
        return 'Principiante';
      case 'intermedio':
        return 'Intermedio';
      case 'avanzado':
        return 'Avanzado';
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _getColor(colors);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        _getLabel(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Chip de estadística
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
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

/// Dialog de preview de plantilla
class _TemplatePreviewDialog extends StatelessWidget {
  final RoutineTemplate template;
  final VoidCallback onConfirm;

  const _TemplatePreviewDialog({
    required this.template,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(
        template.nombre,
        style: AppTypography.titleLarge,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                template.descripcion,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Estructura de la rutina:',
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ...template.dias.map((dia) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dia.nombre,
                      style: AppTypography.titleSmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${dia.ejercicios.length} ejercicios',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Usar plantilla'),
        ),
      ],
    );
  }
}
