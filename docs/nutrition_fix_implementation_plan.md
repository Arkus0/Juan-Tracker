# Plan de Implementación - Correcciones Nutrición

> Basado en decisiones del usuario - Orden optimizado por dependencias

---

## Decisiones Confirmadas

✅ **Pantalla Alimentos**: Eliminar de tabs, mover a Resumen (al final)  
✅ **Diario**: Estilo FatSecret - 4 secciones fijas expandibles  
✅ **Smart Import**: Botón FAB con menú (como entrenamiento) + integrar en búsqueda  
✅ **Settings**: Nuevo tab "Perfil/Settings" con datos usuario (edad, sexo, altura)  
✅ **TDEE**: Calculadora automática Mifflin-St Jeor + guardar en perfil  
✅ **Ajustes**: Consolidar en Settings, quitar icono de Resumen  

---

## FASE 1: Estructura Base (Preparación) ✅ COMPLETADA

**Objetivo**: Crear fundamentos para las siguientes fases

**Archivos creados:**
- `lib/core/models/user_profile_model.dart` - Modelo de perfil con enums Gender y ActivityLevel
- `lib/core/services/tdee_calculator.dart` - Calculadora Mifflin-St Jeor completa
- `lib/diet/repositories/user_profile_repository.dart` - Repositorio Drift para persistencia
- `lib/features/settings/presentation/settings_screen.dart` - Pantalla de perfil/ajustes

**Archivos modificados:**
- `lib/training/database/database.dart` - Añadida tabla UserProfiles, schema v6
- `lib/core/providers/database_provider.dart` - Añadidos providers userProfileProvider, isProfileCompleteProvider
- `lib/diet/repositories/repositories.dart` - Export añadido
- `lib/features/home/presentation/home_screen.dart` - Eliminado tab Alimentos, añadido tab Perfil
- `lib/features/summary/presentation/summary_screen.dart` - Eliminado icono settings, añadida sección Biblioteca

**Cambios en navegación:**
- Tabs: Diario | Peso | Resumen | Coach | Perfil
- Biblioteca de alimentos accesible desde Resumen y Perfil
- Settings consolidado en tab Perfil

### 1.1 Modelo de Perfil de Usuario
```dart
// Nuevo archivo: lib/core/models/user_profile_model.dart
class UserProfileModel {
  final String? id;
  final int? age;
  final String? gender; // 'male', 'female'
  final double? heightCm;
  final double? currentWeightKg; // Último peso registrado
  final ActivityLevel activityLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

enum ActivityLevel {
  sedentary,      // 1.2 - Poco o ningún ejercicio
  lightlyActive,  // 1.375 - 1-3 días/semana
  moderatelyActive, // 1.55 - 3-5 días/semana
  veryActive,     // 1.725 - 6-7 días/semana
  extremelyActive // 1.9 - 2x día o trabajo físico
}
```

### 1.2 Tabla Drift para Perfil
```dart
// lib/core/local_db/app_database.dart
class UserProfiles extends Table {
  TextColumn get id => text().unique()();
  IntColumn get age => integer().nullable()();
  TextColumn get gender => text().nullable()(); // 'male', 'female'
  RealColumn get heightCm => real().nullable()();
  RealColumn get currentWeightKg => real().nullable()();
  TextColumn get activityLevel => text().withDefault(const Constant('moderatelyActive'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
```

### 1.3 Reorganizar Navegación Principal
**Archivo**: `lib/features/home/presentation/home_screen.dart`

Cambiar tabs:
- ❌ Eliminar: `FoodsScreen()` 
- ✅ Mantener: `DiaryScreen()`, `WeightScreen()`, `SummaryScreen()`, `CoachScreen()`
- ✅ Nuevo: `SettingsScreen()` (reemplaza Alimentos)

Orden propuesto:
1. **Diario** (book icon) - Principal
2. **Peso** (scale icon) 
3. **Resumen** (dashboard icon) - Con Alimentos al final
4. **Coach** (auto_graph icon)
5. **Perfil** (person icon) - Nuevo

### 1.4 Quitar Ajustes de Resumen
**Archivo**: `lib/features/summary/presentation/summary_screen.dart`
- Eliminar IconButton de settings del AppBar
- Los ajustes ahora están en tab Perfil

---

## FASE 2: Pantalla Perfil/Settings + TDEE

**Objetivo**: Crear centro de configuración usuario + calculadora TDEE

### 2.1 Settings Screen
**Nuevo archivo**: `lib/features/settings/presentation/settings_screen.dart`

Secciones:
1. **Perfil** (expandible)
   - Edad, Sexo, Altura, Peso actual
   - Nivel de actividad (selector)
   - Botón "Calcular TDEE"
   
2. **Objetivos** (link a TargetsScreen)
   - Calorías objetivo actuales
   - Macros configurados
   
3. **Biblioteca de Alimentos** (link a FoodsScreen)
   - "Gestionar mis alimentos"
   - Importar/Exportar
   
4. **Coach Adaptativo** (link a CoachScreen)
   - Estado del plan actual
   
5. **Pro/Avanzado** (si aplica)
   - Features premium

### 2.2 Calculadora TDEE Precisa
**Nuevo archivo**: `lib/core/services/tdee_calculator.dart`

```dart
class TdeeCalculator {
  /// Mifflin-St Jeor Equation
  /// Hombres: (10 × peso kg) + (6.25 × altura cm) - (5 × edad) + 5
  /// Mujeres: (10 × peso kg) + (6.25 × altura cm) - (5 × edad) - 161
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    double bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    if (gender == 'male') {
      bmr += 5;
    } else {
      bmr -= 161;
    }
    return bmr;
  }
  
  static double calculateTDEE(double bmr, ActivityLevel activity) {
    final multipliers = {
      ActivityLevel.sedentary: 1.2,
      ActivityLevel.lightlyActive: 1.375,
      ActivityLevel.moderatelyActive: 1.55,
      ActivityLevel.veryActive: 1.725,
      ActivityLevel.extremelyActive: 1.9,
    };
    return bmr * (multipliers[activity] ?? 1.55);
  }
}
```

### 2.3 Diálogo "Completar Perfil"
**Nuevo archivo**: `lib/features/settings/presentation/complete_profile_dialog.dart`

Cuando usuario intenta calcular TDEE sin datos completos:
1. Mostrar diálogo modal con campos faltantes
2. Guardar en UserProfile
3. Calcular y mostrar resultado
4. Ofrecer "Usar este TDEE" para Coach

### 2.4 Integración Coach
**Archivo**: `lib/diet/screens/coach/plan_setup_screen.dart`

Cambios:
- Pre-llenar peso desde último registro (`latestWeightProvider`)
- Botón "Calcular mi TDEE" → abre CompleteProfileDialog → inserta valor calculado
- Si ya tiene perfil completo, mostrar sugerencia: "Tu TDEE estimado: X kcal"

---

## FASE 3: Fixes Críticos Coach

**Archivo**: `lib/diet/screens/coach/plan_setup_screen.dart`

### 3.1 Fix Slider Velocidad (CRÍTICO)
```dart
// REEMPLAZAR el slider actual (líneas ~359-432)

Widget _buildRateSlider() {
  if (_goal == WeightGoal.maintain) {
    return const Card(...); // Sin cambios
  }

  // NUEVO: Rango según objetivo
  final isLosing = _goal == WeightGoal.lose;
  final minRate = 0.001; // 0.1%
  final maxRate = 0.025; // 2.5%
  
  // Convertir a positivo para UI
  final displayValue = _weeklyRatePercent.abs();
  
  return Column(
    children: [
      Slider(
        value: displayValue.clamp(minRate, maxRate),
        min: minRate,
        max: maxRate,
        divisions: 24, // 0.1% steps
        label: '${(displayValue * 100).toStringAsFixed(1)}%',
        onChanged: (value) {
          setState(() {
            // Restaurar signo según objetivo
            _weeklyRatePercent = isLosing ? -value : value;
          });
        },
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Conservador (0.1%)'),
          Text('${(displayValue * _weight).toStringAsFixed(2)} kg/semana'),
          Text('Agresivo (2.5%)'),
        ],
      ),
    ],
  );
}
```

### 3.2 Fix Pixel Overflow
- Envolver contenido en `SingleChildScrollView` con `physics: AlwaysScrollableScrollPhysics()`
- Asegurar que hay suficiente padding bottom (32px)

---

## FASE 4: Reorganización Pantalla Diario (Estilo FatSecret)

**Archivo principal**: `lib/features/diary/presentation/diary_screen.dart`

### 4.1 Nueva Estructura
En lugar de lista plana, mostrar 4 secciones expandibles:

```dart
// Nuevo provider para controlar expansión
final expandedMealsProvider = StateProvider<Set<MealType>>(
  (ref) => {MealType.breakfast, MealType.lunch, MealType.dinner, MealType.snack}
);
```

Layout:
```
[Header con fecha]
[Resumen diario card]
[Sugerencias inteligentes]

[DESAYUNO v] ← Expandible
  [Lista de items]
  [+ Añadir a desayuno]

[ALMUERZO v]
  [Lista de items]  
  [+ Añadir a almuerzo]

[CENA v]
  [Lista de items]
  [+ Añadir a cena]

[SNACKS v]
  [Lista de items]
  [+ Añadir a snack]

[Espacio para FAB]
```

### 4.2 Componente MealSection
```dart
class _MealSection extends ConsumerWidget {
  final MealType mealType;
  final List<DiaryEntryModel> entries;
  final MealTotals totals;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          // Header expandible
          ListTile(
            title: Text(mealType.displayName),
            subtitle: Text('${totals.kcal} kcal | P:${totals.protein}g C:${totals.carbs}g G:${totals.fat}g'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _showAddFood(context, mealType),
                ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          // Contenido expandible
          if (isExpanded) ...[
            Divider(height: 1),
            ...entries.map((e) => _EntryTile(entry: e)),
            if (entries.isEmpty)
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: Colors.grey),
                title: Text('Añadir ${mealType.displayName.toLowerCase()}', 
                  style: TextStyle(color: Colors.grey)),
                onTap: () => _showAddFood(context, mealType),
              ),
          ],
        ],
      ),
    );
  }
}
```

### 4.3 Eliminar FAB Principal
- Quitar `AppFAB` flotante
- Cada sección tiene su propio botón "+"
- O mantener FAB como "Añadir Rápido" con opciones

---

## FASE 5: Smart Import + Búsqueda Unificada

### 5.1 Botón FAB Menú (Estilo Entrenamiento)
**Archivo**: `lib/features/diary/presentation/diary_screen.dart`

```dart
// Nuevo FAB expandible
class _ExpandableFAB extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded) ...[
          _FABOption(
            icon: Icons.mic,
            label: 'Voz',
            onTap: _startVoiceSearch,
          ),
          _FABOption(
            icon: Icons.qr_code_scanner,
            label: 'Código',
            onTap: _scanBarcode,
          ),
          _FABOption(
            icon: Icons.document_scanner,
            label: 'OCR',
            onTap: _scanLabel,
          ),
          _FABOption(
            icon: Icons.bolt,
            label: 'Rápido',
            onTap: _showQuickAdd,
          ),
        ],
        FloatingActionButton(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          child: Icon(_isExpanded ? Icons.close : Icons.add),
        ),
      ],
    );
  }
}
```

### 5.2 Integrar Búsqueda OFF
**Archivo**: `lib/features/diary/presentation/food_search_screen.dart`

Modificar para búsqueda unificada:
1. Buscar primero en local (`foodRepository.search(query)`)
2. Mostrar resultados locales inmediatamente
3. En paralelo, buscar en OFF (`externalFoodSearchProvider`)
4. Mostrar sección "Resultados Online" debajo de locales
5. Indicador visual mientras carga OFF

```dart
class _UnifiedSearchResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localResults = ref.watch(foodSearchResultsProvider);
    final onlineResults = ref.watch(externalFoodSearchProvider);
    
    return ListView(
      children: [
        // Locales
        if (localResults.hasValue && localResults.value!.isNotEmpty) ...[
          _SectionHeader('Tus alimentos'),
          ...localResults.value!.map((f) => _FoodTile(food: f)),
        ],
        
        // Online
        if (onlineResults.isLoading)
          _LoadingIndicator('Buscando en Open Food Facts...'),
          
        if (onlineResults.hasResults) ...[
          _SectionHeader('Open Food Facts'),
          ...onlineResults.results.map((r) => _OpenFoodTile(result: r)),
        ],
        
        // Crear nuevo
        if (localResults.value?.isEmpty ?? true)
          _CreateNewOption(query: query),
      ],
    );
  }
}
```

### 5.3 Opción "Crear Nuevo"
Cuando búsqueda no encuentra resultados:
- Mostrar card "Crear '${query}' como nuevo alimento"
- Al tocar, abrir diálogo de creación rápida con nombre pre-llenado
- Guardar en biblioteca local y seleccionar automáticamente

### 5.4 Editar/Eliminar Alimentos
- Long-press en item del diario → menú contextual (Editar/Eliminar)
- O swipe-to-delete con confirmación
- Editar cantidad/comida directamente

---

## FASE 6: Pantalla Alimentos en Resumen

**Archivo**: `lib/features/summary/presentation/summary_screen.dart`

Al final del scroll, añadir sección:

```dart
SliverToBoxAdapter(
  child: Column(
    children: [
      Divider(),
      ListTile(
        leading: Icon(Icons.restaurant_menu),
        title: Text('Biblioteca de Alimentos'),
        subtitle: Text('Gestionar tus alimentos guardados'),
        trailing: Icon(Icons.chevron_right),
        onTap: () => context.pushTo(AppRouter.nutritionFoods),
      ),
    ],
  ),
)
```

**Nota**: FoodsScreen se mantiene como pantalla standalone, accesible solo desde Resumen.

---

## FASE 7: Mejoras Pantalla Peso

**Archivo**: `lib/features/weight/presentation/weight_screen.dart`

### 7.1 Tooltips Explicativos
```dart
AppStatCard(
  label: 'Tendencia',
  value: result.trendWeight.toStringAsFixed(1),
  infoTooltip: 'Media móvil de 7 días que suaviza las fluctuaciones diarias',
)
```

### 7.2 Gráfica de Evolución
**Nueva dependencia**: `fl_chart` (ya está en pubspec)

Añadir card con gráfica de línea:
- X: Fechas (últimos 30 días)
- Y: Peso
- Línea de tendencia (suavizada)
- Puntos en días con registro

### 7.3 Contexto de Progreso
Añadir card con:
- "Llevas X días registrando peso"
- "Variación desde inicio: Y kg"
- "Promedio semanal: Z kg"

---

## FASE 8: Fixes Menores

### 8.1 Fix Snackbar Vacío
**Archivos**: 
- `lib/core/widgets/app_snackbar.dart` (revisar implementación)
- `lib/features/home/presentation/entry_screen.dart:267`

Si `AppSnackbar.show` tiene bug, reemplazar por:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Peso registrado')),
);
```

### 8.2 Fix Home Navigation
**Archivo**: `lib/core/router/app_router.dart`

Añadir botón volver en HomeScreen AppBar:
```dart
AppBar(
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => context.go(AppRouter.entry),
  ),
)
```

O usar `WillPopScope` / `PopScope` para manejar back button.

---

## Archivos a Modificar/Crear

### Nuevos Archivos
```
lib/
├── core/
│   ├── models/
│   │   └── user_profile_model.dart
│   └── services/
│       └── tdee_calculator.dart
├── features/
│   └── settings/
│       ├── presentation/
│       │   ├── settings_screen.dart
│       │   └── complete_profile_dialog.dart
│       └── providers/
│           └── settings_providers.dart
```

### Archivos Modificados
```
lib/
├── core/
│   ├── local_db/
│   │   └── app_database.dart (añadir tabla UserProfiles)
│   ├── providers/
│   │   └── database_provider.dart (añadir providers perfil)
│   └── router/
│       └── app_router.dart (nueva ruta settings)
├── features/
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart (cambiar tabs)
│   ├── diary/
│   │   └── presentation/
│   │       ├── diary_screen.dart (reorganizar)
│   │       └── food_search_screen.dart (integrar OFF)
│   ├── summary/
│   │   └── presentation/
│   │       └── summary_screen.dart (quitar settings, añadir link alimentos)
│   └── weight/
│       └── presentation/
│           └── weight_screen.dart (añadir gráfica)
└── diet/
    └── screens/
        └── coach/
            └── plan_setup_screen.dart (fix slider, añadir TDEE auto)
```

---

## Orden de Implementación Recomendado

| Fase | Descripción | Estado | Tiempo Est. |
|------|-------------|--------|-------------|
| 1 | Perfil + Tabla DB + Navegación | ✅ Completada | 2-3h |
| 2 | Settings Screen + TDEE Calc + Fix Coach Slider | ✅ Completada | 2-3h |
| 3 | Reorganizar Diario (FatSecret) | 🔄 Pendiente | 4-5h |
| 4 | Smart Import + Búsqueda Unificada | 🔄 Pendiente | 4-5h |
| 5 | Gráfica Peso + Tooltips | 🔄 Pendiente | 2-3h |
| 6 | Fixes menores | 🔄 Pendiente | 30min |

**Total estimado**: 17-23 horas de trabajo | **Completado**: ~5-6h | **Restante**: ~11-16h

---

## Resumen de Fases Completadas

### ✅ Fase 1: Estructura Base
- Modelo UserProfileModel con Gender y ActivityLevel
- Tabla UserProfiles en Drift (schema v6)
- Repositorio DriftUserProfileRepository
- SettingsScreen con edición de perfil
- Navegación reorganizada: Diario | Peso | Resumen | Coach | Perfil

### ✅ Fase 2: Coach Fixes + TDEE Integration
- **FIX CRÍTICO**: Slider de velocidad corregido (0.1% a 2.5% positivo)
- TDEE calculado automáticamente desde perfil (Mifflin-St Jeor)
- Peso pre-llenado desde último registro
- Diálogo para completar perfil si faltan datos

---

## Siguiente Paso: Fase 3

**Reorganizar Diario (Estilo FatSecret)**:
- 4 secciones expandibles (Desayuno, Almuerzo, Cena, Snack)
- Cada sección con su botón "+ Añadir"
- Eliminar FAB redundante
- Mostrar macros en header de cada sección

**¿Continuamos con la Fase 3?**

---

*Plan actualizado: 30/01/2026 - Fases 1-2 completadas*
