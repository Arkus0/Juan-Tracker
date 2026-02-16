import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/design_system.dart';
import '../../models/library_exercise.dart';
import '../../services/alternativas_service.dart';

/// Dialog que muestra las alternativas para un ejercicio.
class AlternativasDialog extends StatelessWidget {
  final LibraryExercise ejercicioOriginal;
  final List<LibraryExercise> allExercises;
  // Callback devuelve el objeto completo seleccionado
  final void Function(LibraryExercise seleccion) onReplace;
  final VoidCallback? onCancel;

  const AlternativasDialog({
    super.key,
    required this.ejercicioOriginal,
    required this.allExercises,
    required this.onReplace,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenemos los objetos reales usando el servicio
    final alternativas = AlternativasService.instance.getAlternativas(
      exerciseId: ejercicioOriginal.id,
      allExercises: allExercises,
    );

    return AlertDialog(
      backgroundColor: AppColors.bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.live.withValues(alpha: 0.5)),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz,
                color: AppColors.neonPrimary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ALTERNATIVAS',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ejercicioOriginal.name.toUpperCase(),
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.neonPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: alternativas.isEmpty
            ? _buildEmptyState()
            : _buildAlternativasList(context, alternativas),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          child: Text(
            'CERRAR',
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            'Sin alternativas registradas',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativasList(
    BuildContext context,
    List<LibraryExercise> alternativas,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: alternativas.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.bgDeep),
      itemBuilder: (context, index) {
        final alternativa = alternativas[index];
        return _AlternativaItem(
          exercise: alternativa,
          isFirst: index == 0,
          onTap: () {
            try {
              HapticFeedback.selectionClick();
            } catch (_) {}
            Navigator.pop(context);
            onReplace(alternativa);
          },
        );
      },
    );
  }
}

class _AlternativaItem extends StatelessWidget {
  final LibraryExercise exercise;
  final bool isFirst;
  final VoidCallback onTap;

  const _AlternativaItem({
    required this.exercise,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name.toUpperCase(),
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isFirst ? Colors.white : Colors.white38,
                    ),
                  ),
                  if (exercise.equipment.isNotEmpty)
                    Text(
                      exercise.equipment,
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textTertiary,
                        letterSpacing: 0,
                      ),
                    ),
                  if (isFirst)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'RECOMENDADA',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.neonPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.live.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.live.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'CAMBIAR',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.redAccent[100],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Función helper actualizada para requerir los objetos
Future<void> showAlternativasDialog({
  required BuildContext context,
  required LibraryExercise ejercicioOriginal,
  required List<LibraryExercise> allExercises,
  required void Function(LibraryExercise seleccion) onReplace,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlternativasDialog(
      ejercicioOriginal: ejercicioOriginal,
      allExercises: allExercises,
      onReplace: onReplace,
    ),
  );
}
