# Training Benchmark Matrix

> Análisis comparativo de conceptos de apps líderes de entrenamiento para evaluar mejoras en Juan Tracker Training.
>
> **Fecha:** 1 Febrero 2026  
> **Estado:** PHASE 1 - Discovery + Benchmark  
> **Metodología:** Solo features confirmadas de fuentes públicas (Play Store, sitios oficiales, reviews)

---

## 1. Apps Benchmarked

### 1.1 Strong (strong.app)
- **Categoría:** Workout logging puro
- **Rating:** 4.9★ (27K+ reviews Google Play)
- **Downloads:** 3M+
- **Fuente:** [strong.app](https://www.strong.app), [Google Play](https://play.google.com/store/apps/details?id=io.strongapp.strong)

**Features confirmadas:**
- Interface minimalista y rápida
- Auto Rest Timer con countdown popup
- Supersets / ejercicios agrupados
- Tag sets: Warmup, Failure, Drop Sets
- Plate Calculator
- Warm-up Calculator
- 1RM progression charts
- Custom exercises
- CSV export
- Apple Health / Google Fit sync
- Rutinas/templates

### 1.2 Boostcamp (boostcamp.app)
- **Categoría:** Programas estructurados
- **Rating:** 4.8★ (10K+ ratings App Store, 4.7★ Play Store)
- **Downloads:** 15M+
- **Fuente:** [boostcamp.app](https://www.boostcamp.app)

**Features confirmadas:**
- Programas de coaches expertos (GZCLP, nSuns, 5/3/1, etc.)
- Auto-progressions y weight recommendations
- Tracking avanzado con analytics
- Muscle engagement visualization
- Workout planning diario
- Community / Reddit integration (no social obligatorio)

### 1.3 Alpha Progression (alphaprogression.com)
- **Categoría:** AI/Algorithm-driven hypertrophy
- **Rating:** 4.7★+ (iOS/Android)
- **Fuente:** [alphaprogression.com](https://alphaprogression.com)

**Features confirmadas:**
- Plan generator 100% custom (>1,000 quadrillion combinations)
- Progression recommendations per-set
- RIR tracking
- Periodization y deloads automáticos
- 550+ exercises con videos
- Charts de progreso (1RM, volume, sets)
- Exercise evaluations (ROM, stability)

### 1.4 Hevy (hevy.com)
- **Categoría:** Social workout logging
- **Rating:** ~4.7★
- **Fuente:** Información limitada (sitio no detallado), reviews de usuarios

**Features inferidas de reviews/competitors:**
- Interface similar a Strong
- Social feed / sharing
- Rest timer
- Routine templates
- History tracking

---

## 2. Estado Actual de Juan Tracker Training

### ✅ Features Ya Implementadas

| Feature | Implementación | Archivo Principal |
|---------|----------------|-------------------|
| Logging peso/reps/RPE | ✅ Completo | `session_set_row.dart`, `log_input.dart` |
| Rest Timer + notificaciones | ✅ Completo | `rest_timer_controller.dart`, `timer_notification_service.dart` |
| Ghost values (historial inline) | ✅ Completo | `history` map en `TrainingState` |
| Tap ghost to copy | ✅ Completo | `onGhostTap` en `LogInput` |
| Superseries | ✅ Completo | `supersetId`, timer skip logic |
| Plate calculator | ✅ Completo | `plate_calculator_dialog.dart` |
| Add/Remove sets | ✅ Completo | `addSetToExercise()`, `removeSetFromExercise()` |
| Add exercise mid-session | ✅ Completo | `addExerciseToSession()` |
| Progression engine | ✅ Completo | `progression_engine.dart` (lineal, doble, RPE) |
| PR tracking | ✅ Completo | `getPersonalRecords()` en AnalyticsRepository |
| 1RM trend charts | ✅ Completo | `StrengthTrend` widget |
| Activity heatmap | ✅ Completo | `ActivityHeatmap` widget |
| Deload alerts | ✅ Completo | `DeloadAlertsWidget` |
| CSV export | ✅ Completo | `CsvExportService` |
| Warmup/Failure/Dropset tags | ✅ Completo | `isWarmup`, `isFailure`, `isDropset` en `SerieLog` |
| Validación tolerante | ✅ Completo | `ErrorToleranceRules` |
| OCR import | ✅ Completo | `RoutineOcrService` |
| Voice input | ✅ Completo | `VoiceInputService` |
| Scheduling modes | ✅ Completo | `sequential`, `weeklyAnchored`, `floatingCycle` |

### 🟡 Gaps Identificados

| Gap | Impacto UX | Complejidad |
|-----|------------|-------------|
| No hay "Copy Previous Set" one-tap | Alto | Bajo |
| No hay swipe-to-delete set con undo | Alto | Bajo |
| Swipe solo vertical en LogInput (no gestures en rows) | Medio | Bajo |
| No hay reorder de ejercicios en sesión | Medio | Medio |
| Timer UX podría ser más compacta | Bajo | Bajo |
| No hay collapse/expand rápido de ejercicios | Bajo | Ya existe (auto-collapse) |

---

## 3. Feature Benchmark Matrix

### Escala de Evaluación
- **User Value:** 1 (bajo) - 5 (crítico para UX diaria)
- **Complexity:** 1 (trivial) - 5 (arquitectura compleja)
- **ROI = Value / Complexity** (mayor = mejor candidato)
- **Offline:** Yes / Partial / No

---

### 3.1 Logging Speed & Session UX

| Concepto | Inspirado en | Qué hace | User Value | Complexity | Fit | Data Required | Risks | Offline | ROI | Status |
|----------|--------------|----------|------------|------------|-----|---------------|-------|---------|-----|--------|
| **Copy Previous Set (one-tap)** | Strong, Hevy | Botón en cada set para copiar peso/reps de la serie anterior | 5 | 1 | Strong | Ya existe `copyPreviousSet()` | Ninguno | Yes | **5.0** | 🎯 **CANDIDATO** |
| **Repeat Last Session** | Strong | Botón para copiar todos los sets del último workout del mismo ejercicio | 4 | 2 | Strong | Ya existe `history` map | Conflicto si estructura cambió | Yes | **2.0** | 🎯 **CANDIDATO** |
| **Swipe to Delete Set** | Strong, iOS patterns | Swipe left en set row → delete con undo | 4 | 1 | Strong | Ya existe `removeSetFromExercise()` | None | Yes | **4.0** | 🎯 **CANDIDATO** |
| **Swipe to Duplicate Set** | Strong | Swipe right → duplicate set | 3 | 1 | Strong | Ya existe `addSetToExercise()` | UX clutter | Yes | 3.0 | Opcional |
| **In-session Exercise Reorder** | Boostcamp | Drag & drop para reordenar ejercicios | 3 | 3 | Medium | Modificar `exercises` list | State complexity | Yes | 1.0 | Low ROI |
| **Numpad Quick Entry** | Strong | Modal numpad para entrada rápida | 3 | 2 | Medium | UI only | Ya existe parcialmente | Yes | 1.5 | Ya existe |
| **Previous Performance Inline** | Strong, Hevy | Mostrar "Last: 80kg × 10" visible sin interacción | 5 | 1 | Strong | Ya existe (`prevLog` ghost) | Ninguno | Yes | **5.0** | ✅ Ya existe |
| **Warm-up Set Suggestions** | Strong, Alpha | Auto-generar sets de calentamiento | 2 | 3 | Weak | Cálculo local | Complica UX | Yes | 0.67 | Low ROI |
| **Auto-fill from Template** | Strong | Al iniciar, pre-llenar peso/reps del último workout | 4 | 2 | Strong | Ya en `history` map | Opt-in preference | Yes | **2.0** | 🎯 **CANDIDATO** |

---

### 3.2 Rest Timer UX

| Concepto | Inspirado en | Qué hace | User Value | Complexity | Fit | Data Required | Risks | Offline | ROI | Status |
|----------|--------------|----------|------------|------------|-----|---------------|-------|---------|-----|--------|
| **Timer in Notification** | Strong | Countdown visible en lock screen | 5 | 3 | Strong | Ya implementado | None | Yes | 1.67 | ✅ Ya existe |
| **Skip/+30s from Notification** | Strong | Botones en notificación | 4 | 2 | Strong | Ya implementado | None | Yes | 2.0 | ✅ Ya existe |
| **Timer Auto-start on Complete** | Strong | Timer inicia automáticamente al marcar set | 4 | 1 | Strong | Ya implementado | None | Yes | 4.0 | ✅ Ya existe |
| **Haptic on Timer End** | - | Vibración fuerte al terminar | 3 | 1 | Strong | Ya implementado | None | Yes | 3.0 | ✅ Ya existe |
| **Compact Timer Bar** | Hevy | Timer más pequeño, menos intrusivo | 2 | 1 | Medium | UI only | Preferencia personal | Yes | 2.0 | Opcional |

---

### 3.3 Routine Editor UX

| Concepto | Inspirado en | Qué hace | User Value | Complexity | Fit | Data Required | Risks | Offline | ROI | Status |
|----------|--------------|----------|------------|------------|-----|---------------|-------|---------|-----|--------|
| **Exercise Search + Filters** | All apps | Buscar por nombre, filtrar por músculo/equipo | 4 | 2 | Strong | Biblioteca local | None | Yes | 2.0 | ✅ Ya existe |
| **Superset Grouping UI** | Strong, Boostcamp | Visual claro de superseries | 4 | 2 | Strong | Ya implementado | None | Yes | 2.0 | ✅ Ya existe |
| **Discard Changes Safety** | Best practice | Confirmar antes de perder cambios | 5 | 1 | Strong | Ya implementado | None | Yes | 5.0 | ✅ Ya existe |
| **Deep Copy on Edit** | Best practice | No mutar original hasta guardar | 5 | 2 | Strong | Ya implementado | None | Yes | 2.5 | ✅ Ya existe |

---

### 3.4 History & Insights

| Concepto | Inspirado en | Qué hace | User Value | Complexity | Fit | Data Required | Risks | Offline | ROI | Status |
|----------|--------------|----------|------------|------------|-----|---------------|-------|---------|-----|--------|
| **PR Tracking** | Strong, Alpha | Best weight for reps, estimated 1RM | 5 | 3 | Strong | Ya implementado | None | Yes | 1.67 | ✅ Ya existe |
| **Volume Trend Charts** | Alpha, Boostcamp | Gráfica de volumen semanal | 4 | 3 | Strong | Sessions data | None | Yes | 1.33 | ✅ Ya existe (StrengthTrend) |
| **Calendar Heatmap** | Strong, Hevy | Mapa de calor anual de actividad | 3 | 3 | Strong | Ya implementado | None | Yes | 1.0 | ✅ Ya existe |
| **Muscle Recovery Monitor** | Alpha | Días desde último entrenamiento por músculo | 3 | 2 | Strong | Ya implementado | None | Yes | 1.5 | ✅ Ya existe |
| **Streak Counter** | Gamification | Contador de racha de días | 3 | 2 | Strong | Ya implementado | None | Yes | 1.5 | ✅ Ya existe |

---

### 3.5 Program Structure (Boostcamp-style)

| Concepto | Inspirado en | Qué hace | User Value | Complexity | Fit | Data Required | Risks | Offline | ROI | Status |
|----------|--------------|----------|------------|------------|-----|---------------|-------|---------|-----|--------|
| **Multi-week Programs** | Boostcamp | Programa = semanas con días asignados | 3 | 4 | Medium | Nueva estructura DB | Scope creep | Yes | 0.75 | Fuera de alcance |
| **Auto-progression per Program** | Boostcamp, Alpha | Reglas de progresión por programa | 3 | 4 | Medium | Ya existe por ejercicio | Duplicación | Yes | 0.75 | Ya existe (por ejercicio) |
| **Periodization/Deloads** | Alpha | Ciclos con deload programado | 2 | 4 | Weak | Training blocks | Complejidad | Yes | 0.5 | ✅ Ya existe (TrainingBlock) |
| **Pre-made Program Library** | Boostcamp | Biblioteca de programas populares | 2 | 5 | Weak | Content creation | Mantenimiento | Yes | 0.4 | Fuera de alcance |

---

## 4. Resumen de Candidatos por ROI

### 🎯 Alta Prioridad (ROI ≥ 2.0, sin implementar)

| # | Feature | ROI | Complexity | Status Actual |
|---|---------|-----|------------|---------------|
| 1 | **Copy Previous Set (one-tap)** | 5.0 | 1 | `copyPreviousSet()` existe pero no hay UI dedicada |
| 2 | **Swipe to Delete Set** | 4.0 | 1 | `removeSetFromExercise()` existe, UI via long-press |
| 3 | **Repeat Last Session / Auto-fill** | 2.0 | 2 | `history` existe, no hay UI para auto-fill |

### ✅ Ya Implementado (no requiere trabajo)

- Previous performance inline (ghost values)
- Timer notifications con Skip/+30s
- Plate calculator
- Warm-up/Failure/Dropset tags
- PR tracking
- 1RM charts
- Heatmap
- Deload alerts
- Discard changes safety

### ❌ Descartado (bajo ROI o fuera de alcance)

- Multi-week programs (complexity: 4, value: 3)
- Pre-made program library (requiere content, mantenimiento)
- In-session exercise reorder (complexity sin beneficio claro)

---

## 5. Análisis de Gaps Críticos

### Gap 1: UX de "Copy Previous Set"

**Estado actual:**
- `copyPreviousSet(exerciseIndex, setIndex)` existe en `TrainingSessionNotifier`
- Solo copia de la serie anterior (índice-1), no del historial
- No hay botón visible en UI; ghost values requieren tap

**Oportunidad:**
- Añadir botón explícito "↻" en cada `SessionSetRow` para copiar historial
- Tap en ghost ya funciona, pero no es discoverable

**Impacto:** Alto - feature #1 más solicitada en apps de gym

---

### Gap 2: Swipe Actions en Set Rows

**Estado actual:**
- `removeSetFromExercise()` existe, activado via long-press > confirmar
- Swipe vertical existe en `LogInput` para ±peso/reps
- No hay swipe horizontal para delete/duplicate

**Oportunidad:**
- `Dismissible` widget con `direction: DismissDirection.endToStart` para delete
- Undo via SnackBar (patrón ya usado en otras partes de la app)

**Impacto:** Alto - reduce fricción significativamente

---

### Gap 3: Auto-fill desde Historial

**Estado actual:**
- `history` map contiene últimos logs por ejercicio
- Sets inician en 0kg × 0 reps (vacíos)
- Ghost values muestran qué poner, pero no pre-llenan

**Oportunidad:**
- Opción en settings: "Pre-llenar peso/reps del último workout"
- Al iniciar sesión, copiar `history[exerciseKey]` a `logs`

**Impacto:** Medio-Alto - ahorra ~20 taps por sesión típica

---

## 6. Fuentes y Referencias

### Documentación Oficial
- [Strong App](https://www.strong.app) - Features confirmadas
- [Strong Play Store](https://play.google.com/store/apps/details?id=io.strongapp.strong) - Rating 4.1★, 1M+ downloads
- [Boostcamp](https://www.boostcamp.app) - Features confirmadas
- [Alpha Progression](https://alphaprogression.com) - Features confirmadas

### Reviews Citadas
- The Verge: "With apps like Strong, working out feels more like a game"
- CNBC: "I'd suggest downloading the Strong app before you return to the gym"
- Lifehacker: "Strong is the clear winner. It's easy to use, even when you're exhausted mid-workout"
- CNET: "A variety of strength-tracking apps exist. Strong is the best one I've tried."

### Metodología
- Solo features verificables de fuentes públicas
- No se asumen features sin evidencia
- Priorización por ROI = User Value / Complexity
- Offline-first como requisito base

---

*Última actualización: Febrero 2026*
