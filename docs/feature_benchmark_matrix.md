# Feature Benchmark Matrix

> Análisis comparativo de conceptos de apps líderes en fitness/nutrición para evaluar implementación en Juan Tracker.
> 
> **Fecha:** 1 Febrero 2026  
> **Autor:** GitHub Copilot  
> **Estado:** PHASE 1 - Discovery

---

## 1. Resumen del Estado Actual de Juan Tracker

### ✅ Features Ya Implementadas

| Feature | Estado | Notas |
|---------|--------|-------|
| Adaptive TDEE | ✅ Completo | `AdaptiveCoachService` - Calcula TDEE real basado en ingesta + cambio de peso |
| Weight Trend Smoothing | ✅ Completo | `WeightTrendCalculator` - EMA, Holt-Winters, Kalman, Regresión Lineal |
| Check-in Workflow | ✅ Completo | `WeeklyCheckInScreen` - Ajustes automáticos con transparencia de cálculos |
| Smart Food Suggestions | ✅ Completo | `habitualFoodProvider` - Detección de patrones con 40% umbral |
| Barcode Scanning | ✅ Completo | `mobile_scanner` + Open Food Facts API |
| FTS5 Search | ✅ Completo | Búsqueda local + híbrida con OFF |
| Recipe Model | ✅ Modelo | `RecipeModel` existe pero sin UI de builder |
| Macro Presets | ✅ Completo | `MacroPreset` enum con distribuciones predefinidas |
| Phase Detection | ✅ Completo | `WeightPhase` - losing/maintaining/gaining |

### 🟡 Gaps Identificados

| Gap | Impacto | Complejidad |
|-----|---------|-------------|
| No hay goal line/ETA en charts | Alto | Bajo |
| No hay proyección visual de peso | Alto | Bajo |
| No hay meal templates (comidas guardadas) | Medio | Medio |
| No hay resúmenes semanales históricos | Medio | Medio |
| No hay visualización de adherencia | Bajo | Bajo |

---

## 2. Feature Benchmark Matrix

### Escala de Evaluación
- **User Value:** 1 (bajo) - 5 (crítico)
- **Complexity:** 1 (trivial) - 5 (muy complejo)
- **ROI Score:** User Value / Complexity (mayor = mejor)

---

### 2.1 MacroFactor-like Features

| Concepto | User Value | Complexity | Data Requirements | Privacy Risk | Offline | Fit | Dependencies | ROI | Status |
|----------|------------|------------|-------------------|--------------|---------|-----|--------------|-----|--------|
| **Dynamic TDEE Estimation** | 5 | 4 | weighIns + diaryEntries | Low | Yes | ✅ IMPLEMENTED | None | 1.25 | ✅ Ya existe |
| **Goal Forecasting (ETA)** | 4 | 2 | weighIns + goal + trend | Low | Yes | Strong | None | **2.0** | 🎯 **CANDIDATO** |
| **Check-in Workflow** | 5 | 4 | weighIns + diary + plan | Low | Yes | ✅ IMPLEMENTED | None | 1.25 | ✅ Ya existe |
| **Food Logging Speed (Recents/Favorites)** | 4 | 2 | diaryEntries + foods | Low | Yes | Strong | None | **2.0** | 🎯 **CANDIDATO** |
| **Macro Flexibility Ranges** | 3 | 3 | targets | Low | Yes | Medium | None | 1.0 | Pendiente |
| **Trend Weight Smoothing** | 5 | 4 | weighIns | Low | Yes | ✅ IMPLEMENTED | None | 1.25 | ✅ Ya existe |

---

### 2.2 FatSecret-like Features

| Concepto | User Value | Complexity | Data Requirements | Privacy Risk | Offline | Fit | Dependencies | ROI | Status |
|----------|------------|------------|-------------------|--------------|---------|-----|--------------|-----|--------|
| **Barcode Logging** | 4 | 3 | OFF API + local cache | Low | Partial | ✅ IMPLEMENTED | mobile_scanner | 1.33 | ✅ Ya existe |
| **Quick Meal Templates** | 3 | 3 | recipes table + UI | Low | Yes | Medium | None | 1.0 | Pendiente |
| **Recipe Builder (Offline)** | 3 | 4 | recipes + recipeItems | Low | Yes | Medium | None | 0.75 | Bajo ROI |
| **Weekly History Insights** | 4 | 2 | diaryEntries agregados | Low | Yes | Strong | None | **2.0** | 🎯 **CANDIDATO** |

---

### 2.3 Libra-like Features

| Concepto | User Value | Complexity | Data Requirements | Privacy Risk | Offline | Fit | Dependencies | ROI | Status |
|----------|------------|------------|-------------------|--------------|---------|-----|--------------|-----|--------|
| **Weight Trend Smoothing** | 5 | 4 | weighIns | Low | Yes | ✅ IMPLEMENTED | None | 1.25 | ✅ Ya existe |
| **Goal Line + ETA** | 4 | 2 | goal + trend | Low | Yes | Strong | None | **2.0** | 🎯 **CANDIDATO** |
| **Water Retention Smoothing** | 2 | 3 | weighIns + ML opcional | Low | Yes | Weak | None | 0.67 | Bajo valor |
| **Adherence Visualization** | 3 | 2 | diaryEntries | Low | Yes | Strong | None | 1.5 | Opcional |

---

### 2.4 Yuka-like Features

| Concepto | User Value | Complexity | Data Requirements | Privacy Risk | Offline | Fit | Dependencies | ROI | Status |
|----------|------------|------------|-------------------|--------------|---------|-----|--------------|-----|--------|
| **Product Score** | 3 | 5 | Nutri-Score/NOVA + claims | **HIGH** | No | Weak | Legal review | 0.6 | ⛔ OUT OF SCOPE |
| **Ingredient Flags** | 2 | 4 | Ingredient database | **HIGH** | No | Weak | Data license | 0.5 | ⛔ OUT OF SCOPE |
| **Scanning Feedback** | 2 | 3 | OFF nutriScore/novaGroup | Medium | Partial | Medium | None | 0.67 | Bajo prioridad |

---

## 3. Análisis de Candidatos

### 🎯 TOP CANDIDATES (ROI ≥ 2.0)

#### A. Goal Forecasting (Weight Projection + ETA)
```
User Value: 4 | Complexity: 2 | ROI: 2.0
```

**Qué hace:**
- Muestra una línea de objetivo en el gráfico de peso
- Calcula y muestra ETA (fecha estimada para alcanzar peso objetivo)
- Actualiza proyección basándose en el trend actual (ya calculado por Holt-Winters)

**Por qué es ideal:**
- Ya tenemos `hwPrediction7d/30d` y `hwTrend` en `WeightTrendResult`
- Ya tenemos `WeightGoal` y `weeklyRateKg` en `CoachPlan`
- Solo necesitamos **UI nueva**, no lógica de cálculo
- Libra es famoso por esta feature - alto impacto percibido

**Integración:**
1. Nuevo provider: `goalProjectionProvider` que combina CoachPlan + WeightTrendResult
2. UI: Línea punteada en `_WeightLineChart`
3. UI: Card de "Meta" con ETA en `weight_screen.dart`

---

#### B. Food Logging Speed (Recents + Quick-Add)
```
User Value: 4 | Complexity: 2 | ROI: 2.0
```

**Qué hace:**
- Muestra alimentos recientes en la parte superior de búsqueda
- Quick-add para alimentos frecuentes con cantidad predeterminada
- Botón de "repetir comida de ayer"

**Por qué es ideal:**
- Ya tenemos `recentSearchesProvider` y `habitualFoodProvider`
- Ya tenemos `foods.lastUsedAt` y `foods.useCount`
- Solo necesitamos **UI nueva**

**Integración:**
1. UI: Chips de recientes encima de búsqueda
2. UI: Botón "Repetir ayer" en DiaryScreen
3. Nuevo provider: `yesterdayMealsProvider`

---

#### C. Weekly History Insights
```
User Value: 4 | Complexity: 2 | ROI: 2.0
```

**Qué hace:**
- Vista de resumen semanal (total kcal, promedio, adherencia)
- Comparación semana vs semana
- Mini-charts de evolución

**Por qué es ideal:**
- Ya tenemos datos en `diaryEntries`
- Solo necesitamos agregación y nueva UI
- Complementa el check-in semanal existente

**Integración:**
1. Nuevo provider: `weeklyInsightsProvider`
2. Nueva screen: `WeeklyHistoryScreen` o tab en Summary

---

## 4. Hard Gate Analysis

### ⛔ REJECTED - Out of Scope

| Feature | Reason | Risk |
|---------|--------|------|
| Yuka Product Scoring | Requiere claims nutricionales = riesgo legal | HIGH |
| Yuka Ingredient Flags | Requiere base de datos de aditivos con licencia | HIGH |
| Account/Sync | Requiere infraestructura de servidor | OUT OF SCOPE |
| Social Features | Requiere moderación y GDPR compliance | OUT OF SCOPE |
| Premium/Payments | No hay infraestructura de pagos | OUT OF SCOPE |

### 🟡 DEFERRED - Lower Priority

| Feature | Reason | When |
|---------|--------|------|
| Recipe Builder UI | ROI 0.75, modelo ya existe | v2.0 |
| Macro Flexibility Ranges | ROI 1.0, nice-to-have | v1.5 |
| Water Retention Smoothing | ROI 0.67, valor cuestionable | Maybe never |
| Meal Templates | ROI 1.0, requiere más diseño UX | v1.5 |

---

## 5. Decision Memo

### ✅ IMPLEMENTAR AHORA (PR2)

**Feature:** Goal Forecasting (Weight Projection + ETA)

**Justificación:**
1. **ROI Alto (2.0):** Máximo valor con mínima complejidad
2. **Fit Perfecto:** Ya tenemos TODA la lógica necesaria:
   - `WeightTrendResult.hwTrend` - velocidad actual kg/día
   - `WeightTrendResult.predictWeight(days)` - proyección Holt-Winters
   - `CoachPlan.goal` y `weeklyRateKg` - objetivo del usuario
3. **Solo UI:** No requiere cambios de modelo, DB, o servicios
4. **Diferenciador:** Libra es la app de referencia para esto - alto impacto visual
5. **Offline-First:** 100% local, sin dependencias externas

**Scope de Implementación:**
- Nuevo provider: `goalProjectionProvider` → `GoalProjection` model
- UI: Goal line (dashed) en weight chart
- UI: ETA card con fecha estimada
- UI: Mensaje de progreso ("X días para tu meta")
- Tests: Unit tests para cálculo de ETA

### 🟡 CONSIDERAR DESPUÉS (PR3 - Si PR2 es estable)

**Feature:** Food Logging Speed (Recents Quick-Add)

**Justificación:**
- Ya tenemos los providers necesarios
- Alta mejora en UX diaria
- Requiere solo UI work

---

## 6. Implementation Roadmap

### Phase 1: Goal Forecasting (Este PR)

```
1. Model: GoalProjection
   ├── goalWeightKg: double
   ├── currentTrendWeight: double
   ├── projectedWeightKg(days): double
   ├── estimatedDaysToGoal: int?
   ├── goalDate: DateTime?
   └── progressPercentage: double

2. Provider: goalProjectionProvider
   ├── Inputs: CoachPlan + WeightTrendResult
   └── Output: GoalProjection?

3. UI: WeightScreen enhancements
   ├── Goal line in chart (dashed)
   ├── ETA card ("Meta: 75kg en ~45 días")
   └── Progress indicator

4. Tests
   ├── goal_projection_test.dart
   └── Update weight_screen_test.dart
```

### Phase 2: Food Logging Speed (Siguiente PR)

```
1. Provider: yesterdayMealsProvider
2. UI: Recents chips in FoodSearchUnifiedScreen
3. UI: "Repetir ayer" button in DiaryScreen
```

### Phase 3: Weekly Insights (Backlog)

```
1. Provider: weeklyInsightsProvider
2. Screen: WeeklyHistoryScreen
3. Integration with SummaryScreen
```

---

## 7. Quality Checklist for Implementation

- [ ] **No jank:** Cálculos de proyección ya están en `WeightTrendResult` (off-UI)
- [ ] **Deterministic:** ETA se calcula con fórmula simple: `deltaPeso / trenDaily`
- [ ] **Transparent:** Mostrar "basado en tu ritmo actual de X kg/semana"
- [ ] **Safe defaults:** Si no hay goal o datos insuficientes → no mostrar ETA
- [ ] **Tests:** Unit tests para `GoalProjection` calculations
- [ ] **Docs:** `docs/feature_goal_projection.md`

---

*Última actualización: 1 Febrero 2026*
