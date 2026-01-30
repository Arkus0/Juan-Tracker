# ARCHAEOLOGY_REPORT.md - Análisis de Profundidad Latente

> **Fecha**: Enero 2026
> **Versión analizada**: Schema v6, Post-Coach Adaptativo
> **Metodología**: Arqueología de código con mentalidad "feature detective"

---

## EXECUTIVE SUMMARY

Juan Tracker tiene una arquitectura sólida con **excelente separación de concerns** pero sufre de **"tech debt de profundidad"**: el código fue diseñado pensando en un usuario casual y tiene múltiples puntos donde la escalabilidad hacia maestría está bloqueada por decisiones de diseño que asumen simplicidad.

**Hallazgos clave**:
- 🔴 **17 constantes hardcodeadas** que limitan personalización avanzada
- 🔴 **2 silos completos** (Training y Diet no conversan)
- 🟡 **8 campos "durmientes"** (datos guardados pero nunca analizados)
- 🟡 **4 enums rígidos** que podrían ser configurables
- 🟢 **Buena base modular** que permite refactorización incremental

---

## SECCIÓN 1: HALLAZGOS DE CEMENTO

### 1.1 Magic Numbers Críticos

| Constante | Archivo | Valor | Limitación |
|-----------|---------|-------|------------|
| `kKcalPerKg` | `adaptive_coach_service.dart:8` | 7700.0 | Asume metabolismo estándar. No considera adaptación metabólica ni termogénesis adaptativa |
| `kMaxWeeklyKcalChange` | `adaptive_coach_service.dart:9` | 200 | Límite maternal. Un deportista puede hacer ajustes de 500+ kcal/semana |
| `kMinWeighInDays` | `adaptive_coach_service.dart:10` | 3 | Rígido. Un power user con smart scale podría tener 7 pesajes diarios |
| `kMinDiaryDays` | `adaptive_coach_service.dart:11` | 4 | Rígido. No considera calidad de tracking (parcial vs completo) |
| `kMinKcalTarget` | `adaptive_coach_service.dart:12` | 1200 | Validación maternal. PSMF puede bajar a 800 kcal |
| `kMaxKcalTarget` | `adaptive_coach_service.dart:13` | 6000 | Límite arbitrario. Michael Phelps consume 10000+ |

**Código problemático**:
```dart
// adaptive_coach_service.dart:8-13
const double kKcalPerKg = 7700.0;  // ← Asume todos iguales
const int kMaxWeeklyKcalChange = 200;  // ← Protección maternal
const int kMinKcalTarget = 1200;  // ← Bloquea PSMF/VLCD
const int kMaxKcalTarget = 6000;  // ← Bloquea atletas elite
```

### 1.2 Enums Rígidos

#### MealType (4 valores fijos)
**Archivo**: `database.dart:69`
```dart
enum MealType { breakfast, lunch, dinner, snack }
```

**Limitaciones**:
- No soporta Intermittent Fasting (1-2 comidas)
- No soporta culturistas (6-7 comidas)
- No tiene `pre_workout`, `post_workout`, `intra_workout`
- No tiene `refeed_meal` vs `regular_meal`

#### Gender (binario)
**Archivo**: `user_profile_model.dart:66`
```dart
enum Gender { male, female }
```

**Limitaciones**:
- No soporta personas trans con consideraciones metabólicas especiales
- No tiene opción "custom" con BMR manual

#### ActivityLevel (5 multiplicadores fijos)
**Archivo**: `user_profile_model.dart:68-74`
```dart
enum ActivityLevel {
  sedentary,        // 1.2
  lightlyActive,    // 1.375
  moderatelyActive, // 1.55
  veryActive,       // 1.725
  extremelyActive,  // 1.9
}
```

**Limitaciones**:
- Multiplicadores Harris-Benedict de 1984
- No considera NEAT variable por día
- No soporta multiplicador custom
- No distingue trabajo de escritorio + gym vs trabajo físico + gym

#### RecoveryStatus (días fijos)
**Archivo**: `analysis_models.dart:39-42`
```dart
enum RecoveryStatus {
  recovering(0, 2, ...),  // 0-2 días
  ready(3, 4, ...),       // 3-4 días
  fresh(5, 999, ...),     // 5+ días
}
```

**Limitaciones**:
- No considera volumen de la sesión previa
- No considera calidad de sueño
- No considera ingesta de proteína post-workout
- Thresholds hardcodeados (debería ser configurable por usuario)

### 1.3 Incrementos de Peso Hardcodeados

**Archivo**: `progression_engine_models.dart:131-142`
```dart
double getIncrement(double currentWeight) {
  switch (this) {
    case ExerciseCategory.heavyCompound:
      return currentWeight >= 60 ? 2.5 : 1.25;  // ← Threshold fijo
    case ExerciseCategory.lightCompound:
      return currentWeight >= 40 ? 2.5 : 1.25;  // ← Threshold fijo
    case ExerciseCategory.isolation:
      return 1.25;  // ← Siempre fijo
    case ExerciseCategory.machine:
      return 2.5;   // ← Ignora incrementos de máquina reales
  }
}
```

**Limitaciones**:
- No considera que cada gym tiene placas diferentes (1kg, 1.25kg, 2kg, 2.5kg, 5kg)
- No soporta micro-loading (0.5kg, 0.25kg)
- Thresholds (60kg, 40kg) son arbitrarios

### 1.4 Deload Hardcodeado

**Archivo**: `progression_engine.dart:469`
```dart
const deloadPercent = 0.10; // 10% - estándar Rippetoe/Mehdi
```

**Limitaciones**:
- No considera fase de entrenamiento (5% en fase de peaking vs 15% en hypertrofia)
- No considera edad del levantador
- No soporta deload por volumen vs deload por intensidad

### 1.5 UI/UX Hardcoded

**Archivo**: `analysis_models.dart:19-25`
```dart
int get intensityLevel {
  if (sessionsCount == 0) return 0;
  if (totalVolume < 2000) return 1;   // ← Light
  if (totalVolume < 5000) return 2;   // ← Normal
  if (totalVolume < 10000) return 3;  // ← Heavy
  return 4;                            // ← Beast mode
}
```

**Limitaciones**:
- No considera peso corporal (2000kg para 60kg vs 100kg es muy diferente)
- No tiene personalización de umbrales
- No escala con el progreso del usuario

---

## SECCIÓN 2: RELACIONES NO EXPLORADAS

### 2.1 EL GRAN SILO: Training ↔ Diet

**Estado actual**: **CERO conexión**

| Entidad Training | Entidad Diet | Relación Potencial |
|------------------|--------------|-------------------|
| `Session.startTime` | `DiaryEntry.createdAt` | Nutrición peri-workout (qué comió antes/después) |
| `Session.isBadDay` | `DailyTotals` | Correlación rendimiento ↔ nutrición del día |
| `WorkoutSets.rpe` | `WeighIn.weightKg` | RPE vs estado de hidratación/peso |
| `MuscleRecovery.daysSinceTraining` | `DiaryEntry.protein` | Proteína por grupo muscular en recuperación |

**Oportunidad arquitectónica**: Un `NutritionTimingEngine` que sugiera:
- "Entrenaste piernas hace 2h. Registra una comida alta en proteína."
- "Tu sesión de ayer fue RPE 9+. Considera aumentar carbs hoy."

### 2.2 WeighIn ↔ Session (sin explorar)

**Datos disponibles pero no cruzados**:
- `WeighIn` guarda peso diario
- `Session` guarda rendimiento

**Análisis faltante**:
- Correlación peso corporal vs PRs
- Detección de "sweet spot" de peso para fuerza
- Alertas de "Tu peso bajó 2kg esta semana pero tu fuerza subió. Posible recomposición corporal."

### 2.3 Session.isBadDay ↔ Análisis Causal

**Archivo**: `database.dart:161`
```dart
BoolColumn get isBadDay => boolean().withDefault(const Constant(false))();
```

**Estado actual**: Solo se guarda, nunca se analiza.

**Análisis faltante**:
- ¿Los días malos correlacionan con días después de déficit calórico fuerte?
- ¿Correlacionan con días lunes (fin de semana de excesos)?
- ¿Hay patrón de días malos cada N sesiones (fatiga acumulada)?

### 2.4 WorkoutSets.restSeconds ↔ Performance

**Se guarda pero no se usa para**:
- Detectar si descansos cortos causan menos reps
- Sugerir descansos óptimos personalizados
- Tracking de densidad de entrenamiento

---

## SECCIÓN 3: DATOS DURMIENTES

### 3.1 Campos Guardados pero Nunca Analizados

| Campo | Tabla | Potencial No Explotado |
|-------|-------|----------------------|
| `DiaryEntry.createdAt` | DiaryEntries | Análisis de timing de comidas (cronobiología) |
| `DiaryEntry.notes` | DiaryEntries | NLP para detectar patrones ("comí tarde", "estaba estresado") |
| `Session.startTime` | Sessions | Hora óptima de entreno por rendimiento |
| `WeighIn.note` | WeighIns | Correlación notas con fluctuaciones ("retención", "deshidratado") |
| `WorkoutSets.restSeconds` | WorkoutSets | Análisis de densidad y fatiga |
| `WorkoutSets.notes` | WorkoutSets | Contexto cualitativo de sets |
| `Foods.sourceMetadata` | Foods | Datos de OpenFoodFacts no explotados |
| `Session.isBadDay` | Sessions | Predicción de días malos |

### 3.2 Potencial de Series Temporales

**El sistema guarda historia pero no hace**:
- Predicción de peso futuro (solo Holt-Winters simple)
- Detección de ciclos (menstruales, semanales, estacionales)
- Alertas proactivas ("Los martes tu adherencia baja 30%")
- Seasonal decomposition de datos

---

## SECCIÓN 4: VALIDACIONES MATERNALES

### 4.1 Protecciones que Castran al Experto

| Validación | Archivo | Alternativa Propuesta |
|------------|---------|----------------------|
| Min 1200 kcal | `adaptive_coach_service.dart` | Warning + confirmación para <1200, no bloqueo |
| Max 6000 kcal | `adaptive_coach_service.dart` | Modo "athlete" que desbloquea hasta 10000 |
| Max 200 kcal/semana cambio | `adaptive_coach_service.dart` | Configurable por objetivo (aggressive/conservative) |
| Peso 20-500kg | `user_profile_model` (implícito) | Sin validación - el usuario sabe su peso |
| Edad 10-120 | Validación TDEE | Sin límites - fórmulas funcionan para cualquier edad razonable |

### 4.2 Patrón Anti-Expert Detectado

El código usa **fail-safe defaults** que asumen incompetencia:
```dart
// Ejemplo: defaultRestSeconds = 90
// Un powerlifter necesita 3-5 minutos
// Un HIIT necesita 15-30 segundos
// El default de 90s no sirve para ninguno
```

---

## SECCIÓN 5: ANTI-PATTERNS DETECTADOS

### 5.1 Anemic Domain Model

**Problema**: Lógica de negocio distribuida en servicios, no en modelos.

**Ejemplo** (`TargetsModel`):
```dart
class TargetsModel {
  final int kcalTarget;
  // ... solo campos, sin comportamiento
}
```

**Debería tener métodos como**:
- `isInDeficit(int consumed)`
- `suggestMealSize(int mealsRemaining)`
- `adaptToActivity(ActivityLevel todayLevel)`

### 5.2 God Provider Pattern

El `settingsProvider` tiene **13 settings planos** sin jerarquía:
```dart
class UserSettings {
  final bool timerSoundEnabled;
  final bool timerVibrationEnabled;
  final bool autoStartTimer;
  final int defaultRestSeconds;
  // ... 9 más
}
```

**Debería ser**:
```dart
class UserSettings {
  final TimerSettings timer;
  final ProgressionSettings progression;
  final UISettings ui;
  final AdvancedSettings? advanced; // null para casuals
}
```

### 5.3 Missing Temporal Dimension

Los `Targets` tienen `validFrom` para versionado, pero:
- `UserProfile` no tiene historial
- `UserSettings` no tiene historial
- No hay concepto de "fases de entrenamiento/dieta"

---

## SECCIÓN 6: OPORTUNIDADES DE MAESTRÍA LATENTE

### 6.1 Campos que Quieren Ser Más

| Campo Actual | Tipo | Potencial Expandido |
|--------------|------|-------------------|
| `kcalTarget: int` | Valor fijo | `DynamicTarget` con fórmula basada en día |
| `activityLevel: enum` | Constante | `DailyActivity` que varía por día |
| `isBadDay: bool` | Binario | `SessionQuality { excellent, good, normal, suboptimal, terrible }` |
| `mealType: enum` | 4 opciones | Custom meal slots configurables |
| `notes: String` | Texto libre | Structured tags + free text |

### 6.2 Booleans que Quieren Ser Enums

```dart
// Actual
isBadDay: bool

// Potencial
sessionQuality: SessionQuality {
  prDay,      // PR establecido
  excellent,  // Superó expectativas
  standard,   // Normal
  suboptimal, // Algo flojo
  terrible,   // Día desastroso
  deload,     // Deload planificado
}
```

### 6.3 Strings que Quieren Ser Estructuras

```dart
// Actual
DiaryEntry.notes: String  // "comí tarde porque llegué del gym"

// Potencial
DiaryEntry.metadata: MealContext {
  timing: MealTiming { onTime, late, early, skipped }
  trigger: EatingTrigger? { hunger, social, emotional, scheduled }
  location: String?
  companions: int?
  freeNotes: String?
}
```

---

## CONCLUSIONES

### Fortalezas Arquitectónicas
1. **Separación de módulos** clara (training/, diet/, features/)
2. **Repositorios bien definidos** con interfaces
3. **Servicios de cálculo puros** y testeables
4. **Versionado de Targets** (buen precedente para expandir)

### Deudas Técnicas de Profundidad
1. **Silos de datos** que impiden análisis holístico
2. **Constantes hardcodeadas** en lugar de configuración
3. **Enums rígidos** en lugar de configurables
4. **Datos históricos no explotados** para predicción
5. **Validaciones protectoras** que bloquean uso avanzado

### Siguiente Paso Recomendado
Ver `ARCHITECTURE_PROPOSALS.md` para propuestas concretas de refactorización basadas en estos hallazgos.
