# Deprecated and Unused Code Inventory

> Inventario de código, assets, scripts y documentación deprecated.
> 
> **Última limpieza**: Febrero 2026 - Se eliminaron archivos marcados como seguros.

---

## Metodología de Detección

### Comandos utilizados

```bash
# Búsqueda de referencias a archivos/patrones
grep -r "pattern" lib/ test/ --include="*.dart"

# Verificar imports no usados
flutter analyze

# Buscar assets en pubspec.yaml
cat pubspec.yaml | grep assets

# Buscar referencias a archivos específicos
grep -rn "filename" .
```

### Limitaciones

- **Imports dinámicos**: Código cargado dinámicamente puede no detectarse
- **Reflection**: Dart no usa reflection extensivamente, pero MirrorSystem podría ocultar usos
- **Assets cargados en runtime**: Assets referenciados por string pueden escapar detección
- **Código generado**: Archivos `.g.dart` pueden tener referencias no evidentes

---

## 🔴 Archivos Dart No Referenciados

### ~~1. `lib/core/navigation/app_router.dart` (Legacy Router)~~ ✅ ELIMINADO

| Campo | Valor |
|-------|-------|
| **Estado** | ✅ ELIMINADO en limpieza Febrero 2026 |
| **Razón** | Router legacy reemplazado por GoRouter en `lib/core/router/` |

### 2. `lib/training/screens/focus_session_screen.dart` - MANTENER

| Campo | Valor |
|-------|-------|
| **Tipo** | Dart file |
| **Path** | `lib/training/screens/focus_session_screen.dart` |
| **Estado** | 📌 MANTENIDO - Feature alternativa completa (778 líneas) |
| **Notas** | UI alternativa para sesiones con FAB flotante. Puede activarse con toggle en settings futuro. |

### 3. `lib/training/screens/external_session_screen.dart` - MANTENER

| Campo | Valor |
|-------|-------|
| **Tipo** | Dart file |
| **Path** | `lib/training/screens/external_session_screen.dart` |
| **Estado** | 📌 MANTENIDO - Feature útil para registrar sesiones pasadas |
| **Notas** | Permite añadir workouts realizados fuera de la app (1212 líneas). |

### ~~4-5. Stubs de servicios~~ ✅ ELIMINADOS

| Campo | Valor |
|-------|-------|
| **Archivos eliminados** | `stub_timer_service.dart`, `i_timer_service.dart`, `stub_voice_input_service.dart`, `i_voice_input_service.dart`, `service_providers.dart` |
| **Razón** | Stubs no utilizados. Timer real usa `NativeBeepService`, voz usa `speech_to_text` directamente. |

### ~~6. `lib/diet/presentation/providers/food_search_provider.dart`~~ ✅ ELIMINADO

| Campo | Valor |
|-------|-------|
| **Estado** | ✅ ELIMINADO en consolidación de búsqueda |
| **Razón** | Sistema de búsqueda consolidado. Ver también eliminación de `lib/diet/data/`, `lib/diet/domain/`, `lib/diet/search.dart` |

---

## 🟡 Assets Potencialmente No Usados

### ~~1. Archivo de sonido: `bar_drop_clang.mp3`~~ ✅ ELIMINADO

| Campo | Valor |
|-------|-------|
| **Estado** | ✅ ELIMINADO |
| **Razón** | Sin referencias en código. Timer usa `NativeBeepService` (ToneGenerator). |

### 2. `success.mp3`, `beep.mp3` - MANTENER

| Campo | Valor |
|-------|-------|
| **Estado** | 📌 MANTENIDO |
| **Razón** | Potencial uso futuro para feedback sonoro alternativo. |

### ~~3. Fuentes Montserrat Italic (9 archivos)~~ ✅ ELIMINADOS

| Campo | Valor |
|-------|-------|
| **Archivos eliminados** | Todas las variantes `*Italic.ttf` |
| **Razón** | No declaradas en `pubspec.yaml`, no usadas en código. |

---

## 🟠 Scripts No Invocados

### ~~1. `docs/extract_providers.dart`~~ ✅ ELIMINADO

| Campo | Valor |
|-------|-------|
| **Estado** | ✅ ELIMINADO |
| **Razón** | Duplicado de `scripts/extract_providers.dart` |

### ~~2. `scripts/spain_subset.jsonl.gz`~~ ✅ ELIMINADO

| Campo | Valor |
|-------|-------|
| **Estado** | ✅ ELIMINADO |
| **Razón** | Output de script, no necesario en repo. El archivo usado es `assets/data/foods.jsonl.gz` |

---

## 🔵 Documentación Obsoleta

### ~~1. `docs/porting_starter/`~~ ✅ ELIMINADO

| Campo | Valor |
|-------|-------|
| **Estado** | ✅ ELIMINADO (directorio completo) |
| **Razón** | Material de referencia histórico no utilizado |

### ~~2. Archivos de patch: `codex_patch`, `patch.diff`~~ ✅ ELIMINADOS

| Campo | Valor |
|-------|-------|
| **Estado** | ✅ ELIMINADOS |
| **Razón** | Archivos históricos de migración pasada |

---

## 🟣 Código Duplicado - LIMPIEZA COMPLETADA ✅

> **Febrero 2026 - Limpieza Mayor**: Se identificaron y eliminaron ~20 archivos (~3,500 líneas) de código duplicado del módulo de entrenamiento.

### Archivos Eliminados en Limpieza Febrero 2026

#### features/training/presentation/ (9 archivos - ~2,200 líneas) ✅ ELIMINADO
| Archivo | Razón |
|---------|-------|
| `training_home_screen.dart` | Duplicado de `training/training_shell.dart` + `main_screen.dart` |
| `training_session_screen.dart` | Duplicado de `training/screens/training_session_screen.dart` |
| `session_detail_screen.dart` | Duplicado de `training/screens/session_detail_screen.dart` |
| `history_screen.dart` | Duplicado de `training/screens/history_screen.dart` |
| `create_edit_routine_screen.dart` | Duplicado de `training/screens/create_edit_routine_screen.dart` |
| `exercise_search_screen.dart` | Duplicado de `training/screens/exercise_search_screen.dart` |
| `exercise_detail_screen.dart` | Duplicado de `training/screens/exercise_detail_screen.dart` |
| `providers/training_providers.dart` | Duplicado de `training/providers/` |
| `widgets/session/` | Duplicado de `training/widgets/` |

#### core/models/training_*.dart (4 archivos - ~300 líneas) ✅ ELIMINADO
| Archivo | Razón |
|---------|-------|
| `training_session.dart` | Duplicado simplificado de `training/models/sesion.dart` |
| `training_set.dart` | Duplicado simplificado de `training/models/serie_log.dart` |
| `training_exercise.dart` | Duplicado simplificado de `training/models/ejercicio.dart` |
| `training_routine.dart` | Duplicado simplificado de `training/models/rutina.dart` |

#### core/repositories/ (4 archivos) ✅ ELIMINADO
| Archivo | Razón |
|---------|-------|
| `in_memory_training_repository.dart` | Producción usa DriftTrainingRepository |
| `i_training_repository.dart` | Interfaz obsoleta (interfaz real en training/) |
| `routine_repository.dart` | Duplicado de `training/repositories/routine_repository.dart` |
| `drift_training_repository.dart` (core) | Producción usa `training/repositories/drift_training_repository.dart` |

#### core/providers/ (3 archivos) ✅ ELIMINADO
| Archivo | Razón |
|---------|-------|
| `training_providers.dart` | Duplicado de `training/providers/training_provider.dart` |
| `training_session_controller.dart` | Duplicado de `training/providers/training_session_provider.dart` |
| `routine_providers.dart` | Duplicado de `training/providers/routine_provider.dart` |

#### test/ (6 archivos) ✅ ELIMINADO
| Carpeta | Razón |
|---------|-------|
| `test/features/training/` | Tests de screens duplicadas |
| `test/core/training/` | Tests de modelos/repos duplicados |

---

## ✅ Archivos Verificados como Usados

Los siguientes archivos fueron verificados y SÍ están en uso:

- `assets/data/exercises_local.json` - Usado por `LocalExerciseRepository` y `ExerciseLibraryService`
- `assets/data/alternativas.json` - Usado por `AlternativasService`
- `assets/data/foods.jsonl.gz` - Usado por `FoodDatabaseLoader`
- `assets/sounds/beep.mp3` - Mencionado en README pero timer usa ToneGenerator
- `lib/core/telemetry_service.dart` - Usado por timer services
- `wait-for-emulator.sh` - Usado por `.github/workflows/android-ci.yml`

---

## Recomendaciones

### ✅ Ya Eliminados (Febrero 2026)
- `lib/core/navigation/app_router.dart` - Router legacy
- `lib/core/services/stub_*.dart`, `i_*_service.dart` - Stubs de servicios
- `lib/core/providers/service_providers.dart` - Provider de stubs
- `lib/diet/data/`, `lib/diet/domain/`, `lib/diet/presentation/providers/` - Sistema de búsqueda duplicado
- `lib/diet/search.dart` - Barrel de búsqueda obsoleto
- `docs/porting_starter/` - Material histórico
- `codex_patch`, `patch.diff` - Archivos de patch
- `scripts/spain_subset.jsonl.gz` - Output de script
- `docs/extract_providers.dart` - Duplicado
- `assets/sounds/bar_drop_clang.mp3` - Audio no usado
- `assets/fonts/Montserrat-*Italic.ttf` - Fuentes no declaradas

### 📌 Mantenidos para Evaluación
1. `lib/training/screens/focus_session_screen.dart` - UI alternativa completa
2. `lib/training/screens/external_session_screen.dart` - Feature para sesiones pasadas
3. `assets/sounds/beep.mp3`, `success.mp3` - Potencial uso futuro

### ⚠️ Pendiente de Revisión
1. Fuentes Montserrat adicionales (Light, Thin, SemiBold, ExtraLight) - mantener si google_fonts las necesita

---

*Generado: Febrero 2026*
*Última limpieza: Febrero 2026 - Consolidación de búsqueda + eliminación de código duplicado de training (~3,500 líneas)*
