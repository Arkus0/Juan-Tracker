import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/widgets/widgets.dart';
import '../../models/analysis_models.dart';
import '../../providers/analysis_provider.dart';

class WeeklyMuscleVolumeCard extends ConsumerWidget {
  const WeeklyMuscleVolumeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final volumeAsync = ref.watch(muscleVolumeWeekProvider);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: scheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'VOLUMEN SEMANAL POR MÚSCULO',
                style: AppTypography.labelLarge.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          volumeAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'No se pudo cargar el volumen semanal',
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            data: (volumes) {
              if (volumes.isEmpty) {
                return Text(
                  'Aún no hay datos de esta semana',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                );
              }

              final sorted = volumes.values.toList()
                ..sort((a, b) => b.totalVolume.compareTo(a.totalVolume));
              final maxVolume =
                  sorted.isNotEmpty ? sorted.first.totalVolume : 0.0;

              return Column(
                children: sorted.take(8).map((muscle) {
                  final ratio =
                      maxVolume > 0 ? muscle.totalVolume / maxVolume : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _MuscleVolumeRow(
                      muscle: muscle,
                      ratio: ratio,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MuscleVolumeRow extends StatelessWidget {
  final MuscleVolume muscle;
  final double ratio;

  const _MuscleVolumeRow({
    required this.muscle,
    required this.ratio,
  });

  String _formatVolume(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}t';
    }
    return '${value.toStringAsFixed(0)}kg';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                muscle.displayName,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              _formatVolume(muscle.totalVolume),
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(scheme.primary),
          ),
        ),
      ],
    );
  }
}
