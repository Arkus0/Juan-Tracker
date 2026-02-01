# Training System Map

> Mapa técnico del módulo Training en Juan Tracker.
> Generado: Febrero 2026

---

## 1. Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              TRAINING MODULE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────┐                  │
│  │   SCREENS   │───▶│   PROVIDERS  │───▶│  REPOSITORIES  │                  │
│  │  (Flutter)  │    │  (Riverpod)  │    │    (Drift)     │                  │
│  └─────────────┘    └──────────────┘    └────────────────┘                  │
│         │                  │                    │                            │
│         ▼                  ▼                    ▼                            │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────┐                  │
│  │   WIDGETS   │    │   SERVICES   │    │   DATABASE     │                  │
│  │  (session/) │    │ (timer, etc) │    │  (SQLite/Drift)│                  │
│  └─────────────┘    └──────────────┘    └────────────────┘                  │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Modelo de Datos

### 2.1 Esquema de Base de Datos (Drift, Schema v11)

| Tabla | Descripción | Campos Clave |
|-------|-------------|--------------|
| `Routines` | Rutinas del usuario | `id`, `name`, `schedulingMode`, `schedulingConfig` |
| `RoutineDays` | Días dentro de una rutina | `routineId`, `name`, `progressionType`, `weekdays`, `minRestHours` |
| `RoutineExercises` | Ejercicios en cada día | `dayId`, `libraryId`, `series`, `repsRange`, `progressionType`, `weightIncrement`, `targetRpe`, `supersetId` |
| `Sessions` | Sesiones completadas | `id`, `routineId`, `dayName`, `startTime`, `durationSeconds`, `isBadDay`, `completedAt` |
| `SessionExercises` | Ejercicios en sesión | `sessionId`, `libraryId`, `name`, `musclesPrimary`, `exerciseIndex` |
| `WorkoutSets` | Series registradas | `sessionExerciseId`, `weight`, `reps`, `completed`, `rpe`, `isFailure`, `isDropset`, `isWarmup`, `restSeconds` |
| `ExerciseNotes` | Notas por ejercicio | `exerciseName`, `note` |

### 2.2 Modelos de Dominio

```
lib/training/models/
├── rutina.dart              # Rutina con días, bloques, scheduling
├── dia.dart                 # Día de entrenamiento con ejercicios
├── ejercicio_en_rutina.dart # Ejercicio template (EjercicioEnRutina)
├── ejercicio.dart           # Ejercicio en sesión activa (Ejercicio)
├── serie_log.dart           # Serie individual (SerieLog)
├── sesion.dart              # Sesión completada (Sesion)
├── library_exercise.dart    # Ejercicio de biblioteca
├── rest_timer_state.dart    # Estado del timer
├── progression_type.dart    # Enum: none, lineal, dobleRepsFirst, rpe
└── progression_engine_models.dart # ProgressionDecision, etc.
```

**Relaciones clave:**
```
Rutina ──1:N──▶ Dia ──1:N──▶ EjercicioEnRutina
                                    │
                                    ▼ (al iniciar sesión)
TrainingState.exercises ─────▶ Ejercicio ──1:N──▶ SerieLog
                                    │
                                    ▼ (al guardar)
Sesion ──1:N──▶ Ejercicio (ejerciciosCompletados)
```

---

## 3. State Management (Riverpod 3)

### 3.1 Provider Principal: `TrainingSessionNotifier`

**Archivo:** `lib/training/providers/training_provider.dart`

```dart
class TrainingState {
  final Rutina? activeRutina;
  final String? dayName;
  final int? dayIndex;
  final List<Ejercicio> exercises;    // Working copy con logs
  final List<Ejercicio> targets;      // Snapshot de targets (rutina original)
  final DateTime? startTime;
  final int defaultRestSeconds;
  final RestTimerState restTimer;
  final Map<String, List<SerieLog>> history;  // Ghost values
  final bool showAdvancedOptions;
  final bool showTimerBar;
}
```

**Métodos principales:**
| Método | Función |
|--------|---------|
| `startSession()` | Inicia sesión desde rutina |
| `updateLog()` | Actualiza peso/reps/RPE de una serie |
| `copyPreviousSet()` | Copia serie anterior (índice-1) |
| `addSetToExercise()` | Añade serie a ejercicio durante sesión |
| `removeSetFromExercise()` | Elimina serie (con límite mínimo de 1) |
| `addExerciseToSession()` | Añade ejercicio de biblioteca |
| `startRest()` / `stopRest()` | Control del timer de descanso |
| `finishSession()` | Guarda sesión y limpia estado |

### 3.2 Providers Clave

```dart
// Core
trainingRepositoryProvider          // ITrainingRepository (Drift impl)
trainingSessionProvider             // TrainingSessionNotifier (sesión activa)

// Streams
rutinasStreamProvider               // Stream<List<Rutina>>
sesionesHistoryStreamProvider       // Stream<List<Sesion>> (limit: 50)
activeSessionStreamProvider         // Stream<ActiveSessionData?>

// Paginación
sesionesHistoryPaginatedProvider    // StreamProvider.family<List<Sesion>, int>
historyPaginationProvider           // Notifier<int> para página actual

// Análisis
analysisTabIndexProvider            // Tab actual (Historial/Estadísticas)
yearlyActivityProvider              // Heatmap data
streakDataProvider                  // Racha de entrenamiento
muscleRecoveryProvider              // Recuperación muscular
strengthTrendProvider               // Tendencia de fuerza por ejercicio

// Progresión
progressionProvider                 // ProgressionSuggestion para ejercicio actual
progressionControllerProvider       // Control de progresiones

// UI State
focusManagerProvider                // Auto-focus en siguiente set
sessionProgressProvider             // Progreso de sesión (% completado)
settingsProvider                    // Configuración de entrenamiento
```

---

## 4. Flujos de Navegación

### 4.1 Flujo: Iniciar Entrenamiento

```
TrainingShell (main_screen.dart)
    │
    ├── [Tap "Entrenar"] ──▶ TrainSelectionScreen
    │                            │
    │                            ├── Seleccionar rutina
    │                            ├── Seleccionar día
    │                            │
    │                            ▼
    │                       TrainingSessionScreen
    │                            │
    │                            ├── Log sets (ExerciseCard → SessionSetRow)
    │                            ├── Timer automático (RestTimerBar)
    │                            ├── Añadir ejercicio/serie
    │                            │
    │                            ▼
    │                       [Finalizar] ──▶ finishSession()
    │                            │
    │                            ▼
    │                       HistoryScreen (sesión guardada)
```

### 4.2 Flujo: Editar Rutina

```
RutinasScreen
    │
    ├── [Tap rutina] ──▶ CreateEditRoutineScreen (rutina: existente)
    │                        │
    │                        ├── DiaExpansionTile × N días
    │                        │       │
    │                        │       └── EjercicioCard × N ejercicios
    │                        │
    │                        ├── [+] ──▶ BibliotecaBottomSheet
    │                        │             └── Buscar/seleccionar ejercicio
    │                        │
    │                        ├── [Guardar] ──▶ saveRutina()
    │                        │
    │                        └── [Back sin guardar] ──▶ _confirmExit() dialog
```

---

## 5. Servicios Clave

### 5.1 Timer de Descanso

| Archivo | Clase | Responsabilidad |
|---------|-------|-----------------|
| `rest_timer_controller.dart` | `RestTimerController` | Lógica de timer, superseries, persistencia |
| `timer_notification_service.dart` | `TimerNotificationService` | Notificación Android con countdown |
| `timer_audio_service.dart` | `TimerAudioService` | Beeps de finalización |
| `native_beep_service.dart` | `NativeBeepService` | ToneGenerator nativo (no just_audio) |

**Flujo del timer:**
```
Completar serie → shouldStartTimerForSuperset() → startRest(seconds)
                        │                               │
                        │ (si es superset, no iniciar)  ▼
                        │                        RestTimerController
                        │                               │
                        ▼                               ▼
              Continuar al siguiente         TimerNotificationService
              ejercicio del superset         (notificación lock screen)
```

### 5.2 Motor de Progresión

| Archivo | Clase | Descripción |
|---------|-------|-------------|
| `progression_engine.dart` | `ProgressionEngine` | Motor de progresión determinista v2 |
| `progression_calculator.dart` | `ProgressionCalculator` | Cálculos 1RM, PRs |

**Modelos de progresión:**
- `none` - Sin progresión automática
- `lineal` - Subir peso fijo cada sesión
- `dobleRepsFirst` - Subir reps hasta max, luego peso (estilo Lyle McDonald)
- `rpe` - Basado en RPE objetivo

### 5.3 Tolerancia a Errores

| Archivo | Clase | Descripción |
|---------|-------|-------------|
| `error_tolerance_system.dart` | `ErrorToleranceRules` | Validación de peso (detecta errores de dedo) |
| `defensive_input_validation_service.dart` | - | Validación defensiva |

---

## 6. Widgets de Sesión

```
lib/training/widgets/session/
├── exercise_card.dart          # Card principal por ejercicio
├── session_set_row.dart        # Fila individual de serie (peso/reps/check)
├── log_input.dart              # Input numérico con ghost values y swipe
├── rest_timer_bar.dart         # Barra del timer (sticky bottom)
├── rest_timer_panel.dart       # Panel expandido del timer
├── progression_suggestion_chip.dart # Chip con sugerencia de progresión
├── session_progress_bar.dart   # Barra de progreso de sesión
├── session_modifiers.dart      # AddSetButton, etc.
├── quick_actions_menu.dart     # Menu FAB con acciones rápidas
├── focused_set_row.dart        # Set row en modo focus
└── numpad_input_modal.dart     # Modal numpad para input rápido
```

---

## 7. Características Existentes ✅

| Feature | Estado | Implementación |
|---------|--------|----------------|
| Logging de peso/reps/RPE | ✅ | `SessionSetRow`, `LogInput` |
| Timer de descanso | ✅ | `RestTimerController`, notificaciones Android |
| Superseries | ✅ | `supersetId` en `EjercicioEnRutina`, lógica de timer |
| Ghost values (historial inline) | ✅ | `history` map en `TrainingState`, `prevLog` en UI |
| Tap para copiar ghost value | ✅ | `onGhostTap` en `LogInput` |
| Añadir serie | ✅ | `addSetToExercise()` |
| Eliminar serie | ✅ | `removeSetFromExercise()` (mínimo 1) |
| Añadir ejercicio en sesión | ✅ | `addExerciseToSession()` |
| Progresión automática | ✅ | `ProgressionEngine` (lineal, doble, RPE) |
| PR tracking | ✅ | `AnalyticsRepository.getPersonalRecords()` |
| Heatmap calendario | ✅ | `ActivityHeatmap` widget |
| Tendencia de fuerza | ✅ | `StrengthTrend` widget con 1RM estimado |
| Alerta de deload | ✅ | `DeloadAlertsWidget` |
| Export CSV | ✅ | `CsvExportService` |
| OCR import rutinas | ✅ | `RoutineOcrService` |
| Voz input | ✅ | `VoiceInputService` |
| Plate calculator | ✅ | `PlateCalculatorDialog` |
| Alternativas ejercicio | ✅ | `AlternativasService` |
| Auto-scroll a siguiente set | ✅ | `focusManagerProvider` |
| Validación tolerante | ✅ | `ErrorToleranceRules` |
| Día malo flag | ✅ | `isBadDay` en `Sessions` |
| Scheduling modes | ✅ | `sequential`, `weeklyAnchored`, `floatingCycle` |

---

## 8. Potenciales Hotspots de Performance

| Área | Riesgo | Mitigación Actual |
|------|--------|-------------------|
| Lista de ejercicios larga | Medio | `ListView.builder`, no virtualizado |
| Rebuilds de `ExerciseCard` | Bajo | `==` / `hashCode` en modelos |
| Ghost values lookup | Bajo | `Map<String, List<SerieLog>>` en memoria |
| Historial grande | Medio | Paginación (`historyPaginationProvider`) |
| Timer con streams | Bajo | `StreamSubscription` limpiadas en dispose |

---

## 9. Archivos Clave para Referencia

### Data Layer
- `lib/training/database/database.dart` - Esquema Drift
- `lib/training/repositories/drift_training_repository.dart` - Repo principal
- `lib/training/repositories/session_repository.dart` - Lógica de sesiones

### State Layer
- `lib/training/providers/training_provider.dart` - `TrainingSessionNotifier`
- `lib/training/providers/analysis_provider.dart` - Providers de análisis

### UI Layer
- `lib/training/screens/training_session_screen.dart` - Pantalla principal
- `lib/training/widgets/session/exercise_card.dart` - Card de ejercicio
- `lib/training/widgets/session/session_set_row.dart` - Row de serie
- `lib/training/widgets/session/log_input.dart` - Input numérico

### Services
- `lib/training/services/rest_timer_controller.dart` - Timer
- `lib/training/services/progression_engine.dart` - Motor de progresión

---

*Última actualización: Febrero 2026*
