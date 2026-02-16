import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart' show AppTypography;
import '../../diet/providers/nutrition_streak_provider.dart';

/// Widget que muestra la racha de registro de nutrición
class NutritionStreakCounter extends ConsumerWidget {
  const NutritionStreakCounter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(nutritionStreakProvider);
    final scheme = Theme.of(context).colorScheme;

    return streakAsync.when(
      data: (streak) => _buildContent(context, scheme, streak),
      loading: () => _buildLoading(scheme),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme scheme,
    NutritionStreakData streak,
  ) {
    final hasStreak = streak.currentStreak > 0;
    final isNewRecord = streak.currentStreak >= streak.longestStreak &&
        streak.currentStreak > 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: hasStreak
            ? LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.2),
                  scheme.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              )
            : null,
        color: hasStreak ? null : scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasStreak
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.outline,
        ),
      ),
      child: Row(
        children: [
          // Icon con efecto
          if (hasStreak) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                isNewRecord ? '🏆' : '🥗',
                style: TextStyle(fontSize: hasStreak ? 28 : 20),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Info de racha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${streak.currentStreak}',
                      style: AppTypography.dataLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: hasStreak
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      streak.currentStreak == 1 ? 'DÍA' : 'DÍAS',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasStreak
                      ? 'Racha de registro'
                      : streak.lastLogDate != null
                          ? 'Sin racha activa'
                          : 'Registra tu primer día',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Récord badge
          if (streak.longestStreak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.outline),
              ),
              child: Column(
                children: [
                  Text(
                    '${streak.longestStreak}',
                    style: AppTypography.dataSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isNewRecord
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'RÉCORD',
                    style: AppTypography.microBadge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

          // Mini calendar de últimos 7 días
          if (hasStreak) ...[
            const SizedBox(width: 8),
            _MiniWeekCalendar(recentDays: streak.recentDays),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading(ColorScheme scheme) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: scheme.primary,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

/// Mini calendario de 7 días mostrando cuáles tienen registros
class _MiniWeekCalendar extends StatelessWidget {
  final Set<DateTime> recentDays;

  const _MiniWeekCalendar({required this.recentDays});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (i) {
            final day = today.subtract(Duration(days: 6 - i));
            final hasLog = recentDays.contains(day);
            final isToday = day == today;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasLog
                      ? scheme.primary
                      : isToday
                          ? scheme.outline
                          : scheme.outline.withValues(alpha: 0.3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Badge compacto para inline display
class NutritionStreakBadge extends ConsumerWidget {
  const NutritionStreakBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(nutritionStreakProvider);
    final scheme = Theme.of(context).colorScheme;

    return streakAsync.when(
      data: (streak) {
        if (streak.currentStreak == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary.withValues(alpha: 0.25),
                scheme.primary.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🥗', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '${streak.currentStreak}',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
