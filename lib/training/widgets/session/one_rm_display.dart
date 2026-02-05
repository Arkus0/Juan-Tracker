import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../../services/one_rm_calculator.dart';

/// Widget que muestra el 1RM estimado basado en la última serie completada.
///
/// Se muestra en la tarjeta de ejercicio y se actualiza automáticamente.
class OneRMDisplay extends StatelessWidget {
  final double? weight;
  final int? reps;
  final VoidCallback? onTap;

  const OneRMDisplay({
    super.key,
    this.weight,
    this.reps,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (weight == null || reps == null || weight! <= 0 || reps! <= 0) {
      return const SizedBox.shrink();
    }

    // Solo mostrar si hay suficientes datos
    if (reps! > 15) {
      return const SizedBox.shrink(); // No es fiable con >15 reps
    }

    final result = OneRMCalculator.calculateAll(weight: weight!, reps: reps!);
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.primary.withAlpha(50),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '1RM: ${result.rounded.toStringAsFixed(1)} kg',
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (result.confidence < 70) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: 'Baja confianza (${result.confidence.toInt()}%). '
                         'Haz una serie con 1-5 reps para mejor precisión.',
                child: Icon(
                  Icons.help_outline,
                  size: 12,
                  color: colorScheme.primary.withAlpha(150),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog que muestra el desglose completo del 1RM.
class OneRMDetailDialog extends StatelessWidget {
  final double weight;
  final int reps;

  const OneRMDetailDialog({
    super.key,
    required this.weight,
    required this.reps,
  });

  @override
  Widget build(BuildContext context) {
    final result = OneRMCalculator.calculateAll(weight: weight, reps: reps);
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '1RM Estimado',
                    style: AppTypography.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Input data
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      label: 'Peso usado',
                      value: '${weight.toStringAsFixed(1)} kg',
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      label: 'Reps',
                      value: '$reps',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // 1RM Principal
            Center(
              child: Column(
                children: [
                  Text(
                    result.rounded.toStringAsFixed(1),
                    style: AppTypography.headlineLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    'kg estimados',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildConfidenceBadge(result.confidence),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            
            // Tabla de fórmulas
            Text('Desglose por fórmula:', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...result.results.entries.map((e) => _buildFormulaRow(
              _getFormulaName(e.key),
              e.value,
              colorScheme,
            )),
            
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            
            // Tabla de porcentajes
            Text('Tabla de cargas:', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _buildPercentageTable(result.rounded, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall),
        Text(value, style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    final color = confidence >= 80 
        ? AppColors.success 
        : confidence >= 60 
            ? AppColors.warning 
            : AppColors.error;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Confianza: ${confidence.toInt()}%',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFormulaRow(String name, double value, ColorScheme colorScheme) {
    final isAverage = name == 'Promedio';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isAverage ? FontWeight.bold : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${value.toStringAsFixed(1)} kg',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isAverage ? FontWeight.bold : null,
                color: isAverage ? colorScheme.primary : null,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageTable(double oneRM, ColorScheme colorScheme) {
    final table = OneRMCalculator.calculatePercentageTable(oneRM);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: table.entries.map((e) {
          return SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  '${e.key}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  e.value.toStringAsFixed(1),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFormulaName(OneRMFormula formula) {
    return switch (formula) {
      OneRMFormula.brzycki => 'Brzycki',
      OneRMFormula.epley => 'Epley',
      OneRMFormula.lombardi => 'Lombardi',
      OneRMFormula.mayhew => 'Mayhew',
      OneRMFormula.oconner => "O'Conner",
      OneRMFormula.wathen => 'Wathen',
      OneRMFormula.average => 'Promedio',
    };
  }
}

/// Chip que indica el 1RM estimado de forma más compacta.
class OneRMChip extends StatelessWidget {
  final double? weight;
  final int? reps;

  const OneRMChip({
    super.key,
    this.weight,
    this.reps,
  });

  @override
  Widget build(BuildContext context) {
    if (weight == null || reps == null || weight! <= 0 || reps! <= 0) {
      return const SizedBox.shrink();
    }

    if (reps! > 15) return const SizedBox.shrink();

    final result = OneRMCalculator.calculateAll(weight: weight!, reps: reps!);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '1RM ${result.rounded.toStringAsFixed(0)}',
        style: AppTypography.labelSmall.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
