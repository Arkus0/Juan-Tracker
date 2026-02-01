# Feature: Goal Projection (Weight ETA & Progress)

> **Status:** ✅ Implemented  
> **Version:** 1.0.0  
> **Date:** 1 Febrero 2026  
> **Inspired by:** Libra (weight trend smoothing + goal line + ETA)

---

## Overview

Goal Projection es una feature que muestra al usuario una proyección de cuándo alcanzará su peso objetivo basándose en su ritmo actual de cambio de peso. Incluye:

1. **ETA (Estimated Time of Arrival):** Fecha estimada para alcanzar el peso objetivo
2. **Progress Bar:** Porcentaje de progreso hacia la meta
3. **On-Track Indicator:** Badge que indica si el ritmo actual lleva al objetivo
4. **Pace Message:** Comparación del ritmo actual vs el objetivo

---

## Architecture

### Data Flow

```
┌─────────────────┐     ┌────────────────────┐
│   CoachPlan     │────▶│                    │
│ (goal, rate,    │     │ GoalProjection-    │     ┌─────────────────┐
│  startWeight)   │     │ Calculator         │────▶│ GoalProjection  │
└─────────────────┘     │                    │     │ (ETA, progress, │
                        │                    │     │  messages)      │
┌─────────────────┐     │                    │     └─────────────────┘
│ WeightTrendResult────▶│                    │
│ (hwTrend,       │     └────────────────────┘
│  trendWeight)   │
└─────────────────┘
```

### Files

| File | Purpose |
|------|---------|
| [goal_projection_model.dart](../lib/diet/models/goal_projection_model.dart) | Data model + calculations |
| [goal_projection_providers.dart](../lib/diet/providers/goal_projection_providers.dart) | Riverpod providers |
| [weight_screen.dart](../lib/features/weight/presentation/weight_screen.dart) | UI (GoalProjectionCard) |
| [goal_projection_test.dart](../test/diet/services/goal_projection_test.dart) | Unit tests |

---

## Model: GoalProjection

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `goalWeightKg` | `double` | Peso objetivo en kg |
| `currentTrendWeight` | `double` | Peso tendencia actual (suavizado) |
| `latestWeight` | `double` | Último peso registrado |
| `dailyTrendRate` | `double` | Cambio diario en kg (+ = ganando, - = perdiendo) |
| `goal` | `WeightGoal` | Objetivo: `lose`, `maintain`, `gain` |
| `targetWeeklyRateKg` | `double` | Ritmo objetivo en kg/semana |
| `planStartDate` | `DateTime` | Fecha de inicio del plan |
| `daysSinceStart` | `int` | Días desde inicio |

### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `weightDelta` | `double` | Diferencia actual vs objetivo |
| `isOnTrack` | `bool` | ¿Moviéndose en dirección correcta? |
| `goalReached` | `bool` | ¿Ya alcanzó el objetivo (±0.5 kg)? |
| `estimatedDaysToGoal` | `int?` | Días estimados para meta (null si no aplica) |
| `estimatedGoalDate` | `DateTime?` | Fecha estimada de meta |
| `progressPercentage` | `double` | Porcentaje 0-100+ |
| `currentWeeklyRate` | `double` | Ritmo actual en kg/semana |
| `paceRatio` | `double` | Ratio actual/objetivo (1.0 = en target) |

### Methods

```dart
// Predecir peso en N días
double predictWeightInDays(int days)

// Predecir peso en una fecha
double predictWeightAt(DateTime date)

// Generar puntos para línea de objetivo en chart
List<GoalChartPoint> generateGoalLine({int maxDays = 90})
```

---

## Calculations

### ETA Calculation

```dart
estimatedDaysToGoal = (currentWeight - goalWeight).abs() / dailyTrendRate.abs()
```

**Constraints:**
- Returns `null` si el trend va en dirección incorrecta
- Returns `null` si el trend es ~0
- Returns `null` si ETA > 730 días (2 años)
- Returns `0` si ya se alcanzó el objetivo

### Progress Calculation

```dart
startWeight = currentTrendWeight - (dailyTrendRate * daysSinceStart)
totalChange = currentTrendWeight - startWeight
targetTotalChange = goalWeightKg - startWeight
progressPercentage = (totalChange / targetTotalChange) * 100
```

### On-Track Detection

| Goal | On Track Condition |
|------|-------------------|
| `lose` | `dailyTrendRate < 0` |
| `gain` | `dailyTrendRate > 0` |
| `maintain` | Siempre `true` |

---

## Providers

### Main Provider

```dart
// Obtiene la proyección completa
final goalProjectionProvider = Provider<AsyncValue<GoalProjection?>>((ref) {
  // Combina coachPlanProvider + weightTrendProvider
});
```

### Derived Providers (para UI específica)

```dart
// Mensaje de progreso (para badges)
final goalProgressMessageProvider = Provider<String?>

// ETA en días
final goalEtaDaysProvider = Provider<int?>

// ¿Está on track?
final isOnTrackProvider = Provider<bool?>

// Porcentaje de progreso
final goalProgressPercentageProvider = Provider<double?>

// Puntos para goal line en chart
final goalChartLineProvider = Provider<List<GoalChartPoint>?>
```

### Custom Goal Weight

```dart
// Peso objetivo configurable por usuario
final customGoalWeightProvider = NotifierProvider<CustomGoalWeightNotifier, double?>

// Peso objetivo efectivo (custom o calculado)
final effectiveGoalWeightProvider = Provider<double?>
```

---

## UI Components

### _GoalProjectionCard

Card principal que muestra:

1. **Header:** Icono de objetivo + título + status badge
2. **Metrics:** Meta (kg) + ETA
3. **Progress Bar:** Barra visual de progreso
4. **Messages:** Mensaje de progreso + mensaje de ritmo

**Condiciones de visibilidad:**
- Solo se muestra si hay `CoachPlan` activo
- Solo se muestra si hay datos de peso suficientes

### _StatusBadge

Badge que indica estado:

| Estado | Color | Texto |
|--------|-------|-------|
| Goal reached | Verde | "Meta" |
| On track | Verde | "En camino" |
| Off track | Naranja | "Ajustar" |

---

## Usage Examples

### En Weight Screen

El card se muestra automáticamente si hay un CoachPlan configurado:

```dart
// En WeightScreen, el card está incluido
const SliverToBoxAdapter(
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    child: _GoalProjectionCard(),
  ),
),
```

### Acceder a datos desde otros widgets

```dart
// En cualquier Consumer widget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final eta = ref.watch(goalEtaDaysProvider);
  final isOnTrack = ref.watch(isOnTrackProvider);
  
  if (eta != null && isOnTrack == true) {
    return Text('¡Alcanzarás tu meta en $eta días!');
  }
  return const SizedBox.shrink();
}
```

---

## Assumptions & Limitations

### Assumptions

1. **Trend lineal:** La proyección asume que el ritmo actual se mantendrá constante
2. **Holt-Winters trend:** Usa `hwTrend` de WeightTrendResult (kg/día)
3. **Tolerancia de meta:** ±0.5 kg se considera "meta alcanzada"
4. **Peso objetivo por defecto:** Si no hay peso objetivo explícito, se usa startingWeight ± 5 kg

### Limitations

1. No considera variaciones estacionales (Navidad, vacaciones)
2. No ajusta por mesetas (plateaus)
3. No tiene en cuenta objetivos parciales (ej: -5 kg primero, luego otros -5 kg)
4. El peso objetivo debe ser configurado en CoachPlan

---

## Future Improvements

1. **Goal Line en Chart:** Agregar línea punteada del objetivo en _WeightLineChart
2. **Peso objetivo configurable:** UI para que usuario defina peso objetivo específico
3. **Proyección con confianza:** Mostrar rango (best case / worst case)
4. **Celebración de milestones:** Notificaciones cuando alcance 25%, 50%, 75%
5. **Ajuste automático de meta:** Si el usuario está muy lejos, sugerir meta intermedia

---

## Testing

### Unit Tests

```bash
flutter test test/diet/services/goal_projection_test.dart
```

**Coverage:**
- ✅ ETA calculations (loss, gain, edge cases)
- ✅ Progress percentage
- ✅ Weekly rate calculations
- ✅ Pace ratio
- ✅ Weight prediction
- ✅ Goal chart points generation
- ✅ UI messages
- ✅ Calculator with real CoachPlan + WeightTrendResult

---

## Dependencies

- `WeightTrendCalculator` (existente) - Proporciona `hwTrend`
- `AdaptiveCoachService` (existente) - Proporciona `CoachPlan`
- `fl_chart` (existente) - Para goal line (futuro)

---

*Última actualización: 1 Febrero 2026*
