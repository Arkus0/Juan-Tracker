/// Servicio de progresión para Rest-Pause (RP)
///
/// El Rest-Pause es una técnica donde:
/// 1. Haces reps al fallo (ej: 8 reps)
/// 2. Descansas 10-20 segundos
/// 3. Haces más reps con el mismo peso (ej: 3 reps más)
/// 4. Total = 11 reps "efectivas"
///
/// Este servicio sugiere cuándo aumentar peso basado en el rendimiento en RP.
class RestPauseService {
  /// Umbral mínimo de reps totales en RP para considerar progresar
  static const int minTotalRepsForProgression = 10;
  
  /// Umbral mínimo de reps en la "mini-serie" después del descanso
  static const int minMiniSetReps = 2;
  
  /// Incremento de peso sugerido para RP (más conservador que series normales)
  static const double weightIncrement = 2.5; // kg

  /// Analiza una serie RP y determina si se debe progresar.
  ///
  /// [targetReps] - Reps objetivo de la serie original (ej: 8)
  /// [firstSetReps] - Reps logradas en el primer intento (ej: 8)
  /// [miniSetReps] - Reps logradas después del descanso RP (ej: 3)
  /// [currentWeight] - Peso actual usado
  ///
  /// Retorna [RestPauseProgressionResult] con la decisión y sugerencias.
  RestPauseProgressionResult analyze({
    required int targetReps,
    required int firstSetReps,
    required int miniSetReps,
    required double currentWeight,
  }) {
    final totalReps = firstSetReps + miniSetReps;
    
    // Si no cumple el mínimo de reps totales, mantener peso
    if (totalReps < minTotalRepsForProgression) {
      return RestPauseProgressionResult(
        shouldProgress: false,
        currentWeight: currentWeight,
        message: 'Mantén $currentWeight kg. Busca al menos $minTotalRepsForProgression reps totales '
                 '($firstSetReps + $miniSetReps = $totalReps)',
        totalReps: totalReps,
        targetReps: targetReps,
      );
    }
    
    // Si la mini-serie es muy corta, mantener peso pero estás cerca
    if (miniSetReps < minMiniSetReps) {
      return RestPauseProgressionResult(
        shouldProgress: false,
        currentWeight: currentWeight,
        message: 'Casi. Lograste $totalReps reps totales pero solo $miniSetReps en la mini-serie. '
                 'Intenta descansar un poco menos (10-15s) la próxima vez.',
        totalReps: totalReps,
        targetReps: targetReps,
      );
    }
    
    // Si completó el objetivo + reps extra en mini-serie = PROGRESAR
    if (firstSetReps >= targetReps && miniSetReps >= minMiniSetReps) {
      return RestPauseProgressionResult(
        shouldProgress: true,
        currentWeight: currentWeight,
        suggestedWeight: _calculateNewWeight(currentWeight),
        message: '¡Excelente RP! $firstSetReps reps + $miniSetReps reps = $totalReps totales. '
                 'Sube a ${_calculateNewWeight(currentWeight)} kg.',
        totalReps: totalReps,
        targetReps: targetReps,
      );
    }
    
    // Fallback: mantener peso
    return RestPauseProgressionResult(
      shouldProgress: false,
      currentWeight: currentWeight,
      message: 'Mantén $currentWeight kg. Intenta llegar a $targetReps reps + $minMiniSetReps en mini-serie.',
      totalReps: totalReps,
      targetReps: targetReps,
    );
  }

  /// Calcula el nuevo peso sugerido.
  double _calculateNewWeight(double currentWeight) {
    // Incremento conservador para RP
    if (currentWeight < 20) return currentWeight + 1.25;
    if (currentWeight < 50) return currentWeight + 2.5;
    return currentWeight + 5.0;
  }

  /// Valida si una serie marcada como RP tiene sentido.
  ///
  /// Retorna advertencias si detecta inconsistencias.
  List<String> validateRestPauseSet({
    required int setIndex,
    required int totalSets,
    required bool isRestPause,
    int? previousSetReps,
    int? currentSetReps,
  }) {
    final warnings = <String>[];
    
    if (!isRestPause) return warnings;
    
    // No debería ser la primera serie
    if (setIndex == 0) {
      warnings.add('RP en primera serie: Considera calentar antes de hacer RP');
    }
    
    // No debería ser la última serie (sin sentido, no hay más series después)
    if (setIndex == totalSets - 1) {
      warnings.add('RP en última serie: No hay series después para comparar');
    }
    
    return warnings;
  }

  /// Genera un resumen de la sesión con RP.
  RestPauseSessionSummary summarizeSession({
    required List<RestPauseSetData> rpSets,
  }) {
    if (rpSets.isEmpty) {
      return const RestPauseSessionSummary(
        totalRpSets: 0,
        totalExtraReps: 0,
        message: 'No se registraron series RP',
      );
    }
    
    final totalExtraReps = rpSets.fold<int>(
      0, 
      (sum, set) => sum + (set.miniSetReps ?? 0),
    );
    
    final avgFirstSetReps = rpSets.fold<int>(0, (sum, s) => sum + s.firstSetReps) / rpSets.length;
    
    return RestPauseSessionSummary(
      totalRpSets: rpSets.length,
      totalExtraReps: totalExtraReps,
      averageFirstSetReps: avgFirstSetReps,
      message: 'RP completado: ${rpSets.length} series, $totalExtraReps reps extra',
    );
  }
}

/// Datos de una serie RP
class RestPauseSetData {
  final int setIndex;
  final int firstSetReps;
  final int? miniSetReps;
  final double weight;
  final bool completed;

  const RestPauseSetData({
    required this.setIndex,
    required this.firstSetReps,
    this.miniSetReps,
    required this.weight,
    this.completed = true,
  });

  int get totalReps => firstSetReps + (miniSetReps ?? 0);
}

/// Resultado del análisis de progresión RP
class RestPauseProgressionResult {
  final bool shouldProgress;
  final double currentWeight;
  final double? suggestedWeight;
  final String message;
  final int totalReps;
  final int targetReps;

  const RestPauseProgressionResult({
    required this.shouldProgress,
    required this.currentWeight,
    this.suggestedWeight,
    required this.message,
    required this.totalReps,
    required this.targetReps,
  });

  bool get shouldIncreaseWeight => suggestedWeight != null && suggestedWeight! > currentWeight;
  double get weightIncrease => suggestedWeight != null ? suggestedWeight! - currentWeight : 0;
}

/// Resumen de sesión con RP
class RestPauseSessionSummary {
  final int totalRpSets;
  final int totalExtraReps;
  final double? averageFirstSetReps;
  final String message;

  const RestPauseSessionSummary({
    required this.totalRpSets,
    required this.totalExtraReps,
    this.averageFirstSetReps,
    required this.message,
  });

  double get averageExtraRepsPerSet => 
      totalRpSets > 0 ? totalExtraReps / totalRpSets : 0;
}

/// Extensión para calcular volumen efectivo incluyendo RP
extension RestPauseVolume on List<RestPauseSetData> {
  /// Calcula el volumen total incluyendo reps de mini-series RP
  double calculateEffectiveVolume() {
    return fold<double>(0, (sum, set) => sum + (set.totalReps * set.weight));
  }
  
  /// Calcula reps totales incluyendo mini-series
  int get totalRepsIncludingMiniSets {
    return fold<int>(0, (sum, set) => sum + set.totalReps);
  }
}
