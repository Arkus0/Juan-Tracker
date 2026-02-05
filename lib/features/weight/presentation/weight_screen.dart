// Weight Screen - Enhanced version with chart and tooltips
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/diet/providers/goal_projection_providers.dart';
import 'package:juan_tracker/diet/models/weighin_model.dart';
import 'package:juan_tracker/diet/models/goal_projection_model.dart';
import 'package:juan_tracker/diet/services/adaptive_coach_service.dart';
import 'package:juan_tracker/diet/services/weight_input_validator.dart';
import 'package:juan_tracker/diet/services/weight_trend_calculator.dart';

import 'package:intl/intl.dart';

class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Peso'),
            centerTitle: true,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: HomeButton(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _MainStatsSection(),
            ),
          ),
          // Card de proyecciÃƒÂ³n de objetivo (Goal ETA)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _GoalProjectionCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          // NUEVO: Analytics avanzados
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _EnhancedAnalyticsCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          // GrÃƒÂ¡fica de evoluciÃƒÂ³n
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _WeightChartCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          // Contexto de progreso
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _ProgressContextCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          _WeighInsListSliver(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<double?>(
            context: context,
            builder: (context) => const AddWeightDialog(),
          );

          if (result != null && context.mounted) {
            // Mostrar confirmaciÃƒÂ³n mÃƒÂ¡s detallada
            AppSnackbar.show(
              context,
              message: '${result.toStringAsFixed(1)} kg registrado',
            );
            // Forzar refresco de providers
            ref.invalidate(weightTrendProvider);
            ref.invalidate(recentWeighInsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
    );
  }
}

class AddWeightDialog extends ConsumerStatefulWidget {
  const AddWeightDialog({super.key});

  @override
  ConsumerState<AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends ConsumerState<AddWeightDialog> {
  late final TextEditingController _weightController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    final value = WeightInputValidator.parse(_weightController.text);
    final validationError = WeightInputValidator.validate(
      _weightController.text,
    );

    if (value == null || validationError != null) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          message: validationError ?? 'Ingresa un peso válido',
        );
      }
      return;
    }

    final repo = ref.read(weighInRepositoryProvider);
    final id = 'wi_${DateTime.now().millisecondsSinceEpoch}';
    await repo.insert(
      WeighInModel(id: id, dateTime: _selectedDate, weightKg: value),
    );
    if (mounted) {
      Navigator.of(context).pop(value); // Devolver el valor del peso
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Peso (kg)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Fecha: '),
              TextButton(
                onPressed: _selectDate,
                child: Text(
                  DateFormat('d MMM yyyy', 'es').format(_selectedDate),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('CANCELAR'),
        ),
        FilledButton(onPressed: _save, child: const Text('GUARDAR')),
      ],
    );
  }
}

/// Card de estadÃƒÂ­sticas principales con tooltips
class _MainStatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);

    return trendAsync.when(
      data: (result) {
        if (result == null) {
          return AppEmpty(
            icon: Icons.scale_outlined,
            title: 'Sin registros',
            subtitle: 'Registra tu primer peso',
          );
        }
        return Row(
          children: [
            Expanded(
              child: _StatCardWithTooltip(
                label: 'ÃƒÅ¡ltimo',
                value: result.latestWeight.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.scale_outlined,
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Tu ÃƒÂºltimo peso registrado',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCardWithTooltip(
                label: 'Tendencia',
                value: result.trendWeight.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.trending_flat,
                color: Theme.of(context).colorScheme.secondary,
                tooltip:
                    'Media mÃƒÂ³vil de 7 dÃƒÂ­as que suaviza fluctuaciones diarias',
                onTap: () => _showTrendDetailsDialog(context, result),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCardWithTooltip(
                label: 'Semana',
                value:
                    '${result.weeklyRate >= 0 ? '+' : ''}${result.weeklyRate.toStringAsFixed(1)}',
                unit: 'kg',
                icon: result.weeklyRate > 0
                    ? Icons.trending_up
                    : result.weeklyRate < 0
                    ? Icons.trending_down
                    : Icons.trending_flat,
                color: _getWeeklyRateColor(result.weeklyRate),
                tooltip: 'Ritmo de cambio estimado en kg por semana',
                onTap: () => _showWeekDetailsDialog(context, result),
              ),
            ),
          ],
        );
      },
      loading: () => const AppLoading(),
      error: (_, _) => AppError(
        message: 'Error al cargar',
        onRetry: () => ref.invalidate(weightTrendProvider),
      ),
    );
  }

  Color _getWeeklyRateColor(double rate) {
    if (rate.abs() < 0.1) return AppColors.success; // Mantenimiento
    if (rate < 0) return AppColors.info; // Perdiendo
    return Colors.orange; // Ganando
  }

  void _showTrendDetailsDialog(BuildContext context, WeightTrendResult result) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            const Flexible(child: Text('Tendencia')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: 'Peso tendencia',
                value: '${result.trendWeight.toStringAsFixed(2)} kg',
                description: 'Combina EMA y filtro Kalman',
              ),
              const Divider(),
              _DetailRow(
                label: 'EMA (Media MÃƒÂ³vil)',
                value: '${result.emaWeight.toStringAsFixed(2)} kg',
                description: 'Suaviza fluctuaciones diarias',
              ),
              _DetailRow(
                label: 'Kalman (Filtro)',
                value: '${result.kalmanWeight.toStringAsFixed(2)} kg',
                description: 'EstimaciÃƒÂ³n mÃƒÂ¡s precisa',
              ),
              _DetailRow(
                label: 'Confianza Kalman',
                value: '${(result.kalmanConfidence * 100).round()}%',
                description: 'Fiabilidad del modelo',
              ),
              const Divider(),
              _DetailRow(
                label: 'Pendiente (RÃ‚Â²)',
                value: '${(result.regressionR2 * 100).round()}%',
                description: 'Ajuste de regresiÃƒÂ³n lineal',
              ),
              _DetailRow(
                label: 'Varianza',
                value:
                    '${result.variance >= 0 ? '+' : ''}${result.variance.toStringAsFixed(2)} kg',
                description: 'DesviaciÃƒÂ³n del peso actual vs tendencia',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  void _showWeekDetailsDialog(BuildContext context, WeightTrendResult result) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.calendar_month, color: colors.primary),
            const SizedBox(width: 8),
            const Text('AnÃƒÂ¡lisis Semanal'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                label: 'Ritmo semanal',
                value:
                    '${result.weeklyRate >= 0 ? '+' : ''}${result.weeklyRate.toStringAsFixed(2)} kg/sem',
                description: result.phaseDescription,
              ),
              const Divider(),
              _DetailRow(
                label: 'Fase actual',
                value: _getPhaseName(result.phase),
                description: '${result.daysInPhase} dÃƒÂ­as en esta fase',
              ),
              _DetailRow(
                label: 'Tendencia diaria',
                value: '${(result.hwTrend * 1000).round()} g/dÃƒÂ­a',
                description: 'Modelo Holt-Winters',
              ),
              if (result.hwPrediction7d != null) ...[
                const Divider(),
                _DetailRow(
                  label: 'PredicciÃƒÂ³n 7 dÃƒÂ­as',
                  value: '${result.hwPrediction7d!.toStringAsFixed(1)} kg',
                  description: 'Si mantienes este ritmo',
                ),
              ],
              if (result.hwPrediction30d != null)
                _DetailRow(
                  label: 'PredicciÃƒÂ³n 30 dÃƒÂ­as',
                  value: '${result.hwPrediction30d!.toStringAsFixed(1)} kg',
                  description: 'ProyecciÃƒÂ³n a un mes',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  String _getPhaseName(WeightPhase phase) {
    switch (phase) {
      case WeightPhase.losing:
        return 'Perdiendo peso';
      case WeightPhase.maintaining:
        return 'Mantenimiento';
      case WeightPhase.gaining:
        return 'Ganando peso';
      case WeightPhase.insufficientData:
        return 'Recopilando datos';
    }
  }
}

/// Fila de detalle para los diÃƒÂ¡logos analÃƒÂ­ticos
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String description;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant.withAlpha(180),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de estadÃƒÂ­stica con tooltip informativo
class _StatCardWithTooltip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const _StatCardWithTooltip({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: onTap != null
          ? '$tooltip\n(Pulsa para mÃƒÂ¡s detalles)'
          : tooltip,
      preferBelow: true,
      child: AppStatCard(
        label: label,
        value: value,
        unit: unit,
        icon: icon,
        color: color,
        onTap: onTap,
      ),
    );
  }
}

/// Card con grÃƒÂ¡fica de evoluciÃƒÂ³n de peso
class _WeightChartCard extends ConsumerWidget {
  const _WeightChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighInsAsync = ref.watch(recentWeighInsProvider);

    return weighInsAsync.when(
      data: (weighIns) {
        if (weighIns.length < 2) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EvoluciÃƒÂ³n (30 dÃƒÂ­as)',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 200,
                  child: _WeightLineChart(weighIns: weighIns),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// GrÃƒÂ¡fica de lÃƒÂ­nea para evoluciÃƒÂ³n de peso
/// PERF: Uses memoized stats from weightChartStatsProvider
/// FEATURE: Muestra lÃƒÂ­nea de objetivo si hay CoachPlan activo
class _WeightLineChart extends ConsumerWidget {
  final List<WeighInModel> weighIns;

  const _WeightLineChart({required this.weighIns});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // PERF: Use memoized stats instead of calculating in build()
    final statsAsync = ref.watch(weightChartStatsProvider);
    // Goal line: peso objetivo desde GoalProjection
    final goalWeight = ref.watch(effectiveGoalWeightProvider);

    return statsAsync.when(
      data: (stats) {
        if (stats == null) {
          return const Center(child: Text('Se necesitan mÃƒÂ¡s datos'));
        }
        return _buildChart(context, theme, stats, goalWeight);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Error al cargar datos')),
    );
  }

  Widget _buildChart(
    BuildContext context,
    ThemeData theme,
    WeightChartStats stats,
    double? goalWeight,
  ) {
    // Filter to last 30 days for display
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final filteredWeighIns =
        weighIns.where((w) => w.dateTime.isAfter(cutoffDate)).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (filteredWeighIns.length < 2) {
      return const Center(child: Text('Se necesitan mÃƒÂ¡s datos'));
    }

    // PERF: Use pre-computed values from provider
    final minWeight = stats.minWeight;
    final maxWeight = stats.maxWeight;
    final weightRange = stats.weightRange;
    final padding = stats.padding;

    // Ajustar lÃƒÂ­mites para incluir el peso objetivo si existe
    final adjustedMinWeight = goalWeight != null
        ? (minWeight < goalWeight ? minWeight : goalWeight)
        : minWeight;
    final adjustedMaxWeight = goalWeight != null
        ? (maxWeight > goalWeight ? maxWeight : goalWeight)
        : maxWeight;
    final adjustedPadding = padding;

    final spots = filteredWeighIns.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weightKg);
    }).toList();

    // LÃƒÂ­nea de objetivo (horizontal punteada)
    final goalSpots = goalWeight != null
        ? [
            FlSpot(0, goalWeight),
            FlSpot((filteredWeighIns.length - 1).toDouble(), goalWeight),
          ]
        : <FlSpot>[];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: weightRange > 0 ? weightRange / 4 : 1,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
        maxX: (filteredWeighIns.length - 1).toDouble(),
        minY: adjustedMinWeight - adjustedPadding,
        maxY: adjustedMaxWeight + adjustedPadding,
        lineBarsData: [
          // LÃƒÂ­nea principal de peso
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
            ),
          ),
          // LÃƒÂ­nea de objetivo (punteada)
          if (goalSpots.isNotEmpty)
            LineChartBarData(
              spots: goalSpots,
              isCurved: false,
              color: AppColors.success.withAlpha((0.7 * 255).round()),
              barWidth: 2,
              isStrokeCapRound: true,
              dashArray: [8, 4], // LÃƒÂ­nea punteada
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                theme.colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) {
                    // Solo mostrar tooltip para la lÃƒÂ­nea principal (no para goal line)
                    if (spot.barIndex != 0) return null;
                    final weighIn = filteredWeighIns[spot.x.toInt()];
                    return LineTooltipItem(
                      '${weighIn.weightKg.toStringAsFixed(1)} kg\n',
                      TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: DateFormat(
                            'd MMM',
                            'es',
                          ).format(weighIn.dateTime),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  })
                  .whereType<LineTooltipItem>()
                  .toList();
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GOAL PROJECTION CARD (NEW - Libra-style ETA)
// ============================================================================

/// Card que muestra la proyecciÃƒÂ³n hacia el objetivo de peso
/// Estilo Libra: muestra ETA, progreso, y ritmo actual vs objetivo
class _GoalProjectionCard extends ConsumerWidget {
  const _GoalProjectionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectionAsync = ref.watch(goalProjectionProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return projectionAsync.when(
      data: (projection) {
        // Si no hay proyecciÃƒÂ³n (sin plan o sin datos), no mostrar
        if (projection == null) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          color: colorScheme.primaryContainer.withAlpha((0.4 * 255).round()),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      _getGoalIcon(projection.goal),
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ProyecciÃƒÂ³n de objetivo',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Badge de estado
                    _StatusBadge(
                      isOnTrack: projection.isOnTrack,
                      goalReached: projection.goalReached,
                      goal: projection.goal,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Goal Weight & ETA
                Row(
                  children: [
                    Expanded(
                      child: _GoalMetric(
                        label: 'Meta',
                        value:
                            '${projection.goalWeightKg.toStringAsFixed(1)} kg',
                        icon: Icons.flag_outlined,
                      ),
                    ),
                    Expanded(
                      child: _GoalMetric(
                        label: 'ETA',
                        value: _formatEta(projection),
                        icon: Icons.schedule,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Progress bar
                _ProgressBar(
                  progress: projection.progressPercentage / 100,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 8),

                // Progress message
                Text(
                  projection.progressMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                // Pace message (ritmo actual)
                Text(
                  projection.paceMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  IconData _getGoalIcon(WeightGoal goal) {
    switch (goal) {
      case WeightGoal.lose:
        return Icons.trending_down;
      case WeightGoal.gain:
        return Icons.trending_up;
      case WeightGoal.maintain:
        return Icons.balance;
    }
  }

  String _formatEta(GoalProjection projection) {
    // Para mantener peso, mostrar texto diferente cuando estÃƒÂ¡ en objetivo
    if (projection.goal == WeightGoal.maintain) {
      if (projection.goalReached) return 'En objetivo';
      return 'Ajustando...';
    }

    if (projection.goalReached) return 'Ã‚Â¡Logrado!';

    final date = projection.estimatedGoalDate;
    if (date == null) return 'Ã¢â‚¬â€';

    final days = projection.estimatedDaysToGoal;
    if (days != null && days < 14) {
      return '$days dÃƒÂ­as';
    }

    return DateFormat('MMM yyyy', 'es').format(date);
  }
}

/// Badge que indica si estÃƒÂ¡ on track o no
class _StatusBadge extends StatelessWidget {
  final bool isOnTrack;
  final bool goalReached;
  final WeightGoal goal;

  const _StatusBadge({
    required this.isOnTrack,
    required this.goalReached,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    // Para objetivo "mantener", mostrar texto diferente
    if (goal == WeightGoal.maintain) {
      final isMaintaining = goalReached;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isMaintaining ? AppColors.success : Colors.orange).withAlpha(
            51,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMaintaining ? Icons.balance : Icons.sync,
              size: 14,
              color: isMaintaining ? AppColors.success : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              isMaintaining ? 'Manteniendo' : 'Ajustando',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isMaintaining ? AppColors.success : Colors.orange,
              ),
            ),
          ],
        ),
      );
    }

    if (goalReached) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(51),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              'Meta',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isOnTrack ? AppColors.success : Colors.orange).withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnTrack ? Icons.check : Icons.warning_amber,
            size: 14,
            color: isOnTrack ? AppColors.success : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isOnTrack ? 'En camino' : 'Ajustar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOnTrack ? AppColors.success : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

/// MÃƒÂ©trica de objetivo individual
class _GoalMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _GoalMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: colorScheme.onPrimaryContainer.withAlpha(153),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer.withAlpha(153),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

/// Barra de progreso hacia el objetivo
class _ProgressBar extends StatelessWidget {
  final double progress; // 0.0 - 1.0+
  final ColorScheme colorScheme;

  const _ProgressBar({required this.progress, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onPrimaryContainer.withAlpha(153),
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: 8,
            backgroundColor: colorScheme.onPrimaryContainer.withAlpha(26),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppColors.success : colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card con contexto de progreso
/// PERF: Uses memoized stats from weightChartStatsProvider
class _ProgressContextCard extends ConsumerWidget {
  const _ProgressContextCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PERF: Use memoized stats instead of calculating in build()
    final statsAsync = ref.watch(weightChartStatsProvider);
    final theme = Theme.of(context);

    return statsAsync.when(
      data: (stats) {
        if (stats == null) return const SizedBox.shrink();

        // PERF: Use pre-computed values from provider
        final totalChange = stats.totalChange;
        final daysCount = stats.daysTracking;
        final weeklyAvg = stats.weeklyAverage;

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(
            (0.5 * 255).round(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Tu progreso',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _ProgressItem(
                  icon: Icons.calendar_today,
                  label: 'Llevas registrando',
                  value: '$daysCount dÃƒÂ­as',
                ),
                const SizedBox(height: 8),
                _ProgressItem(
                  icon: totalChange <= 0
                      ? Icons.trending_down
                      : Icons.trending_up,
                  label: 'VariaciÃƒÂ³n total',
                  value:
                      '${totalChange >= 0 ? '+' : ''}${totalChange.toStringAsFixed(1)} kg',
                  valueColor: totalChange < 0
                      ? Colors.green
                      : totalChange > 0
                      ? Colors.orange
                      : theme.colorScheme.onSurface,
                ),
                if (weeklyAvg != null) ...[
                  const SizedBox(height: 8),
                  _ProgressItem(
                    icon: Icons.date_range,
                    label: 'Promedio semanal',
                    value: '${weeklyAvg.toStringAsFixed(1)} kg',
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Item individual de progreso
class _ProgressItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProgressItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Card con anÃƒÂ¡lisis avanzado: velocidad, consistencia, volatilidad
class _EnhancedAnalyticsCard extends ConsumerWidget {
  const _EnhancedAnalyticsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighInsAsync = ref.watch(recentWeighInsProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return weighInsAsync.when(
      data: (weighIns) {
        if (weighIns.length < 7) return const SizedBox.shrink();

        final stats = _calculateStats(weighIns);

        return AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'AnÃƒÂ¡lisis de tendencias',
                      style: AppTypography.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Grid de mÃƒÂ©tricas
                Row(
                  children: [
                    Expanded(
                      child: _AnalyticsMetric(
                        label: 'Velocidad',
                        value:
                            '${stats.velocity > 0 ? '+' : ''}${stats.velocity.toStringAsFixed(1)}',
                        unit: 'kg/sem',
                        icon: stats.velocity > 0
                            ? Icons.trending_up
                            : stats.velocity < 0
                            ? Icons.trending_down
                            : Icons.trending_flat,
                        color: _getVelocityColor(stats.velocity, colors),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _AnalyticsMetric(
                        label: 'Consistencia',
                        value: '${stats.consistency.round()}',
                        unit: '%',
                        icon: Icons.event_available,
                        color: colors.tertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _AnalyticsMetric(
                        label: 'Volatilidad',
                        value: stats.volatility.toStringAsFixed(1),
                        unit: 'kg',
                        icon: Icons.waves,
                        color: colors.secondary,
                      ),
                    ),
                  ],
                ),

                if (stats.bestWeek != null && stats.worstWeek != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // Best vs Worst week
                  Row(
                    children: [
                      Expanded(
                        child: _WeekComparison(
                          label: 'Mejor semana',
                          change: stats.bestWeek!,
                          icon: Icons.arrow_upward,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _WeekComparison(
                          label: 'Semana mÃƒÂ¡s desafiante',
                          change: stats.worstWeek!,
                          icon: Icons.arrow_downward,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],

                // Insight message
                if (stats.insight != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: colors.primary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            stats.insight!,
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.onSurface,
                            ),
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
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Color _getVelocityColor(double velocity, ColorScheme colors) {
    // Para pÃƒÂ©rdida de peso, velocidad negativa es buena
    // Asumimos que la meta es perder peso (ajustar segÃƒÂºn el caso)
    final absVelocity = velocity.abs();
    if (absVelocity < 0.25) return colors.primary; // Mantenimiento
    if (absVelocity < 0.5) return AppColors.success; // Ritmo saludable
    if (absVelocity < 1.0) return Colors.orange; // RÃƒÂ¡pido
    return colors.error; // Muy rÃƒÂ¡pido, posiblemente no saludable
  }

  _StatsResult _calculateStats(List<WeighInModel> weighIns) {
    // Ordenar por fecha
    final sorted = [...weighIns]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Calcular velocidad (cambio por semana en ÃƒÂºltimos 30 dÃƒÂ­as)
    final recent = sorted
        .where(
          (w) => w.dateTime.isAfter(
            DateTime.now().subtract(const Duration(days: 30)),
          ),
        )
        .toList();

    double velocity = 0;
    if (recent.length >= 2) {
      final first = recent.first.weightKg;
      final last = recent.last.weightKg;
      final days = recent.last.dateTime
          .difference(recent.first.dateTime)
          .inDays;
      if (days > 0) {
        velocity = ((last - first) / days) * 7; // kg por semana
      }
    }

    // Calcular consistencia (% de dÃƒÂ­as con registro en ÃƒÂºltimos 30 dÃƒÂ­as)
    final daysWithData = recent
        .map((w) => DateTime(w.dateTime.year, w.dateTime.month, w.dateTime.day))
        .toSet()
        .length;
    final consistency = ((daysWithData / 30.0 * 100).clamp(0, 100)).toDouble();

    // Calcular volatilidad (desviaciÃƒÂ³n estÃƒÂ¡ndar de cambios diarios)
    double volatility = 0;
    if (sorted.length >= 2) {
      final changes = <double>[];
      for (var i = 1; i < sorted.length; i++) {
        changes.add(sorted[i].weightKg - sorted[i - 1].weightKg);
      }
      final mean = changes.reduce((a, b) => a + b) / changes.length;
      final squaredDiffs = changes.map((c) => (c - mean) * (c - mean));
      final variance = squaredDiffs.reduce((a, b) => a + b) / changes.length;
      volatility = variance > 0 ? variance.toDouble() : 0.0;
    }

    // Encontrar mejor y peor semana
    double? bestWeek;
    double? worstWeek;
    if (sorted.length >= 7) {
      final weeklyChanges = <double>[];
      for (var i = 7; i < sorted.length; i += 7) {
        weeklyChanges.add(sorted[i].weightKg - sorted[i - 7].weightKg);
      }
      if (weeklyChanges.isNotEmpty) {
        bestWeek = weeklyChanges.reduce(
          (a, b) => a < b ? a : b,
        ); // Menor cambio = mejor (pÃƒÂ©rdida)
        worstWeek = weeklyChanges.reduce(
          (a, b) => a > b ? a : b,
        ); // Mayor cambio = peor (ganancia)
      }
    }

    // Generar insight
    String? insight;
    if (consistency < 50) {
      insight =
          'Ã°Å¸â€™Â¡ Intenta pesarte mÃƒÂ¡s regularmente para mejores datos';
    } else if (volatility > 1.0) {
      insight =
          'Ã°Å¸â€™Â¡ Tus pesos fluctÃƒÂºan bastante. Considera pesarte a la misma hora cada dÃƒÂ­a';
    } else if (velocity.abs() > 1.5) {
      insight =
          'Ã¢Å¡Â¡ EstÃƒÂ¡s progresando rÃƒÂ¡pido. AsegÃƒÂºrate de mantener buenos hÃƒÂ¡bitos';
    } else if (velocity.abs() < 0.1 && consistency > 70) {
      insight = 'Ã°Å¸Å½Â¯ EstÃƒÂ¡s manteniendo tu peso consistentemente';
    }

    return _StatsResult(
      velocity: velocity,
      consistency: consistency,
      volatility: volatility,
      bestWeek: bestWeek,
      worstWeek: worstWeek,
      insight: insight,
    );
  }
}

class _StatsResult {
  final double velocity;
  final double consistency;
  final double volatility;
  final double? bestWeek;
  final double? worstWeek;
  final String? insight;

  _StatsResult({
    required this.velocity,
    required this.consistency,
    required this.volatility,
    this.bestWeek,
    this.worstWeek,
    this.insight,
  });
}

class _AnalyticsMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _AnalyticsMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: AppTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekComparison extends StatelessWidget {
  final String label;
  final double change;
  final IconData icon;
  final Color color;

  const _WeekComparison({
    required this.label,
    required this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} kg',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: change < 0 ? AppColors.success : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeighInsListSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighInsAsync = ref.watch(recentWeighInsProvider);

    return weighInsAsync.when(
      data: (weighIns) {
        if (weighIns.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final w = weighIns[index];
            return Dismissible(
              key: Key(w.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) async {
                await ref.read(weighInRepositoryProvider).delete(w.id);
                if (context.mounted) {
                  AppSnackbar.show(context, message: 'Peso eliminado');
                }
              },
              child: ListTile(
                leading: Icon(
                  Icons.scale,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text('${w.weightKg.toStringAsFixed(1)} kg'),
                subtitle: Text(DateFormat('d MMM', 'es').format(w.dateTime)),
              ),
            );
          }, childCount: weighIns.length),
        );
      },
      loading: () => const SliverToBoxAdapter(child: AppLoading()),
      error: (e, _) =>
          SliverToBoxAdapter(child: AppError(message: 'Error: $e')),
    );
  }
}
