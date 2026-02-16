import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/design_system/design_system.dart';
import 'package:juan_tracker/training/models/ejercicio_en_rutina.dart';
import 'package:juan_tracker/training/models/library_exercise.dart';
import 'package:juan_tracker/training/models/training_set_type.dart';
import 'package:juan_tracker/training/services/alternativas_service.dart';
import 'package:juan_tracker/training/services/exercise_library_service.dart';
import 'package:juan_tracker/training/widgets/common/alternativas_dialog.dart';

/// Payload passed through drag events so the parent knows which item is moving.
class SupersetDragData {
  final int visualIndex;
  final int flatIndex;
  final String? supersetId;

  const SupersetDragData({
    required this.visualIndex,
    required this.flatIndex,
    this.supersetId,
  });
}

/// Payload for simple reorder drags (single exercise)
class ReorderDragData {
  final int flatIndex;

  const ReorderDragData({required this.flatIndex});
}

class EjercicioCard extends StatefulWidget {
  final EjercicioEnRutina ejercicio;
  final Function() onRemove;
  final Function(EjercicioEnRutina) onUpdate;
  final Function(String alternativaNombre)? onReplace;
  final Function()? onUnlink;
  final Function()? onDuplicate; // 🆕 Para duplicar ejercicio

  const EjercicioCard({
    super.key,
    required this.ejercicio,
    required this.onRemove,
    required this.onUpdate,
    this.onReplace,
    this.onUnlink,
    this.onDuplicate, // 🆕
  });

  @override
  State<EjercicioCard> createState() => _EjercicioCardState();
}

class _EjercicioCardState extends State<EjercicioCard> {
  late TextEditingController _seriesController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _seriesController = TextEditingController(
      text: widget.ejercicio.series.toString(),
    );
    _repsController = TextEditingController(text: widget.ejercicio.repsRange);
  }

  @override
  void didUpdateWidget(EjercicioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if the value changed externally AND differs from current controller text
    // This prevents cursor jumping when the user is actively typing
    if (oldWidget.ejercicio.series != widget.ejercicio.series) {
      final currentText = _seriesController.text;
      final newText = widget.ejercicio.series.toString();
      if (currentText != newText) {
        final selection = _seriesController.selection;
        _seriesController.text = newText;
        // Restore cursor position if valid
        if (selection.isValid && selection.end <= newText.length) {
          _seriesController.selection = selection;
        }
      }
    }
    if (oldWidget.ejercicio.repsRange != widget.ejercicio.repsRange) {
      final currentText = _repsController.text;
      final newText = widget.ejercicio.repsRange;
      if (currentText != newText) {
        final selection = _repsController.selection;
        _repsController.text = newText;
        // Restore cursor position if valid
        if (selection.isValid && selection.end <= newText.length) {
          _repsController.selection = selection;
        }
      }
    }
  }

  @override
  void dispose() {
    _seriesController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _showAlternativasDialog(
    BuildContext context,
    LibraryExercise? libExercise,
  ) {
    final scheme = Theme.of(context).colorScheme;

    if (libExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: No se encontró información del ejercicio en la biblioteca',
          ),
        ),
      );
      return;
    }

    // Obtenemos la lista completa de ejercicios para que el servicio pueda buscar
    final allExercises = ExerciseLibraryService.instance.exercises
        .cast<LibraryExercise>();

    showAlternativasDialog(
      context: context,
      ejercicioOriginal: libExercise,
      allExercises: allExercises,
      onReplace: (LibraryExercise seleccion) {
        try {
          HapticFeedback.vibrate();
        } catch (_) {}

        if (widget.onReplace != null) {
          widget.onReplace!(seleccion.name);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reemplazado por ${seleccion.name}',
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            backgroundColor: scheme.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _showProOptions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OPCIONES: ${widget.ejercicio.nombre}',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              if (widget.onUnlink != null)
                ListTile(
                  leading: Icon(Icons.link_off, color: scheme.tertiary),
                  title: Text(
                    'DESVINCULAR (ROMPER SUPERSERIE)',
                    style: TextStyle(
                      color: scheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.onUnlink!();
                  },
                ),

              TextFormField(
                initialValue: widget.ejercicio.notas,
                style: TextStyle(color: scheme.onSurface),
                decoration: const InputDecoration(
                  labelText: 'Notas / RPE / Tempo',
                ),
                onChanged: (val) {
                  widget.onUpdate(widget.ejercicio.copyWith(notas: val));
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tipo de serie',
                  style: AppTypography.bodyCompact.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: TrainingSetType.values.map((type) {
                  final selected = widget.ejercicio.setType == type;
                  return ChoiceChip(
                    label: Text(type.label.toUpperCase()),
                    selected: selected,
                    onSelected: (_) {
                      widget.onUpdate(
                        widget.ejercicio.copyWith(setType: type),
                      );
                    },
                    selectedColor: scheme.primaryContainer,
                    backgroundColor: scheme.surfaceContainerHighest,
                    labelStyle: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Rest Time
              Row(
                children: [
                  Text(
                    'Descanso (seg): ',
                    style: TextStyle(color: scheme.onSurface),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          widget.ejercicio.descansoSugerido?.inSeconds
                              .toString() ??
                          '60',
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: scheme.onSurface),
                      onChanged: (val) {
                        final sec = int.tryParse(val);
                        if (sec != null) {
                          widget.onUpdate(
                            widget.ejercicio.copyWith(
                              descansoSugerido: Duration(seconds: sec),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  widget.onRemove();
                },
                icon: Icon(Icons.delete, color: scheme.onError),
                label: const Text('ELIMINAR EJERCICIO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Lookup library exercise by library ID (more reliable than matching by name)
    final libId = int.tryParse(widget.ejercicio.id);
    final libraryExercise = libId == null
        ? null
        : ExerciseLibraryService.instance.exercises
              .cast<LibraryExercise?>()
              .firstWhere((e) => e?.id == libId, orElse: () => null);

    final imageWidget = _buildImage(scheme, libraryExercise);

    // Verificar si hay alternativas usando el ID entero
    final tieneAlternativas =
        libId != null && AlternativasService.instance.hasAlternativas(libId);

    final cardContent = Card(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Drag Handle (reorder handled by parent)
            Icon(Icons.drag_indicator, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),

            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: imageWidget,
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ejercicio.nombre.toUpperCase(),
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.ejercicio.musculosPrincipales.join(', '),
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (!widget.ejercicio.setType.isDefault) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        widget.ejercicio.setType.shortLabel,
                        style: AppTypography.micro.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onPrimaryContainer,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Series x Reps Inputs with controllers to prevent focus loss
                  Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: TextField(
                          controller: _seriesController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: scheme.outline),
                            ),
                          ),
                          onChanged: (val) {
                            final s = int.tryParse(val);
                            if (s != null) {
                              widget.onUpdate(
                                widget.ejercicio.copyWith(series: s),
                              );
                            }
                          },
                        ),
                      ),
                      Text(
                        ' x ',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _repsController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: scheme.outline),
                            ),
                          ),
                          onChanged: (val) {
                            widget.onUpdate(
                              widget.ejercicio.copyWith(repsRange: val),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Alternatives button
            if (tieneAlternativas)
              IconButton(
                icon: Icon(Icons.swap_horiz, color: scheme.tertiary, size: 20),
                onPressed: () =>
                    _showAlternativasDialog(context, libraryExercise),
                visualDensity: VisualDensity.compact,
                tooltip: 'Ver alternativas',
              ),

            // Info Icon / Menu
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () => _showProOptions(context),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );

    // 🆕 Envolver en Slidable para swipe actions
    // El LongPressDraggable para superseries está en dia_expansion_tile.dart
    return Slidable(
      key: ValueKey(widget.ejercicio.id),
      // Swipe derecha: Duplicar (acción constructiva)
      startActionPane: widget.onDuplicate != null
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    HapticFeedback.mediumImpact();
                    widget.onDuplicate!();
                  },
                  backgroundColor: AppColors.completedGreen,
                  foregroundColor: Colors.white,
                  icon: Icons.copy,
                  label: 'Duplicar',
                ),
              ],
            )
          : null,
      // Swipe izquierda: Eliminar (acción destructiva)
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              widget.onRemove();
            },
            backgroundColor: scheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Eliminar',
          ),
        ],
      ),
      child: cardContent,
    );
  }

  Widget _buildImage(ColorScheme scheme, LibraryExercise? libExercise) {
    if (libExercise != null &&
        libExercise.localImagePath != null &&
        libExercise.localImagePath!.isNotEmpty) {
      final file = File(libExercise.localImagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          cacheWidth: 120,
          cacheHeight: 120,
          errorBuilder: (ctx, err, stack) => Icon(
            Icons.fitness_center,
            color: scheme.onSurfaceVariant,
            size: 30,
          ),
        );
      }
    }

    if (libExercise != null && libExercise.imageUrls.isNotEmpty) {
      return Image.network(
        libExercise.imageUrls.first,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        // Cache en memoria para evitar re-descargas
        cacheWidth: 120, // 2x para retina
        cacheHeight: 120,
        errorBuilder: (ctx, err, stack) => Icon(
          Icons.fitness_center,
          color: scheme.onSurfaceVariant,
          size: 30,
        ),
      );
    }

    return Container(
      width: 60,
      height: 60,
      color: scheme.surface,
      alignment: Alignment.center,
      child: Icon(
        Icons.fitness_center,
        color: scheme.onSurfaceVariant,
        size: 30,
      ),
    );
  }
}
