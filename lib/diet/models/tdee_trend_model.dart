// Modelos para la visualización de tendencia TDEE

/// Punto de datos de TDEE estimado para un día
class TdeeDataPoint {
  final DateTime date;
  final double estimatedTdee;
  final double avgIntake;
  final double weightChangePeriod; // kg en el periodo de ventana
  final int windowDays;
  final int diaryDaysInWindow;
  final int weighInDaysInWindow;
  final double confidence; // 0.0 - 1.0

  const TdeeDataPoint({
    required this.date,
    required this.estimatedTdee,
    required this.avgIntake,
    required this.weightChangePeriod,
    required this.windowDays,
    required this.diaryDaysInWindow,
    required this.weighInDaysInWindow,
    required this.confidence,
  });
}

/// Dirección de la tendencia TDEE
enum TdeeTrendDirection { increasing, stable, decreasing, insufficient }

/// Resultado completo del análisis de tendencia TDEE
class TdeeTrendResult {
  /// Puntos de datos ordenados cronológicamente
  final List<TdeeDataPoint> dataPoints;

  /// Puntos suavizados con EMA para el gráfico
  final List<TdeeDataPoint> smoothedPoints;

  /// TDEE actual estimado (último punto suavizado)
  final double? currentTdee;

  /// TDEE promedio del período
  final double? avgTdee;

  /// Dirección de la tendencia
  final TdeeTrendDirection direction;

  /// Cambio semanal estimado en kcal
  final double? weeklyChangeKcal;

  /// TDEE inicial del CoachPlan (referencia)
  final int? initialTdeeEstimate;

  /// Target kcal actual (referencia)
  final int? currentTargetKcal;

  const TdeeTrendResult({
    required this.dataPoints,
    required this.smoothedPoints,
    this.currentTdee,
    this.avgTdee,
    this.direction = TdeeTrendDirection.insufficient,
    this.weeklyChangeKcal,
    this.initialTdeeEstimate,
    this.currentTargetKcal,
  });

  /// Resultado vacío cuando no hay datos suficientes
  static const empty = TdeeTrendResult(
    dataPoints: [],
    smoothedPoints: [],
    direction: TdeeTrendDirection.insufficient,
  );

  bool get hasData => smoothedPoints.length >= 2;

  /// Rango de TDEE para configurar los ejes del gráfico
  double get minTdee {
    if (smoothedPoints.isEmpty) return 1500;
    return smoothedPoints
        .map((p) => p.estimatedTdee)
        .reduce((a, b) => a < b ? a : b);
  }

  double get maxTdee {
    if (smoothedPoints.isEmpty) return 2500;
    return smoothedPoints
        .map((p) => p.estimatedTdee)
        .reduce((a, b) => a > b ? a : b);
  }
}
