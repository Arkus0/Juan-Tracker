# 🗺️ ROADMAP COMPRENSIVO - Juan Tracker UX/UI Improvements

> **Fecha de creación**: 30 Enero 2026  
> **Última actualización**: 30 Enero 2026  
> **Estado**: Fases 1-6 completadas ✅  
> **Tiempo estimado total**: ~21 días de trabajo efectivo

---

## 📋 ÍNDICE

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Fases Completadas](#fases-completadas)
3. [Calendario de Implementación](#calendario-de-implementación)
4. [Detalle por Fase](#detalle-por-fase)
5. [Dependencias entre Tareas](#dependencias-entre-tareas)
6. [Archivos Clave](#archivos-clave)
7. [Cómo Continuar](#cómo-continuar)

---

## RESUMEN EJECUTIVO

### Problema Original
La app tenía 4 issues CRÍTICOS identificados en la auditoría UX (`UX_HEATMAP.md`):

| Issue | Descripción | Impacto |
|-------|-------------|---------|
| **CRIT-001** | Programación de entrenamiento sin anchor temporal | Abandono semana 2-3 |
| **CRIT-002** | Entry Screen no muestra qué toca entrenar hoy | Confusión diaria |
| **CRIT-003** | Nutrición muestra "consumido" vs "restante" | Carga cognitiva |
| **CRIT-004** | No hay vista unificada "HOY" | Fragmentación UX |

### Solución Propuesta
Implementación incremental en 10 fases, priorizando **quick wins** primero para demostrar valor inmediato.

---

## FASES COMPLETADAS

### ✅ FASE 1: Quick Wins Críticos (~2 horas)
**Fecha**: 30 Enero 2026  
**Estado**: COMPLETADA

| Tarea | Descripción | Archivos | Estado |
|-------|-------------|----------|--------|
| QW-01 | Conectar smartSuggestionProvider a Entry Screen | `entry_screen.dart` | ✅ |
| QW-02 | Invertir consumido→restante en macros | `diary_screen.dart` | ✅ |
| QW-03 | Snackbar consistency (infra ya existía) | `app_snackbar.dart` | ✅ |
| QW-10 | Color contrast fix en macros | `diary_screen.dart` | ✅ |

**Impacto logrado**:
- Entry Screen ahora muestra "Toca PECHO • Últ: hace 3d"
- Macros muestran valores RESTANTES en lugar de consumidos
- Mejor contraste visual en light mode

---

### ✅ FASE 2: Contexto Temporal (~2 horas)
**Fecha**: 30 Enero 2026  
**Estado**: COMPLETADA

| Tarea | Descripción | Archivos | Estado |
|-------|-------------|----------|--------|
| QW-04 | timeSinceFormattedContextual + motivationalMessage | `training_provider.dart` | ✅ |
| QW-09 | Welcome back toast para sesiones reanudadas | `training_session_screen.dart` | ✅ |
| HIGH-004 | Auto-scroll al ejercicio activo | `training_session_screen.dart` | ✅ |

---

### ✅ FASE 3: UI Entry Screen (~3 horas)
**Fecha**: 30 Enero 2026  
**Estado**: COMPLETADA

| Tarea | Descripción | Archivos | Estado |
|-------|-------------|----------|--------|
| QW-05 | Progress ring en Nutrition Card | `entry_screen.dart` | ✅ |
| QW-08 | Thumb zone reorganization | `entry_screen.dart` | ✅ |
| QW-06 | Sugerir nombres semánticos para días | `create_edit_routine_screen.dart` | ✅ |
| QW-07 | Empty state educativo (ya existía) | `diary_screen.dart` | ✅ |

---

### ✅ FASE 4: Today View Básica (~2 días)
**Fecha**: 30 Enero 2026  
**Estado**: COMPLETADA

| Tarea | Descripción | Archivos | Estado |
|-------|-------------|----------|--------|
| todaySummaryProvider | Provider combinado training + nutrition | `today_providers.dart` (nuevo) | ✅ |

---

### ✅ FASE 5: Scheduling Mejorado (~3 días)
**Fecha**: 30 Enero 2026  
**Estado**: COMPLETADA

| Tarea | Descripción | Archivos | Estado |
|-------|-------------|----------|--------|
| SchedulingService | ImprovedSequentialScheduler implementado | `scheduling_service.dart` (nuevo) | ✅ |
| Detección descanso | <20h sugiere descanso | `scheduling_service.dart` | ✅ |
| MissedDayRecovery | Opciones de recuperación para gaps | `scheduling_service.dart` | ✅ |

---

### ✅ FASE 6: Today View Completa (~3 días)
**Fecha**: 30 Enero 2026  
**Estado**: COMPLETADA

| Tarea | Descripción | Archivos | Estado |
|-------|-------------|----------|--------|
| today_screen.dart | Pantalla HOY unificada | `today_screen.dart` (nuevo) | ✅ |
| Lógica contextual | Mensajes según hora del día | `today_screen.dart` | ✅ |
| TrainingTodayCard | Card de entrenamiento con estado visual | `today_screen.dart` | ✅ |
| NutritionTodayCard | Card de nutrición con macros y progreso | `today_screen.dart` | ✅ |
| QuickActionsSection | Accesos rápidos contextuales por hora | `today_screen.dart` | ✅ |

---

## CALENDARIO DE IMPLEMENTACIÓN

```
═══════════════════════════════════════════════════════════════════════════════
FASE                          DURACIÓN    DÍAS        DEPENDENCIA
═══════════════════════════════════════════════════════════════════════════════
✅ FASE 1: Quick Wins          ~2h        Día 1       Ninguna
   ├─ QW-01: smartSuggestionProvider conectado
   ├─ QW-02: Macros restantes
   ├─ QW-03: Snackbar helper
   └─ QW-10: Color contrast
───────────────────────────────────────────────────────────────────────────────
✅ FASE 2: Contexto Temporal    ~2h        Día 1-2     Fase 1
   ├─ QW-04: timeSinceLastSession formateado
   ├─ QW-09: Welcome back toast
   └─ HIGH-004: Recuperación contexto sesión
───────────────────────────────────────────────────────────────────────────────
✅ FASE 3: UI Entry Screen      ~3h        Día 2       Fase 1
   ├─ QW-05: Progress ring
   ├─ QW-08: Thumb zone
   ├─ QW-06: Nombres semánticos
   └─ QW-07: Empty states educativos
───────────────────────────────────────────────────────────────────────────────
✅ FASE 4: Today View Básica    ~2d        Día 3-4     Fase 1, 2
   ├─ remainingMacrosProvider
   ├─ Consolidar Entry Screen
   └─ todaySummaryProvider v1
───────────────────────────────────────────────────────────────────────────────
✅ FASE 5: Scheduling Base      ~3d        Día 5-7     Fase 2, 4
   ├─ ImprovedSequentialScheduler (SchedulingService)
   ├─ Detectar descanso (<20h)
   └─ Missed Day Recovery UI
───────────────────────────────────────────────────────────────────────────────
✅ FASE 6: Today View Completa  ~3d        Día 8-10    Fase 4, 5
   ├─ today_screen.dart
   ├─ Lógica contextual por hora
   └─ Integración scheduling
───────────────────────────────────────────────────────────────────────────────
⏳ FASE 7: Scheduling Avanzado  ~5d        Día 11-15   Fase 5, 6
   ├─ WeeklyAnchoredScheduler
   ├─ FloatingCycleScheduler
   ├─ UI config semana
   └─ Migración automática
───────────────────────────────────────────────────────────────────────────────
⏳ FASE 8: Features Import      ~3d        Día 16-18   Ninguna
   ├─ TODO-2: Smart import
   └─ TODO-3: OCR import
───────────────────────────────────────────────────────────────────────────────
⏳ FASE 9: Polish Final         ~2d        Día 19-20   Todas
   ├─ MED-002: Calendario indicadores
   ├─ MED-005: Deload detection
   ├─ HIGH-003: Comida habitual
   └─ A11y y polish
───────────────────────────────────────────────────────────────────────────────
⏳ FASE 10: Refactor Navegación ~1d        Día 21      Fase 8
   ├─ TODO-1: Parámetros edición
   └─ GoRouter migration
═══════════════════════════════════════════════════════════════════════════════
TOTAL: ~21 días de trabajo efectivo
```

---

## DETALLE POR FASE

### 🔄 FASE 2: Contexto Temporal (~2h)

**Objetivo**: Añadir contexto temporal rico al sistema de scheduling

#### QW-04: Añadir "Última vez: X días" (45 min)

**Archivo**: `lib/training/providers/training_provider.dart`

El modelo `SmartWorkoutSuggestion` ya tiene `timeSinceLastSession` y `timeSinceFormatted`, pero el formateo es básico:

```dart
// ACTUAL (ya existe):
String get timeSinceFormatted {
  if (timeSinceLastSession == null) return 'nuevo';
  final hours = timeSinceLastSession!.inHours;
  if (hours < 24) return 'hace ${hours}h';
  final days = timeSinceLastSession!.inDays;
  if (days == 1) return 'ayer';
  return 'hace $days días';
}

// MEJORA PROPUESTA:
String get timeSinceFormattedContextual {
  if (timeSinceLastSession == null) return 'Primera vez';
  final days = timeSinceLastSession!.inDays;
  
  if (days == 0) return 'Hoy';
  if (days == 1) return 'Ayer';
  if (days <= 3) return 'Hace $days días';
  if (days <= 7) return 'Hace $days días (esta semana)';
  if (days <= 14) return 'Hace ${(days / 7).floor()} semanas';
  return '¡Hace $days días! Retoma tu rutina';
}
```

**Tareas**:
1. Extender `timeSinceFormatted` con contexto adicional
2. Añadir propiedad `contextualSubtitle` al modelo (ya existe, poblarla)
3. Usar en `entry_screen.dart` para mensajes más ricos

#### QW-09: Welcome Back Toast (30 min)

**Archivo**: `lib/training/screens/training_session_screen.dart`

Cuando usuario reabre app con sesión activa después de >5 min:

```dart
void _showWelcomeBackIfNeeded() {
  final session = ref.read(trainingSessionProvider);
  if (session.startTime != null) {
    final elapsed = DateTime.now().difference(session.startTime!);
    if (elapsed.inMinutes > 5) {
      _showWelcomeBackBanner(session, elapsed);
    }
  }
}
```

**UI**: MaterialBanner con:
- Tiempo transcurrido total
- Series completadas / totales
- Siguiente ejercicio pendiente
- Botón "CONTINUAR"

#### HIGH-004: Recuperación de Contexto de Sesión (45 min)

**Archivo**: `lib/training/screens/training_session_screen.dart`

Al reabrir sesión, scroll automático al ejercicio activo y highlight de la serie actual.

---

### ⏳ FASE 3: UI Entry Screen (~3h)

#### QW-05: Progress Ring en Entry Screen (1h)

**Archivo**: `lib/features/home/presentation/entry_screen.dart`

Añadir `_MiniProgressRing` a `_NutritionModeCard`:

```dart
class _MiniProgressRing extends StatelessWidget {
  final double progress;
  final int remaining;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 4,
            backgroundColor: Colors.white.withAlpha(50),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 1 ? Colors.red : Colors.white,
            ),
          ),
          Text('${(progress * 100).toInt()}%', 
               style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

#### QW-08: Thumb Zone Reorganization (1h)

Mover accesos rápidos al bottom de Entry Screen (zona del pulgar).

#### QW-06: Sugerir Nombres Semánticos (30 min)

**Archivo**: `lib/training/screens/create_edit_routine_screen.dart`

Añadir chips de sugerencia al crear día de rutina.

#### QW-07: Empty State Educativo (45 min)

**Archivo**: `lib/features/diary/presentation/diary_screen.dart`

Mejorar copy de empty states con beneficios de trackear.

---

### ⏳ FASE 4: Today View Básica (~2d)

**Objetivo**: Consolidar Entry Screen con datos reales y crear provider combinado

#### Tarea 1: remainingMacrosProvider (2h)

Nuevo provider que exponga macros restantes de forma reactiva.

#### Tarea 2: Consolidar Entry Screen (4h)

Asegurar que ambas cards (nutrición y entrenamiento) usen datos reales.

#### Tarea 3: todaySummaryProvider v1 (6h)

```dart
final todaySummaryProvider = FutureProvider<TodaySummary>((ref) async {
  final training = await ref.watch(smartSuggestionProvider.future);
  final nutrition = await ref.watch(daySummaryProvider.future);
  
  return TodaySummary(
    isTrainingDay: training != null && !training.isRestDay,
    suggestedWorkout: training?.dayName,
    daysSinceLastSession: training?.timeSinceLastSession?.inDays,
    kcalRemaining: nutrition.progress.kcalRemaining ?? 0,
    proteinRemaining: nutrition.targets?.proteinTarget != null 
        ? nutrition.targets!.proteinTarget! - nutrition.consumed.protein 
        : 0,
    // ... más campos
  );
});
```

---

### ⏳ FASE 5: Scheduling Mejorado (~3d)

**Objetivo**: Implementar sistema de scheduling inteligente base

#### ImprovedSequentialScheduler (4h)

**Archivo nuevo**: `lib/training/services/scheduling_service.dart`

```dart
class ImprovedSequentialScheduler {
  SmartWorkoutSuggestion? suggest({
    required Rutina rutina,
    required List<Sesion> history,
  }) {
    // 1. Detectar tiempo desde última sesión
    // 2. Si <20h → sugerir descanso
    // 3. Calcular siguiente día con contexto temporal
    // 4. Detectar gaps (días saltados)
  }
}
```

#### UI Missed Day Recovery (6h)

Pantalla intermedia cuando hay gap >2 días:

```
┌─────────────────────────────────┐
│ 🔄 RETOMA TU RUTINA             │
├─────────────────────────────────┤
│ Llevas 5 días sin entrenar      │
│                                 │
│ [Continuar secuencia]          │
│ [Reiniciar semana]             │
│ [Elegir manualmente]           │
└─────────────────────────────────┘
```

---

### ⏳ FASE 6: Today View Completa (~3d)

**Objetivo**: Crear pantalla "HOY" unificada que reemplace Entry Screen

#### today_screen.dart (6h)

Nueva pantalla con:
- Hero section de entrenamiento (qué toca hoy)
- Macros restantes prominentes
- Quick actions basados en hora
- Sesión en progreso (si aplica)

#### Lógica contextual por hora (4h)

```dart
String getContextualGreeting(DateTime now) {
  final hour = now.hour;
  if (hour < 10) return 'Buenos días. ¿Listo para empezar?';
  if (hour < 14) return 'Tu día de hoy';
  if (hour < 18) return 'Quedan X horas para el gym';
  if (hour < 21) return '¿Qué cenar con X kcal?';
  return 'Resumen de hoy';
}
```

---

### ⏳ FASE 7: Scheduling Avanzado (~5d)

#### WeeklyAnchoredScheduler (8h)

Permite asignar días de semana a cada día de rutina:
- Lunes = Pecho
- Miércoles = Espalda
- Viernes = Pierna

#### FloatingCycleScheduler (8h)

Para usuarios A/B que entrenan "cuando pueden":
- Detecta patrón Upper/Lower
- Sugiere basado en horas de descanso, no días

#### UI Config Semana (8h)

Vista tipo calendario para asignar días.

#### Migración Automática (6h)

Infierir modo de scheduling basado en nombres de días existentes.

---

### ⏳ FASE 8: Features Import (~3d)

Resolver TODOs del código:

#### TODO-2: Smart Import (6h)
**Archivo**: `lib/training/screens/search_exercise_screen.dart:268`

Importar ejercicios desde otras rutinas/plantillas.

#### TODO-3: OCR Import (10h)
**Archivo**: `lib/training/screens/search_exercise_screen.dart:279`

Usar ML Kit para escanear imagen de rutina y extraer ejercicios.

---

### ⏳ FASE 9: Polish Final (~2d)

#### MED-002: Calendario Indicadores Cumplimiento (6h)

Markers visuales en calendario mensual:
- Verde: día cumplido
- Amarillo: parcial
- Rojo: excedido

#### MED-005: Deload Detection (4h)

Conectar `detectOvertrainingRisk` existente a UI.

#### HIGH-003: Comida Habitual (6h)

Detectar patrones temporales y sugerir comidas habituales por hora.

---

### ⏳ FASE 10: Refactor Navegación (~1d)

#### TODO-1: Parámetros Edición (4h)
**Archivo**: `lib/training/screens/rutinas_screen.dart:74`

Refactorizar para pasar parámetros a CreateEditRoutineScreen.

#### GoRouter Migration (4h)

Completar migración a navegación declarativa.

---

## DEPENDENCIAS ENTRE TAREAS

```
                    ┌─────────────────────┐
                    │   FASE 1 COMPLETA   │
                    │  (Quick Wins Base)  │
                    └──────────┬──────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
           ▼                   ▼                   ▼
    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │   FASE 2     │   │   FASE 3     │   │   FASE 4     │
    │  (Contexto)  │   │  (UI Polish) │   │ (Today Base) │
    └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
           │                   │                   │
           └───────────┬───────┴───────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │   FASE 5        │
              │ (Scheduling Base)
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │   FASE 6        │
              │ (Today View)    │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │   FASE 7        │
              │ (Scheduling Adv)│
              └────────┬────────┘
                       │
           ┌───────────┴───────────┐
           │                       │
           ▼                       ▼
    ┌──────────────┐       ┌──────────────┐
    │   FASE 8     │       │   FASE 9     │
    │   (Import)   │       │   (Polish)   │
    └──────┬───────┘       └──────┬───────┘
           │                      │
           └──────────┬───────────┘
                      │
                      ▼
             ┌────────────────┐
             │   FASE 10      │
             │ (Refactor Nav) │
             └────────────────┘
```

---

## ARCHIVOS CLAVE

### Ya Modificados (Fase 1)
- `lib/features/home/presentation/entry_screen.dart`
- `lib/features/diary/presentation/diary_screen.dart`

### A Modificar en Fases 2-10

| Fase | Archivos Principales |
|------|---------------------|
| 2 | `training_session_screen.dart`, `training_provider.dart` |
| 3 | `entry_screen.dart`, `create_edit_routine_screen.dart` |
| 4 | `today_providers.dart` (nuevo) |
| 5 | `scheduling_service.dart` (nuevo), `train_selection_screen.dart` |
| 6 | `today_screen.dart` (nuevo) |
| 7 | `database.dart` (migración), múltiples schedulers |
| 8 | `search_exercise_screen.dart`, servicios OCR |
| 9 | `diary_screen.dart`, `training_provider.dart` |
| 10 | `rutinas_screen.dart`, router config |

---

## CÓMO CONTINUAR

### Para Continuar en Nueva Conversación:

1. **Lee este archivo primero** (`docs/COMPREHENSIVE_ROADMAP.md`)
2. **Verifica estado actual** con `SetTodoList` tool
3. **Continúa desde FASE 2** (Contexto Temporal)

### Comandos Útiles:

```bash
# Verificar estado de implementación
flutter analyze

# Ejecutar tests
flutter test

# Ver cambios en archivos clave
git diff lib/features/home/presentation/entry_screen.dart
```

### Issues de Seguimiento:

- CRIT-001: Programación sin anchor → Fases 5, 7
- CRIT-002: Entry Screen no muestra entrenamiento → Fase 1 ✅
- CRIT-003: Nutrición consumido→restante → Fase 1 ✅
- CRIT-004: No vista HOY → Fases 4, 6

### Notas para Desarrolladores Futuros:

1. **SmartWorkoutSuggestion** ya tiene campos para contexto temporal (`timeSinceLastSession`, `contextualSubtitle`) - solo necesitan ser poblados correctamente.

2. **AppSnackbar** ya existe - usar `AppSnackbar.show()` en lugar de `ScaffoldMessenger.of(context).showSnackBar()` para consistencia.

3. **Los TODOs del código** (TODO-1, TODO-2, TODO-3) están en:
   - `rutinas_screen.dart:74`
   - `search_exercise_screen.dart:268` 
   - `search_exercise_screen.dart:279`

---

## CHECKLIST DE PROGRESO

### Fase 1 ✅
- [x] QW-01: smartSuggestionProvider conectado
- [x] QW-02: Macros restantes
- [x] QW-03: Snackbar helper
- [x] QW-10: Color contrast

### Fase 2 🔄
- [x] QW-04: timeSinceLastSession contextual
- [x] QW-09: Welcome back toast
- [x] HIGH-004: Recuperación contexto

### Fase 3 ⏳
- [ ] QW-05: Progress ring
- [ ] QW-08: Thumb zone
- [ ] QW-06: Nombres semánticos
- [ ] QW-07: Empty states

### Fases 4-10 ⏳
- [ ] Fase 4: Today View Base
- [ ] Fase 5: Scheduling Base
- [ ] Fase 6: Today View Completa
- [ ] Fase 7: Scheduling Avanzado
- [ ] Fase 8: Import Features
- [ ] Fase 9: Polish Final
- [ ] Fase 10: Refactor Nav

---

*Documento generado automáticamente - Actualizar fecha al modificar*
