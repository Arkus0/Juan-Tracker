import '../models/progression_engine_models.dart';
import '../models/progression_type.dart';

// ════════════════════════════════════════════════════════════════════════════
// PROGRESSION CONTROLLER v3
// ════════════════════════════════════════════════════════════════════════════
//
// Arquitectura de 3 capas:
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │                        PROGRESSION CONTROLLER                           │
// │                     (Orquestador / Máquina de Estados)                  │
// ├─────────────────────────────────────────────────────────────────────────┤
// │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
// │  │  EXECUTION DATA  │  │ PROGRESSION MODEL│  │    DECISION      │      │
// │  │  (Datos Crudos)  │  │  (Estrategia)    │  │   (Resultado)    │      │
// │  ├──────────────────┤  ├──────────────────┤  ├──────────────────┤      │
// │  │ - SessionHistory │  │ - Linear         │  │ - Action         │      │
// │  │ - CurrentWeight  │  │ - Double         │  │ - NewWeight      │      │
// │  │ - TargetReps     │  │ - RPE/RIR        │  │ - UserMessage    │      │
// │  │ - Category       │  │ - Custom         │  │ - NextPreview    │      │
// │  └──────────────────┘  └──────────────────┘  └──────────────────┘      │
// └─────────────────────────────────────────────────────────────────────────┘
//
// DIAGRAMA DE ESTADOS:
//
//                    ┌──────────────────┐
//                    │    CALIBRATING   │ ←─── Inicio (0-1 sesiones)
//                    │    (calibrando)  │
//                    └────────┬─────────┘
//                             │ 2 sesiones completadas
//                             ▼
//     ┌──────────────────────────────────────────────────────────────┐
//     │                                                              │
//     │  ┌──────────────┐    éxito    ┌──────────────┐              │
//     │  │  PROGRESSING │ ──────────► │  CONFIRMING  │              │
//     │  │ (progresando)│ ◄────────── │ (confirmando)│              │
//     │  └──────────────┘   fracaso   └──────┬───────┘              │
//     │         │                            │                       │
//     │         │ 3+ fracasos                │ 2do éxito             │
//     │         ▼                            ▼                       │
//     │  ┌──────────────┐           ┌──────────────┐                │
//     │  │   PLATEAU    │           │   PROGRESS   │ (subir peso)   │
//     │  │  (estancado) │           │   ACHIEVED   │                │
//     │  └──────┬───────┘           └──────────────┘                │
//     │         │                                                    │
//     │         │ deload completado                                  │
//     │         ▼                                                    │
//     │  ┌──────────────┐                                           │
//     │  │   DELOADING  │ ───────────────────────────────────►      │
//     │  │   (deload)   │              vuelve a PROGRESSING         │
//     │  └──────────────┘                                           │
//     │                                                              │
//     └──────────────────────────────────────────────────────────────┘
//
// ════════════════════════════════════════════════════════════════════════════

/// Estado extendido del controlador de progresión
enum ControllerState {
  /// Recopilando datos iniciales (0-1 sesiones)
  calibrating('calibrating', 'Calibrando', '⚙️'),

  /// Progresión normal activa
  progressing('progressing', 'Progresando', '📈'),

  /// Esperando confirmación de 2da sesión exitosa
  confirming('confirming', 'Confirmando', '🔄'),

  /// Estancamiento detectado (3+ fracasos)
  plateau('plateau', 'Estancado', '⚠️'),

  /// En fase de deload
  deloading('deloading', 'Deload', '🔽'),

  /// Fatiga acumulada detectada (RPE consistentemente alto)
  fatigued('fatigued', 'Fatiga', '😓'),

  /// Regresión necesaria (peso demasiado alto)
  regression('regression', 'Regresión', '↩️');

  final String value;
  final String label;
  final String emoji;

  const ControllerState(this.value, this.label, this.emoji);

  static ControllerState fromString(String? value) {
    if (value == null) return ControllerState.calibrating;
    for (final state in ControllerState.values) {
      if (state.value == value) return state;
    }
    return ControllerState.calibrating;
  }
}

/// Reglas de transición entre estados (explícitas y visibles)
class TransitionRule {
  final ControllerState from;
  final ControllerState to;
  final String condition;
  final String userExplanation;

  const TransitionRule({
    required this.from,
    required this.to,
    required this.condition,
    required this.userExplanation,
  });

  @override
  String toString() => '$from → $to: $condition';
}

/// Umbrales configurables (visibles para el usuario)
class ProgressionThresholds {
  /// % mínimo de series exitosas para considerar sesión "exitosa"
  final double successRate;

  /// Sesiones exitosas consecutivas para subir peso
  final int confirmationSessions;

  /// Sesiones fallidas consecutivas para detectar estancamiento
  final int plateauThreshold;

  /// RPE promedio para detectar fatiga
  final double fatigueRpeThreshold;

  /// Semanas máximas en el mismo peso antes de forzar cambio
  final int maxWeeksAtWeight;

  const ProgressionThresholds({
    this.successRate = 0.80, // 80%
    this.confirmationSessions = 2,
    this.plateauThreshold = 3,
    this.fatigueRpeThreshold = 9.0,
    this.maxWeeksAtWeight = 4,
  });

  /// Umbrales por defecto
  static const defaults = ProgressionThresholds();

  /// Umbrales más agresivos (para principiantes)
  static const aggressive = ProgressionThresholds(
    successRate: 0.75,
    confirmationSessions: 1,
    plateauThreshold: 2,
  );

  /// Umbrales conservadores (para intermedios/avanzados)
  static const conservative = ProgressionThresholds(
    successRate: 0.85,
    confirmationSessions: 3,
    plateauThreshold: 4,
    maxWeeksAtWeight: 6,
  );

  /// Copia con modificaciones
  ProgressionThresholds copyWith({
    double? successRate,
    int? confirmationSessions,
    int? plateauThreshold,
    double? fatigueRpeThreshold,
    int? maxWeeksAtWeight,
  }) {
    return ProgressionThresholds(
      successRate: successRate ?? this.successRate,
      confirmationSessions: confirmationSessions ?? this.confirmationSessions,
      plateauThreshold: plateauThreshold ?? this.plateauThreshold,
      fatigueRpeThreshold: fatigueRpeThreshold ?? this.fatigueRpeThreshold,
      maxWeeksAtWeight: maxWeeksAtWeight ?? this.maxWeeksAtWeight,
    );
  }

  /// Descripción legible de los umbrales
  String describe() {
    return '''
Umbrales de Progresión:
• Éxito de sesión: ≥${(successRate * 100).round()}% series completadas
• Confirmar subida: $confirmationSessions sesiones exitosas consecutivas
• Detectar estancamiento: $plateauThreshold sesiones fallidas
• Fatiga: RPE promedio ≥$fatigueRpeThreshold
• Máximo en mismo peso: $maxWeeksAtWeight semanas
''';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CAPA 1: DATOS DE EJECUCIÓN
// ════════════════════════════════════════════════════════════════════════════

/// Datos crudos de ejecución (independientes del modelo de progresión)
class ExecutionData {
  /// Nombre del ejercicio
  final String exerciseName;

  /// Categoría del ejercicio
  final ExerciseCategory category;

  /// Peso actual confirmado (baseline)
  final double confirmedWeight;

  /// Rango de reps objetivo (min, max)
  final (int, int) repsRange;

  /// Historial de últimas N sesiones
  final List<SessionExecutionData> sessionHistory;

  /// Semanas en el peso actual
  final int weeksAtCurrentWeight;

  const ExecutionData({
    required this.exerciseName,
    required this.category,
    required this.confirmedWeight,
    required this.repsRange,
    required this.sessionHistory,
    this.weeksAtCurrentWeight = 0,
  });

  /// ¿Hay suficientes datos para decisiones?
  bool get hasEnoughData => sessionHistory.length >= 2;

  /// Última sesión
  SessionExecutionData? get lastSession =>
      sessionHistory.isNotEmpty ? sessionHistory.first : null;

  /// Reps objetivo (mínimo del rango)
  int get targetReps => repsRange.$1;

  /// Reps máximas (máximo del rango)
  int get maxReps => repsRange.$2;

  /// Incremento de peso apropiado
  double get increment => category.getIncrement(confirmedWeight);

  /// Calcula éxitos consecutivos
  int get consecutiveSuccesses {
    var count = 0;
    for (final session in sessionHistory) {
      if (session.isSuccess) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Calcula fracasos consecutivos
  int get consecutiveFailures {
    var count = 0;
    for (final session in sessionHistory) {
      if (!session.isSuccess) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// RPE promedio de las últimas N sesiones
  double? get averageRpe {
    final rpeSessions = sessionHistory
        .where((s) => s.averageRpe != null)
        .take(3)
        .toList();
    if (rpeSessions.isEmpty) return null;
    return rpeSessions.map((s) => s.averageRpe!).reduce((a, b) => a + b) /
        rpeSessions.length;
  }
}

/// Datos de una sesión ejecutada
class SessionExecutionData {
  final DateTime date;
  final double weight;
  final List<SetExecutionData> sets;

  const SessionExecutionData({
    required this.date,
    required this.weight,
    required this.sets,
  });

  /// ¿Sesión exitosa? (≥80% series OK)
  bool get isSuccess => successRate >= 0.80;

  /// Tasa de éxito (0.0 - 1.0)
  double get successRate {
    if (sets.isEmpty) return 0.0;
    final completed = sets.where((s) => s.completed && s.metTarget).length;
    return completed / sets.length;
  }

  /// Reps promedio
  double get averageReps {
    if (sets.isEmpty) return 0;
    return sets.map((s) => s.reps).reduce((a, b) => a + b) / sets.length;
  }

  /// RPE promedio
  double? get averageRpe {
    final setsWithRpe = sets.where((s) => s.rpe != null).toList();
    if (setsWithRpe.isEmpty) return null;
    return setsWithRpe.map((s) => s.rpe!).reduce((a, b) => a + b) /
        setsWithRpe.length;
  }

  /// Evalúa resultado de la sesión
  SessionResult evaluate() {
    final rate = successRate;
    if (rate >= 1.0) return SessionResult.complete;
    if (rate >= 0.80) return SessionResult.acceptable;
    if (rate >= 0.50) return SessionResult.partial;
    return SessionResult.failed;
  }
}

/// Datos de una serie ejecutada
class SetExecutionData {
  final int reps;
  final double weight;
  final int targetReps;
  final bool completed;
  final double? rpe;

  const SetExecutionData({
    required this.reps,
    required this.weight,
    required this.targetReps,
    required this.completed,
    this.rpe,
  });

  /// ¿Alcanzó el objetivo?
  bool get metTarget => completed && reps >= targetReps;
}

// ════════════════════════════════════════════════════════════════════════════
// CAPA 2: MODELOS DE PROGRESIÓN (ESTRATEGIAS INTERCAMBIABLES)
// ════════════════════════════════════════════════════════════════════════════

/// Interfaz para modelos de progresión
abstract class ProgressionModel {
  /// Nombre del modelo
  String get name;

  /// Descripción para el usuario
  String get description;

  /// Calcula la decisión basada en datos y estado
  ProgressionDecision calculate({
    required ExecutionData data,
    required ControllerState currentState,
    required ProgressionThresholds thresholds,
  });

  /// Determina si debe cambiar de estado
  ControllerState? shouldTransition({
    required ExecutionData data,
    required ControllerState currentState,
    required ProgressionThresholds thresholds,
  });
}

/// Modelo: Progresión Lineal (Starting Strength / StrongLifts 5x5)
///
/// Reglas según Rippetoe y Mehdi:
/// - Sesión exitosa → subir peso INMEDIATAMENTE (sin confirmación)
/// - Stall = 3 fallos al MISMO peso → deload 10%
/// - Después de deload, volver a subir progresivamente
///
/// "Add weight to the bar every workout for as long as possible."
/// — Mark Rippetoe, Starting Strength 3rd Ed.
class LinearProgressionModel implements ProgressionModel {
  const LinearProgressionModel();

  @override
  String get name => 'Lineal (Starting Strength)';

  @override
  String get description =>
      'Sube peso cada sesión exitosa. 3 fallos = deload 10%. Ideal novatos.';

  @override
  ProgressionDecision calculate({
    required ExecutionData data,
    required ControllerState currentState,
    required ProgressionThresholds thresholds,
  }) {
    final lastSession = data.lastSession;
    if (lastSession == null) {
      return ProgressionDecision.calibrating(
        weight: data.confirmedWeight,
        reps: data.targetReps,
        sessionNumber: 1,
      );
    }

    final result = lastSession.evaluate();

    // ════════════════════════════════════════════════════════════════════════
    // STALL DETECTION (Rippetoe): 3 fallos al MISMO peso
    // ════════════════════════════════════════════════════════════════════════
    // Calcular fallos al peso actual
    var failuresAtWeight = 0;
    for (final session in data.sessionHistory) {
      if ((session.weight - data.confirmedWeight).abs() > 0.1) break;
      if (!session.isSuccess) failuresAtWeight++;
    }

    // Stall = 3 fallos → DELOAD 10%
    if (failuresAtWeight >= 3 ||
        currentState == ControllerState.plateau ||
        currentState == ControllerState.deloading) {
      final deloadAmount = data.confirmedWeight * 0.10; // 10% deload (Rippetoe)
      final newWeight = (data.confirmedWeight - deloadAmount)
          .clamp(0, double.infinity)
          .toDouble();
      return ProgressionDecision(
        action: ProgressionAction.decreaseWeight,
        suggestedWeight: newWeight,
        suggestedReps: data.targetReps,
        reason: 'Stall: 3 fallos → deload 10% (Rippetoe)',
        userMessage: 'Deload a ${_fmt(newWeight)}kg y vuelve a subir.',
        confidence: ProgressionConfidence.high,
        nextStepPreview:
            'Volverás a ${_fmt(data.confirmedWeight)}kg en ~3 semanas',
      );
    }

    // ════════════════════════════════════════════════════════════════════════
    // SESIÓN COMPLETA: Subir peso INMEDIATAMENTE (Rippetoe/StrongLifts)
    // ════════════════════════════════════════════════════════════════════════
    // "Add weight every workout" - NO hay confirmación de 2 sesiones
    if (result == SessionResult.complete) {
      final newWeight = data.confirmedWeight + data.increment;
      return ProgressionDecision(
        action: ProgressionAction.increaseWeight,
        suggestedWeight: newWeight,
        suggestedReps: data.targetReps,
        reason: 'Sesión completa → +peso (Rippetoe)',
        userMessage: '¡Sube a ${_fmt(newWeight)}kg!',
        confidence: ProgressionConfidence.high,
        isImprovement: true,
        nextStepPreview: 'Si éxito: ${_fmt(newWeight + data.increment)}kg',
      );
    }

    // Sesión aceptable: Repetir antes de subir
    if (result == SessionResult.acceptable) {
      return ProgressionDecision(
        action: ProgressionAction.maintain,
        suggestedWeight: data.confirmedWeight,
        suggestedReps: data.targetReps,
        reason: 'Casi completa, repetir',
        userMessage: 'Repite ${_fmt(data.confirmedWeight)}kg. Casi lo tienes.',
        nextStepPreview: 'Si completas todas: +${_fmt(data.increment)}kg',
      );
    }

    // Sesión fallida: Mantener y contar hacia stall
    return ProgressionDecision(
      action: ProgressionAction.maintain,
      suggestedWeight: data.confirmedWeight,
      suggestedReps: data.targetReps,
      reason: 'Fallo ${failuresAtWeight + 1}/3, reintentar',
      userMessage:
          'Repite ${_fmt(data.confirmedWeight)}kg. Fallo ${failuresAtWeight + 1}/3.',
      nextStepPreview: failuresAtWeight >= 1
          ? 'Si fallas de nuevo: deload 10%'
          : 'Si fallas 2 más: deload',
    );
  }

  @override
  ControllerState? shouldTransition({
    required ExecutionData data,
    required ControllerState currentState,
    required ProgressionThresholds thresholds,
  }) {
    // Ver reglas de transición más abajo
    return null; // Delegado al controller
  }

  String _fmt(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
}

/// Modelo: Doble Progresión (Lyle McDonald)
///
/// Reglas según Lyle McDonald:
/// - Rango de reps (ej: 8-12)
/// - Sube reps hasta que TODAS las series alcanzan max (no promedio)
/// - Cuando TODAS las series en max → subir peso
/// - Al subir peso, volver al mínimo del rango
///
/// "Once you can complete ALL sets at the top of the rep range,
/// add weight and drop back to the bottom."
/// — Lyle McDonald
class DoubleProgressionModel implements ProgressionModel {
  const DoubleProgressionModel();

  @override
  String get name => 'Doble Progresión (Lyle)';

  @override
  String get description =>
      'Sube reps hasta max en TODAS las series, luego sube peso. Ideal hipertrofia.';

  @override
  ProgressionDecision calculate({
    required ExecutionData data,
    required ControllerState currentState,
    required ProgressionThresholds thresholds,
  }) {
    final lastSession = data.lastSession;
    if (lastSession == null) {
      return ProgressionDecision.calibrating(
        weight: data.confirmedWeight,
        reps: data.targetReps,
        sessionNumber: 1,
      );
    }

    final result = lastSession.evaluate();
    final avgReps = lastSession.averageReps;
    final (minReps, maxReps) = data.repsRange;

    // Verificar si TODAS las series alcanzaron max reps (criterio Lyle)
    final allSetsAtMax = lastSession.sets.every((s) => s.reps >= maxReps);

    // ════════════════════════════════════════════════════════════════════════
    // STALL/DELOAD: 2 fallos al mismo peso → deload 10%
    // ════════════════════════════════════════════════════════════════════════
    var failuresAtWeight = 0;
    for (final session in data.sessionHistory) {
      if ((session.weight - data.confirmedWeight).abs() > 0.1) break;
      if (!session.isSuccess) failuresAtWeight++;
    }

    if (failuresAtWeight >= 2 ||
        currentState == ControllerState.plateau ||
        currentState == ControllerState.deloading) {
      final deloadAmount = data.confirmedWeight * 0.10; // 10% deload
      final newWeight = (data.confirmedWeight - deloadAmount)
          .clamp(0, double.infinity)
          .toDouble();
      return ProgressionDecision(
        action: ProgressionAction.decreaseWeight,
        suggestedWeight: newWeight,
        suggestedReps: maxReps,
        reason: 'Deload 10% (Lyle McDonald)',
        userMessage:
            'Deload a ${_fmt(newWeight)}kg × $maxReps. Reconstruir desde ahí.',
        confidence: ProgressionConfidence.high,
        nextStepPreview:
            'Objetivo: volver a ${_fmt(data.confirmedWeight)}kg en ~3 semanas',
      );
    }

    // ════════════════════════════════════════════════════════════════════════
    // TODAS las series en MAX REPS: SUBIR PESO (Lyle McDonald)
    // ════════════════════════════════════════════════════════════════════════
    // "Once you can complete ALL sets at the top of the rep range, add weight"
    if (allSetsAtMax) {
      final newWeight = data.confirmedWeight + data.increment;
      return ProgressionDecision(
        action: ProgressionAction.increaseWeight,
        suggestedWeight: newWeight,
        suggestedReps: minReps,
        reason: 'Todas las series a $maxReps reps (Lyle)',
        userMessage: '¡Sube a ${_fmt(newWeight)}kg! Empieza con $minReps reps.',
        confidence: ProgressionConfidence.high,
        isImprovement: true,
        nextStepPreview: 'Próximo: ${_fmt(newWeight)}kg × ${minReps + 1}',
      );
    }

    // ════════════════════════════════════════════════════════════════════════
    // Sesión exitosa pero NO todas en max → subir reps
    // ════════════════════════════════════════════════════════════════════════
    if (result == SessionResult.complete ||
        result == SessionResult.acceptable) {
      // Usar el mínimo de reps de la sesión + 1 para progresión gradual
      final minRepsInSession = lastSession.sets
          .map((s) => s.reps)
          .reduce((a, b) => a < b ? a : b);
      final nextReps = (minRepsInSession + 1).clamp(minReps, maxReps);

      // Si promedio alto pero alguna serie falló, mantener objetivo
      if (avgReps >= maxReps - 0.5 && !allSetsAtMax) {
        return ProgressionDecision(
          action: ProgressionAction.maintain,
          suggestedWeight: data.confirmedWeight,
          suggestedReps: maxReps,
          reason: 'Casi todas en max, consolidar',
          userMessage: 'Intenta $maxReps reps en TODAS las series.',
          confidence: ProgressionConfidence.high,
          nextStepPreview:
              'Si todas a $maxReps: subir a ${_fmt(data.confirmedWeight + data.increment)}kg',
        );
      }

      return ProgressionDecision(
        action: ProgressionAction.increaseReps,
        suggestedWeight: data.confirmedWeight,
        suggestedReps: nextReps,
        reason: 'Progresando en reps',
        userMessage: 'Intenta $nextReps reps hoy.',
        confidence: ProgressionConfidence.high,
        isImprovement: true,
        nextStepPreview: nextReps >= maxReps
            ? 'Si todas a $maxReps: subir peso'
            : 'Siguiente: ${nextReps + 1} reps',
      );
    }

    // ════════════════════════════════════════════════════════════════════════
    // Sesión fallida: Mantener y contar hacia deload
    // ════════════════════════════════════════════════════════════════════════
    return ProgressionDecision(
      action: ProgressionAction.maintain,
      suggestedWeight: data.confirmedWeight,
      suggestedReps: data.targetReps,
      reason: 'Día difícil, mantener',
      userMessage: 'Repite el objetivo. Un día malo no cambia nada.',
    );
  }

  @override
  ControllerState? shouldTransition({
    required ExecutionData data,
    required ControllerState currentState,
    required ProgressionThresholds thresholds,
  }) => null;

  String _fmt(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
}

/// Modelo: RPE/RIR (Autorregulación - Mike Tuchscherer/RTS)
///
/// Escala RPE:
/// - RPE 10 = fallo muscular, 0 reps en reserva (RIR)
/// - RPE 9 = 1 RIR (podrías hacer 1 más)
/// - RPE 8 = 2 RIR (podrías hacer 2 más)
/// - RPE 7 = 3 RIR (podrías hacer 3 más)
///
/// Reglas:
/// - RPE < 7 → peso muy ligero, subir
/// - RPE 7-9 → zona óptima, mantener
/// - RPE > 9 consistente → fatiga, considerar deload
class RpeProgressionModel implements ProgressionModel {
  const RpeProgressionModel();

  @override
  String get name => 'RPE/RIR (Autoregulación)';

  @override
  String get description =>
      'Ajusta según esfuerzo percibido. RPE 8 = 2 reps en reserva. Ideal avanzados.';

  @override
  ProgressionDecision calculate({
    required ExecutionData data,
    required ControllerState currentState,
    required ProgressionThresholds thresholds,
  }) {
    final lastSession = data.lastSession;
    if (lastSession == null) {
      return ProgressionDecision.calibrating(
        weight: data.confirmedWeight,
        reps: data.targetReps,
        sessionNumber: 1,
      );
    }

    final avgRpe = lastSession.averageRpe;

    // Sin datos RPE → fallback a mantener
    if (avgRpe == null) {
      return ProgressionDecision(
        action: ProgressionAction.maintain,
        suggestedWeight: data.confirmedWeight,
        suggestedReps: data.targetReps,
        reason: 'Sin datos RPE',
        userMessage: 'Registra RPE para sugerencias automáticas.',
        confidence: ProgressionConfidence.low,
      );
    }

    // Fatiga detectada
    if (currentState == ControllerState.fatigued) {
      final newWeight = data.confirmedWeight - data.increment;
      return ProgressionDecision(
        action: ProgressionAction.decreaseWeight,
        suggestedWeight: newWeight.clamp(0, double.infinity).toDouble(),
        suggestedReps: data.targetReps,
        reason: 'Fatiga: RPE consistentemente alto',
        userMessage: 'RPE alto. Baja a ${_fmt(newWeight)}kg para recuperar.',
        confidence: ProgressionConfidence.high,
      );
    }

    // RPE muy bajo → subir peso
    if (avgRpe < 7) {
      final newWeight = data.confirmedWeight + data.increment;
      return ProgressionDecision(
        action: ProgressionAction.increaseWeight,
        suggestedWeight: newWeight,
        suggestedReps: data.targetReps,
        reason: 'RPE ${avgRpe.toStringAsFixed(1)} < 7',
        userMessage: 'RPE bajo. Sube a ${_fmt(newWeight)}kg.',
        confidence: ProgressionConfidence.high,
        isImprovement: true,
      );
    }

    // RPE en rango óptimo (7-9)
    if (avgRpe >= 7 && avgRpe <= 9) {
      return ProgressionDecision(
        action: ProgressionAction.maintain,
        suggestedWeight: data.confirmedWeight,
        suggestedReps: data.targetReps,
        reason: 'RPE ${avgRpe.toStringAsFixed(1)} en zona óptima',
        userMessage: 'RPE ${avgRpe.toStringAsFixed(1)} perfecto. Mantén.',
        confidence: ProgressionConfidence.high,
      );
    }

    // RPE muy alto (> 9)
    if (data.consecutiveFailures >= 1 || (data.averageRpe ?? 0) > 9) {
      final newWeight = data.confirmedWeight - data.increment;
      return ProgressionDecision(
        action: ProgressionAction.decreaseWeight,
        suggestedWeight: newWeight.clamp(0, double.infinity).toDouble(),
        suggestedReps: data.targetReps,
        reason: 'RPE ${avgRpe.toStringAsFixed(1)} > 9',
        userMessage: 'RPE muy alto. Baja a ${_fmt(newWeight)}kg.',
        confidence: ProgressionConfidence.high,
      );
    }

    // RPE alto pero solo 1 sesión → observar
    return ProgressionDecision(
      action: ProgressionAction.maintain,
      suggestedWeight: data.confirmedWeight,
      suggestedReps: data.targetReps,
      reason: 'RPE ${avgRpe.toStringAsFixed(1)} alto (1 sesión)',
      userMessage: 'RPE alto hoy. Repite para evaluar.',
    );
  }

  @override
  ControllerState? shouldTransition({
    required ExecutionData data,
    required ControllerState currentState,
    required ProgressionThresholds thresholds,
  }) {
    // Detectar fatiga
    final avgRpe = data.averageRpe;
    if (avgRpe != null && avgRpe >= thresholds.fatigueRpeThreshold) {
      if (currentState != ControllerState.fatigued) {
        return ControllerState.fatigued;
      }
    }
    return null;
  }

  String _fmt(double w) =>
      w == w.roundToDouble() ? w.toInt().toString() : w.toStringAsFixed(1);
}

// ════════════════════════════════════════════════════════════════════════════
// CAPA 3: CONTROLADOR CENTRAL (MÁQUINA DE ESTADOS)
// ════════════════════════════════════════════════════════════════════════════

/// Controlador central de progresión
///
/// Responsabilidades:
/// 1. Mantener estado actual
/// 2. Aplicar reglas de transición
/// 3. Delegar cálculo al modelo activo
/// 4. Comunicar cambios al usuario
class ProgressionController {
  /// Estado actual
  ControllerState _state;

  /// Modelo de progresión activo
  ProgressionModel _model;

  /// Umbrales configurados
  ProgressionThresholds _thresholds;

  /// Historial de transiciones (para debug/explicación)
  final List<TransitionRecord> _transitionHistory = [];

  ProgressionController({
    ControllerState initialState = ControllerState.calibrating,
    ProgressionModel? model,
    ProgressionThresholds? thresholds,
  }) : _state = initialState,
       _model = model ?? const DoubleProgressionModel(),
       _thresholds = thresholds ?? ProgressionThresholds.defaults;

  // ─────────────────────────────────────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────────────────────────────────────

  ControllerState get state => _state;
  ProgressionModel get model => _model;
  ProgressionThresholds get thresholds => _thresholds;
  List<TransitionRecord> get transitionHistory =>
      List.unmodifiable(_transitionHistory);

  // ─────────────────────────────────────────────────────────────────────────
  // CONFIGURACIÓN
  // ─────────────────────────────────────────────────────────────────────────

  /// Cambia el modelo de progresión
  void setModel(ProgressionModel newModel) {
    _model = newModel;
  }

  /// Cambia los umbrales
  void setThresholds(ProgressionThresholds newThresholds) {
    _thresholds = newThresholds;
  }

  /// Fuerza un estado (para testing/override manual)
  void forceState(ControllerState newState, {String? reason}) {
    final oldState = _state;
    _state = newState;
    _recordTransition(oldState, newState, reason ?? 'Forzado manualmente');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CÁLCULO PRINCIPAL
  // ─────────────────────────────────────────────────────────────────────────

  /// Calcula la decisión de progresión
  ProgressionDecision calculate(ExecutionData data) {
    // 1. Evaluar transiciones de estado
    _evaluateTransitions(data);

    // 2. Delegar al modelo
    final decision = _model.calculate(
      data: data,
      currentState: _state,
      thresholds: _thresholds,
    );

    return decision;
  }

  /// Evalúa y aplica transiciones de estado
  void _evaluateTransitions(ExecutionData data) {
    final newState = _determineState(data);
    if (newState != _state) {
      final oldState = _state;
      _state = newState;
      _recordTransition(
        oldState,
        newState,
        _getTransitionReason(oldState, newState, data),
      );
    }
  }

  /// Determina el estado correcto basado en datos
  ControllerState _determineState(ExecutionData data) {
    // Calibración: menos de 2 sesiones
    if (!data.hasEnoughData) {
      return ControllerState.calibrating;
    }

    // Dejar que el modelo sugiera transición
    final modelSuggestion = _model.shouldTransition(
      data: data,
      currentState: _state,
      thresholds: _thresholds,
    );
    if (modelSuggestion != null) {
      return modelSuggestion;
    }

    // Reglas globales de transición

    // Estancamiento: N fracasos consecutivos
    if (data.consecutiveFailures >= _thresholds.plateauThreshold) {
      if (_state != ControllerState.deloading) {
        return ControllerState.plateau;
      }
    }

    // Fatiga: RPE consistentemente alto
    final avgRpe = data.averageRpe;
    if (avgRpe != null && avgRpe >= _thresholds.fatigueRpeThreshold) {
      return ControllerState.fatigued;
    }

    // Demasiado tiempo en mismo peso
    if (data.weeksAtCurrentWeight >= _thresholds.maxWeeksAtWeight) {
      return ControllerState.plateau;
    }

    // Confirmando: 1 éxito, esperando 2do
    if (_state == ControllerState.progressing &&
        data.consecutiveSuccesses == 1 &&
        _thresholds.confirmationSessions > 1) {
      return ControllerState.confirming;
    }

    // Éxito confirmado → volver a progressing
    if (_state == ControllerState.confirming &&
        data.consecutiveSuccesses >= _thresholds.confirmationSessions) {
      return ControllerState.progressing;
    }

    // Fracaso en confirmación → volver a progressing
    if (_state == ControllerState.confirming && data.consecutiveFailures > 0) {
      return ControllerState.progressing;
    }

    // Saliendo de deload
    if (_state == ControllerState.deloading && data.consecutiveSuccesses >= 1) {
      return ControllerState.progressing;
    }

    // Plateau → deload
    if (_state == ControllerState.plateau) {
      return ControllerState.deloading;
    }

    // Default: progressing
    if (_state == ControllerState.calibrating && data.hasEnoughData) {
      return ControllerState.progressing;
    }

    return _state;
  }

  String _getTransitionReason(
    ControllerState from,
    ControllerState to,
    ExecutionData data,
  ) {
    return switch ((from, to)) {
      (ControllerState.calibrating, ControllerState.progressing) =>
        '2 sesiones completadas',
      (ControllerState.progressing, ControllerState.confirming) =>
        '1 éxito, esperando confirmación',
      (ControllerState.confirming, ControllerState.progressing) =>
        'Confirmado o fracaso',
      (ControllerState.progressing, ControllerState.plateau) =>
        '${data.consecutiveFailures} fracasos consecutivos',
      (ControllerState.plateau, ControllerState.deloading) =>
        'Iniciando deload',
      (ControllerState.deloading, ControllerState.progressing) =>
        'Deload completado',
      (_, ControllerState.fatigued) =>
        'RPE promedio ≥${_thresholds.fatigueRpeThreshold}',
      _ => 'Transición automática',
    };
  }

  void _recordTransition(
    ControllerState from,
    ControllerState to,
    String reason,
  ) {
    _transitionHistory.add(
      TransitionRecord(
        timestamp: DateTime.now(),
        from: from,
        to: to,
        reason: reason,
      ),
    );

    // Mantener solo últimas 20 transiciones
    if (_transitionHistory.length > 20) {
      _transitionHistory.removeAt(0);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // REGLAS DE TRANSICIÓN (EXPLÍCITAS)
  // ─────────────────────────────────────────────────────────────────────────

  /// Obtiene todas las reglas de transición (para documentación/UI)
  static List<TransitionRule> get allTransitionRules => [
    const TransitionRule(
      from: ControllerState.calibrating,
      to: ControllerState.progressing,
      condition: 'sessionHistory.length >= 2',
      userExplanation:
          'Después de 2 sesiones, el sistema tiene datos suficientes.',
    ),
    const TransitionRule(
      from: ControllerState.progressing,
      to: ControllerState.confirming,
      condition: 'consecutiveSuccesses == 1 && confirmationSessions > 1',
      userExplanation: '1 sesión exitosa. Repite para confirmar subida.',
    ),
    const TransitionRule(
      from: ControllerState.confirming,
      to: ControllerState.progressing,
      condition: 'consecutiveSuccesses >= confirmationSessions',
      userExplanation: 'Confirmado. Subes peso y vuelves a progresión normal.',
    ),
    const TransitionRule(
      from: ControllerState.confirming,
      to: ControllerState.progressing,
      condition: 'consecutiveFailures > 0',
      userExplanation: 'Confirmación fallida. Vuelves a intentar.',
    ),
    const TransitionRule(
      from: ControllerState.progressing,
      to: ControllerState.plateau,
      condition: 'consecutiveFailures >= plateauThreshold',
      userExplanation: 'Varias sesiones difíciles. Considera un deload.',
    ),
    const TransitionRule(
      from: ControllerState.plateau,
      to: ControllerState.deloading,
      condition: 'automático',
      userExplanation: 'Iniciando fase de deload para recuperar.',
    ),
    const TransitionRule(
      from: ControllerState.deloading,
      to: ControllerState.progressing,
      condition: 'consecutiveSuccesses >= 1',
      userExplanation: 'Deload completado. Vuelves a progresar.',
    ),
    const TransitionRule(
      from: ControllerState.progressing,
      to: ControllerState.fatigued,
      condition: 'averageRpe >= fatigueRpeThreshold',
      userExplanation: 'RPE consistentemente alto. Necesitas recuperar.',
    ),
  ];
}

/// Registro de una transición de estado
class TransitionRecord {
  final DateTime timestamp;
  final ControllerState from;
  final ControllerState to;
  final String reason;

  const TransitionRecord({
    required this.timestamp,
    required this.from,
    required this.to,
    required this.reason,
  });

  @override
  String toString() => '${from.emoji} → ${to.emoji}: $reason';
}

// ════════════════════════════════════════════════════════════════════════════
// FACTORY: CREAR MODELO DESDE TIPO
// ════════════════════════════════════════════════════════════════════════════

/// Crea el modelo de progresión apropiado
ProgressionModel createProgressionModel(ProgressionType type) {
  return switch (type) {
    ProgressionType.lineal => const LinearProgressionModel(),
    ProgressionType.dobleRepsFirst => const DoubleProgressionModel(),
    ProgressionType.rpe => const RpeProgressionModel(),
    ProgressionType.none => const LinearProgressionModel(), // fallback
  };
}
