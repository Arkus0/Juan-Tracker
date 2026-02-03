# AGENTS.md - Juan Tracker

> Este archivo contiene información esencial para agentes de código AI que trabajen en este proyecto. El idioma principal del proyecto es **español** (UI, comentarios y documentación).

---

## Project Overview

**Juan Tracker** es una aplicación Flutter multi-módulo para tracking personal que combina:

1. **Nutrición/Dieta**: Diario de alimentos, gestión de peso, resumen calórico (TDEE), coach adaptativo
2. **Entrenamiento**: Sesiones de gym, rutinas, biblioteca de ejercicios, análisis de progreso

La app está diseñada **Android-first** pero también soporta web. Usa arquitectura limpia con Riverpod 3 para state management y Drift para persistencia local SQLite.

### Tech Stack

- **Framework**: Flutter ^3.10.7
- **State Management**: `flutter_riverpod` ^3.0.0 (Notifier/AsyncNotifier)
- **Base de datos**: `drift` ^2.22.0 (SQLite con codegen)
- **UI**: Material 3 + `google_fonts` (Montserrat)
- **Charts**: `fl_chart` ^1.1.1
- **Calendario**: `table_calendar` ^3.2.0
- **Notificaciones**: `flutter_local_notifications` ^20.0.0
- **Audio**: Beeps nativos via ToneGenerator (no usa just_audio para timer)
- **OCR**: `google_mlkit_text_recognition` ^0.15.0
- **Voz**: `speech_to_text` ^7.0.0
- **Navegación**: `go_router` ^14.6.3
- **HTTP**: `dio` ^5.8.0 + `http` ^1.3.0
- **Barcode**: `mobile_scanner` ^6.0.7

---

## Project Structure

```
lib/
├── main.dart                    # Entry point, inicializa locale 'es', SharedPreferences
├── app.dart                     # MaterialApp.router con tema personalizado + DatabaseLoadingScreen
├── core/                        # Código compartido entre features
│   ├── design_system/           # Tokens (AppColors, AppSpacing, AppRadius, AppTypography)
│   ├── router/                  # GoRouter configuration (app_router.dart)
│   ├── navigation/              # Router legacy (no usado actualmente)
│   ├── providers/               # Providers globales (database, diary, etc.)
│   ├── repositories/            # Interfaces + implementaciones de repositorios
│   ├── services/                # Interfaces de servicios (tdee_calculator)
│   ├── models/                  # Modelos compartidos (user_profile, food, weight_entry, etc.)
│   ├── widgets/                 # Widgets reutilizables (AppCard, AppButton, etc.)
│   ├── onboarding/              # SplashWrapper, OnboardingScreen
│   ├── tdee/                    # Cálculos TDEE
│   ├── feedback/                # Sistema de feedback
│   ├── settings/                # Theme provider
│   └── local_db/seeds/          # Seed data
├── features/                    # Features de NUTRICIÓN (presentation layer)
│   ├── diary/presentation/      # DiaryScreen
│   ├── foods/                   # FoodSearchUnifiedScreen, providers de búsqueda
│   ├── home/presentation/       # EntryScreen, HomeScreen, TodayScreen
│   ├── settings/presentation/   # SettingsScreen (perfil/nutrición)
│   ├── summary/presentation/    # SummaryScreen (resumen calórico)
│   └── weight/presentation/     # WeightScreen
├── diet/                        # Capa de datos de nutrición
│   ├── models/                  # Modelos de dominio (FoodModel, DiaryEntryModel, etc.)
│   ├── repositories/            # AlimentoRepository, CoachRepository, etc.
│   ├── providers/               # FoodSearchNotifier, weight_trend_providers, etc.
│   ├── screens/coach/           # CoachScreen, PlanSetupScreen, WeeklyCheckInScreen
│   ├── services/                # WeightTrendCalculator, AdaptiveCoachService, OCR
│   └── presentation/providers/  # Providers alternativos de búsqueda
└── training/                    # Feature de ENTRENAMIENTO (módulo autocontenido)
    ├── database/                # AppDatabase (Drift) - TODAS las tablas aquí
    ├── models/                  # Modelos del dominio (Ejercicio, Sesion, Rutina, SerieLog, etc.)
    ├── providers/               # Training providers (trainingRepositoryProvider, trainingSessionProvider)
    ├── repositories/            # Repositorios (DriftTrainingRepository, RoutineRepository, etc.)
    ├── screens/                 # UI screens (TrainingSessionScreen, AnalysisScreen, HistoryScreen, etc.)
    ├── services/                # TimerAudioService, NativeBeepService, OCR, voz
    ├── training_shell.dart      # Shell de navegación de entrenamiento
    ├── features/exercises/      # Subsistema de búsqueda de ejercicios
    ├── utils/                   # design_system.dart (legacy), strings
    └── widgets/                 # Widgets reutilizables (ExerciseCard, RestTimerBar, etc.)
```

---

## Build Commands

```bash
# Ejecutar en Android
flutter run -d android

# Tests
flutter test

# Codegen (Drift) - REQUERIDO tras modificar tablas
dart run build_runner build --delete-conflicting-outputs

# Limpiar build
flutter clean && flutter pub get
```

---

## Code Style Guidelines

### Idioma
- **UI**: Español (textos visibles al usuario)
- **Código/Variables**: Inglés preferido, español permitido para dominio específico
- **Comentarios**: Español

### Patrones de código

**Riverpod 3 Notifier pattern:**
```dart
final myProvider = NotifierProvider<MyNotifier, State>(MyNotifier.new);

class MyNotifier extends Notifier<State> {
  @override
  State build() => initialState;
  
  void update() => state = newState;
}
```

**Repositorios:**
```dart
abstract class IFoodRepository {
  Future<List<FoodModel>> getAll();
}

class DriftFoodRepository implements IFoodRepository {
  final AppDatabase db;
  // Implementación
}
```

### Patrones de código seguros

**BuildContext después de async:**
```dart
final result = await someAsyncOperation();
if (context.mounted) {
  Navigator.of(context).pop();
}
```

**withAlpha vs withOpacity:**
```dart
// ✅ Correcto
.color.withAlpha((0.15 * 255).round())
```

---

## Design System Conventions (PR1-PR3 Alignment)

> Resultado del esfuerzo de alineación visual entre secciones Diet y Training.

### Principios

1. **Theme First**: Siempre usar `Theme.of(context).colorScheme` primero
2. **Tokens Second**: `AppTypography`, `AppSpacing`, `AppRadius` del core
3. **NO hardcoded**: Evitar `Colors.grey[800]`, `Colors.white`, etc.
4. **NO GoogleFonts directo**: Usar `AppTypography` en lugar de `GoogleFonts.montserrat()`

### Jerarquía de Imports

```dart
// 1. Core design system (preferido)
import '../../../core/design_system/design_system.dart' show AppTypography;

// 2. Training-specific colors (cuando sea necesario)
import '../../utils/design_system.dart' show AppColors;

// ❌ NUNCA importar ambos sin 'show' (conflicto de nombres)
// import '../../../core/design_system/design_system.dart';
// import '../../utils/design_system.dart'; // ¡Conflicto! Ambos definen AppColors
```

### Patrones de UI Consistentes

**Dialogs (Material 3):**
```dart
// ✅ Correcto - Usar Material 3 theme
showDialog(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text('Título', style: AppTypography.titleMedium),
    content: Text('Contenido'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCELAR')),
      FilledButton(onPressed: () {}, child: Text('GUARDAR')),
    ],
  ),
);

// ❌ Incorrecto - Colores hardcodeados
AlertDialog(
  backgroundColor: AppColors.bgElevated, // No usar en nuevos dialogs
  title: Text('Título', style: GoogleFonts.montserrat(...)), // Nunca
)
```

**Snackbars:**
```dart
// ✅ Correcto - Usar AppSnackbar
AppSnackbar.show(context, message: 'Guardado');
AppSnackbar.showError(context, message: 'Error');
AppSnackbar.showWithUndo(context, message: 'Eliminado', onUndo: () => restore());

// ❌ Incorrecto - ScaffoldMessenger directo
ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))
```

**Cards:**
```dart
// ✅ Correcto - AppCard o Card con theme
AppCard(child: ...)

// o
Card(
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: ...,
  ),
)
```

### Estado de Migración (Febrero 2026)

| Área | Estado | Notas |
|------|--------|-------|
| `core/widgets/` | ✅ Completo | AppCard, AppButton, AppEmpty, AppLoading, AppError, AppSnackbar |
| `core/design_system/` | ✅ Completo | AppTypography, AppColors, AppSpacing, AppRadius |
| `training/widgets/` | ✅ Migrado | Todos los widgets usan core design system |
| `training/screens/` | ✅ Migrado | Todas las pantallas migradas |
| Código duplicado | ✅ Eliminado | Ya no existe features/training/presentation/ ni modelos duplicados en core/ |

### Deuda Técnica Conocida

El archivo `training/utils/design_system.dart` mantiene un design system legacy "Aggressive Red" para compatibilidad. Los nuevos desarrollos deben usar `core/design_system/` exclusivamente.

**Estrategia:** En nuevos features usar el core design system. El archivo legacy se mantiene solo para referencias de color específicas del modo entrenamiento.

---

## Features Implementadas (Enero 2026)

### 1. Smart Food Suggestions (HIGH-003) ✅
Detección de patrones de comida habitual.
- **Algoritmo**: 30 días, umbral 40% frecuencia
- **Cantidad promedio**: Calculada de historial real
- **UI**: Chips contextuales en DiaryScreen

### 2. Deload Alerts (MED-005) ✅
Detección de estancamiento en ejercicios.
- Widget en AnalysisScreen (pestaña "Laboratorio")
- Alertas por severidad (warning/critical)

### 3. Calendar Indicators (MED-002) ✅
Dots en calendario mensual indicando días con registros.

### 4. OCR Import (TODO-3) ✅
Importar rutinas desde imágenes con ML Kit.

### 5. Coach Adaptativo ✅
Sistema de ajuste de targets basado en TDEE real.
- Fórmula: `TDEE_real = AVG_kcal - (ΔTrendWeight × 7700 / días)`
- Check-in semanal con propuestas de ajuste

### 6. Sistema de Búsqueda Inteligente de Alimentos (NUEVO) ✅
Búsqueda híbrida local + Open Food Facts con debounce y cancelación.
- **FTS5**: Tabla virtual para búsqueda por texto completo
- **Debounce**: 300ms para reducir llamadas API
- **Cancelación**: CancelToken de Dio para requests en vuelo
- **Ranking**: Por frecuencia de uso, recencia, y verificación
- **Providers**: `FoodSearchNotifier`, `predictiveFoodsProvider`, `recentSearchesProvider`
- **UI**: `FoodSearchBar` con autocompletado, `FoodSearchResults` con estados (loading, empty, offline, error)

### 7. Goal Projection / ETA (Febrero 2026) ✅
Proyección de peso hacia objetivo estilo Libra.
- **ETA**: Fecha estimada para alcanzar peso objetivo
- **Cálculo**: Basado en `hwTrend` (Holt-Winters) de WeightTrendResult
- **Progress**: Barra de progreso + porcentaje
- **On-Track**: Badge indicando si el ritmo actual lleva al objetivo
- **Model**: `GoalProjection` con métodos de predicción
- **Providers**: `goalProjectionProvider`, `goalEtaDaysProvider`, `isOnTrackProvider`
- **UI**: `_GoalProjectionCard` en WeightScreen
- **Docs**: `docs/feature_goal_projection.md`

### 8. Goal Line in Weight Chart (Febrero 2026) ✅
Línea horizontal punteada mostrando peso objetivo en gráfico.
- **Visual**: Línea verde punteada (`dashArray: [8, 4]`) a la altura del objetivo
- **Integración**: Usa `effectiveGoalWeightProvider` existente
- **Y-Axis**: Bounds ajustados automáticamente para incluir goal
- **UI**: Modificado `_WeightLineChart` en WeightScreen

### 9. Quick Actions / Repeat Yesterday (Febrero 2026) ✅
Acceso rápido para registro de alimentos frecuentes.
- **Repeat Yesterday**: Botón para copiar todas las comidas del día anterior
- **Repeat Meal**: Copiar comidas de una sola comida (desayuno, almuerzo, etc.)
- **Recent Foods**: Chips con los 6 alimentos más recientes (últimos 7 días)
- **Providers**: `yesterdayMealsProvider`, `repeatYesterdayProvider`, `repeatMealFromYesterdayProvider`, `quickRecentFoodsProvider`
- **UI**: `_QuickActionsCard` en DiaryScreen con chips interactivos

### 10. Weekly History Insights (Febrero 2026) ✅
Resumen semanal con métricas de adherencia y tendencias.
- **Adherence**: Porcentaje de días dentro del ±10% del objetivo calórico
- **Averages**: Promedio de kcal, proteínas, carbohidratos, grasas
- **Week Comparison**: Diferencia vs semana anterior (↑/↓ con color)
- **Visual**: Badge de adherencia (Excelente >80%, Buena 60-80%, Mejorable <60%)
- **Model**: `WeeklyInsight` con weekLabel, adherencePercentage, avgKcal, macros
- **Providers**: `weeklyInsightsProvider` (últimas 4 semanas), `currentWeekInsightProvider`
- **UI**: `_WeeklyInsightsCard` en SummaryScreen

### 11. Meal Templates (Febrero 2026) ✅
Guardar comidas como plantillas reutilizables con 1 toque.
- **Guardar**: PopupMenuButton en cada sección de comida → "Guardar como plantilla"
- **Aplicar**: Chips en _QuickActionsCard con las 4 plantillas más usadas
- **Modelo**: `MealTemplateModel` con items anidados (`MealTemplateItemModel`)
- **Snapshots**: Valores nutricionales guardados por 100g para cálculo dinámico
- **Providers**: `mealTemplatesProvider`, `topMealTemplatesProvider`, `saveMealAsTemplateProvider`, `useMealTemplateProvider`, `deleteMealTemplateProvider`
- **Repository**: `MealTemplateRepository` con CRUD completo
- **UI**: `_TemplateChip` en Quick Actions, dialog de guardado con nombre

---

## Database (Drift)

### Schema v12 (Actual)

**Training:**
- `Routines` - Rutinas con `schedulingMode` y `schedulingConfig` (v9)
- `RoutineDays` - Días con `weekdays` y `minRestHours` (v9)
- `RoutineExercises` - Ejercicios con progresión
- `Sessions` - Sesiones con `isBadDay` flag (v4)
- `SessionExercises` - Ejercicios de sesión
- `WorkoutSets` - Series registradas
- `ExerciseNotes` - Notas por ejercicio

**User:**
- `UserProfiles` - Perfil de usuario para TDEE (v6)

**Diet:**
- `Foods` - Alimentos con `isFavorite`, `useCount`, `lastUsedAt`, `nutriScore`, `novaGroup` (v7+)
- `DiaryEntries` - Entradas del diario
- `WeighIns` - Registros de peso
- `Targets` - Objetivos calóricos versionados
- `Recipes`, `RecipeItems` - Recetas compuestas
- `MealTemplates`, `MealTemplateItems` - Plantillas de comidas reutilizables (v12)

**Search System (v7+):**
- `FoodsFts` - Tabla FTS5 virtual (food_id UNINDEXED, name, brand)
- `SearchHistory` - Historial de búsquedas
- `ConsumptionPatterns` - Patrones de consumo para ML

**Nota importante sobre FTS5:**
La tabla `foods_fts` usa una estructura personalizada con `food_id` como columna UNINDEXED (no rowid). 
La sincronización es manual mediante `insertFoodFts()`, `rebuildFtsIndex()` en `AppDatabase`.

### Providers Clave

```dart
// Core Database
appDatabaseProvider              // AppDatabase singleton
diaryRepositoryProvider          // IDiaryRepository (Drift)
foodRepositoryProvider           // IFoodRepository (Drift)
weighInRepositoryProvider        // IWeighInRepository (Drift)
targetsRepositoryProvider        // ITargetsRepository (Drift)
alimentoRepositoryProvider       // AlimentoRepository (búsqueda avanzada)

// UI State
selectedDateProvider             // Fecha seleccionada en diario

// Diary Streams
dayEntriesStreamProvider         // Stream de entradas del día
dailyTotalsProvider              // Stream de totales diarios
calendarEntryDaysProvider        // Set<DateTime> días con registros

// Food Search
foodSearchProvider               // FoodSearchNotifier (búsqueda híbrida)
foodSearchResultsProvider        // Resultados de búsqueda
predictiveFoodsProvider          // Alimentos predictivos
recentSearchesProvider           // Historial de búsquedas

// Smart Suggestions
smartFoodSuggestionsProvider     // Sugerencias basadas en historial

// Quick Actions
yesterdayMealsProvider           // Comidas de ayer por tipo
repeatYesterdayProvider          // Copiar todas las comidas de ayer
quickRecentFoodsProvider         // 6 alimentos recientes para chips

// Meal Templates
mealTemplatesProvider            // Todas las plantillas guardadas
topMealTemplatesProvider         // 4 plantillas más usadas
saveMealAsTemplateProvider       // Guardar comida actual como plantilla
useMealTemplateProvider          // Aplicar plantilla al diario

// Weekly Insights
weeklyInsightsProvider           // Últimas 4 semanas de insights
currentWeekInsightProvider       // Insight de la semana actual

// Weight
weightStreamProvider             // Stream de pesos (90 días)
weightTrendProvider              // Tendencia calculada (EMA, Kalman, etc.)
latestWeightProvider             // Último peso registrado
goalProjectionProvider           // Proyección hacia peso objetivo

// Training
trainingSessionProvider          // Estado de sesión activa
trainingSettingsProvider         // Configuración de entrenamiento

// Coach
coachRepositoryProvider          // CoachRepository (SharedPreferences)
```

---

## Design System

**Import:**
```dart
import 'core/design_system/design_system.dart';
```

**Tokens:**
- `AppColors.primary` - Terracota `#DA5A2A`
- `AppColors.secondary` - Teal
- `AppTypography.titleMedium`
- `AppSpacing.lg` (16.0)
- `AppRadius.md` (12.0)

**Componentes:**
```dart
AppCard(child: ...)
AppButton(onPressed: ..., child: ...)
AppEmpty(icon: ..., title: ...)
AppLoading(message: ...)
```

---

## Navegación (GoRouter)

**Extensiones:**
```dart
context.goToNutrition();
context.goToDiary();
context.goToTraining();
context.pushTo('/ruta');
```

**Rutas principales:**
- `/` - EntryScreen
- `/nutrition/diary` - Diario
- `/nutrition/foods` - Alimentos
- `/training` - Entrenamiento
- `/training/routines` - Rutinas

---

## Testing

```bash
flutter test
```

**Cobertura:**
- 33+ archivos de test
- Tests de servicios puros, repositorios, UI, providers
- Áreas cubiertas: WeightTrendCalculator, DaySummaryCalculator, AdaptiveCoachService, 
  FTS search, OCR parsing, voice input, router, providers

**Patrones:**
```dart
// Usar flutter_test, NO package:test
import 'package:flutter_test/flutter_test.dart';

// Modelos NO son const (usan DateTime.now())
final model = MyModel(id: '1');  // ✅
const model = MyModel(id: '1'); // ❌
```

---

## CI/CD

**GitHub Actions:**
- `android-ci.yml` - Build APK + tests en emulador Android
- `preview-web.yml` - Deploy a Vercel en PRs

**Scripts:**
- `wait-for-emulator.sh` - Script para CI (espera boot del emulador)

---

## ⚠️ CRÍTICO: Sistema de Búsqueda FTS5

> **LEER ANTES DE TOCAR CUALQUIER QUERY SQL DE ALIMENTOS**

### Nombres de Columnas en Drift

Drift convierte nombres camelCase a snake_case **SIN guion bajo antes de números**:

| Dart (en tabla)    | SQL real (en DB)   | ❌ INCORRECTO      |
|--------------------|--------------------|--------------------|
| `kcalPer100g`      | `kcal_per100g`     | `kcal_per_100g`    |
| `proteinPer100g`   | `protein_per100g`  | `protein_per_100g` |
| `carbsPer100g`     | `carbs_per100g`    | `carbs_per_100g`   |
| `fatPer100g`       | `fat_per100g`      | `fat_per_100g`     |

**Para verificar nombres reales**: Revisar `database.g.dart` (archivo generado por Drift).

### Arquitectura de Búsqueda FTS5

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUJO DE BÚSQUEDA                            │
├─────────────────────────────────────────────────────────────────┤
│  Usuario escribe "leche"                                        │
│       ↓                                                         │
│  FoodSearchNotifier.search() [150ms debounce]                   │
│       ↓                                                         │
│  AlimentoRepository.search()                                    │
│       ↓                                                         │
│  AppDatabase.searchFoodsFTS() ← AQUÍ ESTÁ LA MAGIA              │
│       ↓                                                         │
│  Estrategia de 3 pasos:                                         │
│    1. AND query: "leche*" (más preciso)                         │
│    2. OR query: "leche* OR desnatada*" (si AND=0)               │
│    3. Sinónimos: expandQueryWithSynonyms() (último recurso)     │
│       ↓                                                         │
│  _executeFtsQuery() [2 queries separadas]:                      │
│    a) SELECT food_id FROM foods_fts WHERE MATCH ?               │
│    b) SELECT * FROM foods WHERE id IN (...)                     │
│       ↓                                                         │
│  _mapRowToFood() → Lista de Food                                │
│       ↓                                                         │
│  Ranking en AlimentoRepository._applyRanking()                  │
│       ↓                                                         │
│  UI muestra resultados                                          │
└─────────────────────────────────────────────────────────────────┘
```

### Query FTS5 Correcta (¡COPIAR ESTO!)

```dart
/// Helper to execute FTS query and map results
Future<List<Food>> _executeFtsQuery(String ftsQuery, int limit) async {
  // PASO 1: Buscar IDs en tabla FTS5
  final ftsResults = await customSelect(
    'SELECT food_id FROM foods_fts WHERE foods_fts MATCH ? LIMIT ?',
    variables: [Variable(ftsQuery), Variable(limit)],
  ).get();
  
  if (ftsResults.isEmpty) return [];
  
  // PASO 2: Obtener alimentos completos por IDs
  final foodIds = ftsResults.map((r) => r.data['food_id'] as String).toList();
  final placeholders = List.filled(foodIds.length, '?').join(',');
  
  final results = await customSelect(
    'SELECT id, name, normalized_name, brand, barcode, '
    'kcal_per100g, protein_per100g, carbs_per100g, fat_per100g, '  // ← SIN guion bajo antes de 100
    'portion_name, portion_grams, user_created, verified_source, '
    'source_metadata, use_count, last_used_at, nutri_score, nova_group, '
    'is_favorite, created_at, updated_at '
    'FROM foods WHERE id IN ($placeholders)',
    variables: foodIds.map((id) => Variable(id)).toList(),
  ).get();
  
  return results.map((row) => _mapRowToFood(row)).toList();
}
```

### ¿Por qué 2 queries separadas?

La tabla `foods_fts` usa `food_id UNINDEXED` (no es rowid). Un JOIN directo como:
```sql
-- ❌ NO FUNCIONA BIEN
SELECT f.* FROM foods f 
INNER JOIN foods_fts fts ON f.id = fts.food_id 
WHERE foods_fts MATCH ?
```
Causa problemas de sintaxis. La solución es **2 queries separadas**:
1. Obtener IDs del índice FTS
2. Obtener datos completos de `foods` con IN clause

### Sinónimos Españoles

Archivo: `lib/diet/utils/spanish_text_utils.dart`

- 180+ sinónimos en 80 grupos semánticos
- `expandQueryWithSynonyms()`: Genera query OR con sinónimos de una palabra
- Solo sinónimos sin espacios (multi-palabra se ignoran para FTS)
- Ejemplo: "leche" → "leche* OR lacteo* OR desnatada* OR descremada*"

---

## 🔒 Patrones de Seguridad Críticos (Post-Sprint 2)

### SQL Injection Prevention

> **REGLA DE ORO**: NUNCA concatenar input de usuario en queries SQL.

**✅ Correcto - Parametrización completa:**
```dart
// lib/training/database/database.dart
Future<List<Food>> _searchFoodsLike(String query, {int limit = 50}) async {
  final terms = normalized.split(' ').where((t) => t.isNotEmpty).toList();
  final whereConditions = <String>[];
  final variables = <Variable<Object>>[];  // Type-safe variables
  
  for (final term in terms) {
    // Escapar caracteres especiales de LIKE
    final escapedTerm = term.replaceAll('%', '\\%').replaceAll('_', '\\_');
    whereConditions.add(
      "(LOWER(name) LIKE ? ESCAPE '\\' OR LOWER(COALESCE(brand, '')) LIKE ? ESCAPE '\\')"
    );
    // Placeholders parametrizados
    variables.add(Variable('%$escapedTerm%'));
    variables.add(Variable('%$escapedTerm%'));
  }
  
  final whereClause = whereConditions.join(' AND ');
  variables.add(Variable<int>(limit));
  
  final results = await customSelect(
    'SELECT * FROM foods WHERE $whereClause LIMIT ?',
    variables: variables,  // ✅ Seguro: nunca concatena input del usuario
  ).get();
}
```

**❌ Incorrecto - Concatenación directa (VULNERABLE):**
```dart
// NUNCA hacer esto
String whereClause = terms.map((t) => 
  "(LOWER(name) LIKE '%$t%' ...)"  // ❌ SQL Injection!
).join(' AND ');
```

### CancelToken Pattern para Requests HTTP

```dart
// lib/diet/repositories/alimento_repository.dart
class AlimentoRepository {
  CancelToken? _cancelToken;
  
  AlimentoRepository(this._db) {
    _cancelToken = CancelToken();  // Inicializar en constructor
  }
  
  Future<List<ScoredFood>> searchOnline(String query) async {
    // Cancelar búsqueda anterior si existe
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('New search started');
    }
    _cancelToken = CancelToken();  // Nuevo token para esta búsqueda
    
    try {
      return await _dio.get(..., cancelToken: _cancelToken);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return [];  // Búsqueda cancelada - no es error
      }
      rethrow;
    }
  }
  
  void cancelPendingRequests() {
    _cancelToken?.cancel('Cancelled by user');
    _cancelToken = CancelToken();
  }
}
```

### Memory Management - LRU Cache

```dart
// lib/training/utils/performance_utils.dart
class MemoCache<K, V> {
  final Map<K, _MemoEntry<V>> _cache = {};
  final List<K> _lruKeys = [];  // Track access order
  final int maxSize;  // Límite para prevenir OOM
  
  MemoCache({this.maxSize = 1000});  // Default seguro
  
  V getOrCompute(K key, V Function() compute) {
    // Evict LRU si es necesario
    if (_cache.length >= maxSize && _lruKeys.isNotEmpty) {
      final lruKey = _lruKeys.first;
      _cache.remove(lruKey);
      _lruKeys.removeAt(0);
    }
    
    // ... resto de lógica
  }
}
```

---

## 🏗️ Arquitectura Post-Refactorización (Sprint 2)

### TrainingSessionNotifier - Decomposition

El God Object original (>1000 líneas) ha sido decompuesto en servicios especializados:

```
TrainingSessionNotifier (UI State + Coordination)
    │
    ├── RestTimerController (Timer state + notifications)
    ├── SessionPersistenceService (Save/restore + debounce)
    └── SessionHistoryManager (LRU cache de historial)
```

**Ventajas:**
- Testabilidad: Cada servicio puede testearse aislado
- Reutilización: SessionHistoryManager se puede usar en otros features
- Mantenibilidad: Cambios en timer no afectan persistencia

### TelemetryService - Monitoreo en Producción

```dart
// Uso básico
TelemetryService().recordMetric(
  MetricNames.foodSearchLocal,
  value: elapsedMs,
  tags: {'query_length': query.length},
);

// Medir automáticamente
final results = await TelemetryService().measureAsync(
  MetricNames.dbLoadFoods,
  () => loader.loadDatabase(),
);

// Ver estadísticas
final stats = TelemetryService().getStats(MetricNames.foodSearchLocal);
print(stats);  // count=150, mean=12.5ms, p95=45ms, p99=89ms
```

---

## Known Pitfalls

1. **FTS5 sync**: Después de insertar alimentos, llamar `rebuildFtsIndex()` o `insertFoodFts()` manualmente.
2. **Timer audio**: Usar `TimerAudioService` que delega a `NativeBeepService` (ToneGenerator), NO just_audio.
3. **BuildContext async**: Siempre verificar `context.mounted` después de `await`.
4. **Drift codegen**: Ejecutar `dart run build_runner build` después de modificar tablas.
5. **GoRouter vs Navigator**: Usar extensiones de `context.goTo*()`, no `Navigator.push()`.
6. **Búsqueda de alimentos**: Sistema unificado en `AlimentoRepository` (local FTS5 + Open Food Facts). NO existe ya el sistema en `diet/data/` ni `diet/domain/`.
7. **⚠️ NOMBRES DE COLUMNAS SQL**: Drift genera `kcal_per100g` NO `kcal_per_100g`. Ver sección "Sistema de Búsqueda FTS5" arriba.
8. **FTS5 queries**: Usar 2 queries separadas (FTS → IDs → SELECT foods). NO usar JOIN directo con foods_fts.
9. **Training providers**: Los providers de entrenamiento están en `training/providers/`, NO en `core/providers/`. El repositorio de training usa Drift (`DriftTrainingRepository`), no InMemory.
10. **Training models**: Los modelos de entrenamiento (Sesion, Ejercicio, Rutina, SerieLog) están en `training/models/`, NO en `core/models/`.

---

## Checklist para Nuevos Features

- [ ] ¿A qué modo pertenece (Nutrición/Entrenamiento/Ambos)?
- [ ] ¿Requiere cambios en schema de DB? → Incrementar `schemaVersion` en `database.dart`
- [ ] ¿Funciona offline?
- [ ] ¿Usa el Design System unificado? (`AppColors`, `AppSpacing`, `AppRadius`)
- [ ] ¿Maneja `mounted` después de async?
- [ ] ¿Tiene tests unitarios para lógica pura?
- [ ] `flutter analyze` sin errores
- [ ] `flutter test` pasa

---

*Última actualización: Febrero 2026 - Schema v11, estructura actualizada*
