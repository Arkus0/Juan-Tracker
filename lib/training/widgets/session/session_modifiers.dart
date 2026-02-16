import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../models/ejercicio_en_rutina.dart';
import '../../models/library_exercise.dart';
import '../../providers/training_provider.dart';
import '../../screens/create_routine/widgets/biblioteca_bottom_sheet.dart';

/// Botón compacto para añadir una serie adicional a un ejercicio
class AddSetButton extends ConsumerWidget {
  final int exerciseIndex;

  const AddSetButton({super.key, required this.exerciseIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          ref
              .read(trainingSessionProvider.notifier)
              .addSetToExercise(exerciseIndex);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text('Serie añadida', style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0.8,
                  )),
                ],
              ),
              backgroundColor: AppColors.bgElevated,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.bgInteractive.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'AÑADIR SERIE',
                style: AppTypography.sectionLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón para añadir un nuevo ejercicio a la sesión activa
class AddExerciseButton extends ConsumerWidget {
  const AddExerciseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddExerciseSheet(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.techCyan.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.bgElevated.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.techCyan,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'AÑADIR EJERCICIO',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppColors.techCyan,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => BibliotecaBottomSheet(
          onAdd: (libExercise) {
            Navigator.pop(sheetContext);
            // Añadir directamente a la sesión (sin dialog intermedio)
            ref
                .read(trainingSessionProvider.notifier)
                .addExerciseToSession(libExercise);

            if (!context.mounted) return;

            // Ofrecer guardar en rutina como acción secundaria del snackbar
            final state = ref.read(trainingSessionProvider);
            final hasActiveRoutine =
                state.activeRutina != null && state.dayIndex != null;

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${libExercise.name} añadido',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                action: hasActiveRoutine
                    ? SnackBarAction(
                        label: 'GUARDAR EN RUTINA',
                        textColor: Colors.white,
                        onPressed: () =>
                            _saveExerciseToRoutine(context, ref, libExercise),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Guarda el ejercicio también en la rutina activa (acción opcional).
  Future<void> _saveExerciseToRoutine(
    BuildContext context,
    WidgetRef ref,
    LibraryExercise exercise,
  ) async {
    final state = ref.read(trainingSessionProvider);
    if (state.activeRutina == null || state.dayIndex == null) return;

    final rutina = state.activeRutina!;
    final dayIndex = state.dayIndex!;

    if (dayIndex < rutina.dias.length) {
      final newExercise = EjercicioEnRutina(
        id: exercise.id.toString(),
        nombre: exercise.name,
        descripcion: exercise.description,
        musculosPrincipales: exercise.muscles,
        musculosSecundarios: exercise.secondaryMuscles,
        equipo: exercise.equipment,
        localImagePath: exercise.localImagePath,
      );

      final updatedDay = rutina.dias[dayIndex].copyWith(
        ejercicios: [...rutina.dias[dayIndex].ejercicios, newExercise],
      );

      final newDias = [...rutina.dias];
      newDias[dayIndex] = updatedDay;
      final updatedRutina = rutina.copyWith(dias: newDias);

      await ref.read(trainingRepositoryProvider).saveRutina(updatedRutina);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Guardado en rutina',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0.8,
              ),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
