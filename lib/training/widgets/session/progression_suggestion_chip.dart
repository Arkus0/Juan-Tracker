import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../models/progression_engine_models.dart';
import '../../providers/progression_provider.dart';
import '../../providers/training_provider.dart';

/// Chip prominente y accionable para sugerencias de progresión
///
/// Muestra la sugerencia del motor de progresión de forma clara y permite
/// aplicarla con un solo tap al primer set incompleto del ejercicio.
///
/// Diseño:
/// - Visible inmediatamente al expandir un ejercicio con historial suficiente
/// - Muestra icono de tendencia y texto corto: "Siguiente: 82.5kg × 5"
/// - Background con color primario al 15% de opacidad
/// - Tocable para aplicar la sugerencia al primer set incompleto
class ProgressionSuggestionChip extends ConsumerWidget {
  final int exerciseIndex;
  final VoidCallback? onApply;

  const ProgressionSuggestionChip({
    super.key,
    required this.exerciseIndex,
    this.onApply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decision = ref.watch(exerciseProgressionProvider(exerciseIndex));
    final sessionState = ref.watch(trainingSessionProvider);

    // No mostrar si no hay decisión o no hay suficiente historial
    if (decision == null) return const SizedBox.shrink();
    if (!_hasEnoughHistory(decision)) return const SizedBox.shrink();

    // Encontrar el primer set incompleto
    if (exerciseIndex >= sessionState.exercises.length) {
      return const SizedBox.shrink();
    }

    final exercise = sessionState.exercises[exerciseIndex];
    final firstIncompleteIndex = exercise.logs.indexWhere((log) => !log.completed);

    // Si todas las series están completadas, no mostrar el chip
    if (firstIncompleteIndex == -1) return const SizedBox.shrink();

    return _ProgressionChipContent(
      decision: decision,
      onApply: () => _applySuggestion(ref, context, decision, firstIncompleteIndex),
    );
  }

  /// Determina si hay suficiente historial para mostrar la sugerencia
  /// Requiere al menos 3 sesiones de historial (no calibración)
  bool _hasEnoughHistory(ProgressionDecision decision) {
    // No mostrar durante fase de calibración
    if (decision.reason.contains('Calibración') ||
        decision.reason.contains('calibración') ||
        decision.reason.contains('Sesion 1') ||
        decision.reason.contains('Sesion 2') ||
        decision.reason.contains('Calibrando')) {
      return false;
    }

    // No mostrar si el mensaje indica calibración
    if (decision.userMessage.contains('calibración') ||
        decision.userMessage.contains('baseline') ||
        decision.userMessage.contains('Sesion 1') ||
        decision.userMessage.contains('Sesion 2')) {
      return false;
    }

    return true;
  }

  /// Aplica la sugerencia al primer set incompleto
  void _applySuggestion(
    WidgetRef ref,
    BuildContext context,
    ProgressionDecision decision,
    int setIndex,
  ) {
    final notifier = ref.read(trainingSessionProvider.notifier);

    // Aplicar peso y reps sugeridos
    notifier.updateLog(
      exerciseIndex,
      setIndex,
      peso: decision.suggestedWeight,
      reps: decision.suggestedReps,
    );

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Mostrar snackbar de confirmación
    if (context.mounted) {
      final weightText = _formatWeight(decision.suggestedWeight);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Aplicado: ${weightText}kg × ${decision.suggestedReps}',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    }

    // Llamar callback opcional
    onApply?.call();
  }

  String _formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }
}

/// Widget interno que renderiza el contenido visual del chip
class _ProgressionChipContent extends StatelessWidget {
  final ProgressionDecision decision;
  final VoidCallback onApply;

  const _ProgressionChipContent({
    required this.decision,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final weightText = _formatWeight(decision.suggestedWeight);
    final hasNextStep = decision.nextStepPreview != null &&
                        decision.nextStepPreview!.isNotEmpty;

    return GestureDetector(
      onTap: onApply,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha((0.15 * 255).round()),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.primary.withAlpha((0.30 * 255).round()),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icono de tendencia
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.20 * 255).round()),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                _getIconForAction(decision.action),
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),

            // Contenido principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Línea principal: "Siguiente: 82.5kg × 5"
                  Text(
                    'Siguiente: ${weightText}kg × ${decision.suggestedReps}',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),

                  // Preview del siguiente paso si existe
                  if (hasNextStep) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Si lo logras → ${_getShortNextStep(decision.nextStepPreview!)}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary.withAlpha((0.80 * 255).round()),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Botón de aplicar
            FilledButton.tonalIcon(
              onPressed: onApply,
              icon: const Icon(Icons.check, size: 16),
              label: Text(
                'APLICAR',
                style: AppTypography.captionBold.copyWith(
                  letterSpacing: 0.5,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForAction(ProgressionAction action) {
    switch (action) {
      case ProgressionAction.increaseWeight:
        return Icons.trending_up_rounded;
      case ProgressionAction.increaseReps:
        return Icons.add_circle_outline_rounded;
      case ProgressionAction.maintain:
        return Icons.sync_rounded;
      case ProgressionAction.decreaseWeight:
      case ProgressionAction.decreaseReps:
        return Icons.trending_down_rounded;
    }
  }

  String _formatWeight(double weight) {
    if (weight == weight.roundToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toStringAsFixed(1);
  }

  /// Extrae solo la parte relevante del next step preview
  String _getShortNextStep(String fullPreview) {
    // Remover prefijos comunes para hacerlo más corto
    final prefixes = [
      'Siguiente: ',
      'Si éxito: ',
      'Si completas todas: ',
      'Si todas a ',
      'Objetivo: ',
    ];

    var result = fullPreview;
    for (final prefix in prefixes) {
      if (result.startsWith(prefix)) {
        result = result.substring(prefix.length);
        break;
      }
    }

    return result;
  }
}
