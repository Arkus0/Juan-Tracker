/// Servicio de analisis de fuerza multi-modelo
library;

import '../models/analysis_models.dart';
import 'dart:math';

class StrengthAnalysisResult {
  final List<StrengthDataPoint> dataPoints;
  final double kalman1RM;
  final double kalmanConfidence;
  final double hwLevel;
  final double hwTrend;
  final double regressionSlope;
  final double regressionR2;
  final StrengthPhase phase;
  final int weeksInPhase;
  final double weeklyProgression;
  
  const StrengthAnalysisResult({
    required this.dataPoints,
    required this.kalman1RM,
    required this.kalmanConfidence,
    required this.hwLevel,
    required this.hwTrend,
    required this.regressionSlope,
    required this.regressionR2,
    required this.phase,
    required this.weeksInPhase,
    required this.weeklyProgression,
  });
  
  double get trend1RM => (kalman1RM * 0.6) + (hwLevel * 0.4);
  bool get isStalled => phase == StrengthPhase.plateau && weeksInPhase >= 4;
}

enum StrengthPhase { improving, plateau, declining, inconsistent }

class StrengthAnalysisService {
  const StrengthAnalysisService();
  
  StrengthAnalysisResult analyze(List<StrengthDataPoint> points) {
    if (points.isEmpty) throw ArgumentError('No data');
    if (points.length < 3) return _basicAnalysis(points);
    
    final sorted = List<StrengthDataPoint>.from(points)
      ..sort((a, b) => a.date.compareTo(b.date));
    final oneRMs = sorted.map((p) => p.estimated1RM).toList();
    
    final kalman = _kalmanFilter(oneRMs);
    final holtWinters = _holtWinters(oneRMs);
    final regression = _linearRegression(sorted);
    final phase = _detectPhase(oneRMs, regression.slope);
    
    final daysSpan = sorted.last.date.difference(sorted.first.date).inDays;
    final weeklyProgression = daysSpan > 0
        ? (oneRMs.last - oneRMs.first) / (daysSpan / 7)
        : 0.0;
        
    return StrengthAnalysisResult(
      dataPoints: sorted,
      kalman1RM: kalman.value,
      kalmanConfidence: kalman.confidence,
      hwLevel: holtWinters.level,
      hwTrend: holtWinters.trend * 7,
      regressionSlope: regression.slope,
      regressionR2: regression.r2,
      phase: phase,
      weeksInPhase: 0,
      weeklyProgression: weeklyProgression,
    );
  }
  
  StrengthAnalysisResult _basicAnalysis(List<StrengthDataPoint> points) {
    final avg = points.map((p) => p.estimated1RM).reduce((a, b) => a + b) / points.length;
    return StrengthAnalysisResult(
      dataPoints: points,
      kalman1RM: avg,
      kalmanConfidence: 0.5,
      hwLevel: avg,
      hwTrend: 0,
      regressionSlope: 0,
      regressionR2: 0,
      phase: StrengthPhase.inconsistent,
      weeksInPhase: 0,
      weeklyProgression: 0,
    );
  }
  
  _KalmanResult _kalmanFilter(List<double> values) {
    double estimate = values.first;
    double errorCovariance = 1.0;
    const processNoise = 0.5;
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
  
  _RegressionResult _linearRegression(List<StrengthDataPoint> points) {
    final n = points.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += points[i].estimated1RM;
      sumXY += i * points[i].estimated1RM;
      sumX2 += i * i;
    }
    
    final denom = n * sumX2 - sumX * sumX;
    if (denom.abs() < 1e-10) return _RegressionResult(0, sumY / n, 0);
    
    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;
    
    final yMean = sumY / n;
    double ssTotal = 0, ssResidual = 0;
    for (int i = 0; i < n; i++) {
      final pred = slope * i + intercept;
      ssTotal += pow(points[i].estimated1RM - yMean, 2);
      ssResidual += pow(points[i].estimated1RM - pred, 2);
    }
    final r2 = ssTotal > 0 ? 1 - (ssResidual / ssTotal) : 0;
    
    return _RegressionResult(slope, intercept, r2.clamp(0, 1).toDouble());
  }
  
  StrengthPhase _detectPhase(List<double> values, double slope) {
    if (values.length < 3) return StrengthPhase.inconsistent;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final cv = mean > 0 ? (sqrt(variance) / mean) : 0;
    
    if (cv > 0.1) return StrengthPhase.inconsistent;
    if (slope > 0.5) return StrengthPhase.improving;
    if (slope < -0.5) return StrengthPhase.declining;
    return StrengthPhase.plateau;
  }
}

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

class _RegressionResult {
  final double slope;
  final double intercept;
  final double r2;
  _RegressionResult(this.slope, this.intercept, this.r2);
}
