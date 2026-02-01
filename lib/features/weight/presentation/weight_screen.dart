// Weight Screen - Enhanced version with chart and tooltips
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/widgets/home_button.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/diet/providers/goal_projection_providers.dart';
import 'package:juan_tracker/diet/models/weighin_model.dart';
import 'package:juan_tracker/diet/models/goal_projection_model.dart';
import 'package:juan_tracker/diet/services/adaptive_coach_service.dart';

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
          // Card de proyección de objetivo (Goal ETA)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _GoalProjectionCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          // Gráfica de evolución
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
          final messenger = ScaffoldMessenger.of(context);

          final result = await showDialog<bool>(
            context: context,
            builder: (context) => const AddWeightDialog(),
          );

          if (result == true && context.mounted) {
            messenger.showSnackBar(const SnackBar(content: Text('Peso registrado')));
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
    final text = _weightController.text.trim();
    final value = double.tryParse(text.replaceAll(',', '.'));

    // Validación: peso debe ser un número válido entre 20-500 kg
    if (value == null || value < 20 || value > 500) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa un peso válido (20-500 kg)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final repo = ref.read(weighInRepositoryProvider);
    final id = 'wi_${DateTime.now().millisecondsSinceEpoch}';
    await repo.insert(WeighInModel(id: id, dateTime: _selectedDate, weightKg: value));
    if (mounted) {
      Navigator.of(context).pop(true);
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
                child: Text(DateFormat('d MMM yyyy', 'es').format(_selectedDate)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }
}

/// Card de estadísticas principales con tooltips
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
                label: 'Ultimo',
                value: result.latestWeight.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.scale_outlined,
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Tu último peso registrado',
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
                tooltip: 'Media móvil de 7 días que suaviza fluctuaciones diarias',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCardWithTooltip(
                label: 'Semana',
                value: result.weeklyRate.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.trending_up,
                color: AppColors.success,
                tooltip: 'Ritmo de cambio estimado en kg por semana',
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
}

/// Card de estadística con tooltip informativo
class _StatCardWithTooltip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String tooltip;

  const _StatCardWithTooltip({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: true,
      child: AppStatCard(
        label: label,
        value: value,
        unit: unit,
        icon: icon,
        color: color,
      ),
    );
  }
}

/// Card con gráfica de evolución de peso
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
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
                      'Evolución (30 días)',
                      style: GoogleFonts.montserrat(
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

/// Gráfica de línea para evolución de peso
/// PERF: Uses memoized stats from weightChartStatsProvider
/// FEATURE: Muestra línea de objetivo si hay CoachPlan activo
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
          return const Center(child: Text('Se necesitan más datos'));
        }
        return _buildChart(context, theme, stats, goalWeight);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Error al cargar datos')),
    );
  }

  Widget _buildChart(BuildContext context, ThemeData theme, WeightChartStats stats, double? goalWeight) {
    // Filter to last 30 days for display
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final filteredWeighIns = weighIns
        .where((w) => w.dateTime.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (filteredWeighIns.length < 2) {
      return const Center(child: Text('Se necesitan más datos'));
    }

    // PERF: Use pre-computed values from provider
    final minWeight = stats.minWeight;
    final maxWeight = stats.maxWeight;
    final weightRange = stats.weightRange;
    final padding = stats.padding;

    // Ajustar límites para incluir el peso objetivo si existe
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

    // Línea de objetivo (horizontal punteada)
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
          // Línea principal de peso
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
          // Línea de objetivo (punteada)
          if (goalSpots.isNotEmpty)
            LineChartBarData(
              spots: goalSpots,
              isCurved: false,
              color: AppColors.success.withAlpha((0.7 * 255).round()),
              barWidth: 2,
              isStrokeCapRound: true,
              dashArray: [8, 4], // Línea punteada
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => theme.colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                // Solo mostrar tooltip para la línea principal (no para goal line)
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
                      text: DateFormat('d MMM', 'es').format(weighIn.dateTime),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).whereType<LineTooltipItem>().toList();
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

/// Card que muestra la proyección hacia el objetivo de peso
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
        // Si no hay proyección (sin plan o sin datos), no mostrar
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
                        'Proyección de objetivo',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Badge de estado
                    _StatusBadge(
                      isOnTrack: projection.isOnTrack,
                      goalReached: projection.goalReached,
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
                        value: '${projection.goalWeightKg.toStringAsFixed(1)} kg',
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
    if (projection.goalReached) return '¡Logrado!';
    
    final date = projection.estimatedGoalDate;
    if (date == null) return '—';
    
    final days = projection.estimatedDaysToGoal;
    if (days != null && days < 14) {
      return '$days días';
    }
    
    return DateFormat('MMM yyyy', 'es').format(date);
  }
}

/// Badge que indica si está on track o no
class _StatusBadge extends StatelessWidget {
  final bool isOnTrack;
  final bool goalReached;

  const _StatusBadge({
    required this.isOnTrack,
    required this.goalReached,
  });

  @override
  Widget build(BuildContext context) {
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

/// Métrica de objetivo individual
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
            Icon(icon, size: 16, color: colorScheme.onPrimaryContainer.withAlpha(153)),
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
          style: GoogleFonts.montserrat(
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

  const _ProgressBar({
    required this.progress,
    required this.colorScheme,
  });

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
          color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tu progreso',
                      style: GoogleFonts.montserrat(
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
                  value: '$daysCount días',
                ),
                const SizedBox(height: 8),
                _ProgressItem(
                  icon: totalChange <= 0 ? Icons.trending_down : Icons.trending_up,
                  label: 'Variación total',
                  value: '${totalChange >= 0 ? '+' : ''}${totalChange.toStringAsFixed(1)} kg',
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
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
          delegate: SliverChildBuilderDelegate(
            (context, index) {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Peso eliminado')),
                    );
                  }
                },
                child: ListTile(
                  leading: Icon(Icons.scale, color: Theme.of(context).colorScheme.primary),
                  title: Text('${w.weightKg.toStringAsFixed(1)} kg'),
                  subtitle: Text(DateFormat('d MMM', 'es').format(w.dateTime)),
                ),
              );
            },
            childCount: weighIns.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: AppLoading()),
      error: (e, _) => SliverToBoxAdapter(
        child: AppError(message: 'Error: $e'),
      ),
    );
  }
}
