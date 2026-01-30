# INFORME DE AUDITORÍA - JUAN TRACKER

**Fecha:** 2026-01-30
**Auditor:** Claude Opus 4.5
**Versión App:** 1.0.0+1
**Stack detectado:**
- State Management: Riverpod 3.0
- Persistencia: Drift (SQLite) con FTS5
- HTTP: Dio 5.8.0
- Navegación: go_router 14.6.3
- APIs: Open Food Facts
- Voice/OCR: speech_to_text, google_mlkit

---

# A) RESUMEN EJECUTIVO

## Top 10 Riesgos Antes de Beta

| Rank | Riesgo | Severidad | Probabilidad | Área |
|------|--------|-----------|--------------|------|
| 1 | **División por cero al editar entrada con amount=0** | BLOCKER | Alta | Dieta |
| 2 | **FTS5 con rowid TEXT causa búsquedas rotas** | CRITICAL | Alta | Persistencia |
| 3 | **CancelToken compartido causa race condition** | CRITICAL | Alta | Networking |
| 4 | **TypeConverters pierden datos silenciosamente** | CRITICAL | Media | Persistencia |
| 5 | **Async init sin await en providers** | MAJOR | Alta | Estado |
| 6 | **Doble debounce (800ms total) degrada UX** | MAJOR | Alta | UX |
| 7 | **Paginación local no funciona (sin offset)** | MAJOR | Alta | Dieta |
| 8 | **Image.network sin cache causa re-descargas** | MAJOR | Media | Performance |
| 9 | **Validación de inputs incompleta (0, negativos)** | MAJOR | Alta | Validación |
| 10 | **Migraciones silencian errores reales** | MAJOR | Media | Persistencia |

## Qué Arreglar Primero y Por Qué

### Sprint 0 (Bloqueadores - 0-2 horas)
1. **División por cero** - Crash garantizado si entry.amount=0
2. **FTS5 rowid** - Búsqueda completamente rota con IDs texto

### Sprint 1 (Críticos - 1 día)
3. **CancelToken por operación** - Race conditions en búsquedas
4. **TypeConverters con logging** - Pérdida de datos silenciosa
5. **Validación de inputs** - Datos corruptos en DB

### Sprint 2 (Mayores - 2-3 días)
6. **Eliminar doble debounce** - UX degradada
7. **Async init con FutureProvider** - Flickering en UI
8. **Cache de imágenes** - Performance y datos móviles

---

# B) MATRIZ DE HALLAZGOS

## BLOCKER (1)

| ID | Área | Severidad | Prob. | Síntoma | Causa Raíz | Evidencia | Reproducción | Fix | Test |
|----|------|-----------|-------|---------|------------|-----------|--------------|-----|------|
| BUG-001 | Dieta | BLOCKER | Alta | App crashea al editar entrada | División por cero cuando `entry.amount = 0` | `edit_entry_dialog.dart:87` - `final factor = newAmount / entry.amount;` | 1. Crear QuickAdd con 0g 2. Intentar editarlo | Validar `entry.amount > 0` antes de división | Unit test con entry.amount=0 |

## CRITICAL (4)

| ID | Área | Severidad | Prob. | Síntoma | Causa Raíz | Evidencia | Reproducción | Fix | Test |
|----|------|-----------|-------|---------|------------|-----------|--------------|-----|------|
| BUG-002 | Persistencia | CRITICAL | Alta | Búsqueda FTS5 no encuentra nada | `content_rowid='id'` espera INTEGER pero Foods.id es TEXT | `database.dart:568` - FTS5 content_rowid con TEXT ID | Crear alimentos, buscar con FTS | Cambiar a content sync manual o usar INTEGER rowid | Integration test FTS |
| BUG-003 | Networking | CRITICAL | Alta | Búsqueda cancelada incorrectamente | `_cancelToken` compartido entre `search()` y `loadMore()` | `external_food_search_provider.dart:205,571` | Buscar, scroll down rápido mientras carga | Usar CancelToken separados | Widget test con scroll |
| BUG-004 | Persistencia | CRITICAL | Media | Datos perdidos sin error | `StringListConverter` retorna `[]` en parse error | `database.dart:22-24` - `catch (e) { return []; }` | Corromper JSON en columna string list | Agregar logging, throw con contexto | Unit test con JSON malformado |
| BUG-005 | Persistencia | CRITICAL | Baja | Crash en enum desconocido | `MealType.values.byName()` sin fallback | `database.dart:59` | Rollback de DB con nuevo MealType | Usar try/catch con default | Unit test enum parsing |

## MAJOR (12)

| ID | Área | Severidad | Prob. | Síntoma | Causa Raíz | Evidencia | Reproducción | Fix | Test |
|----|------|-----------|-------|---------|------------|-----------|--------------|-----|------|
| BUG-006 | Estado | MAJOR | Alta | UI muestra valor incorrecto inicialmente | `_loadPreference()` async no awaited en `build()` | `information_density_provider.dart:17-19` | Abrir app, ver density mode | Usar FutureProvider o AsyncNotifier | Unit test initial state |
| BUG-007 | UX | MAJOR | Alta | Búsqueda lenta (800ms delay) | Doble debounce: screen (500ms) + provider (300ms) | `external_food_search_screen.dart:74`, `external_food_search_provider.dart:222` | Escribir en búsqueda, notar delay | Eliminar debounce de pantalla | Widget test timing |
| BUG-008 | Dieta | MAJOR | Alta | "Cargar más" repite mismos resultados | `loadMore()` no pasa offset al repository | `food_search_provider.dart:271-276` - comentario en código | Scroll down en resultados locales | Implementar offset en repository | Integration test pagination |
| BUG-009 | Performance | MAJOR | Media | Imágenes re-descargadas constantemente | `Image.network()` sin cache persistente | `biblioteca_bottom_sheet.dart:1226`, `ejercicio_card.dart:457` | Scroll lista ejercicios, ver red tab | Usar CachedNetworkImage | Manual profiling |
| BUG-010 | Validación | MAJOR | Alta | Datos inválidos aceptados | No validación de 0, negativos, extremos | `weight_screen.dart:118`, `numpad_input_modal.dart:195-201` | Ingresar 0 kg peso, -5 reps | Agregar validación `value > 0` | Unit tests edge cases |
| BUG-011 | Validación | MAJOR | Alta | Alimento con 0 kcal/100g | Validator solo chequea empty, no numérico | `foods_screen.dart:678-680` | Crear food con "abc" en kcal | Validar parseo exitoso y > 0 | Unit test food creation |
| BUG-012 | Persistencia | MAJOR | Media | Schema inconsistente post-upgrade | Migraciones catch todo sin log | `database.dart:492-555` - múltiples `catch (e) {}` | Upgrade con error de permisos | Loguear errores, re-throw reales | Migration test |
| BUG-013 | Persistencia | MAJOR | Media | Campos v7 no disponibles en modelo | `FoodMapping` no mapea campos nuevos | `drift_diet_repositories.dart:10-27` - falta useCount, etc | Usar sugerencias inteligentes | Agregar campos al mapping | Unit test mapping |
| BUG-014 | Estado | MAJOR | Media | Voice init puede fallar silenciosamente | `Future.microtask()` sin await en build | `voice_input_provider.dart:99-102` | Usar voz antes de init completo | Usar AsyncNotifierProvider | Integration test voice |
| BUG-015 | Navegación | MAJOR | Baja | Deep link a sesión no funciona | Ruta ignora parámetro ID | `app_router.dart:206-209` - `builder: (ctx, state) => const HistoryScreen()` | Navegar a /training/session/detail/123 | Implementar o eliminar ruta | Navigation test |
| BUG-016 | Persistencia | MAJOR | Baja | FTS triggers duplicados posibles | `_createFts5Triggers` llamado en onCreate y v7 migrate | `database.dart:485,552` | Fresh install vs upgrade a v7 | Usar CREATE IF NOT EXISTS en todos | Migration test |
| BUG-017 | Persistencia | MAJOR | Baja | recordFoodUsage no transaccional | UPDATE y INSERT separados | `database.dart:777-790` | Kill app entre operaciones | Envolver en `transaction()` | Unit test atomicity |

## MINOR (8)

| ID | Área | Severidad | Prob. | Síntoma | Causa Raíz | Evidencia | Reproducción | Fix | Test |
|----|------|-----------|-------|---------|------------|-----------|--------------|-----|------|
| BUG-018 | Memory | MINOR | Media | SpeechToText no disposed | Instancia como field sin dispose | `external_food_search_screen.dart:42` | Navegar in/out de búsqueda múltiples veces | Dispose en dispose() | Memory profiling |
| BUG-019 | UX | MINOR | Baja | Barcode inválido enviado a API | Sin validación de formato | `external_food_search_screen.dart:177-186` | Ingresar "abc123" como barcode | Regex validación EAN/UPC | Unit test barcode |
| BUG-020 | Persistencia | MINOR | Baja | LIKE wildcards no escapados | Query usa `%$input%` directo | `database.dart:702-705` | Buscar "50%" en alimentos | Escapar caracteres especiales | Unit test search |
| BUG-021 | Performance | MINOR | Media | FTS index sin dedup | Mismo producto indexado múltiples veces | `external_food_search_provider.dart:496-515` | Búsquedas con resultados solapados | Dedup antes de indexar | Unit test index |
| BUG-022 | Estado | MINOR | Baja | List mutation in place | Extension `reverse()` muta lista original | `coach_providers.dart:195-221` | Usar dailyKcalList después de reverse | Usar `.reversed.toList()` | Unit test immutability |
| BUG-023 | API | MINOR | Baja | page/pageSize como String | Conversión innecesaria `.toString()` | `open_food_facts_service.dart:346-347` | N/A (funciona pero ineficiente) | Pasar como int directamente | N/A |
| BUG-024 | Config | MINOR | Baja | País hardcodeado a "es" | Default country = 'es' sin locale | `open_food_facts_service.dart:244` | Usuario en México | Detectar locale del dispositivo | N/A |
| BUG-025 | Performance | MINOR | Media | Provider rebuilds excesivos | `ref.watch()` de estado completo | `food_search_results.dart:29` | Cambiar cualquier campo del provider | Usar `.select()` para campos específicos | Widget test rebuild |

---

# C) ANÁLISIS PROFUNDO POR ÁREAS

## 1) Estado y Arquitectura (Riverpod)

### Problemas Detectados

#### 1.1 Race Conditions en Async Init
```dart
// information_density_provider.dart:17-19
DensityMode build() {
  _loadPreference();  // ❌ ASYNC NO AWAITED
  return DensityMode.comfortable;  // Retorna antes de cargar
}
```
**Impacto:** UI muestra modo incorrecto por 100-300ms, causando layout shift.

#### 1.2 Future.microtask Sin Espera
```dart
// voice_input_provider.dart:99-102
VoiceInputState build() {
  Future.microtask(() async {
    await _init();  // ❌ Ejecuta después de build
  });
  return const VoiceInputState();
}
```
**Impacto:** Si usuario activa voz antes de init, falla silenciosamente.

#### 1.3 Timer No Cancelado en Invalidación
```dart
// training_provider.dart:153-214
@override
TrainingState build() {
  _initializeServices();  // ❌ Si provider invalidado, recursos anteriores pueden quedar
  ref.onDispose(() {
    _timerController.dispose();  // Solo dispose del último
  });
}
```

#### 1.4 Watch de Estado Completo
```dart
// food_search_results.dart:29
final state = ref.watch(foodSearchProvider);  // ❌ Rebuild en cualquier cambio
```
**Fix:**
```dart
final results = ref.watch(foodSearchProvider.select((s) => s.results));
```

### Recomendaciones
1. Usar `AsyncNotifierProvider` para providers con init async
2. Separar CancelTokens por operación
3. Usar `.select()` en todos los watches de estados complejos
4. Agregar `.autoDispose` a providers con datos pesados

---

## 2) Persistencia (Drift/SQLite)

### Problemas Críticos

#### 2.1 FTS5 con TEXT rowid
```sql
-- database.dart:563-570
CREATE VIRTUAL TABLE foods_fts USING fts5(
  name, brand,
  content='foods',
  content_rowid='id'  -- ❌ Foods.id es TEXT, FTS5 espera INTEGER
);
```
**Impacto:** FTS queries fallan o retornan resultados incorrectos.

**Fix:**
```sql
-- Opción 1: Sincronización manual sin content_rowid
CREATE VIRTUAL TABLE foods_fts USING fts5(name, brand);

-- Opción 2: Agregar columna INTEGER autoincrement a Foods
```

#### 2.2 TypeConverters Silenciosos
```dart
// database.dart:18-24
@override
List<String> fromSql(String fromDb) {
  try {
    return List<String>.from(json.decode(fromDb));
  } catch (e) {
    return [];  // ❌ Pérdida de datos sin aviso
  }
}
```
**Fix:**
```dart
catch (e, stack) {
  debugPrint('JSON parse error in StringListConverter: $e\nData: $fromDb');
  // Opción: throw o retornar con flag de error
  return [];
}
```

#### 2.3 Migraciones Sin Logging
```dart
// database.dart:489-495
if (from < 2) {
  try {
    await m.addColumn(routineExercises, routineExercises.supersetId);
  } catch (e) {
    // ❌ Errores reales ocultos (permisos, disco lleno, etc.)
  }
}
```

#### 2.4 Campos No Mapeados
```dart
// drift_diet_repositories.dart:10-27 - FoodMapping
extension FoodMapping on db.Food {
  models.FoodModel toModel() => models.FoodModel(
    // ❌ Faltan: useCount, lastUsedAt, nutriScore, novaGroup, normalizedName
  );
}
```

#### 2.5 Transacciones Faltantes
```dart
// database.dart:773-790
Future<void> recordFoodUsage(String foodId) async {
  // ❌ No transaccional - kill entre UPDATE y INSERT corrompe contadores
  await customStatement('UPDATE foods SET use_count = ...');
  await customStatement('INSERT INTO consumption_patterns ...');
}
```

### Índices Faltantes
| Tabla | Columna | Uso Frecuente | Impacto |
|-------|---------|---------------|---------|
| Sessions | completedAt | Filtro sesiones activas | O(n) en cada query |
| DiaryEntries | foodId | Join con Foods | Lento en reportes |
| ConsumptionPatterns | lastConsumedAt | Ordenamiento | Lento en sugerencias |

---

## 3) Networking (Open Food Facts)

### Análisis del Algoritmo de Búsqueda

#### 3.1 Flujo Actual
```
Usuario escribe → 500ms debounce (screen) → 300ms debounce (provider) → API call
                                                    ↓
                                        Total: 800ms de delay
```

#### 3.2 Parámetros de API
```dart
// open_food_facts_service.dart:341-373
final queryParams = {
  'search_terms': query,
  'page': page.toString(),      // ❌ Innecesario toString
  'page_size': pageSize.toString(),
  'sort_by': 'unique_scans_n',  // Ordena por popularidad, NO relevancia
  'sort_direction': 'desc',
  'cc': 'es',                   // ❌ Hardcoded a España
};
```

**Problema de Relevancia:** El API ordena por `unique_scans_n` (escaneos), lo que significa que productos populares aparecen primero, no los más relevantes al query.

#### 3.3 Sistema de Scoring (BM25 Local)
```dart
// food_search_scoring.dart - Pesos actuales
const ScoringWeights({
  this.text = 1.0,      // Coincidencia texto
  this.category = 0.3,  // Categorías preferidas
  this.quality = 0.2,   // Nutri-Score/Nova
  this.freshness = 0.1, // Recencia del dato
  this.spanish = 0.4,   // Marcas españolas
});
```

**Problema:** El scoring local se aplica DESPUÉS de recibir resultados ordenados por popularidad, limitando la calidad del reordenamiento.

#### 3.4 Recomendación: Mejorar Búsqueda

```dart
// Cambios sugeridos en open_food_facts_service.dart

// 1. Usar parámetros de relevancia de la API
final queryParams = {
  'search_terms': query,
  'page': page,  // Sin toString
  'page_size': pageSize,
  // 'sort_by': 'popularity_key', // Alternativa: relevancia
  'tagtype_0': 'categories',
  'tag_contains_0': 'contains',
  'tag_0': _inferCategory(query),  // Inferir categoría del query
};

// 2. Detectar país del dispositivo
String get _countryCode {
  final locale = Platform.localeName;
  return locale.split('_').last.toLowerCase();
}

// 3. Búsqueda multi-término
String _buildSearchQuery(String query) {
  // "pollo pechuga" → "pollo AND pechuga"
  return query.split(' ')
    .where((t) => t.length >= 2)
    .join(' AND ');
}
```

#### 3.5 Race Condition en CancelToken
```dart
// external_food_search_provider.dart
CancelToken? _cancelToken;  // ❌ Compartido

Future<void> search(...) {
  _cancelToken?.cancel();
  _cancelToken = CancelToken();  // Line 230
  // ...
}

Future<void> loadMore() {
  _cancelToken?.cancel();     // ❌ Cancela el search en progreso!
  _cancelToken = CancelToken();  // Line 571-572
}
```

**Fix:**
```dart
CancelToken? _searchCancelToken;
CancelToken? _paginationCancelToken;
```

---

## 4) Navegación y Lifecycle

### 4.1 Ruta Inútil
```dart
// app_router.dart:206-209
GoRoute(
  path: trainingSessionDetail,  // '/training/session/detail'
  builder: (context, state) => const HistoryScreen(),  // ❌ Ignora ID
),
```

### 4.2 SpeechToText Memory Leak
```dart
// external_food_search_screen.dart:42
class _ExternalFoodSearchScreenState {
  final _speech = SpeechToText();  // ❌ Nunca disposed

  @override
  void dispose() {
    // ❌ Falta: _speech.stop(); _speech.cancel();
    super.dispose();
  }
}
```

### 4.3 Falta PopScope en Edición
Las siguientes pantallas permiten edición pero no preguntan antes de salir:
- `CreateEditRoutineScreen` - Perder rutina completa
- `FocusSessionScreen` - Perder sets de workout
- `FoodSearchScreen` - Perder selección

---

## 5) UX y Validaciones

### 5.1 División por Cero
```dart
// edit_entry_dialog.dart:87
({int kcal, ...}) _calculateMacros() {
  final factor = newAmount / entry.amount;  // ❌ entry.amount puede ser 0
  return (
    kcal: (entry.kcal * factor).round(),  // NaN/Infinity
    // ...
  );
}
```

### 5.2 Validación Incompleta

| Campo | Archivo | Línea | Problema |
|-------|---------|-------|----------|
| Peso corporal | weight_screen.dart | 118 | Acepta 0, negativos, >1000 |
| Reps | numpad_input_modal.dart | 195 | `value >= 0` permite 0 reps |
| Kcal en food | foods_screen.dart | 678 | Validator solo chequea empty |
| Macros en quickadd | add_entry_dialog.dart | 371-397 | Acepta negativos |
| Targets | targets_screen.dart | 647-662 | TextField sin validación |

### 5.3 Formato Decimal
```dart
// log_input.dart:458-465
inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),  // ❌ Permite ".5" o "5."
]
```

---

## 6) Performance y Estabilidad

### 6.1 Imágenes Sin Cache
```dart
// biblioteca_bottom_sheet.dart:1226
Image.network(
  ex.imageUrls.first,
  fit: BoxFit.cover,
);  // ❌ Re-descarga en cada rebuild
```

**Archivos afectados:**
- `biblioteca_bottom_sheet.dart:1226`
- `ejercicio_card.dart:457`
- `external_food_search_screen.dart:937`
- `food_search_screen.dart:799`

### 6.2 Filtrado en Build
```dart
// biblioteca_bottom_sheet.dart:879-887
builder: (context, exercises, _) {
  var filtered = _applyOptionalFilters(exercises);  // ❌ Cada rebuild
  filtered = _searchExercises(filtered, _query);    // ❌ O(n) por rebuild
}
```

### 6.3 FutureBuilder en Build
```dart
// food_search_bar.dart:120-148
Widget _buildSuggestionsList() {
  return FutureBuilder<List<String>>(
    future: ref.read(foodSearchProvider.notifier)
        .getAutocompleteSuggestions(_controller.text),  // ❌ Nueva Future cada build
```

### 6.4 Streams Sin Límite
```dart
// drift_diet_repositories.dart:159-163
Stream<List<FoodModel>> watchAll() {
  return _db.select(_db.foods).watch()  // ❌ Sin límite - todos los foods
    .map((rows) => rows.map((r) => r.toModel()).toList());
}
```

---

# D) PLAN DE ACCIÓN

## Sprint 0: Blockers (0-2 horas)

| # | Fix | Archivo | Tiempo |
|---|-----|---------|--------|
| 1 | Validar `entry.amount > 0` antes de división | edit_entry_dialog.dart:87 | 10 min |
| 2 | Cambiar FTS5 a sync manual sin content_rowid | database.dart:563-570 | 45 min |

## Sprint 1: Críticos (1 día)

| # | Fix | Archivo | Tiempo |
|---|-----|---------|--------|
| 3 | Separar CancelTokens (search vs pagination) | external_food_search_provider.dart | 30 min |
| 4 | Agregar logging a TypeConverters | database.dart:14-86 | 30 min |
| 5 | Fallback seguro en enum converters | database.dart:54-86 | 20 min |
| 6 | Validación `> 0` en todos los inputs numéricos | weight_screen, numpad_modal, foods_screen | 1 hora |
| 7 | Agregar campos faltantes a FoodMapping | drift_diet_repositories.dart:10-27 | 30 min |

## Sprint 2: Mayores (2-3 días)

| # | Fix | Archivo | Tiempo |
|---|-----|---------|--------|
| 8 | Eliminar debounce de pantalla (usar solo provider) | external_food_search_screen.dart:74 | 15 min |
| 9 | Usar FutureProvider para InformationDensity | information_density_provider.dart | 45 min |
| 10 | Usar AsyncNotifier para VoiceInput | voice_input_provider.dart | 45 min |
| 11 | Agregar CachedNetworkImage | 4 archivos con Image.network | 1 hora |
| 12 | Implementar offset en paginación local | food_search_provider.dart, repositories | 2 horas |
| 13 | Agregar logging a migraciones | database.dart:487-557 | 30 min |
| 14 | Envolver recordFoodUsage en transaction | database.dart:773-790 | 15 min |
| 15 | Dispose SpeechToText | external_food_search_screen.dart | 10 min |

## Tests Mínimos a Agregar

```dart
// test/diet/edit_entry_division_test.dart
test('edit entry with zero amount should not crash', () {
  final entry = DiaryEntryModel(amount: 0, ...);
  // Expect validation error, not division by zero
});

// test/database/type_converters_test.dart
test('StringListConverter logs and returns empty on malformed JSON', () {
  final converter = StringListConverter();
  expect(converter.fromSql('not-json'), isEmpty);
  // Verify log was emitted
});

// test/diet/external_search_cancel_test.dart
test('loadMore does not cancel ongoing search', () {
  // Start search
  // Call loadMore before search completes
  // Verify search completes successfully
});
```

## Métricas/Logs para Beta

```dart
// Agregar a TelemetryService

void logSearchLatency(String query, Duration latency, int resultCount);
void logDatabaseError(String operation, Object error, StackTrace stack);
void logValidationFailure(String field, String value, String reason);
void logNavigationError(String route, Object error);
```

---

# E) BONUS

## Bugs Silenciosos (No crashean pero corrompen datos)

| Bug | Síntoma | Impacto Real |
|-----|---------|--------------|
| FoodMapping sin campos v7 | useCount siempre 0 | Sugerencias inteligentes rotas |
| recordFoodUsage no transaccional | Contadores divergen | Analytics de consumo incorrectos |
| Paginación sin offset | Duplicados en lista | UX confusa, posible doble registro |
| TypeConverters silenciosos | Listas vacías | Historial perdido sin aviso |
| Division por cero propaga Infinity | Macros mostrados como "Infinity" | Totales diarios incorrectos |

## Riesgos Que Requieren Beta Testers Humanos

| Riesgo | Por Qué No Se Detecta en Código |
|--------|--------------------------------|
| Relevancia de búsqueda OFF | Depende de intención del usuario real |
| UX de 800ms debounce | Percepción subjetiva de lentitud |
| Confusión entre "g" y "porción" | Modelo mental del usuario |
| Workflow de QuickAdd | Flujo natural vs diseñado |
| Accesibilidad (contraste, tamaños) | Requiere usuarios con discapacidad visual |
| Navegación por voz en gimnasio | Ruido ambiente real |
| OCR de etiquetas nutricionales | Variedad de formatos reales |

---

# Archivos a Modificar (Orden de PRs)

## PR 1: Hotfixes Críticos
```
lib/features/diary/presentation/edit_entry_dialog.dart
lib/training/database/database.dart (TypeConverters + FTS5)
lib/diet/providers/external_food_search_provider.dart (CancelTokens)
```

## PR 2: Validaciones
```
lib/features/weight/presentation/weight_screen.dart
lib/training/widgets/session/numpad_input_modal.dart
lib/features/foods/presentation/foods_screen.dart
lib/features/diary/presentation/add_entry_dialog.dart
lib/features/targets/presentation/targets_screen.dart
```

## PR 3: Estado y Providers
```
lib/core/providers/information_density_provider.dart
lib/training/providers/voice_input_provider.dart
lib/features/diary/presentation/external_food_search_screen.dart (debounce + dispose)
lib/diet/repositories/drift_diet_repositories.dart (FoodMapping)
```

## PR 4: Performance
```
lib/training/screens/create_routine/widgets/biblioteca_bottom_sheet.dart
lib/training/screens/create_routine/widgets/ejercicio_card.dart
lib/features/diary/presentation/external_food_search_screen.dart
lib/features/diary/presentation/food_search_screen.dart
pubspec.yaml (agregar cached_network_image)
```

---

*Fin del informe de auditoría*
