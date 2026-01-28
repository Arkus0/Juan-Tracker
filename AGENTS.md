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
- `Routines` - Rutinas de entrenamiento
- `RoutineDays` - Días dentro de una rutina
- `RoutineExercises` - Ejercicios configurados en un día
- `Sessions` - Sesiones completadas (o activas si `completedAt` is null)
- `SessionExercises` - Ejercicios realizados en una sesión
- `WorkoutSets` - Series individuales (peso, reps, RPE)
- `ExerciseNotes` - Notas por ejercicio

### Migraciones
Schema version actual: **4**
- v1 → v2: Agrega `supersetId` a `routine_exercises`
- v2 → v3: Agrega progresión (`progressionType`, `weightIncrement`, `targetRpe`) y day info
- v3 → v4: Agrega flag `isBadDay` para tolerancia de errores

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

---

*Última actualización: Enero 2026*
