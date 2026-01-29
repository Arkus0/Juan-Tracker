/// Extensiones del motor de progresion con analisis multi-modelo
library;

import 'dart:math' as math;
import '../models/analysis_models.dart';
import 'progression_engine.dart';

/// Extensión del ProgressionEngine con métodos de análisis avanzado
extension ProgressionEngineAnalysis on ProgressionEngine {
  /// Analiza la tendencia de fuerza usando filtros estadisticos
  StrengthTrendAnalysis analyzeStrengthTrend(List<StrengthDataPoint> dataPoints) {
    if (dataPoints.length < 3) {
      return StrengthTrendAnalysis(
        kalman1RM: dataPoints.isEmpty ? 0 : dataPoints.last.estimated1RM,
        confidence: 0.5,
        weeklyTrend: 0,
        phase: StrengthTrendPhase.insufficient,
        isStalled: false,
      );
    }

    final sorted = List<StrengthDataPoint>.from(dataPoints)
      ..sort((a, b) => a.date.compareTo(b.date));
    final oneRMs = sorted.map((p) => p.estimated1RM).toList();

    final kalman = _kalmanFilter(oneRMs);
    final hw = _holtWinters(oneRMs);
    final weeklyTrend = hw.trend * 7;
    final phase = _detectTrendPhase(oneRMs, weeklyTrend);
    final isStalled = phase == StrengthTrendPhase.plateau &&
        sorted.length >= 4 &&
        sorted.last.date.difference(sorted.first.date).inDays >= 28;

    return StrengthTrendAnalysis(
      kalman1RM: kalman.value,
      confidence: kalman.confidence,
      weeklyTrend: weeklyTrend,
      phase: phase,
      isStalled: isStalled,
    );
  }

  _KalmanResult _kalmanFilter(List<double> values) {
    double estimate = values.first;
    double errorCovariance = 1.0;
    const processNoise = 1.0;
    const observationNoise = 5.0;

    for (final measurement in values) {
      final predictedError = errorCovariance + processNoise;
      final gain = predictedError / (predictedError + observationNoise);
      estimate = estimate + gain * (measurement - estimate);
      errorCovariance = (1 - gain) * predictedError;
    }

    return _KalmanResult(estimate, (1.0 / (1.0 + errorCovariance)).clamp(0.0, 1.0));
  }

  _HoltWintersResult _holtWinters(List<double> values) {
    if (values.length < 2) return _HoltWintersResult(values.first, 0);
    const alpha = 0.3;
    const beta = 0.1;
    double level = values.first;
    double trend = values[1] - values.first;

    for (int i = 1; i < values.length; i++) {
      final prevLevel = level;
      level = alpha * values[i] + (1 - alpha) * (level + trend);
      trend = beta * (level - prevLevel) + (1 - beta) * trend;
    }
    return _HoltWintersResult(level, trend);
  }

  StrengthTrendPhase _detectTrendPhase(List<double> values, double weeklyTrend) {
    if (values.length < 3) return StrengthTrendPhase.insufficient;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final cv = mean > 0 ? (math.sqrt(variance) / mean) : 0;

    if (cv > 0.15) return StrengthTrendPhase.inconsistent;
    if (weeklyTrend > 0.5) return StrengthTrendPhase.improving;
    if (weeklyTrend < -0.5) return StrengthTrendPhase.declining;
    return StrengthTrendPhase.plateau;
  }
}

class StrengthTrendAnalysis {
  final double kalman1RM;
  final double confidence;
  final double weeklyTrend;
  final StrengthTrendPhase phase;
  final bool isStalled;
  const StrengthTrendAnalysis({required this.kalman1RM, required this.confidence, required this.weeklyTrend, required this.phase, required this.isStalled});
}

enum StrengthTrendPhase { improving, plateau, declining, inconsistent, insufficient }

class _KalmanResult {
  final double value;
  final double confidence;
  _KalmanResult(this.value, this.confidence);
}

class _HoltWintersResult {
  final double level;
  final double trend;
  _HoltWintersResult(this.level, this.trend);
}
