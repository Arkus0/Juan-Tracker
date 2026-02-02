# Feature Benchmark Matrix

> Análisis comparativo de conceptos de apps líderes en fitness/nutrición para evaluar implementación en Juan Tracker.
> 
> **Fecha:** 15 Febrero 2026  
> **Autor:** GitHub Copilot  
> **Estado:** PHASE 2 - Implemented

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
| Goal Forecasting (ETA) | ✅ Completo | `GoalProjection` + `goalProjectionProvider` - Proyección de peso con ETA |
| Goal Line in Chart | ✅ Completo | Línea punteada verde en gráfico de peso |
| Food Logging Speed | ✅ Completo | `quickRecentFoodsProvider` - Chips de alimentos recientes |
| Repeat Yesterday | ✅ Completo | `repeatYesterdayProvider` - Copiar comidas del día anterior |
| Weekly History Insights | ✅ Completo | `weeklyInsightsProvider` - Resúmenes semanales con adherencia |
| Meal Templates | ✅ Completo | `mealTemplatesProvider` - Guardar comidas como plantillas reutilizables |

### 🟡 Gaps Identificados

| Gap | Impacto | Complejidad |
|-----|---------|-------------|
| Recipe Builder UI ausente | Bajo | Alto |

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
| **Goal Forecasting (ETA)** | 4 | 2 | weighIns + goal + trend | Low | Yes | ✅ IMPLEMENTED | None | 2.0 | ✅ Ya existe |
| **Check-in Workflow** | 5 | 4 | weighIns + diary + plan | Low | Yes | ✅ IMPLEMENTED | None | 1.25 | ✅ Ya existe |
| **Food Logging Speed (Recents/Favorites)** | 4 | 2 | diaryEntries + foods | Low | Yes | ✅ IMPLEMENTED | None | 2.0 | ✅ Ya existe |
| **Macro Flexibility Ranges** | 3 | 3 | targets | Low | Yes | Medium | None | 1.0 | Pendiente |
| **Trend Weight Smoothing** | 5 | 4 | weighIns | Low | Yes | ✅ IMPLEMENTED | None | 1.25 | ✅ Ya existe |

---

### 2.2 FatSecret-like Features

| Concepto | User Value | Complexity | Data Requirements | Privacy Risk | Offline | Fit | Dependencies | ROI | Status |
|----------|------------|------------|-------------------|--------------|---------|-----|--------------|-----|--------|
| **Barcode Logging** | 4 | 3 | OFF API + local cache | Low | Partial | ✅ IMPLEMENTED | mobile_scanner | 1.33 | ✅ Ya existe |
| **Quick Meal Templates** | 3 | 3 | MealTemplates + UI | Low | Yes | ✅ IMPLEMENTED | None | 1.0 | ✅ Ya existe |
| **Recipe Builder (Offline)** | 3 | 4 | recipes + recipeItems | Low | Yes | Medium | None | 0.75 | Bajo ROI |
| **Weekly History Insights** | 4 | 2 | diaryEntries agregados | Low | Yes | ✅ IMPLEMENTED | None | 2.0 | ✅ Ya existe |

---

### 2.3 Libra-like Features

| Concepto | User Value | Complexity | Data Requirements | Privacy Risk | Offline | Fit | Dependencies | ROI | Status |
|----------|------------|------------|-------------------|--------------|---------|-----|--------------|-----|--------|
| **Weight Trend Smoothing** | 5 | 4 | weighIns | Low | Yes | ✅ IMPLEMENTED | None | 1.25 | ✅ Ya existe |
| **Goal Line + ETA** | 4 | 2 | goal + trend | Low | Yes | ✅ IMPLEMENTED | None | 2.0 | ✅ Ya existe |
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

> **NOTA:** Los features marcados como "🎯 CANDIDATO" en la versión anterior de este documento 
> (Goal Forecasting, Food Logging Speed, Weekly History Insights) han sido **implementados** 
> en Febrero 2026. Ver sección "✅ Features Ya Implementadas" arriba.

### ✅ IMPLEMENTADO: Quick Meal Templates (v12)

#### A. Quick Meal Templates (IMPLEMENTADO)
```
User Value: 3 | Complexity: 3 | ROI: 1.0 | Status: ✅ Completo
```

**Qué hace:**
- Guardar combinaciones de alimentos como "plantillas de comida"
- Permite agregar comidas completas con un toque
- Similar a recetas pero más simple (sin proporción, solo alimentos fijos)

**Implementación:**
- Tablas: `MealTemplates`, `MealTemplateItems` (schema v12)
- Modelos: `MealTemplateModel`, `MealTemplateItemModel`
- Repository: `MealTemplateRepository` con CRUD
- Providers: `mealTemplatesProvider`, `topMealTemplatesProvider`, `saveMealAsTemplateProvider`, `useMealTemplateProvider`
- UI: PopupMenuButton en `_MealSection` → "Guardar como plantilla"
- UI: `_TemplateChip` en `_QuickActionsCard` con las 4 plantillas más usadas

---

## 4. ✅ Features Implementadas (Febrero 2026)

### Goal Forecasting + Goal Line (IMPLEMENTADO)
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

## 4. ✅ Features Implementadas (Febrero 2026)

### Goal Forecasting + Goal Line ✅

**Estado:** IMPLEMENTADO

**Qué hace:**
- Muestra una línea de objetivo (verde punteada) en el gráfico de peso
- Calcula y muestra ETA (fecha estimada para alcanzar peso objetivo)
- Progress bar con porcentaje hacia el objetivo
- Badge "On Track" cuando el ritmo actual lleva al objetivo

**Implementación:**
- Provider: `goalProjectionProvider`, `goalEtaDaysProvider`, `isOnTrackProvider`
- Model: `GoalProjection` en `lib/diet/models/goal_projection.dart`
- UI: `_GoalProjectionCard` en `weight_screen.dart`
- Docs: `docs/feature_goal_projection.md`

---

### Food Logging Speed ✅

**Estado:** IMPLEMENTADO

**Qué hace:**
- Muestra los 6 alimentos más recientes como chips interactivos
- Quick-add con selector de comida (desayuno, almuerzo, etc.)
- Botón "Repetir ayer" para copiar todas las comidas del día anterior
- Botón "Repetir comida" para copiar una sola comida específica

**Implementación:**
- Providers: `quickRecentFoodsProvider`, `yesterdayMealsProvider`, `repeatYesterdayProvider`
- UI: `_QuickActionsCard` + `_RecentFoodChip` en `diary_screen.dart`
- Modelo: `QuickRecentFood` con macros incluidos

---

### Weekly History Insights ✅

**Estado:** IMPLEMENTADO

**Qué hace:**
- Resumen semanal con adherencia (% días dentro de ±10% objetivo)
- Promedios de kcal, proteínas, carbos, grasas
- Comparación vs semana anterior (↑/↓ con color)
- Badge de adherencia (Excelente >80%, Buena 60-80%, Mejorable <60%)

**Implementación:**
- Provider: `weeklyInsightsProvider`, `currentWeekInsightProvider`
- Model: `WeeklyInsight` en `lib/diet/models/weekly_insight.dart`
- UI: `_WeeklyInsightsCard` en `summary_screen.dart`

---

## 5. Hard Gate Analysis

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
| Meal Templates | ✅ Implementado en schema v12 | ✅ v1.0 |

---

## 6. Quality Checklist

- [x] **No jank:** Cálculos de proyección en `WeightTrendResult` (off-UI)
- [x] **Deterministic:** ETA se calcula con fórmula simple
- [x] **Transparent:** Mostrar "basado en tu ritmo actual"
- [x] **Safe defaults:** Si no hay goal o datos insuficientes → no mostrar ETA
- [x] **Tests:** Unit tests implementados
- [x] **Docs:** `docs/feature_goal_projection.md`

---

*Última actualización: 18 Febrero 2026 - Meal Templates implementado*
