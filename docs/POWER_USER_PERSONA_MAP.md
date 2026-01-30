# POWER_USER_PERSONA_MAP.md - Usuarios Expertos Sin Soporte

> **Propósito**: Identificar qué tipos de power users están actualmente **excluidos** por la arquitectura de Juan Tracker, y qué cambios mínimos los habilitarían.

---

## METODOLOGÍA

Analizamos el código para identificar **asunciones implícitas** sobre el usuario:
- Qué valores están hardcodeados (asume "usuario promedio")
- Qué features están ausentes (asume "no lo necesita")
- Qué validaciones protegen de qué (asume "no sabe lo que hace")

De ahí derivamos las **personas no soportadas**.

---

## PERSONA 1: El Periodizador de Dieta

### Descripción
> "Uso carb cycling, refeeds programados, y fases de cutting/bulking. Mi dieta no es estática, cambia cada semana según mi fase de entrenamiento."

### Lo que necesita pero no tiene

| Necesidad | Estado Actual | Bloqueo |
|-----------|--------------|---------|
| Objetivos que varían por día | `TargetsModel.kcalTarget` es fijo | Hardcoded |
| Fases de dieta explícitas | No hay concepto de "fase" | Missing |
| Carb cycling automático | No hay reglas condicionales | Missing |
| Refeeds programados | No hay trigger "después de X días de déficit" | Missing |
| Macro periodización | Macros son porcentajes fijos | Hardcoded |

### Evidencia en Código
```dart
// adaptive_coach_service.dart
class CoachPlan {
  final WeightGoal goal;         // Solo: lose, maintain, gain
  final double weeklyRateKg;     // Velocidad fija
  final MacroPreset macroPreset; // Preset fijo
  // ❌ No hay: DietPhase, cyclingRules, refeedSchedule
}
```

### Cambios Mínimos para Habilitarlo
1. **DynamicTargetsModel** con reglas condicionales
2. Nuevo enum `DietPhase { cut, maintain, bulk, refeed, depletion }`
3. `CyclingRule` que ajusta macros por día de la semana

### Esfuerzo Estimado
🟡 Medium - Requiere DynamicTarget (Propuesta #3)

---

## PERSONA 2: El Atleta de Nutrición Peri-Workout

### Descripción
> "Necesito ver qué comí antes del entrenamiento, qué comí después. Quiero correlacionar mi pre-workout con mi rendimiento. La nutrición alrededor del entreno es lo más importante."

### Lo que necesita pero no tiene

| Necesidad | Estado Actual | Bloqueo |
|-----------|--------------|---------|
| Ver comidas pre/post workout | Training y Diet no conversan | Silo |
| MealType "pre-workout" y "post-workout" | Solo 4 tipos fijos | Hardcoded enum |
| Sugerencia de post-workout basada en sesión | No existe | Missing |
| Correlación proteína pre-workout ↔ fuerza | No hay análisis cruzado | Missing |
| Ventana anabólica configurable | No existe concepto | Missing |

### Evidencia en Código
```dart
// database.dart
enum MealType { breakfast, lunch, dinner, snack }
// ❌ No hay: preWorkout, intraWorkout, postWorkout

// Session y DiaryEntry viven en mundos separados
// Nunca se cruzan datos
```

### Cambios Mínimos para Habilitarlo
1. **NutritionTimingEngine** (Propuesta #1)
2. MealType extensible o custom meal slots
3. Provider que detecte "session activa o reciente" y sugiera registrar comida

### Esfuerzo Estimado
🟡 Medium - Requiere NutritionTimingEngine

---

## PERSONA 3: El Analista de Correlaciones

### Descripción
> "Quiero saber si mis días de bajo rendimiento correlacionan con mala nutrición el día anterior. Quiero hacer queries tipo 'muéstrame mi RPE promedio cuando dormí menos de 6 horas'."

### Lo que necesita pero no tiene

| Necesidad | Estado Actual | Bloqueo |
|-----------|--------------|---------|
| Campo de horas de sueño | No existe | Missing |
| Queries cruzadas training-diet | No hay servicio | Missing |
| Análisis de correlación | Solo hay análisis aislados | Missing |
| Export de datos para Excel/R | No hay export | Missing |
| Predicción basada en patrones | Solo Holt-Winters simple | Limited |

### Evidencia en Código
```dart
// weight_trend_calculator.dart
// Tiene análisis sofisticado PERO solo para peso
// No cruza con training ni con nutrición

// analysis_models.dart
// Tiene PRs, volumen, recovery PERO no cruza con diet
```

### Cambios Mínimos para Habilitarlo
1. **TemporalQueryEngine** (Propuesta #4)
2. Campo opcional `sleepHours` en Session o en tabla nueva `DailyLog`
3. Export CSV/JSON de datos históricos

### Esfuerzo Estimado
🔴 High - Requiere TemporalQueryEngine + nuevo schema

---

## PERSONA 4: El Powerlifter/Strongman Pesado

### Descripción
> "Peso 130kg, necesito 5000+ kcal en volumen. Mis incrementos de peso son de 5kg no 2.5kg. Mis descansos son 5-7 minutos entre series pesadas."

### Lo que necesita pero no tiene

| Necesidad | Estado Actual | Bloqueo |
|-----------|--------------|---------|
| kcal target > 6000 | `kMaxKcalTarget = 6000` | Hardcoded |
| Incrementos custom | Hardcoded por categoría | Hardcoded |
| Descansos largos (5-7 min) | UI no optimizada para eso | UX |
| Macros en gramos absolutos | Macros son % del total | Limited |
| Proteína > 300g | No hay límite pero % dificulta | UX |

### Evidencia en Código
```dart
// adaptive_coach_service.dart
const int kMaxKcalTarget = 6000; // ← Bloquea

// progression_engine_models.dart
double getIncrement(double currentWeight) {
  // Lógica fija, no configurable por usuario
}
```

### Cambios Mínimos para Habilitarlo
1. **ConstraintManager** con modo `advanced` o `master` (Propuesta #2)
2. Custom increments en `ProgressionSettings`
3. Opción de definir macros en gramos, no solo %

### Esfuerzo Estimado
🟢 Low - Principalmente configuración

---

## PERSONA 5: El Practicante de Intermittent Fasting

### Descripción
> "Como en una ventana de 4-6 horas. No tengo 'desayuno', 'almuerzo', 'cena'. Tengo 'primera comida' y 'última comida'. A veces es una sola comida grande."

### Lo que necesita pero no tiene

| Necesidad | Estado Actual | Bloqueo |
|-----------|--------------|---------|
| Custom meal types | `enum MealType` fijo con 4 valores | Hardcoded |
| Ventana de alimentación | No hay concepto | Missing |
| Tracking de ayuno | No existe | Missing |
| Menos de 3 comidas sin warning | Implícito en UI | UX |

### Evidencia en Código
```dart
// database.dart
enum MealType { breakfast, lunch, dinner, snack }
// No hay forma de personalizar

// UI asume al menos 3 comidas normales
// No hay soporte para patterns tipo OMAD
```

### Cambios Mínimos para Habilitarlo
1. Custom meal slots en `NutritionSettings`
2. O: Hacer `MealType` extensible con valores custom
3. Opcional: Timer de ayuno integrado

### Esfuerzo Estimado
🟢 Low - Cambio en enum o settings

---

## PERSONA 6: La Atleta con Ciclo Menstrual

### Descripción
> "Mi rendimiento y mi apetito varían con mi ciclo. Quiero trackear mi fase y ver correlaciones. Quiero que el sistema ajuste expectativas en semana premenstrual."

### Lo que necesita pero no tiene

| Necesidad | Estado Actual | Bloqueo |
|-----------|--------------|---------|
| Tracking de ciclo | No existe | Missing |
| Gender con consideraciones específicas | Gender es solo para TDEE | Limited |
| Ajuste de expectativas por fase | No hay concepto de "fase fisiológica" | Missing |
| Correlación ciclo ↔ rendimiento | No hay datos | Missing |

### Evidencia en Código
```dart
// user_profile_model.dart
enum Gender { male, female }
// Solo afecta fórmula BMR, nada más

// No hay campo de ciclo ni tracking
```

### Cambios Mínimos para Habilitarlo
1. Nueva tabla `CycleTracking` (opcional, opt-in)
2. Provider que ajuste `RecoveryStatus` basado en fase
3. Análisis en TemporalQueryEngine filtrado por fase

### Esfuerzo Estimado
🟡 Medium - Nuevo schema + lógica

---

## PERSONA 7: El Minimalista Extremo (PSMF/VLCD)

### Descripción
> "Hago protocolos de pérdida rápida supervisados. Necesito poder registrar 800-1000 kcal sin que la app me bloquee o me regañe."

### Lo que necesita pero no tiene

| Necesidad | Estado Actual | Bloqueo |
|-----------|--------------|---------|
| kcal < 1200 | `kMinKcalTarget = 1200` bloquea | Hardcoded |
| Sin warnings constantes | Validación "maternal" | UX |
| Tracking de proteína mínima (PSMF es high protein) | Macros son % no mínimos | Limited |
| Modo "supervisado médicamente" | No existe | Missing |

### Evidencia en Código
```dart
// adaptive_coach_service.dart
const int kMinKcalTarget = 1200;
// Clamp que bloquea targets menores

// En UI probablemente hay warnings adicionales
```

### Cambios Mínimos para Habilitarlo
1. **ConstraintManager** con nivel `master` (Propuesta #2)
2. Disclaimer legal que el usuario acepta una vez
3. Quitar warnings para usuarios que optaron por modo experto

### Esfuerzo Estimado
🟢 Low - ConstraintManager + disclaimer

---

## PERSONA 8: El Coach/Entrenador Personal

### Descripción
> "Quiero usar la app con mis clientes. Necesito ver múltiples perfiles, exportar datos para informes, y ajustar parámetros por cliente."

### Lo que necesita pero no tiene

| Necesidad | Estado Actual | Bloqueo |
|-----------|--------------|---------|
| Múltiples perfiles | Solo 1 UserProfile | Architecture |
| Export de datos | No hay export | Missing |
| Override de parámetros por cliente | Todo global | Architecture |
| Dashboard comparativo | No existe | Missing |

### Evidencia en Código
```dart
// database.dart
class UserProfiles extends Table {
  // Tabla existe pero solo 1 row en práctica
  // No hay concepto de "cuenta" vs "perfil"
}
```

### Cambios Mínimos para Habilitarlo
1. Multi-profile support (nuevo `ActiveProfileId` en settings)
2. Export JSON/CSV de histórico
3. UI de "switching profiles"

### Esfuerzo Estimado
🔴 High - Cambio arquitectónico significativo

---

## MATRIZ DE PRIORIZACIÓN

| Persona | Usuarios Potenciales | Esfuerzo | ROI |
|---------|---------------------|----------|-----|
| #4 Powerlifter Pesado | 🟡 Medium | 🟢 Low | ⭐⭐⭐ High |
| #7 PSMF/VLCD | 🟢 Low | 🟢 Low | ⭐⭐⭐ High |
| #5 Intermittent Fasting | 🔴 High | 🟢 Low | ⭐⭐⭐ High |
| #1 Periodizador de Dieta | 🟡 Medium | 🟡 Medium | ⭐⭐ Medium |
| #2 Nutrición Peri-Workout | 🟡 Medium | 🟡 Medium | ⭐⭐ Medium |
| #3 Analista de Correlaciones | 🟢 Low | 🔴 High | ⭐ Low (nicho) |
| #6 Atleta con Ciclo | 🔴 High | 🟡 Medium | ⭐⭐ Medium |
| #8 Coach/Entrenador | 🟢 Low | 🔴 High | ⭐ Low (B2B) |

### Quick Wins (Low Effort, High ROI)

1. **#4 + #7**: Implementar ConstraintManager → Desbloquea powerlifters Y PSMF
2. **#5**: Custom meal types → Desbloquea IF sin tocar mucho código

### High Impact, Medium Effort

3. **#1 + #2**: NutritionTimingEngine + DynamicTargets → Desbloquea periodizadores

### Long Term

4. **#3**: TemporalQueryEngine → Para los data nerds
5. **#6 + #8**: Schema changes significativos → Roadmap futuro

---

## ARQUETIPOS COMBINADOS

En la realidad, los usuarios son combinaciones:

### "El Competidor de Powerlifting en Corte"
= #4 (Powerlifter) + #1 (Periodizador) + #7 (VLCD en peak week)

**Necesita**:
- Targets altos en off-season (5000+ kcal)
- Targets bajos en peak week (< 1200 kcal)
- Macros que cambian por fase
- Sin validaciones molestas

### "La Culturista Natural"
= #1 (Periodizador) + #2 (Peri-Workout) + #6 (Ciclo)

**Necesita**:
- Nutrición timing precisa
- Fases de prep/off-season
- Consideración de ciclo menstrual
- Refeeds programados

### "El Biohacker Cuantificado"
= #3 (Analista) + #5 (IF) + #7 (PSMF experimental)

**Necesita**:
- Queries cruzadas de todo
- Protocolos extremos sin restricciones
- Export de datos para análisis externo
- Tracking de variables adicionales (sueño, HRV)

---

## CONCLUSIÓN

La arquitectura actual de Juan Tracker está optimizada para:
> **Usuario casual que entrena 3-4 días/semana, come 3 comidas normales, quiere perder peso gradualmente, y no tiene conocimiento avanzado de nutrición o periodización.**

Esto excluye sistemáticamente a:
1. Atletas de fuerza serios
2. Practicantes de IF/protocolos especiales
3. Personas que periorizan su dieta
4. Power users que quieren correlacionar datos
5. Atletas femeninas con consideraciones de ciclo

La buena noticia: **La arquitectura modular permite habilitar estos usuarios sin reescritura**, principalmente a través de:
- `ConstraintManager` para desbloquear validaciones
- `NutritionTimingEngine` para cruzar Training↔Diet
- Custom settings para personalización
- `DynamicTargets` para objetivos inteligentes
