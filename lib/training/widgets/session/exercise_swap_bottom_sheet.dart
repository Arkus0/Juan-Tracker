import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../models/ejercicio.dart';
import '../../models/library_exercise.dart';
import '../../providers/exercise_alternatives_provider.dart';

/// {@template exercise_swap_bottom_sheet}
/// Bottom sheet para sustituir un ejercicio durante una sesión activa.
///
/// Muestra alternativas basadas en:
/// 1. Mapeo explícito de alternativas.json
/// 2. Fallback por grupos musculares compartidos
/// 3. Priorización por equipment similar
///
/// El swap preserva (opcionalmente) las series completadas como sugerencias.
/// {@endtemplate}
class ExerciseSwapBottomSheet extends ConsumerStatefulWidget {
  final Ejercicio currentExercise;
  final int exerciseIndex;
  final Function(LibraryExercise selected) onSwapSelected;

  const ExerciseSwapBottomSheet({
    super.key,
    required this.currentExercise,
    required this.exerciseIndex,
    required this.onSwapSelected,
  });

  /// Muestra el bottom sheet de swap y retorna la alternativa seleccionada
  static Future<LibraryExercise?> show(
    BuildContext context, {
    required Ejercicio currentExercise,
    required int exerciseIndex,
    required Function(LibraryExercise selected) onSwapSelected,
  }) async {
    return showModalBottomSheet<LibraryExercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseSwapBottomSheet(
        currentExercise: currentExercise,
        exerciseIndex: exerciseIndex,
        onSwapSelected: onSwapSelected,
      ),
    );
  }

  @override
  ConsumerState<ExerciseSwapBottomSheet> createState() =>
      _ExerciseSwapBottomSheetState();
}

class _ExerciseSwapBottomSheetState
    extends ConsumerState<ExerciseSwapBottomSheet> {
  String? _selectedEquipment;
  final List<String> _commonEquipment = [
    'barra',
    'mancuernas',
    'maquina',
    'cuerpo libre',
    'cables',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    // Obtener ID del library exercise actual
    final libraryId = int.tryParse(widget.currentExercise.libraryId);
    
    // Preparar grupos musculares para búsqueda
    final muscleGroups = [
      ...widget.currentExercise.musculosPrincipales,
      ...widget.currentExercise.musculosSecundarios,
    ];

    // Watch alternativas
    final alternativesAsync = libraryId != null
        ? ref.watch(exerciseAlternativesProvider((
            exerciseId: libraryId,
            muscleGroups: muscleGroups,
            equipment: null, // Sin preferencia de equipment específica
          )))
        : <LibraryExercise>[];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUSTITUIR EJERCICIO',
                            style: AppTypography.labelLarge.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.currentExercise.nombre,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.fitness_center,
                      label: widget.currentExercise.musculosPrincipales.join(", "),
                      color: colors.primary,
                    ),
                    _InfoChip(
                      icon: Icons.format_list_numbered,
                      label: '${widget.currentExercise.logs.length} series',
                      color: colors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Filter por equipment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FILTRAR POR EQUIPO',
                  style: AppTypography.labelMedium.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // "Todos" option
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Todos'),
                          selected: _selectedEquipment == null,
                          onSelected: (_) => setState(
                            () => _selectedEquipment = null,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      // Equipment options
                      ..._commonEquipment.map((equipment) {
                        final isSelected = _selectedEquipment == equipment;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_capitalize(equipment)),
                            selected: isSelected,
                            onSelected: (_) => setState(
                              () => _selectedEquipment = isSelected ? null : equipment,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de alternativas
          Flexible(
            child: _buildAlternativesList(alternativesAsync, colors),
          ),

          // Bottom padding
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildAlternativesList(
    List<LibraryExercise> alternatives,
    ColorScheme colors,
  ) {
    if (alternatives.isEmpty) {
      return _buildEmptyState(colors);
    }

    // Aplicar filtro de equipment si está seleccionado
    final filteredAlternatives = _selectedEquipment != null
        ? alternatives
            .where((e) =>
                e.equipment.toLowerCase() == _selectedEquipment!.toLowerCase())
            .toList()
        : alternatives;

    if (filteredAlternatives.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 48,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay alternativas con ese equipo',
              style: AppTypography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedEquipment = null),
              child: const Text('Mostrar todos'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredAlternatives.length,
      itemBuilder: (context, index) {
        final exercise = filteredAlternatives[index];
        // Recomendar el primero de la lista (ya ordenados por relevancia)
        final isRecommended = index == 0;

        return _AlternativeTile(
          exercise: exercise,
          isRecommended: isRecommended,
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onSwapSelected(exercise);
            Navigator.of(context).pop(exercise);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colors.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron alternativas',
            style: AppTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta buscar manualmente en la biblioteca',
            style: AppTypography.bodyMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Navegar a búsqueda manual
              // Esto se manejaría desde el caller
            },
            icon: const Icon(Icons.library_books),
            label: const Text('Abrir biblioteca'),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Chip informativo del ejercicio actual
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de alternativa individual
class _AlternativeTile extends StatelessWidget {
  final LibraryExercise exercise;
  final bool isRecommended;
  final VoidCallback onTap;

  const _AlternativeTile({
    required this.exercise,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: isRecommended
          ? colors.primaryContainer.withValues(alpha: 0.3)
          : colors.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecommended
            ? BorderSide(color: colors.primary.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Equipment icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEquipmentIcon(exercise.equipment),
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 16),

              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name.toUpperCase(),
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        _MetaChip(
                          label: exercise.equipment,
                          icon: Icons.fitness_center,
                        ),
                        if (exercise.muscles.isNotEmpty)
                          _MetaChip(
                            label: exercise.muscles.first,
                            icon: Icons.accessibility_new,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Recommended badge or arrow
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'IDEAL',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getEquipmentIcon(String equipment) {
    final normalized = equipment.toLowerCase();
    if (normalized.contains('barra')) return Icons.linear_scale;
    if (normalized.contains('mancuerna')) return Icons.donut_large;
    if (normalized.contains('maquina')) return Icons.precision_manufacturing;
    if (normalized.contains('cable')) return Icons.settings_ethernet;
    if (normalized.contains('cuerpo')) return Icons.person;
    return Icons.fitness_center;
  }
}

/// Chip metadatos pequeño
class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          _capitalize(label),
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
