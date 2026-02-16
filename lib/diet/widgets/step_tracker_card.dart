import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../core/widgets/app_snackbar.dart';
import '../models/step_entry_model.dart';
import '../providers/step_providers.dart';

/// Card compacta para registro rápido de pasos en hábitos.
///
/// Muestra pasos del día, kcal estimadas, botones +1000/+5000,
/// y opción de editar manualmente.
class StepTrackerCard extends ConsumerWidget {
  final DateTime date;

  const StepTrackerCard({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final steps = ref.watch(dailyStepsProvider(date));
    final kcal = ref.watch(todayStepKcalProvider(date));
    final weeklyAvg = ref.watch(weeklyStepAvgProvider);
    final colors = Theme.of(context).colorScheme;
    final activity = StepActivityLevel.fromSteps(steps);
    final diff = weeklyAvg > 0 ? steps - weeklyAvg : null;
    final diffValue = diff?.abs() ?? 0;
    final diffColor = diff == null
        ? colors.onSurfaceVariant
        : diff >= 0
            ? colors.primary
            : colors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                Icon(Icons.directions_walk, color: colors.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text('Pasos', style: AppTypography.titleSmall),
                const Spacer(),
                // Editar manualmente
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: colors.onSurfaceVariant),
                  onPressed: () => _showEditDialog(context, ref, steps),
                  tooltip: 'Editar pasos',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Contador principal
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  StepEntry(dateKey: '', steps: steps).formattedSteps,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'pasos',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                // Badge de actividad
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _activityColor(colors, activity)
                        .withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${activity.emoji} ${activity.label}',
                    style: AppTypography.labelSmall.copyWith(
                      color: _activityColor(colors, activity),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xs),

            // Kcal y distancia
            Row(
              children: [
                Icon(Icons.local_fire_department, size: 14, color: colors.error),
                const SizedBox(width: 4),
                Text(
                  '~${kcal.round()} kcal',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(Icons.straighten, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '~${StepEntry(dateKey: '', steps: steps).estimatedKm.toStringAsFixed(1)} km',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            if (diff != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    diff >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: diffColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'vs media semanal: '
                    '${diff >= 0 ? '+' : '-'}'
                    '${StepEntry(dateKey: '', steps: diffValue).formattedSteps}',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Botones rápidos de incremento
            Row(
              children: [
                _QuickAddButton(
                  label: '+1.000',
                  tooltip: 'Añadir 1.000 pasos',
                  onTap: () {
                    ref.read(stepDataProvider.notifier).addSteps(date, 1000);
                    HapticFeedback.lightImpact();
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickAddButton(
                  label: '+5.000',
                  tooltip: 'Añadir 5.000 pasos',
                  onTap: () {
                    ref.read(stepDataProvider.notifier).addSteps(date, 5000);
                    HapticFeedback.lightImpact();
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickAddButton(
                  label: '+10.000',
                  tooltip: 'Añadir 10.000 pasos',
                  onTap: () {
                    ref.read(stepDataProvider.notifier).addSteps(date, 10000);
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _activityColor(ColorScheme colors, StepActivityLevel level) =>
      switch (level) {
        StepActivityLevel.sedentary => colors.onSurfaceVariant,
        StepActivityLevel.lowActive => colors.tertiary,
        StepActivityLevel.somewhatActive => colors.secondary,
        StepActivityLevel.active => colors.primary,
        StepActivityLevel.highlyActive => colors.primary,
      };

  void _showEditDialog(BuildContext context, WidgetRef ref, int currentSteps) {
    final controller = TextEditingController(
      text: currentSteps > 0 ? currentSteps.toString() : '',
    );
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar pasos', style: AppTypography.titleMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'N?mero de pasos',
            suffixText: 'pasos',
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              final newSteps = int.tryParse(controller.text) ?? 0;
              ref.read(stepDataProvider.notifier).setSteps(date, newSteps);
              Navigator.pop(ctx);
              if (context.mounted) {
                AppSnackbar.show(context, message: 'Pasos actualizados');
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }
}

/// Botón de incremento rápido de pasos.
class _QuickAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? tooltip;

  const _QuickAddButton({
    required this.label,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final button = Material(
      color: colors.primaryContainer.withAlpha((0.45 * 255).round()),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    return Expanded(
      child: tooltip == null
          ? button
          : Tooltip(
              message: tooltip!,
              child: button,
            ),
    );
  }
}

/// Resumen compacto de pasos para SummaryScreen.
///
/// Muestra promedio semanal, nivel de actividad inferido, y mini gráfico.
class StepWeeklySummary extends ConsumerWidget {
  const StepWeeklySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAvg = ref.watch(weeklyStepAvgProvider);
    final activity = ref.watch(stepBasedActivityProvider);
    final history = ref.watch(weeklyStepHistoryProvider);
    final stepTdee = ref.watch(stepAdjustedTdeeProvider);
    final colors = Theme.of(context).colorScheme;

    // No mostrar si no hay datos
    if (weeklyAvg == 0 && history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk, color: colors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text('Actividad semanal', style: AppTypography.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Promedio y nivel
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Media diaria',
                    value: StepEntry(dateKey: '', steps: weeklyAvg).formattedSteps,
                    suffix: 'pasos',
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Nivel',
                    value: '${activity.emoji} ${activity.label}',
                    suffix: '',
                  ),
                ),
                if (stepTdee != null)
                  Expanded(
                    child: _MetricTile(
                      label: 'TDEE (pasos)',
                      value: stepTdee.round().toString(),
                      suffix: 'kcal',
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Mini gráfico de barras de 7 días
            if (history.isNotEmpty) _MiniStepChart(history: history),
          ],
        ),
      ),
    );
  }
}

/// Tile de métrica individual.
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTypography.titleSmall.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (suffix.isNotEmpty)
                TextSpan(
                  text: ' $suffix',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mini gráfico de barras mostrando pasos de los últimos 7 días.
class _MiniStepChart extends StatelessWidget {
  final List<StepEntry> history;

  const _MiniStepChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    // Crear mapa de últimos 7 días
    final Map<String, int> daySteps = {};
    for (final entry in history) {
      daySteps[entry.dateKey] = entry.steps;
    }

    // Generar 7 días (de hace 6 días hasta hoy)
    final days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return (
        label: dayLabels[date.weekday - 1],
        steps: daySteps[key] ?? 0,
      );
    });

    final maxSteps = days.fold<int>(0, (max, d) => d.steps > max ? d.steps : max);
    final barMax = maxSteps > 0 ? maxSteps : 10000;

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final fraction = (d.steps / barMax).clamp(0.0, 1.0);
          final isToday = d == days.last;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: fraction > 0 ? fraction : 0.02,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? colors.primary
                                : d.steps >= 10000
                                    ? colors.primary.withAlpha((0.7 * 255).round())
                                    : colors.primary.withAlpha((0.3 * 255).round()),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.label,
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: isToday ? colors.primary : colors.onSurfaceVariant,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
