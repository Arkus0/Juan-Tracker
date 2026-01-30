# ARCHITECTURE_PROPOSALS.md - Propuestas de Refactorización

> **Basado en**: ARCHAEOLOGY_REPORT.md
> **Enfoque**: Evolución elegante, no reescritura
> **Principio**: Cada propuesta debe ser implementable incrementalmente

---

## PROPUESTA 1: NutritionTimingEngine - El Puente Training↔Diet

### Problema Actual
Training y Diet son **silos completos**. Un usuario no puede:
- Ver qué comió antes/después de una sesión
- Correlacionar rendimiento con nutrición del día
- Recibir sugerencias de comidas basadas en entrenamiento

### Lugar en Código
- **Nuevo servicio**: `lib/core/services/nutrition_timing_engine.dart`
- **Conexiones**: Lee de `SessionRepository` y `DiaryRepository`

### Limitación Actual
```dart
// Session no sabe nada de nutrición
class Session {
  final DateTime startTime;
  // ... sin referencia a meals
}

// DiaryEntry no sabe nada de entrenamiento
class DiaryEntry {
  final DateTime createdAt;
  // ... sin referencia a workouts
}
```

### Propuesta Concreta

```dart
/// Motor de análisis de nutrición temporal
/// Cruza datos de Training y Diet para insights peri-workout
class NutritionTimingEngine {
  final DiaryRepository diaryRepo;
  final SessionRepository sessionRepo;

  /// Obtiene el contexto nutricional de una sesión
  Future<SessionNutritionContext> getSessionContext(String sessionId) async {
    final session = await sessionRepo.getById(sessionId);
    if (session == null) return SessionNutritionContext.empty();

    final windowStart = session.startTime.subtract(Duration(hours: 3));
    final windowEnd = session.completedAt?.add(Duration(hours: 2))
        ?? session.startTime.add(Duration(hours: 3));

    final entries = await diaryRepo.getEntriesInRange(windowStart, windowEnd);

    return SessionNutritionContext(
      preWorkoutMeals: entries.where((e) => e.createdAt.isBefore(session.startTime)).toList(),
      postWorkoutMeals: entries.where((e) => e.createdAt.isAfter(session.startTime)).toList(),
      totalPreWorkoutProtein: _sumProtein(preWorkoutMeals),
      totalPreWorkoutCarbs: _sumCarbs(preWorkoutMeals),
      timeSinceLastMeal: _timeSinceLastMeal(session.startTime, entries),
    );
  }

  /// Sugiere comida post-workout basada en la sesión
  PostWorkoutSuggestion suggestPostWorkout(Session session) {
    final musclesTrained = _extractMuscles(session);
    final estimatedProteinNeed = musclesTrained.length * 10; // ~10g por grupo

    return PostWorkoutSuggestion(
      targetProtein: estimatedProteinNeed.clamp(20, 50),
      targetCarbs: session.isBadDay ? 30 : 50, // Menos carbs si día malo
      reason: 'Entrenaste ${musclesTrained.join(", ")}. Proteína para recuperación.',
    );
  }

  /// Correlaciona rendimiento con nutrición histórica
  Future<NutritionPerformanceCorrelation> analyzeCorrelation({
    required String exerciseName,
    required int lastNSessions,
  }) async {
    // Obtener últimas N sesiones del ejercicio
    // Para cada una, calcular nutrición pre-workout
    // Correlacionar con resultado (RPE, completitud, volumen)
    // Devolver insights
  }
}

class SessionNutritionContext {
  final List<DiaryEntryModel> preWorkoutMeals;
  final List<DiaryEntryModel> postWorkoutMeals;
  final double totalPreWorkoutProtein;
  final double totalPreWorkoutCarbs;
  final Duration? timeSinceLastMeal;

  bool get trainedFasted => timeSinceLastMeal == null ||
      timeSinceLastMeal!.inHours >= 4;
}
```

### Impacto Usuario
- **Descubrimiento**: Nuevo tab "Nutrición" en detalle de sesión pasada
- **No intrusivo**: Solo aparece si hay datos de ambos lados
- **Power user**: Puede ver correlaciones en "Laboratorio"

### Esfuerzo
🟡 **Medium** - Requiere nuevo servicio pero usa repos existentes

---

## PROPUESTA 2: ConstraintManager - Sistema de Restricciones Progresivas

### Problema Actual
Validaciones hardcodeadas que protegen al casual pero castran al experto:
- Min 1200 kcal (bloquea PSMF)
- Max 200 kcal/semana cambio (bloquea ajustes agresivos)
- 4 tipos de comida fijos (bloquea IF)

### Lugar en Código
- **Nuevo servicio**: `lib/core/services/constraint_manager.dart`
- **Migración**: Mover validaciones de servicios a este manager

### Propuesta Concreta

```dart
/// Niveles de experiencia que desbloquean restricciones
enum ExpertiseLevel {
  casual,     // Validaciones estrictas, muchas protecciones
  informed,   // Warnings en lugar de bloqueos
  advanced,   // Sin warnings, asume conocimiento
  master,     // Sin validaciones, modo "sé lo que hago"
}

/// Configuración de restricciones por nivel
class ConstraintConfig {
  final int minKcalTarget;
  final int maxKcalTarget;
  final int maxWeeklyKcalChange;
  final bool allowNegativeBalance;
  final bool allowCustomMealTypes;
  final bool allowManualTdeeOverride;

  static const casual = ConstraintConfig(
    minKcalTarget: 1200,
    maxKcalTarget: 4000,
    maxWeeklyKcalChange: 200,
    allowNegativeBalance: false,
    allowCustomMealTypes: false,
    allowManualTdeeOverride: false,
  );

  static const informed = ConstraintConfig(
    minKcalTarget: 1000,
    maxKcalTarget: 5000,
    maxWeeklyKcalChange: 350,
    allowNegativeBalance: true, // Con warning
    allowCustomMealTypes: false,
    allowManualTdeeOverride: false,
  );

  static const advanced = ConstraintConfig(
    minKcalTarget: 800,
    maxKcalTarget: 6000,
    maxWeeklyKcalChange: 500,
    allowNegativeBalance: true,
    allowCustomMealTypes: true,
    allowManualTdeeOverride: true,
  );

  static const master = ConstraintConfig(
    minKcalTarget: 0,       // PSMF, extended fasts
    maxKcalTarget: 15000,   // Sumo wrestlers, Phelps
    maxWeeklyKcalChange: 9999,
    allowNegativeBalance: true,
    allowCustomMealTypes: true,
    allowManualTdeeOverride: true,
  );
}

/// Manager que evalúa restricciones según nivel
class ConstraintManager {
  final ExpertiseLevel level;
  late final ConstraintConfig config;

  ConstraintManager({this.level = ExpertiseLevel.casual}) {
    config = switch (level) {
      ExpertiseLevel.casual => ConstraintConfig.casual,
      ExpertiseLevel.informed => ConstraintConfig.informed,
      ExpertiseLevel.advanced => ConstraintConfig.advanced,
      ExpertiseLevel.master => ConstraintConfig.master,
    };
  }

  /// Valida un target de calorías
  ValidationResult validateKcalTarget(int kcal) {
    if (kcal < config.minKcalTarget) {
      if (level == ExpertiseLevel.casual) {
        return ValidationResult.blocked(
          'Mínimo ${config.minKcalTarget} kcal por seguridad',
        );
      }
      return ValidationResult.warning(
        'Valores < ${config.minKcalTarget} kcal requieren supervisión médica',
      );
    }
    // ... similar para max
    return ValidationResult.ok();
  }

  /// Valida un cambio semanal
  ValidationResult validateWeeklyChange(int currentKcal, int newKcal) {
    final change = (newKcal - currentKcal).abs();
    if (change > config.maxWeeklyKcalChange) {
      if (level == ExpertiseLevel.casual) {
        return ValidationResult.blocked(
          'Cambio máximo de ${config.maxWeeklyKcalChange} kcal/semana',
        );
      }
      return ValidationResult.warning(
        'Cambios grandes pueden afectar metabolismo',
      );
    }
    return ValidationResult.ok();
  }
}

class ValidationResult {
  final ValidationStatus status;
  final String? message;

  ValidationResult.ok() : status = ValidationStatus.ok, message = null;
  ValidationResult.warning(this.message) : status = ValidationStatus.warning;
  ValidationResult.blocked(this.message) : status = ValidationStatus.blocked;
}

enum ValidationStatus { ok, warning, blocked }
```

### Impacto Usuario
- **Descubrimiento**: Settings > "Nivel de experiencia" con quiz opcional
- **No intrusivo**: Default es `casual`, igual que ahora
- **Power user**: Puede desbloquear `advanced`/`master` aceptando disclaimer

### Esfuerzo
🟢 **Low** - Wrapper sobre validaciones existentes

---

## PROPUESTA 3: DynamicTarget - Objetivos que Varían por Contexto

### Problema Actual
`TargetsModel.kcalTarget` es un **número fijo** que no considera:
- Días de entrenamiento vs descanso
- Fase actual (déficit vs mantenimiento vs superávit)
- Fatiga acumulada

### Lugar en Código
- **Evolución de**: `lib/diet/models/targets_model.dart`
- **Nuevo modelo**: `DynamicTargetsModel`

### Limitación Actual
```dart
class TargetsModel {
  final int kcalTarget;  // ← Número fijo para todos los días
}
```

### Propuesta Concreta

```dart
/// Target dinámico que se adapta al contexto del día
class DynamicTargetsModel extends TargetsModel {
  /// Reglas de ajuste por día
  final List<TargetAdjustmentRule> rules;

  /// Calcula el target efectivo para un día específico
  int effectiveKcalTarget({
    required DateTime date,
    required bool isTrainingDay,
    required String? trainedMuscleGroup,
    required double? sleepHours,
    required double currentTrendWeight,
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

/// Regla de ajuste de targets
abstract class TargetAdjustmentRule {
  bool applies(DateTime date, bool isTrainingDay, String? muscleGroup);
  int apply(int baseKcal);
}

/// Regla: +300 kcal en días de entrenamiento de piernas
class LegDayBoostRule extends TargetAdjustmentRule {
  final int extraKcal;

  LegDayBoostRule({this.extraKcal = 300});

  @override
  bool applies(DateTime date, bool isTrainingDay, String? muscleGroup) {
    return isTrainingDay &&
           (muscleGroup?.toLowerCase().contains('pierna') ?? false);
  }

  @override
  int apply(int baseKcal) => baseKcal + extraKcal;
}

/// Regla: Carbos ciclados (low carb en rest days)
class CarbCyclingRule extends TargetAdjustmentRule {
  final int restDayDeficit;

  CarbCyclingRule({this.restDayDeficit = 200});

  @override
  bool applies(DateTime date, bool isTrainingDay, String? muscleGroup) {
    return !isTrainingDay;
  }

  @override
  int apply(int baseKcal) => baseKcal - restDayDeficit;
}

/// Regla: Refeed cada N días de déficit
class RefeedRule extends TargetAdjustmentRule {
  final int deficitDaysBeforeRefeed;
  final int refeedSurplus;

  // Necesita contexto histórico
  bool applies(...) {
    // Cuenta días consecutivos en déficit
    // Si >= deficitDaysBeforeRefeed, aplica refeed
  }
}
```

### Impacto Usuario
- **Descubrimiento**: "Objetivos Avanzados" en configuración de Coach
- **No intrusivo**: Default sin reglas = comportamiento actual
- **Power user**: Puede crear reglas tipo "Si es día de piernas, +300kcal"

### Esfuerzo
🟡 **Medium** - Requiere refactor de cómo se calculan targets diarios

---

## PROPUESTA 4: TemporalQueryEngine - Análisis de Series Temporales

### Problema Actual
Se guardan datos históricos pero solo se hacen queries simples:
- "Dame el peso de hoy"
- "Dame las entradas del diario de ayer"

No se puede preguntar:
- "Muéstrame los martes que dormí mal vs bien y cómo afectó mi strength"
- "¿Cuál es mi RPE promedio después de días con <100g de carbs?"

### Lugar en Código
- **Nuevo servicio**: `lib/core/services/temporal_query_engine.dart`
- **Usa**: Todos los repositorios existentes

### Propuesta Concreta

```dart
/// Motor de queries temporales para análisis cruzado
class TemporalQueryEngine {
  final SessionRepository sessionRepo;
  final DiaryRepository diaryRepo;
  final WeightRepository weightRepo;

  /// Query builder para análisis complejos
  TemporalQuery query() => TemporalQuery(this);
}

class TemporalQuery {
  final TemporalQueryEngine engine;
  DateTimeRange? _range;
  List<QueryFilter> _filters = [];
  List<QueryGroupBy> _groupBy = [];
  QueryMetric? _metric;

  TemporalQuery(this.engine);

  /// Rango de tiempo
  TemporalQuery inRange(DateTime start, DateTime end) {
    _range = DateTimeRange(start: start, end: end);
    return this;
  }

  /// Últimos N días
  TemporalQuery lastDays(int n) {
    final now = DateTime.now();
    return inRange(now.subtract(Duration(days: n)), now);
  }

  /// Filtrar por condición
  TemporalQuery where(QueryFilter filter) {
    _filters.add(filter);
    return this;
  }

  /// Agrupar resultados
  TemporalQuery groupBy(QueryGroupBy group) {
    _groupBy.add(group);
    return this;
  }

  /// Métrica a calcular
  TemporalQuery measure(QueryMetric metric) {
    _metric = metric;
    return this;
  }

  /// Ejecutar query
  Future<QueryResult> execute() async {
    // Implementación que cruza datos de múltiples repos
  }
}

// === EJEMPLO DE USO ===

// "¿Cuál es mi RPE promedio los días que consumí >150g de proteína?"
final result = await engine.query()
    .lastDays(90)
    .where(DietFilter.proteinGreaterThan(150))
    .measure(TrainingMetric.averageRpe)
    .execute();

// "Compara mi volumen de piernas en semanas de déficit vs mantenimiento"
final comparison = await engine.query()
    .lastDays(180)
    .groupBy(DietPhaseGroup()) // déficit vs maintenance
    .where(MuscleGroupFilter('piernas'))
    .measure(TrainingMetric.weeklyVolume)
    .execute();

// "¿Qué día de la semana tengo mejor rendimiento?"
final byDay = await engine.query()
    .lastDays(365)
    .groupBy(DayOfWeekGroup())
    .measure(TrainingMetric.completionRate)
    .execute();
```

### Filtros Predefinidos

```dart
// Filtros de dieta
class DietFilter {
  static QueryFilter proteinGreaterThan(double g) => ...;
  static QueryFilter carbsLessThan(double g) => ...;
  static QueryFilter inDeficit() => ...; // kcal < target
  static QueryFilter inSurplus() => ...;
}

// Filtros de entrenamiento
class TrainingFilter {
  static QueryFilter rpeGreaterThan(double rpe) => ...;
  static QueryFilter muscleGroup(String group) => ...;
  static QueryFilter isBadDay() => ...;
}

// Filtros de peso
class WeightFilter {
  static QueryFilter trendingDown() => ...;
  static QueryFilter trendingUp() => ...;
  static QueryFilter varianceGreaterThan(double kg) => ...;
}
```

### Impacto Usuario
- **Descubrimiento**: Nuevo tab "Laboratorio" > "Análisis Avanzado"
- **No intrusivo**: UI con queries predefinidas + opción "Custom"
- **Power user**: Interface tipo "Excel pivot table" para exploracion

### Esfuerzo
🔴 **High** - Requiere diseño de DSL y optimización de queries

---

## PROPUESTA 5: HierarchicalSettings - Configuración por Capas

### Problema Actual
`UserSettings` es un objeto plano con 13+ campos mezclados:
- Settings de timer (sonido, vibración, auto-start)
- Settings de UI (animaciones, modo oscuro)
- Settings de progresión (peso barra, incrementos)
- Todo junto sin organización

### Lugar en Código
- **Refactor de**: `lib/training/providers/settings_provider.dart`
- **Nueva estructura**: Jerárquica con capas

### Propuesta Concreta

```dart
/// Settings jerárquicos por categoría
class UserSettings {
  final TimerSettings timer;
  final ProgressionSettings progression;
  final UISettings ui;
  final NutritionSettings nutrition;
  final AdvancedSettings? advanced; // null = modo casual

  /// Nivel de expertise (afecta validaciones y features visibles)
  final ExpertiseLevel expertiseLevel;
}

class TimerSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoStart;
  final int defaultRestSeconds;
  final bool lockScreenEnabled;
}

class ProgressionSettings {
  final double barWeight;
  final Map<ExerciseCategory, double> customIncrements; // Overrides
  final double deloadPercent;
  final int confirmationSessions;
}

class UISettings {
  final bool reduceAnimations;
  final bool reduceVibrations;
  final bool focusedInputMode;
  final ThemeMode themeMode;
}

class NutritionSettings {
  final MacroPreset macroPreset;
  final List<String> customMealTypes; // ["Pre-workout", "Post-workout", ...]
  final bool trackMicronutrients;
  final bool trackFiber;
  final bool trackSodium;
}

/// Settings avanzados (solo visibles si expertiseLevel >= advanced)
class AdvancedSettings {
  final bool manualTdeeOverride;
  final int? customTdee;
  final bool enableExperimentalFeatures;
  final Map<String, dynamic> customConstraints;

  /// Overrides de constantes del sistema
  final double? kcalPerKgOverride; // Default 7700
  final List<double>? availablePlates; // Placas del gym
}
```

### Migración

```dart
// Migración automática de settings viejos a nuevos
extension LegacySettingsMigration on UserSettings {
  static UserSettings fromLegacy(LegacyUserSettings old) {
    return UserSettings(
      timer: TimerSettings(
        soundEnabled: old.timerSoundEnabled,
        vibrationEnabled: old.timerVibrationEnabled,
        autoStart: old.autoStartTimer,
        defaultRestSeconds: old.defaultRestSeconds,
        lockScreenEnabled: old.lockScreenTimerEnabled,
      ),
      // ... mapear resto
      expertiseLevel: ExpertiseLevel.casual, // Default
    );
  }
}
```

### Impacto Usuario
- **Descubrimiento**: Settings reorganizados en secciones colapsables
- **No intrusivo**: Mismos settings, mejor organización
- **Power user**: Sección "Avanzado" visible solo si lo desbloquea

### Esfuerzo
🟢 **Low** - Reorganización estructural, misma persistencia

---

## RESUMEN DE PROPUESTAS

| # | Propuesta | Esfuerzo | Impacto | Dependencias |
|---|-----------|----------|---------|--------------|
| 1 | NutritionTimingEngine | 🟡 Medium | 🔴 High | Ninguna |
| 2 | ConstraintManager | 🟢 Low | 🟡 Medium | #5 (settings) |
| 3 | DynamicTarget | 🟡 Medium | 🔴 High | #2 (constraints) |
| 4 | TemporalQueryEngine | 🔴 High | 🔴 High | #1 (nutrition timing) |
| 5 | HierarchicalSettings | 🟢 Low | 🟡 Medium | Ninguna |

### Orden de Implementación Recomendado

```
FASE 1 (Foundation):
  └─ #5 HierarchicalSettings
     └─ #2 ConstraintManager

FASE 2 (Bridge):
  └─ #1 NutritionTimingEngine

FASE 3 (Power Features):
  └─ #3 DynamicTarget
  └─ #4 TemporalQueryEngine (puede ir en paralelo)
```

Ver `REFACTOR_ROADMAP.md` para el plan detallado de implementación.
