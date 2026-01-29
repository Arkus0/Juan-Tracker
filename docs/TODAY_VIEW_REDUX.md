# TODAY_VIEW_REDUX.md - Especificación de la Pantalla "HOY"

> **Objetivo**: Diseñar la pantalla que el usuario debería ver al abrir la app
> **Principio rector**: En 3 segundos debe saber: ¿Entreno hoy? ¿Qué me queda de comer?

---

## El Problema Actual

### Entry Screen Actual (entry_screen.dart)
```
┌─────────────────────────────────┐
│ ☀️ ¡Buenos días!                │
│ JUEVES, 30 ENERO                │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 🍽️ NUTRICIÓN               │ │
│ │ Diario, alimentos, peso... │ │
│ │ 🔥 1200 kcal  ⚖️ 75.5 kg   │ │  ← DATOS REALES ✅
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 🏋️ ENTRENAMIENTO           │ │
│ │ Sesiones, rutinas...       │ │
│ │ 📅 —  ⏱️ --                 │ │  ← HARDCODED ❌
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ ACCESOS RÁPIDOS                 │
│ [+ Peso] [▶ Entrenar] [🍴 Comida]│
└─────────────────────────────────┘
```

**Problemas identificados**:
1. Obliga a elegir entre dos modos (bifurcación innecesaria)
2. Card de entrenamiento no muestra datos reales
3. No responde "¿Qué me queda de comer?" (solo lo consumido)
4. No responde "¿Toca entrenar hoy?"

---

## Propuesta: "TODAY VIEW" Unificada

### Wireframe Conceptual (ASCII)

```
┌─────────────────────────────────────┐
│ HOY - Jueves 30 Ene         [⚙️]   │
├─────────────────────────────────────┤
│                                     │
│  ╔═══════════════════════════════╗  │
│  ║  🏋️ PECHO & TRÍCEPS          ║  │
│  ║  Última vez: Domingo (3 días) ║  │
│  ║                               ║  │
│  ║  [████████████████    ] 75%   ║  │
│  ║  6/8 ejercicios completados   ║  │
│  ║                               ║  │
│  ║      [ ENTRENAR AHORA ]       ║  │
│  ║         ↳ Cambiar día         ║  │
│  ╚═══════════════════════════════╝  │
│                                     │
│  ─────────── o DESCANSO ───────────  │  ← Alternativa si no toca
│                                     │
├─────────────────────────────────────┤
│  MACROS RESTANTES                   │
│  ┌─────────┬─────────┬─────────┐   │
│  │  🔥     │  🥩     │  🍞     │   │
│  │  800    │  40g    │  60g    │   │
│  │  kcal   │ prote   │ carbos  │   │
│  │ restant │ restant │ restant │   │
│  └─────────┴─────────┴─────────┘   │
│                                     │
│  Progreso: [██████████░░░░] 60%    │
│  Consumido: 1200 / 2000 kcal       │
│                                     │
│  [ + REGISTRAR COMIDA ]             │
│                                     │
├─────────────────────────────────────┤
│  QUICK ADD (basado en hora)         │
│  [☕ Café+leche 45kcal] [🥣 Avena]  │
│                                     │
└─────────────────────────────────────┘
```

---

## Sistema de Información: Jerarquía Visual

### Prioridad 1: Estado de Entrenamiento (Hero Section)
**Ubicación**: Top 40% de la pantalla
**Información mostrada**:

```
SI hay entrenamiento programado para hoy:
┌────────────────────────────────────┐
│ 🏋️ [NOMBRE_DÍA] - [NOMBRE_RUTINA] │
│ Última sesión de este grupo: X días│
│                                    │
│ Ejercicios: Press Banca, Fondos... │
│ Series totales: ~24               │
│ Tiempo estimado: 45-60 min        │
│                                    │
│      [ ENTRENAR AHORA ]           │  ← CTA Primario (bottom 1/3 de card)
│      Toca "Cambiar" para otro día │
└────────────────────────────────────┘

SI es día de descanso:
┌────────────────────────────────────┐
│ 😴 DÍA DE DESCANSO                │
│ Próximo entrenamiento: Mañana     │
│ → Espalda & Bíceps               │
│                                    │
│ Recuperación activa sugerida:     │
│ • 20 min cardio ligero           │
│ • Estiramientos 10 min           │
│                                    │
│   [ VER PLAN SEMANAL ]            │
└────────────────────────────────────┘
```

### Prioridad 2: Macros Restantes (Prospective View)
**Ubicación**: Middle 35% de la pantalla
**Datos mostrados (EN ORDEN DE PRIORIDAD)**:

1. **Proteína restante** (crítico para ganancia muscular)
2. **Calorías restantes** (presupuesto general)
3. **Carbohidratos restantes** (energía para entrenamiento)
4. **Grasa restante** (menos crítico, puede ser secundario)

```dart
// Propuesta de estructura de datos
class TodaySummary {
  // Entrenamiento
  final bool isTrainingDay;
  final String? suggestedWorkout;      // "Pecho & Tríceps"
  final int? daysSinceLastSession;     // 3
  final String? lastSessionDate;       // "Domingo"

  // Nutrición - RESTANTE (no consumido)
  final int kcalRemaining;             // 800
  final double proteinRemaining;       // 40g
  final double carbsRemaining;         // 60g
  final double fatRemaining;           // 25g

  // Progreso
  final double kcalProgress;           // 0.6 (60%)
  final double proteinProgress;        // 0.7 (70%)
}
```

### Prioridad 3: Quick Actions
**Ubicación**: Bottom 25% de la pantalla (Thumb Zone)
**Acciones**:
- [ + REGISTRAR COMIDA ] - CTA secundario
- Quick Add chips basados en hora del día y historial

---

## Arquitectura de Providers Propuesta

### Nuevo Provider: todaySummaryProvider

```dart
// Ubicación propuesta: lib/core/providers/today_providers.dart

/// Provider unificado que combina datos de entrenamiento y nutrición
/// para la vista "HOY"
final todaySummaryProvider = FutureProvider<TodaySummary>((ref) async {
  // 1. Obtener sugerencia de entrenamiento
  final trainingSuggestion = await ref.watch(smartSuggestionProvider.future);

  // 2. Obtener última sesión del grupo muscular sugerido
  final sessionsHistory = await ref.watch(sesionesHistoryStreamProvider.future);
  final lastSessionOfType = _findLastSessionOfType(
    sessionsHistory,
    trainingSuggestion?.dayName,
  );

  // 3. Obtener resumen nutricional con RESTANTES
  final nutritionSummary = await ref.watch(daySummaryProvider.future);

  // 4. Combinar en vista unificada
  return TodaySummary(
    // Training
    isTrainingDay: trainingSuggestion != null,
    suggestedWorkout: trainingSuggestion?.dayName,
    suggestedRutina: trainingSuggestion?.rutina,
    daysSinceLastSession: lastSessionOfType != null
        ? DateTime.now().difference(lastSessionOfType.fecha).inDays
        : null,
    lastSessionDate: lastSessionOfType?.fecha,

    // Nutrition - RESTANTES (cálculo invertido)
    kcalRemaining: nutritionSummary.progress.kcalRemaining ?? 0,
    proteinRemaining: _calculateRemaining(
      nutritionSummary.targets?.proteinTarget,
      nutritionSummary.consumed.protein,
    ),
    carbsRemaining: _calculateRemaining(
      nutritionSummary.targets?.carbsTarget,
      nutritionSummary.consumed.carbs,
    ),
    fatRemaining: _calculateRemaining(
      nutritionSummary.targets?.fatTarget,
      nutritionSummary.consumed.fat,
    ),

    // Progress
    kcalProgress: nutritionSummary.progress.kcalPercent ?? 0,
    proteinProgress: nutritionSummary.progress.proteinPercent ?? 0,
  );
});

double _calculateRemaining(double? target, double consumed) {
  if (target == null) return 0;
  return (target - consumed).clamp(0, target);
}
```

---

## Decisiones de Diseño

### 1. ¿Por qué unificar Nutrición + Entrenamiento?

**Modelo mental del usuario**: "¿Qué tengo que hacer HOY?"

El usuario no piensa en "módulos" separados. Piensa en su día:
- Mañana: ¿Desayuno algo distinto si entreno?
- Mediodía: ¿Cuánta proteína me falta?
- Tarde: ¿Toca gym o descanso?
- Noche: ¿Puedo cenar esto sin pasarme?

### 2. ¿Por qué "Restante" en lugar de "Consumido"?

**Loss Aversion** (Kahneman): Las personas reaccionan más fuerte a pérdidas que a ganancias.

- "Te quedan 800 kcal" → Sensación de presupuesto disponible, libertad
- "Has consumido 1200 kcal" → Sensación de deuda, culpa

**Contexto de decisión**: A las 14:00 en un restaurante, el usuario necesita saber "¿cuánto PUEDO gastar?" no "¿cuánto GASTÉ?".

### 3. ¿Por qué Proteína antes que Calorías?

Para el público objetivo (culturista, fitness):
- **Proteína** es el macro limitante para ganancia muscular
- **Calorías** son fáciles de ajustar (comer más/menos de cualquier cosa)
- **Proteína restante** → Decisión de qué comer (pollo vs. pasta)

### 4. ¿Cómo manejar días de descanso?

**No mostrar vacío**. Mostrar:
- Confirmación de que es día de descanso (validación)
- Qué toca mañana (preparación mental)
- Sugerencias de recuperación activa (valor añadido)

---

## Comportamiento Contextual (Warm Start)

### Basado en Hora del Día

```dart
String getContextualGreeting(DateTime now) {
  final hour = now.hour;

  if (hour < 10) {
    // Mañana temprana: Enfatizar desayuno + ¿entreno hoy?
    return 'Buenos días. ¿Listo para empezar?';
  } else if (hour < 14) {
    // Media mañana: Enfatizar plan del día
    return 'Tu día de hoy';
  } else if (hour < 18) {
    // Tarde: Enfatizar si queda entrenamiento pendiente
    return 'Quedan ${hoursUntilGym}h para el gym';
  } else if (hour < 21) {
    // Noche: Enfatizar cena + resumen del día
    return '¿Qué cenar con ${kcalRemaining} kcal?';
  } else {
    // Noche tardía: Resumen del día
    return 'Resumen de hoy';
  }
}
```

### Basado en Estado de Sesión Activa

Si hay una sesión de entrenamiento pausada:
```
┌────────────────────────────────────┐
│ ⚡ SESIÓN EN PROGRESO             │
│ Pecho & Tríceps - 45 min          │
│ 18/24 series completadas          │
│                                    │
│      [ CONTINUAR SESIÓN ]         │
│      [ Terminar y guardar ]       │
└────────────────────────────────────┘
```

---

## Integración con Navegación Existente

### Opción A: Reemplazar Entry Screen (Recomendado)
- `entry_screen.dart` → `today_screen.dart`
- Eliminar bifurcación Nutrición/Entrenamiento
- Navegación profunda desde cards específicas

### Opción B: Agregar Tab "HOY" (Menos invasivo)
- Mantener Entry Screen como launcher
- Agregar nuevo tab en ambos módulos
- Duplicación de código, no recomendado

### Navegación desde TODAY VIEW

```
┌─────────────────────────────────────┐
│ TODAY VIEW                          │
├─────────────────────────────────────┤
│ [Card Entrenamiento]                │
│   → Tap CTA: TrainingSessionScreen  │
│   → Tap "Cambiar": TrainSelectionScreen
│   → Tap card: MainScreen (training) │
├─────────────────────────────────────┤
│ [Card Nutrición]                    │
│   → Tap "+ Registrar": FoodSearch   │
│   → Tap card: DiaryScreen           │
│   → Tap macro: SummaryScreen        │
├─────────────────────────────────────┤
│ [Quick Add Chips]                   │
│   → Tap chip: Añade directamente    │
│   → Long press: Ver detalles        │
└─────────────────────────────────────┘
```

---

## Métricas de Éxito

### KPIs a Medir

| Métrica | Baseline | Target |
|---------|----------|--------|
| Tiempo para saber "¿entreno hoy?" | 8-15s (navegar) | <3s (visible) |
| Tiempo para saber "macros restantes" | 5-10s (calcular) | <2s (visible) |
| Taps para iniciar entrenamiento | 3-4 taps | 1 tap |
| Taps para registrar comida | 2 taps | 1 tap |
| Sesiones abandonadas por confusión | ~15% | <5% |

### A/B Testing Propuesto

1. **Control**: Entry Screen actual con bifurcación
2. **Variante A**: Today View unificada
3. **Variante B**: Today View con hero de nutrición (invertir orden)

Medir: Engagement diario, completitud de registro, retención 7d/30d.

---

## Implementación Incremental

### Fase 1: Quick Win (2-4 horas)
- Conectar `smartSuggestionProvider` a card de entrenamiento en Entry Screen
- Cambiar "—" por nombre del día sugerido

### Fase 2: Inversión Nutricional (2-3 horas)
- Crear `remainingMacrosProvider`
- Actualizar card de nutrición para mostrar "restante"

### Fase 3: Vista Unificada (5-7 días)
- Crear `today_screen.dart` con layout propuesto
- Crear `todaySummaryProvider` combinado
- Implementar lógica contextual por hora
- Migrar como pantalla principal

---

*Especificación creada como parte de la auditoría UX - Enero 2026*
