// Providers para la tendencia TDEE
//
// Computan TDEE rolling a partir de datos existentes (diario + pesajes)
// y exponen el resultado para visualización en gráficos.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../models/tdee_trend_model.dart';
import '../providers/coach_providers.dart';
import '../services/tdee_trend_service.dart';

// ============================================================================
// SERVICIO
// ============================================================================

/// Provider del servicio de tendencia TDEE (singleton puro).
final tdeeTrendServiceProvider = Provider<TdeeTrendService>(
  (_) => const TdeeTrendService(),
);

// ============================================================================
// TENDENCIA TDEE (90 DÍAS)
// ============================================================================

/// Provider que calcula la tendencia TDEE de los últimos 90 días.
///
/// Usa datos del diario (kcal diarias) y pesajes para computar
/// un TDEE rolling con ventana deslizante de 14 días + suavizado EMA.
/// Este es el equivalente al gráfico TDEE de MacroFactor.
final tdeeTrendProvider = FutureProvider<TdeeTrendResult>((ref) async {
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final weighInRepo = ref.watch(weighInRepositoryProvider);
  final service = ref.watch(tdeeTrendServiceProvider);
  final coachPlan = ref.watch(coachPlanProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // Necesitamos 90 días de análisis + 14 días de ventana = 104 días de datos
  final dataStart = today.subtract(const Duration(days: 104));
  final analysisStart = today.subtract(const Duration(days: 90));

  // Obtener datos del diario
  final entries = await diaryRepo.getByDateRange(dataStart, today);

  // Agrupar por día para obtener kcal diarias
  final dailyIntakes = <DailyIntakeData>[];
  final intakeByDay = <String, int>{};

  for (final entry in entries) {
    final dateKey =
        '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
    intakeByDay[dateKey] = (intakeByDay[dateKey] ?? 0) + entry.kcal;
  }

  for (final entry in intakeByDay.entries) {
    final parts = entry.key.split('-');
    dailyIntakes.add(DailyIntakeData(
      date: DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      ),
      kcal: entry.value,
    ));
  }

  // Obtener pesajes
  final weighIns = await weighInRepo.getByDateRange(dataStart, today);

  // Calcular tendencia
  return service.calculate(
    dailyIntakes: dailyIntakes,
    weighIns: weighIns,
    analysisStart: analysisStart,
    analysisEnd: today,
    initialTdeeEstimate: coachPlan?.initialTdeeEstimate,
    currentTargetKcal: coachPlan?.currentKcalTarget,
  );
});

// ============================================================================
// DERIVADOS
// ============================================================================

/// TDEE actual estimado (último punto suavizado).
final currentTdeeEstimateProvider = Provider<double?>((ref) {
  final trendAsync = ref.watch(tdeeTrendProvider);
  return trendAsync.whenOrNull(data: (trend) => trend.currentTdee);
});

/// Dirección de la tendencia TDEE.
final tdeeTrendDirectionProvider = Provider<TdeeTrendDirection>((ref) {
  final trendAsync = ref.watch(tdeeTrendProvider);
  return trendAsync.whenOrNull(data: (trend) => trend.direction) ??
      TdeeTrendDirection.insufficient;
});

/// Período seleccionado para el gráfico de balance energético.
class EnergyChartPeriodNotifier extends Notifier<int> {
  @override
  int build() => 90;

  void setPeriod(int days) => state = days;
}

final energyChartPeriodProvider =
    NotifierProvider<EnergyChartPeriodNotifier, int>(
  EnergyChartPeriodNotifier.new,
);

/// Datos formateados para el gráfico fl_chart.
///
/// Retorna puntos (x = índice, y = tdee) y metadata para tooltips.
final tdeeTrendChartDataProvider =
    Provider<AsyncValue<TdeeChartData>>((ref) {
  final period = ref.watch(energyChartPeriodProvider);
  return ref.watch(tdeeTrendProvider).whenData((trend) {
    if (!trend.hasData) {
      return const TdeeChartData(points: [], dates: []);
    }

    // Usar puntos suavizados para el gráfico principal
    var points = trend.smoothedPoints;

    // Filtrar por período seleccionado
    if (points.length > period) {
      points = points.sublist(points.length - period);
    }

    final dates = points.map((p) => p.date).toList();

    // Calcular bounds de intake
    final intakeValues = points
        .map((p) => p.avgIntake)
        .where((v) => v > 0)
        .toList();
    final minIntake = intakeValues.isNotEmpty
        ? intakeValues.reduce((a, b) => a < b ? a : b)
        : 1500.0;
    final maxIntake = intakeValues.isNotEmpty
        ? intakeValues.reduce((a, b) => a > b ? a : b)
        : 2500.0;

    // Recalcular TDEE bounds para el período filtrado
    final tdeeValues = points.map((p) => p.estimatedTdee).toList();
    final minTdee = tdeeValues.reduce((a, b) => a < b ? a : b);
    final maxTdee = tdeeValues.reduce((a, b) => a > b ? a : b);

    return TdeeChartData(
      points: points,
      dates: dates,
      minTdee: minTdee,
      maxTdee: maxTdee,
      minIntake: minIntake,
      maxIntake: maxIntake,
      initialEstimate: trend.initialTdeeEstimate?.toDouble(),
      currentTarget: trend.currentTargetKcal?.toDouble(),
    );
  });
});

/// Datos preparados para el gráfico de TDEE
class TdeeChartData {
  final List<TdeeDataPoint> points;
  final List<DateTime> dates;
  final double minTdee;
  final double maxTdee;
  final double minIntake;
  final double maxIntake;
  final double? initialEstimate;
  final double? currentTarget;

  const TdeeChartData({
    required this.points,
    required this.dates,
    this.minTdee = 1500,
    this.maxTdee = 2500,
    this.minIntake = 1500,
    this.maxIntake = 2500,
    this.initialEstimate,
    this.currentTarget,
  });

  bool get hasData => points.length >= 2;

  double get range {
    final allMin = [minTdee, minIntake].reduce((a, b) => a < b ? a : b);
    final allMax = [maxTdee, maxIntake].reduce((a, b) => a > b ? a : b);
    return allMax - allMin;
  }

  double get padding => range > 0 ? range * 0.15 : 100;
}
