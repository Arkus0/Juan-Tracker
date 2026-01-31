# AGENTS.md - Juan Tracker

> Este archivo contiene información esencial para agentes de código AI que trabajen en este proyecto. El idioma principal del proyecto es **español** (UI, comentarios y documentación).

---

## Project Overview

**Juan Tracker** es una aplicación Flutter multi-módulo para tracking personal que combina:

1. **Nutrición/Dieta**: Diario de alimentos, gestión de peso, resumen calórico (TDEE)
2. **Entrenamiento**: Sesiones de gym, rutinas, biblioteca de ejercicios, análisis de progreso

La app está diseñada **Android-first** pero también soporta web. Usa arquitectura limpia con Riverpod 3 para state management y Drift para persistencia local SQLite.

### Tech Stack

- **Framework**: Flutter ^3.10.7
- **State Management**: `flutter_riverpod` ^3.0.0 (Notifier/AsyncNotifier)
- **Base de datos**: `drift` ^2.22.0 (SQLite con codegen)
- **UI**: Material 3 + `google_fonts` (Montserrat/Oswald)
- **Charts**: `fl_chart` ^1.1.1
- **Calendario**: `table_calendar` ^3.2.0
- **Notificaciones**: `flutter_local_notifications` ^20.0.0
- **Audio**: `just_audio` ^0.9.34
- **OCR**: `google_mlkit_text_recognition` ^0.15.0
- **Voz**: `speech_to_text` ^7.0.0
- **Navegación**: `go_router` ^14.8.1

---

## Project Structure

```
lib/
├── main.dart                    # Entry point, inicializa locale 'es'
├── app.dart                     # MaterialApp con tema personalizado
├── core/                        # Código compartido entre features
│   ├── design_system/           # Tokens, colores, tipografía
│   ├── router/                  # GoRouter configuration
│   ├── providers/               # Providers globales (database, diary)
│   └── widgets/                 # Widgets reutilizables
├── features/                    # Features de NUTRICIÓN
│   ├── diary/                   # Diario de alimentos
│   ├── foods/                   # Gestión de alimentos
│   ├── home/                    # Entry point dieta (EntryScreen)
│   ├── targets/                 # Objetivos diarios
│   ├── weight/                  # Tracking de peso
│   └── today/                   # Pantalla HOY unificada
├── diet/                        # Capa de datos de nutrición
│   ├── models/                  # Modelos de dominio puros
│   ├── repositories/            # Interfaces + Implementaciones Drift
│   ├── providers/               # Riverpod providers
│   └── services/                # Servicios de cálculo puros
└── training/                    # Feature de ENTRENAMIENTO
    ├── database/                # Drift database + tablas
    ├── models/                  # Modelos del dominio
    ├── providers/               # Riverpod providers
    ├── repositories/            # Repositorios especializados
    ├── screens/                 # UI screens
    ├── services/                # Servicios nativos (timer, voz, OCR)
    └── widgets/                 # Widgets reutilizables
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

---

## Database (Drift)

### Schema v7

**Training:**
- `Routines`, `RoutineDays`, `RoutineExercises`
- `Sessions`, `SessionExercises`, `WorkoutSets`

**Diet:**
- `Foods`, `DiaryEntries`, `WeighIns`, `Targets`, `Recipes`, `RecipeItems`
- `FoodsFts` - Tabla FTS5 para búsqueda de texto (sincronización manual)
- `SearchHistory` - Historial de búsquedas
- `ConsumptionPatterns` - Patrones de consumo para ML

**Nota importante sobre FTS5:**
Los triggers automáticos para sincronizar `foods` con `foods_fts` fueron eliminados porque FTS5 requiere `rowid` INTEGER pero usamos UUIDs TEXT. La sincronización debe hacerse manualmente mediante los métodos `insertFoodFts()`, `updateFoodFts()`, `deleteFoodFts()` en `AppDatabase`.

### Providers Clave

```dart
// Core
appDatabaseProvider
diaryRepositoryProvider
foodRepositoryProvider

// Diary
selectedDateProvider
dayEntriesStreamProvider
daySummaryProvider
calendarEntryDaysProvider  // Días con registros (para calendario)
smartFoodSuggestionsProvider  // Sugerencias basadas en historial

// Weight
weightStreamProvider
weightTrendProvider

// Training
trainingSessionProvider
deloadAlertsProvider
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
- 242 tests pasando
- Tests de servicios puros, repositorios, UI

**Patrones:**
```dart
// Usar flutter_test, NO package:test
import 'package:flutter_test/flutter_test.dart';

// Modelos NO son const (usan DateTime.now())
final model = MyModel(id: '1');  // ✅
const model = MyModel(id: '1'); // ❌
```

---

## Checklist para Nuevos Features

- [ ] ¿A qué modo pertenece (Nutrición/Entrenamiento/Ambos)?
- [ ] ¿Requiere cambios en schema de DB?
- [ ] ¿Funciona offline?
- [ ] ¿Usa el Design System unificado?
- [ ] ¿Maneja `mounted` después de async?
- [ ] ¿Tiene tests unitarios para lógica pura?
- [ ] `flutter analyze` sin errores
- [ ] `flutter test` pasa

---

*Última actualización: Enero 2026 - Sistema de búsqueda inteligente implementado, 242 tests*
