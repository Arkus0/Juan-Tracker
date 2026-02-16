# 🤖 Roadmap de IA y Automatización - Juan Tracker

## Sistemas Inteligentes Actuales (Ya Implementados)

### 1. 🎯 Motor de Progresión Determinista v2 (`progression_engine.dart`)
**Estado:** ✅ Implementado y funcional

| Feature | Descripción |
|---------|-------------|
| Doble Progresión (Lyle McDonald) | Subir reps hasta max → subir peso → reset reps |
| Progresión Lineal (Rippetoe) | +peso cada sesión exitosa, deload 10% en stall |
| Progresión RPE (Tuchscherer) | Autoregulación basada en RPE 7-9 |
| Stall Detection | 3 fallos mismo peso = deload |
| Confirmación Inteligente | 2 sesiones antes de subir peso |

**Lógica de Negocio Clave:**
```dart
// Diferenciador vs Hevy: Hevy es manual, nosotros automático
if (allSetsHitMaxReps(maxReps) && consecutiveSuccesses >= 1) {
  return increaseWeight(); // Automático
}
```

### 2. 🛡️ Error Tolerance System (`error_tolerance_system.dart`)
**Estado:** ✅ Implementado

| Regla | Comportamiento |
|-------|----------------|
| Serie Fallida | NO afecta progresión (1 día malo no castiga) |
| Error de Entrada | Detecta 500kg en curl → sugiere 50kg |
| Sesión Saltada | Ajusta según días: <7d sin cambios, 7-14d reset, >30d recalibración |
| Día Malo | <80% completado = mensaje de ánimo, no castigo |
| Override Manual | Usuario siempre gana, sistema aprende preferencia |

**Diferenciador:** Hevy no tiene protección contra errores de dedo.

### 3. 🔍 Smart Exercise Search (`smart_exercise_search_service.dart`)
**Estado:** ✅ Implementado

- Fuzzy matching (Levenshtein distance)
- Sinónimos español/inglés (180+ aliases)
- Autocomplete inteligente
- Scoring por relevancia

### 4. 🚨 Deload Alerts (`deload_alerts_provider.dart`)
**Estado:** ✅ Implementado

- Detecta tendencia de fuerza descendente
- Alertas por severidad (warning/critical)
- Análisis de estancamiento por ejercicio

### 5. 🎙️ Sistema de Voz (`voice_input_service.dart`)
**Estado:** ✅ Implementado

- Smart Import por voz (crear rutinas completas)
- Comandos durante sesión
- Parsing natural language ("3 series de 10 a 80 kilos")

### 6. 📊 Análisis Avanzado (`analysis_models.dart`)
**Estado:** ✅ Implementado

- Recovery Monitor (músculos por día de recuperación)
- Muscle Imbalance Dashboard (Push/Pull, Quad/Ham)
- Symmetry Radar (visualización radial)
- Hall of Fame (PRs automáticos)
- Strength Trend (tendencias de fuerza)

---

## 🚀 Nuevas Propuestas de IA/Automatización

### TIER 1: Alto Impacto / Implementable (3-6 meses)

#### 1.1 🤖 **AI Coach Personalizado** (`ai_coach_service.dart`)

**Concepto:** Un coach virtual que aprende del usuario y da consejos personalizados.

**Features:**
```dart
class AICoachService {
  // Analiza patrones de entrenamiento
  Future<CoachAdvice> analyzeTrainingPatterns() {
    // - "Veo que entrenas mejor los lunes, considera mover piernas a ese día"
    // - "Tu press banca estancó hace 3 semanas, prueba variar el rango de reps"
    // - "Detecto fatiga acumulada en hombros, sugeriría descanso 2 días"
  }
  
  // Predicción de capacidad de recuperación
  RecoveryPrediction predictRecovery() {
    // ML basado en: horas de sueño (si tenemos), volumen reciente, 
    // historial de RPE, días desde último entreno del grupo muscular
  }
}
```

**Implementación:**
- Reglas deterministas inicialmente (no requiere ML pesado)
- Evolucionar a ML on-device con `tflite_flutter`
- Entrenar con datos del propio usuario (personalización)

**Diferenciador vs Hevy:** Hevy no tiene coach integrado.

---

#### 1.2 🔮 **Predictor de PRs** (`pr_predictor_service.dart`)

**Concepto:** Predecir cuándo el usuario batirá su próximo récord personal.

**Features:**
```dart
class PRPredictor {
  // Basado en tendencia de fuerza (regresión lineal)
  PredictionResult predictNextPR(String exercise) {
    return PredictionResult(
      estimatedDate: DateTime.now().add(Duration(days: 14)),
      confidence: 0.78,
      targetWeight: 100.0, // kg
      currentBest: 95.0,
      message: "Basado en tu progresión actual, deberías poder hacer 100kg en ~2 semanas",
    );
  }
  
  // Detectar si el usuario está "cerca" de un PR y motivar
  bool isNearPR(String exercise, double currentWeight, int reps) {
    final estimated1RM = estimateOneRepMax(currentWeight, reps);
    final best1RM = getBest1RM(exercise);
    return estimated1RM > best1RM * 0.95; // 95% del PR = "cerca"
  }
}
```

**UI:** Banner en sesión: "¡Estás al 95% de tu PR! Dale con todo 🔥"

---

#### 1.3 🧠 **Smart Exercise Substitution** (`smart_substitution_service.dart`)

**Concepto:** Sugerir alternativas de ejercicios inteligentes basadas en equipamiento disponible, lesiones, o objetivos.

**Features:**
```dart
class SmartSubstitutionService {
  // Si el usuario no tiene barra, sugerir alternativas con mancuernas
  List<ExerciseAlternative> getAlternatives(
    String targetExercise, {
    List<String> availableEquipment,
    List<String> injuries,
    TrainingGoal goal,
  }) {
    // Ejemplo: "Sentadilla" → ["Goblet Squat", "Hack Squat", "Leg Press"]
    // Priorizadas por: similaridad muscular, transferencia de fuerza, disponibilidad
  }
  
  // Auto-detectar cuando un ejercicio no está funcionando
  bool shouldSuggestAlternative(String exercise) {
    // Si lleva 4+ sesiones sin progreso en un ejercicio de aislamiento
    // Sugerir variante (ej: curl martillo vs curl normal)
  }
}
```

**Base de datos necesaria:** Matriz de transferencia entre ejercicios.

---

#### 1.4 ⏱️ **Smart Rest Timer** (`smart_rest_service.dart`)

**Concepto:** Timer de descanso que se ajusta automáticamente basado en:
- Tipo de ejercicio (compuesto vs aislamiento)
- RPE de la serie anterior
- Historial de recuperación del usuario

**Features:**
```dart
class SmartRestService {
  int calculateRestTime({
    required ExerciseType type,
    required int lastRPE,
    required double lastWeight,
    required int targetReps,
    required List<int> recentRestTimes, // Lo que el usuario realmente descansa
  }) {
    // Base: Compuestos 3-5min, Aislamiento 1-2min
    // Ajuste: RPE alto = +30s, RPE bajo = -15s
    // Aprendizaje: Si el usuario siempre descansa 30s más, ajustar
  }
  
  // Notificación: "Tu RPE fue 9.5, descansa 3:30 para recuperarte bien"
}
```

**Diferenciador:** Hevy tiene timer fijo o manual. Nosotros adaptativo.

---

#### 1.5 📅 **Periodización Automática** (`auto_periodization_service.dart`)

**Concepto:** Ajustar automáticamente el programa de entrenamiento basado en ciclos.

**Features:**
```dart
class AutoPeriodizationService {
  // Detectar fase del ciclo de entrenamiento
  TrainingPhase detectPhase(List<Sesion> recentSessions) {
    // - Accumulation: Volumen creciente, intensidad moderada
    // - Intensification: Volumen moderado, intensidad alta
    // - Realization: Peak strength (bajo volumen, alta intensidad)
    // - Deload: Recuperación
  }
  
  // Sugerir cambios automáticos a la rutina
  RoutineAdjustment suggestAdjustment(Rutina routine) {
    // Ejemplo: "Llevas 4 semanas acumulando. Semana que viene: reduce sets 20%, sube peso"
  }
}
```

---

### TIER 2: Medio Impacto / Complejidad Media (6-12 meses)

#### 2.1 📸 **Form Check por Cámara** (`form_analysis_service.dart`)

**Concepto:** Usar ML Kit Pose Detection para dar feedback básico de forma.

**Features:**
```dart
class FormAnalysisService {
  // Análisis básico (no reemplaza a un coach humano)
  FormCheckResult analyzeSquat(List<Pose> poses) {
    // Detectar: profundidad, rodillas valgas, cadera primeras
    // Dar feedback: "Intenta bajar más, los muslos no están paralelos"
  }
  
  // Solo para ejercicios clave: sentadilla, peso muerto, press banca
}
```

**Limitaciones:** Requiere buena iluminación y ángulo. MVP: Solo contar reps automáticamente.

---

#### 2.2 🍽️ **Nutri-Training Integration** (`nutrition_training_sync.dart`)

**Concepto:** Sincronizar recomendaciones de nutrición con entrenamiento.

**Features:**
```dart
class NutritionTrainingSync {
  // Ajustar calorías según volumen de entrenamiento
  CalorieAdjustment adjustForTrainingDay(DiaryEntry day, TrainingSession session) {
    // Día de piernas +500kcal vs día de brazos +100kcal
  }
  
  // Timing de comidas pre/post entreno
  MealTimingSuggestion suggestMealTiming(TrainingSession plannedSession) {
    // "Entrenas a las 18:00. Come carbohidratos 2h antes, proteína después"
  }
  
  // Detectar under-fueling (poca comida + entrenamiento de alta intensidad)
  bool detectUnderFueling();
}
```

**Diferenciador:** Hevy no tiene nutrición. MyFitnessPal no sabe tu entrenamiento.

---

#### 2.3 🎯 **Smart Workout Generator** (`workout_generator.dart`)

**Concepto:** Generar rutinas completas basadas en objetivos, tiempo disponible, y equipamiento.

**Features:**
```dart
class WorkoutGenerator {
  Rutina generateRoutine({
    required TrainingGoal goal, // Fuerza, hipertrofia, resistencia
    required int daysPerWeek,
    required int timePerSession, // minutos
    required List<String> availableEquipment,
    required List<String> injuries,
  }) {
    // Usar plantillas existentes + ajustes inteligentes
    // - Seleccionar split óptimo (PPL, Upper/Lower, Full Body)
    // - Distribuir volumen según recencia (músculos detrásados = más volumen)
    // - Seleccionar ejercicios por disponibilidad
  }
}
```

---

#### 2.4 📊 **Anomalías y Detección de Problemas** (`anomaly_detection.dart`)

**Concepto:** Detectar patrones preocupantes en el entrenamiento.

**Features:**
```dart
class AnomalyDetectionService {
  List<Anomaly> detectAnomalies() {
    return [
      // "Volumen aumentó 50% esta semana vs promedio - riesgo de lesión"
      // "RPE promedio subió de 7.5 a 9.2 en 2 semanas - sobreentrenamiento"
      // "Frecuencia de piernas bajó 40% - desbalance"
      // "Dormiste mal 3 noches seguidas y tu fuerza bajó 10%"
    ];
  }
}
```

---

### TIER 3: Alto Impacto / Alta Complejidad (12+ meses)

#### 3.1 🧬 **Programa Adaptativo Real-Time** (`adaptive_programming.dart`)

**Concepto:** La rutina cambia semanalmente basada en respuesta del usuario.

**Features:**
```dart
class AdaptiveProgramming {
  // Ajustar volumen semanal basado en MRV (Maximum Recoverable Volume) individual
  WeeklyVolume adjustVolume(String muscleGroup) {
    // Si usuario recupera bien = +1 set
    // Si RPE sube demasiado = -2 sets
    // Basado en: soreness, RPE, progreso, sueño (si disponible)
  }
  
  // Periodización auto-regulada
  void autoRegulate(Rutina routine) {
    // No es LP fijo, es DUP (Daily Undulating Periodization) automático
    // Día 1: 3x12, Día 2: 4x8, Día 3: 5x5 - basado en recuperación
  }
}
```

---

#### 3.2 🗣️ **NLP Avanzado para Voice** (`advanced_nlp_service.dart`)

**Concepto:** Entender contexto y ambigüedad en comandos de voz.

**Features:**
```dart
// Actual: "3 series de 10 a 80 kilos"
// Futuro: 
// - "Igual que la última vez" → busca historial
// - "Un poquito más pesado" → +2.5kg o +5kg según contexto
// - "Hasta el fallo" → detectar cuando deja de poder hacer reps
// - "Aumenta 2 discos" → sabe que disco = 2.5kg en máquinas, 20kg en olímpica
```

---

#### 3.3 🔄 **Transfer Learning entre Usuarios** (`federated_learning.dart`)

**Concepto:** Aprender de patrones anónimos de todos los usuarios para mejorar recomendaciones.

**Features:**
- Detectar: "Usuarios como tú (edad, peso, nivel) progresan mejor con X"
- Sistema de recomendación colaborativo para ejercicios
- Federated learning (privacidad preservada)

---

## 🛠️ Implementación Técnica

### Stack de IA Recomendado

| Tecnología | Uso | Complejidad |
|------------|-----|-------------|
| **tflite_flutter** | ML on-device (pose detection, predicciones) | Media |
| **TensorFlow.js** | Modelos en web companion | Media |
| **Firebase ML** | AutoML para clasificación de ejercicios | Baja |
| **Reglas deterministas** | 80% de las features actuales | Baja |
| **Algoritmos estadísticos** | Regresión lineal, moving averages | Baja |

### Arquitectura Propuesta

```
lib/training/services/ai/
├── ai_coach_service.dart           # Coach personalizado
├── pr_predictor_service.dart       # Predicción de PRs
├── smart_substitution_service.dart # Alternativas inteligentes
├── smart_rest_service.dart         # Timer adaptativo
├── auto_periodization_service.dart # Periodización auto
├── form_analysis_service.dart      # Análisis de forma (ML Kit)
├── anomaly_detection.dart          # Detección de anomalías
├── workout_generator.dart          # Generador de rutinas
└── models/
    ├── user_profile.dart           # Perfil de usuario para ML
    ├── training_response.dart      # Respuesta al entrenamiento
    └── prediction_models.dart      # Modelos de predicción
```

### Base de Datos ML

```sql
-- Tablas necesarias para ML
CREATE TABLE ml_user_profiles (
  id TEXT PRIMARY KEY,
  responder_type TEXT, -- 'high', 'medium', 'low' responder
  recovery_capacity INTEGER, -- 1-10
  volume_tolerance INTEGER, -- 1-10
  strength_endurance_ratio REAL, -- Fuerza vs resistencia
  updated_at DATETIME
);

CREATE TABLE training_responses (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  session_id TEXT,
  expected_progression REAL,
  actual_progression REAL,
  rpe_avg REAL,
  soreness_next_day INTEGER, -- 1-10
  sleep_quality INTEGER, -- 1-10 (opcional)
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE exercise_transfer_matrix (
  exercise_a TEXT,
  exercise_b TEXT,
  transfer_coefficient REAL, -- 0.0-1.0 (qué tan transferable es)
  PRIMARY KEY (exercise_a, exercise_b)
);
```

---

## 📈 Métricas de Éxito

| KPI | Target | Cómo Medir |
|-----|--------|------------|
| Adherencia al programa | +20% | Sesiones completadas / planificadas |
| PRs por mes | +15% | Conteo de nuevos récords |
| Estancamientos resueltos | 80% | Tiempo en plateau antes/después de AI |
| User satisfaction | 4.5★ | Encuesta: "El coach me ayudó" |
| Feature adoption | 60% | % usuarios que usan sugerencias IA |

---

## 🎯 Priorización Final

### Fase 1 (Próximos 3 meses)
1. **AI Coach básico** (reglas deterministas)
2. **PR Predictor** (regresión lineal simple)
3. **Smart Rest Timer** (fórmulas basadas en RPE)

### Fase 2 (3-6 meses)
4. **Smart Exercise Substitution**
5. **Anomalías Detection**
6. **Nutri-Training Integration** (ya tenemos nutrición)

### Fase 3 (6-12 meses)
7. **Workout Generator**
8. **Form Check básico** (ML Kit)
9. **NLP avanzado para voz**

### Fase 4 (12+ meses)
10. **Adaptive Programming real-time**
11. **Federated Learning**
12. **Periodización Automática completa**

---

## 💡 Diferenciadores Clave vs Competencia

| Feature | Juan Tracker | Hevy | Strong | Fitbod |
|---------|-------------|------|--------|--------|
| Coach IA | 🚀 **Planificado** | ❌ No | ❌ No | ✅ Sí (básico) |
| Progresión Auto | ✅ **Avanzada** | ❌ Manual | ❌ Manual | ✅ Automática |
| Error Tolerance | ✅ **Único** | ❌ No | ❌ No | ❌ No |
| Nutrición + Gym | ✅ **Integrado** | ❌ No | ❌ No | ❌ No |
| PR Predictor | 🚀 **Planificado** | ❌ No | ❌ No | ❌ No |
| Form Check | 🚀 **Planificado** | ❌ No | ❌ No | ❌ No |

**Conclusión:** Con estas features, Juan Tracker sería la app más inteligente del mercado, no solo un tracker.
