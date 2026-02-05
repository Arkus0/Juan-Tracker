import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../../core/design_system/design_system.dart' show AppTypography;
import '../../models/analysis_models.dart';
import '../../providers/analysis_provider.dart';

/// Horizontal list showing muscle group recovery status
class RecoveryMonitor extends ConsumerWidget {
  const RecoveryMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoveryAsync = ref.watch(muscleRecoveryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.secondary.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.battery_charging_full,
                  color: scheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'MONITOR DE RECUPERACION',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        recoveryAsync.when(
          data: (recoveries) {
            if (recoveries.isEmpty) return _buildEmptyState(scheme);
            return _buildRecoveryList(recoveries, scheme);
          },
          loading: () => _buildLoading(scheme),
          error: (_, _) => _buildEmptyState(scheme),
        ),
      ],
    );
  }

  Widget _buildRecoveryList(
    List<MuscleRecovery> recoveries,
    ColorScheme scheme,
  ) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: recoveries.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
            child: _RecoveryCard(recovery: recoveries[index], scheme: scheme),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha((0.35 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, color: scheme.outline, size: 32),
          const SizedBox(height: 8),
          Text(
            'Entrena para ver tu recuperacion',
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(ColorScheme scheme) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(
                  (0.35 * 255).round(),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final MuscleRecovery recovery;
  final ColorScheme scheme;

  const _RecoveryCard({required this.recovery, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final status = recovery.status;

    double recoveryPercent;
    if (recovery.daysSinceTraining >= 5) {
      recoveryPercent = 1.0;
    } else if (recovery.daysSinceTraining <= 0) {
      recoveryPercent = 0.0;
    } else {
      recoveryPercent = recovery.daysSinceTraining / 5.0;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showRecoveryDetail(context);
      },
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              status.color.withAlpha((0.15 * 255).round()),
              scheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status.color.withAlpha((0.3 * 255).round()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getMuscleEmoji(recovery.muscleName),
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: status.color.withAlpha((0.5 * 255).round()),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recovery.displayName.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            LinearPercentIndicator(
              padding: EdgeInsets.zero,
              lineHeight: 4,
              percent: recoveryPercent,
              backgroundColor: scheme.surfaceContainerHighest,
              linearGradient: LinearGradient(
                colors: [
                  status.color.withAlpha((0.7 * 255).round()),
                  status.color,
                ],
              ),
              barRadius: const Radius.circular(2),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  recovery.daysSinceTraining >= 999
                      ? '--'
                      : '${recovery.daysSinceTraining}d',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: status.color,
                  ),
                ),
                const Spacer(),
                Text(status.emoji, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecoveryDetail(BuildContext context) {
    final status = recovery.status;
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    _getMuscleEmoji(recovery.muscleName),
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recovery.displayName,
                          style: AppTypography.headlineLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: status.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status.label.toUpperCase(),
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: status.color,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withAlpha(
                    (0.4 * 255).round(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      'Dias desde ultimo entreno',
                      recovery.daysSinceTraining >= 999
                          ? 'Nunca entrenado'
                          : '${recovery.daysSinceTraining} dias',
                    ),
                    Divider(color: scheme.outline, height: 24),
                    _buildDetailRow(
                      context,
                      'Estado de recuperacion',
                      _getRecoveryAdvice(status),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status.color.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: status.color.withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getRecommendationIcon(status),
                      color: status.color,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getRecommendation(status),
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _getMuscleEmoji(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'pecho':
        return '\u{1FAC1}';
      case 'espalda':
        return '\u{1F519}';
      case 'piernas':
        return '\u{1F9B5}';
      case 'hombros':
        return '\u{1F937}';
      case 'brazos':
        return '\u{1F4AA}';
      case 'core':
        return '\u{1F3AF}';
      default:
        return '\u{1F4AA}';
    }
  }

  String _getRecoveryAdvice(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.recovering:
        return 'Necesita descanso';
      case RecoveryStatus.ready:
        return 'Listo para entrenar';
      case RecoveryStatus.fresh:
        return 'Completamente fresco';
    }
  }

  IconData _getRecommendationIcon(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.recovering:
        return Icons.hotel;
      case RecoveryStatus.ready:
        return Icons.thumb_up;
      case RecoveryStatus.fresh:
        return Icons.flash_on;
    }
  }

  String _getRecommendation(RecoveryStatus status) {
    switch (status) {
      case RecoveryStatus.recovering:
        return 'Este musculo aun se esta recuperando. Considera entrenar otro grupo muscular hoy.';
      case RecoveryStatus.ready:
        return 'Buen momento para entrenar este musculo. La recuperacion esta casi completa.';
      case RecoveryStatus.fresh:
        return 'Hora de atacar. Este musculo esta completamente recuperado y listo para el maximo esfuerzo.';
    }
  }
}
