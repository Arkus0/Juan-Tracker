import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../../services/rest_pause_service.dart';

/// Widget que muestra sugerencias de progresión para series Rest-Pause.
///
/// Se muestra después de completar una serie marcada como RP,
/// sugiriendo si se debe mantener o aumentar peso.
class RestPauseSuggestion extends StatelessWidget {
  final int targetReps;
  final int firstSetReps;
  final int miniSetReps;
  final double currentWeight;
  final VoidCallback? onAcceptSuggestion;
  final VoidCallback? onDismiss;

  const RestPauseSuggestion({
    super.key,
    required this.targetReps,
    required this.firstSetReps,
    required this.miniSetReps,
    required this.currentWeight,
    this.onAcceptSuggestion,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final result = RestPauseService().analyze(
      targetReps: targetReps,
      firstSetReps: firstSetReps,
      miniSetReps: miniSetReps,
      currentWeight: currentWeight,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: result.shouldProgress 
            ? AppColors.success.withAlpha(20)
            : AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: result.shouldProgress ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                result.shouldProgress ? Icons.trending_up : Icons.info,
                color: result.shouldProgress ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  result.shouldProgress ? '¡Progresa en RP!' : 'Mantén el peso',
                  style: AppTypography.titleSmall.copyWith(
                    color: result.shouldProgress ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            result.message,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          
          // Stats de la serie RP
          Row(
            children: [
              _buildStat(
                label: 'Primer set',
                value: '$firstSetReps reps',
              ),
              const SizedBox(width: AppSpacing.lg),
              _buildStat(
                label: 'Mini-set',
                value: '$miniSetReps reps',
              ),
              const SizedBox(width: AppSpacing.lg),
              _buildStat(
                label: 'Total efectivo',
                value: '${result.totalReps} reps',
                highlight: true,
              ),
            ],
          ),

          if (result.shouldProgress && result.suggestedWeight != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onAcceptSuggestion,
              icon: const Icon(Icons.arrow_upward),
              label: Text('Aumentar a ${result.suggestedWeight!.toStringAsFixed(1)} kg'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            color: highlight ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }
}

/// Chip que indica que una serie es Rest-Pause.
///
/// Versión compacta para mostrar en la lista de series.
class RestPauseChip extends StatelessWidget {
  final int? miniSetReps;
  final VoidCallback? onTap;

  const RestPauseChip({
    super.key,
    this.miniSetReps,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.secondary.withAlpha(100),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_10,
              size: 14,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              miniSetReps != null ? 'RP +$miniSetReps' : 'RP',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog para ingresar reps de la mini-serie RP.
///
/// Se muestra después de completar una serie RP para registrar
/// cuántas reps extra se hicieron después del descanso corto.
class RestPauseMiniSetDialog extends StatefulWidget {
  final int firstSetReps;
  final double weight;

  const RestPauseMiniSetDialog({
    super.key,
    required this.firstSetReps,
    required this.weight,
  });

  @override
  State<RestPauseMiniSetDialog> createState() => _RestPauseMiniSetDialogState();
}

class _RestPauseMiniSetDialogState extends State<RestPauseMiniSetDialog> {
  int miniSetReps = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rest-Pause Completado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primer set: ${widget.firstSetReps} reps con ${widget.weight}kg',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('¿Cuántas reps extra hiciste después del descanso?'),
          const SizedBox(height: AppSpacing.md),
          
          // Selector de reps
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: miniSetReps > 0 
                    ? () => setState(() => miniSetReps--) 
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '$miniSetReps',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => miniSetReps++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Total: ${widget.firstSetReps + miniSetReps} reps efectivas',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OMITIR'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, miniSetReps),
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }
}
