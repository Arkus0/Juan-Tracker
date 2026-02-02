/// Providers para tendencias de peso con análisis multi-modelo
///
/// Combina EMA, Holt-Winters, Filtro de Kalman y Regresión Lineal
/// para proporcionar el análisis más completo posible 100% offline.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../models/models.dart';
import '../services/weight_trend_calculator.dart';

// ============================================================================
// CALCULATOR
// ============================================================================

/// Provider del calculador de tendencias multi-modelo
final weightTrendCalculatorProvider = Provider<WeightTrendCalculator>(
  (_) => const WeightTrendCalculator(),
);

/// Provider de configuración personalizada (opcional)
final trendConfigProvider = Provider<TrendConfig>(
  (_) => TrendConfig.defaultConfig,
);

// ============================================================================
// WEIGH-INS STREAMS
// ============================================================================

/// Provider de weigh-ins recientes (últimos 90 días)
final recentWeighInsProvider = StreamProvider<List<WeighInModel>>((ref) {
  final repo = ref.watch(weighInRepositoryProvider);
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 90));
  return repo.watchByDateRange(from, now);
});

/// Provider de todos los weigh-ins (sin límite)
final allWeighInsProvider = StreamProvider<List<WeighInModel>>((ref) {
  return ref.watch(weighInRepositoryProvider).watchAll();
});

/// Provider del weigh-in más reciente (derivado del stream para reactividad)
final latestWeighInProvider = Provider<AsyncValue<WeighInModel?>>((ref) {
  final weighInsAsync = ref.watch(recentWeighInsProvider);
  return weighInsAsync.when(
    data: (weighIns) => AsyncValue.data(weighIns.isNotEmpty ? weighIns.first : null),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// ============================================================================
// TREND CALCULATIONS
// ============================================================================

/// Provider del análisis completo de tendencia
final weightTrendProvider = Provider<AsyncValue<WeightTrendResult?>>((ref) {
  final weighInsAsync = ref.watch(recentWeighInsProvider);
  final calculator = ref.watch(weightTrendCalculatorProvider);

  return weighInsAsync.when(
    data: (weighIns) {
      if (weighIns.isEmpty) {
        return const AsyncValue<WeightTrendResult?>.data(null);
      }
      try {
        final trend = calculator.calculate(weighIns);
        return AsyncValue.data(trend);
      } catch (e, st) {
        return AsyncValue.error(e, st);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Provider del análisis con historial extendido (1 año)
/// MA-003: Usa calculateAsync() para ejecutar en isolate si hay muchos datos
final weightTrendHistoryProvider = FutureProvider<WeightTrendResult?>((ref) async {
  final repo = ref.watch(weighInRepositoryProvider);
  final calculator = ref.watch(weightTrendCalculatorProvider);

  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 365));
  final weighIns = await repo.getByDateRange(from, now);

  if (weighIns.isEmpty) return null;

  try {
    // MA-003: Usar calculateAsync para listas grandes (>50 registros)
    // Esto ejecuta el cálculo en un isolate separado y evita bloquear la UI
    return await calculator.calculateAsync(weighIns);
  } catch (_) {
    return null;
  }
});

/// Provider de datos para gráficos
final weightChartDataProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final trendAsync = ref.watch(weightTrendHistoryProvider);
  final calculator = ref.watch(weightTrendCalculatorProvider);

  return trendAsync.when(
    data: (trend) {
      if (trend == null) return [];
      return calculator.generateChartData(trend.entries);
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

// ============================================================================
// STATS PROVIDERS
// ============================================================================

/// Provider de estadísticas simplificadas para UI
class WeightStats {
  final double latestWeight;
  final double trendWeight;
  final double? weeklyRate;
  final WeightPhase phase;
  final bool isPredictionReliable;

  const WeightStats({
    required this.latestWeight,
    required this.trendWeight,
    this.weeklyRate,
    required this.phase,
    required this.isPredictionReliable,
  });

  double get variance => latestWeight - trendWeight;

  String get formattedWeeklyRate {
    if (weeklyRate == null) return '--';
    final sign = weeklyRate! >= 0 ? '+' : '';
    return '$sign${weeklyRate!.toStringAsFixed(1)} kg';
  }
}

/// Provider de estadísticas simplificadas
final weightStatsProvider = Provider<AsyncValue<WeightStats?>>((ref) {
  final trendAsync = ref.watch(weightTrendProvider);

  return trendAsync.when(
    data: (result) {
      if (result == null) return const AsyncValue.data(null);

      final stats = WeightStats(
        latestWeight: result.latestWeight,
        trendWeight: result.trendWeight,
        weeklyRate: result.weeklyRate,
        phase: result.phase,
        isPredictionReliable: result.isPredictionReliable,
      );
      return AsyncValue.data(stats);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// ============================================================================
// CHART STATS (PERF: Memoized to avoid recalculation in build())
// ============================================================================

/// Pre-computed chart statistics for weight screen
/// PERF: Calculated once per data change, not per widget rebuild
class WeightChartStats {
  final double minWeight;
  final double maxWeight;
  final double? weeklyAverage;
  final int daysTracking;
  final double totalChange;

  const WeightChartStats({
    required this.minWeight,
    required this.maxWeight,
    this.weeklyAverage,
    required this.daysTracking,
    required this.totalChange,
  });

  double get weightRange => maxWeight - minWeight;
  double get padding => weightRange > 0 ? weightRange * 0.1 : 1.0;
}

/// Memoized provider for weight chart statistics.
/// Calculates min/max/weeklyAvg once when data changes, not on every rebuild.
final weightChartStatsProvider = Provider<AsyncValue<WeightChartStats?>>((ref) {
  final weighInsAsync = ref.watch(recentWeighInsProvider);

  return weighInsAsync.when(
    data: (weighIns) {
      if (weighIns.isEmpty) {
        return const AsyncValue.data(null);
      }

      // Filter to last 30 days for chart
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final filtered = weighIns
          .where((w) => w.dateTime.isAfter(cutoffDate))
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (filtered.length < 2) {
        return const AsyncValue.data(null);
      }

      // PERF: Single pass for min/max instead of two separate reduce() calls
      var minWeight = filtered.first.weightKg;
      var maxWeight = filtered.first.weightKg;
      for (final w in filtered) {
        if (w.weightKg < minWeight) minWeight = w.weightKg;
        if (w.weightKg > maxWeight) maxWeight = w.weightKg;
      }

      // Calculate weekly average from most recent 7 entries
      double? weeklyAverage;
      if (weighIns.length >= 7) {
        var sum = 0.0;
        for (var i = 0; i < 7; i++) {
          sum += weighIns[i].weightKg;
        }
        weeklyAverage = sum / 7;
      }

      // Progress stats
      final firstWeight = weighIns.last.weightKg;
      final latestWeight = weighIns.first.weightKg;
      final totalChange = latestWeight - firstWeight;
      final daysTracking =
          DateTime.now().difference(weighIns.last.dateTime).inDays + 1;

      return AsyncValue.data(WeightChartStats(
        minWeight: minWeight,
        maxWeight: maxWeight,
        weeklyAverage: weeklyAverage,
        daysTracking: daysTracking,
        totalChange: totalChange,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// ============================================================================
// PREDICTION PROVIDERS
// ============================================================================

/// Provider de predicciones futuras
final weightPredictionsProvider = Provider<AsyncValue<WeightPredictions?>>((ref) {
  final trendAsync = ref.watch(weightTrendProvider);

  return trendAsync.when(
    data: (result) {
      if (result == null || !result.isPredictionReliable) {
        return const AsyncValue.data(null);
      }

      final predictions = WeightPredictions(
        day7: result.hwPrediction7d,
        day30: result.hwPrediction30d,
        confidence: result.kalmanConfidence,
        r2: result.regressionR2,
      );
      return AsyncValue.data(predictions);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

/// Predicciones de peso futuro
class WeightPredictions {
  final double? day7;
  final double? day30;
  final double confidence;
  final double r2;

  const WeightPredictions({
    this.day7,
    this.day30,
    required this.confidence,
    required this.r2,
  });
}
