import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juan_tracker/training/models/ejercicio_en_rutina.dart';
import 'package:juan_tracker/training/providers/routine_editor_provider.dart';
import 'package:juan_tracker/training/utils/design_system.dart';

/// Widget de ejercicio completamente editable inline
/// 
/// Permite editar todos los parámetros del ejercicio sin navegación:
/// - Nombre (con navegación a búsqueda si se quiere cambiar)
/// - Series y repeticiones
/// - Peso objetivo
/// - RPE objetivo
/// - Notas
class EditableExerciseCard extends ConsumerWidget {
  final int dayIndex;
  final int exerciseIndex;
  final VoidCallback? onReplace;

  const EditableExerciseCard({
    super.key,
    required this.dayIndex,
    required this.exerciseIndex,
    this.onReplace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usar select para evitar rebuilds innecesarios
    final exercise = ref.watch(
      routineEditorProvider(null).select(
        (state) => state.routine.dias[dayIndex].ejercicios[exerciseIndex],
      ),
    );

    return Slidable(
      key: ValueKey(exercise.instanceId),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.5,
        children: [
          // Duplicar
          SlidableAction(
            onPressed: (_) => _duplicate(ref),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.copy,
            label: 'Duplicar',
          ),
          // Eliminar
          SlidableAction(
            onPressed: (_) => _delete(context, ref),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Eliminar',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.grey[900],
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: exercise.supersetId != null 
                ? AppColors.neonPrimary.withAlpha(100)
                : Colors.transparent,
            width: exercise.supersetId != null ? 2 : 0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y menú
              _ExerciseHeader(
                exercise: exercise,
                onReplace: onReplace,
              ),
              
              const SizedBox(height: 12),
              
              // Configuración de series (editable inline)
              _SeriesConfigRow(
                exercise: exercise,
                onChanged: (updated) => _updateExercise(ref, updated),
              ),
              
              const SizedBox(height: 8),
              
              // Fila de opciones adicionales (peso, RPE, descanso)
              _AdvancedOptionsRow(
                exercise: exercise,
                onChanged: (updated) => _updateExercise(ref, updated),
              ),
              
              // Notas (expandible)
              if (exercise.notas?.isNotEmpty == true)
                _NotesDisplay(
                  notes: exercise.notas!,
                  onEdit: () => _showNotesDialog(context, ref, exercise),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateExercise(WidgetRef ref, EjercicioEnRutina updated) {
    ref.read(routineEditorProvider(null).notifier)
        .updateExercise(dayIndex, exerciseIndex, updated);
  }

  void _duplicate(WidgetRef ref) {
    ref.read(routineEditorProvider(null).notifier)
        .duplicateExercise(dayIndex, exerciseIndex);
  }

  void _delete(BuildContext context, WidgetRef ref) {
    // Mostrar undo
    final exercise = ref.read(
      routineEditorProvider(null).select(
        (state) => state.routine.dias[dayIndex].ejercicios[exerciseIndex],
      ),
    );

    ref.read(routineEditorProvider(null).notifier)
        .removeExercise(dayIndex, exerciseIndex);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise.nombre} eliminado'),
        action: SnackBarAction(
          label: 'DESHACER',
          onPressed: () {
            // Reinsertar en el mismo índice
            ref.read(routineEditorProvider(null).notifier).addExercise(
              dayIndex,
              exercise,
            );
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showNotesDialog(BuildContext context, WidgetRef ref, EjercicioEnRutina exercise) {
    final controller = TextEditingController(text: exercise.notas ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Notas',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: GoogleFonts.montserrat(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Notas sobre este ejercicio...',
            hintStyle: GoogleFonts.montserrat(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCELAR', style: GoogleFonts.montserrat()),
          ),
          TextButton(
            onPressed: () {
              _updateExercise(ref, exercise.copyWith(notas: controller.text));
              Navigator.pop(ctx);
            },
            child: Text('GUARDAR', style: GoogleFonts.montserrat()),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _ExerciseHeader extends StatelessWidget {
  final EjercicioEnRutina exercise;
  final VoidCallback? onReplace;

  const _ExerciseHeader({
    required this.exercise,
    this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Indicador de superset
        if (exercise.supersetId != null)
          Container(
            width: 4,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.neonPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        
        // Nombre del ejercicio
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.nombre,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (exercise.equipo.isNotEmpty)
                Text(
                  exercise.equipo,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
            ],
          ),
        ),
        
        // Botón de menú
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          onSelected: (value) {
            switch (value) {
              case 'replace':
                onReplace?.call();
              case 'notes':
                // Manejado por el padre
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'replace',
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 20),
                  const SizedBox(width: 8),
                  Text('Cambiar ejercicio', style: GoogleFonts.montserrat()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'notes',
              child: Row(
                children: [
                  const Icon(Icons.note_add, size: 20),
                  const SizedBox(width: 8),
                  Text('Añadir nota', style: GoogleFonts.montserrat()),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SeriesConfigRow extends StatelessWidget {
  final EjercicioEnRutina exercise;
  final ValueChanged<EjercicioEnRutina> onChanged;

  const _SeriesConfigRow({
    required this.exercise,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Número de series
        _NumberField(
          value: exercise.series,
          label: 'Series',
          min: 1,
          max: 20,
          onChanged: (value) => onChanged(exercise.copyWith(series: value)),
        ),
        
        const SizedBox(width: 12),
        
        // Icono X
        const Icon(Icons.close, color: Colors.white38, size: 16),
        
        const SizedBox(width: 12),
        
        // Rango de repeticiones
        Expanded(
          flex: 2,
          child: _RepsRangeField(
            repsRange: exercise.repsRange,
            onChanged: (value) => onChanged(exercise.copyWith(repsRange: value)),
          ),
        ),
      ],
    );
  }
}

class _AdvancedOptionsRow extends StatelessWidget {
  final EjercicioEnRutina exercise;
  final ValueChanged<EjercicioEnRutina> onChanged;

  const _AdvancedOptionsRow({
    required this.exercise,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Descanso
        _DurationChip(
          icon: Icons.timer_outlined,
          value: exercise.descansoSugerido,
          label: 'Descanso',
          onTap: () async {
            final current = exercise.descansoSugerido ?? const Duration(minutes: 2);
            final minutes = await _showDurationPicker(context, current);
            if (minutes != null) {
              onChanged(exercise.copyWith(descansoSugerido: Duration(minutes: minutes)));
            }
          },
        ),
        
        const SizedBox(width: 8),
        
        // RPE objetivo
        _RpeChip(
          value: exercise.targetRpe,
          onTap: () async {
            final rpe = await _showRpePicker(context, exercise.targetRpe);
            if (rpe != null) {
              onChanged(exercise.copyWith(targetRpe: rpe));
            }
          },
        ),
        
        // Botón de notas
        IconButton(
          icon: Icon(
            exercise.notas?.isNotEmpty == true 
                ? Icons.note 
                : Icons.note_add_outlined,
            color: exercise.notas?.isNotEmpty == true 
                ? AppColors.neonPrimary 
                : Colors.white54,
            size: 20,
          ),
          onPressed: () {
            // El padre maneja esto
          },
        ),
      ],
    );
  }

  Future<int?> _showDurationPicker(BuildContext context, Duration current) async {
    final options = [30, 60, 90, 120, 150, 180, 240, 300];
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Descanso entre series',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: options.map((seconds) {
                final isSelected = current.inSeconds == seconds;
                return ChoiceChip(
                  label: Text(
                    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.neonPrimary,
                  onSelected: (_) => Navigator.pop(ctx, seconds),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    return selected;
  }

  Future<int?> _showRpePicker(BuildContext context, int? current) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'RPE Objetivo',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              'Perceived Exertion (6-10)',
              style: GoogleFonts.montserrat(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(5, (i) {
                final rpe = i + 6;
                final isSelected = current == rpe;
                return ChoiceChip(
                  label: Text('$rpe'),
                  selected: isSelected,
                  selectedColor: _rpeColor(rpe),
                  onSelected: (_) => Navigator.pop(ctx, rpe),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    return selected;
  }

  Color _rpeColor(int rpe) {
    if (rpe <= 6) return Colors.green;
    if (rpe <= 7) return Colors.yellow;
    if (rpe <= 8) return Colors.orange;
    return Colors.red;
  }
}

class _NotesDisplay extends StatelessWidget {
  final String notes;
  final VoidCallback onEdit;

  const _NotesDisplay({
    required this.notes,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.note, size: 16, color: Colors.white54),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notes,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.white70,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS REUTILIZABLES
// ═══════════════════════════════════════════════════════════════════════════

class _NumberField extends StatelessWidget {
  final int value;
  final String label;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.value,
    required this.label,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _RepsRangeField extends StatefulWidget {
  final String repsRange;
  final ValueChanged<String> onChanged;

  const _RepsRangeField({
    required this.repsRange,
    required this.onChanged,
  });

  @override
  State<_RepsRangeField> createState() => _RepsRangeFieldState();
}

class _RepsRangeFieldState extends State<_RepsRangeField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.repsRange);
  }

  @override
  void didUpdateWidget(covariant _RepsRangeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repsRange != widget.repsRange && 
        widget.repsRange != _controller.text) {
      _controller.text = widget.repsRange;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: '8-12',
          hintStyle: GoogleFonts.montserrat(color: Colors.white30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
          label: Center(
            child: Text(
              'Reps',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Colors.white54,
              ),
            ),
          ),
          floatingLabelAlignment: FloatingLabelAlignment.center,
        ),
        onChanged: (value) {
          // Validar formato: número, guion opcional, número opcional
          final clean = value.replaceAll(RegExp(r'[^0-9-]'), '');
          if (clean != value) {
            _controller.text = clean;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: clean.length),
            );
          }
          widget.onChanged(clean);
        },
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final IconData icon;
  final Duration? value;
  final String label;
  final VoidCallback onTap;

  const _DurationChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value != null 
        ? '${value!.inMinutes}:${(value!.inSeconds % 60).toString().padLeft(2, '0')}'
        : '2:00';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white54),
            const SizedBox(width: 4),
            Text(
              displayValue,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: value != null ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RpeChip extends StatelessWidget {
  final int? value;
  final VoidCallback onTap;

  const _RpeChip({
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value != null ? _rpeBackgroundColor(value!) : Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RPE',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: value != null ? Colors.white70 : Colors.white38,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value?.toString() ?? '-',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: value != null ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _rpeBackgroundColor(int rpe) {
    if (rpe <= 6) return Colors.green.withAlpha(50);
    if (rpe <= 7) return Colors.yellow.withAlpha(50);
    if (rpe <= 8) return Colors.orange.withAlpha(50);
    return Colors.red.withAlpha(50);
  }
}
