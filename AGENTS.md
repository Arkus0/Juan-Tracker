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
- **Gráficos calendario**: `table_calendar` ^3.2.0
- **Notificaciones locales**: `flutter_local_notifications` ^20.0.0
- **Audio**: `just_audio` ^0.9.34
- **OCR**: `google_mlkit_text_recognition` ^0.15.0
- **Voz**: `speech_to_text` ^7.0.0
- **Share**: `share_plus` ^12.0.1

---

## Project Structure

```
lib/
├── main.dart                    # Entry point, inicializa locale 'es'
├── app.dart                     # MaterialApp con tema personalizado
├── core/                        # Código compartido entre features
│   ├── app_constants.dart       # Constantes globales (appName)
│   ├── local_db/               # Seeds para base de datos
│   ├── models/                 # Modelos básicos (Food, WeightEntry, DiaryEntry)
│   ├── providers/              # Providers core (database, food, weight, diary)
│   └── repositories/           # Repositorios para nutrición
├── features/                    # Features de NUTRICIÓN
│   ├── diary/                  # Diario de alimentos
│   ├── foods/                  # Gestión de alimentos
│   ├── home/                   # Entry point dieta (HomeScreen)
│   ├── summary/                # Resumen/TDEE
│   └── weight/                 # Tracking de peso corporal
└── training/                    # Feature de ENTRENAMIENTO (más complejo)
    ├── database/               # Drift database + tablas + migraciones
    ├── features/exercises/     # Búsqueda de ejercicios
    ├── models/                 # Modelos del dominio (Sesion, Ejercicio, SerieLog, Rutina)
    ├── providers/              # Riverpod providers (training, voice, progression)
    ├── repositories/           # Repositorios especializados
    ├── screens/                # UI screens
    ├── services/               # Servicios nativos (timer, voz, OCR, haptics)
    ├── utils/                  # Strings y design system
    └── widgets/                # Widgets reutilizables

test/                           # Tests unitarios y de widget
├── core/                       # Tests de lógica de negocio
└── features/                   # Tests de UI

docs/                           # Documentación de porting/specs
scripts/                        # Scripts de utilidad (extract_providers.dart)
assets/                         # Fuentes, sonidos, datos JSON
```

---

## Build Commands

```bash
# Ejecutar en Android
flutter run -d android

# Ejecutar en web local
flutter run -d chrome

# Build web release
flutter build web --release

# Tests
flutter test

# Codegen (Drift) - REQUERIDO tras modificar tablas o @DriftDatabase
dart run build_runner build --delete-conflicting-outputs

# Ver dependencias desactualizadas
flutter pub outdated

# Limpiar build
flutter clean && flutter pub get
```

---

## Code Style Guidelines

### Idioma
- **UI**: Español (textos visibles al usuario)
- **Código/Variables**: Inglés preferido, español permitido para dominio específico
- **Comentarios**: Español

### Estructura de archivos
```
lib/training/models/sesion.dart           # Modelos: inmutables, copyWith, helpers
lib/training/repositories/i_training_repository.dart  # Interfaces abstractas
lib/training/repositories/drift_training_repository.dart  # Implementación
lib/training/providers/training_provider.dart  # Notifier/AsyncNotifier
lib/training/screens/main_screen.dart     # ConsumerWidget/ConsumerStatefulWidget
lib/training/widgets/session/exercise_card.dart  # Widgets reutilizables
```

### Patrones de código

**Modelos**: Inmutables con `copyWith`:
```dart
class Sesion {
  final String id;
  final DateTime fecha;
  // ...
  Sesion copyWith({...}) => ...;
}
```

**Providers**: Riverpod 3 Notifier pattern:
```dart
final myProvider = NotifierProvider<MyNotifier, State>(MyNotifier.new);

class MyNotifier extends Notifier<State> {
  @override
  State build() => initialState;
  
  void update() => state = newState;
}
```

**Repositorios**: Interfaz + Implementación con delegación:
```dart
abstract class ITrainingRepository {
  Stream<List<Sesion>> watchSesionesHistory();
  Future<void> saveSesion(Sesion sesion);
}

class DriftTrainingRepository implements ITrainingRepository {
  final AppDatabase db;
  late final SessionRepository _sessionRepo = SessionRepository(db);
  // Delegación por feature
}
```

### Linter
Usa `flutter_lints` v6.0.0. Config en `analysis_options.yaml`.

### Patrones de código seguros

**Manejo de BuildContext después de operaciones async**:
```dart
// ❌ INCORRECTO: Puede causar crash si el widget se desmontó
final result = await someAsyncOperation();
Navigator.of(context).pop();  // Risky!

// ✅ CORRECTO: Verificar mounted antes de usar context
final result = await someAsyncOperation();
if (context.mounted) {  // o simplemente if (mounted) en StatefulWidget
  Navigator.of(context).pop();
}
```

**SharePlus API (share_plus ^12.0.1)**:
```dart
// ❌ DEPRECATED: API antigua de share_plus
Share.share(text, subject: '...');

// ✅ CORRECTO: Nueva API SharePlus
await SharePlus.instance.share(
  ShareParams(text: text, subject: '...'),
);
```

## Notas recientes para agentes (correcciones importantes)
> Pequeñas lecciones extraídas al arreglar errores comunes del repositorio.

- **Riverpod 3 / Notifier**: El proyecto usa Riverpod v3. Cuando migres `StateNotifier`/`StateProvider` a la API nueva, prefiere `Notifier` + `NotifierProvider`. Evita manipular `.state` desde fuera de la implementación del `Notifier`; expón setters o métodos en el `Notifier` (ej.: `set query(String)` o `set meal(MealType)`). Esto mejora encapsulación y evita warnings `invalid_use_of_visible_for_testing_member`.

- **Exports y nombres duplicados**: No reexportes tipos que puedan colisionar en la API global (ej.: `MealType` existe en más de un paquete). Si necesitas reexportar providers, hazlo de forma selectiva y con `show` o usa prefijos de import (`as diet`) para evitar `ambiguous_import`.

- **withOpacity deprecado**: Para evitar pérdida de precisión y advertencias, prefiere `withAlpha((factor * 255).round())` o `withValues()` en lugar de `withOpacity()` cuando el linter sugiere `withValues`.

- **BuildContext y `mounted`**: Evita usar `BuildContext` tras `await` si el widget puede desmontarse. Si necesitas hacer `Navigator.pop()` después de esperar, guarda el `Navigator.of(context)` en una variable antes del `await` o comprueba `if (mounted)` antes de usar el contexto.

- **Formateo en UI**: Para mostrar valores numéricos (peso, volumen, etc.) formatea enteros sin decimal (ej.: mostrar `100` en vez de `100.0`) para que los tests de widgets que busquen texto coincidan exactamente.

- **Tests y adaptadores temporales**: En tests de integración/logic que mezclan APIs antiguas y nuevas, usa adaptadores temporales (shim objects) para no cambiar la API de producción.

> Estas notas **no** cambian las reglas de estilo globales, son recomendaciones prácticas para evitar los errores más frecuentes que aparecieron al corregir el repo.

**ColorScheme (Material 3)**:
```dart
// ❌ DEPRECATED: background fue reemplazado por surface
ColorScheme(background: Colors.black)
scheme.background

// ✅ CORRECTO: Usar surface
ColorScheme(surface: Colors.black)
scheme.surface
// Para scaffoldBackgroundColor: scheme.surface
```

**Control flow structures**:
```dart
// ❌ INCORRECTO: If sin llaves (linter: curly_braces_in_flow_control_structures)
if (condition) return true;

// ✅ CORRECTO: Siempre usar llaves
if (condition) {
  return true;
}
```

**Imports en tests**:
```dart
// ❌ INCORRECTO: No usar package:test en proyectos Flutter
import 'package:test/test.dart';

// ✅ CORRECTO: Usar flutter_test
import 'package:flutter_test/flutter_test.dart';
```

**Ignorar warnings intencionales**:
```dart
// ignore: unused_element
void _unusedPrivateMethod() { }

// ignore: deprecated_member_use
final db = WebDatabase('name');  // APIs deprecated conocidas
```

---

## Testing Instructions

### Tests existentes
```bash
flutter test
```

Cobertura actual:
- `test/core/macros_test.dart` - Cálculos nutricionales
- `test/core/tdee_test.dart` - Cálculos TDEE
- `test/core/training/*` - Repositorios y controller de sesión
- `test/features/training/*` - Widget tests de UI
- `test/diet/*` - Tests de capa de datos de Diet (Food, Diary, WeighIn, Targets)

### Escribir nuevos tests

**Unit test**: Repositorios, controllers, lógica pura
```dart
test('addSet aumenta volumen total', () {
  final controller = TrainingSessionController();
  controller.startSession(id: '1');
  controller.addSet(ejercicioId: 'ex1', peso: 100, reps: 10);
  expect(controller.state.activeSession!.totalVolume, 1000.0);
});
```

**Widget test**: Screens y widgets
```dart
testWidgets('HistoryScreen muestra agrupación correcta', (tester) async {
  await tester.pumpWidget(ProviderScope(child: MaterialApp(
    home: HistoryScreen(),
  )));
  expect(find.text('ESTA SEMANA'), findsOneWidget);
});
```

**Integration**: Tests manuales en dispositivo para features nativas (OCR, voz, notificaciones).

---

## Database (Drift)

### Tablas principales

#### Training
- `Routines` - Rutinas de entrenamiento
- `RoutineDays` - Días dentro de una rutina
- `RoutineExercises` - Ejercicios configurados en un día
- `Sessions` - Sesiones completadas (o activas si `completedAt` is null)
- `SessionExercises` - Ejercicios realizados en una sesión
- `WorkoutSets` - Series individuales (peso, reps, RPE)
- `ExerciseNotes` - Notas por ejercicio

#### Diet (Schema v5)
- `Foods` - Alimentos guardados (macros por 100g y/o porción, flags: userCreated, verifiedSource)
- `DiaryEntries` - Entradas del diario (date, mealType, amount, macros calculados)
- `WeighIns` - Registros de peso corporal (measuredAt, weightKg, note)
- `Targets` - Objetivos diarios versionados por fecha (kcal, protein, carbs, fat)
- `Recipes` - Recetas/comidas compuestas (totales calculados, porciones)
- `RecipeItems` - Ingredientes de recetas (snapshot de macros del food)

### Estructura de la capa de datos Diet
```
lib/diet/
├── models/           # Modelos de dominio puros
│   ├── food_model.dart
│   ├── diary_entry_model.dart
│   ├── weighin_model.dart
│   ├── targets_model.dart
│   └── recipe_model.dart
├── repositories/     # Interfaces + Implementación Drift
│   ├── food_repository.dart
│   ├── diary_repository.dart
│   ├── weighin_repository.dart
│   ├── targets_repository.dart
│   └── drift_diet_repositories.dart
└── providers/        # Providers de Riverpod
    ├── diet_providers.dart
    └── diary_ui_providers.dart
```

### Providers de UI para Diet

**Providers de estado global (diet_providers.dart):**
- `appDatabaseProvider` - Singleton de base de datos Drift
- `foodRepositoryProvider` - Repositorio de alimentos
- `diaryRepositoryProvider` - Repositorio de diario
- `weighInRepositoryProvider` - Repositorio de pesos
- `targetsRepositoryProvider` - Repositorio de objetivos

**Providers de UI del Diario (diary_ui_providers.dart):**
- `selectedDateProvider` - Fecha seleccionada (StateNotifier)
- `dayEntriesStreamProvider` - Stream de entradas del día
- `dailyTotalsProvider` - Stream de totales diarios
- `entriesByMealProvider` - Entradas filtradas por mealType
- `mealTotalsProvider` - Totales por tipo de comida
- `foodSearchResultsProvider` - Resultados de búsqueda de alimentos
- `editingEntryProvider` - Entrada en edición actual
- `selectedMealTypeProvider` - Tipo de comida seleccionado

**Providers legacy (core/providers/) - Adaptadores para compatibilidad:**
- `dayEntriesProvider` - Adapta Stream de entradas a modelos antiguos
- `dayTotalsProvider` - Adapta totales a modelo antiguo
- `foodListStreamProvider` - Stream de alimentos
- `searchFoodsProvider` - Búsqueda de alimentos
- `weightListStreamProvider` - Stream de pesos
- `latestWeightProvider` - Último peso registrado

### Migraciones
Schema version actual: **5**
- v1 → v2: Agrega `supersetId` a `routine_exercises`
- v2 → v3: Agrega progresión (`progressionType`, `weightIncrement`, `targetRpe`) y day info
- v3 → v4: Agrega flag `isBadDay` para tolerancia de errores
- v4 → v5: Agrega tablas de Diet (`Foods`, `DiaryEntries`, `WeighIns`, `Targets`, `Recipes`, `RecipeItems`)

**IMPORTANTE**: Tras modificar tablas, ejecutar:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Esto regenera `lib/training/database/database.g.dart`.

---

## Key Features & Architecture

### Entrenamiento (Training)

**Flujo de sesión**:
1. `MainScreen` → Tab "ENTRENAR" (índice 1 por defecto)
2. Seleccionar rutina o sesión libre
3. `TrainingSessionScreen` con:
   - Registro de series (peso/reps/RPE)
   - Timer de descanso con notificaciones
   - Input por voz (speech-to-text)
   - Sugerencias de progresión
   - DESHACER última serie

**Arquitectura por capas**:
```
UI (Screens/Widgets)
  ↓
Providers (Riverpod Notifiers) - Estado + Lógica de UI
  ↓
ITrainingRepository (Interface)
  ↓
DriftTrainingRepository → Repositorios especializados → AppDatabase
```

**Servicios nativos**:
- `VoiceInputService` - Speech-to-text para input rápido
- `TimerPlatformService` - Timer con notificaciones en background
- `RoutineOcrService` - OCR para importar rutinas desde imágenes
- `HapticsController` - Feedback háptico
- `MediaControlService` - Controles de música durante sesión

### Nutrición (Diet)

**Features**:
- Diario diario con totales calóricos
- Base de datos de alimentos (local + custom)
- Tracking de peso corporal con gráficos
- Resumen semanal/mensual

---

## Development Workflow

### Setup inicial
```bash
flutter pub get
```

### Desarrollo día a día
```bash
# Terminal 1: Ejecutar app
flutter run -d android

# Terminal 2: Watch para codegen (si editas tablas Drift)
dart run build_runner watch --delete-conflicting-outputs
```

### Antes de commitear
1. `flutter analyze` - Sin warnings
2. `flutter test` - Todos pasan
3. Formato: `dart format lib/ test/`

---

## Security Considerations

- **Datos sensibles**: Todo local, sin backend. SharedPreferences para settings.
- **Permisos Android**: Cámara (OCR), Micrófono (voz), Notificaciones (timer).
- **No hardcodear**: API keys (si se añaden servicios externos) deben ir en `.env` (no commiteado).

---

## Useful Resources

- `docs/TRAINING_MVP_NOTES.md` - Notas del MVP de entrenamiento
- `docs/PORTING_SPEC.md` - Spec para portar la "alma" a otros repos
- `docs/porting_starter/` - Código starter para reimplementación

---

## Common Issues

**Error**: `database.g.dart` no encontrado o desactualizado
**Fix**: `dart run build_runner build --delete-conflicting-outputs`

**Error**: Permisos de notificaciones en Android
**Fix**: Verificar `AndroidManifest.xml` tiene permisos necesarios

**Error**: Locale español no funciona en fechas
**Fix**: `main.dart` llama `initializeDateFormatting('es')` antes de runApp

**Warning**: `use_build_context_synchronously` después de operaciones async
**Fix**: Verificar `if (context.mounted)` o `if (mounted)` antes de usar `BuildContext`

**Warning**: `curly_braces_in_flow_control_structures` en if sin llaves
**Fix**: Siempre usar llaves: `if (x) { return; }`

**Warning**: `deprecated_member_use` para `Share.share` o `ColorScheme.background`
**Fix**: Ver sección "Patrones de código seguros" arriba para las APIs correctas

**Warning**: `depend_on_referenced_packages` en tests
**Fix**: Cambiar `import 'package:test/test.dart'` por `import 'package:flutter_test/flutter_test.dart'`

---

*Última actualización: Enero 2026*
