import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/home_button.dart';
import '../../../diet/providers/coach_providers.dart';
import '../../../diet/providers/diet_providers.dart';
import '../../../diet/providers/weekly_insights_provider.dart';
import '../../../diet/services/day_summary_calculator.dart';

/// Pantalla de resumen tipo "budget" con progreso detallado.
///
/// Muestra:
/// - Consumo del día vs objetivos
/// - Barras de progreso visuales
/// - Historial reciente
/// - Acceso rápido a gestión de objetivos
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(daySummaryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final coachPlan = ref.watch(coachPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: HomeButton(),
        ),
      ),
      body: summaryAsync.when(
        data: (summary) => _SummaryContent(
          summary: summary,
          selectedDate: selectedDate,
          coachPlan: coachPlan,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

/// Contenido principal del resumen.
class _SummaryContent extends StatelessWidget {
  final DaySummary summary;
  final DateTime selectedDate;
  final dynamic coachPlan; // CoachPlan?

  const _SummaryContent({
    required this.summary,
    required this.selectedDate,
    this.coachPlan,
  });

  @override
  Widget build(BuildContext context) {
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

          // Gráfico de tendencia semanal
          Text(
            'TENDENCIA SEMANAL',
            style: _sectionStyle(context),
          ),
          const SizedBox(height: 12),
          const _WeeklyTrendChart(),
          const SizedBox(height: 24),

          // Weekly Insights: adherencia y comparación
          Text(
            'RESUMEN SEMANAL',
            style: _sectionStyle(context),
          ),
          const SizedBox(height: 12),
          const _WeeklyInsightsCard(),
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

          // Desglose detallado
          Text(
            'DESGLOSE',
            style: _sectionStyle(context),
          ),
          const SizedBox(height: 12),
          _MacroBreakdown(summary: summary),
          const SizedBox(height: 24),

          // Estado del día
          Text(
            'ESTADO DEL DÍA',
            style: _sectionStyle(context),
          ),
          const SizedBox(height: 12),
          _DayStatusCard(summary: summary),
        ],
      ),
    );
  }

  TextStyle _sectionStyle(BuildContext context) {
    return GoogleFonts.montserrat(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: Theme.of(context).colorScheme.primary,
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
          style: GoogleFonts.montserrat(
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

/// Card principal de budget con calorías y progreso.
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
    final progress = hasTarget ? (consumedKcal / targetKcal).clamp(0.0, 1.0) : 0.0;
    final percentage = hasTarget ? ((consumedKcal / targetKcal) * 100).round() : 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'CALORÍAS',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Números principales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$consumedKcal',
                  style: GoogleFonts.montserrat(
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
                      style: GoogleFonts.montserrat(
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
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
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
              // Información de progreso
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
                  color: colorScheme.secondaryContainer.withAlpha((0.5 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sin objetivo configurado',
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                      ),
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

/// Estadística individual del budget.
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
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// CTA para crear objetivos cuando no hay ninguno.
class _CreateTargetsCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      elevation: 0,
      child: InkWell(
        onTap: () => context.pushTo(AppRouter.nutritionCoach),
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
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define calorías y macros para ver tu progreso y mantenerte en track.',
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

/// Indicador de que se está usando el Coach Adaptativo.
class _CoachPlanIndicator extends StatelessWidget {
  final dynamic plan; // CoachPlan

  const _CoachPlanIndicator({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.secondaryContainer.withAlpha(128),
      elevation: 0,
      child: InkWell(
        onTap: () => context.pushTo(AppRouter.nutritionCoach),
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
                      style: GoogleFonts.montserrat(
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

/// Desglose detallado de macros con barras de progreso.
class _MacroBreakdown extends StatelessWidget {
  final DaySummary summary;

  const _MacroBreakdown({required this.summary});

  @override
  Widget build(BuildContext context) {
    final targets = summary.targets;

    return Column(
      children: [
        _MacroProgressBar(
          label: 'Proteína',
          icon: Icons.fitness_center,
          consumed: summary.consumed.protein,
          target: targets?.proteinTarget,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 16),
        _MacroProgressBar(
          label: 'Carbohidratos',
          icon: Icons.grain,
          consumed: summary.consumed.carbs,
          target: targets?.carbsTarget,
          color: Colors.amber.shade600,
        ),
        const SizedBox(height: 16),
        _MacroProgressBar(
          label: 'Grasa',
          icon: Icons.water_drop,
          consumed: summary.consumed.fat,
          target: targets?.fatTarget,
          color: Colors.blue.shade400,
        ),
      ],
    );
  }
}

/// Barra de progreso individual para un macro.
class _MacroProgressBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double consumed;
  final double? target;
  final Color color;

  const _MacroProgressBar({
    required this.label,
    required this.icon,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = target != null && target! > 0;
    final progress = hasTarget ? (consumed / target!).clamp(0.0, 1.0) : 0.0;
    final percentage = hasTarget ? ((consumed / target!) * 100).round() : 0;

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
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: color.withAlpha((0.2 * 255).round()),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
                    style: GoogleFonts.montserrat(
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
        message: 'Configura un objetivo para ver análisis del día.',
      );
    }

    if (!summary.hasConsumption) {
      return _StatusInfo(
        icon: Icons.restaurant_outlined,
        color: Colors.orange,
        title: 'Día vacío',
        message: 'Aún no has registrado consumo para este día.',
      );
    }

    final kcalPercent = summary.progress.kcalPercent ?? 0;
    if (kcalPercent < 0.5) {
      return _StatusInfo(
        icon: Icons.trending_down,
        color: Colors.green,
        title: 'Por debajo del objetivo',
        message: 'Tienes muchas calorías disponibles para el resto del día.',
      );
    } else if (kcalPercent < 0.9) {
      return _StatusInfo(
        icon: Icons.trending_flat,
        color: Colors.orange,
        title: 'En rango',
        message: 'Vas bien, mantén el control para llegar a tu objetivo.',
      );
    } else if (kcalPercent <= 1.0) {
      return _StatusInfo(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        title: 'Cerca del objetivo',
        message: '¡Bien! Estás muy cerca de tu objetivo diario.',
      );
    } else {
      return _StatusInfo(
        icon: Icons.warning_amber,
        color: Colors.red,
        title: 'Por encima del objetivo',
        message: 'Has superado tu objetivo calórico para hoy.',
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

/// Gráfico de barras de la tendencia semanal de calorías.
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
      error: (e, st) => SizedBox(
        height: 160,
        child: Center(child: Text('Error: $e')),
      ),
    );
  }
}

/// Contenido del gráfico de tendencia.
class _TrendChartContent extends StatelessWidget {
  final List<DayTrendData> data;

  const _TrendChartContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasTarget = data.isNotEmpty && data.first.kcalTarget != null;

    // Calcular el máximo para escalar las barras
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
                        dayName: DateFormat('E', 'es').format(d.date).substring(0, 2),
                        kcal: d.kcalConsumed,
                        barHeight: barHeight,
                        targetHeight: targetHeight,
                        isToday: isToday,
                        isOverTarget: hasTarget && d.kcalConsumed > d.kcalTarget!,
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

    final avg = daysWithData.fold<int>(0, (sum, d) => sum + d.kcalConsumed) ~/
        daysWithData.length;
    return 'Promedio: $avg kcal/día (${daysWithData.length} días con registro)';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Barra individual de un día.
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
              // Línea de objetivo
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
        // Nombre del día
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
              color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
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

/// Card con insights de la semana actual y comparación con anterior
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
                'Sin datos suficientes para análisis semanal',
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
                        current.isCurrentWeek ? 'Esta semana' : current.weekLabel,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _AdherenceBadge(insight: current),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Métricas principales
                Row(
                  children: [
                    Expanded(
                      child: _InsightMetric(
                        icon: Icons.restaurant,
                        label: 'Días registrados',
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

                // Comparación con semana anterior
                if (previous != null && previous.daysLogged > 0 && current.kcalChangeVsLastWeek != null) ...[
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

/// Métrica individual del insight
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
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Comparación con semana anterior
class _WeekComparison extends StatelessWidget {
  final int change;
  final int previousAvg;

  const _WeekComparison({
    required this.change,
    required this.previousAvg,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPositive = change > 0;
    final changeColor = isPositive ? Colors.orange : Colors.green;
    final changeIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      children: [
        Icon(
          changeIcon,
          size: 16,
          color: changeColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${change.abs()} kcal/día vs semana anterior',
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
          ),
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
          _MacroItem(label: 'Prot', value: protein, unit: 'g', color: Colors.blue),
          _MacroItem(label: 'Carbs', value: carbs, unit: 'g', color: Colors.orange),
          _MacroItem(label: 'Grasa', value: fat, unit: 'g', color: Colors.purple),
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
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
