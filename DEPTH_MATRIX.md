# DEPTH MATRIX - Juan Tracker Feature Evaluation

> **Fecha de evaluación**: 2026-01-30
> **Versión analizada**: Post-Fase 2 (Coach Fixes + TDEE Integration)
> **Framework**: "Easy to Learn, Hard to Master" - Power Layer Audit

---

## CONTEXTO FILOSÓFICO

La capa superficial (casual) está optimizada ✅. Este documento audita la **capa de poder** (Power Layer):
- ¿Existen las herramientas que un culturista de 5 años necesita pero un newbie no ve en su camino?
- ¿El acceso a lo profundo es "descubrible" (intuitivo tras uso prolongado) pero no "intrusivo"?
- ¿Hay "icebergs de funcionalidad" (10% visible, 90% accesible mediante gestures, long-press, o settings contextuales)?

---

## FASE 1: ARQUITECTURA DE PROFUNDIDAD (Progressive Disclosure Audit)

### El Dilema del Iceberg

#### SURFACE LAYER (Casual) - Lo que ve el nuevo usuario

| Acción | Implementación | Discoverability | Evaluación |
|--------|----------------|-----------------|------------|
| "Iniciar entrenamiento" | Training tab → FAB "Iniciar" | ✅ Prominente | ÓPTIMO |
| "Añadir comida" | Diary tab → FAB "+" por meal | ✅ Prominente | ÓPTIMO |
| "Ver progreso básico" | Summary tab | ✅ Visible en nav | ÓPTIMO |
| "Registrar peso" | Weight screen → FAB | ✅ Material Design | ÓPTIMO |
| Meta de peso | Profile setup | ✅ Onboarding flow | ÓPTIMO |
| Calorías aproximadas | Coach plan setup | ✅ Guided wizard | ÓPTIMO |

**Diagnóstico Surface Layer**: ✅ **BIEN DISEÑADO** - Acciones core son obvias y accesibles.

---

#### MID LAYER (Engaged) - El puente crítico (1-2 semanas de uso)

| Expectativa | Estado Actual | Cómo se descubre | Evaluación |
|-------------|---------------|------------------|------------|
| Ajustar % de macros sin ir a settings globales | ⚠️ PARCIAL | Coach setup tiene presets, pero editar % requiere saber que existe "Custom" | MEJORABLE |
| Long-press en ejercicio → opciones avanzadas (RM, historial, notas) | ❌ NO EXISTE | No hay long-press contextual | GAP CRÍTICO |
| Swipe en set para "fail set" | ❌ NO EXISTE | Solo checkbox visible | GAP CRÍTICO |
| Double-tap para "warmup set" | ❌ NO EXISTE | Requiere expandir opciones | GAP CRÍTICO |
| Ver tendencia de peso tras 1 semana | ✅ EXISTE | Weight screen muestra trend automáticamente | ÓPTIMO |
| Suggestions de progresión | ⚠️ OCULTO | Progression Engine corre pero no muestra sugerencias en UI | GAP CRÍTICO |

**Anti-patterns detectados en Mid Layer**:

| Anti-pattern | ¿Presente? | Evidencia |
|--------------|------------|-----------|
| **"Settings Cemetery"** | ⚠️ PARCIAL | Settings tiene opciones mezcladas (rest time junto a theme) sin categorización clara |
| **"Wizard Hell"** | ✅ NO | Coach setup permite skip, no fuerza tutorial |
| **"Feature Hiding"** | ⚠️ SÍ | Progression Engine, Bad Day flag, Deload alerts existen pero son invisibles |

**Diagnóstico Mid Layer**: ⚠️ **PUENTE ROTO** - Features avanzadas existen pero el usuario engaged no las descubre naturalmente.

---

#### DEEP LAYER (Master) - El toolkit del atleta avanzado

| Capacidad | Estado | Accesibilidad | Evaluación |
|-----------|--------|---------------|------------|
| **Periodización** (lineal, undulating, conjugate) | ❌ NO EXISTE | N/A | GAP CRÍTICO |
| **Manejo de fatiga** (RIR/RPE) | ✅ EXISTE | Input en cada set, opcional | OCULTO |
| **Volume landmarks** (MEV/MRV) | ❌ NO EXISTE | N/A | GAP CRÍTICO |
| **Datos exportables** (CSV para Excel) | ⚠️ PARCIAL | JSON export existe, CSV básico | MEJORABLE |
| **Automatizaciones** (IF ganó fuerza THEN sube peso) | ✅ EXISTE | Progression Engine automático | INVISIBLE |
| **1RM tracking** | ✅ EXISTE | Epley/Brzycki en strength analysis | OCULTO |
| **Trend analysis 6+ meses** | ✅ EXISTE | Kalman + Holt-Winters | TÉCNICAMENTE OCULTO |
| **Detección de plateaus** | ✅ EXISTE | Phase detection en weight + strength | OCULTO |

**Diagnóstico Deep Layer**: ⚠️ **FUNCIONALIDAD FANTASMA** - Mucho poder técnico existe pero está enterrado sin affordances visibles.

---

### RESUMEN FASE 1: Mapa de Progressive Disclosure

```
                    ┌─────────────────────────────────────┐
   SURFACE          │  ✅ Iniciar entreno  ✅ Add food    │
   (Visible)        │  ✅ Ver summary      ✅ Log weight  │
                    ├─────────────────────────────────────┤
   MID LAYER        │  ⚠️ Macro %         ❌ Long-press   │
   (Discoverable?)  │  ⚠️ Progression     ❌ Gestures     │
                    ├─────────────────────────────────────┤
   DEEP LAYER       │  ❌ Periodización   ✅ RPE (oculto) │
   (Power tools)    │  ✅ Kalman (oculto) ❌ MEV/MRV      │
                    │  ✅ 1RM (oculto)    ⚠️ Export       │
                    └─────────────────────────────────────┘

PROBLEMA CENTRAL: Las capas están desconectadas.
No hay "rampas" del Mid al Deep layer.
```

---

## FASE 2: DIMENSIÓN HORIZONTAL - BREADTH AUDIT

### 1. ANÁLISIS DE DATOS AVANZADO

| Feature | Estado | Profundidad | Notas |
|---------|--------|-------------|-------|
| **Gráficos tendencia largo plazo (6+ meses)** | ✅ EXISTE | 5/5 | Kalman + Holt-Winters + regression lineal |
| **Líneas de regresión** | ✅ EXISTE | 4/5 | Implementado en `strength_analysis_service.dart` |
| **Detección automática de plateaus** | ✅ EXISTE | 4/5 | Phase detection (improving/plateau/declining) |
| **Correlación sueño/performance** | ❌ NO | 0/5 | Sin integración con wearables |
| **Correlación calorías/fuerza** | ❌ NO | 0/5 | Diet y training no están conectados |
| **Correlación volumen/fatiga** | ⚠️ PARCIAL | 2/5 | Recovery monitor existe pero sin tracking de fatiga acumulada |
| **Export CSV/Excel** | ⚠️ PARCIAL | 3/5 | JSON completo, CSV básico, sin filtros |
| **Export para R/Python** | ❌ NO | 0/5 | No hay formato específico |
| **API para Google Sheets** | ❌ NO | 0/5 | No implementado |

**Score Análisis de Datos**: 2.2/5 (Funcionalidad existe pero no es accesible/útil para power user)

---

### 2. PERIODIZACIÓN & PROGRAMACIÓN INTELIGENTE

| Feature | Estado | Profundidad | Notas |
|---------|--------|-------------|-------|
| **Block periodization** | ❌ NO | 0/5 | Sin concepto de bloques/mesociclos |
| **Daily Undulating Periodization (DUP)** | ⚠️ WORKAROUND | 1/5 | Posible creando 3 días diferentes manualmente |
| **Conjugate method** | ❌ NO | 0/5 | Sin rotación de variantes |
| **RPE input** | ✅ EXISTE | 4/5 | 1-10 scale por set, opcional |
| **RIR (Reps in Reserve)** | ⚠️ IMPLÍCITO | 2/5 | RPE 8 = 2 RIR, no UI dedicada |
| **Velocidad de barra (VBT)** | ❌ NO | 0/5 | Sin integración hardware |
| **Deload automático** | ⚠️ PARCIAL | 3/5 | Detección existe (`deload_alerts_provider`), sin scheduling |
| **Peaking protocols** | ❌ NO | 0/5 | Sin templates de competición |
| **Mesociclo templates** | ❌ NO | 0/5 | Sin templates predefinidos |

**Score Periodización**: 1.1/5 (GAP CRÍTICO - Bloquea usuarios avanzados)

---

### 3. NUTRICIÓN DE PRECISIÓN

| Feature | Estado | Profundidad | Notas |
|---------|--------|-------------|-------|
| **Ciclos dietéticos** (bulk/cut phases) | ✅ EXISTE | 4/5 | Coach plan con goal (lose/maintain/gain) |
| **Refeed days automáticos** | ❌ NO | 0/5 | Sin lógica de refeeds |
| **Diet breaks** | ❌ NO | 0/5 | Sin programación de pausas |
| **Nutrient timing** (carbs peri-workout) | ❌ NO | 0/5 | Sin distribución temporal |
| **Adaptive TDEE** | ⚠️ PARCIAL | 3/5 | Weekly check-in ajusta, pero solo Mifflin base |
| **Metabolic adaptation detection** | ⚠️ PARCIAL | 2/5 | Coach detecta stalls pero no "metabolic adaptation" |
| **Suplementación tracking** | ❌ NO | 0/5 | No existe |
| **Creatina/cafeína timing** | ❌ NO | 0/5 | No existe |
| **Macro cycling** (high/low carb days) | ❌ NO | 0/5 | Targets son fijos por día |

**Score Nutrición Precisión**: 1.0/5 (Coach básico existe, features avanzadas missing)

---

### 4. CUSTOMIZACIÓN TÉCNICA

| Feature | Estado | Profundidad | Notas |
|---------|--------|-------------|-------|
| **Tempo prescriptions** (4010, pausa) | ❌ NO | 0/5 | Sin campo tempo |
| **Partial reps** | ❌ NO | 0/5 | Sin flag |
| **Drop sets** | ✅ EXISTE | 3/5 | Flag en `SerieLog` |
| **Rest-pause sets** | ❌ NO | 0/5 | Sin flag |
| **Myo-reps** | ❌ NO | 0/5 | Sin concepto |
| **Equipment profiles** (gym A vs B) | ❌ NO | 0/5 | Single equipment set |
| **Injury mode** (sustituciones automáticas) | ❌ NO | 0/5 | No existe |
| **Exercise alternatives mapping** | ❌ NO | 0/5 | No hay equivalencias definidas |
| **Custom exercise notes** | ✅ EXISTE | 3/5 | Notes en ejercicio |
| **Form cues/técnica** | ⚠️ PARCIAL | 2/5 | Description en library, no personalizable |

**Score Customización Técnica**: 0.8/5 (Muy básico para power user)

---

### 5. WORKFLOW EFFICIENCY (Power User UX)

| Feature | Estado | Profundidad | Notas |
|---------|--------|-------------|-------|
| **Routine templates** | ⚠️ PARCIAL | 2/5 | Puede crear rutinas pero no hay biblioteca |
| **iOS/Android widget** | ❌ NO | 0/5 | No implementado |
| **Acceso directo "último ejercicio"** | ❌ NO | 0/5 | No existe |
| **Batch edit (múltiples sets)** | ❌ NO | 0/5 | Edit individual only |
| **Duplicar días entre semanas** | ❌ NO | 0/5 | No existe |
| **Voice commands** | ✅ EXISTE | 4/5 | "Registrar 100kg banco" funciona |
| **Keyboard shortcuts** | ❌ NO | 0/5 | No implementado |
| **Undo/redo** | ❌ NO | 0/5 | No existe |
| **Copy last session** | ⚠️ PARCIAL | 2/5 | Progression sugiere, no "copy" directo |

**Score Workflow Efficiency**: 0.9/5 (Voice es excelente, resto missing)

---

### RESUMEN FASE 2: Heat Map de Breadth

```
                        PROFUNDIDAD IMPLEMENTADA
                    0    1    2    3    4    5
                    ├────┼────┼────┼────┼────┤
Análisis Datos      │████████████░░░░░░░░░░░│ 2.2/5
Periodización       │████░░░░░░░░░░░░░░░░░░░│ 1.1/5  ← CRÍTICO
Nutrición Precisión │████░░░░░░░░░░░░░░░░░░░│ 1.0/5  ← CRÍTICO
Customización       │███░░░░░░░░░░░░░░░░░░░░│ 0.8/5  ← CRÍTICO
Workflow UX         │███░░░░░░░░░░░░░░░░░░░░│ 0.9/5  ← CRÍTICO
                    └────────────────────────┘

DIAGNÓSTICO: Breadth muy limitada en 4 de 5 categorías power-user.
```

---

## FASE 3: DIMENSIÓN VERTICAL - DEPTH AUDIT

### Feature: WEIGHT TREND ANALYSIS

| Nivel | Capacidad | Estado | Score |
|-------|-----------|--------|-------|
| 1 - Basic | Log peso manual | ✅ | ██████████ |
| 2 - Intermediate | Gráfico de historial | ✅ | ██████████ |
| 3 - Advanced | Moving average (EMA 7d) | ✅ | ██████████ |
| 4 - Expert | Multi-model (Holt-Winters + Kalman) | ✅ | ██████████ |
| 5 - Master | Fusion con confidence + phase detection | ✅ | ██████████ |

**Profundidad Total**: 5/5 ✅ **EXCELENTE** - Feature más profunda de la app.

---

### Feature: PROGRESSION ENGINE

| Nivel | Capacidad | Estado | Score |
|-------|-----------|--------|-------|
| 1 - Basic | Registro manual de progreso | ✅ | ██████████ |
| 2 - Intermediate | Historial por ejercicio | ✅ | ██████████ |
| 3 - Advanced | Linear progression automática | ✅ | ██████████ |
| 4 - Expert | 4 modelos (Linear, Double, RPE, None) + state machine | ✅ | ██████████ |
| 5 - Master | Stall detection + deload auto + confirmation logic | ✅ | ██████████ |

**Profundidad Total**: 5/5 ✅ **EXCELENTE** - Comparable a apps premium.

**PROBLEMA**: Profundidad 5/5 pero Discoverability 1/5. Usuario no sabe que existe.

---

### Feature: FOOD LOGGING

| Nivel | Capacidad | Estado | Score |
|-------|-----------|--------|-------|
| 1 - Basic | Add manual (nombre + kcal) | ✅ | ██████████ |
| 2 - Intermediate | Search en database | ✅ | ██████████ |
| 3 - Advanced | Barcode scan + API (Open Food Facts) | ✅ | ██████████ |
| 4 - Expert | OCR de etiquetas + fuzzy matching | ✅ | ██████████ |
| 5 - Master | Habitual foods + caching inteligente | ✅ | ██████████ |

**Profundidad Total**: 5/5 ✅ **EXCELENTE**

---

### Feature: SESSION TRACKING

| Nivel | Capacidad | Estado | Score |
|-------|-----------|--------|-------|
| 1 - Basic | Log sets (peso × reps) | ✅ | ██████████ |
| 2 - Intermediate | Rest timer + sets múltiples | ✅ | ██████████ |
| 3 - Advanced | RPE + flags (warmup, dropset, failure) | ✅ | ██████████ |
| 4 - Expert | Voice input + real-time validation | ✅ | ██████████ |
| 5 - Master | Bad day flag + session evaluation + persistence | ✅ | ██████████ |

**Profundidad Total**: 5/5 ✅ **EXCELENTE**

---

### Feature: ADAPTIVE COACH (Diet)

| Nivel | Capacidad | Estado | Score |
|-------|-----------|--------|-------|
| 1 - Basic | Set calorie target manually | ✅ | ██████████ |
| 2 - Intermediate | TDEE calculation (Mifflin) | ✅ | ██████████ |
| 3 - Advanced | Goal-based targets (lose/maintain/gain) | ✅ | ██████████ |
| 4 - Expert | Weekly check-in con convergence logic | ✅ | ██████████ |
| 5 - Master | Refeed detection + diet break scheduling | ❌ | ░░░░░░░░░░ |

**Profundidad Total**: 4/5 ⚠️ **MUY BUENO** - Falta nivel master.

---

### Feature: PERIODIZATION

| Nivel | Capacidad | Estado | Score |
|-------|-----------|--------|-------|
| 1 - Basic | Crear rutina multi-día | ✅ | ██████████ |
| 2 - Intermediate | Templates por objetivo | ❌ | ░░░░░░░░░░ |
| 3 - Advanced | Block programming (mesociclos) | ❌ | ░░░░░░░░░░ |
| 4 - Expert | DUP / Conjugate automático | ❌ | ░░░░░░░░░░ |
| 5 - Master | Auto-regulation + peaking protocols | ❌ | ░░░░░░░░░░ |

**Profundidad Total**: 1/5 ❌ **GAP CRÍTICO**

---

### Feature: EXERCISE LIBRARY

| Nivel | Capacidad | Estado | Score |
|-------|-----------|--------|-------|
| 1 - Basic | Lista de ejercicios predefinidos | ✅ | ██████████ |
| 2 - Intermediate | Search + filtros (músculo, equipo) | ✅ | ██████████ |
| 3 - Advanced | Custom exercises + aliases | ✅ | ██████████ |
| 4 - Expert | Notas técnicas personalizadas | ⚠️ | █████░░░░░ |
| 5 - Master | Exercise alternatives + substitution rules | ❌ | ░░░░░░░░░░ |

**Profundidad Total**: 3.5/5 ⚠️ **BUENO** - Falta nivel 4-5.

---

### Feature: ANALYTICS DASHBOARD

| Nivel | Capacidad | Estado | Score |
|-------|-----------|--------|-------|
| 1 - Basic | Session history list | ✅ | ██████████ |
| 2 - Intermediate | Activity heatmap | ✅ | ██████████ |
| 3 - Advanced | Strength trending + 1RM estimation | ✅ | ██████████ |
| 4 - Expert | Recovery monitor + muscle symmetry | ✅ | ██████████ |
| 5 - Master | Cross-module correlations + predictive insights | ❌ | ░░░░░░░░░░ |

**Profundidad Total**: 4/5 ⚠️ **MUY BUENO** - Falta conexión cross-module.

---

### Feature: DATA EXPORT

| Nivel | Capacidad | Estado | Score |
|-------|-----------|--------|-------|
| 1 - Basic | Ver datos en app | ✅ | ██████████ |
| 2 - Intermediate | Share session individual | ✅ | ██████████ |
| 3 - Advanced | Export JSON/CSV batch | ✅ | ██████████ |
| 4 - Expert | Filtros por ejercicio/fecha + formato elegible | ❌ | ░░░░░░░░░░ |
| 5 - Master | API access + integración spreadsheets | ❌ | ░░░░░░░░░░ |

**Profundidad Total**: 3/5 ⚠️ **ACEPTABLE** - Falta poder para data analysts.

---

### RESUMEN FASE 3: Depth Scorecard

```
FEATURE                      DEPTH    DISCOVERABILITY   RESULTADO
────────────────────────────────────────────────────────────────
Weight Trend Analysis        5/5 ✅    3/5 ⚠️           OCULTO
Progression Engine           5/5 ✅    1/5 ❌           FANTASMA
Food Logging                 5/5 ✅    5/5 ✅           ÓPTIMO
Session Tracking             5/5 ✅    4/5 ✅           BUENO
Adaptive Coach               4/5 ⚠️    4/5 ✅           BUENO
Periodization                1/5 ❌    N/A              NO EXISTE
Exercise Library             3.5/5⚠️   4/5 ✅           ACEPTABLE
Analytics Dashboard          4/5 ⚠️    3/5 ⚠️           OCULTO
Data Export                  3/5 ⚠️    2/5 ❌           ENTERRADO
────────────────────────────────────────────────────────────────
PROMEDIO                     3.8/5     2.9/5

PROBLEMA: Features profundas (5/5) tienen baja discoverability.
         Features visibles tienen profundidad media (3/5).
```

---

## ESCALA DE PROFUNDIDAD (1-5)

| Nivel | Nombre | Descripción | Ejemplo |
|-------|--------|-------------|---------|
| **1** | Casual | Entrada manual básica, sin análisis | Contador de calorías simple |
| **2** | Enthusiast | Tracking histórico + tendencias simples | MyFitnessPal básico |
| **3** | Committed | Análisis multi-modelo, sugerencias smart | MacroFactor nivel medio |
| **4** | Advanced | Motores de decisión determinísticos, auto-ajuste | Gravitus/RP Hypertrophy |
| **5** | Master | Periodización compleja, meta-programming | Spreadsheets custom de coach |

---

## INVENTARIO DE FEATURES POR NIVEL

### MÓDULO: DIET/NUTRICIÓN

| Feature | Nivel Actual | Nivel Target | Gap | Notas |
|---------|--------------|--------------|-----|-------|
| **Food Logging** | 4 | 4 | ✅ | OCR + barcode + Open Food Facts API |
| **Búsqueda de alimentos** | 4 | 4 | ✅ | Fuzzy search + cache + heurísticas |
| **Quick Add** | 2 | 2 | ✅ | Solo nombre + macros manuales |
| **Meal Categorization** | 2 | 3 | ⚠️ | 4 comidas fijas, no personalizable |
| **Portion Tracking** | 3 | 4 | ⚠️ | Falta conversión automática entre unidades |
| **Weight Tracking** | 5 | 5 | ✅ | EMA + Holt-Winters + Kalman Filter |
| **Trend Analysis** | 5 | 5 | ✅ | Multi-model fusion + phase detection |
| **Macro Targets** | 3 | 4 | ⚠️ | Versioning ok, falta cycling (carb cycling) |
| **Calorie Targets** | 3 | 4 | ⚠️ | Sin ajuste automático por día de entreno |
| **Daily Summary** | 3 | 3 | ✅ | Budget-style progress cards |
| **Adaptive Coach** | 4 | 5 | ⚠️ | Falta refeed detection, diet break logic |
| **Weekly Check-in** | 4 | 4 | ✅ | Convergence logic + deload detection |
| **TDEE Estimation** | 3 | 4 | ⚠️ | Solo Mifflin-St Jeor, falta adaptive TDEE |
| **Meal Planning** | 0 | 3 | ❌ | NO IMPLEMENTADO |
| **Recipe Builder** | 0 | 3 | ❌ | NO IMPLEMENTADO |
| **Macro Cycling** | 0 | 4 | ❌ | NO IMPLEMENTADO (high/low days) |

**Promedio Módulo Diet**: 3.1/5 (Committed+)

---

### MÓDULO: TRAINING/ENTRENAMIENTO

| Feature | Nivel Actual | Nivel Target | Gap | Notas |
|---------|--------------|--------------|-----|-------|
| **Exercise Library** | 4 | 4 | ✅ | 200+ ejercicios + custom + aliases |
| **Routine Creation** | 4 | 5 | ⚠️ | Multi-day ok, falta templates por objetivo |
| **Routine Import (OCR)** | 4 | 4 | ✅ | ML Kit + fuzzy matching |
| **Session Tracking** | 5 | 5 | ✅ | Real-time + voice + validation |
| **Set Logging** | 4 | 4 | ✅ | Weight/reps/RPE/flags (warmup, dropset) |
| **RPE Tracking** | 3 | 4 | ⚠️ | Manual entry, sin calibración individual |
| **Rest Timer** | 4 | 4 | ✅ | Lock screen + audio + haptics |
| **Volume Calculation** | 3 | 4 | ⚠️ | Total volume ok, falta per-muscle breakdown |
| **Superseries** | 3 | 3 | ✅ | Grouping funcional |
| **Progression Engine** | 5 | 5 | ✅ | 4 modelos: Linear, Double, RPE, None |
| **Stall Detection** | 4 | 4 | ✅ | 3 failures = deload |
| **Plateau Detection** | 4 | 4 | ✅ | 3 weeks same weight |
| **Voice Input** | 4 | 5 | ⚠️ | Funcional pero falta offline mode |
| **Periodization** | 1 | 5 | ❌ | NO IMPLEMENTADO (mesociclos, DUP) |
| **Deload Programming** | 2 | 4 | ⚠️ | Detección ok, no auto-schedule |
| **1RM Estimation** | 3 | 4 | ⚠️ | Epley/Brzycki ok, falta velocity-based |
| **Program Templates** | 0 | 4 | ❌ | NO IMPLEMENTADO |
| **Block Programming** | 0 | 5 | ❌ | NO IMPLEMENTADO |

**Promedio Módulo Training**: 3.3/5 (Committed++)

---

### MÓDULO: ANALYTICS

| Feature | Nivel Actual | Nivel Target | Gap | Notas |
|---------|--------------|--------------|-----|-------|
| **Session History** | 4 | 4 | ✅ | Stream-based, real-time |
| **Activity Heatmap** | 4 | 4 | ✅ | Calendar visualization |
| **Strength Trending** | 5 | 5 | ✅ | Kalman + Holt-Winters + regression |
| **Phase Detection** | 4 | 4 | ✅ | Improving/plateau/declining |
| **Recovery Monitor** | 4 | 4 | ✅ | Per-muscle status |
| **Muscle Symmetry** | 4 | 4 | ✅ | Radar chart |
| **Hall of Fame (PRs)** | 3 | 4 | ⚠️ | Básico, falta trending PRs |
| **Deload Alerts** | 3 | 4 | ⚠️ | Detección ok, no actionable |
| **Data Export** | 3 | 4 | ⚠️ | Training JSON/CSV ok, diet incompleto |
| **Cross-Module Analytics** | 0 | 4 | ❌ | NO IMPLEMENTADO |
| **Sleep/Recovery Import** | 0 | 4 | ❌ | NO IMPLEMENTADO (Whoop, Garmin) |
| **Adherence Metrics** | 2 | 3 | ⚠️ | Compliance básico |

**Promedio Módulo Analytics**: 3.0/5 (Committed)

---

### MÓDULO: UX/INFRAESTRUCTURA

| Feature | Nivel Actual | Nivel Target | Gap | Notas |
|---------|--------------|--------------|-----|-------|
| **Theme System** | 2 | 3 | ⚠️ | Light/dark ok, sin high-contrast |
| **Information Density** | 2 | 4 | ❌ | Una sola vista, no toggle compact/detailed |
| **Keyboard Shortcuts** | 0 | 3 | ❌ | NO IMPLEMENTADO |
| **Bulk Edit Mode** | 0 | 4 | ❌ | NO IMPLEMENTADO |
| **Undo/Redo** | 0 | 3 | ❌ | NO IMPLEMENTADO |
| **Offline Mode** | 1 | 3 | ❌ | SQLite local pero sin sync |
| **Cloud Backup** | 0 | 3 | ❌ | NO IMPLEMENTADO |
| **Widget (Android)** | 0 | 3 | ❌ | NO IMPLEMENTADO |

**Promedio Módulo UX**: 0.6/5 (Casual)

---

## RESUMEN EJECUTIVO: DEPTH VS BREADTH

```
                    BREADTH (# features)
                    Low         Medium        High
                    ┌─────────────────────────────┐
        High (5)    │                             │
                    │                             │
        Medium (3)  │      ★ JUAN TRACKER        │
DEPTH               │      (3.0 avg, 40+ features)│
                    │                             │
        Low (1)     │                             │
                    └─────────────────────────────┘

Diagnóstico: "ANCHA PERO CON PICOS"
- Training Session + Weight Trending: Nivel 5 (Master)
- Food Logging + Progression Engine: Nivel 4 (Advanced)
- Analytics + Coach: Nivel 3-4 (Committed+)
- Periodization + Cross-module: Nivel 0-1 (Inexistente)
```

---

## FASE 4: COGNITIVE WALKTHROUGH - 3 ARQUETIPOS

### PERSONA A: "El Periodizador" (Culturista 3+ años)

**Escenario**: Preparando fase de volumen de 12 semanas con periodización DUP.

| Paso | Flujo Esperado | ¿Posible en Juan Tracker? | Workaround | Fricción |
|------|----------------|---------------------------|------------|----------|
| 1 | Definir mesociclo (4 sem acumulación + 1 intensidad + 1 deload) | ❌ NO | Crear 3 rutinas separadas y cambiar manualmente | ALTA |
| 2 | Configurar DUP: L(3-5), M(8-12), V(1-3@85%) | ⚠️ PARCIAL | Crear días diferentes en misma rutina | MEDIA |
| 3 | Regla progresión: "Si RPE≤8, sube 2.5kg" | ✅ SÍ | Progression Engine con RPE-based | BAJA |
| 4 | Gráfico volumen semanal (tonelaje) | ⚠️ PARCIAL | Activity Heatmap muestra intensidad, no tonelaje detallado | MEDIA |

**Evaluación Persona A**:
- **Taps para configurar semana tipo**: ~45-60 taps (crear rutina + 3 días + ejercicios + sets)
- **Pueden hacer el flujo completo**: ❌ NO sin workarounds significativos
- **Missing crítico**: Periodization module, mesocycle templates, auto-deload scheduling

**Recomendación**: Implementar concepto de "Bloques" con fechas de inicio/fin y objetivos por bloque.

---

### PERSONA B: "El Data Analyst" (Powerlifter científico)

**Escenario**: Analizando estancamiento en press de banca con datos granulares.

| Paso | Flujo Esperado | ¿Posible en Juan Tracker? | Workaround | Fricción |
|------|----------------|---------------------------|------------|----------|
| 1 | Exportar 6 meses de bench: peso × reps × RPE × descanso × fecha | ⚠️ PARCIAL | Export JSON tiene data, pero no granular por ejercicio | MEDIA |
| 2 | Cruzar con datos de sueño (Whoop/Garmin) | ❌ NO | No hay importación de wearables | ALTA |
| 3 | Identificar correlación sueño ↔ RPE | ❌ NO | Sin cross-module analytics | ALTA |
| 4 | Ajuste automático volumen post-mala noche | ❌ NO | No hay reglas condicionales | ALTA |

**Evaluación Persona B**:
- **App como "fuente de verdad" rica**: ⚠️ PARCIAL (rich data model, poor export/analysis)
- **Data granularity**: ✅ BUENA (sets individuales con timestamps, RPE, flags)
- **Missing crítico**: External data import, SQL-style queries, conditional rules

**Recomendación**:
1. Implementar export CSV con filtros por ejercicio/fecha
2. API de integración con Health Connect / Apple Health
3. "Smart Rules" builder: IF condition THEN action

---

### PERSONA C: "El Coach" (Entrena a otros o planifica con complejidad)

**Escenario**: Gestionar múltiples fases y biblioteca de ejercicios custom.

| Paso | Flujo Esperado | ¿Posible en Juan Tracker? | Workaround | Fricción |
|------|----------------|---------------------------|------------|----------|
| 1 | Crear biblioteca de ejercicios custom con notas técnicas | ✅ SÍ | Exercise library soporta custom exercises | BAJA |
| 2 | Programar bloques de 4 semanas con diferentes objetivos | ❌ NO | Múltiples rutinas sin linking temporal | ALTA |
| 3 | Comparar progreso entre versiones pasadas de sí mismo | ⚠️ PARCIAL | Session history existe, no hay comparison view | MEDIA |
| 4 | Ajuste dinámico: "Si pierde fuerza 2 sem → cambiar ejercicio" | ❌ NO | Sin auto-substitution rules | ALTA |

**Evaluación Persona C**:
- **Flexibilidad extrema**: ⚠️ LIMITADA (flexible per-session, no per-block)
- **Multi-athlete support**: ❌ NO (single user app)
- **Missing crítico**: Block programming, exercise substitution rules, progress comparison

**Recomendación**:
1. "Training Blocks" con objetivos definidos y auto-progression rules
2. "Compare" mode para ver lado a lado períodos diferentes
3. Exercise alternatives mapping para auto-substitution

---

## FASE 5: MATRIZ DISCOVERABILITY VS UTILIDAD

### Clasificación de Features Existentes

#### ✅ HIGH UTILITY + HIGH DISCOVERABILITY (Ideal)

| Feature | Ubicación | Por qué funciona |
|---------|-----------|------------------|
| Food Logging | Diary Screen principal | CTA prominente, flujo intuitivo |
| Session Start | Training tab → "Iniciar" | Botón grande y claro |
| Weight Entry | Weight screen → FAB | Patrón Material Design estándar |
| Rest Timer | Durante sesión | Aparece automáticamente post-set |
| Daily Summary | Tab dedicado | Visible en navegación principal |

#### ⚠️ HIGH UTILITY + LOW DISCOVERABILITY (Enterradas - PRIORIDAD MOVER)

| Feature | Ubicación Actual | Problema | Recomendación |
|---------|------------------|----------|---------------|
| **Progression Engine** | Automático en background | Usuario no sabe que existe | Mostrar "Sugerencia de hoy" en session start |
| **RPE Tracking** | Input opcional en set | Muchos no lo ven | Tooltip educativo primera vez |
| **Weight Trend Phase** | Dentro de Weight screen | Solo visible si scrolleas | Badge en home: "Fase: Perdiendo 0.3kg/sem" |
| **Deload Alerts** | Provider sin UI visible | Feature fantasma | Notification + banner en Analysis |
| **Exercise Aliases** | Solo en search backend | Usuario no puede agregar | "Agregar alias" en exercise detail |
| **Bad Day Flag** | Long press en session | Nadie lo descubre | Tutorial/onboarding |
| **Focus Mode** | Settings → Training | Escondido en settings | Toggle visible durante sesión |

#### ❌ LOW UTILITY + HIGH DISCOVERABILITY (Feature Bloat - MOVER A AVANZADO)

| Feature | Problema | Recomendación |
|---------|----------|---------------|
| **4 Progression Types** | Casual user confused by options | Default to "Auto" (linear), advanced settings for others |
| **Kalman Filter toggle** | Demasiado técnico para UI | Esconder en "Advanced Analytics" |
| **Multiple trend algorithms** | Confusing output | Single "Smart Trend" que use fusion internally |

#### 🗑️ LOW UTILITY + LOW DISCOVERABILITY (Candidatos a eliminar/simplificar)

| Feature | Evaluación | Acción |
|---------|-----------|--------|
| *No se identificaron features en esta categoría* | - | - |

---

## FASE 6: "MAESTRO INVISIBLE" - UX DE PODER

### 1. ACCELERATORS (Atajos para expertos)

| Accelerator | Estado | Implementación Sugerida |
|-------------|--------|-------------------------|
| **Keyboard shortcuts (tablet)** | ❌ No existe | `Ctrl+N` nuevo ejercicio, `Ctrl+S` guardar sesión |
| **Shake to undo** | ❌ No existe | Undo último set loggeado |
| **Long press → bulk edit** | ❌ No existe | Selección múltiple de sets para editar RPE/flags |
| **Swipe gestures** | ⚠️ Parcial | Swipe left to delete existe, falta swipe right to duplicate |
| **Double tap to complete** | ❌ No existe | Double tap set → mark as done with last values |
| **Voice commands** | ✅ Existe | Ya implementado para session creation |

### 2. SMART DEFAULTS CON OVERRIDE

| Área | Default Casual | Override Avanzado | Estado |
|------|----------------|-------------------|--------|
| **Set config** | 3×10 | 5×3@85% + backoff | ⚠️ Parcial (no backoff sets) |
| **Rest time** | 90s | Per-exercise custom | ✅ Implementado |
| **Progression** | Linear | DUP / Block periodization | ❌ No existe |
| **Weight units** | kg | kg/lbs toggle | ✅ Implementado |
| **RPE** | Hidden | Always show | ⚠️ Setting existe pero no granular |

### 3. META-PROGRAMMING (Reglas IF-THEN)

| Regla | Estado | Complejidad |
|-------|--------|-------------|
| "Si RPE≤8 todas series → +2.5kg" | ✅ Implementado | Progression Engine |
| "Si peso baja >0.5kg/sem → +10% carbs" | ❌ No existe | Requiere diet-training linking |
| "Si fallo 3 semanas → auto-deload" | ✅ Implementado | Stall detection |
| "Si benchmark mejora → unlock next block" | ❌ No existe | Requiere block programming |
| "Notificar si no entreno en 3 días" | ❌ No existe | Requiere notification rules |

### 4. INFORMATION DENSITY TOGGLE

| Vista | Estado | Implementación |
|-------|--------|----------------|
| **Compact mode** (más datos/pantalla) | ❌ No existe | Reducir padding, font size, hide images |
| **Detailed mode** (más espacio) | ✅ Default actual | - |
| **Data tables** vs **Cards** | ❌ Solo cards | Toggle para ver sesiones en tabla |
| **Mini widgets** | ❌ No existe | Resumen colapsable en home |

---

## MATRIZ DE PRIORIZACIÓN: ACCIONES RECOMENDADAS

### PRIORIDAD CRÍTICA (Bloquean power users)

| # | Acción | Impacto | Esfuerzo | Módulo |
|---|--------|---------|----------|--------|
| 1 | **Block Programming** - Definir mesociclos con objetivos | Persona A, C | Alto | Training |
| 2 | **Surfacing Progression** - Mostrar sugerencias en UI | Persona A, B | Bajo | Training |
| 3 | **Export granular** - CSV por ejercicio con filtros | Persona B | Medio | Analytics |
| 4 | **Information Density Toggle** | Todos power users | Medio | UX |

### PRIORIDAD ALTA (Mejoran significativamente)

| # | Acción | Impacto | Esfuerzo | Módulo |
|---|--------|---------|----------|--------|
| 5 | **Health Connect Integration** | Persona B | Alto | Analytics |
| 6 | **Smart Rules Builder** | Persona B, C | Alto | Core |
| 7 | **Training-Diet Linking** | Persona A, B | Medio | Cross-module |
| 8 | **Bulk Edit Mode** | Todos | Medio | UX |

### PRIORIDAD MEDIA (Nice to have)

| # | Acción | Impacto | Esfuerzo | Módulo |
|---|--------|---------|----------|--------|
| 9 | Keyboard shortcuts | Tablet users | Bajo | UX |
| 10 | Shake to undo | All | Bajo | UX |
| 11 | Android widget | Casual+ | Medio | UX |
| 12 | Exercise comparison view | Persona C | Medio | Analytics |

---

## CONCLUSIÓN: DIAGNÓSTICO FINAL

### Fortalezas (Moat Técnico)
1. **Weight Trending**: Nivel Master (Kalman + Holt-Winters fusion) - Diferenciador vs competencia
2. **Progression Engine**: Nivel Master (4 algoritmos, state machine) - Comparable a apps $$$
3. **Voice Input**: Nivel Advanced (STT + fuzzy matching) - Único en categoría
4. **Data Model**: Expert-level granularity (sets, RPE, flags, timestamps)

### Debilidades (Gaps Críticos)
1. **Periodization**: Nivel 0 - Bloquea culturistas serios
2. **Cross-module Analytics**: Nivel 0 - No conecta training ↔ diet ↔ recovery
3. **Meta-programming**: Nivel 1 - Sin reglas personalizables beyond progression
4. **UX Power Features**: Nivel 0-1 - Sin accelerators ni density toggle

### Perfil de Usuario Ideal (Actual)
> **"Intermediate lifter que trackea macros y quiere progresión automática"**
> - Nivel 2-3 de experiencia
> - No necesita periodización compleja
> - Aprecia voice input y OCR
> - Usa app como diario, no como sistema de programación

### Perfil de Usuario Target (Post-mejoras)
> **"Advanced lifter o coach que programa bloques y analiza datos"**
> - Nivel 4-5 de experiencia
> - Necesita periodización y auto-ajustes
> - Quiere exportar datos a spreadsheets
> - Usa app como sistema de decisiones, no solo logging

---

## PRÓXIMOS PASOS

1. **Fase Inmediata**: Surfacing de features existentes (Progression suggestions en UI, badges de fase)
2. **Fase Corta**: Information density toggle + export mejorado
3. **Fase Media**: Block programming MVP + Health Connect
4. **Fase Larga**: Smart Rules builder + cross-module analytics

---

*Documento generado para evaluación de profundidad de features siguiendo el marco "Easy to Learn, Hard to Master"*
