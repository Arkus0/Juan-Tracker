# AGENTS.md - Juan Tracker

> Este archivo contiene informaciÃ³n esencial para agentes de cÃ³digo AI que trabajen en este proyecto. El idioma principal del proyecto es **espaÃ±ol** (UI, comentarios y documentaciÃ³n).

---

## Project Overview

**Juan Tracker** es una aplicaciÃ³n Flutter multi-mÃ³dulo para tracking personal que combina:

1. **NutriciÃ³n/Dieta**: Diario de alimentos, gestiÃ³n de peso, resumen calÃ³rico (TDEE)
2. **Entrenamiento**: Sesiones de gym, rutinas, biblioteca de ejercicios, anÃ¡lisis de progreso

La app estÃ¡ diseÃ±ada **Android-first** pero tambiÃ©n soporta web. Usa arquitectura limpia con Riverpod 3 para state management y Drift para persistencia local SQLite.

### Tech Stack

- **Framework**: Flutter ^3.10.7
- **State Management**: `flutter_riverpod` ^3.0.0 (Notifier/AsyncNotifier)
- **Base de datos**: `drift` ^2.22.0 (SQLite con codegen)
- **UI**: Material 3 + `google_fonts` (Montserrat/Oswald)
- **Charts**: `fl_chart` ^1.1.1
- **GrÃ¡ficos calendario**: `table_calendar` ^3.2.0
- **Notificaciones locales**: `flutter_local_notifications` ^20.0.0
- **Audio**: `just_audio` ^0.9.34
- **OCR**: `google_mlkit_text_recognition` ^0.15.0
- **Voz**: `speech_to_text` ^7.0.0
- **Share**: `share_plus` ^12.0.1
- **Barcode Scanning**: `mobile_scanner` ^6.0.11

---

## Project Structure

```
lib/
â”œâ”€â”€ main.dart                    # Entry point, inicializa locale 'es'
â”œâ”€â”€ app.dart                     # MaterialApp con tema personalizado
â”œâ”€â”€ core/                        # CÃ³digo compartido entre features
â”‚   â”œâ”€â”€ app_constants.dart       # Constantes globales (appName)
â”‚   â”œâ”€â”€ local_db/               # Seeds para base de datos
â”‚   â”œâ”€â”€ models/                 # Modelos bÃ¡sicos (Food, WeightEntry, DiaryEntry)
â”‚   â”œâ”€â”€ providers/              # Providers core (database, food, weight, diary)
â”‚   â””â”€â”€ repositories/           # Repositorios para nutriciÃ³n
â”œâ”€â”€ features/                    # Features de NUTRICIÃ“N
â”‚   â”œâ”€â”€ diary/                  # Diario de alimentos
â”‚   â”œâ”€â”€ foods/                  # GestiÃ³n de alimentos
â”‚   â”œâ”€â”€ home/                   # Entry point dieta (HomeScreen)
â”‚   â”œâ”€â”€ summary/                # Resumen/TDEE
â”‚   â”œâ”€â”€ weight/                 # Tracking de peso corporal
â”‚   â””â”€â”€ coach/                  # Coach Adaptativo (MacroFactor-style)
â”œâ”€â”€ diet/                       # Capa de datos y servicios de nutrición
â”‚   â”œâ”€â”€ models/                # Modelos de dominio
â”‚   â”œâ”€â”€ repositories/          # Interfaces + Implementaciones Drift
â”‚   â”œâ”€â”€ providers/             # Riverpod providers
â”‚   â”œâ”€â”€ services/              # Servicios de cálculo puros
â”‚   â””â”€â”€ screens/coach/         # UI del Coach Adaptativo
â””â”€â”€ training/                    # Feature de ENTRENAMIENTO (mÃ¡s complejo)
    â”œâ”€â”€ database/               # Drift database + tablas + migraciones
    â”œâ”€â”€ features/exercises/     # BÃºsqueda de ejercicios
    â”œâ”€â”€ models/                 # Modelos del dominio (Sesion, Ejercicio, SerieLog, Rutina)
    â”œâ”€â”€ providers/              # Riverpod providers (training, voice, progression)
    â”œâ”€â”€ repositories/           # Repositorios especializados
    â”œâ”€â”€ screens/                # UI screens
    â”œâ”€â”€ services/               # Servicios nativos (timer, voz, OCR, haptics)
    â”œâ”€â”€ utils/                  # Strings y design system
    â””â”€â”€ widgets/                # Widgets reutilizables

test/                           # Tests unitarios y de widget
â”œâ”€â”€ core/                       # Tests de lÃ³gica de negocio
â”œâ”€â”€ diet/                       # Tests de capa de datos (models, repos, services)
â”‚   â”œâ”€â”€ services/              # Tests de servicios puros (DaySummaryCalculator, AdaptiveCoachService)
â”‚   â””â”€â”€ providers/             # Tests de providers
â””â”€â”€ features/                   # Tests de UI

docs/                           # DocumentaciÃ³n de porting/specs
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
- **UI**: EspaÃ±ol (textos visibles al usuario)
- **CÃ³digo/Variables**: InglÃ©s preferido, espaÃ±ol permitido para dominio especÃ­fico
- **Comentarios**: EspaÃ±ol

### Estructura de archivos
```
lib/training/models/sesion.dart           # Modelos: inmutables, copyWith, helpers
lib/training/repositories/i_training_repository.dart  # Interfaces abstractas
lib/training/repositories/drift_training_repository.dart  # ImplementaciÃ³n
lib/training/providers/training_provider.dart  # Notifier/AsyncNotifier
lib/training/screens/main_screen.dart     # ConsumerWidget/ConsumerStatefulWidget
lib/training/widgets/session/exercise_card.dart  # Widgets reutilizables
```

### Patrones de cÃ³digo

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

**Repositorios**: Interfaz + ImplementaciÃ³n con delegaciÃ³n:
```dart
abstract class ITrainingRepository {
  Stream<List<Sesion>> watchSesionesHistory();
  Future<void> saveSesion(Sesion sesion);
}

class DriftTrainingRepository implements ITrainingRepository {
  final AppDatabase db;
  late final SessionRepository _sessionRepo = SessionRepository(db);
  // DelegaciÃ³n por feature
}
```

### Linter
Usa `flutter_lints` v6.0.0. Config en `analysis_options.yaml`.

### Patrones de cÃ³digo seguros

**Manejo de BuildContext despuÃ©s de operaciones async**:
```dart
// âŒ INCORRECTO: Puede causar crash si el widget se desmontÃ³
final result = await someAsyncOperation();
Navigator.of(context).pop();  // Risky!

// âœ… CORRECTO: Verificar mounted antes de usar context
final result = await someAsyncOperation();
if (context.mounted) {  // o simplemente if (mounted) en StatefulWidget
  Navigator.of(context).pop();
}
```

**SharePlus API (share_plus ^12.0.1)**:
```dart
// âŒ DEPRECATED: API antigua de share_plus
Share.share(text, subject: '...');

// âœ… CORRECTO: Nueva API SharePlus
await SharePlus.instance.share(
  ShareParams(text: text, subject: '...'),
);
```

## Notas recientes para agentes (correcciones importantes)
> PequeÃ±as lecciones extraÃ­das al arreglar errores comunes del repositorio.

- **Servicios de cÃ¡lculo puros**: Para lÃ³gica compleja (cÃ¡lculos, agregaciones), crear servicios 100% puros Dart en `lib/diet/services/` o `lib/training/services/`. 
  - Ejemplo: `DaySummaryCalculator` combina totales consumidos + objetivos sin depender de Flutter ni DB.
  - Ejemplo: `WeightTrendCalculator` implementa múltiples modelos (EMA, Holt-Winters, Filtro de Kalman, Regresión Lineal) para análisis avanzado de tendencias de peso. Todo offline sin redes neuronales.
  - Ejemplo: `AdaptiveCoachService` calcula TDEE real y ajusta targets basado en datos del usuario (ingesta + cambio de peso). Determinista, testeable, sin dependencias externas.
  - Facilita testing unitario y reutilizaciÃ³n.

- **Riverpod 3 / Notifier**: El proyecto usa Riverpod v3. Cuando migres `StateNotifier`/`StateProvider` a la API nueva, prefiere `Notifier` + `NotifierProvider`. Evita manipular `.state` desde fuera de la implementaciÃ³n del `Notifier`; expÃ³n setters o mÃ©todos en el `Notifier` (ej.: `set query(String)` o `set meal(MealType)`). Esto mejora encapsulaciÃ³n y evita warnings `invalid_use_of_visible_for_testing_member`.

- **Exports y nombres duplicados**: No reexportes tipos que puedan colisionar en la API global (ej.: `MealType` existe en mÃ¡s de un paquete). Si necesitas reexportar providers, hazlo de forma selectiva y con `show` o usa prefijos de import (`as diet`) para evitar `ambiguous_import`.

- **withOpacity deprecado**: Para evitar pÃ©rdida de precisiÃ³n y advertencias, prefiere `withAlpha((factor * 255).round())` o `withValues()` en lugar de `withOpacity()` cuando el linter sugiere `withValues`.

- **BuildContext y `mounted`**: Evita usar `BuildContext` tras `await` si el widget puede desmontarse. Si necesitas hacer `Navigator.pop()` despuÃ©s de esperar, guarda el `Navigator.of(context)` en una variable antes del `await` o comprueba `if (mounted)` antes de usar el contexto.

- **Formateo en UI**: Para mostrar valores numÃ©ricos (peso, volumen, etc.) formatea enteros sin decimal (ej.: mostrar `100` en vez de `100.0`) para que los tests de widgets que busquen texto coincidan exactamente.

- **Constructores const en tests**: Los modelos de dominio (`TargetsModel`, `DaySummary`, etc.) NO tienen constructores `const` porque usan `DateTime.now()` como default. En tests, usar `final` en lugar de `const`:
  ```dart
  // âŒ INCORRECTO: TargetsModel no es const
  const target = TargetsModel(id: '1', ...);
  
  // âœ… CORRECTO: Usar final
  final target = TargetsModel(id: '1', ...);
  ```

- **Tests y adaptadores temporales**: En tests de integraciÃ³n/logic que mezclan APIs antiguas y nuevas, usa adaptadores temporales (shim objects) para no cambiar la API de producciÃ³n.

> Estas notas **no** cambian las reglas de estilo globales, son recomendaciones prÃ¡cticas para evitar los errores mÃ¡s frecuentes que aparecieron al corregir el repo.

**ColorScheme (Material 3)**:
```dart
// âŒ DEPRECATED: background fue reemplazado por surface
ColorScheme(background: Colors.black)
scheme.background

// âœ… CORRECTO: Usar surface
ColorScheme(surface: Colors.black)
scheme.surface
// Para scaffoldBackgroundColor: scheme.surface
```

**Control flow structures**:
```dart
// âŒ INCORRECTO: If sin llaves (linter: curly_braces_in_flow_control_structures)
if (condition) return true;

// âœ… CORRECTO: Siempre usar llaves
if (condition) {
  return true;
}
```

**Imports en tests**:
```dart
// âŒ INCORRECTO: No usar package:test en proyectos Flutter
import 'package:test/test.dart';

// âœ… CORRECTO: Usar flutter_test
import 'package:flutter_test/flutter_test.dart';
```

**GrÃ¡ficos con fl_chart**:
```dart
// LineChart requiere FlSpot(x, y) y configuraciÃ³n de ejes
LineChart(
  LineChartData(
    gridData: FlGridData(show: true, drawVerticalLine: false),
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
    ),
    lineBarsData: [
      LineChartBarData(
        spots: dataPoints.map((p) => FlSpot(index, value)).toList(),
        isCurved: true,
        color: scheme.primary,
      ),
    ],
  ),
)
```
- Ver ejemplo completo en `lib/features/weight/presentation/weight_screen.dart` (grÃ¡fico de peso con lÃ­nea de tendencia EMA)
- Ver ejemplo en `lib/training/widgets/analysis/strength_trend.dart` (tendencia de fuerza)

**Ignorar warnings intencionales**:
```dart
// ignore: unused_element
void _unusedPrivateMethod() { }

// ignore: deprecated_member_use
final db = WebDatabase('name');  // APIs deprecated conocidas
```

---

### Cambios recientes y lecciones (Timer nativo y telemetría) ✅
> Resumen de la implementación y aprendizajes obtenidos tras añadir soporte nativo para el temporizador de descanso y telemetría (Enero 2026).

- **Foreground Service nativo**: Se añadió `TimerForegroundService.kt` como implementación nativa del temporizador (start/update/stop) y se declaró en `AndroidManifest.xml` (permiso `FOREGROUND_SERVICE`). `MainActivity.kt` ahora responde a `startTimerService`, `updateTimerService`, `stopTimerService` y devuelve `true` al arrancar el servicio nativo con éxito.

- **Comportamiento de notificación**: La notificación de descanso es persistente y contiene acciones (Pausar / Reanudar / +30s / Saltar). Si el servicio nativo está activo usamos **solo** el servicio nativo para evitar duplicados y para garantizar que la notificación se gestione aun si el Flutter engine muere.

- **Beep nativo y audio focus**: Los beeps se reproducen nativamente con `AudioTrack` (mismas frecuencias y duraciones que antes) y usan `STREAM_NOTIFICATION` para NO interrumpir la música del usuario. **No** se introdujo ningún beep nuevo ni extraño cuando se siguieron estas reglas; cuidado con duplicados si Dart y el servicio nativo reproducen a la vez (ahora evitado).

- **Canal de eventos entre nativo y Dart**: Se agregó `TimerEventBridge` en `MainActivity.kt` y el servicio invoca eventos (`onServiceStarted`, `onServiceStopped`, `onFinished`, `onPause`, `onResume`, `onAdd30`, `onSkip`) para que Dart reciba notificaciones del lifecycle nativo.

- **Telemetría ligera**: Se agregó `TelemetryService` en `lib/core/telemetry_service.dart`. Eventos instrumentados de ejemplo:
  - `timer_start` (platform: native|flutter_fallback, seconds)
  - `notification_start`, `notification_update`, `notification_stop`
  - `timer_finished`, `service_started`, `service_stopped`
  - `notification_action` (pause/resume/add30/skip)
  - `notification_fallback_to_flutter` (cuando se usa fallback Dart)
  Recomendación: integrar Sentry/Firebase para envío remoto y alertas en producción.

- **Mitigaciones y pruebas**:
  - Probar en múltiples OEM (Xiaomi, Huawei, Samsung) y escenarios (app background, bloqueo de pantalla, cambios rápidos de app) — algunos fabricantes tienen políticas agresivas de background.
  - Checklist de QA: ver acciones de notificación, beeps en thresholds, desaparición de notificación al terminar y que los beeps no pausen música en reproducción.

- **Lecciones aprendidas**:
  - Preferir lógica nativa para funcionalidades críticas en background.
  - Evitar duplicar responsabilidades entre Dart y nativo: un único "source of truth" reduce errores y race conditions.
  - Telemetría desde el inicio facilita reproducir incidentes en producción.

### Errores recientes y cómo evitarlos (checklist práctico) ✅
- AndroidManifest / permisos
  - Coloca `<uses-permission>` fuera del `<application>` (a nivel de manifest).
  - Usa valores `foregroundServiceType` **documentados**; por ejemplo `mediaPlayback`. Evita escribir valores inválidos como `media|location` sin verificar el nombre exacto permitido por la SDK. Si dudas, prueba con `flutter build apk` para atrapar errores de linkeo de recursos.
- Kotlin/Platform changes
  - Cuando agregues llamadas nativas (Intents, Build.VERSION, PendingIntent) recuerda añadir imports: `android.content.Intent`, `android.os.Build`, `android.app.PendingIntent`, etc. Ejecuta `./gradlew assembleDebug` (o `flutter run`) temprano para detectar errores de compilación nativos.
- Widgets y árbol de la UI
  - Evita intentar mostrar `Scaffold` fuera de `MaterialApp`/`WidgetsApp` (error común: "No Directionality widget found"). Si añades un `SplashWrapper`, colócalo como `home` dentro de `MaterialApp`, no por encima.
- Beeps & audio
  - Evita duplicados: cuando arranque el servicio nativo marca `nativeStarted=true` y desactiva el `Timer.periodic`/beeps en Dart para no reproducir beeps dos veces.
  - Usa `STREAM_NOTIFICATION` o equivalente para beeps de temporizador (no pedir Audio Focus) y configura la notificación con `playSound=false` si solo quieres beeps nativos.
- Telemetría y logging
  - Instrumenta eventos clave: `timer_start`, `notification_start`, `notification_update`, `timer_finished`, `service_started`, `service_stopped`, `notification_action`, `beep_played`.
  - No incluir PII en eventos. Añade breadcrumbs para errores críticos y usa sampling en producción si la frecuencia es alta.
- QA / OEM tests
  - Prueba en varios OEMs (Xiaomi, Huawei, Samsung) y escenarios (app background, bloqueos de pantalla, cambios rápidos de app). Algunos OEMs aplican políticas agresivas a servicios en background.
  - Manual checklist: iniciar timer → bloquear pantalla → esperar finalización → verificar notificación desaparece y que los beeps suenan.

### Lecciones de Refactorización UX/UI (Enero 2026) ✅
> Aprendizajes de la refactorización visual masiva - Design System unificado y mejoras de UX.

#### Resumen de Cambios Realizados
- **Design System Unificado**: Nuevo sistema de tokens en `lib/core/design_system/`
  - Paleta consistente: Primario terracota `#DA5A2A`
  - Dos temas: Nutrición (claro) y Entrenamiento (oscuro)
  - Componentes base: AppCard, AppButton, AppStatCard, AppInput
  - Animaciones estandarizadas: 150ms/250ms/400ms
  
- **Pantallas Rediseñadas**:
  - EntryScreen: Saludo dinámico, cards con gradiente, accesos rápidos
  - DiaryScreen: Calendario semanal horizontal, macro donut chart
  - WeightScreen: 3 stat cards, indicador de fase, lista simplificada
  - RutinasScreen: Grid moderno con preview de días
  
- **Onboarding Completo**:
  - Splash animado con logo
  - 4 páginas de onboarding (bienvenida, nutrición, entrenamiento, coach)
  - Sistema de haptics global (`AppHaptics`)
  - Transiciones suaves entre modos
  
- **Dark Mode Toggle**: Persistencia en SharedPreferences, selector en bottom sheet

#### Errores Cometidos y Soluciones

**1. Conflictos de Design System Legacy vs Nuevo**
```
// ❌ PROBLEMA: Importar ambos design systems causa ambiguous_import
import 'core/design_system/app_theme.dart';
import 'training/utils/design_system.dart';  // <- Legacy, no usar

// ✅ SOLUCIÓN: Usar solo el nuevo design system centralizado
import 'core/design_system/design_system.dart';  // Exporta todo
```

**2. Nombres de tokens inconsistentes**
```dart
// ❌ PROBLEMA: Algunos archivos usan nombres antiguos
AppColors.techCyan      // <- No existe en nuevo DS
AppColors.timerActive   // <- No existe
AppColors.bgElevated    // <- No existe (usar surfaceContainerHighest)

// ✅ SOLUCIÓN: Usar nombres estandarizados
AppColors.secondary     // <- teal/cyan
AppColors.primary       // <- terracota
AppColors.success       // <- verde
```

**3. Imports de Riverpod confusos**
```dart
// ❌ PROBLEMA: StateNotifier vs Notifier en Riverpod 3
class MyNotifier extends StateNotifier<State>  // <- API antigua

// ✅ SOLUCIÓN: Usar Notifier (Riverpod 3)
class MyNotifier extends Notifier<State> {
  @override
  State build() => initialState;
}
```

**4. Valores nullable sin manejo**
```dart
// ❌ PROBLEMA: toStringAsFixed en valores nullable
text: '${food.proteinPer100g.toStringAsFixed(1)}g',  // <- Crash si null

// ✅ SOLUCIÓN: Operador de null-aware con fallback
text: '${food.proteinPer100g?.toStringAsFixed(1) ?? '0'}g',
```

#### Checklist para Futuras Refactorizaciones UI

**Antes de empezar:**
- [ ] Verificar qué design system usa cada pantalla (legacy vs nuevo)
- [ ] Identificar imports problemáticos con `flutter analyze`
- [ ] Planificar migración gradual si hay conflictos graves

**Durante el desarrollo:**
- [ ] Usar solo `core/design_system/design_system.dart` (barrel export)
- [ ] Verificar nombres de tokens en `app_theme.dart`
- [ ] Manejar valores nullable con `?.` y `??`
- [ ] Usar `AppHaptics` en lugar de `HapticFeedback` directo

**Antes de commit:**
- [ ] `flutter analyze` sin errores (warnings de librerías externas OK)
- [ ] Probar en modo claro y oscuro
- [ ] Verificar que no hay imports duplicados

#### Patrones Aprobados

**Navegación con transiciones:**
```dart
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (_, animation, __) => const DestinationScreen(),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 400),
  ),
);
```

**Estados de UI consistentes:**
```dart
// Usar componentes del design system
AppEmpty(icon: Icons.xxx, title: '...', subtitle: '...')
AppLoading(message: 'Cargando...')
AppError(message: 'Error', onRetry: () {})
```

**Provider con persistencia:**
```dart
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  () => ThemeModeNotifier(),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSaved();  // Async en constructor
    return ThemeMode.system;
  }
}
```

### PR / CI checklist (imponer antes de merge) 🔁
- Código: `flutter analyze` y `flutter test` pasan en la rama.
- Android: `flutter build apk` (o `./gradlew assembleDebug`) sin errores de manifest o Kotlin.
- Manual testing steps incluidos en la descripción del PR (pasos y logs esperados).
- Telemetría: eventos instrumentados añadidos y con sample rate apropiado.
- Changelog breve en la descripción y un tag `ci/needs-manual-tests` si hay cambios nativos que requieren QA.

---

## Testing Instructions

### Tests existentes
```bash
flutter test
```

Cobertura actual:
- `test/core/macros_test.dart` - CÃ¡lculos nutricionales
- `test/core/tdee_test.dart` - CÃ¡lculos TDEE
- `test/core/training/*` - Repositorios y controller de sesiÃ³n
- `test/features/training/*` - Widget tests de UI
- `test/diet/*` - Tests de capa de datos de Diet (Food, Diary, WeighIn, Targets)

### Escribir nuevos tests

**Unit test**: Repositorios, controllers, lÃ³gica pura
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
testWidgets('HistoryScreen muestra agrupaciÃ³n correcta', (tester) async {
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
- `RoutineDays` - DÃ­as dentro de una rutina
- `RoutineExercises` - Ejercicios configurados en un dÃ­a
- `Sessions` - Sesiones completadas (o activas si `completedAt` is null)
- `SessionExercises` - Ejercicios realizados en una sesiÃ³n
- `WorkoutSets` - Series individuales (peso, reps, RPE)
- `ExerciseNotes` - Notas por ejercicio

#### Diet (Schema v5)
- `Foods` - Alimentos guardados (macros por 100g y/o porciÃ³n, flags: userCreated, verifiedSource)
- `DiaryEntries` - Entradas del diario (date, mealType, amount, macros calculados)
- `WeighIns` - Registros de peso corporal (measuredAt, weightKg, note)
- `Targets` - Objetivos diarios versionados por fecha (kcal, protein, carbs, fat)
- `Recipes` - Recetas/comidas compuestas (totales calculados, porciones)
- `RecipeItems` - Ingredientes de recetas (snapshot de macros del food)

### Estructura de la capa de datos Diet
```
lib/diet/
â”œâ”€â”€ models/           # Modelos de dominio puros
â”‚   â”œâ”€â”€ food_model.dart
â”‚   â”œâ”€â”€ diary_entry_model.dart
â”‚   â”œâ”€â”€ weighin_model.dart        # WeighIn + WeightTrend
â”‚   â”œâ”€â”€ targets_model.dart
â”‚   â””â”€â”€ recipe_model.dart
â”œâ”€â”€ repositories/     # Interfaces + ImplementaciÃ³n Drift
â”‚   â”œâ”€â”€ food_repository.dart
â”‚   â”œâ”€â”€ diary_repository.dart
â”‚   â”œâ”€â”€ weighin_repository.dart
â”‚   â”œâ”€â”€ targets_repository.dart
â”‚   â””â”€â”€ drift_diet_repositories.dart
â”œâ”€â”€ providers/        # Providers de Riverpod
â”‚   â”œâ”€â”€ diet_providers.dart
â”‚   â”œâ”€â”€ diary_ui_providers.dart
â”‚   â”œâ”€â”€ summary_providers.dart    # Providers de objetivos y resumen
â”‚   â””â”€â”€ weight_trend_providers.dart  # Providers de tendencia de peso
â””â”€â”€ services/         # Servicios de cÃ¡lculo puros (testeables)
    â”œâ”€â”€ day_summary_calculator.dart
    â””â”€â”€ weight_trend_calculator.dart  # EMA para trend de peso
```

### Providers de UI para Diet

**Providers de estado global (diet_providers.dart):**
- `appDatabaseProvider` - Singleton de base de datos Drift
- `foodRepositoryProvider` - Repositorio de alimentos
- `diaryRepositoryProvider` - Repositorio de diario
- `weighInRepositoryProvider` - Repositorio de pesos
- `targetsRepositoryProvider` - Repositorio de objetivos

**Providers de Resumen y Objetivos (summary_providers.dart):**
- `daySummaryProvider` - Resumen completo del dÃ­a (consumo + targets + progreso)
- `dayTargetsProvider` - Target activo para la fecha seleccionada (versionado)
- `allTargetsProvider` - Stream de todos los objetivos histÃ³ricos
- `targetsFormProvider` - Estado del formulario de creaciÃ³n/ediciÃ³n de targets

**Providers de UI del Diario (diary_ui_providers.dart):**
- `selectedDateProvider` - Fecha seleccionada (StateNotifier)
- `dayEntriesStreamProvider` - Stream de entradas del dÃ­a
- `dailyTotalsProvider` - Stream de totales diarios
- `entriesByMealProvider` - Entradas filtradas por mealType
- `mealTotalsProvider` - Totales por tipo de comida
- `foodSearchResultsProvider` - Resultados de bÃºsqueda de alimentos
- `editingEntryProvider` - Entrada en ediciÃ³n actual
- `selectedMealTypeProvider` - Tipo de comida seleccionado

**Providers de Peso y Tendencia (weight_trend_providers.dart):**
- `weightTrendCalculatorProvider` - Calculador EMA (Exponential Moving Average)
- `weightTrendProvider` - Trend de peso calculado con EMA
- `weightStatsProvider` - EstadÃ­sticas simplificadas (Ãºltimo peso, trend, cambio semanal)
- `weightChartDataProvider` - Datos para grÃ¡ficos de peso vs tendencia
- `recentWeighInsProvider` - Stream de weigh-ins recientes (90 dÃ­as)
- `weightTrendHistoryProvider` - Historial completo para grÃ¡ficos

**Providers legacy (core/providers/) - Adaptadores para compatibilidad:**
- `dayEntriesProvider` - Adapta Stream de entradas a modelos antiguos
- `dayTotalsProvider` - Adapta totales a modelo antiguo
- `foodListStreamProvider` - Stream de alimentos
- `searchFoodsProvider` - BÃºsqueda de alimentos
- `weightListStreamProvider` - Stream de pesos
- `latestWeightProvider` - Ãšltimo peso registrado

### Migraciones
Schema version actual: **5**
- v1 â†’ v2: Agrega `supersetId` a `routine_exercises`
- v2 â†’ v3: Agrega progresiÃ³n (`progressionType`, `weightIncrement`, `targetRpe`) y day info
- v3 â†’ v4: Agrega flag `isBadDay` para tolerancia de errores
- v4 â†’ v5: Agrega tablas de Diet (`Foods`, `DiaryEntries`, `WeighIns`, `Targets`, `Recipes`, `RecipeItems`)

**IMPORTANTE**: Tras modificar tablas, ejecutar:
```bash
dart run build_runner build --delete-conflicting-outputs
```

Esto regenera `lib/training/database/database.g.dart`.

---

## Key Features & Architecture

### Entrenamiento (Training)

**Flujo de sesiÃ³n**:
1. `MainScreen` â†’ Tab "ENTRENAR" (Ã­ndice 1 por defecto)
2. Seleccionar rutina o sesiÃ³n libre
3. `TrainingSessionScreen` con:
   - Registro de series (peso/reps/RPE)
   - Timer de descanso con notificaciones
   - Input por voz (speech-to-text)
   - Sugerencias de progresiÃ³n
   - DESHACER Ãºltima serie

**Arquitectura por capas**:
```
UI (Screens/Widgets)
  â†“
Providers (Riverpod Notifiers) - Estado + LÃ³gica de UI
  â†“
ITrainingRepository (Interface)
  â†“
DriftTrainingRepository â†’ Repositorios especializados â†’ AppDatabase
```

**Servicios nativos**:
- `VoiceInputService` - Speech-to-text para input rÃ¡pido
- `TimerPlatformService` - Timer con notificaciones en background
- `RoutineOcrService` - OCR para importar rutinas desde imÃ¡genes
- `HapticsController` - Feedback hÃ¡ptico
- `MediaControlService` - Controles de mÃºsica durante sesiÃ³n

### NutriciÃ³n (Diet)

**Features**:
- **Diario de alimentos**: Entradas por tipo de comida con cÃ¡lculo automÃ¡tico de macros
- **Base de datos de alimentos**: Local + custom con bÃºsqueda
- **Tracking de peso corporal**: GrÃ¡ficos de progreso con lÃ­nea de tendencia EMA, cambio semanal/mensual, swipe-to-delete con undo
- **Objetivos diarios (Targets)**: Versionados por fecha de inicio
  - Permite cambiar objetivos a lo largo del tiempo (bulk â†’ cut â†’ mantenimiento)
  - Cada dÃ­a usa el objetivo vigente en esa fecha especÃ­fica
  - UI tipo "budget" muestra consumido vs objetivo con barras de progreso
- **Resumen tipo budget**: Progreso visual de calorÃ­as y macros vs objetivos

**Arquitectura de Targets**:
- Tabla `Targets` en Drift con `validFrom` para versionado
- `DaySummaryCalculator` (servicio puro) calcula progreso combinando consumo + objetivo activo
- Historial completo: al cambiar objetivos, los dÃ­as pasados mantienen su target original

**Arquitectura de Weigh-ins**:
- Tabla `WeighIns` en Drift (measuredAt, weightKg, note)
- `WeightTrendCalculator` (servicio puro) implementa EMA (Exponential Moving Average) con perÃ­odo 7 dÃ­as
  - FÃ³rmula: `EMA_today = (Weight_today - EMA_yesterday) Ã— multiplier + EMA_yesterday`
  - Suaviza fluctuaciones diarias para mostrar tendencia real
  - Calcula cambio semanal/mensual comparando EMAs histÃ³ricos
  - Maneja gaps en datos (no interpola valores faltantes)
- UI en `lib/features/weight/presentation/weight_screen.dart` con:
  - Stats cards: Ãºltimo peso, trend weight (EMA), cambio semanal
  - GrÃ¡fico `fl_chart` con peso real (puntos) + lÃ­nea de tendencia EMA
  - Lista agrupada por mes con swipe-to-delete y snackbar de deshacer
  - Formularios con selector de fecha

---

## Development Workflow

### Setup inicial
```bash
flutter pub get
```

### Desarrollo dÃ­a a dÃ­a
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
- **Permisos Android**: CÃ¡mara (OCR), MicrÃ³fono (voz), Notificaciones (timer).
- **No hardcodear**: API keys (si se aÃ±aden servicios externos) deben ir en `.env` (no commiteado).

---

## Useful Resources

- `docs/TRAINING_MVP_NOTES.md` - Notas del MVP de entrenamiento
- `docs/PORTING_SPEC.md` - Spec para portar la "alma" a otros repos
- `docs/porting_starter/` - CÃ³digo starter para reimplementaciÃ³n

---

## Common Issues

**Error**: `database.g.dart` no encontrado o desactualizado
**Fix**: `dart run build_runner build --delete-conflicting-outputs`

**Error**: Permisos de notificaciones en Android
**Fix**: Verificar `AndroidManifest.xml` tiene permisos necesarios

**Error**: Locale espaÃ±ol no funciona en fechas
**Fix**: `main.dart` llama `initializeDateFormatting('es')` antes de runApp

**Warning**: `use_build_context_synchronously` despuÃ©s de operaciones async
**Fix**: Verificar `if (context.mounted)` o `if (mounted)` antes de usar `BuildContext`

**Warning**: `curly_braces_in_flow_control_structures` en if sin llaves
**Fix**: Siempre usar llaves: `if (x) { return; }`

**Warning**: `deprecated_member_use` para `Share.share` o `ColorScheme.background`
**Fix**: Ver secciÃ³n "Patrones de cÃ³digo seguros" arriba para las APIs correctas

**Warning**: `depend_on_referenced_packages` en tests
**Fix**: Cambiar `import 'package:test/test.dart'` por `import 'package:flutter_test/flutter_test.dart'`

---

*Última actualización: Enero 2026 - Weigh-ins con tendencia EMA, gráficos de peso y cambio semanal/mensual*
---

## Modelos Matemáticos Offline (Nuevo)

El proyecto ahora incluye análisis estadístico avanzado 100% offline:

### Para Peso Corporal (lib/diet/services/weight_trend_calculator.dart)
- **EMA** - Exponential Moving Average (suavizado)
- **Kalman Filter** - Estimación óptima del peso "real"
- **Holt-Winters** - Nivel + Tendencia con predicción
- **Regresión Lineal** - Pendiente y R²
- **Detección de Fase** - Plateau, pérdida, ganancia

### Para Fuerza (lib/training/services/strength_analysis_service.dart)
Mismos modelos aplicados a 1RM estimado de ejercicios.

### Extensión de Progresión (lib/training/services/progression_engine_extensions.dart)
`dart
import 'progression_engine_extensions.dart';

// Análisis de tendencia
final trend = ProgressionEngine.instance.analyzeStrengthTrend(dataPoints);
// trend.kalman1RM, trend.confidence, trend.isStalled

// Detección de sobreentrenamiento
final risk = ProgressionEngine.instance.detectOvertrainingRisk(
  recent1RMs: dataPoints,
  recentRPEs: rpeList,
  failuresAtCurrentWeight: 2,
);
// risk.level, risk.shouldDeload, risk.recommendation
`

### Visualizaciones añadidas
- **Insights contextuales** - Alertas de plateau, pérdida rápida, datos variables
- **Calidad de datos** - Barra de consistencia basada en Kalman + R²
- **Predicciones** - Proyección a 7 y 30 días (cuando R² > 0.6)

*Última actualización: Enero 2026 - Modelos multi-modelo offline implementados*

---

## Coach Adaptativo (MacroFactor-style)

Sistema de ajuste automático de targets calóricos basado en datos reales del usuario.

### Arquitectura
```
lib/diet/services/adaptive_coach_service.dart      # Lógica matemática pura
lib/diet/repositories/coach_repository.dart        # Persistencia (SharedPreferences)
lib/diet/providers/coach_providers.dart            # Riverpod providers
lib/diet/screens/coach/                            # UI
├── coach_screen.dart                              # Dashboard principal
├── plan_setup_screen.dart                         # Crear/editar plan
└── weekly_check_in_screen.dart                    # Check-in semanal
```

### Modelo Matemático

**Fórmula central:**
```
TDEE_real = AVG_kcal - (ΔTrendWeight × 7700 / días)
Nuevo_target = TDEE_real ± ajuste_objetivo
```

Donde:
- `7700 kcal/kg` = aproximación de energía por kg de tejido
- `ΔTrendWeight` = cambio de trendWeight en el período (kg)
- `ajuste_objetivo` = weeklyRatePercent × peso × 7700 / 7

### Flujo de Uso

1. **Usuario crea plan**: objetivo (lose/maintain/gain), velocidad (%/semana), TDEE inicial
2. **Registro diario**: peso + entradas de diario
3. **Check-in semanal**: el sistema calcula TDEE real y propone nuevos targets
4. **Confirmación**: usuario revisa y aplica (no es automático)

### Seguridades Implementadas

- **Mínimo de datos**: 4 días de diario + 3 pesajes para calcular
- **Clamps**: máximo ±200 kcal de cambio por semana
- **Límites absolutos**: 1200-6000 kcal
- **Todo offline**: sin datos online ni APIs externas

### Tests

```bash
flutter test test/diet/services/adaptive_coach_service_test.dart
```

Cubre:
- Cálculos de TDEE con diferentes escenarios de peso
- Escenarios reales (plateau, recomp, bulking too fast)
- Clamps de seguridad
- Manejo de datos insuficientes

*Última actualización: Enero 2026 - Coach Adaptativo implementado*

---

## Integración Open Food Facts + OCR de Etiquetas (Nuevo)

Sistema de búsqueda de alimentos externos con cache offline y OCR de etiquetas nutricionales.

### Arquitectura

```
lib/diet/services/
├── open_food_facts_service.dart      # Cliente HTTP con rate limiting
├── food_cache_service.dart            # Cache local (SharedPreferences + filesystem)
└── food_label_ocr_service.dart        # OCR de etiquetas con ML Kit

lib/diet/providers/
└── external_food_search_provider.dart # Estado de búsqueda (online/offline)

lib/features/diary/presentation/
└── external_food_search_screen.dart   # UI con voz/OCR/barcode/texto
```

### Características Implementadas

**Búsqueda Open Food Facts:**
- Búsqueda por texto con debounce (500ms)
- Búsqueda por código de barras (EAN-13)
- Búsqueda por voz (`speech_to_text`)
- Rate limiting: 60 req/minuto
- Timeout: 10 segundos

**Modo Offline:**
- Cache de búsquedas (TTL: 7 días)
- Alimentos guardados disponibles sin red
- Búsqueda local en cache

**OCR de Etiquetas:**
- Escaneo desde cámara o galería
- Detección automática de nombre del producto
- Pegar texto desde portapapeles
- Edición manual antes de buscar

### Permisos Android Necesarios

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Dependencias

```yaml
dependencies:
  http: ^1.3.0
  connectivity_plus: ^6.1.3
  google_mlkit_text_recognition: ^0.15.0  # Ya existía
  image_picker: ^1.1.2                    # Ya existía
  speech_to_text: ^7.0.0                  # Ya existía
```

### Patrones Aprendidos

**OCR con ML Kit:**
```dart
// Procesar imagen
final inputImage = InputImage.fromFilePath(imagePath);
final textRecognizer = TextRecognizer();
final recognizedText = await textRecognizer.processImage(inputImage);

// Extraer líneas
for (final block in recognizedText.blocks) {
  for (final line in block.lines) {
    lines.add(line.text.trim());
  }
}
await textRecognizer.close(); // Siempre cerrar
```

**Portapapeles:**
```dart
final data = await Clipboard.getData(Clipboard.kTextPlain);
final text = data?.text;
```

**BuildContext después de async:**
```dart
// ❌ INCORRECTO: Usar context después de await sin verificar
final result = await asyncOperation();
showDialog(context: context, ...); // Puede crashar

// ✅ CORRECTO: Verificar mounted antes de usar context
final result = await asyncOperation();
if (!mounted) return;
showDialog(context: context, ...);
```

**Casting de JSON de APIs externas:**
```dart
// ❌ INCORRECTO: Cast directo que puede fallar
final products = json['products'] as List<Map<String, dynamic>>;

// ✅ CORRECTO: Convertir cada elemento
final products = (json['products'] as List)
    .map((p) => Map<String, dynamic>.from(p as Map))
    .toList();
```

**Rate Limiting simple:**
```dart
final _requestTimestamps = <DateTime>[];

bool get _canMakeRequest {
  _requestTimestamps.removeWhere(
    (ts) => DateTime.now().difference(ts).inMinutes >= 1,
  );
  return _requestTimestamps.length < _maxRequestsPerMinute;
}
```

**Test de servicios con SharedPreferences:**
```dart
// Resetear singleton entre tests
@visibleForTesting
static void resetForTesting() => _instance = null;

// En setUp:
SharedPreferences.setMockInitialValues({});
Service.resetForTesting();
```

### Errores Comunes y Soluciones

**Error: `use_build_context_synchronously`**
- **Causa**: Usar `BuildContext` después de `await` sin verificar `mounted`
- **Solución**: Verificar `if (mounted)` antes de usar el context

**Error: `extends_non_class` en Riverpod 3**
- **Causa**: Usar `StateNotifierProvider` en lugar de `NotifierProvider`
- **Solución**: Migrar a `Notifier` + `NotifierProvider`

**Error: `unused_local_variable`**
- **Causa**: Variables declaradas pero no usadas
- **Solución**: Eliminar o usar la variable

**Error: Cast de tipos en JSON**
- **Causa**: Cast directo de `List<dynamic>` a `List<Map<String, dynamic>>`
- **Solución**: Usar `.map()` con `Map<String, dynamic>.from()`

**Error: mobile_scanner v6.x `torchState` no existe**
- **Causa**: La API cambió en v6.x, `torchState` (Stream) fue eliminado
- **Solución**: Usar `toggleTorch()` método y mantener estado local:
```dart
// ❌ INCORRECTO - v5.x API
ValueListenableBuilder(
  valueListenable: _controller.torchState,
  builder: (context, state, child) => Icon(
    state == TorchState.on ? Icons.flash_on : Icons.flash_off,
  ),
)

// ✅ CORRECTO - v6.x API
IconButton(
  icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
  onPressed: () async {
    await _controller.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
  },
)
```
- **Archivo referencia**: `lib/features/diary/presentation/barcode_scanner_screen.dart`

*Última actualización: Enero 2026 - mobile_scanner v6.x API documentada, flujos UX documentados*

---

## Flujos Críticos UX

Flujos de usuario que requieren atención especial por su impacto en la retención y usabilidad.

### 1. Entry Screen - Selección de Modo
**Archivos**: `lib/features/home/presentation/entry_screen.dart`

El punto de entrada de la app presenta dos modos distintos:
- **Nutrición** (tema claro, primario terracota) → Navega a `HomeScreen`
- **Entrenamiento** (tema oscuro, primario cyan/teal) → Navega a `TrainingShell`

**Patrón de navegación**:
```dart
Navigator.of(context).push(
  PageRouteBuilder(
    pageBuilder: (_, animation, _) => const HomeScreen(), // o TrainingShell
    transitionsBuilder: (_, animation, _, child) => 
      FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 400),
  ),
);
```

**Constraints**:
- Cada modo tiene su propio tema (MaterialApp usa `theme`/`darkTheme`)
- No hay persistencia del modo seleccionado (se decide en cada sesión)

### 2. External Food Search - Búsqueda de Alimentos
**Archivos**: `lib/features/diary/presentation/external_food_search_screen.dart`

Flujo multi-modal para añadir alimentos al diario:

```
┌─────────────────────────────────────────────────────────────┐
│  Usuario selecciona "Añadir comida"                         │
│  ↓                                                          │
│  Muestra: Barra de búsqueda + Chips de acción               │
│  ├─ Pegar (portapapeles)                                    │
│  ├─ OCR (cámara/galería)                                    │
│  ├─ Voz (speech-to-text)                                    │
│  └─ Barcode (camera-first)                                  │
│  ↓                                                          │
│  Resultados filtrados (solo coinciden con query)            │
│  ↓                                                          │
│  Selección → Añadir al diario                               │
└─────────────────────────────────────────────────────────────┘
```

**UX Decisions**:
- **No mostrar productos aleatorios** en estado idle (muestra búsquedas recientes)
- **Filtrado de resultados OFF**: Solo productos cuyo nombre/marca contengan los términos buscados
- **Barcode camera-first**: Primero intenta cámara, fallback a entrada manual

### 3. Diary Screen - Calendario vs Lista
**Archivos**: `lib/features/diary/presentation/diary_screen.dart`

Dos vistas toggleables:
- **Lista**: Calendario semanal horizontal + entradas del día
- **Calendario**: `TableCalendar` mensual con dots de actividad

```dart
// Toggle en AppBar
IconButton(
  icon: Icon(viewMode == DiaryViewMode.list 
    ? Icons.calendar_month 
    : Icons.list),
  onPressed: () => ref.read(diaryViewModeProvider.notifier).state = 
    viewMode == DiaryViewMode.list 
      ? DiaryViewMode.calendar 
      : DiaryViewMode.list,
)
```

**Constraints**:
- Al seleccionar fecha en modo calendario, automáticamente cambia a modo lista
- Los dots en el calendario mensual representan días con entradas (no cantidad)

### 4. Coach Adaptativo - Setup y Check-in
**Archivos**: `lib/diet/screens/coach/`

Flujo de configuración de plan:

```
1. Plan Setup Screen
   ├─ Objetivo: Perder / Mantener / Ganar
   ├─ Velocidad: kg/semana (convertido desde % del peso)
   │  └─ -2.5% a +2.5% del peso corporal
   ├─ TDEE inicial (o estimado)
   └─ Distribución de macros:
      ├─ Presets: Low Carb, Balanced, High Protein, High Carb, Keto
      └─ Custom: Sliders con validación 100%

2. Weekly Check-in Screen (cada 7 días)
   ├─ Revisa progreso (peso trend vs calorías consumidas)
   ├─ Calcula TDEE real
   ├─ Propone ajuste (máx ±200 kcal/semana)
   └─ Usuario confirma o modifica
```

**Fórmulas clave**:
```
TDEE_real = AVG_kcal - (ΔTrendWeightKg × 7700 / días)
Ajuste_kcal = weeklyRatePercent × pesoKg × 7700 / 7
```

**Validaciones**:
- Mínimo 4 días de diario + 3 pesajes para calcular
- Clamps: máx ±200 kcal cambio/semana, límites absolutos 1200-6000 kcal

### 5. Training Session - Timer y Notificaciones
**Archivos**: `lib/training/screens/training_session_screen.dart`, servicios nativos

Flujo crítico para retención de usuarios de gym:

```
Usuario registra serie → Inicia timer descanso
                                    ↓
                    ┌───────────────┼───────────────┐
                    ↓               ↓               ↓
              Timer en app    Notificación    Foreground Service
              (visual)        persistente     (nativo, background)
                    ↓               ↓               ↓
                    └───────────────┴───────────────┘
                                    ↓
                            Acciones disponibles:
                            ├─ Pausar / Reanudar
                            ├─ +30s
                            ├─ Saltar
                            └─ Tap para volver a app
```

**Constraints técnicas**:
- **Android-only**: Foreground service nativo en `TimerForegroundService.kt`
- **OEM issues**: Xiaomi/Huawei tienen políticas agresivas de background killing
- **Audio focus**: Beeps usan `STREAM_NOTIFICATION` (no interrumpen música)

---

## Constraints Actuales

### Arquitecturales

#### 1. Offline-First Obligatorio
**Constraint**: La app funciona 100% offline excepto búsqueda OFF.

**Implicaciones**:
- Cache local obligatoria para resultados de Open Food Facts (TTL: 7 días)
- No se puede asumir conectividad para features core
- Sincronización cloud (si se implementa) debe ser opt-in y secundaria

#### 2. Dual Theme System
**Constraint**: Dos temas completamente separados (Nutrición claro, Entrenamiento oscuro).

**Implicaciones**:
- No hay toggle de dark mode dentro de un modo
- Widgets deben funcionar en ambos temas (usar `ColorScheme`, no colores hardcodeados)
- Transiciones entre modos deben ser suaves (fade 400ms)

#### 3. Database Schema v5 - Congelada
**Constraint**: Schema de Drift en v5, migraciones futuras deben mantener compatibilidad.

**Tablas actuales**:
```sql
-- Training
Routines, RoutineDays, RoutineExercises, Sessions, 
SessionExercises, WorkoutSets, ExerciseNotes

-- Diet  
Foods, DiaryEntries, WeighIns, Targets, Recipes, RecipeItems
```

**Reglas para cambios**:
- Solo añadir columnas nullable (nunca eliminar/modificar existentes)
- Incrementar `schemaVersion` en `@DriftDatabase`
- Ejecutar `build_runner` y probar migración en dispositivo real

### Técnicos

#### 4. mobile_scanner v6.x API
**Constraint**: La API cambió significativamente en v6.x.

**Antes vs Ahora**:
```dart
// ❌ REMOVED en v6.x
_controller.torchState  // Stream<TorchState>

// ✅ CORRECTO en v6.x  
_controller.torchEnabled  // bool, sincrono
await _controller.toggleTorch();  // Toggle método
```

**Archivo referencia**: `lib/features/diary/presentation/barcode_scanner_screen.dart`

#### 5. Rate Limiting Open Food Facts
**Constraint**: 60 requests/minuto (límite conservador self-imposed).

**Implementación**:
```dart
final _requestTimestamps = <DateTime>[];

bool get canMakeRequest {
  _requestTimestamps.removeWhere(
    (ts) => DateTime.now().difference(ts).inMinutes >= 1,
  );
  return _requestTimestamps.length < _maxRequestsPerMinute;
}
```

**Fallback**: Cache local + búsqueda en alimentos guardados.

#### 6. Speech-to-Text Limitaciones
**Constraint**: `speech_to_text` requiere permisos específicos por plataforma y no funciona en todos los dispositivos.

**Mitigaciones**:
- Siempre proveer input manual alternativo
- Detectar disponibilidad: `speechToText.initialize()` puede fallar silenciosamente
- No bloquear flujo si STT no está disponible

### UX/UI

#### 7. Context después de Async
**Constraint**: Flutter linter exige `mounted` check después de operaciones async.

**Patrón obligatorio**:
```dart
final result = await asyncOperation();
if (!mounted) return;  // o if (!context.mounted)
Navigator.of(context).pop(result);
```

**Violaciones comunes** (ahora corregidas):
- Uso de `BuildContext` después de `await` en dialogs
- Navegación después de operaciones de red/cache

#### 8. Formato numérico en UI
**Constraint**: Mostrar enteros sin decimal para valores redondos.

```dart
// ✅ Correcto - muestra "100" en lugar de "100.0"
text: grams == grams.round() 
  ? grams.toStringAsFixed(0) 
  : grams.toStringAsFixed(1)

// Tests de widget dependen de este formato exacto
```

### Testing

#### 9. Tests y pumpAndSettle
**Constraint**: Animaciones continuas (splash, transiciones) causan timeout en `pumpAndSettle`.

**Solución**:
```dart
// ❌ EVITAR en tests
await tester.pumpAndSettle();

// ✅ USAR
await tester.pump(const Duration(milliseconds: 500));
// o
await tester.pump();  // Single frame
```

#### 10. SharedPreferences en Tests
**Constraint**: Singleton de SharedPreferences requiere reset entre tests.

**Patrón**:
```dart
setUp(() {
  SharedPreferences.setMockInitialValues({});
  Service.resetForTesting();  // Si el servicio expone este método
});
```

---

## Decisiones de Arquitectura Pendientes

### 1. Navegación unificada vs Separada
**Estado actual**: Dos navegaciones separadas (Nutrición tiene sus screens, Entrenamiento los suyos).

**Consideraciones**:
- Unificar en un solo `Navigator` simplificaría deep linking
- Mantener separado permite evolucionar modos independientemente

### 2. Caché de OFF - TTL y Estrategia
**Estado actual**: 7 días TTL fijo.

**Alternativas consideradas**:
- Cache infinito con invalidación manual (complica UI)
- Sin cache (muy lento, rate limiting issues)
- Cache adaptativo basado en frecuencia de uso (complejo)

### 3. Modelos - Separación Diet/Training
**Estado actual**: Modelos en `lib/diet/models/` y `lib/training/models/`.

**Consideraciones**:
- Unificar en `lib/core/models/` si hay overlap creciente
- Mantener separado (preferido actualmente) para claridad de dominio

---

## Checklist para Nuevos Features

Antes de implementar un nuevo feature:

- [ ] ¿A qué modo pertenece (Nutrición/Entrenamiento/Ambos)?
- [ ] ¿Requiere cambios en schema de DB?
- [ ] ¿Funciona offline? Si no, ¿tiene fallback claro?
- [ ] ¿Usa el Design System unificado (`core/design_system/`)?
- [ ] ¿Maneja `mounted` después de operaciones async?
- [ ] ¿Tiene tests unitarios para lógica pura?
- [ ] ¿Funciona en ambos temas (claro/oscuro)?
- [ ] ¿Requiere permisos nuevos en AndroidManifest?

---

*Última actualización: Enero 2026 - mobile_scanner integrado, flujos UX documentados*
