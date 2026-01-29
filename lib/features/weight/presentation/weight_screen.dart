import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';
import '../../../diet/services/weight_trend_calculator.dart';

/// Pantalla de seguimiento de peso corporal con análisis multi-modelo
class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peso'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentWeighInsProvider);
          ref.invalidate(weightTrendHistoryProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Stats Cards principales
            SliverToBoxAdapter(
              child: _MainStatsSection(),
            ),

            // Indicador de fase
            SliverToBoxAdapter(
              child: _PhaseIndicator(),
            ),

            // Predicciones
            SliverToBoxAdapter(
              child: _PredictionsSection(),
            ),

            // Gráfico
            SliverToBoxAdapter(
              child: _WeightChartSection(),
            ),

            // Métricas avanzadas
            SliverToBoxAdapter(
              child: _AdvancedMetricsSection(),
            ),

            // Título de lista
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'HISTORIAL',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),

            // Lista de registros
            _WeighInsList(),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWeightDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sobre el Análisis'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Esta pantalla usa múltiples modelos matemáticos para analizar tu peso:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• EMA: Media móvil exponencial (suavizado)'),
              Text('• Kalman: Filtro que estima el peso "real" filtrando ruido'),
              Text('• Holt-Winters: Detecta nivel y tendencia'),
              Text('• Regresión: Calcula la pendiente de largo plazo'),
              SizedBox(height: 12),
              Text(
                'Todo el procesamiento es local en tu dispositivo. No se envían datos a ningún servidor.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddWeightDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (ctx) => const _AddWeightDialog(),
    );
  }
}

// ============================================================================
// STATS PRINCIPALES
// ============================================================================

class _MainStatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);

    return trendAsync.when(
      data: (result) {
        if (result == null) {
          return const _EmptyStatsCard();
        }
        return _StatsGrid(result: result);
      },
      loading: () => const _StatsSkeleton(),
      error: (_, __) => const _EmptyStatsCard(),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final WeightTrendResult result;

  const _StatsGrid({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Último',
                  value: result.latestWeight.toStringAsFixed(1),
                  unit: 'kg',
                  icon: Icons.scale,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Tendencia',
                  value: result.trendWeight.toStringAsFixed(1),
                  unit: 'kg',
                  icon: Icons.trending_flat,
                  color: colorScheme.secondary,
                  subtitle: result.variance >= 0
                      ? '+${result.variance.toStringAsFixed(1)} kg'
                      : '${result.variance.toStringAsFixed(1)} kg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Semana',
                  value: _formatWeeklyRate(result.weeklyRate),
                  unit: '',
                  icon: result.weeklyRate < 0
                      ? Icons.trending_down
                      : result.weeklyRate > 0
                          ? Icons.trending_up
                          : Icons.trending_flat,
                  color: _getRateColor(result.weeklyRate, colorScheme),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWeeklyRate(double rate) {
    final sign = rate >= 0 ? '+' : '';
    return '$sign${rate.toStringAsFixed(1)}';
  }

  Color _getRateColor(double rate, ColorScheme scheme) {
    if (rate.abs() < 0.2) return scheme.onSurfaceVariant;
    return rate < 0 ? Colors.green : Colors.orange;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.2 * 255).round())),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// INDICADOR DE FASE
// ============================================================================

class _PhaseIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);

    return trendAsync.when(
      data: (result) {
        if (result == null) return const SizedBox.shrink();
        return _PhaseBanner(result: result);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PhaseBanner extends StatelessWidget {
  final WeightTrendResult result;

  const _PhaseBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (color, icon, title) = _getPhaseInfo(result.phase, colorScheme);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha((0.3 * 255).round())),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result.phaseDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (result.daysInPhase > 0)
                  Text(
                    '${result.daysInPhase} días en esta fase',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _getPhaseInfo(
    WeightPhase phase,
    ColorScheme scheme,
  ) {
    switch (phase) {
      case WeightPhase.losing:
        return (Colors.green, Icons.trending_down, 'Perdiendo peso');
      case WeightPhase.maintaining:
        return (
          scheme.onSurfaceVariant,
          Icons.trending_flat,
          'Mantenimiento'
        );
      case WeightPhase.gaining:
        return (Colors.orange, Icons.trending_up, 'Ganando peso');
      case WeightPhase.insufficientData:
        return (
          scheme.outline,
          Icons.timeline,
          'Recopilando datos'
        );
    }
  }
}

// ============================================================================
// PREDICCIONES
// ============================================================================

class _PredictionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);

    return trendAsync.when(
      data: (result) {
        if (result == null || !result.isPredictionReliable) {
          return const SizedBox.shrink();
        }
        return _PredictionsCard(result: result);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PredictionsCard extends StatelessWidget {
  final WeightTrendResult result;

  const _PredictionsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha((0.3 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'PROYECCIÓN',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PredictionItem(
                  days: 7,
                  weight: result.hwPrediction7d!,
                  currentWeight: result.latestWeight,
                ),
              ),
              if (result.hwPrediction30d != null)
                Expanded(
                  child: _PredictionItem(
                    days: 30,
                    weight: result.hwPrediction30d!,
                    currentWeight: result.latestWeight,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Confianza: ${(result.kalmanConfidence * 100).toStringAsFixed(0)}% (R² = ${result.regressionR2.toStringAsFixed(2)})',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionItem extends StatelessWidget {
  final int days;
  final double weight;
  final double currentWeight;

  const _PredictionItem({
    required this.days,
    required this.weight,
    required this.currentWeight,
  });

  @override
  Widget build(BuildContext context) {
    final diff = weight - currentWeight;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          'En $days días',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${weight.toStringAsFixed(1)} kg',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          diff >= 0 ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            color: diff < 0 ? Colors.green : Colors.orange,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// GRÁFICO
// ============================================================================

class _WeightChartSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(weightChartDataProvider);

    return chartDataAsync.when(
      data: (data) {
        if (data.length < 2) return const SizedBox.shrink();
        return _WeightChart(data: data);
      },
      loading: () => const _ChartSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<ChartDataPoint> data;

  const _WeightChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final point in data) {
      if (point.weight < minY) minY = point.weight;
      if (point.weight > maxY) maxY = point.weight;
      if (point.ema != null) {
        if (point.ema! < minY) minY = point.ema!;
        if (point.ema! > maxY) maxY = point.ema!;
      }
    }

    final yRange = maxY - minY;
    minY = (minY - yRange * 0.15).clamp(0, double.infinity);
    maxY = maxY + yRange * 0.15;

    if (maxY - minY < 2) {
      final center = (maxY + minY) / 2;
      minY = (center - 1).clamp(0, double.infinity);
      maxY = center + 1;
    }

    final weightSpots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final emaSpots = data.asMap().entries
        .where((e) => e.value.ema != null)
        .map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.ema!);
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withAlpha((0.5 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.show_chart, color: colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'EVOLUCIÓN',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendItem(color: colorScheme.primary, label: 'Peso real'),
              const SizedBox(width: 16),
              _LegendItem(color: colorScheme.secondary, label: 'Tendencia EMA'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.outline.withAlpha((0.3 * 255).round()),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: data.length > 12
                          ? (data.length / 4).ceil().toDouble()
                          : data.length > 6
                              ? 2
                              : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final date = data[index].date;
                        return Text(
                          '${date.day}/${date.month}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weightSpots,
                    isCurved: false,
                    color: colorScheme.primary,
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: colorScheme.primary,
                          strokeWidth: 1,
                          strokeColor: colorScheme.surface,
                        );
                      },
                    ),
                  ),
                  LineChartBarData(
                    spots: emaSpots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: colorScheme.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondary.withAlpha((0.2 * 255).round()),
                          colorScheme.secondary.withAlpha((0 * 255).round()),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        final point = data[index];
                        final dateStr = DateFormat('d MMM', 'es').format(point.date);
                        final isTrend = spot.barIndex == 1;

                        return LineTooltipItem(
                          '$dateStr\n',
                          TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: isTrend
                                  ? 'Tendencia: ${point.ema?.toStringAsFixed(1) ?? "--"}kg'
                                  : 'Peso: ${point.weight.toStringAsFixed(1)}kg',
                              style: TextStyle(
                                color: isTrend
                                    ? colorScheme.secondary
                                    : colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MÉTRICAS AVANZADAS
// ============================================================================

class _AdvancedMetricsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);

    return trendAsync.when(
      data: (result) {
        if (result == null) return const SizedBox.shrink();
        return _MetricsCard(result: result);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final WeightTrendResult result;

  const _MetricsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANÁLISIS TÉCNICO',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            label: 'Kalman (peso real estimado)',
            value: '${result.kalmanWeight.toStringAsFixed(2)} kg',
            subvalue: 'Confianza ${(result.kalmanConfidence * 100).toStringAsFixed(0)}%',
          ),
          _MetricRow(
            label: 'Holt-Winters (nivel)',
            value: '${result.hwLevel.toStringAsFixed(2)} kg',
            subvalue: 'Tendencia ${result.hwTrend >= 0 ? "+" : ""}${result.hwTrend.toStringAsFixed(3)} kg/día',
          ),
          _MetricRow(
            label: 'Regresión lineal',
            value: '${result.regressionSlope >= 0 ? "+" : ""}${(result.regressionSlope * 7).toStringAsFixed(2)} kg/semana',
            subvalue: 'R² = ${result.regressionR2.toStringAsFixed(3)}',
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String subvalue;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.subvalue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subvalue,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPONENTES REUTILIZABLES (Legend, Empty, Skeleton)
// ============================================================================

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmptyStatsCard extends StatelessWidget {
  const _EmptyStatsCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.scale_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).round()),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin registros de peso',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Registra tu primer peso para ver análisis avanzado',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (_) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ============================================================================
// LISTA DE WEIGH-INS
// ============================================================================

class _WeighInsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighInsAsync = ref.watch(recentWeighInsProvider);

    return weighInsAsync.when(
      data: (weighIns) {
        if (weighIns.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return _GroupedWeighInsList(weighIns: weighIns);
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => SliverToBoxAdapter(
        child: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _GroupedWeighInsList extends StatelessWidget {
  final List<WeighInModel> weighIns;

  const _GroupedWeighInsList({required this.weighIns});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<WeighInModel>>{};
    for (final w in weighIns) {
      final key = DateFormat('MMMM yyyy', 'es').format(w.dateTime);
      grouped.putIfAbsent(key, () => []).add(w);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final month = grouped.keys.elementAt(index);
          final entries = grouped[month]!;
          return _MonthSection(month: month, entries: entries);
        },
        childCount: grouped.length,
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  final String month;
  final List<WeighInModel> entries;

  const _MonthSection({required this.month, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            month.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...entries.map((w) => _WeightListTile(weighIn: w)),
      ],
    );
  }
}

class _WeightListTile extends ConsumerWidget {
  final WeighInModel weighIn;

  const _WeightListTile({required this.weighIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(weighIn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final repo = ref.read(weighInRepositoryProvider);
        await repo.delete(weighIn.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registro eliminado'),
              action: SnackBarAction(
                label: 'Deshacer',
                onPressed: () async {
                  await repo.insert(weighIn);
                },
              ),
            ),
          );
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.scale,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          '${weighIn.weightKg.toStringAsFixed(1)} kg',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE d, HH:mm', 'es').format(weighIn.dateTime),
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            if (weighIn.note != null && weighIn.note!.isNotEmpty)
              Text(
                weighIn.note!,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine: weighIn.note != null && weighIn.note!.isNotEmpty,
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editWeight(context, ref),
        ),
      ),
    );
  }

  Future<void> _editWeight(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (ctx) => _EditWeightDialog(weighIn: weighIn),
    );
  }
}

// ============================================================================
// DIÁLOGOS
// ============================================================================

class _AddWeightDialog extends ConsumerStatefulWidget {
  const _AddWeightDialog();

  @override
  ConsumerState<_AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends ConsumerState<_AddWeightDialog> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              hintText: 'Ej: 75.5',
              border: OutlineInputBorder(),
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                DateFormat('d MMMM yyyy', 'es').format(_selectedDate),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'Ej: Por la mañana, en ayunas',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saveWeight,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveWeight() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0 || weight > 300) {
      return;
    }

    final now = DateTime.now();
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
    );

    final weighIn = WeighInModel(
      id: const Uuid().v4(),
      dateTime: dateTime,
      weightKg: weight,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    final repo = ref.read(weighInRepositoryProvider);
    await repo.insert(weighIn);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _EditWeightDialog extends ConsumerStatefulWidget {
  final WeighInModel weighIn;

  const _EditWeightDialog({required this.weighIn});

  @override
  ConsumerState<_EditWeightDialog> createState() => _EditWeightDialogState();
}

class _EditWeightDialogState extends ConsumerState<_EditWeightDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.weighIn.weightKg.toStringAsFixed(1),
    );
    _noteController = TextEditingController(text: widget.weighIn.note ?? '');
    _selectedDate = widget.weighIn.dateTime;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              border: OutlineInputBorder(),
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                DateFormat('d MMMM yyyy', 'es').format(_selectedDate),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Nota',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _updateWeight,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _updateWeight() async {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0 || weight > 300) return;

    final updated = widget.weighIn.copyWith(
      weightKg: weight,
      dateTime: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    final repo = ref.read(weighInRepositoryProvider);
    await repo.update(updated);

    if (mounted) Navigator.of(context).pop();
  }
}
