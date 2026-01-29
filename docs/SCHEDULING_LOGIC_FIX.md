# SCHEDULING_LOGIC_FIX.md - Solución al Problema del "Día X Flotante"

> **Problema central**: El sistema usa "Día 1, Día 2, Día 3" sin anchor temporal, causando confusión y carga cognitiva.

---

## Diagnóstico del Sistema Actual

### Código Actual: `smartSuggestionProvider`
**Ubicación**: `lib/training/providers/training_provider.dart:826-905`

```dart
// Lógica actual (simplificada)
final smartSuggestionProvider = FutureProvider<SmartWorkoutSuggestion?>((ref) async {
  // 1. Buscar última sesión
  final lastSession = sessions.firstWhere((s) => s.rutinaId == rutina.id);

  // 2. Calcular siguiente día con rotación circular
  final lastDayIndex = lastSession.dayIndex ?? -1;
  final totalDays = rutina.dias.length;
  var nextDayIndex = (lastDayIndex + 1) % totalDays;  // ← PROBLEMA AQUÍ

  // 3. Saltar días vacíos
  while (rutina.dias[nextDayIndex].ejercicios.isEmpty) {
    nextDayIndex = (nextDayIndex + 1) % totalDays;
  }

  return SmartWorkoutSuggestion(
    rutina: rutina,
    dayIndex: nextDayIndex,
    dayName: rutina.dias[nextDayIndex].nombre,
    reason: 'Siguiente día en tu rutina',  // ← RAZÓN GENÉRICA
  );
});
```

### Limitaciones Identificadas

| Limitación | Impacto | Persona Afectada |
|------------|---------|------------------|
| No considera tiempo transcurrido | Sugiere entrenar aunque fue ayer | Todos |
| No soporta días fijos de semana | No puede decir "Lunes=Pecho" | Planificador Estructurado |
| No soporta ciclos A/B alternos | No detecta Upper/Lower pattern | Flexible A/B |
| No maneja días saltados | No recupera tras vacaciones | Todos |
| No sugiere descanso | Nunca dice "Hoy descansa" | Novatos |

---

## Propuesta de Arquitectura: Sistema de Scheduling Híbrido

### Tres Modos de Programación

```dart
enum SchedulingMode {
  /// Modo actual: Día 1 → Día 2 → Día 3 → Día 1...
  /// Sin consideración de fechas ni tiempo
  sequential,

  /// Nuevo: Asigna días específicos de la semana
  /// Lunes=Pecho, Miércoles=Espalda, Viernes=Pierna
  weeklyAnchored,

  /// Nuevo: Basado en tiempo desde último entrenamiento
  /// "Upper cada 48h, Lower cada 48h, alternando"
  floatingCycle,
}
```

---

## Modo 1: Sequential (Actual, Mejorado)

### Mejoras Propuestas

```dart
class ImprovedSequentialScheduler {
  SmartWorkoutSuggestion? suggest({
    required Rutina rutina,
    required List<Sesion> history,
  }) {
    final lastSession = _findLastSessionOfRoutine(history, rutina.id);

    if (lastSession == null) {
      // Primera vez: empezar por Día 1
      return SmartWorkoutSuggestion(
        rutina: rutina,
        dayIndex: 0,
        dayName: rutina.dias[0].nombre,
        reason: '¡Comienza tu rutina!',
        timeSinceLastSession: null,
      );
    }

    // MEJORA 1: Calcular tiempo transcurrido
    final daysSinceLastSession = DateTime.now()
        .difference(lastSession.fecha)
        .inDays;

    // MEJORA 2: Si fue hace menos de 24h, sugerir descanso
    final hoursSinceLastSession = DateTime.now()
        .difference(lastSession.fecha)
        .inHours;

    if (hoursSinceLastSession < 20) {
      return SmartWorkoutSuggestion(
        rutina: rutina,
        dayIndex: -1,  // Indica descanso
        dayName: 'Descanso',
        reason: 'Entrenaste hace ${hoursSinceLastSession}h. Recupera.',
        isRestDay: true,
        nextWorkout: _getNextDay(rutina, lastSession.dayIndex),
      );
    }

    // Siguiente día en rotación
    final nextDayIndex = ((lastSession.dayIndex ?? -1) + 1) % rutina.dias.length;
    final nextDay = rutina.dias[nextDayIndex];

    // MEJORA 3: Mostrar contexto temporal
    return SmartWorkoutSuggestion(
      rutina: rutina,
      dayIndex: nextDayIndex,
      dayName: nextDay.nombre,
      reason: _buildContextualReason(daysSinceLastSession, lastSession),
      timeSinceLastSession: Duration(days: daysSinceLastSession),
      lastSessionDate: lastSession.fecha,
    );
  }

  String _buildContextualReason(int days, Sesion lastSession) {
    if (days == 0) return 'Continúa donde lo dejaste';
    if (days == 1) return 'Siguiente día de tu rutina';
    if (days == 2) return 'Han pasado 2 días. ¡A por ello!';
    if (days <= 7) return 'Última sesión hace $days días';
    return 'Retoma tu rutina (${days} días sin entrenar)';
  }
}
```

---

## Modo 2: Weekly Anchored (Nuevo)

### Modelo de Datos

```dart
/// Extiende el modelo Dia para soportar asignación semanal
class DiaConAnchor extends Dia {
  /// Días de la semana asignados (1=Lunes, 7=Domingo)
  /// Puede ser múltiple: [1, 4] = Lunes y Jueves
  final List<int>? weekdays;

  /// Hora preferida de entrenamiento (opcional)
  final TimeOfDay? preferredTime;

  DiaConAnchor({
    required super.nombre,
    required super.ejercicios,
    this.weekdays,
    this.preferredTime,
  });
}
```

### Lógica de Sugerencia

```dart
class WeeklyAnchoredScheduler {
  SmartWorkoutSuggestion? suggest({
    required Rutina rutina,
    required List<Sesion> history,
    required DateTime now,
  }) {
    final today = now.weekday; // 1=Lunes ... 7=Domingo

    // Buscar día asignado a hoy
    final todaysWorkout = rutina.dias.firstWhereOrNull(
      (dia) => dia.weekdays?.contains(today) ?? false,
    );

    if (todaysWorkout != null) {
      // Verificar si ya entrenó hoy
      final alreadyTrainedToday = history.any(
        (s) => _isSameDay(s.fecha, now) && s.dayName == todaysWorkout.nombre,
      );

      if (alreadyTrainedToday) {
        return SmartWorkoutSuggestion(
          dayName: 'Completado',
          reason: 'Ya entrenaste ${todaysWorkout.nombre} hoy',
          isCompleted: true,
        );
      }

      return SmartWorkoutSuggestion(
        rutina: rutina,
        dayIndex: rutina.dias.indexOf(todaysWorkout),
        dayName: todaysWorkout.nombre,
        reason: 'Hoy es ${_weekdayName(today)}: toca ${todaysWorkout.nombre}',
        isScheduledForToday: true,
      );
    }

    // Hoy no hay entrenamiento asignado → Día de descanso
    final nextWorkout = _findNextScheduledDay(rutina, now);
    return SmartWorkoutSuggestion(
      dayName: 'Descanso',
      reason: 'Próximo: ${nextWorkout.nombre} el ${_weekdayName(nextWorkout.weekday)}',
      isRestDay: true,
      nextScheduledDate: _getNextDate(now, nextWorkout.weekday),
    );
  }
}
```

### UI para Configurar Weekly Anchor

```
┌─────────────────────────────────────────┐
│ CONFIGURAR SEMANA                       │
├─────────────────────────────────────────┤
│                                         │
│ Pecho & Tríceps                         │
│ [L] [M] [X] [J] [V] [S] [D]             │
│  ●       ●                               │  ← Lunes y Miércoles seleccionados
│                                         │
│ Espalda & Bíceps                        │
│ [L] [M] [X] [J] [V] [S] [D]             │
│      ●       ●                           │  ← Martes y Jueves
│                                         │
│ Pierna                                   │
│ [L] [M] [X] [J] [V] [S] [D]             │
│                  ●                       │  ← Viernes
│                                         │
│ Vista Semanal:                          │
│ ┌───┬───┬───┬───┬───┬───┬───┐          │
│ │ L │ M │ X │ J │ V │ S │ D │          │
│ │Pec│Esp│Pec│Esp│Pie│ - │ - │          │
│ └───┴───┴───┴───┴───┴───┴───┘          │
│                                         │
│         [ GUARDAR CONFIGURACIÓN ]       │
└─────────────────────────────────────────┘
```

---

## Modo 3: Floating Cycle (Nuevo)

### Modelo de Datos

```dart
/// Configuración de ciclo flotante (independiente de calendario)
class FloatingCycleConfig {
  /// Horas mínimas de descanso entre sesiones
  final int minRestHours;

  /// Horas máximas antes de sugerir entrenar
  final int maxRestHours;

  /// Si es true, alterna automáticamente entre días
  /// (Upper → Lower → Upper sin importar calendario)
  final bool autoAlternate;

  const FloatingCycleConfig({
    this.minRestHours = 24,
    this.maxRestHours = 72,
    this.autoAlternate = true,
  });
}
```

### Lógica de Sugerencia

```dart
class FloatingCycleScheduler {
  SmartWorkoutSuggestion? suggest({
    required Rutina rutina,
    required List<Sesion> history,
    required FloatingCycleConfig config,
    required DateTime now,
  }) {
    final lastSession = history.firstOrNull;

    if (lastSession == null) {
      return SmartWorkoutSuggestion(
        rutina: rutina,
        dayIndex: 0,
        dayName: rutina.dias[0].nombre,
        reason: '¡Comienza tu ciclo!',
      );
    }

    final hoursSinceLastSession = now.difference(lastSession.fecha).inHours;

    // Demasiado pronto: sugerir descanso
    if (hoursSinceLastSession < config.minRestHours) {
      final hoursUntilReady = config.minRestHours - hoursSinceLastSession;
      return SmartWorkoutSuggestion(
        dayName: 'Recuperando',
        reason: 'Listo para entrenar en ~${hoursUntilReady}h',
        isRestDay: true,
        hoursUntilReady: hoursUntilReady,
      );
    }

    // Siguiente día en ciclo
    final nextDayIndex = ((lastSession.dayIndex ?? -1) + 1) % rutina.dias.length;
    final nextDay = rutina.dias[nextDayIndex];

    // Calcular urgencia basada en tiempo
    String reason;
    SchedulingUrgency urgency;

    if (hoursSinceLastSession > config.maxRestHours) {
      reason = '¡${(hoursSinceLastSession / 24).round()} días sin entrenar!';
      urgency = SchedulingUrgency.high;
    } else if (hoursSinceLastSession > config.minRestHours + 12) {
      reason = 'Recuperado. Ideal para entrenar.';
      urgency = SchedulingUrgency.optimal;
    } else {
      reason = 'Puedes entrenar (${hoursSinceLastSession}h de descanso)';
      urgency = SchedulingUrgency.available;
    }

    return SmartWorkoutSuggestion(
      rutina: rutina,
      dayIndex: nextDayIndex,
      dayName: nextDay.nombre,
      reason: reason,
      urgency: urgency,
      hoursSinceLastSession: hoursSinceLastSession,
    );
  }
}

enum SchedulingUrgency {
  /// Menos de minRestHours, no debería entrenar
  rest,
  /// Entre minRestHours y optimal, puede entrenar
  available,
  /// Zona óptima de recuperación
  optimal,
  /// Más de maxRestHours, urgente entrenar
  high,
}
```

### Visualización de Ciclo Flotante

```
┌─────────────────────────────────────────┐
│ CICLO FLOTANTE                          │
├─────────────────────────────────────────┤
│                                         │
│ Timeline de las últimas 2 semanas:      │
│                                         │
│  L   M   X   J   V   S   D   L   M  HOY │
│  ─   ●   ─   ●   ─   ─   ●   ─   ●   ?  │
│     Upp     Low         Upp     Low     │
│                                         │
│ Patrón detectado: Upper/Lower alterno   │
│ Frecuencia: ~48h entre sesiones         │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │  ⏱️ Última sesión: Martes (48h)    │ │
│ │  📊 Estado: ÓPTIMO para entrenar   │ │
│ │  💪 Siguiente: UPPER               │ │
│ └─────────────────────────────────────┘ │
│                                         │
│        [ ENTRENAR UPPER AHORA ]         │
└─────────────────────────────────────────┘
```

---

## Flujo de "Missed Day Recovery"

### Escenario: Usuario no entrenó 5 días

```dart
class MissedDayRecoveryHandler {
  RecoveryOptions suggestRecovery({
    required Rutina rutina,
    required Sesion lastSession,
    required int daysMissed,
  }) {
    if (daysMissed <= 2) {
      // Gap pequeño: continuar donde estaba
      return RecoveryOptions(
        primary: RecoveryAction.continueSequence,
        message: 'Continúa con ${_getNextDay(rutina, lastSession.dayIndex)}',
      );
    }

    if (daysMissed <= 7) {
      // Gap mediano: ofrecer opciones
      return RecoveryOptions(
        primary: RecoveryAction.continueSequence,
        alternatives: [
          RecoveryAction.restartWeek,
          RecoveryAction.skipToFavorite,
        ],
        message: 'Han pasado $daysMissed días. ¿Cómo quieres continuar?',
      );
    }

    // Gap grande: reiniciar ciclo
    return RecoveryOptions(
      primary: RecoveryAction.restartCycle,
      alternatives: [
        RecoveryAction.continueSequence,
        RecoveryAction.customSelection,
      ],
      message: 'Llevas $daysMissed días sin entrenar. Te sugiero reiniciar.',
    );
  }
}

enum RecoveryAction {
  /// Continuar donde estaba (Día 3 si estaba en Día 2)
  continueSequence,

  /// Reiniciar la semana (volver a Día 1)
  restartWeek,

  /// Reiniciar todo el ciclo (si es periodización)
  restartCycle,

  /// Ir a su ejercicio favorito (engagement)
  skipToFavorite,

  /// Elegir manualmente
  customSelection,
}
```

### UI de Missed Day Recovery

```
┌─────────────────────────────────────────┐
│ 🔄 RETOMA TU RUTINA                     │
├─────────────────────────────────────────┤
│                                         │
│ Llevas 5 días sin entrenar.             │
│ Tu última sesión fue: Pierna (Domingo)  │
│                                         │
│ ¿Cómo quieres continuar?                │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ ▶ CONTINUAR SECUENCIA              │ │
│ │   Siguiente: Pecho & Tríceps       │ │
│ │   (Recomendado)                    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │   REINICIAR SEMANA                 │ │
│ │   Empezar desde Día 1              │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │   ELEGIR MANUALMENTE               │ │
│ │   Ver todos los días               │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## Migración de Datos

### Compatibilidad con Rutinas Existentes

```dart
/// Migra una Rutina existente al nuevo sistema
extension RutinaMigration on Rutina {
  /// Infiere el modo de scheduling basado en nombres de días
  SchedulingMode inferSchedulingMode() {
    // Si los días se llaman "Lunes", "Martes", etc. → Weekly
    final weekdayPattern = RegExp(r'^(lunes|martes|miércoles|jueves|viernes|sábado|domingo)$', caseSensitive: false);
    if (dias.every((d) => weekdayPattern.hasMatch(d.nombre))) {
      return SchedulingMode.weeklyAnchored;
    }

    // Si se llaman "Upper", "Lower" o "A", "B" → Floating
    final abPattern = RegExp(r'^(upper|lower|push|pull|a|b)$', caseSensitive: false);
    if (dias.every((d) => abPattern.hasMatch(d.nombre))) {
      return SchedulingMode.floatingCycle;
    }

    // Default: Sequential
    return SchedulingMode.sequential;
  }

  /// Intenta asignar weekdays basado en historial
  List<int>? inferWeekdaysFromHistory(List<Sesion> history, Dia dia) {
    final sessionsOfDay = history.where((s) => s.dayName == dia.nombre);
    if (sessionsOfDay.length < 3) return null;  // No suficiente data

    // Contar frecuencia de días de la semana
    final weekdayCounts = <int, int>{};
    for (final session in sessionsOfDay) {
      final wd = session.fecha.weekday;
      weekdayCounts[wd] = (weekdayCounts[wd] ?? 0) + 1;
    }

    // Si un día aparece >60% de las veces, es probable que sea fijo
    final total = sessionsOfDay.length;
    return weekdayCounts.entries
        .where((e) => e.value / total > 0.6)
        .map((e) => e.key)
        .toList();
  }
}
```

---

## Persistencia

### Extensión de Modelo en Base de Datos

```sql
-- Nueva columna en tabla Routines
ALTER TABLE Routines ADD COLUMN scheduling_mode TEXT DEFAULT 'sequential';
ALTER TABLE Routines ADD COLUMN scheduling_config TEXT;  -- JSON

-- Nueva columna en tabla RoutineDays
ALTER TABLE RoutineDays ADD COLUMN weekdays TEXT;  -- JSON array: [1,3,5]
ALTER TABLE RoutineDays ADD COLUMN min_rest_hours INTEGER;
```

### Modelo Drift

```dart
// En database.dart
class Routines extends Table {
  // ... columnas existentes ...

  TextColumn get schedulingMode => text()
      .withDefault(const Constant('sequential'))();

  TextColumn get schedulingConfig => text().nullable()();
}

class RoutineDays extends Table {
  // ... columnas existentes ...

  TextColumn get weekdays => text().nullable()();  // JSON: "[1,3,5]"
  IntColumn get minRestHours => integer().nullable()();
}
```

---

## Resumen de Implementación

### Fase 1: Quick Wins (2-4 horas)
- [ ] Añadir `timeSinceLastSession` a `SmartWorkoutSuggestion`
- [ ] Mejorar `reason` con contexto temporal
- [ ] Mostrar "Última vez: X días" en UI

### Fase 2: Sequential Mejorado (1-2 días)
- [ ] Implementar `ImprovedSequentialScheduler`
- [ ] Detectar y sugerir descanso si entrenó <20h antes
- [ ] Añadir UI de "Missed Day Recovery"

### Fase 3: Weekly Anchored (3-4 días)
- [ ] Extender modelo de datos (Drift migration)
- [ ] Crear `WeeklyAnchoredScheduler`
- [ ] UI para configurar días de la semana
- [ ] Vista de calendario semanal

### Fase 4: Floating Cycle (3-4 días)
- [ ] Implementar `FloatingCycleScheduler`
- [ ] UI de timeline visual
- [ ] Detección automática de patrones
- [ ] Alertas de urgencia

### Fase 5: Unificación (2 días)
- [ ] Provider único con switch de modo
- [ ] Migración automática de rutinas existentes
- [ ] Tests de integración

---

*Documento creado como parte de la auditoría UX - Enero 2026*
