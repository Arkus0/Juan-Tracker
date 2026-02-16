// Servicio de cálculo de tendencia TDEE con ventana deslizante
//
// Replica el algoritmo de MacroFactor: calcula TDEE real a partir del
// balance energético (ingesta vs cambio de peso) usando una ventana
// deslizante de 14 días.

import 'dart:math' as math;

import '../models/tdee_trend_model.dart';
import '../models/weighin_model.dart';
import '../services/weight_trend_calculator.dart';

/// Constantes del cálculo TDEE
const double _kKcalPerKg = 7700.0;
const int _kDefaultWindowDays = 14;
const int _kMinDiaryDays = 4;
const int _kMinWeighInDays = 3;
const double _kEmaAlpha = 0.15; // Suavizado EMA (menor = más suave)
const double _kMinTdee = 800.0;
const double _kMaxTdee = 6000.0;

/// Datos de ingesta diaria para el cálculo
class DailyIntakeData {
  final DateTime date;
  final int kcal;

  const DailyIntakeData({required this.date, required this.kcal});
}

/// Servicio que calcula la tendencia de TDEE a lo largo del tiempo.
///
/// Usa una ventana deslizante de [windowDays] días para computar
/// el TDEE real basándose en balance energético:
/// `TDEE = avgIntake - (ΔtrendWeight × 7700 / días)`
class TdeeTrendService {
  final int windowDays;
  final WeightTrendCalculator _trendCalculator;

  const TdeeTrendService({
    this.windowDays = _kDefaultWindowDays,
    WeightTrendCalculator trendCalculator = const WeightTrendCalculator(),
  }) : _trendCalculator = trendCalculator;

  /// Calcula la tendencia TDEE a partir de datos de ingesta y pesajes.
  ///
  /// [dailyIntakes] debe cubrir al menos [windowDays] + días de análisis.
  /// [weighIns] debe cubrir el mismo período.
  /// [analysisStart] es la fecha desde la que se generan puntos.
  /// [analysisEnd] es la última fecha a analizar.
  TdeeTrendResult calculate({
    required List<DailyIntakeData> dailyIntakes,
    required List<WeighInModel> weighIns,
    required DateTime analysisStart,
    required DateTime analysisEnd,
    int? initialTdeeEstimate,
    int? currentTargetKcal,
  }) {
    // Ordenar datos cronológicamente
    final sortedIntakes = List<DailyIntakeData>.from(dailyIntakes)
      ..sort((a, b) => a.date.compareTo(b.date));
    final sortedWeighIns = List<WeighInModel>.from(weighIns)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (sortedIntakes.isEmpty || sortedWeighIns.length < 2) {
      return TdeeTrendResult.empty;
    }

    // Indexar intakes por fecha (normalizada)
    final intakeMap = <String, int>{};
    for (final intake in sortedIntakes) {
      final key = _dateKey(intake.date);
      intakeMap[key] = (intakeMap[key] ?? 0) + intake.kcal;
    }

    // Generar puntos de TDEE para cada día del análisis
    final rawPoints = <TdeeDataPoint>[];

    var current = DateTime(
      analysisStart.year,
      analysisStart.month,
      analysisStart.day,
    );
    final end = DateTime(
      analysisEnd.year,
      analysisEnd.month,
      analysisEnd.day,
    );

    while (!current.isAfter(end)) {
      final point = _calculatePointForDate(
        date: current,
        intakeMap: intakeMap,
        weighIns: sortedWeighIns,
      );

      if (point != null) {
        rawPoints.add(point);
      }

      current = current.add(const Duration(days: 1));
    }

    if (rawPoints.isEmpty) {
      return TdeeTrendResult.empty;
    }

    // Aplicar suavizado EMA
    final smoothed = _applyEma(rawPoints);

    // Calcular estadísticas
    final currentTdee =
        smoothed.isNotEmpty ? smoothed.last.estimatedTdee : null;
    final avgTdee = smoothed.isNotEmpty
        ? smoothed.map((p) => p.estimatedTdee).reduce((a, b) => a + b) /
            smoothed.length
        : null;

    // Calcular dirección de tendencia
    final direction = _calculateDirection(smoothed);
    final weeklyChange = _calculateWeeklyChange(smoothed);

    return TdeeTrendResult(
      dataPoints: rawPoints,
      smoothedPoints: smoothed,
      currentTdee: currentTdee,
      avgTdee: avgTdee,
      direction: direction,
      weeklyChangeKcal: weeklyChange,
      initialTdeeEstimate: initialTdeeEstimate,
      currentTargetKcal: currentTargetKcal,
    );
  }

  /// Calcula el TDEE para una fecha usando ventana deslizante.
  TdeeDataPoint? _calculatePointForDate({
    required DateTime date,
    required Map<String, int> intakeMap,
    required List<WeighInModel> weighIns,
  }) {
    final windowStart = date.subtract(Duration(days: windowDays));
    final windowEnd = date;

    // Recoger ingesta dentro de la ventana
    final windowIntakes = <int>[];
    var d = windowStart;
    while (!d.isAfter(windowEnd)) {
      final key = _dateKey(d);
      final intake = intakeMap[key];
      if (intake != null && intake > 0) {
        windowIntakes.add(intake);
      }
      d = d.add(const Duration(days: 1));
    }

    // Recoger pesajes dentro de la ventana (con margen de 1 día)
    final windowWeighIns = weighIns.where((w) {
      final wd = DateTime(w.dateTime.year, w.dateTime.month, w.dateTime.day);
      return !wd.isBefore(windowStart.subtract(const Duration(days: 1))) &&
          !wd.isAfter(windowEnd.add(const Duration(days: 1)));
    }).toList();

    // Verificar datos mínimos
    if (windowIntakes.length < _kMinDiaryDays ||
        windowWeighIns.length < _kMinWeighInDays) {
      return null;
    }

    // Calcular ingesta media
    final avgIntake =
        windowIntakes.reduce((a, b) => a + b) / windowIntakes.length;

    // Calcular cambio de peso en la ventana usando trend (EMA)
    double trendStart;
    double trendEnd;

    if (windowWeighIns.length >= 3) {
      // Calcular trend weights
      final trendResult = _trendCalculator.calculate(windowWeighIns);
      trendEnd = trendResult.trendWeight;

      // Trend al inicio: calcular solo con pesajes de la primera mitad
      final midpoint = windowStart.add(Duration(days: windowDays ~/ 2));
      final earlyWeighIns = windowWeighIns
          .where((w) => w.dateTime.isBefore(midpoint))
          .toList();
      if (earlyWeighIns.length >= 2) {
        trendStart = _trendCalculator.calculate(earlyWeighIns).trendWeight;
      } else {
        trendStart = windowWeighIns.first.weightKg;
      }
    } else {
      // Con pocos pesajes, usar primero y último directamente
      trendStart = windowWeighIns.first.weightKg;
      trendEnd = windowWeighIns.last.weightKg;
    }

    final weightChange = trendEnd - trendStart;
    final days = windowEnd.difference(windowStart).inDays;
    if (days <= 0) return null;

    // Fórmula TDEE: intake - (cambio_peso * 7700 / días)
    final deltaKcalPerDay = weightChange * _kKcalPerKg / days;
    var estimatedTdee = avgIntake - deltaKcalPerDay;

    // Clamp a valores razonables
    estimatedTdee = estimatedTdee.clamp(_kMinTdee, _kMaxTdee);

    // Calcular confianza basada en cantidad de datos
    final diaryRatio = windowIntakes.length / (windowDays + 1);
    final weighInRatio =
        math.min(1.0, windowWeighIns.length / (windowDays * 0.5));
    final confidence = ((diaryRatio + weighInRatio) / 2).clamp(0.0, 1.0);

    return TdeeDataPoint(
      date: date,
      estimatedTdee: estimatedTdee,
      avgIntake: avgIntake,
      weightChangePeriod: weightChange,
      windowDays: days,
      diaryDaysInWindow: windowIntakes.length,
      weighInDaysInWindow: windowWeighIns.length,
      confidence: confidence,
    );
  }

  /// Aplica EMA (Exponential Moving Average) para suavizar la serie.
  List<TdeeDataPoint> _applyEma(List<TdeeDataPoint> points) {
    if (points.isEmpty) return [];

    final result = <TdeeDataPoint>[points.first];

    for (var i = 1; i < points.length; i++) {
      final prev = result.last.estimatedTdee;
      final current = points[i].estimatedTdee;
      final smoothed = _kEmaAlpha * current + (1 - _kEmaAlpha) * prev;

      result.add(TdeeDataPoint(
        date: points[i].date,
        estimatedTdee: smoothed,
        avgIntake: points[i].avgIntake,
        weightChangePeriod: points[i].weightChangePeriod,
        windowDays: points[i].windowDays,
        diaryDaysInWindow: points[i].diaryDaysInWindow,
        weighInDaysInWindow: points[i].weighInDaysInWindow,
        confidence: points[i].confidence,
      ));
    }

    return result;
  }

  /// Calcula la dirección de la tendencia comparando últimas 2 semanas.
  TdeeTrendDirection _calculateDirection(List<TdeeDataPoint> smoothed) {
    if (smoothed.length < 14) return TdeeTrendDirection.insufficient;

    // Comparar promedio de últimos 7 días vs 7 días previos
    final recent = smoothed.sublist(smoothed.length - 7);
    final previous = smoothed.sublist(
      smoothed.length - 14,
      smoothed.length - 7,
    );

    final recentAvg =
        recent.map((p) => p.estimatedTdee).reduce((a, b) => a + b) / 7;
    final previousAvg =
        previous.map((p) => p.estimatedTdee).reduce((a, b) => a + b) / 7;

    final change = recentAvg - previousAvg;

    // Umbral de 30 kcal para considerar cambio significativo
    if (change > 30) return TdeeTrendDirection.increasing;
    if (change < -30) return TdeeTrendDirection.decreasing;
    return TdeeTrendDirection.stable;
  }

  /// Calcula el cambio semanal estimado en kcal.
  double? _calculateWeeklyChange(List<TdeeDataPoint> smoothed) {
    if (smoothed.length < 14) return null;

    final recent = smoothed.last.estimatedTdee;
    final twoWeeksAgo = smoothed[smoothed.length - 14].estimatedTdee;
    return (recent - twoWeeksAgo) / 2; // Cambio por semana
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
