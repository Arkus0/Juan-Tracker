/// Servicio avanzado para cálculo de tendencias de peso con múltiples modelos matemáticos
///
/// Implementación 100% offline sin redes neuronales. Combina:
/// - EMA (Exponential Moving Average) - Suavizado básico
/// - Holt-Winters - Nivel + Tendencia explícita
/// - Filtro de Kalman simple - Estimación óptima del "peso real"
/// - Regresión lineal - Pendiente de largo plazo
/// - Detección de fase - Identifica plateau, pérdida, ganancia
///
/// Todos los algoritmos son O(n) y funcionan en tiempo real en cualquier dispositivo.
library;

import '../models/weighin_model.dart' show WeighInModel;

// ============================================================================
// ENUMS Y CONFIGURACIÓN
// ============================================================================

/// Fase detectada del peso corporal
enum WeightPhase {
  losing, // Pérdida significativa
  maintaining, // Estable (plateau)
  gaining, // Ganancia significativa
  insufficientData, // No hay suficientes datos
}

/// Configuración para los algoritmos
class TrendConfig {
  /// Período para EMA (días)
  final int emaPeriod;

  /// Período para Holt-Winters (días)
  final int holtWintersPeriod;

  /// Ruido de proceso para Kalman (qué tan rápido puede cambiar el peso real)
  final double kalmanProcessNoise;

  /// Ruido de observación para Kalman (qué ruido tienen las básculas)
  final double kalmanObservationNoise;

  /// Umbral para considerar cambio significativo (kg/semana)
  final double phaseChangeThreshold;

  /// Días mínimos para considerar un plateau
  final int plateauMinDays;

  const TrendConfig({
    this.emaPeriod = 7,
    this.holtWintersPeriod = 7,
    this.kalmanProcessNoise = 0.01, // 10g de variación día a día esperada
    this.kalmanObservationNoise = 0.5, // 500g de ruido de báscula
    this.phaseChangeThreshold = 0.2, // 200g/semana
    this.plateauMinDays = 14,
  });

  static const defaultConfig = TrendConfig();
}

// ============================================================================
// RESULTADOS
// ============================================================================

/// Resultado completo del análisis de tendencia
class WeightTrendResult {
  // === EMA (Exponential Moving Average) ===
  final double emaWeight;
  final List<double> emaHistory;

  // === Holt-Winters (Nivel + Tendencia) ===
  final double hwLevel; // Nivel actual estimado
  final double hwTrend; // Tendencia (kg/día)
  final double? hwPrediction7d; // Predicción a 7 días
  final double? hwPrediction30d; // Predicción a 30 días

  // === Filtro de Kalman ===
  final double kalmanWeight; // Mejor estimación del peso "real"
  final double kalmanConfidence; // Confianza (0-1)

  // === Regresión Lineal ===
  final double regressionSlope; // Pendiente (kg/día)
  final double regressionIntercept;
  final double regressionR2; // Coeficiente de determinación (0-1)

  // === Análisis de Fase ===
  final WeightPhase phase;
  final int daysInPhase;
  final double weeklyRate; // kg/semana (positivo = ganancia)

  // === Datos ===
  final double latestWeight;
  final List<WeighInModel> entries;

  const WeightTrendResult({
    required this.emaWeight,
    required this.emaHistory,
    required this.hwLevel,
    required this.hwTrend,
    this.hwPrediction7d,
    this.hwPrediction30d,
    required this.kalmanWeight,
    required this.kalmanConfidence,
    required this.regressionSlope,
    required this.regressionIntercept,
    required this.regressionR2,
    required this.phase,
    required this.daysInPhase,
    required this.weeklyRate,
    required this.latestWeight,
    required this.entries,
  });

  /// Diferencia entre peso actual y tendencia
  double get variance => latestWeight - emaWeight;

  /// Trend weight recomendado (promedio ponderado de EMA y Kalman)
  double get trendWeight => (emaWeight * 0.4) + (kalmanWeight * 0.6);

  /// Descripción legible de la fase
  String get phaseDescription {
    switch (phase) {
      case WeightPhase.losing:
        return 'Perdiendo ${weeklyRate.abs().toStringAsFixed(1)} kg/semana';
      case WeightPhase.maintaining:
        return 'Estable (${daysInPhase} días)';
      case WeightPhase.gaining:
        return 'Ganando ${weeklyRate.toStringAsFixed(1)} kg/semana';
      case WeightPhase.insufficientData:
        return 'Recopilando datos...';
    }
  }

  /// Predicción del peso en N días usando Holt-Winters
  double? predictWeight(int days) {
    if (days <= 0) return hwLevel;
    return hwLevel + (hwTrend * days);
  }

  Map<String, dynamic> toDebugMap() => {
        'latestWeight': latestWeight,
        'trendWeight': trendWeight,
        'emaWeight': emaWeight,
        'kalmanWeight': kalmanWeight,
        'kalmanConfidence': kalmanConfidence,
        'hwLevel': hwLevel,
        'hwTrend': hwTrend,
        'hwPrediction7d': hwPrediction7d,
        'regressionSlope': regressionSlope,
        'regressionR2': regressionR2,
        'phase': phase.name,
        'daysInPhase': daysInPhase,
        'weeklyRate': weeklyRate,
      };

  @override
  String toString() => 'WeightTrendResult(${toDebugMap()})';
}

// ============================================================================
// CALCULADOR PRINCIPAL
// ============================================================================

/// Calculadora avanzada de tendencias de peso
class WeightTrendCalculator {
  final TrendConfig config;

  const WeightTrendCalculator({this.config = TrendConfig.defaultConfig});

  /// Calcula todas las métricas de tendencia
  WeightTrendResult calculate(List<WeighInModel> entries) {
    if (entries.isEmpty) {
      throw ArgumentError('Cannot calculate trend from empty entries list');
    }

    // Ordenar cronológicamente (más antiguo primero) para cálculos
    final sortedAsc = List<WeighInModel>.from(entries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Ordenar descendente (más reciente primero) para el resultado
    final sortedDesc = List<WeighInModel>.from(sortedAsc.reversed);

    final weights = sortedAsc.map((e) => e.weightKg).toList();

    // Calcular todos los modelos
    final ema = _calculateEMA(weights);
    final holtWinters = _calculateHoltWinters(weights);
    final kalman = _calculateKalman(weights);
    final regression = _calculateRegression(sortedAsc);
    final phase = _detectPhase(sortedAsc, ema.history);

    return WeightTrendResult(
      // EMA
      emaWeight: ema.current,
      emaHistory: ema.history.reversed.toList(), // Más reciente primero

      // Holt-Winters
      hwLevel: holtWinters.level,
      hwTrend: holtWinters.trend,
      hwPrediction7d: holtWinters.level + (holtWinters.trend * 7),
      hwPrediction30d: sortedAsc.length >= 14
          ? holtWinters.level + (holtWinters.trend * 30)
          : null,

      // Kalman
      kalmanWeight: kalman.current,
      kalmanConfidence: kalman.confidence,

      // Regresión
      regressionSlope: regression.slope,
      regressionIntercept: regression.intercept,
      regressionR2: regression.r2,

      // Fase
      phase: phase.phase,
      daysInPhase: phase.daysInPhase,
      weeklyRate: phase.weeklyRate,

      // Datos
      latestWeight: sortedDesc.first.weightKg,
      entries: sortedDesc,
    );
  }

  // ============================================================================
  // ALGORITMO 1: EMA (Exponential Moving Average)
  // ============================================================================

  _EMAResult _calculateEMA(List<double> weights) {
    final multiplier = 2.0 / (config.emaPeriod + 1);
    final emaValues = <double>[];
    double? previousEma;

    for (final weight in weights) {
      if (previousEma == null) {
        previousEma = weight;
      } else {
        previousEma = (weight - previousEma) * multiplier + previousEma;
      }
      emaValues.add(previousEma);
    }

    return _EMAResult(
      current: emaValues.last,
      history: emaValues,
    );
  }

  // ============================================================================
  // ALGORITMO 2: Holt-Winters (Doble Exponential Smoothing)
  // ============================================================================

  _HoltWintersResult _calculateHoltWinters(List<double> weights) {
    if (weights.length < 2) {
      return _HoltWintersResult(
        level: weights.first,
        trend: 0.0,
      );
    }

    // Parámetros de suavizado (alpha para nivel, beta para tendencia)
    final alpha = 2.0 / (config.holtWintersPeriod + 1);
    final beta = alpha * 0.5; // La tendencia suele ser más estable

    double level = weights.first;
    double trend = weights[1] - weights.first;

    for (int i = 1; i < weights.length; i++) {
      final value = weights[i];
      final previousLevel = level;

      // Actualizar nivel
      level = alpha * value + (1 - alpha) * (level + trend);

      // Actualizar tendencia
      trend = beta * (level - previousLevel) + (1 - beta) * trend;
    }

    return _HoltWintersResult(level: level, trend: trend);
  }

  // ============================================================================
  // ALGORITMO 3: Filtro de Kalman (1D simplificado)
  // ============================================================================

  _KalmanResult _calculateKalman(List<double> weights) {
    // Estado inicial
    double estimate = weights.first;
    double errorCovariance = 1.0; // Incertidumbre inicial

    final q = config.kalmanProcessNoise;
    final r = config.kalmanObservationNoise;

    for (int i = 0; i < weights.length; i++) {
      final measurement = weights[i];

      // Predicción
      final predictedEstimate = estimate;
      final predictedErrorCovariance = errorCovariance + q;

      // Actualización (corrección con la medición)
      final kalmanGain =
          predictedErrorCovariance / (predictedErrorCovariance + r);
      estimate = predictedEstimate + kalmanGain * (measurement - predictedEstimate);
      errorCovariance = (1 - kalmanGain) * predictedErrorCovariance;
    }

    // Confianza basada en la covarianza del error (menor = más confianza)
    final confidence = (1.0 / (1.0 + errorCovariance)).clamp(0.0, 1.0);

    return _KalmanResult(
      current: estimate,
      confidence: confidence,
    );
  }

  // ============================================================================
  // ALGORITMO 4: Regresión Lineal (Mínimos Cuadrados)
  // ============================================================================

  _RegressionResult _calculateRegression(List<WeighInModel> entries) {
    if (entries.length < 2) {
      return _RegressionResult(slope: 0, intercept: entries.first.weightKg, r2: 0);
    }

    final n = entries.length;

    // Usar índices como X (0, 1, 2, ...) y peso como Y
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = entries[i].weightKg;

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;
    }

    final denominator = n * sumX2 - sumX * sumX;

    if (denominator.abs() < 1e-10) {
      return _RegressionResult(slope: 0, intercept: sumY / n, r2: 0);
    }

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;

    // Calcular R²
    final yMean = sumY / n;
    double ssTotal = 0, ssResidual = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = entries[i].weightKg;
      final predicted = slope * x + intercept;

      ssTotal += (y - yMean) * (y - yMean);
      ssResidual += (y - predicted) * (y - predicted);
    }

    final r2 = ssTotal > 0 ? 1 - (ssResidual / ssTotal) : 0;

    return _RegressionResult(
      slope: slope,
      intercept: intercept,
      r2: r2.clamp(0, 1).toDouble(),
    );
  }

  // ============================================================================
  // ALGORITMO 5: Detección de Fase y Plateau
  // ============================================================================

  _PhaseResult _detectPhase(
    List<WeighInModel> entries,
    List<double> emaValues,
  ) {
    if (entries.length < 3) {
      return _PhaseResult(
        phase: WeightPhase.insufficientData,
        daysInPhase: 0,
        weeklyRate: 0,
      );
    }

    // Calcular cambio reciente usando pendiente de los últimos 7-14 días
    final recentDays = entries.length >= 14 ? 14 : entries.length;
    final recentEntries = entries.sublist(entries.length - recentDays);

    // Calcular tasa semanal (kg/semana)
    final firstWeight = recentEntries.first.weightKg;
    final lastWeight = recentEntries.last.weightKg;
    final daysDiff = recentEntries.last.dateTime
        .difference(recentEntries.first.dateTime)
        .inDays;

    if (daysDiff < 1) {
      return _PhaseResult(
        phase: WeightPhase.insufficientData,
        daysInPhase: 0,
        weeklyRate: 0,
      );
    }

    final dailyRate = (lastWeight - firstWeight) / daysDiff;
    final weeklyRate = dailyRate * 7;

    // Detectar fase
    WeightPhase phase;
    if (weeklyRate.abs() < config.phaseChangeThreshold) {
      phase = WeightPhase.maintaining;
    } else if (weeklyRate < 0) {
      phase = WeightPhase.losing;
    } else {
      phase = WeightPhase.gaining;
    }

    // Contar días en la fase actual (recorriendo hacia atrás)
    int daysInPhase = 0;
    if (entries.length >= 2) {
      // Usar EMA para detectar cambios de dirección
      for (int i = emaValues.length - 1; i > 0; i--) {
        final currentDiff = emaValues[i] - emaValues[i - 1];
        final currentSign = currentDiff.sign;

        // Verificar si el signo coincide con la fase detectada
        bool matchesPhase = false;
        if (phase == WeightPhase.maintaining && currentDiff.abs() < 0.05) {
          matchesPhase = true;
        } else if (phase == WeightPhase.losing && currentSign < 0) {
          matchesPhase = true;
        } else if (phase == WeightPhase.gaining && currentSign > 0) {
          matchesPhase = true;
        }

        if (matchesPhase) {
          // Estimar días basado en la diferencia de tiempo
          if (i < entries.length) {
            final daysBetween = entries[i]
                .dateTime
                .difference(entries[i - 1].dateTime)
                .inDays;
            daysInPhase += daysBetween > 0 ? daysBetween : 1;
          } else {
            daysInPhase += 1;
          }
        } else {
          break;
        }
      }
    }

    return _PhaseResult(
      phase: phase,
      daysInPhase: daysInPhase.clamp(0, daysDiff),
      weeklyRate: weeklyRate,
    );
  }

  // ============================================================================
  // UTILIDADES
  // ============================================================================

  /// Genera datos para gráfico con múltiples líneas
  List<ChartDataPoint> generateChartData(List<WeighInModel> entries) {
    if (entries.isEmpty) return [];

    final result = calculate(entries);
    final points = <ChartDataPoint>[];

    // Ordenar cronológicamente
    final sortedAsc = List<WeighInModel>.from(entries)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    for (int i = 0; i < sortedAsc.length; i++) {
      final entry = sortedAsc[i];
      final emaIndex = result.emaHistory.length - 1 - (sortedAsc.length - 1 - i);

      points.add(ChartDataPoint(
        date: entry.dateTime,
        weight: entry.weightKg,
        ema: emaIndex >= 0 && emaIndex < result.emaHistory.length
            ? result.emaHistory[emaIndex]
            : null,
        kalman: null, // Requeriría guardar historia de Kalman
        note: entry.note,
      ));
    }

    return points;
  }
}

// ============================================================================
// CLASES AUXILIARES INTERNAS
// ============================================================================

class _EMAResult {
  final double current;
  final List<double> history;
  _EMAResult({required this.current, required this.history});
}

class _HoltWintersResult {
  final double level;
  final double trend;
  _HoltWintersResult({required this.level, required this.trend});
}

class _KalmanResult {
  final double current;
  final double confidence;
  _KalmanResult({required this.current, required this.confidence});
}

class _RegressionResult {
  final double slope; // kg/día
  final double intercept;
  final double r2;
  _RegressionResult({
    required this.slope,
    required this.intercept,
    required this.r2,
  });
}

class _PhaseResult {
  final WeightPhase phase;
  final int daysInPhase;
  final double weeklyRate; // kg/semana
  _PhaseResult({
    required this.phase,
    required this.daysInPhase,
    required this.weeklyRate,
  });
}

// ============================================================================
// PUNTOS DE DATOS PARA GRÁFICOS
// ============================================================================

/// Punto de datos enriquecido para gráficos
class ChartDataPoint {
  final DateTime date;
  final double weight;
  final double? ema;
  final double? kalman;
  final String? note;

  const ChartDataPoint({
    required this.date,
    required this.weight,
    this.ema,
    this.kalman,
    this.note,
  });
}

// ============================================================================
// EXTENSIONES
// ============================================================================

extension WeightTrendResultExtensions on WeightTrendResult {
  /// Verifica si la predicción es fiable (R² > 0.7 y suficientes datos)
  bool get isPredictionReliable =>
      regressionR2 > 0.7 && entries.length >= 7 && kalmanConfidence > 0.6;

  /// Descripción completa del estado
  String get fullStatus {
    final buffer = StringBuffer();
    buffer.writeln('Peso: ${latestWeight.toStringAsFixed(1)} kg');
    buffer.writeln('Tendencia: ${trendWeight.toStringAsFixed(1)} kg');
    buffer.writeln(phaseDescription);
    if (hwPrediction7d != null) {
      buffer.writeln('Predicción 7d: ${hwPrediction7d!.toStringAsFixed(1)} kg');
    }
    buffer.writeln('Confianza: ${(kalmanConfidence * 100).toStringAsFixed(0)}%');
    return buffer.toString();
  }
}
