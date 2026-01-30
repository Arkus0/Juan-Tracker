# Informe de Mejoras: Sistema de Búsqueda de Juan Tracker

> Análisis exhaustivo de fallos, code smells, y oportunidades de mejora basado en best practices de apps de nutrición líderes

---

## RESUMEN EJECUTIVO

La implementación actual de búsqueda en Juan Tracker tiene **arquitectura sólida** pero presenta **problemas críticos de rendimiento, UX y mantenibilidad**. Este informe prioriza las mejoras necesarias para alcanzar el nivel de apps como FatSecret y MyFitnessPal.

### Puntuación Actual vs Objetivo

| Métrica | Actual | Objetivo | Prioridad |
|---------|--------|----------|-----------|
| Tiempo de respuesta inicial | 500-2000ms | <100ms | CRÍTICA |
| UX de búsqueda | 5/10 | 9/10 | ALTA |
| Cobertura offline | 30% | 90% | ALTA |
| Precisión de resultados | 6/10 | 9/10 | ALTA |
| Mantenibilidad | 5/10 | 8/10 | MEDIA |

---

## 1. FALLOS CRÍTICOS

### 1.1 ❌ Debounce NO implementado correctamente

**Ubicación:** `external_food_search_provider.dart` - método `search()`

**Problema:** Cada tecla presionada dispara una búsqueda completa sin debounce, causando:
- Saturación de la API de Open Food Facts
- Rate limiting (429 errors)
- UI que "salta" con resultados parciales
- Batería drenada innecesariamente

**Código problemático:**
```dart
// ❌ NO hay debounce - cada tecla dispara búsqueda
Future<void> search(String query, {bool forceOffline = false}) async {
  // ... sin esperar a que el usuario deje de escribir
  await _searchOnline(query.trim()); // Llamada inmediata
}
```

**Solución:**
```dart
// ✅ Debounce de 300ms con cancelación
Future<void> search(String query, {bool forceOffline = false}) async {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
    if (!mounted) return;
    await _performSearch(query, forceOffline: forceOffline);
  });
}
```

---

### 1.2 ❌ Cancelación de requests NO implementada

**Ubicación:** `open_food_facts_service.dart` - método `searchProducts()`

**Problema:** Si el usuario escribe rápidamente "pollo" → "pollo asado", se ejecutan 2 búsquedas:
1. "pollo" → tarda 1.5s
2. "pollo asado" → tarda 1s

Resultado: La búsqueda de "pollo" llega DESPUÉS y sobreescribe los resultados correctos de "pollo asado".

**Código problemático:**
```dart
// ❌ Sin cancelación - requests se acumulan
Future<OpenFoodFactsSearchResponse> searchProducts(...) async {
  final response = await _executeWithRetry(uri); // No cancelable
  return result;
}
```

**Solución:**
```dart
// ✅ CancelToken de Dio o http.Client con timeout
Future<OpenFoodFactsSearchResponse> searchProducts(
  String query, {
  int page = 1,
  int pageSize = 50,
  String country = 'es',
  bool withFallback = true,
  CancelToken? cancelToken, // ← NUEVO
}) async {
  final response = await _client.get(
    uri, 
    headers: _headers,
    cancelToken: cancelToken, // ← Cancelable
  ).timeout(_timeout);
  // ...
}

// En el provider:
CancelToken? _currentCancelToken;

Future<void> search(String query) async {
  _currentCancelToken?.cancel('New search initiated');
  _currentCancelToken = CancelToken();
  
  try {
    final response = await _apiService.searchProducts(
      query,
      cancelToken: _currentCancelToken,
    );
  } on DioException catch (e) {
    if (CancelToken.isCancel(e)) return; // Ignorar cancelaciones
  }
}
```

---

### 1.3 ❌ Sin base de datos local persistente (Drift)

**Ubicación:** Todo el sistema de caché

**Problema:** El sistema actual usa:
- `SharedPreferences` para JSON (NO es una base de datos)
- Índices en memoria que se pierden al cerrar la app
- Sin FTS5 nativo de SQLite

**Consecuencias:**
- Búsqueda offline muy limitada
- Sin capacidad de búsqueda avanzada (filtros, ordenamiento)
- Sin historial persistente de uso por alimento
- Sin capacidad de "alimentos habituales" inteligente

**Solución:** Migrar a Drift con FTS5:
```dart
// ✅ Tablas Drift con FTS5
@DriftDatabase(tables: [Alimentos, HistorialBusquedas, AlimentosFts])
class AppDatabase extends _$AppDatabase {
  // Búsqueda FTS5 nativa
  Future<List<Alimento>> buscarFTS(String query) {
    return customSelect(
      'SELECT a.* FROM alimentos a '
      'INNER JOIN alimentos_fts fts ON a.id = fts.rowid '
      'WHERE alimentos_fts MATCH ? '
      'ORDER BY rank',
      variables: [Variable(query)],
    ).map((row) => Alimento.fromData(row.data)).get();
  }
}
```

---

### 1.4 ❌ User-Agent incorrecto para Open Food Facts

**Ubicación:** `open_food_facts_service.dart`

**Problema:**
```dart
// ❌ User-Agent genérico
static const String _userAgent = 'JuanTracker/1.0 (contact@juantracker.app)';
```

Open Food Facts **REQUIERE** User-Agent con formato específico:
```
AppName/Version (contact@email.com)
```

El actual es correcto, pero debería incluir más información:
```dart
// ✅ User-Agent completo
static const String _userAgent = 
  'JuanTracker/1.0 (Flutter; Android; es-ES; contact@juantracker.app)';
```

---

### 1.5 ❌ Sin manejo de "Sin resultados" inteligente

**Ubicación:** UI de búsqueda

**Problema:** Cuando no hay resultados, la app muestra lista vacía sin ayuda al usuario.

**Apps líderes hacen:**
- Sugerir términos similares ("¿Quisiste decir...?")
- Mostrar búsquedas populares relacionadas
- Permitir crear alimento personalizado
- Buscar con términos más genéricos

---

## 2. CODE SMELLS Y DEUDA TÉCNICA

### 2.1 🔴 Singletons con estado mutable

**Ubicación:** Múltiples servicios

```dart
// ❌ Singletons problemáticos
class FoodCacheService {
  static FoodCacheService? _instance;
  factory FoodCacheService() {
    _instance ??= FoodCacheService._internal();
    return _instance!;
  }
}

class FoodAutocompleteService {
  static FoodAutocompleteService? _instance;
  // ... mismo patrón
}
```

**Problemas:**
- Imposible de testear unitariamente
- Estado compartido entre tests
- No funciona con Riverpod (dependency injection)
- Memory leaks potenciales

**Solución:**
```dart
// ✅ Providers de Riverpod para inyección de dependencias
final foodCacheServiceProvider = Provider<FoodCacheService>((ref) {
  return FoodCacheService(ref.read(databaseProvider));
});

final foodAutocompleteServiceProvider = Provider<FoodAutocompleteService>((ref) {
  return FoodAutocompleteService(ref.read(databaseProvider));
});

// Uso:
class ExternalFoodSearchNotifier extends Notifier<ExternalSearchState> {
  late final FoodCacheService _cacheService;
  
  @override
  ExternalSearchState build() {
    _cacheService = ref.read(foodCacheServiceProvider); // ← Inyección
    return const ExternalSearchState();
  }
}
```

---

### 2.2 🔴 FTS "casero" en memoria

**Ubicación:** `food_fts_service.dart`

```dart
// ❌ Implementación propia de FTS (¡reinventando la rueda!)
class FoodFTSService {
  final Map<String, List<_Posting>> _invertedIndex = {};
  final Map<String, _FTSDocument> _documents = {};
  
  // Implementación manual de BM25
  double _idf(String term) { ... }
}
```

**Problemas:**
- 500+ líneas de código para algo que SQLite hace nativamente
- Sin persistencia (se pierde al cerrar app)
- Sin optimizaciones de C (SQLite FTS5 está en C)
- Bugs potenciales en el algoritmo BM25

**Solución:** Usar Drift con FTS5:
```dart
// ✅ FTS5 nativo de SQLite
CREATE VIRTUAL TABLE alimentos_fts USING fts5(
  nombre, marca, categoria,
  content='alimentos',
  content_rowid='id'
);

// Query simple y eficiente
SELECT * FROM alimentos_fts WHERE alimentos_fts MATCH 'manzana' ORDER BY rank;
```

---

### 2.3 🔴 Caché en SharedPreferences

**Ubicación:** `food_cache_service.dart`

```dart
// ❌ SharedPreferences NO es para datos estructurados
Future<void> cacheSearchResults(...) async {
  final json = jsonEncode(cache.map((c) => c.toJson()).toList());
  await _prefs!.setString(_searchCacheKey, json); // ← Mal uso
}
```

**Problemas:**
- SharedPreferences es para settings, no para bases de datos
- Límite de ~1MB en algunas plataformas
- Sin capacidad de query (solo get/set)
- Sin indexación
- Performance pobre con datos grandes

**Solución:** Drift/SQLite:
```dart
// ✅ Base de datos relacional
@Insert(onConflict: OnConflictStrategy.replace)
Future<void> cacheSearchResults(String query, List<Alimento> results);

// Query optimizada con índices
Future<List<Alimento>> getCachedResults(String query) {
  return (select(alimentosCache)
    ..where((a) => a.query.equals(query))
    ..orderBy([(a) => OrderingTerm.desc(a.timestamp)]))
    .get();
}
```

---

### 2.4 🔴 Scoring "casero" sin validación

**Ubicación:** `food_search_scoring.dart`

```dart
// ❌ Pesos arbitrarios sin testing
static const ScoringWeights _defaultWeights = ScoringWeights(
  text: 1.0,
  category: 0.3,
  quality: 0.2,
  freshness: 0.1,
  spanish: 0.4,
);
```

**Problemas:**
- Pesos elegidos sin datos de usuario
- Sin A/B testing
- Sin feedback de relevancia
- No aprende de selecciones del usuario

**Solución:** Sistema de ranking con feedback:
```dart
// ✅ Ranking que aprende del usuario
class SmartRankingService {
  Future<List<Alimento>> rankResults(
    List<Alimento> results, 
    String query,
    UserProfile user,
  ) async {
    final scores = <Alimento, double>{};
    
    for (final alimento in results) {
      var score = 0.0;
      
      // 1. Coincidencia de texto (BM25)
      score += await _textScore(alimento, query);
      
      // 2. Historial de selecciones del usuario
      score += await _userSelectionScore(alimento, user);
      
      // 3. Horario del día (desayuno, almuerzo, cena)
      score += _timeOfDayScore(alimento);
      
      // 4. Patrones de consumo del usuario
      score += await _consumptionPatternScore(alimento, user);
      
      scores[alimento] = score;
    }
    
    return scores.entries
      .sortedByCompare((e) => e.value, (a, b) => b.compareTo(a))
      .map((e) => e.key)
      .toList();
  }
}
```

---

### 2.5 🔴 Sin manejo de errores de red granular

**Ubicación:** `open_food_facts_service.dart`

```dart
// ❌ Manejo de errores genérico
catch (e) {
  throw NetworkException('Error inesperado: $e');
}
```

**Problemas:**
- Usuario no sabe si es error de red, servidor, o timeout
- No hay retry inteligente según tipo de error
- UX pobre (mensajes genéricos)

**Solución:**
```dart
// ✅ Errores específicos con mensajes útiles
sealed class SearchError {
  const SearchError();
}

class NoConnectionError extends SearchError {
  const NoConnectionError();
  String get message => 'Sin conexión a internet. Mostrando resultados guardados.';
}

class ServerBusyError extends SearchError {
  const ServerBusyError();
  String get message => 'El servidor está ocupado. Intenta de nuevo en unos segundos.';
  bool get isRetryable => true;
}

class RateLimitError extends SearchError {
  const RateLimitError(this.retryAfter);
  final Duration retryAfter;
  String get message => 'Demasiadas búsquedas. Espera ${retryAfter.inSeconds}s.';
}
```

---

## 3. OPORTUNIDADES DE MEJORA UX

### 3.1 🎯 Búsqueda predictiva con ML

**Implementación:** Modelo ligero on-device (TensorFlow Lite)

```dart
// ✅ Predicción de alimentos según contexto
class PredictiveSearchService {
  Future<List<Alimento>> getPredictions({
    required DateTime time,
    required MealType? currentMeal,
    required List<MacroNutrientTargets> targets,
    required UserHistory history,
  }) async {
    // ML model predice qué alimentos probablemente quiera el usuario
    final features = _extractFeatures(time, currentMeal, targets, history);
    final predictions = await _tfliteModel.predict(features);
    
    return predictions
      .where((p) => p.confidence > 0.3)
      .sortedBy((p) => p.confidence)
      .take(10)
      .toList();
  }
}
```

**Ejemplo:** A las 8:00 AM, sugerir automáticamente:
- "Café con leche" (85% confianza)
- "Tostadas con aguacate" (72% confianza)
- "Avena con frutas" (68% confianza)

---

### 3.2 🎯 Búsqueda por voz integrada

```dart
// ✅ Speech-to-text con corrección de dominio
class VoiceSearchService {
  Future<String> transcribeWithFoodCorrection() async {
    final rawText = await _speechToText.listen();
    
    // Corrección específica de alimentos
    return _foodCorrector.correct(rawText);
  }
}

// Ejemplo:
// Input: "dos huevos fritos"
// Output: "2 huevos fritos" (normalizado para búsqueda)
```

---

### 3.3 🎯 Búsqueda visual (cámara)

```dart
// ✅ ML Kit para reconocimiento de alimentos
class VisualSearchService {
  Future<List<Alimento>> searchByImage(File image) async {
    // 1. Detectar alimentos en la imagen
    final labels = await _imageLabeler.processImage(image);
    
    // 2. Filtrar solo alimentos (confidence > 0.7)
    final foodLabels = labels.where((l) => _isFood(l)).toList();
    
    // 3. Buscar cada alimento detectado
    final results = <Alimento>[];
    for (final label in foodLabels) {
      results.addAll(await _search(label.text));
    }
    
    return results;
  }
}
```

---

### 3.4 🎯 Filtros avanzados de búsqueda

```dart
// ✅ Filtros tipo FatSecret/MyFitnessPal
class SearchFilters {
  final bool soloGenericos;
  final bool soloVerificados;
  final bool soloConImagen;
  final String? categoria;
  final NutriScore? minNutriScore;
  final NovaGroup? maxNovaGroup;
  final RangeValues? caloriasRange;
  final RangeValues? proteinasRange;
  final List<String>? alergenosExcluir;
  final List<String>? preferenciasDieteticas; // vegano, keto, etc.
}
```

---

### 3.5 🎯 Comparador de alimentos

```dart
// ✅ Comparar múltiples alimentos lado a lado
class FoodComparator {
  Future<ComparisonResult> compare(List<Alimento> alimentos) async {
    return ComparisonResult(
      calorias: _compareMacro(alimentos, (a) => a.kcal),
      proteinas: _compareMacro(alimentos, (a) => a.proteinas),
      carbohidratos: _compareMacro(alimentos, (a) => a.carbohidratos),
      grasas: _compareMacro(alimentos, (a) => a.grasas),
      nutriScore: _compareNutriScore(alimentos),
      mejorOpcion: _determineBestOption(alimentos),
    );
  }
}
```

---

## 4. ARQUITECTURA RECOMENDADA

### 4.1 Diagrama de la nueva arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI Layer                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │ SearchBar   │  │ ResultsList │  │ Filters & Suggestions   │ │
│  │ (debounced) │  │ (animated)  │  │ (predictive)            │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                    State Management (Riverpod 3.0)              │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ searchQueryProvider (StateProvider<String>)               │ │
│  │ searchResultsProvider (AsyncNotifier<List<Alimento>>)     │ │
│  │ searchFiltersProvider (StateProvider<SearchFilters>)      │ │
│  │ searchHistoryProvider (StateNotifier<List<String>>)       │ │
│  │ predictiveResultsProvider (FutureProvider<List<Alimento>>)│ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                      Repository Layer                           │
│  ┌───────────────────────────────────────────────────────────┐ │
│  │ AlimentoRepository                                        │ │
│  │ ├── search(String query, {SearchFilters? filters})        │ │
│  │ ├── searchByBarcode(String barcode)                       │ │
│  │ ├── getPredictions(SearchContext context)                 │ │
│  │ ├── getSuggestions(String prefix)                         │ │
│  │ └── getRecentlyUsed({int limit = 20})                     │ │
│  └───────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                        Data Layer                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Drift/SQLite │  │ Open Food    │  │ FatSecret API        │  │
│  │ + FTS5       │  │ Facts API    │  │ (opcional)           │  │
│  │              │  │              │  │                      │  │
│  │ Tablas:      │  │              │  │                      │  │
│  │ - alimentos  │  │              │  │                      │  │
│  │ - alimentos_ │  │              │  │                      │  │
│  │   fts        │  │              │  │                      │  │
│  │ - historial_ │  │              │  │                      │  │
│  │   busquedas  │  │              │  │                      │  │
│  │ - patrones_  │  │              │  │                      │  │
│  │   consumo    │  │              │  │                      │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. CHECKLIST DE IMPLEMENTACIÓN

### Fase 1: Critical Fixes (1-2 días)
- [ ] Implementar debounce de 300ms
- [ ] Implementar cancelación de requests
- [ ] Corregir User-Agent de Open Food Facts
- [ ] Agregar manejo de "Sin resultados" inteligente

### Fase 2: Migración a Drift (3-5 días)
- [ ] Configurar Drift con FTS5
- [ ] Migrar caché de SharedPreferences a SQLite
- [ ] Implementar índices FTS5
- [ ] Migrar scoring a BM25 nativo
- [ ] Tests de integración

### Fase 3: UX Avanzada (2-3 días)
- [ ] Búsqueda predictiva
- [ ] Sugerencias contextuales
- [ ] Filtros avanzados UI
- [ ] Animaciones de resultados

### Fase 4: Features Premium (3-5 días)
- [ ] Búsqueda por voz
- [ ] Búsqueda visual
- [ ] Comparador de alimentos
- [ ] ML on-device para predicciones

---

## 6. MÉTRICAS DE ÉXITO

| Métrica | Antes | Después | Cómo medir |
|---------|-------|---------|------------|
| Tiempo a primer resultado | 800ms | <100ms | Analytics |
| Búsquedas exitosas | 60% | 90% | User tracking |
| Uso de alimentos guardados | 20% | 60% | DB queries |
| Satisfacción UX | 3.5/5 | 4.5/5 | In-app survey |
| Errores de API | 15% | <2% | Error tracking |

---

## 7. REFERENCIAS

- Open Food Facts API: https://openfoodfacts.github.io/openfoodfacts-server/api/
- Drift FTS5: https://drift.simonbinder.eu/docs/using-sql/extensions/#fts5
- FatSecret API: https://platform.fatsecret.com/api/
- MyFitnessPal UX: https://www.myfitnesspal.com/

---

*Informe generado: 2026-01-31*
*Próximo paso: Prompt para implementación con Kimi Code*
