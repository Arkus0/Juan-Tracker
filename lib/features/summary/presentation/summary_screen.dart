import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/widgets/home_button.dart';
import '../../../diet/providers/coach_providers.dart';
import '../../../diet/providers/diet_providers.dart';
import '../../../diet/providers/macro_cycle_providers.dart';
import '../../../diet/providers/macro_flexibility_providers.dart';
import '../../../diet/providers/tdee_trend_providers.dart';
import '../../../diet/providers/weekly_insights_provider.dart';
import '../../../diet/services/day_summary_calculator.dart';
import '../../../diet/models/macro_cycle_model.dart';
import '../../../diet/models/macro_flexibility_model.dart';
import '../../../diet/models/tdee_trend_model.dart';
import '../../../diet/widgets/step_tracker_card.dart';
import '../../../diet/widgets/water_tracking_card.dart';
import '../providers/summary_sections_provider.dart';
import '../../../core/providers/training_day_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../training/screens/export_screen.dart';
import '../../home/providers/home_providers.dart';

/// Pantalla de resumen tipo "budget" con progreso detallado.
///
/// Muestra:
/// - Consumo del dÃ­a vs objetivos
/// - Barras de progreso visuales
/// - Historial reciente
/// - Acceso rÃ¡pido a gestiÃ³n de objetivos
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(daySummaryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dayColor = isActive
        ? _getDayColor(config, selectedDate, ref, colors)
        : colors.onSurfaceVariant;
    final coachPlan = ref.watch(coachPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: HomeButton(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportar datos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              );
            },
          ),
        ],
      ),
      body: summaryAsync.when(
        data: (summary) => _SummaryContent(
          summary: summary,
          selectedDate: selectedDate,
          coachPlan: coachPlan,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Contenido principal del resumen.
class _SummaryContent extends ConsumerWidget {
  final DaySummary summary;
  final DateTime selectedDate;
  final dynamic coachPlan; // CoachPlan?

  const _SummaryContent({
    required this.summary,
    required this.selectedDate,
    this.coachPlan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(summarySectionsProvider);
    final sectionsNotifier = ref.read(summarySectionsProvider.notifier);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fecha del resumen
          _DateHeader(date: selectedDate),
          const SizedBox(height: 16),

          // Card principal de budget
          _BudgetCard(summary: summary),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: sections.allExpanded
                    ? null
                    : () => sectionsNotifier.setAll(true),
                child: const Text('EXPANDIR TODO'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: sections.anyExpanded
                    ? () => sectionsNotifier.setAll(false)
                    : null,
                child: const Text('COLAPSAR TODO'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _CollapsibleSection(
            title: 'TENDENCIAS SEMANALES',
            titleStyle: _sectionStyle(context),
            expanded: sections.isExpanded(SummarySection.weeklyTrends),
            onToggle: () =>
                sectionsNotifier.toggle(SummarySection.weeklyTrends),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WeeklyTrendChart(),
                const SizedBox(height: 16),
                const _WeeklyInsightsCard(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Habitos (agua + pasos)
          Text('HABITOS', style: _sectionStyle(context)),
          const SizedBox(height: 12),
          const WaterTrackingCard(),
          const SizedBox(height: 12),
          StepTrackerCard(date: selectedDate),
          const SizedBox(height: 12),
          const StepWeeklySummary(),
          const SizedBox(height: 24),

          // Si no hay targets ni coach, mostrar CTA
          if (!summary.hasTargets && coachPlan == null) ...[
            _CreateTargetsCTA(),
            const SizedBox(height: 24),
          ],

          // Si hay coach plan, mostrar indicador
          if (coachPlan != null) ...[
            _CoachPlanIndicator(plan: coachPlan),
            const SizedBox(height: 24),
          ],

          // Macro cycling indicator
          const _MacroCycleIndicator(),
          const SizedBox(height: 16),

          _CollapsibleSection(
            title: 'TENDENCIA TDEE',
            titleStyle: _sectionStyle(context),
            expanded: sections.isExpanded(SummarySection.tdeeTrend),
            onToggle: () =>
                sectionsNotifier.toggle(SummarySection.tdeeTrend),
            child: const _TdeeTrendCard(),
          ),
          const SizedBox(height: 24),

          _CollapsibleSection(
            title: 'DESGLOSE',
            titleStyle: _sectionStyle(context),
            expanded: sections.isExpanded(SummarySection.breakdown),
            onToggle: () =>
                sectionsNotifier.toggle(SummarySection.breakdown),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MacroBreakdown(summary: summary),
                const SizedBox(height: 16),
                _MicronutrientBreakdown(summary: summary),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _CollapsibleSection(
            title: 'ESTADO DEL DIA',
            titleStyle: _sectionStyle(context),
            expanded: sections.isExpanded(SummarySection.dayStatus),
            onToggle: () =>
                sectionsNotifier.toggle(SummarySection.dayStatus),
            child: _DayStatusCard(summary: summary),
          ),
        ],
      ),
    );
  }

  TextStyle _sectionStyle(BuildContext context) {
    return AppTypography.bodyMedium.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  final String title;
  final TextStyle titleStyle;
  final Widget child;
  final bool expanded;
  final VoidCallback onToggle;

  const _CollapsibleSection({
    required this.title,
    required this.titleStyle,
    required this.child,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: titleStyle),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: child,
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AppDurations.fast,
        ),
      ],
    );
  }
}

/// Header con la fecha actual.
class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, DateTime.now());
    final dateText = isToday
        ? 'Hoy, ${DateFormat('d MMMM', 'es').format(date)}'
        : DateFormat('EEEE d MMMM yyyy', 'es').format(date);

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          dateText,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Card principal de budget con calorÃ­as y progreso.
class _BudgetCard extends StatelessWidget {
  final DaySummary summary;

  const _BudgetCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasTarget = summary.hasTargets;
    final targetKcal = summary.targets?.kcalTarget ?? 0;
    final consumedKcal = summary.consumed.kcal;
    final remainingKcal = hasTarget ? targetKcal - consumedKcal : 0;
    final progress = hasTarget
        ? (consumedKcal / targetKcal).clamp(0.0, 1.0)
        : 0.0;
    final percentage = hasTarget
        ? ((consumedKcal / targetKcal) * 100).round()
        : 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // TÃ­tulo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'CALORÃAS',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // NÃºmeros principales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$consumedKcal',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasTarget)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '/ $targetKcal',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasTarget ? 'consumidas' : 'kcal consumidas',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            // Barra de progreso
            if (hasTarget) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.orange.shade100,
                  valueColor: AlwaysStoppedAnimation(
                    _getProgressColor(progress),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // InformaciÃ³n de progreso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BudgetStat(
                    label: 'Restantes',
                    value: '$remainingKcal',
                    unit: 'kcal',
                    color: remainingKcal >= 0 ? Colors.green : Colors.red,
                  ),
                  _BudgetStat(
                    label: 'Progreso',
                    value: '$percentage',
                    unit: '%',
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withAlpha(
                    (0.5 * 255).round(),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Sin objetivo configurado',
                      style: TextStyle(color: colorScheme.onSecondaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) return Colors.green;
    if (progress < 0.8) return Colors.orange;
    if (progress <= 1.0) return Colors.red.shade400;
    return Colors.red.shade700;
  }
}

/// EstadÃ­stica individual del budget.
class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _BudgetStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(unit, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ],
    );
  }
}

/// CTA para crear objetivos cuando no hay ninguno.
class _CreateTargetsCTA extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      elevation: 0,
      child: InkWell(
        onTap: () => ref.read(homeTabProvider.notifier).goToCoach(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.track_changes,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configura tus objetivos',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define calorÃ­as y macros para ver tu progreso y mantenerte en track.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de que se estÃ¡ usando el Coach Adaptativo.
class _CoachPlanIndicator extends ConsumerWidget {
  final dynamic plan; // CoachPlan

  const _CoachPlanIndicator({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.secondaryContainer.withAlpha(128),
      elevation: 0,
      child: InkWell(
        onTap: () => ref.read(homeTabProvider.notifier).goToCoach(),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_graph,
                  color: colorScheme.onSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach Adaptativo',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.goalDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.secondary,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de ciclado de macros con acceso a configuración
class _MacroCycleIndicator extends ConsumerWidget {
  const _MacroCycleIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(macroCycleConfigProvider);
    final colors = Theme.of(context).colorScheme;
    final isActive = config != null && config.enabled;
    final selectedDate = ref.watch(selectedDateProvider);
    final dayColor = isActive
        ? _getDayColor(config, selectedDate, ref, colors)
        : colors.onSurfaceVariant;

    return InkWell(
      onTap: () => context.pushTo(AppRouter.nutritionMacroCycle),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? dayColor.withAlpha((0.08 * 255).round())
              : colors.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isActive
                ? dayColor.withAlpha((0.3 * 255).round())
                : colors.outline.withAlpha((0.2 * 255).round()),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.loop,
              size: 18,
              color: isActive ? dayColor : colors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ciclado de macros',
                    style: AppTypography.labelMedium.copyWith(
                      color: isActive ? dayColor : colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isActive) ...[
                    Text(
                      _getDayLabel(config, selectedDate, ref),
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ] else
                    Text(
                      'Toca para configurar',
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                ],
              ),
            ),
            if (isActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dayColor.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${config.getMacrosForDate(selectedDate).kcal} kcal',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: dayColor,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _getDayLabel(MacroCycleConfig config, DateTime date, WidgetRef ref) {
    final trainingInfo = ref.watch(trainingDayInfoProvider(date));
    return trainingInfo.when(
      data: (info) {
        if (info.didTrain) {
          final muscles = info.shortSummary;
          return 'Entrenamiento: $muscles';
        }
        // Sin sesi?n real ? usar config est?tica
        final type = config.getDayType(date);
        return _dayTypeLabel(type, programado: true);
      },
      loading: () {
        final type = config.getDayType(date);
        return _dayTypeLabel(type);
      },
      error: (_, _) {
        final type = config.getDayType(date);
        return _dayTypeLabel(type);
      },
    );
  }

  String _dayTypeLabel(DayType type, {bool programado = false}) {
    return switch (type) {
      DayType.training => programado
          ? 'Hoy: D?a de entrenamiento (programado)'
          : 'Hoy: D?a de entrenamiento',
      DayType.rest => 'Hoy: D?a de descanso',
      DayType.fasting => 'Hoy: D?a de ayuno',
    };
  }

  Color _getDayColor(
      MacroCycleConfig config, DateTime date, WidgetRef ref, ColorScheme colors) {
    final trainingInfo = ref.watch(trainingDayInfoProvider(date));
    final didTrain = trainingInfo.whenOrNull(data: (info) => info.didTrain);
    if (didTrain == true) return colors.primary;
    final type = config.getDayType(date);
    return switch (type) {
      DayType.training => colors.primary,
      DayType.rest => colors.secondary,
      DayType.fasting => colors.tertiary,
    };
  }
}

/// Desglose detallado de macros con barras de progreso y rangos flexibles.
class _MacroBreakdown extends ConsumerWidget {
  final DaySummary summary;

  const _MacroBreakdown({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targets = summary.targets;
    final flexibility = ref.watch(macroFlexibilityProvider);

    // Pre-calcular rangos para evitar problemas de null-promotion
    MacroRange? proteinRange;
    MacroRange? carbsRange;
    MacroRange? fatRange;
    if (flexibility.enabled && targets != null) {
      final t = targets;
      if (t.proteinTarget != null && t.proteinTarget! > 0) {
        proteinRange = flexibility.rangeForProtein(t.proteinTarget!);
      }
      if (t.carbsTarget != null && t.carbsTarget! > 0) {
        carbsRange = flexibility.rangeForCarbs(t.carbsTarget!);
      }
      if (t.fatTarget != null && t.fatTarget! > 0) {
        fatRange = flexibility.rangeForFat(t.fatTarget!);
      }
    }

    return Column(
      children: [
        _MacroProgressBar(
          label: 'Proteína',
          icon: Icons.fitness_center,
          consumed: summary.consumed.protein,
          target: targets?.proteinTarget,
          color: Colors.red.shade400,
          range: proteinRange,
        ),
        const SizedBox(height: 16),
        _MacroProgressBar(
          label: 'Carbohidratos',
          icon: Icons.grain,
          consumed: summary.consumed.carbs,
          target: targets?.carbsTarget,
          color: Colors.amber.shade600,
          range: carbsRange,
        ),
        const SizedBox(height: 16),
        _MacroProgressBar(
          label: 'Grasa',
          icon: Icons.water_drop,
          consumed: summary.consumed.fat,
          target: targets?.fatTarget,
          color: Colors.blue.shade400,
          range: fatRange,
        ),
      ],
    );
  }
}

/// Barra de progreso individual para un macro con zonas de rango flexible.
class _MacroProgressBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double consumed;
  final double? target;
  final Color color;
  final MacroRange? range;

  const _MacroProgressBar({
    required this.label,
    required this.icon,
    required this.consumed,
    required this.target,
    required this.color,
    this.range,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = target != null && target! > 0;
    final progress = hasTarget ? (consumed / target!).clamp(0.0, 1.5) : 0.0;
    final percentage = hasTarget ? ((consumed / target!) * 100).round() : 0;

    // Determinar color según zona
    final barColor = _getBarColor(consumed);
    final statusIcon = _getStatusIcon(consumed);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (statusIcon != null) ...[
                        const SizedBox(width: 4),
                        statusIcon,
                      ],
                    ],
                  ),
                  Text(
                    hasTarget
                        ? '${consumed.toStringAsFixed(0)} / ${target!.toStringAsFixed(0)}g ($percentage%)'
                        : '${consumed.toStringAsFixed(0)}g',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (hasTarget) ...[
                const SizedBox(height: 6),
                // Barra con zonas de rango
                if (range != null)
                  _RangeProgressBar(
                    progress: progress.clamp(0.0, 1.0),
                    barColor: barColor,
                    backgroundColor: color.withAlpha((0.15 * 255).round()),
                    range: range!,
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: color.withAlpha((0.2 * 255).round()),
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                  ),
                // Etiqueta de rango si está activo
                if (range != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '${range!.greenMin.round()}–${range!.greenMax.round()}g',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withAlpha((0.6 * 255).round()),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _getBarColor(double consumed) {
    if (range == null) return color;
    final status = range!.evaluate(consumed);
    return switch (status) {
      MacroZoneStatus.onTarget => AppColors.success,
      MacroZoneStatus.acceptable => Colors.amber.shade600,
      MacroZoneStatus.offTarget => AppColors.error,
    };
  }

  Widget? _getStatusIcon(double consumed) {
    if (range == null) return null;
    final status = range!.evaluate(consumed);
    if (consumed <= 0) return null;

    return switch (status) {
      MacroZoneStatus.onTarget => Icon(
          Icons.check_circle,
          size: 14,
          color: AppColors.success,
        ),
      MacroZoneStatus.acceptable => Icon(
          Icons.remove_circle_outline,
          size: 14,
          color: Colors.amber.shade600,
        ),
      MacroZoneStatus.offTarget => Icon(
          Icons.error_outline,
          size: 14,
          color: AppColors.error,
        ),
    };
  }
}

/// Barra de progreso con indicadores de zona (verde/amarillo).
///
/// Muestra marcadores verticales en las posiciones de los límites
/// del rango flexible sobre la barra de progreso estándar.
class _RangeProgressBar extends StatelessWidget {
  final double progress;
  final Color barColor;
  final Color backgroundColor;
  final MacroRange range;

  const _RangeProgressBar({
    required this.progress,
    required this.barColor,
    required this.backgroundColor,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    // Posiciones normalizadas de los límites (0.0 a 1.0 relativo al target)
    final greenMinPos = range.target > 0
        ? (range.greenMin / range.target).clamp(0.0, 1.5)
        : 0.0;
    final greenMaxPos = range.target > 0
        ? (range.greenMax / range.target).clamp(0.0, 1.5)
        : 1.0;

    return SizedBox(
      height: 10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Normalizar posiciones al ancho de la barra
          // La barra muestra hasta 100% del target
          final leftMark = (greenMinPos * width).clamp(0.0, width);
          final rightMark = (greenMaxPos * width).clamp(0.0, width);

          return Stack(
            children: [
              // Barra de fondo
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: backgroundColor,
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
              // Zona verde (indicadores de límite)
              Positioned(
                left: leftMark,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1.5,
                  color: AppColors.success.withAlpha((0.7 * 255).round()),
                ),
              ),
              Positioned(
                left: rightMark,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1.5,
                  color: AppColors.success.withAlpha((0.7 * 255).round()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Desglose expandible de micronutrientes en SummaryScreen
class _MicronutrientBreakdown extends StatefulWidget {
  final DaySummary summary;

  const _MicronutrientBreakdown({required this.summary});

  @override
  State<_MicronutrientBreakdown> createState() =>
      _MicronutrientBreakdownState();
}

class _MicronutrientBreakdownState extends State<_MicronutrientBreakdown> {
  bool _expanded = false;

  bool get _hasData {
    final c = widget.summary.consumed;
    final t = widget.summary.targets;
    return (c.fiber > 0 || c.sugar > 0 || c.saturatedFat > 0 || c.sodium > 0) ||
        (t?.fiberTarget != null || t?.sugarLimit != null ||
            t?.saturatedFatLimit != null || t?.sodiumLimit != null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasData) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final consumed = widget.summary.consumed;
    final targets = widget.summary.targets;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.science_outlined, size: 18, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Micronutrientes',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                // Mini resumen cuando está colapsado
                if (!_expanded) ...[
                  _MiniChip(
                    label: 'F',
                    value: consumed.fiber,
                    target: targets?.fiberTarget,
                    unit: 'g',
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 4),
                  _MiniChip(
                    label: 'Az',
                    value: consumed.sugar,
                    target: targets?.sugarLimit,
                    unit: 'g',
                    color: const Color(0xFFFF9800),
                  ),
                ],
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                _MacroProgressBar(
                  label: 'Fibra',
                  icon: Icons.grass,
                  consumed: consumed.fiber,
                  target: targets?.fiberTarget,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(height: 12),
                _MacroProgressBar(
                  label: 'Azúcar',
                  icon: Icons.cookie_outlined,
                  consumed: consumed.sugar,
                  target: targets?.sugarLimit,
                  color: const Color(0xFFFF9800),
                ),
                const SizedBox(height: 12),
                _MacroProgressBar(
                  label: 'Grasa saturada',
                  icon: Icons.water_drop_outlined,
                  consumed: consumed.saturatedFat,
                  target: targets?.saturatedFatLimit,
                  color: const Color(0xFFF44336),
                ),
                const SizedBox(height: 12),
                _MacroProgressBar(
                  label: 'Sodio',
                  icon: Icons.local_fire_department_outlined,
                  consumed: consumed.sodium,
                  target: targets?.sodiumLimit,
                  color: const Color(0xFF9C27B0),
                ),
              ],
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

/// Mini chip de micronutriente para vista colapsada
class _MiniChip extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final String unit;
  final Color color;

  const _MiniChip({
    required this.label,
    required this.value,
    this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = target != null && value > target!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isOver ? Colors.red : color).withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label:${value.toStringAsFixed(0)}$unit',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isOver ? Colors.red : color,
        ),
      ),
    );
  }
}

/// Card con estado del día (análisis rápido).
class _DayStatusCard extends StatelessWidget {
  final DaySummary summary;

  const _DayStatusCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _calculateStatus();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: status.color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(status.icon, color: status.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _calculateStatus() {
    if (!summary.hasTargets) {
      return _StatusInfo(
        icon: Icons.info_outline,
        color: Colors.blue,
        title: 'Sin objetivo',
        message: 'Configura un objetivo para ver anÃ¡lisis del dÃ­a.',
      );
    }

    if (!summary.hasConsumption) {
      return _StatusInfo(
        icon: Icons.restaurant_outlined,
        color: Colors.orange,
        title: 'DÃ­a vacÃ­o',
        message: 'AÃºn no has registrado consumo para este dÃ­a.',
      );
    }

    final kcalPercent = summary.progress.kcalPercent ?? 0;
    if (kcalPercent < 0.5) {
      return _StatusInfo(
        icon: Icons.trending_down,
        color: Colors.green,
        title: 'Por debajo del objetivo',
        message: 'Tienes muchas calorÃ­as disponibles para el resto del dÃ­a.',
      );
    } else if (kcalPercent < 0.9) {
      return _StatusInfo(
        icon: Icons.trending_flat,
        color: Colors.orange,
        title: 'En rango',
        message: 'Vas bien, mantÃ©n el control para llegar a tu objetivo.',
      );
    } else if (kcalPercent <= 1.0) {
      return _StatusInfo(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        title: 'Cerca del objetivo',
        message: 'Â¡Bien! EstÃ¡s muy cerca de tu objetivo diario.',
      );
    } else {
      return _StatusInfo(
        icon: Icons.warning_amber,
        color: Colors.red,
        title: 'Por encima del objetivo',
        message: 'Has superado tu objetivo calÃ³rico para hoy.',
      );
    }
  }
}

class _StatusInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  _StatusInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

/// GrÃ¡fico de barras de la tendencia semanal de calorÃ­as.
class _WeeklyTrendChart extends ConsumerWidget {
  const _WeeklyTrendChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weeklyCalorieTrendProvider);

    return trendAsync.when(
      data: (data) => _TrendChartContent(data: data),
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) =>
          SizedBox(height: 160, child: Center(child: Text('Error: $e'))),
    );
  }
}

/// Contenido del grÃ¡fico de tendencia.
class _TrendChartContent extends StatelessWidget {
  final List<DayTrendData> data;

  const _TrendChartContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasTarget = data.isNotEmpty && data.first.kcalTarget != null;

    // Calcular el mÃ¡ximo para escalar las barras
    final maxKcal = data.fold<int>(
      hasTarget ? (data.first.kcalTarget! * 1.2).round() : 2500,
      (max, d) => d.kcalConsumed > max ? d.kcalConsumed : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leyenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: colorScheme.primary, label: 'Consumido'),
                if (hasTarget) ...[
                  const SizedBox(width: 16),
                  _LegendItem(
                    color: Colors.green.withAlpha(128),
                    label: 'Objetivo',
                    dashed: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Barras
            SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((d) {
                  final barHeight = maxKcal > 0
                      ? (d.kcalConsumed / maxKcal * 100).clamp(0.0, 100.0)
                      : 0.0;
                  final targetHeight = hasTarget && maxKcal > 0
                      ? (d.kcalTarget! / maxKcal * 100).clamp(0.0, 100.0)
                      : 0.0;
                  final isToday = _isSameDay(d.date, DateTime.now());

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _DayBar(
                        dayName: DateFormat(
                          'E',
                          'es',
                        ).format(d.date).substring(0, 2),
                        kcal: d.kcalConsumed,
                        barHeight: barHeight,
                        targetHeight: targetHeight,
                        isToday: isToday,
                        isOverTarget:
                            hasTarget && d.kcalConsumed > d.kcalTarget!,
                        colorScheme: colorScheme,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Promedio semanal
            const SizedBox(height: 12),
            Center(
              child: Text(
                _calculateAverage(),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateAverage() {
    if (data.isEmpty) return '';
    final daysWithData = data.where((d) => d.kcalConsumed > 0).toList();
    if (daysWithData.isEmpty) return 'Sin datos esta semana';

    final avg =
        daysWithData.fold<int>(0, (sum, d) => sum + d.kcalConsumed) ~/
        daysWithData.length;
    return 'Promedio: $avg kcal/dÃ­a (${daysWithData.length} dÃ­as con registro)';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Barra individual de un dÃ­a.
class _DayBar extends StatelessWidget {
  final String dayName;
  final int kcal;
  final double barHeight;
  final double targetHeight;
  final bool isToday;
  final bool isOverTarget;
  final ColorScheme colorScheme;

  const _DayBar({
    required this.dayName,
    required this.kcal,
    required this.barHeight,
    required this.targetHeight,
    required this.isToday,
    required this.isOverTarget,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Barra con indicador de objetivo
        SizedBox(
          height: 80,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // LÃ­nea de objetivo
              if (targetHeight > 0)
                Positioned(
                  bottom: targetHeight * 0.8,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(128),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              // Barra de consumo
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: barHeight * 0.8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kcal == 0
                      ? Colors.grey.shade200
                      : isOverTarget
                      ? Colors.red.shade400
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Nombre del dÃ­a
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: isToday
              ? BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Text(
            dayName.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Item de leyenda.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: dashed ? 2 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(dashed ? 1 : 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WEEKLY INSIGHTS CARD
// ============================================================================

/// Card con insights de la semana actual y comparaciÃ³n con anterior
class _WeeklyInsightsCard extends ConsumerWidget {
  const _WeeklyInsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(weeklyInsightsProvider);
    final colors = Theme.of(context).colorScheme;

    return insightsAsync.when(
      data: (insights) {
        if (insights.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Sin datos suficientes para anÃ¡lisis semanal',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          );
        }

        final current = insights.first;
        final previous = insights.length > 1 ? insights[1] : null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con semana actual
                Row(
                  children: [
                    Icon(Icons.insights, color: colors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        current.isCurrentWeek
                            ? 'Esta semana'
                            : current.weekLabel,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _AdherenceBadge(insight: current),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // MÃ©tricas principales
                Row(
                  children: [
                    Expanded(
                      child: _InsightMetric(
                        icon: Icons.restaurant,
                        label: 'DÃ­as registrados',
                        value: '${current.daysLogged}/7',
                        color: colors.primary,
                      ),
                    ),
                    Expanded(
                      child: _InsightMetric(
                        icon: Icons.local_fire_department,
                        label: 'Prom. diario',
                        value: '${current.avgKcalPerDay} kcal',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // ComparaciÃ³n con semana anterior
                if (previous != null &&
                    previous.daysLogged > 0 &&
                    current.kcalChangeVsLastWeek != null) ...[
                  const Divider(height: 24),
                  _WeekComparison(
                    change: current.kcalChangeVsLastWeek!,
                    previousAvg: previous.avgKcalPerDay,
                  ),
                ],

                // Macros promedio
                if (current.daysLogged > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  _MacrosSummaryRow(
                    protein: current.avgProtein,
                    carbs: current.avgCarbs,
                    fat: current.avgFat,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

/// Badge de adherencia
class _AdherenceBadge extends StatelessWidget {
  final WeeklyInsight insight;

  const _AdherenceBadge({required this.insight});

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(insight.adherenceColorIndex);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        insight.adherenceMessage,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.$1,
        ),
      ),
    );
  }

  (Color, Color) _getColors(int index) {
    return switch (index) {
      0 => (Colors.green, Colors.green.shade100),
      1 => (Colors.blue, Colors.blue.shade100),
      2 => (Colors.orange, Colors.orange.shade100),
      _ => (Colors.red, Colors.red.shade100),
    };
  }
}

/// MÃ©trica individual del insight
class _InsightMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

/// ComparaciÃ³n con semana anterior
class _WeekComparison extends StatelessWidget {
  final int change;
  final int previousAvg;

  const _WeekComparison({required this.change, required this.previousAvg});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPositive = change > 0;
    final changeColor = isPositive ? Colors.orange : Colors.green;
    final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      children: [
        Icon(changeIcon, size: 16, color: changeColor),
        const SizedBox(width: 4),
        Text(
          '${change.abs()} kcal/dÃ­a vs semana anterior',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const Spacer(),
        Text(
          'Antes: $previousAvg',
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurfaceVariant.withAlpha((0.7 * 255).round()),
          ),
        ),
      ],
    );
  }
}

/// Fila de resumen de macros
class _MacrosSummaryRow extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;

  const _MacrosSummaryRow({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MacroItem(
            label: 'Prot',
            value: protein,
            unit: 'g',
            color: Colors.blue,
          ),
          _MacroItem(
            label: 'Carbs',
            value: carbs,
            unit: 'g',
            color: Colors.orange,
          ),
          _MacroItem(
            label: 'Grasa',
            value: fat,
            unit: 'g',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

/// Item de macro individual
class _MacroItem extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)}$unit',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
// ============================================================================
// TDEE TREND CHART (estilo MacroFactor)
// ============================================================================

/// Card con gráfico de tendencia TDEE.
///
/// Muestra la evolución del TDEE estimado en los últimos 90 días
/// usando un LineChart de fl_chart. Incluye líneas de referencia
/// para el TDEE inicial y el target actual.
class _TdeeTrendCard extends ConsumerWidget {
  const _TdeeTrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(tdeeTrendChartDataProvider);
    final trendAsync = ref.watch(tdeeTrendProvider);

    return chartDataAsync.when(
      data: (chartData) {
        if (!chartData.hasData) {
          return _TdeeTrendEmpty();
        }

        final trend = trendAsync.whenOrNull(data: (t) => t);

        return Card(
          elevation: 0,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withAlpha((0.5 * 255).round()),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con icono y TDEE actual
                _TdeeTrendHeader(trend: trend),
                const SizedBox(height: AppSpacing.sm),

                // Selector de período
                const _EnergyPeriodSelector(),
                const SizedBox(height: AppSpacing.md),

                // Stats compactos
                if (trend != null && trend.hasData)
                  _TdeeTrendStats(trend: trend),

                const SizedBox(height: AppSpacing.lg),

                // Gráfico con línea de intake
                SizedBox(
                  height: 200,
                  child: _TdeeTrendLineChart(chartData: chartData),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Leyenda
                const _EnergyChartLegend(),
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        elevation: 0,
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withAlpha((0.5 * 255).round()),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Estado vacío cuando no hay datos suficientes para TDEE.
class _TdeeTrendEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest
          .withAlpha((0.5 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.trending_up,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant
                  .withAlpha((0.4 * 255).round()),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tendencia TDEE',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Registra al menos 2 semanas de diario y pesajes '
              'para ver tu TDEE real calculado.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header del gráfico TDEE con icono y valor actual.
class _TdeeTrendHeader extends StatelessWidget {
  final TdeeTrendResult? trend;

  const _TdeeTrendHeader({required this.trend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'TDEE Estimado',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (trend?.currentTdee != null) ...[
          _TdeeTrendBadge(direction: trend!.direction),
          const SizedBox(width: 8),
          Text(
            '${trend!.currentTdee!.round()} kcal',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Badge que indica la dirección de la tendencia.
class _TdeeTrendBadge extends StatelessWidget {
  final TdeeTrendDirection direction;

  const _TdeeTrendBadge({required this.direction});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (direction) {
      TdeeTrendDirection.increasing => (
          Icons.trending_up,
          AppColors.success,
          'Subiendo'),
      TdeeTrendDirection.stable => (
          Icons.trending_flat,
          Colors.blueGrey,
          'Estable'),
      TdeeTrendDirection.decreasing => (
          Icons.trending_down,
          AppColors.error,
          'Bajando'),
      TdeeTrendDirection.insufficient => (
          Icons.hourglass_empty,
          Colors.grey,
          'Calculando'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats compactos del TDEE (promedio, cambio semanal, rango).
class _TdeeTrendStats extends StatelessWidget {
  final TdeeTrendResult trend;

  const _TdeeTrendStats({required this.trend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TdeeStatItem(
          label: 'Promedio',
          value: trend.avgTdee != null
              ? '${trend.avgTdee!.round()}'
              : '—',
          unit: 'kcal',
        ),
        Container(
          height: 24,
          width: 1,
          color: theme.colorScheme.outlineVariant,
        ),
        _TdeeStatItem(
          label: 'Δ Semanal',
          value: trend.weeklyChangeKcal != null
              ? '${trend.weeklyChangeKcal! >= 0 ? '+' : ''}${trend.weeklyChangeKcal!.round()}'
              : '—',
          unit: 'kcal',
          valueColor: trend.weeklyChangeKcal != null
              ? (trend.weeklyChangeKcal! > 30
                  ? AppColors.success
                  : trend.weeklyChangeKcal! < -30
                      ? AppColors.error
                      : null)
              : null,
        ),
        Container(
          height: 24,
          width: 1,
          color: theme.colorScheme.outlineVariant,
        ),
        _TdeeStatItem(
          label: 'Rango',
          value: '${(trend.maxTdee - trend.minTdee).round()}',
          unit: 'kcal',
        ),
      ],
    );
  }
}

class _TdeeStatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const _TdeeStatItem({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value $unit',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Selector de período para el gráfico de balance energético.
class _EnergyPeriodSelector extends ConsumerWidget {
  const _EnergyPeriodSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(energyChartPeriodProvider);
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final p in [14, 30, 60, 90])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text('${p}d'),
              selected: period == p,
              onSelected: (_) =>
                  ref.read(energyChartPeriodProvider.notifier).setPeriod(p),
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: period == p ? FontWeight.w700 : FontWeight.w500,
                color: period == p ? cs.onPrimary : cs.onSurfaceVariant,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}

/// Leyenda del gráfico de balance energético.
class _EnergyChartLegend extends StatelessWidget {
  const _EnergyChartLegend();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: cs.primary, label: 'TDEE'),
        const SizedBox(width: AppSpacing.md),
        _LegendDot(color: cs.tertiary, label: 'Ingesta'),
        const SizedBox(width: AppSpacing.md),
        _LegendDot(
          color: AppColors.success.withAlpha((0.6 * 255).round()),
          label: 'Target',
          dashed: true,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dashed ? 16 : 8,
          height: dashed ? 2 : 8,
          decoration: BoxDecoration(
            color: dashed ? null : color,
            borderRadius: dashed ? null : BorderRadius.circular(4),
            border: dashed ? Border(top: BorderSide(color: color, width: 2)) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Gráfico de línea de tendencia TDEE.
class _TdeeTrendLineChart extends StatelessWidget {
  final TdeeChartData chartData;

  const _TdeeTrendLineChart({required this.chartData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tdeeSpots = chartData.points.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.estimatedTdee);
    }).toList();

    // Línea de ingesta (avgIntake por punto)
    final intakeSpots = chartData.points.asMap().entries
        .where((e) => e.value.avgIntake > 0)
        .map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.avgIntake);
    }).toList();

    // Línea de referencia: TDEE inicial del CoachPlan
    final initialSpots = chartData.initialEstimate != null
        ? [
            FlSpot(0, chartData.initialEstimate!),
            FlSpot((tdeeSpots.length - 1).toDouble(), chartData.initialEstimate!),
          ]
        : <FlSpot>[];

    // Línea de referencia: target kcal actual
    final targetSpots = chartData.currentTarget != null
        ? [
            FlSpot(0, chartData.currentTarget!),
            FlSpot((tdeeSpots.length - 1).toDouble(), chartData.currentTarget!),
          ]
        : <FlSpot>[];

    // Bounds incluyendo intake
    final allValues = [
      ...tdeeSpots.map((s) => s.y),
      ...intakeSpots.map((s) => s.y),
      if (chartData.initialEstimate != null) chartData.initialEstimate!,
      if (chartData.currentTarget != null) chartData.currentTarget!,
    ];
    final effectiveMinY =
        allValues.reduce((a, b) => a < b ? a : b) - chartData.padding;
    final effectiveMaxY =
        allValues.reduce((a, b) => a > b ? a : b) + chartData.padding;
    final yRange = effectiveMaxY - effectiveMinY;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yRange > 0 ? yRange / 4 : 100,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: _calculateBottomInterval(tdeeSpots.length),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= chartData.dates.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  DateFormat('d/M', 'es').format(chartData.dates[index]),
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (tdeeSpots.length - 1).toDouble(),
        minY: effectiveMinY,
        maxY: effectiveMaxY,
        lineBarsData: [
          // Línea principal: TDEE suavizado
          LineChartBarData(
            spots: tdeeSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary
                  .withAlpha((0.08 * 255).round()),
            ),
          ),
          // Línea de ingesta promedio
          if (intakeSpots.length >= 2)
            LineChartBarData(
              spots: intakeSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: theme.colorScheme.tertiary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.tertiary
                    .withAlpha((0.06 * 255).round()),
              ),
            ),
          // Línea de referencia: TDEE inicial
          if (initialSpots.isNotEmpty)
            LineChartBarData(
              spots: initialSpots,
              isCurved: false,
              color: Colors.blueGrey.withAlpha((0.5 * 255).round()),
              barWidth: 1.5,
              dashArray: [6, 4],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          // Línea de referencia: target actual
          if (targetSpots.isNotEmpty)
            LineChartBarData(
              spots: targetSpots,
              isCurved: false,
              color: AppColors.success.withAlpha((0.6 * 255).round()),
              barWidth: 1.5,
              dashArray: [4, 4],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                theme.colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                // Solo tooltip para las dos líneas principales (TDEE + intake)
                if (spot.barIndex > 1) return null;
                final index = spot.x.toInt();
                if (index < 0 || index >= chartData.points.length) {
                  return null;
                }
                final point = chartData.points[index];
                if (spot.barIndex == 0) {
                  // TDEE line
                  return LineTooltipItem(
                    'TDEE: ${point.estimatedTdee.round()} kcal\n',
                    TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: DateFormat('d MMM', 'es').format(point.date),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                } else {
                  // Intake line
                  return LineTooltipItem(
                    'Ingesta: ${point.avgIntake.round()} kcal',
                    TextStyle(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
              }).whereType<LineTooltipItem>().toList();
            },
          ),
        ),
      ),
    );
  }

  double _calculateBottomInterval(int pointCount) {
    if (pointCount <= 14) return 2;
    if (pointCount <= 30) return 5;
    if (pointCount <= 60) return 10;
    return 15;
  }
}
