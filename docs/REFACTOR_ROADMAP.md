# REFACTOR_ROADMAP.md - Orden de Operaciones

> **Principio guía**: Cada refactor debe habilitar el siguiente. Nunca hacer cambios que no desbloqueen algo concreto.

---

## VISIÓN GENERAL

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FASE 1: FOUNDATION                          │
│  Cambios estructurales que habilitan todo lo demás                  │
│                                                                     │
│  ┌─────────────────────┐    ┌─────────────────────┐                │
│  │ HierarchicalSettings│───▶│  ConstraintManager  │                │
│  │    (Propuesta #5)   │    │    (Propuesta #2)   │                │
│  └─────────────────────┘    └─────────────────────┘                │
│            │                          │                             │
│            ▼                          ▼                             │
│  ┌─────────────────────┐    ┌─────────────────────┐                │
│  │  ExpertiseLevel     │    │  ValidationResult   │                │
│  │  enum + UI toggle   │    │  warning vs block   │                │
│  └─────────────────────┘    └─────────────────────┘                │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         FASE 2: BRIDGE                              │
│  Conectar los silos Training ↔ Diet                                 │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              NutritionTimingEngine (Propuesta #1)            │   │
│  │                                                              │   │
│  │   Session ◄─────────────────────────────────▶ DiaryEntry     │   │
│  │      │                                             │         │   │
│  │      ▼                                             ▼         │   │
│  │  SessionNutritionContext              PostWorkoutSuggestion  │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      FASE 3: POWER FEATURES                         │
│  Features avanzadas para power users                                │
│                                                                     │
│  ┌──────────────────┐         ┌────────────────────────────────┐   │
│  │  DynamicTarget   │         │    TemporalQueryEngine         │   │
│  │  (Propuesta #3)  │         │       (Propuesta #4)           │   │
│  │                  │         │                                │   │
│  │  Rules-based     │         │  Cross-domain analysis         │   │
│  │  target calc     │         │  SQL-like queries              │   │
│  └──────────────────┘         └────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## FASE 1: FOUNDATION

### Paso 1.1: HierarchicalSettings

**Archivo a modificar**: `lib/training/providers/settings_provider.dart`

**Cambios**:
1. Crear nuevas clases de settings agrupadas
2. Migrar `UserSettings` plano a estructura jerárquica
3. Agregar campo `ExpertiseLevel`
4. Mantener backward compatibility con persistencia actual

**Código antes**:
```dart
class UserSettings {
  final bool timerSoundEnabled;
  final bool timerVibrationEnabled;
  final bool autoStartTimer;
  final int defaultRestSeconds;
  final bool showSupersetIndicator;
  final bool performanceModeEnabled;
  final bool reduceAnimations;
  final bool reduceVibrations;
  final double barWeight;
  final bool lockScreenTimerEnabled;
  final bool useFocusedInputMode;
  final bool mediaControlsEnabled;
  final bool autofocusEnabled;
}
```

**Código después**:
```dart
class UserSettings {
  final TimerSettings timer;
  final ProgressionSettings progression;
  final UISettings ui;
  final ExpertiseLevel expertiseLevel;
  final AdvancedSettings? advanced; // null si casual
}

class TimerSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoStart;
  final int defaultRestSeconds;
  final bool lockScreenEnabled;
}

// ... otras clases
```

**Tests requeridos**:
- [ ] Migración de settings antiguos funciona
- [ ] Persistencia de nueva estructura
- [ ] UI de settings se adapta a nueva estructura

**Duración estimada**: 4-6 horas

---

### Paso 1.2: ConstraintManager

**Nuevo archivo**: `lib/core/services/constraint_manager.dart`

**Dependencias**: Paso 1.1 (necesita `ExpertiseLevel`)

**Cambios**:
1. Crear `ConstraintManager` con configs por nivel
2. Crear `ConstraintConfig` con todos los límites
3. Migrar validaciones de `AdaptiveCoachService` a usar ConstraintManager
4. Crear `ValidationResult` con estados ok/warning/blocked

**Puntos de integración**:
- `AdaptiveCoachService.calculateCheckIn()` - usa ConstraintManager para clamps
- `CoachSetupScreen` - usa ConstraintManager para validar inputs
- `TargetsFormScreen` - usa ConstraintManager para validar targets

**Código**:
```dart
// constraint_manager.dart
class ConstraintManager {
  static ConstraintManager fromSettings(UserSettings settings) {
    return ConstraintManager(level: settings.expertiseLevel);
  }

  final ExpertiseLevel level;
  late final ConstraintConfig config;

  ValidationResult validateKcalTarget(int kcal) { ... }
  ValidationResult validateWeeklyChange(int current, int next) { ... }
  ValidationResult validateProteinTarget(double grams, double bodyWeight) { ... }
}
```

**Tests requeridos**:
- [ ] Cada nivel tiene los límites correctos
- [ ] ValidationResult.warning permite continuar
- [ ] ValidationResult.blocked impide acción
- [ ] Upgrade de nivel desbloquea features

**Duración estimada**: 3-4 horas

---

### Paso 1.3: UI para ExpertiseLevel

**Archivos a modificar**:
- `lib/features/settings/screens/settings_screen.dart`
- Nuevo: `lib/features/settings/widgets/expertise_selector.dart`

**Flujo de usuario**:
1. Settings > "Nivel de experiencia"
2. Quiz opcional de 3-5 preguntas O selección directa
3. Disclaimer legal para niveles advanced/master
4. Confirmación con checkbox

**UI mockup**:
```
┌─────────────────────────────────────────┐
│          NIVEL DE EXPERIENCIA           │
├─────────────────────────────────────────┤
│ ○ Casual (recomendado)                  │
│   Validaciones estrictas, protecciones  │
│                                         │
│ ○ Informado                             │
│   Warnings en lugar de bloqueos         │
│                                         │
│ ○ Avanzado                              │
│   Sin warnings, features adicionales    │
│   ⚠️ Requiere confirmación              │
│                                         │
│ ○ Master                                │
│   Sin restricciones, modo experto       │
│   ⚠️ Acepto responsabilidad total       │
└─────────────────────────────────────────┘
```

**Tests requeridos**:
- [ ] Cambio de nivel persiste
- [ ] Disclaimer se muestra para advanced+
- [ ] UI cambia según nivel

**Duración estimada**: 3-4 horas

---

## FASE 2: BRIDGE

### Paso 2.1: NutritionTimingEngine - Servicio Base

**Nuevo archivo**: `lib/core/services/nutrition_timing_engine.dart`

**Dependencias**: Ninguna (usa repos existentes)

**Implementación**:
```dart
class NutritionTimingEngine {
  final DiaryRepository diaryRepo;
  final DriftTrainingRepository sessionRepo;

  NutritionTimingEngine({
    required this.diaryRepo,
    required this.sessionRepo,
  });

  /// Obtiene comidas en ventana pre/post workout
  Future<SessionNutritionContext> getSessionContext(String sessionId) async {
    final session = await sessionRepo.getSessionById(sessionId);
    if (session == null) return SessionNutritionContext.empty();

    final start = session.startTime.subtract(const Duration(hours: 3));
    final end = session.completedAt?.add(const Duration(hours: 2))
        ?? session.startTime.add(const Duration(hours: 3));

    final entries = await diaryRepo.getEntriesInDateRange(start, end);

    return SessionNutritionContext(
      preWorkoutMeals: entries.where((e) =>
        e.createdAt.isBefore(session.startTime)).toList(),
      postWorkoutMeals: entries.where((e) =>
        e.createdAt.isAfter(session.startTime)).toList(),
      session: session,
    );
  }

  /// Sugiere post-workout basado en sesión
  PostWorkoutSuggestion? suggestPostWorkout(Session session) {
    // Extraer músculos entrenados
    // Calcular proteína sugerida
    // Retornar sugerencia
  }
}

class SessionNutritionContext {
  final List<DiaryEntryModel> preWorkoutMeals;
  final List<DiaryEntryModel> postWorkoutMeals;
  final Session? session;

  double get totalPreProtein => preWorkoutMeals.fold(0.0, (s, e) => s + (e.protein ?? 0));
  double get totalPreCarbs => preWorkoutMeals.fold(0.0, (s, e) => s + (e.carbs ?? 0));
  bool get trainedFasted => preWorkoutMeals.isEmpty;

  static SessionNutritionContext empty() => SessionNutritionContext(
    preWorkoutMeals: [],
    postWorkoutMeals: [],
    session: null,
  );
}
```

**Provider**:
```dart
// nutrition_timing_provider.dart
final nutritionTimingEngineProvider = Provider<NutritionTimingEngine>((ref) {
  return NutritionTimingEngine(
    diaryRepo: ref.watch(diaryRepositoryProvider),
    sessionRepo: ref.watch(trainingRepositoryProvider),
  );
});

final sessionNutritionContextProvider = FutureProvider.family<SessionNutritionContext, String>((ref, sessionId) async {
  final engine = ref.watch(nutritionTimingEngineProvider);
  return engine.getSessionContext(sessionId);
});
```

**Tests requeridos**:
- [ ] Detecta comidas pre-workout correctamente
- [ ] Detecta comidas post-workout correctamente
- [ ] Calcula totales de macros
- [ ] Maneja sesiones sin comidas cercanas

**Duración estimada**: 4-5 horas

---

### Paso 2.2: UI de Nutrición en Detalle de Sesión

**Archivo a modificar**: `lib/training/screens/session_detail_screen.dart`
**Nuevo widget**: `lib/training/widgets/session_nutrition_card.dart`

**Diseño**:
```
┌─────────────────────────────────────────┐
│ 🍽️ NUTRICIÓN DE LA SESIÓN              │
├─────────────────────────────────────────┤
│ Pre-workout (2h antes)                  │
│ ├─ Arroz con pollo (350 kcal, 30g P)   │
│ └─ Plátano (100 kcal, 25g C)           │
│                                         │
│ Post-workout (1h después)               │
│ ├─ Batido proteína (200 kcal, 40g P)   │
│ └─ Sin más registros                    │
│                                         │
│ Total pre: 450 kcal | 30g P | 45g C    │
│ Total post: 200 kcal | 40g P | 5g C    │
└─────────────────────────────────────────┘
```

**Condición de visibilidad**:
- Solo mostrar si hay al menos 1 comida pre O post
- Solo en sesiones completadas (no activas)

**Tests requeridos**:
- [ ] Widget aparece cuando hay datos
- [ ] Widget no aparece cuando no hay datos
- [ ] Datos se muestran correctamente

**Duración estimada**: 3-4 horas

---

### Paso 2.3: Sugerencia Post-Workout en DiaryScreen

**Archivo a modificar**: `lib/features/diary/presentation/diary_screen.dart`

**Lógica**:
1. Detectar si hay sesión completada en últimas 2 horas
2. Si no hay comida registrada post-sesión, mostrar suggestion
3. Suggestion desaparece al registrar comida

**UI**:
```
┌─────────────────────────────────────────┐
│ 💡 SUGERENCIA                           │
│ Terminaste entrenamiento de Piernas     │
│ hace 45 min. Registra tu post-workout.  │
│                                         │
│ Sugerido: ~40g proteína, ~50g carbs     │
│                                         │
│ [Registrar comida] [Ignorar]            │
└─────────────────────────────────────────┘
```

**Tests requeridos**:
- [ ] Sugerencia aparece después de sesión
- [ ] Sugerencia desaparece al registrar
- [ ] Sugerencia desaparece después de 2h
- [ ] "Ignorar" oculta por hoy

**Duración estimada**: 3-4 horas

---

## FASE 3: POWER FEATURES

### Paso 3.1: DynamicTargetsModel

**Archivos a modificar**:
- `lib/diet/models/targets_model.dart`
- `lib/diet/services/day_summary_calculator.dart`

**Nueva clase**:
```dart
class DynamicTargetsModel extends TargetsModel {
  final List<TargetAdjustmentRule> rules;

  int effectiveKcalTarget({
    required DateTime date,
    required bool isTrainingDay,
    String? trainedMuscleGroup,
  }) {
    int adjusted = kcalTarget;
    for (final rule in rules) {
      if (rule.applies(date, isTrainingDay, trainedMuscleGroup)) {
        adjusted = rule.apply(adjusted);
      }
    }
    return adjusted;
  }
}

// Reglas built-in
class TrainingDayBoostRule extends TargetAdjustmentRule { ... }
class RestDayDeficitRule extends TargetAdjustmentRule { ... }
class RefeedAfterDeficitRule extends TargetAdjustmentRule { ... }
class WeekendMaintenanceRule extends TargetAdjustmentRule { ... }
```

**Cambios en calculador**:
```dart
// day_summary_calculator.dart
DaySummary calculate(DateTime date, ...) {
  final target = targets is DynamicTargetsModel
      ? (targets as DynamicTargetsModel).effectiveKcalTarget(
          date: date,
          isTrainingDay: _checkIfTrainingDay(date),
        )
      : targets.kcalTarget;

  // ... resto del cálculo
}
```

**Tests requeridos**:
- [ ] Regla de training day aplica correctamente
- [ ] Regla de rest day aplica correctamente
- [ ] Múltiples reglas se combinan
- [ ] Sin reglas = comportamiento original

**Duración estimada**: 6-8 horas

---

### Paso 3.2: UI de Reglas de Targets

**Nuevo archivo**: `lib/features/targets/screens/dynamic_rules_screen.dart`

**Acceso**: Settings > Objetivos > "Reglas Dinámicas" (solo si expertiseLevel >= informed)

**UI**:
```
┌─────────────────────────────────────────┐
│        REGLAS DE OBJETIVOS              │
├─────────────────────────────────────────┤
│ ☑ Días de entrenamiento: +200 kcal      │
│     └─ Días de piernas: +100 extra      │
│                                         │
│ ☑ Días de descanso: -150 kcal           │
│                                         │
│ ☐ Refeed automático                     │
│     Cada 14 días de déficit: +500 kcal  │
│                                         │
│ ☐ Fin de semana mantenimiento           │
│     Sáb-Dom: ajustar a TDEE             │
│                                         │
│         [+ Agregar regla custom]        │
└─────────────────────────────────────────┘
```

**Duración estimada**: 4-5 horas

---

### Paso 3.3: TemporalQueryEngine (Opcional/Futuro)

**Nota**: Esta es la feature más compleja. Puede hacerse en fases:

**Fase A** (MVP): Queries predefinidas hardcodeadas
```dart
// Queries predefinidas que el usuario puede ejecutar
enum PredefinedQuery {
  rpeByDayOfWeek,
  volumeByNutritionStatus,
  weightCorrelationWithCalories,
  performanceByPreWorkoutMeal,
}
```

**Fase B**: Query builder visual simple
**Fase C**: DSL completo (si hay demanda)

**Duración estimada**:
- Fase A: 8-10 horas
- Fase B: 15-20 horas
- Fase C: 30+ horas

---

## RESUMEN DE TIEMPOS

| Paso | Descripción | Horas | Dependencias |
|------|-------------|-------|--------------|
| 1.1 | HierarchicalSettings | 4-6 | - |
| 1.2 | ConstraintManager | 3-4 | 1.1 |
| 1.3 | UI ExpertiseLevel | 3-4 | 1.1, 1.2 |
| **FASE 1 TOTAL** | | **10-14h** | |
| 2.1 | NutritionTimingEngine | 4-5 | - |
| 2.2 | UI Session Nutrition | 3-4 | 2.1 |
| 2.3 | Sugerencia Post-Workout | 3-4 | 2.1 |
| **FASE 2 TOTAL** | | **10-13h** | |
| 3.1 | DynamicTargetsModel | 6-8 | 1.2 |
| 3.2 | UI Reglas Targets | 4-5 | 3.1 |
| 3.3a | TemporalQuery MVP | 8-10 | 2.1 |
| **FASE 3 TOTAL** | | **18-23h** | |

**TOTAL ESTIMADO**: 38-50 horas de desarrollo

---

## ENTREGABLES POR FASE

### Al completar FASE 1:
- [ ] Usuarios pueden elegir nivel de experiencia
- [ ] Validaciones respetan nivel elegido
- [ ] Settings mejor organizados
- [ ] Power users pueden usar targets < 1200 kcal

### Al completar FASE 2:
- [ ] Sesiones muestran contexto nutricional
- [ ] App sugiere post-workout después de entreno
- [ ] Training y Diet ya no son silos

### Al completar FASE 3:
- [ ] Objetivos varían por día automáticamente
- [ ] Usuarios pueden crear reglas custom
- [ ] Análisis cruzados básicos disponibles

---

## CRITERIOS DE ÉXITO

### Métricas cuantitativas:
- [ ] 0 regresiones en tests existentes (201 tests)
- [ ] +30 tests nuevos para features nuevas
- [ ] flutter analyze sin errores

### Métricas cualitativas:
- [ ] Power user puede configurar PSMF sin bloqueos
- [ ] Power user puede ver nutrición peri-workout
- [ ] Power user puede crear reglas de targets dinámicos

### Señales de éxito:
- Usuarios existentes no notan cambios (casual experience intacta)
- Usuarios avanzados descubren y usan features nuevas
- Cero reportes de "la app me bloqueó"
