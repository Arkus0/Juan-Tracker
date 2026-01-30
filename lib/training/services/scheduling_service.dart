import 'package:juan_tracker/training/models/rutina.dart';
import 'package:juan_tracker/training/models/sesion.dart';
import 'package:juan_tracker/training/models/dia.dart';

// Importar enums y clases del provider
import 'package:juan_tracker/training/providers/training_provider.dart' show WorkoutUrgency, SmartWorkoutSuggestion;

/// 🎯 FASE 5: Servicio de scheduling mejorado para entrenamientos
/// 
/// Implementa la lógica de ImprovedSequentialScheduler del documento
/// SCHEDULING_LOGIC_FIX.md con soporte para:
/// - Detección de tiempo transcurrido
/// - Sugerencia de descanso si <20h
/// - Detección de gaps (días saltados)
/// - Mensajes contextuales según urgencia
class SchedulingService {
  
  /// Calcula la sugerencia de entrenamiento mejorada
  /// 
  /// Lógica:
  /// 1. Si no hay historial → Primer día de rutina
  /// 2. Si entrenó hace <20h → Día de descanso sugerido
  /// 3. Si entrenó hace 20-48h → LISTO para entrenar
  /// 4. Si entrenó hace 48-72h → DEBERÍA entrenar
  /// 5. Si entrenó hace >72h → URGENTE / Missed Day Recovery
  static SmartWorkoutSuggestion? suggestWorkout({
    required List<Rutina> rutinas,
    required List<Sesion> sessions,
    required DateTime now,
  }) {
    if (rutinas.isEmpty) return null;

    // Buscar rutina más reciente usada
    final lastSessionData = _findLastSession(sessions, rutinas);
    final lastUsedRutina = lastSessionData.$1;
    final lastSession = lastSessionData.$2;

    // Sin historial → Primer día
    if (lastUsedRutina == null || lastSession == null) {
      return _createFirstTimeSuggestion(rutinas.first);
    }

    // Calcular siguiente día válido
    final nextDayInfo = _calculateNextDay(lastUsedRutina, lastSession);
    if (nextDayInfo == null) return null;

    final nextDayIndex = nextDayInfo.$1;
    final nextDay = nextDayInfo.$2;

    // Calcular tiempo transcurrido
    final timeSince = now.difference(lastSession.fecha);
    final hoursSince = timeSince.inHours;
    final daysSince = timeSince.inDays;

    // Determinar estado según tiempo transcurrido
    return _createSuggestionByTime(
      rutina: lastUsedRutina,
      dayIndex: nextDayIndex,
      day: nextDay,
      hoursSince: hoursSince,
      daysSince: daysSince,
      timeSince: timeSince,
      lastSession: lastSession,
    );
  }

  /// Busca la última sesión y su rutina correspondiente
  static (Rutina?, Sesion?) _findLastSession(
    List<Sesion> sessions,
    List<Rutina> rutinas,
  ) {
    for (final session in sessions) {
      try {
        final matchingRutina = rutinas.firstWhere(
          (r) => r.id == session.rutinaId,
        );
        return (matchingRutina, session);
      } catch (_) {
        // Rutina no encontrada, continuar
        continue;
      }
    }
    return (null, null);
  }

  /// Crea sugerencia para primera vez
  static SmartWorkoutSuggestion _createFirstTimeSuggestion(Rutina rutina) {
    final firstValidDayIndex = rutina.dias.indexWhere(
      (d) => d.ejercicios.isNotEmpty,
    );
    
    if (firstValidDayIndex == -1) {
      throw StateError('Rutina sin días con ejercicios');
    }

    final firstDay = rutina.dias[firstValidDayIndex];

    return SmartWorkoutSuggestion(
      rutina: rutina,
      dayIndex: firstValidDayIndex,
      dayName: firstDay.nombre,
      reason: '¡Comienza tu rutina!',
      timeSinceLastSession: null,
      lastSessionDate: null,
      isRestDay: false,
      urgency: WorkoutUrgency.fresh,
      contextualSubtitle: 'El viaje de mil reps empieza con una serie',
    );
  }

  /// Calcula el siguiente día válido (saltando días vacíos)
  static (int, Dia)? _calculateNextDay(Rutina rutina, Sesion lastSession) {
    final lastDayIndex = lastSession.dayIndex ?? -1;
    final totalDays = rutina.dias.length;

    var nextDayIndex = (lastDayIndex + 1) % totalDays;
    var attempts = 0;

    while (rutina.dias[nextDayIndex].ejercicios.isEmpty && attempts < totalDays) {
      nextDayIndex = (nextDayIndex + 1) % totalDays;
      attempts++;
    }

    if (attempts >= totalDays) return null;

    return (nextDayIndex, rutina.dias[nextDayIndex]);
  }

  /// Crea sugerencia basada en tiempo transcurrido
  static SmartWorkoutSuggestion _createSuggestionByTime({
    required Rutina rutina,
    required int dayIndex,
    required Dia day,
    required int hoursSince,
    required int daysSince,
    required Duration timeSince,
    required Sesion lastSession,
  }) {
    // Caso 1: Descanso sugerido (<20h)
    if (hoursSince < 20) {
      return SmartWorkoutSuggestion(
        rutina: rutina,
        dayIndex: -1,
        dayName: 'DESCANSO',
        reason: 'Recuperación activa',
        timeSinceLastSession: timeSince,
        lastSessionDate: lastSession.fecha,
        isRestDay: true,
        urgency: WorkoutUrgency.rest,
        contextualSubtitle: 'Entrenaste hace ${hoursSince}h. Los músculos crecen descansando.',
      );
    }

    // Caso 2: Listo para entrenar (20-48h)
    if (hoursSince < 48) {
      return SmartWorkoutSuggestion(
        rutina: rutina,
        dayIndex: dayIndex,
        dayName: day.nombre,
        reason: daysSince == 0 ? 'Recuperado y listo' : 'Toca ${day.nombre}',
        timeSinceLastSession: timeSince,
        lastSessionDate: lastSession.fecha,
        isRestDay: false,
        urgency: WorkoutUrgency.ready,
        contextualSubtitle: daysSince == 0
            ? 'Entrenaste hoy temprano, ya pasaron ${hoursSince}h'
            : 'Última sesión: ayer',
      );
    }

    // Caso 3: Debería entrenar (48-72h)
    if (hoursSince < 72) {
      return SmartWorkoutSuggestion(
        rutina: rutina,
        dayIndex: dayIndex,
        dayName: day.nombre,
        reason: 'Sigue la racha',
        timeSinceLastSession: timeSince,
        lastSessionDate: lastSession.fecha,
        isRestDay: false,
        urgency: WorkoutUrgency.shouldTrain,
        contextualSubtitle: 'Hace $daysSince días desde tu última sesión',
      );
    }

    // Caso 4: Urgente / Missed Day (>72h)
    return SmartWorkoutSuggestion(
      rutina: rutina,
      dayIndex: dayIndex,
      dayName: day.nombre,
      reason: daysSince <= 7 ? 'Retoma el ritmo' : '¡Vuelve al gym!',
      timeSinceLastSession: timeSince,
      lastSessionDate: lastSession.fecha,
      isRestDay: false,
      urgency: WorkoutUrgency.urgent,
      contextualSubtitle: daysSince <= 7
          ? '$daysSince días sin entrenar. ¡Hoy es el día!'
          : '$daysSince días. El hierro te extraña.',
    );
  }

  /// Detecta si hay un gap significativo que requiera Missed Day Recovery
  static bool needsMissedDayRecovery(SmartWorkoutSuggestion suggestion) {
    if (suggestion.timeSinceLastSession == null) return false;
    return suggestion.timeSinceLastSession!.inDays > 2 && !suggestion.isRestDay;
  }

  /// Genera opciones de recuperación para Missed Day Recovery
  static MissedDayRecoveryOptions generateRecoveryOptions({
    required Rutina rutina,
    required Sesion lastSession,
    required int daysMissed,
  }) {
    final nextDayIndex = ((lastSession.dayIndex ?? -1) + 1) % rutina.dias.length;
    final nextDay = rutina.dias[nextDayIndex];

    if (daysMissed <= 2) {
      // Gap pequeño: continuar donde estaba
      return MissedDayRecoveryOptions(
        primary: RecoveryAction.continueSequence,
        message: 'Continúa con ${nextDay.nombre}',
        suggestedDayIndex: nextDayIndex,
        suggestedDayName: nextDay.nombre,
      );
    }

    if (daysMissed <= 7) {
      // Gap mediano: ofrecer opciones
      return MissedDayRecoveryOptions(
        primary: RecoveryAction.continueSequence,
        alternatives: [RecoveryAction.restartWeek, RecoveryAction.customSelection],
        message: 'Han pasado $daysMissed días. ¿Cómo quieres continuar?',
        suggestedDayIndex: nextDayIndex,
        suggestedDayName: nextDay.nombre,
      );
    }

    // Gap grande: reiniciar sugerido
    return MissedDayRecoveryOptions(
      primary: RecoveryAction.restartCycle,
      alternatives: [RecoveryAction.continueSequence, RecoveryAction.customSelection],
      message: 'Llevas $daysMissed días sin entrenar. Te sugiero reiniciar.',
      suggestedDayIndex: 0,
      suggestedDayName: rutina.dias.first.nombre,
    );
  }
}

/// Opciones de recuperación para Missed Day Recovery
class MissedDayRecoveryOptions {
  final RecoveryAction primary;
  final List<RecoveryAction> alternatives;
  final String message;
  final int suggestedDayIndex;
  final String suggestedDayName;

  const MissedDayRecoveryOptions({
    required this.primary,
    this.alternatives = const [],
    required this.message,
    required this.suggestedDayIndex,
    required this.suggestedDayName,
  });
}

/// Acciones de recuperación disponibles
enum RecoveryAction {
  /// Continuar donde estaba (Día 3 si estaba en Día 2)
  continueSequence,

  /// Reiniciar la semana (volver a Día 1)
  restartWeek,

  /// Reiniciar todo el ciclo
  restartCycle,

  /// Elegir manualmente
  customSelection,
}

/// 🎯 FASE 7: Configuración de scheduling weekly anchored
/// 
/// Permite asignar días específicos de la semana a cada día de rutina
/// Ej: Lunes=Pecho, Miércoles=Espalda, Viernes=Pierna
class WeeklyAnchoredConfig {
  /// Mapa de dayIndex -> lista de weekdays (1=Lunes, 7=Domingo)
  final Map<int, List<int>> dayToWeekdays;
  
  const WeeklyAnchoredConfig({this.dayToWeekdays = const {}});
  
  /// Crea config desde JSON almacenado
  factory WeeklyAnchoredConfig.fromJson(Map<String, dynamic> json) {
    final Map<int, List<int>> mapping = {};
    json.forEach((key, value) {
      mapping[int.parse(key)] = List<int>.from(value);
    });
    return WeeklyAnchoredConfig(dayToWeekdays: mapping);
  }
  
  /// Convierte a JSON para almacenar
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    dayToWeekdays.forEach((key, value) {
      json[key.toString()] = value;
    });
    return json;
  }
  
  /// Obtiene el día de rutina para un weekday específico
  int? getDayForWeekday(int weekday) {
    for (final entry in dayToWeekdays.entries) {
      if (entry.value.contains(weekday)) {
        return entry.key;
      }
    }
    return null;
  }
  
  /// Verifica si hoy tiene entrenamiento asignado
  bool hasWorkoutToday(DateTime date) {
    return getDayForWeekday(date.weekday) != null;
  }
  
  /// Nombre del día de la semana en español
  static String weekdayName(int weekday) {
    const names = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return names[weekday];
  }
}

/// 🎯 FASE 7: Scheduler semanal con anclaje a días de semana
class WeeklyAnchoredScheduler {
  final WeeklyAnchoredConfig config;
  
  const WeeklyAnchoredScheduler(this.config);
  
  /// Sugiere entrenamiento basado en día de la semana actual
  SmartWorkoutSuggestion? suggestWorkout({
    required Rutina rutina,
    required List<Sesion> history,
    required DateTime now,
  }) {
    final today = now.weekday; // 1=Lunes, 7=Domingo
    final dayIndex = config.getDayForWeekday(today);
    
    if (dayIndex == null) {
      // Hoy no hay entrenamiento asignado -> Día de descanso
      final nextWorkoutDay = _findNextWorkoutDay(today);
      return SmartWorkoutSuggestion(
        rutina: rutina,
        dayIndex: -1,
        dayName: 'Descanso',
        reason: 'Hoy es ${WeeklyAnchoredConfig.weekdayName(today)}',
        timeSinceLastSession: _getTimeSinceLastSession(history),
        isRestDay: true,
        urgency: WorkoutUrgency.rest,
        contextualSubtitle: nextWorkoutDay != null
            ? 'Próximo: ${rutina.dias[config.getDayForWeekday(nextWorkoutDay)!].nombre} el ${WeeklyAnchoredConfig.weekdayName(nextWorkoutDay)}'
            : 'Sin entrenamientos programados',
      );
    }
    
    // Verificar si ya entrenó hoy
    final alreadyTrainedToday = history.any(
      (s) => _isSameDay(s.fecha, now) && s.dayIndex == dayIndex,
    );
    
    if (alreadyTrainedToday) {
      return SmartWorkoutSuggestion(
        rutina: rutina,
        dayIndex: dayIndex,
        dayName: rutina.dias[dayIndex].nombre,
        reason: 'Completado hoy',
        timeSinceLastSession: Duration.zero,
        isRestDay: false,
        urgency: WorkoutUrgency.ready,
        contextualSubtitle: '¡Buen trabajo! Descansa mañana',
      );
    }
    
    // Sugerir entrenamiento de hoy
    return SmartWorkoutSuggestion(
      rutina: rutina,
      dayIndex: dayIndex,
      dayName: rutina.dias[dayIndex].nombre,
      reason: 'Hoy es ${WeeklyAnchoredConfig.weekdayName(today)}',
      timeSinceLastSession: _getTimeSinceLastSession(history),
      isRestDay: false,
      urgency: WorkoutUrgency.ready,
      contextualSubtitle: 'Toca ${rutina.dias[dayIndex].nombre}',
    );
  }
  
  int? _findNextWorkoutDay(int fromWeekday) {
    for (int i = 1; i <= 7; i++) {
      final checkDay = ((fromWeekday + i - 1) % 7) + 1;
      if (config.getDayForWeekday(checkDay) != null) {
        return checkDay;
      }
    }
    return null;
  }
  
  Duration? _getTimeSinceLastSession(List<Sesion> history) {
    if (history.isEmpty) return null;
    return DateTime.now().difference(history.first.fecha);
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// WorkoutUrgency y SmartWorkoutSuggestion se importan desde training_provider.dart
