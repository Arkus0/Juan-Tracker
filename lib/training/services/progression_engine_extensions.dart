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

/// 🎯 MED-005: Análisis de riesgo de sobreentrenamiento y recomendación de deload
class OvertrainingRisk {
  final RiskLevel level;
  final bool shouldDeload;
  final String recommendation;
  final List<String> warningSigns;

  const OvertrainingRisk({
    required this.level,
    required this.shouldDeload,
    required this.recommendation,
    this.warningSigns = const [],
  });
}

enum RiskLevel { low, moderate, high, critical }

/// Extensión para detección de deload
extension DeloadDetection on ProgressionEngine {
  /// 🎯 MED-005: Detecta riesgo de sobreentrenamiento
  /// 
  /// Señales de alerta:
  /// - 3+ semanas sin progreso (plateau)
  /// - RPE promedio aumentando
  /// - Fallos repetidos al mismo peso
  OvertrainingRisk detectOvertrainingRisk({
    required List<StrengthDataPoint> recent1RMs,
    required List<int> recentRPEs,
    required int failuresAtCurrentWeight,
  }) {
    final signs = <String>[];
    var riskScore = 0;

    // Señal 1: Estancamiento prolongado
    if (recent1RMs.length >= 4) {
      final analysis = analyzeStrengthTrend(recent1RMs);
      if (analysis.isStalled) {
        signs.add('${recent1RMs.length} semanas sin progreso');
        riskScore += 3;
      }
    }

    // Señal 2: RPE aumentando
    if (recentRPEs.length >= 3) {
      final avgRecent = recentRPEs.take(3).reduce((a, b) => a + b) / 3;
      final avgPrevious = recentRPEs.skip(3).take(3).reduce((a, b) => a + b) / 3;
      if (avgRecent > avgPrevious + 1) {
        signs.add('RPE aumentando (${avgRecent.toStringAsFixed(1)} vs ${avgPrevious.toStringAsFixed(1)})');
        riskScore += 2;
      }
    }

    // Señal 3: Fallos repetidos
    if (failuresAtCurrentWeight >= 2) {
      signs.add('$failuresAtCurrentWeight fallos al mismo peso');
      riskScore += 2;
    }

    // Determinar nivel de riesgo
    RiskLevel level;
    if (riskScore >= 6) {
      level = RiskLevel.critical;
    } else if (riskScore >= 4) {
      level = RiskLevel.high;
    } else if (riskScore >= 2) {
      level = RiskLevel.moderate;
    } else {
      level = RiskLevel.low;
    }

    // Generar recomendación
    String recommendation;
    switch (level) {
      case RiskLevel.critical:
        recommendation = 'Deload URGENTE: Reduce volumen 40-50% esta semana';
        break;
      case RiskLevel.high:
        recommendation = 'Deload recomendado: Reduce volumen 20-30%';
        break;
      case RiskLevel.moderate:
        recommendation = 'Monitorea tu recuperación. Considera descanso extra';
        break;
      case RiskLevel.low:
        recommendation = 'Progresión normal. Sigue así!';
        break;
    }

    return OvertrainingRisk(
      level: level,
      shouldDeload: level == RiskLevel.high || level == RiskLevel.critical,
      recommendation: recommendation,
      warningSigns: signs,
    );
  }
}
