# Roadmap de Corrección - Módulo de Nutrición

> Análisis exhaustivo de problemas y plan de corrección detallado

---

## Resumen Ejecutivo

Se identificaron **6 áreas críticas** con problemas de UX, bugs funcionales y deuda técnica que afectan la experiencia del usuario en el módulo de nutrición. Este documento detalla cada problema, su causa raíz y la solución propuesta.

---

## 1. PANTALLA DIARIO - Problemas Identificados

### 1.1 Botones de Añadir Redundantes/Confusos

**Problema:**
- El FAB "+ Añadir" y el botón "AÑADIR DESAYUNO" en empty state son redundantes
- Cuando hay comidas registradas, el botón contextual (ej: "AÑADIR DESAYUNO") desaparece completamente
- El FAB siempre añade a `MealType.snack` sin importar la hora

**Causa en código:**
```dart
// En diary_screen.dart:177-178
actionLabel: 'AÑADIR $mealSuggestion'.toUpperCase(),
onAction: () => _showAddEntry(context, ref, suggestedMealType),

// Este botón solo aparece cuando entries.isEmpty
```

**Solución propuesta:**
1. **Unificar en un solo FAB** con menú desplegable (como en entrenamiento)
2. **Siempre mostrar opción de añadir** en cada sección de comida (desayuno, almuerzo, cena, snack)
3. **Reorganizar por comidas:** Mostrar 4 cards/secciones (Desayuno, Almuerzo, Cena, Snack) cada una con su botón "+"

### 1.2 Solo Contabiliza Kcal y Proteínas - Faltan Hidratos y Grasas

**Problema:**
En `_NutritionModeCard` (entry_screen.dart:551-617) solo se muestran kcal y proteínas:
```dart
return (
  [
    _Stat(icon: Icons.local_fire_department, value: '$remainingKcal', label: 'kcal rest'),
    _Stat(icon: Icons.fitness_center, value: '${remainingProtein}g', label: 'prot rest'),
  ],
  ...
);
```

**Causa:** El diseño original priorizaba kcal y proteínas, pero el usuario necesita ver el balance completo de macros.

**Solución propuesta:**
- Añadir cards de hidratos y grasas en el resumen
- O usar un mini gráfico de distribución de macros

### 1.3 Búsqueda en Open Food Facts No Conecta / Smart Import Inaccesible

**Problema:**
- `FoodSearchScreen` solo busca en la biblioteca local (`foodSearchResultsProvider`)
- `ExternalFoodSearchScreen` existe pero está desconectada del flujo principal
- El usuario debe saber que existe "Buscar Online" y hacer 2 taps extra
- Smart Import (OCR, voz, código de barras) está escondido en una pantalla secundaria

**Flujo actual problemático:**
```
Diario → FAB → FoodSearchScreen → "Buscar Online" → ExternalFoodSearchScreen
```

**Solución propuesta:**
1. **Integrar búsqueda unificada:** Local + Open Food Facts en la misma pantalla
2. **Botón flotante estilo entrenamiento** con opciones:
   - 🔍 Buscar (local + OFF)
   - 📷 Escanear código
   - 🎙️ Voz
   - 📋 OCR etiqueta
   - ⚡ Añadir rápido
3. **Búsqueda progresiva:** Primero local, si no hay resultados → automáticamente OFF

### 1.4 No Deja Elegir Tipo de Comida Libremente

**Problema:**
- El sistema sugiere una comida basada en hora pero no permite fácilmente cambiarla
- `_showAddEntry` siempre usa el `mealType` pasado, pero el diálogo no permite cambiarlo fácilmente

**Código problemático:**
```dart
// diary_screen.dart:214-216
void _showAddEntry(BuildContext context, WidgetRef ref, MealType mealType) {
  ref.read(selectedMealTypeProvider.notifier).meal = mealType;
  context.pushTo(AppRouter.nutritionFoods);  // No pasa el mealType al diálogo final
}
```

**Solución propuesta:**
- El selector de tipo de comida debe estar en el diálogo de añadir (ya está en `AddEntryDialog`)
- Permitir añadir a cualquier comida desde cualquier momento
- Mostrar las 4 comidas como secciones expandibles

---

## 2. PANTALLA ALIMENTOS - Redundancia Total

**Problema:**
- Es una pantalla separada que solo lista alimentos de la biblioteca
- Funcionalidad duplicada con la búsqueda del diario
- No permite editar/eliminar fácilmente
- Ocupa un tab completo en la navegación inferior

**Análisis de código:**
```dart
// foods_screen.dart - Solo CRUD básico sin valor añadido
class FoodsScreen extends ConsumerStatefulWidget {
  // Busca en local, permite añadir nuevo
  // Pero no se puede usar directamente en el diario
}
```

**Solución propuesta (Eliminar pantalla):**
1. **Integrar todo en Diario:**
   - Búsqueda unificada (local + OFF)
   - Si el alimento no existe → opción "Crear nuevo" en los resultados
   - Si existe → seleccionar cantidad y añadir
   - Long-press o menú para editar/eliminar alimentos

2. **Navegación:**
   - Eliminar tab "Alimentos" del `HomeScreen`
   - Nueva navegación: Diario | Peso | Resumen | Coach

---

## 3. PANTALLA PESO - Falta Contexto Analítico

**Problema:**
- Muestra "Tendencia" y "Semana" sin explicar qué significan
- No hay gráfica de evolución
- No hay análisis de si la tendencia es positiva/negativa
- "Semana" muestra 0.0 kg cuando solo hay un peso registrado

**Código actual:**
```dart
// weight_screen.dart:159-187
AppStatCard(
  label: 'Tendencia',
  value: result.trendWeight.toStringAsFixed(1),  // Media móvil de 7 días
  unit: 'kg',
),
AppStatCard(
  label: 'Semana',
  value: result.weeklyRate.toStringAsFixed(1),   // Cambio kg/semana
  unit: 'kg',
),
```

**Solución propuesta:**
1. **Añadir tooltips/info buttons** explicando cada métrica:
   - **Tendencia:** Media móvil de 7 días que suaviza fluctuaciones diarias
   - **Semana:** Ritmo de cambio estimado en kg por semana

2. **Añadir gráfica** de evolución de peso (últimos 30 días)

3. **Contexto visual:**
   - Flechas de tendencia (↗️ ↘️ ➡️)
   - Color verde/rojo según objetivo (perder/ganar)

4. **Validar cálculo de weeklyRate:** Revisar `weight_trend_calculator.dart`

---

## 4. PANTALLA RESUMEN - Macros Incompletos

**Problema:**
- El card principal solo muestra calorías y proteínas
- Los hidratos y grasas aparecen en el desglose pero sin contexto de objetivo

**Solución propuesta:**
- Incluir todos los macros en el card principal con progress rings
- O hacer los cards pulsables para ver detalle

---

## 5. PANTALLA COACH - Bugs Críticos

### 5.1 Pixel Overflow

**Problema:**
En `PlanSetupScreen` con macros personalizados, los sliders pueden causar overflow.

**Solución:**
- Añadir `SingleChildScrollView` con `physics: AlwaysScrollableScrollPhysics()`
- O usar `Expanded` donde corresponda

### 5.2 No Calcula TDEE Automáticamente

**Problema:**
El usuario debe introducir su TDEE manualmente sin ayuda de la app.

**Solución propuesta:**
- **Opción A:** Calculadora Mifflin-St Jeor integrada (edad, sexo, altura, peso, actividad)
- **Opción B:** Sugerir basado en el peso: `peso × 22 (mujer) / 24 (hombre) × factor_actividad`

### 5.3 Pide Peso Actual Cuando Ya Debería Tenerlo

**Problema:**
El campo de peso actual en `PlanSetupScreen` no se pre-llena con el último peso registrado.

**Solución:**
```dart
// En initState:
final lastWeight = ref.read(latestWeightProvider);
_weightController.text = lastWeight?.toString() ?? '';
```

### 5.4 Slider de Objetivos Incorrecto (CRÍTICO)

**Problema:**
El slider va de -2.5% a +2.5% independientemente del objetivo seleccionado:

```dart
// plan_setup_screen.dart:378-386 (ACTUAL - INCORRECTO)
Slider(
  value: _weeklyRatePercent.clamp(-0.025, 0.025),
  min: -0.025,  // ❌ Siempre permite valores negativos
  max: 0.025,   // ❌ Siempre permite valores positivos
  divisions: 20,
  label: '${displayValue.toStringAsFixed(1)}%',
)
```

**Comportamiento esperado:**
- **Perder peso:** Slider de 0.1% a 2.5% de PÉRDIDA (valores positivos en UI, negativos en lógica)
- **Ganar peso:** Slider de 0.1% a 2.5% de GANANCIA (valores positivos)
- **Mantener:** No hay slider

**Solución propuesta:**
```dart
// NUEVO - Correcto
if (_goal == WeightGoal.lose) {
  return Slider(
    value: _weeklyRatePercent.abs().clamp(0.001, 0.025),  // Siempre positivo en UI
    min: 0.001,  // 0.1%
    max: 0.025,  // 2.5%
    onChanged: (v) => _weeklyRatePercent = -v,  // Negativo en lógica
  );
} else if (_goal == WeightGoal.gain) {
  return Slider(
    value: _weeklyRatePercent.clamp(0.001, 0.025),
    min: 0.001,
    max: 0.025,
    onChanged: (v) => _weeklyRatePercent = v,  // Positivo en lógica
  );
}
```

---

## 6. PANTALLA HOME (Entry) - Problemas de Navegación

### 6.1 No Hay Forma de Volver a Home

**Problema:**
Una vez entras a Nutrición o Entrenamiento, no hay botón para volver a la pantalla de selección de modo.

**Causa:**
```dart
// app_router.dart - No hay ruta de regreso
goToNutrition() => go(AppRouter.nutrition);  // Reemplaza la ruta
```

**Solución propuesta:**
- **Opción A:** Botón "Volver" en el AppBar de HomeScreen (ya tiene `AppBar`)
- **Opción B:** Añadir un botón "Cambiar modo" en el menú de perfil/settings
- **Opción C:** Gesture de volver (swipe) funciona por defecto en Android

### 6.2 Snackbar Vacío al Registrar Peso

**Problema:**
```dart
// entry_screen.dart:267
AppSnackbar.show(context, message: 'Peso registrado');
```
Pero el código en `weight_screen.dart:45` también usa:
```dart
messenger.showSnackBar(const SnackBar(content: Text('Peso registrado')));
```

El `AppSnackbar.show` podría tener un bug donde no muestra el texto.

**Solución:** Verificar implementación de `AppSnackbar` o usar `ScaffoldMessenger` directamente.

### 6.3 Botón "Comida" Lleva a Pantalla Errónea

**Problema:**
```dart
// entry_screen.dart:275-278
void _showAddFoodDialog(BuildContext context, WidgetRef ref) {
  AppHaptics.buttonPressed();
  context.pushTo(AppRouter.nutritionFoods);  // ❌ Lleva a FoodsScreen
}
```

Debería llevar directamente a añadir una entrada al diario, no a gestionar alimentos.

**Solución:**
```dart
// NUEVO - Correcto
void _showAddFoodDialog(BuildContext context, WidgetRef ref) {
  AppHaptics.buttonPressed();
  // Mostrar selector de tipo de comida primero
  final mealType = await showDialog<MealType>(...);
  if (mealType != null) {
    ref.read(selectedMealTypeProvider.notifier).meal = mealType;
    context.pushTo(AppRouter.nutritionDiary);  // O directo al buscador
  }
}
```

---

## Roadmap de Implementación

### Fase 1: Correcciones Críticas (Alta Prioridad)

| Issue | Archivo(s) | Complejidad |
|-------|------------|-------------|
| Fix slider coach (rango incorrecto) | `plan_setup_screen.dart` | Media |
| Pre-llenar peso en coach | `plan_setup_screen.dart` | Baja |
| Fix pixel overflow coach | `plan_setup_screen.dart` | Baja |
| Añadir tooltips en peso | `weight_screen.dart` | Baja |
| Fix snackbar vacío | `entry_screen.dart`, `app_snackbar.dart` | Baja |

### Fase 2: Reorganización Diario (Media Prioridad)

| Issue | Archivo(s) | Complejidad |
|-------|------------|-------------|
| Reorganizar por secciones de comida | `diary_screen.dart` | Alta |
| Unificar botones de añadir | `diary_screen.dart` | Media |
| Mostrar siempre opción de añadir | `diary_screen.dart` | Baja |
| Añadir hidratos/grasas a resumen | `entry_screen.dart`, `summary_screen.dart` | Media |

### Fase 3: Integración Búsqueda (Media Prioridad)

| Issue | Archivo(s) | Complejidad |
|-------|------------|-------------|
| Crear FAB menu estilo entrenamiento | `diary_screen.dart` | Media |
| Integrar OFF en búsqueda local | `food_search_screen.dart` | Alta |
| Añadir OCR/Voz/Código a FAB | `diary_screen.dart` | Media |

### Fase 4: Eliminación Pantalla Alimentos (Baja Prioridad)

| Issue | Archivo(s) | Complejidad |
|-------|------------|-------------|
| Añadir "Crear nuevo" a búsqueda | `food_search_screen.dart` | Media |
| Añadir editar/eliminar en diario | `diary_screen.dart` | Media |
| Eliminar tab de navegación | `home_screen.dart`, `app_router.dart` | Baja |
| Eliminar archivo foods_screen.dart | - | Baja |

### Fase 5: Mejoras Adicionales (Baja Prioridad)

| Issue | Archivo(s) | Complejidad |
|-------|------------|-------------|
| Gráfica de peso | `weight_screen.dart` | Alta |
| Calculadora TDEE | `plan_setup_screen.dart` | Media |
| Navegación vuelta a home | `app_router.dart`, `home_screen.dart` | Baja |

---

## Dudas para Confirmar

Antes de proceder, necesito confirmar:

1. **¿Eliminamos completamente la pantalla de Alimentos?** O la mantenemos como "Biblioteca" accesible desde algún menú?

2. **¿Cómo debe funcionar exactamente el selector de comida?**
   - Opción A: 4 secciones fijas (Desayuno, Almuerzo, Cena, Snack) cada una con su lista
   - Opción B: Lista plana actual pero con filtro por tipo de comida
   - Opción C: Tabs horizontales para cada comida

3. **¿El Smart Import debe estar siempre visible o en un menú?**
   - Siempre visible = más descubrible pero más clutter
   - En menú = más limpio pero requiere un tap extra

4. **¿Qué datos usar para la calculadora TDEE?**
   - ¿Tenemos edad, sexo, altura del usuario?
   - ¿O solo peso?

---

## Notas Técnicas

### Archivos Clave Modificados

```
lib/
├── features/
│   ├── diary/
│   │   └── presentation/
│   │       ├── diary_screen.dart          # REORGANIZAR
│   │       ├── food_search_screen.dart    # INTEGRAR OFF
│   │       └── add_entry_dialog.dart      # OK (pocos cambios)
│   ├── foods/
│   │   └── presentation/
│   │       └── foods_screen.dart          # ELIMINAR
│   ├── weight/
│   │   └── presentation/
│   │       └── weight_screen.dart         # AÑADIR GRÁFICA/INFO
│   ├── summary/
│   │   └── presentation/
│   │       └── summary_screen.dart        # AÑADIR MACROS
│   └── home/
│       └── presentation/
│           ├── entry_screen.dart          # FIX SNACKBAR, BOTÓN COMIDA
│           └── home_screen.dart           # ELIMINAR TAB ALIMENTOS
├── diet/
│   └── screens/
│       └── coach/
│           ├── coach_screen.dart          # CHECK OVERFLOW
│           └── plan_setup_screen.dart     # FIX SLIDER, AUTO-CALC
└── core/
    └── router/
        └── app_router.dart                # AJUSTAR RUTAS
```

### Tests Afectados

- `test/diet/services/day_summary_calculator_test.dart` - Verificar cálculo de macros
- `test/features/diary/presentation/diary_screen_test.dart` - Actualizar tests de UI
- `test/diet/screens/coach/plan_setup_screen_test.dart` - Añadir tests del slider

---

*Documento generado el 30/01/2026 - Requiere validación antes de implementación*
