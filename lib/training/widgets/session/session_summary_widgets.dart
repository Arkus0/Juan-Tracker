import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/widgets/widgets.dart' show AppCard;
import '../../providers/session_progress_provider.dart';
import '../../providers/training_provider.dart';
import 'session_timer_display.dart';

/// Barra resumen de la sesión con métricas en vivo (series, volumen, tiempo).
class SessionSummaryBar extends ConsumerWidget {
  const SessionSummaryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(sessionProgressProvider);
    if (progress.totalSets == 0) {
      return const SizedBox.shrink();
    }

    final totalVolume = ref.watch(
      trainingSessionProvider.select((s) {
        var volume = 0.0;
        for (final exercise in s.exercises) {
          for (final log in exercise.logs) {
            if (!log.completed) continue;
            if (log.isWarmup) continue;
            if (log.peso <= 0 || log.reps <= 0) continue;
            volume += log.peso * log.reps;
          }
        }
        return volume;
      }),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: SummaryMetric(
                  icon: Icons.fact_check_outlined,
                  label: 'SERIES',
                  value: '${progress.completedSets}/${progress.totalSets}',
                  accent: AppColors.completedGreen,
                ),
              ),
              const SummaryDivider(),
              Expanded(
                child: SummaryMetric(
                  icon: Icons.scale_outlined,
                  label: 'VOLUMEN',
                  value: _formatVolume(totalVolume),
                  accent: AppColors.techCyan,
                ),
              ),
              const SummaryDivider(),
              Expanded(
                child: SummaryMetric(
                  icon: Icons.timer_outlined,
                  label: 'TIEMPO',
                  valueWidget: const SessionTimerDisplay(
                    showIcon: false,
                    compact: true,
                  ),
                  accent: AppColors.goldAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatVolume(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

/// Métrica individual del resumen de sesión.
class SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color accent;

  const SummaryMetric({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelEmphasis.copyWith(fontSize: 9)),
              if (valueWidget != null)
                DefaultTextStyle(
                  style: AppTypography.sectionTitleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  child: valueWidget!,
                )
              else
                Text(
                  value ?? '-',
                  style: AppTypography.sectionTitleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Separador vertical para el resumen de sesión.
class SummaryDivider extends StatelessWidget {
  const SummaryDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: AppColors.border,
    );
  }
}
