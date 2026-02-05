import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart' show AppTypography;
import '../../providers/analysis_provider.dart';

/// Dashboard de desbalances musculares
/// Muestra ratios críticos: empuje/jalón, cuádriceps/femoral
class MuscleImbalanceDashboard extends ConsumerWidget {
  const MuscleImbalanceDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final imbalanceAsync = ref.watch(muscleImbalanceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.balance_outlined,
                  color: scheme.onPrimaryContainer,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'EQUILIBRIO MUSCULAR',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Análisis de proporciones (últimos 30 días)',
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // Ratios principales
          imbalanceAsync.when(
            data: (data) {
              if (data.isEmpty) {
                return _buildEmptyState(scheme);
              }

              return Column(
                children: [
                  // Ratio Empuje/Jalón
                  if (data.pushPullRatio != null)
                    _buildRatioCard(
                      context: context,
                      label: 'EMPUJE / JALÓN',
                      ratio: data.pushPullRatio!,
                      idealRange: const RangeValues(0.8, 1.3),
                      leftLabel: 'Empuje',
                      rightLabel: 'Jalón',
                      leftValue: data.pushVolume ?? 0,
                      rightValue: data.pullVolume ?? 0,
                      icon: Icons.swap_horiz,
                    ),

                  const SizedBox(height: 12),

                  // Ratio Cuádriceps/Femoral
                  if (data.quadHamstringRatio != null)
                    _buildRatioCard(
                      context: context,
                      label: 'CUÁDRICEPS / FEMORAL',
                      ratio: data.quadHamstringRatio!,
                      idealRange: const RangeValues(1.0, 2.0),
                      leftLabel: 'Cuádriceps',
                      rightLabel: 'Femoral',
                      leftValue: data.quadVolume ?? 0,
                      rightValue: data.hamstringVolume ?? 0,
                      icon: Icons.accessibility_new,
                      warningThreshold: 2.5, // Alerta si > 2.5:1
                    ),

                  const SizedBox(height: 16),

                  // Alertas si hay desbalances
                  if (data.warnings.isNotEmpty)
                    _buildWarnings(scheme, data.warnings),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => _buildEmptyState(scheme, error: true),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme, {bool error = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            error ? Icons.error_outline : Icons.fitness_center,
            size: 32,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            error
                ? 'Error al cargar datos'
                : 'Entrena más para ver análisis de equilibrio',
            style: AppTypography.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRatioCard({
    required BuildContext context,
    required String label,
    required double ratio,
    required RangeValues idealRange,
    required String leftLabel,
    required String rightLabel,
    required double leftValue,
    required double rightValue,
    required IconData icon,
    double? warningThreshold,
  }) {
    final scheme = Theme.of(context).colorScheme;

    // Determinar estado
    final isBalanced = ratio >= idealRange.start && ratio <= idealRange.end;
    final isWarning = warningThreshold != null && ratio > warningThreshold;
    final statusColor = isWarning
        ? Colors.red
        : isBalanced
        ? Colors.green
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ratio
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${ratio.toStringAsFixed(2)}:1',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Barra visual del ratio
          _buildRatioBar(
            context: context,
            ratio: ratio,
            idealRange: idealRange,
            leftLabel: leftLabel,
            rightLabel: rightLabel,
            leftValue: leftValue,
            rightValue: rightValue,
            statusColor: statusColor,
          ),

          const SizedBox(height: 8),

          // Labels con valores
          Row(
            children: [
              _buildVolumeLabel(leftLabel, leftValue, scheme, isLeft: true),
              const Spacer(),
              _buildVolumeLabel(rightLabel, rightValue, scheme, isLeft: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioBar({
    required BuildContext context,
    required double ratio,
    required RangeValues idealRange,
    required String leftLabel,
    required String rightLabel,
    required double leftValue,
    required double rightValue,
    required Color statusColor,
  }) {
    final scheme = Theme.of(context).colorScheme;

    // Normalizar ratio para la barra (max 3:1 para visualización)
    final maxRatio = 3.0;
    final normalizedRatio = (ratio / maxRatio).clamp(0.0, 1.0);

    // Posiciones del rango ideal
    final idealStart = (idealRange.start / maxRatio).clamp(0.0, 1.0);
    final idealEnd = (idealRange.end / maxRatio).clamp(0.0, 1.0);

    return SizedBox(
      height: 24,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final idealLeft = barWidth * idealStart;
          final idealRight = barWidth * (1 - idealEnd);
          final indicatorLeft = (barWidth * normalizedRatio - 8).clamp(
            0.0,
            barWidth - 16,
          );

          return Stack(
            children: [
              // Fondo de la barra
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Zona ideal
              Positioned(
                left: idealLeft,
                right: idealRight,
                top: 0,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha((0.3 * 255).round()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Indicador de posición actual
              Positioned(
                left: indicatorLeft,
                top: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withAlpha((0.4 * 255).round()),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVolumeLabel(
    String label,
    double value,
    ColorScheme scheme, {
    required bool isLeft,
  }) {
    return Column(
      crossAxisAlignment: isLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${value.toStringAsFixed(0)} kg·rep',
          style: AppTypography.bodySmall.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildWarnings(
    ColorScheme scheme,
    List<MuscleImbalanceWarning> warnings,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.error.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.error, size: 16),
              const SizedBox(width: 8),
              Text(
                'RECOMENDACIONES',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: scheme.error)),
                  Expanded(
                    child: Text(
                      w.message,
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modelo de advertencia de desbalance
class MuscleImbalanceWarning {
  final String type; // 'push_pull', 'quad_hamstring'
  final String message;
  final double severity; // 0.0 - 1.0

  const MuscleImbalanceWarning({
    required this.type,
    required this.message,
    required this.severity,
  });
}

/// Modelo de datos de desbalance
class MuscleImbalanceData {
  final double? pushPullRatio;
  final double? quadHamstringRatio;
  final double? pushVolume;
  final double? pullVolume;
  final double? quadVolume;
  final double? hamstringVolume;
  final List<MuscleImbalanceWarning> warnings;

  const MuscleImbalanceData({
    this.pushPullRatio,
    this.quadHamstringRatio,
    this.pushVolume,
    this.pullVolume,
    this.quadVolume,
    this.hamstringVolume,
    this.warnings = const [],
  });

  bool get isEmpty => pushPullRatio == null && quadHamstringRatio == null;
}
