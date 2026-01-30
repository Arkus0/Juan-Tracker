# Corpus de Conocimientos: Algoritmos de Búsqueda para Apps de Nutrición

> Investigación consolidada sobre algoritmos de búsqueda de FatSecret, Libra, MyFitnessPal, Open Food Facts API e implementación con Flutter + Drift + Riverpod 3.0

---

## 1. ANÁLISIS DE APPS DE NUTRICIÓN LÍDERES

### 1.1 FatSecret

**Características de Búsqueda:**
- **Base de datos:** #1 en el mundo, 500M+ llamadas API mensuales, 10,000+ desarrolladores
- **API OAuth 2.0** con endpoints REST bien documentados
- **Búsqueda por:**
  - Expresión de texto (`search_expression`)
  - Código de barras (`foods.find_id_for_barcode`)
  - Autocompletado (`foods.autocomplete`)
  - Reconocimiento de imágenes (NLP + Computer Vision)

**Endpoints Clave:**
```
POST https://platform.fatsecret.com/rest/foods/search/v4
POST https://platform.fatsecret.com/rest/foods/autocomplete/v2
POST https://platform.fatsecret.com/rest/foods/find_id_for_barcode/v1
```

**Parámetros de Búsqueda:**
| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `search_expression` | String | Texto a buscar |
| `page_number` | Int | Paginación (0-based) |
| `max_results` | Int | Máx 50 resultados |
| `region` | String | Filtrar por país (default: US) |
| `language` | String | Idioma de resultados |
| `include_sub_categories` | Boolean | Incluir subcategorías |
| `flag_default_serving` | Boolean | Marcar porción por defecto |

**Respuesta (Foods Search v2):**
```json
{
  "foods": {
    "food": [{
      "food_id": "12345",
      "food_name": "Instant Oatmeal",
      "brand_name": "Quaker",
      "food_type": "Brand|Generic",
      "food_url": "...",
      "servings": {
        "serving": [{
          "serving_id": "...",
          "serving_description": "1 cup",
          "calories": "150",
          "carbohydrate": "27",
          "protein": "5",
          "fat": "3"
        }]
      }
    }]
  }
}
```

**Algoritmo de Ranking (Inferido):**
1. **Exact match** en nombre del alimento tiene prioridad máxima
2. **Popularidad** del alimento (frecuencia de uso)
3. **Tipo de alimento:** Brand vs Generic (prioriza según historial usuario)
4. **Recencia** de adición a la base de datos
5. **Completitud** de datos nutricionales

---

### 1.2 MyFitnessPal

**Características de Búsqueda:**
- Base de datos colaborativa (user-generated + verified)
- **Algoritmo de validación:** Usa simulaciones Monte Carlo para eliminar valores extremos/erróneos
- **Fuzzy matching** integrado para corrección de typos
- **Ranking por:**
  - Verificación del alimento (check verde)
  - Frecuencia de uso por la comunidad
  - Coincidencia exacta vs parcial

**Observaciones Clave:**
- Los alimentos verificados aparecen primero
- Sistema de "mejores coincidencias" basado en ML
- Filtrado automático de entradas duplicadas/erróneas

---

### 1.3 Libra (y apps similares: Yuka, Foodvisor)

**Características de Búsqueda:**
- **Escaneo de código de barras** como entrada principal
- **Reconocimiento por imagen** (AI/Computer Vision)
- **Sistema de scoring** propio (ej: Nutri-Score, GoCoCo Score)
- **Búsqueda contextual:** Sugiere alternativas más saludables

**Flujo de Búsqueda:**
1. Escaneo barcode → API lookup (Open Food Facts / base propia)
2. Si no existe → Reconocimiento de imagen
3. Si no reconoce → Entrada manual con sugerencias

---

## 2. OPEN FOOD FACTS API - REFERENCIA COMPLETA

### 2.1 Endpoints Principales

#### Búsqueda por Código de Barras
```http
GET https://world.openfoodfacts.org/api/v2/product/{barcode}
```

**Ejemplo:**
```http
GET https://world.openfoodfacts.org/api/v2/product/3017624010701?fields=product_name,nutrition_grades,nutriments
```

**Respuesta:**
```json
{
  "code": "3017624010701",
  "product": {
    "product_name": "Nutella",
    "nutrition_grades": "e",
    "nutriments": {
      "energy-kcal_100g": 539,
      "carbohydrates_100g": 57.5,
      "sugars_100g": 56.3,
      "fat_100g": 30.9,
      "proteins_100g": 6.3
    }
  },
  "status": 1,
  "status_verbose": "product found"
}
```

#### Búsqueda Avanzada (Search API v2)
```http
GET https://world.openfoodfacts.org/api/v2/search
```

**Parámetros de Filtro:**
| Parámetro | Descripción | Ejemplo |
|-----------|-------------|---------|
| `search_terms` | Búsqueda de texto | `search_terms=chicken` |
| `categories_tags` | Filtrar por categoría | `categories_tags=en:beverages` |
| `brands_tags` | Filtrar por marca | `brands_tags=nestle` |
| `countries_tags` | Filtrar por país | `countries_tags=united-states` |
| `nutrition_grades_tags` | Filtrar por Nutri-Score | `nutrition_grades_tags=a` |
| `nova_groups_tags` | Filtrar por grupo NOVA | `nova_groups_tags=4` |
| `allergens_tags` | Filtrar alérgenos | `allergens_tags=-en:gluten` (excluir) |
| `ingredients_analysis_tags` | Filtrar por análisis | `ingredients_analysis_tags=en:vegan` |

**Parámetros de Ordenamiento:**
| Parámetro | Descripción |
|-----------|-------------|
| `sort_by=popularity` | Por popularidad |
| `sort_by=product_name` | Por nombre |
| `sort_by=created_datetime` | Fecha de creación |
| `sort_by=last_modified_datetime` | Última modificación |
| `sort_by=ecoscore_score` | Por Eco-Score |
| `sort_by=nutriscore_score` | Por Nutri-Score |

**Parámetros de Paginación:**
| Parámetro | Default | Max |
|-----------|---------|-----|
| `page` | 1 | - |
| `page_size` | 20 | 100 |

**Ejemplo Completo:**
```http
GET https://world.openfoodfacts.org/api/v2/search?categories_tags=en:orange-juices&nutrition_grades_tags=c&fields=code,product_name,nutrition_grades&sort_by=popularity&page_size=24
```

### 2.2 Campos Disponibles (fields)

**Campos Básicos:**
- `code` - Código de barras
- `product_name` - Nombre del producto
- `brands` - Marca
- `categories_tags` - Categorías
- `ingredients_text` - Lista de ingredientes

**Campos Nutricionales:**
- `nutriments` - Objeto completo de nutrientes
- `nutrition_grades` - Nutri-Score (a-e)
- `nutriscore_data` - Datos del cálculo Nutri-Score
- `nova_group` - Grupo de procesamiento NOVA

**Campos de Calidad:**
- `ecoscore_score` - Eco-Score
- `ingredients_analysis_tags` - Análisis de ingredientes (vegan, vegetarian, etc.)
- `additives_tags` - Aditivos presentes
- `allergens_tags` - Alérgenos

### 2.3 Búsqueda por Categoría (v0 legacy)
```http
GET https://world.openfoodfacts.org/api/v0/category/{category}.json
```

---

## 3. ALGORITMOS DE BÚSQUEDA Y RANKING

### 3.1 Estrategias de Búsqueda de Texto

#### A. Búsqueda Exacta (Prefix Matching)
```dart
// SQL: WHERE name LIKE 'query%'
// Rápido, índice B-tree, resultados inmediatos
```

#### B. Búsqueda Fuzzy (Corrección de Typos)
**Algoritmos:**
- **Levenshtein Distance:** Mínimo de ediciones para transformar una cadena en otra
- **Jaro-Winkler Distance:** Similaridad entre 0-1, pondera prefijos comunes
- **N-gram Overlap:** Comparación de subsecuencias de n caracteres

**Implementación en Dart (fuzzy_bolt):**
```dart
import 'package:fuzzy_bolt/fuzzy_bolt.dart';

final fuzzySearch = FuzzyBolt<Alimento>(
  items: alimentos,
  getSearchableText: (a) => '${a.nombre} ${a.marca}',
  options: FuzzyOptions(
    threshold: 0.6,
    usePorterStemming: true,
    useIsolate: true, // Para datasets grandes
  ),
);

final resultados = fuzzySearch.search('manzana verde');
```

#### C. Full-Text Search (FTS5)
**Ventajas:**
- Búsqueda en múltiples columnas simultáneamente
- Ranking por relevancia (BM25)
- Highlighting de resultados
- Proximity search (palabras cercanas)

**Sintaxis FTS5:**
```sql
-- Búsqueda básica
SELECT * FROM alimentos_fts WHERE alimentos_fts MATCH 'manzana';

-- Búsqueda por prefijo
SELECT * FROM alimentos_fts WHERE alimentos_fts MATCH 'manz*';

-- Búsqueda AND implícita
SELECT * FROM alimentos_fts WHERE alimentos_fts MATCH 'manzana verde';

-- Búsqueda OR explícita
SELECT * FROM alimentos_fts WHERE alimentos_fts MATCH 'manzana OR pera';

-- Búsqueda por frase exacta
SELECT * FROM alimentos_fts WHERE alimentos_fts MATCH '"manzana verde"';

-- Exclusión
SELECT * FROM alimentos_fts WHERE alimentos_fts MATCH 'manzana -roja';

-- Proximidad (palabras a 5 tokens de distancia)
SELECT * FROM alimentos_fts WHERE alimentos_fts MATCH 'NEAR(manzana verde, 5)';

-- Ordenar por relevancia
SELECT * FROM alimentos_fts WHERE alimentos_fts MATCH 'manzana' ORDER BY rank;

-- Funciones auxiliares
SELECT highlight(fts_alimentos, 0, '<b>', '</b>') FROM alimentos_fts...;
SELECT snippet(fts_alimentos, 0, '<b>', '</b>', '...', 10) FROM alimentos_fts...;
```

### 3.2 Algoritmos de Ranking

#### A. Ponderación por Campos (Field Boosting)
```dart
const fieldWeights = {
  'nombre': 10.0,        // Coincidencia en nombre = máxima prioridad
  'marca': 5.0,          // Coincidencia en marca = alta prioridad
  'categoria': 3.0,      // Coincidencia en categoría = media prioridad
  'ingredientes': 1.0,   // Coincidencia en ingredientes = baja prioridad
};
```

#### B. Señales de Ranking Combinadas
```dart
double calculateRankingScore(Alimento alimento, String query, UserProfile user) {
  // 1. Relevancia de texto (0-1)
  final textScore = calculateTextRelevance(alimento, query);
  
  // 2. Popularidad del alimento (logarítmica)
  final popularityScore = log(alimento.vecesUsado + 1) / log(maxUsos + 1);
  
  // 3. Recencia de uso por el usuario
  final recencyScore = user.haUsadoRecientemente(alimento) ? 0.3 : 0.0;
  
  // 4. Completitud de datos nutricionales
  final completenessScore = alimento.porcentajeCompletitud / 100;
  
  // 5. Preferencias del usuario (vegano, sin gluten, etc.)
  double preferenceScore = 0.0;
  if (user.esVegano && alimento.esVegano) preferenceScore += 0.2;
  if (user.sinGluten && alimento.sinGluten) preferenceScore += 0.2;
  
  // Score final ponderado
  return (textScore * 0.4) + 
         (popularityScore * 0.25) + 
         (recencyScore * 0.15) + 
         (completenessScore * 0.1) + 
         (preferenceScore * 0.1);
}
```

#### C. Personalización por Historial
```dart
// Aprendizaje de las selecciones previas del usuario
List<Alimento> rankByUserHistory(List<Alimento> results, String query) {
  // Obtener alimentos que el usuario seleccionó previamente para queries similares
  final historialSimilar = userSearchHistory
    .where((h) => similarQueries(h.query, query))
    .expand((h) => h.selectedFoods)
    .groupBy((f) => f.foodId)
    .map((id, selections) => MapEntry(id, selections.length));
  
  // Boost a alimentos seleccionados antes
  return results.map((alimento) {
    final boost = historialSimilar[alimento.id] ?? 0;
    return alimento.copyWith(score: alimento.score + (boost * 0.1));
  }).sorted((a, b) => b.score.compareTo(a.score));
}
```

### 3.3 Autocompletado (Typeahead)

**Estrategia:**
1. **Prefix matching** rápido (índice)
2. **Frecuencia** de búsquedas previas
3. **Popularidad** global del alimento
4. **Contexto** (hora del día, comida típica)

```dart
// Implementación con debounce
class SearchSuggestionsNotifier extends StateNotifier<AsyncValue<List<String>>> {
  SearchSuggestionsNotifier(this.ref) : super(const AsyncValue.data([]));
  
  final Ref ref;
  Timer? _debounceTimer;
  
  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (query.length >= 2) {
        _fetchSuggestions(query);
      }
    });
  }
  
  Future<void> _fetchSuggestions(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(alimentoRepositoryProvider);
      return repository.getSuggestions(query, limit: 10);
    });
  }
}
```

---

## 4. IMPLEMENTACIÓN CON FLUTTER + DRIFT + RIVERPOD 3.0

### 4.1 Arquitectura de Búsqueda

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ SearchBar    │  │ ResultsList  │  │ Suggestions  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    State Management                           │
│                    (Riverpod 3.0)                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  searchQueryProvider (StateProvider<String>)         │  │
│  │  searchResultsProvider (FutureProvider.family)       │  │
│  │  suggestionsProvider (StreamProvider)                │  │
│  │  searchHistoryProvider (StateNotifierProvider)       │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Repository Layer                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  AlimentoRepository                                  │  │
│  │  ├── searchLocal(String query)                       │  │
│  │  ├── searchRemote(String query)                      │  │
│  │  ├── searchByBarcode(String barcode)                 │  │
│  │  └── getSuggestions(String prefix)                   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Drift (Local)│  │ OFF API      │  │ FatSecret    │      │
│  │ + FTS5       │  │ (Remote)     │  │ API          │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Configuración Drift con FTS5

**build.yaml:**
```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          sqlite:
            modules:
              - fts5
              - json1
```

**database.drift:**
```sql
-- Tabla principal de alimentos
CREATE TABLE alimentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    barcode TEXT UNIQUE,
    nombre TEXT NOT NULL,
    nombre_normalizado TEXT NOT NULL,
    marca TEXT,
    categoria TEXT,
    imagen_url TEXT,
    -- Campos nutricionales por 100g
    energia_kcal REAL,
    proteinas REAL,
    carbohidratos REAL,
    grasas REAL,
    grasas_saturadas REAL,
    azucares REAL,
    fibra REAL,
    sodio REAL,
    -- Metadatos
    es_generico BOOLEAN DEFAULT 1,
    es_verificado BOOLEAN DEFAULT 0,
    popularidad INTEGER DEFAULT 0,
    veces_usado INTEGER DEFAULT 0,
    ultima_vez_usado DATETIME,
    fecha_sincronizacion DATETIME,
    fuente_datos TEXT -- 'open_food_facts', 'fatsecret', 'manual'
);

-- Índices para búsqueda rápida
CREATE INDEX idx_alimentos_nombre ON alimentos(nombre_normalizado);
CREATE INDEX idx_alimentos_barcode ON alimentos(barcode);
CREATE INDEX idx_alimentos_categoria ON alimentos(categoria);
CREATE INDEX idx_alimentos_popularidad ON alimentos(popularidad DESC);

-- Tabla FTS5 para búsqueda de texto completo
CREATE VIRTUAL TABLE alimentos_fts USING fts5(
    nombre,
    marca,
    categoria,
    content='alimentos',
    content_rowid='id'
);

-- Triggers para mantener FTS sincronizado
CREATE TRIGGER alimentos_fts_insert AFTER INSERT ON alimentos BEGIN
    INSERT INTO alimentos_fts(rowid, nombre, marca, categoria)
    VALUES (new.id, new.nombre, new.marca, new.categoria);
END;

CREATE TRIGGER alimentos_fts_update AFTER UPDATE ON alimentos BEGIN
    UPDATE alimentos_fts SET 
        nombre = new.nombre,
        marca = new.marca,
        categoria = new.categoria
    WHERE rowid = new.id;
END;

CREATE TRIGGER alimentos_fts_delete AFTER DELETE ON alimentos BEGIN
    DELETE FROM alimentos_fts WHERE rowid = old.id;
END;

-- Tabla de historial de búsquedas
CREATE TABLE historial_busquedas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    query TEXT NOT NULL,
    alimento_id INTEGER REFERENCES alimentos(id),
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_historial_query ON historial_busquedas(query);
CREATE INDEX idx_historial_fecha ON historial_busquedas(fecha DESC);

-- Queries predefinidas
buscarPorFTS: SELECT a.* FROM alimentos a 
    INNER JOIN alimentos_fts fts ON a.id = fts.rowid 
    WHERE alimentos_fts MATCH :query 
    ORDER BY rank;

buscarPorNombre: SELECT * FROM alimentos 
    WHERE nombre_normalizado LIKE '%' || :query || '%' 
    ORDER BY popularidad DESC, nombre;

buscarPorBarcode: SELECT * FROM alimentos WHERE barcode = :barcode;

obtenerSugerencias: SELECT DISTINCT query FROM historial_busquedas 
    WHERE query LIKE :prefix || '%' 
    ORDER BY fecha DESC 
    LIMIT :limit;

incrementarUso: UPDATE alimentos SET 
    veces_usado = veces_usado + 1,
    ultima_vez_usado = CURRENT_TIMESTAMP 
    WHERE id = :id;
```

### 4.3 Providers de Riverpod 3.0

**search_providers.dart:**
```dart
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_providers.g.dart';

// Provider del query de búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider del tipo de búsqueda
enum SearchType { text, barcode, recent, favorites }
final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.text);

// Provider de filtros
final searchFiltersProvider = StateProvider<SearchFilters>((ref) => 
  SearchFilters());

class SearchFilters {
  final bool soloGenericos;
  final bool soloVerificados;
  final String? categoria;
  final double? minProteinas;
  final double? maxCalorias;
  
  SearchFilters({
    this.soloGenericos = false,
    this.soloVerificados = false,
    this.categoria,
    this.minProteinas,
    this.maxCalorias,
  });
  
  SearchFilters copyWith({...}) => ...;
}

// Provider principal de resultados con debounce y cancelación
@riverpod
class SearchResults extends _$SearchResults {
  @override
  Future<List<Alimento>> build() async {
    final query = ref.watch(searchQueryProvider);
    final filters = ref.watch(searchFiltersProvider);
    final type = ref.watch(searchTypeProvider);
    
    // Cancelar búsquedas anteriores
    if (query.isEmpty && type == SearchType.text) {
      return [];
    }
    
    // Debounce: esperar a que el usuario deje de escribir
    await ref.debounce(const Duration(milliseconds: 300));
    
    // Verificar si el provider fue disposed durante el debounce
    if (ref.mounted == false) {
      throw AbortedException();
    }
    
    final repository = ref.read(alimentoRepositoryProvider);
    
    return switch (type) {
      SearchType.barcode => repository.searchByBarcode(query),
      SearchType.recent => repository.getRecentlyUsed(),
      SearchType.favorites => repository.getFavorites(),
      SearchType.text => repository.search(query, filters: filters),
    };
  }
}

// Provider de sugerencias con stream
@riverpod
Stream<List<String>> searchSuggestions(SearchSuggestionsRef ref) async* {
  final query = ref.watch(searchQueryProvider);
  
  if (query.length < 2) {
    yield [];
    return;
  }
  
  await Future.delayed(const Duration(milliseconds: 150));
  
  if (ref.mounted == false) return;
  
  final repository = ref.read(alimentoRepositoryProvider);
  
  // Combinar sugerencias del historial + populares
  final historial = await repository.getSuggestionsFromHistory(query);
  final populares = await repository.getPopularMatches(query);
  
  yield {...historial, ...populares}.take(10).toList();
}

// Provider de historial de búsquedas
@riverpod
class SearchHistory extends _$SearchHistory {
  @override
  Future<List<String>> build() async {
    final repository = ref.read(alimentoRepositoryProvider);
    return repository.getRecentQueries(limit: 20);
  }
  
  Future<void> addQuery(String query, {int? alimentoId}) async {
    final repository = ref.read(alimentoRepositoryProvider);
    await repository.saveSearchQuery(query, alimentoId: alimentoId);
    ref.invalidateSelf();
  }
  
  Future<void> clear() async {
    final repository = ref.read(alimentoRepositoryProvider);
    await repository.clearSearchHistory();
    ref.invalidateSelf();
  }
}

// Extension para debounce en Riverpod 3.0
extension DebounceExtension on Ref {
  Future<void> debounce(Duration duration) async {
    var didDispose = false;
    onDispose(() => didDispose = true);
    
    await Future.delayed(duration);
    
    if (didDispose) {
      throw AbortedException();
    }
  }
}

class AbortedException implements Exception {}
```

### 4.4 Repository Pattern

**alimento_repository.dart:**
```dart
import 'package:drift/drift.dart';

class AlimentoRepository {
  final AppDatabase _db;
  final OpenFoodFactsApi _offApi;
  final FatSecretApi? _fatSecretApi;
  
  AlimentoRepository(this._db, this._offApi, [this._fatSecretApi]);
  
  /// Búsqueda principal con múltiples estrategias
  Future<List<Alimento>> search(
    String query, {
    SearchFilters? filters,
    int limit = 50,
  }) async {
    final normalizedQuery = _normalizeText(query);
    
    // 1. Búsqueda local primero (rápida)
    var resultados = await _searchLocal(normalizedQuery, filters: filters);
    
    // 2. Si hay pocos resultados locales, buscar en APIs remotas
    if (resultados.length < 10) {
      final remotos = await _searchRemote(normalizedQuery);
      resultados = _mergeAndDeduplicate(resultados, remotos);
    }
    
    // 3. Aplicar ranking personalizado
    resultados = _rankResults(resultados, query);
    
    return resultados.take(limit).toList();
  }
  
  /// Búsqueda local con FTS5 + fallback a LIKE
  Future<List<Alimento>> _searchLocal(
    String query, {
    SearchFilters? filters,
  }) async {
    // Intentar FTS5 primero
    var results = await _db.buscarPorFTS(query).get();
    
    // Si no hay resultados FTS, usar LIKE
    if (results.isEmpty) {
      results = await _db.buscarPorNombre(query).get();
    }
    
    // Aplicar filtros adicionales
    if (filters != null) {
      results = results.where((a) => _matchesFilters(a, filters)).toList();
    }
    
    return results;
  }
  
  /// Búsqueda en APIs remotas
  Future<List<Alimento>> _searchRemote(String query) async {
    final results = <Alimento>[];
    
    // Paralelizar llamadas a APIs
    await Future.wait([
      _offApi.searchProducts(
        searchTerms: query,
        pageSize: 20,
        sortBy: SortBy.popularity,
      ).then((response) {
        results.addAll(response.products.map(_mapOFFToAlimento));
      }).catchError((_) {}), // Ignorar errores de API
      
      if (_fatSecretApi != null)
        _fatSecretApi!.search(
          searchExpression: query,
          maxResults: 20,
        ).then((response) {
          results.addAll(response.foods.map(_mapFatSecretToAlimento));
        }).catchError((_) {}),
    ]);
    
    // Guardar resultados remotos en caché local
    await _cacheAlimentos(results);
    
    return results;
  }
  
  /// Búsqueda por código de barras
  Future<List<Alimento>> searchByBarcode(String barcode) async {
    // 1. Buscar localmente
    final local = await _db.buscarPorBarcode(barcode).getSingleOrNull();
    if (local != null) {
      await _db.incrementarUso(local.id);
      return [local];
    }
    
    // 2. Buscar en Open Food Facts
    final offResult = await _offApi.getProduct(barcode);
    if (offResult.product != null) {
      final alimento = _mapOFFToAlimento(offResult.product!);
      await _db.insertAlimento(alimento);
      return [alimento];
    }
    
    // 3. Fallback a FatSecret
    if (_fatSecretApi != null) {
      final fsResult = await _fatSecretApi!.findIdForBarcode(barcode);
      if (fsResult != null) {
        final alimento = _mapFatSecretToAlimento(fsResult);
        await _db.insertAlimento(alimento);
        return [alimento];
      }
    }
    
    return [];
  }
  
  /// Obtener sugerencias de autocompletado
  Future<List<String>> getSuggestions(String prefix, {int limit = 10}) async {
    // 1. Sugerencias del historial del usuario
    final historial = await _db.obtenerSugerencias(prefix, limit: limit).get();
    
    // 2. Nombres de alimentos populares que coincidan
    final populares = await (_db.select(_db.alimentos)
      ..where((a) => a.nombre_normalizado.like('$prefix%'))
      ..orderBy([(a) => OrderingTerm.desc(a.popularidad)])
      ..limit(limit))
      .map((a) => a.nombre)
      .get();
    
    // Combinar y eliminar duplicados
    return {...historial, ...populares}.take(limit).toList();
  }
  
  /// Algoritmo de ranking de resultados
  List<Alimento> _rankResults(List<Alimento> results, String query) {
    final queryLower = query.toLowerCase();
    
    return results.map((alimento) {
      var score = 0.0;
      
      // 1. Coincidencia exacta al inicio (máxima prioridad)
      if (alimento.nombre.toLowerCase().startsWith(queryLower)) {
        score += 100;
      }
      // 2. Coincidencia exacta en cualquier parte
      else if (alimento.nombre.toLowerCase().contains(queryLower)) {
        score += 50;
      }
      // 3. Coincidencia en palabras individuales
      else if (alimento.nombre.toLowerCase().split(' ').any(
        (word) => word.startsWith(queryLower)
      )) {
        score += 30;
      }
      
      // 4. Boost por popularidad (escala logarítmica)
      score += log(alimento.popularidad + 1) * 5;
      
      // 5. Boost por uso reciente del usuario
      if (alimento.ultimaVezUsado != null) {
        final diasDesdeUso = DateTime.now()
          .difference(alimento.ultimaVezUsado!)
          .inDays;
        score += max(0, 20 - diasDesdeUso);
      }
      
      // 6. Boost por verificación
      if (alimento.esVerificado) score += 10;
      
      // 7. Penalización por incompletitud
      score -= (100 - alimento.porcentajeCompletitud) * 0.1;
      
      return alimento.copyWith(score: score);
    }).sorted((a, b) => b.score.compareTo(a.score));
  }
  
  String _normalizeText(String text) {
    return text
      .toLowerCase()
      .normalizeNFD() // Quitar acentos
      .replaceAll(RegExp(r'[^\w\s]'), '') // Quitar puntuación
      .trim();
  }
  
  bool _matchesFilters(Alimento a, SearchFilters f) {
    if (f.soloGenericos && !a.esGenerico) return false;
    if (f.soloVerificados && !a.esVerificado) return false;
    if (f.categoria != null && a.categoria != f.categoria) return false;
    if (f.minProteinas != null && (a.proteinas ?? 0) < f.minProteinas!) {
      return false;
    }
    if (f.maxCalorias != null && (a.energiaKcal ?? double.infinity) > f.maxCalorias!) {
      return false;
    }
    return true;
  }
  
  Future<void> _cacheAlimentos(List<Alimento> alimentos) async {
    for (final a in alimentos) {
      await _db.insertAlimentoOnConflictUpdate(a);
    }
  }
}
```

### 4.5 Implementación de Fuzzy Search Local

**fuzzy_search_service.dart:**
```dart
import 'package:fuzzy_bolt/fuzzy_bolt.dart';

class FuzzySearchService {
  late FuzzyBolt<Alimento> _fuzzyEngine;
  bool _initialized = false;
  
  Future<void> initialize(List<Alimento> alimentos) async {
    _fuzzyEngine = FuzzyBolt<Alimento>(
      items: alimentos,
      getSearchableText: (a) => '${a.nombre} ${a.marca ?? ''} ${a.categoria ?? ''}',
      options: FuzzyOptions(
        threshold: 0.5, // 0-1, menor = más estricto
        distance: 100, // Máxima distancia para considerar match
        usePorterStemming: true, // Normalizar palabras a raíz
        useIsolate: alimentos.length > 1000, // Usar isolate para datasets grandes
      ),
    );
    _initialized = true;
  }
  
  List<Alimento> search(String query, {int limit = 20}) {
    if (!_initialized) return [];
    
    final results = _fuzzyEngine.search(query);
    return results.take(limit).toList();
  }
  
  // Búsqueda con fallback: exacta → FTS → Fuzzy
  Future<List<Alimento>> smartSearch(
    AppDatabase db,
    String query, {
    int limit = 50,
  }) async {
    final normalized = query.toLowerCase().trim();
    
    // 1. Búsqueda exacta (más rápida)
    final exact = await db.buscarPorNombre(normalized).get();
    if (exact.isNotEmpty) return exact.take(limit).toList();
    
    // 2. Búsqueda FTS5
    final fts = await db.buscarPorFTS('$normalized*').get();
    if (fts.isNotEmpty) return fts.take(limit).toList();
    
    // 3. Fuzzy search (último recurso, más lento)
    if (_initialized) {
      return search(normalized, limit: limit);
    }
    
    return [];
  }
}
```

### 4.6 UI Components

**search_bar_widget.dart:**
```dart
class SearchBarWidget extends ConsumerWidget {
  const SearchBarWidget({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final suggestions = ref.watch(searchSuggestionsProvider);
    
    return Column(
      children: [
        TextField(
          controller: TextEditingController(text: query)
            ..selection = TextSelection.collapsed(offset: query.length),
          onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
          decoration: InputDecoration(
            hintText: 'Buscar alimentos...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                )
              : null,
          ),
        ),
        // Sugerencias de autocompletado
        suggestions.when(
          data: (suggestions) => suggestions.isEmpty
            ? const SizedBox.shrink()
            : SuggestionsList(
                suggestions: suggestions,
                onSelect: (s) => ref.read(searchQueryProvider.notifier).state = s,
              ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
```

**search_results_widget.dart:**
```dart
class SearchResultsWidget extends ConsumerWidget {
  const SearchResultsWidget({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider);
    
    return results.when(
      data: (alimentos) => alimentos.isEmpty
        ? const EmptySearchState()
        : ListView.builder(
            itemCount: alimentos.length,
            itemBuilder: (context, index) {
              final alimento = alimentos[index];
              return AlimentoListTile(
                alimento: alimento,
                onTap: () {
                  // Registrar uso
                  ref.read(searchHistoryProvider.notifier)
                    .addQuery(ref.read(searchQueryProvider), alimentoId: alimento.id);
                  // Navegar a detalle
                  context.push('/alimento/${alimento.id}');
                },
              );
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
```

---

## 5. ESTRATEGIAS AVANZADAS

### 5.1 Búsqueda por Imagen (Computer Vision)

**Integración con ML Kit:**
```dart
class ImageSearchService {
  final ImageLabeler _labeler = GoogleMlKit.vision.imageLabeler();
  
  Future<List<Alimento>> searchByImage(File image) async {
    // 1. Etiquetar imagen
    final labels = await _labeler.processImage(InputImage.fromFile(image));
    
    // 2. Filtrar etiquetas de comida (confidence > 0.7)
    final foodLabels = labels
      .where((l) => l.confidence > 0.7 && _isFoodLabel(l.label))
      .map((l) => l.label)
      .toList();
    
    // 3. Buscar cada etiqueta
    final results = <Alimento>[];
    for (final label in foodLabels) {
      final alimentos = await _repository.search(label);
      results.addAll(alimentos);
    }
    
    // 4. Agrupar por similitud y rankear
    return _deduplicateAndRank(results);
  }
}
```

### 5.2 Sincronización Offline-Online

```dart
@riverpod
class SyncManager extends _$SyncManager {
  @override
  Future<SyncStatus> build() async {
    // Escuchar cambios de conectividad
    ref.listen(connectivityProvider, (_, connectivity) {
      if (connectivity == ConnectivityResult.online) {
        _syncPendingData();
      }
    });
    
    return const SyncStatus.synced();
  }
  
  Future<void> _syncPendingData() async {
    final pending = await _db.getPendingSyncAlimentos().get();
    
    for (final alimento in pending) {
      try {
        // Subir a API personalizada si existe
        await _api.syncAlimento(alimento);
        await _db.markAsSynced(alimento.id);
      } catch (e) {
        // Mantener como pendiente para reintento
      }
    }
  }
}
```

### 5.3 Caché Inteligente

```dart
class SmartCache {
  final CacheManager _cache;
  final LRUCache<String, List<Alimento>> _memoryCache;
  
  Future<List<Alimento>> getOrFetch(
    String key,
    Future<List<Alimento>> Function() fetcher, {
    Duration ttl = const Duration(hours: 24),
  }) async {
    // 1. Memory cache (más rápido)
    if (_memoryCache.containsKey(key)) {
      return _memoryCache.get(key)!;
    }
    
    // 2. Disk cache
    final cached = await _cache.getFileFromCache(key);
    if (cached != null && cached.validTill.isAfter(DateTime.now())) {
      final data = jsonDecode(await cached.file.readAsString());
      final alimentos = (data as List).map((e) => Alimento.fromJson(e)).toList();
      _memoryCache.put(key, alimentos);
      return alimentos;
    }
    
    // 3. Fetch fresco
    final fresh = await fetcher();
    await _cache.putFile(
      key,
      Uint8List.fromList(utf8.encode(jsonEncode(fresh))),
      maxAge: ttl,
    );
    _memoryCache.put(key, fresh);
    
    return fresh;
  }
}
```

---

## 6. REFERENCIAS

### APIs Documentadas
- **FatSecret Platform API:** https://platform.fatsecret.com/api/
- **Open Food Facts API v2:** https://openfoodfacts.github.io/openfoodfacts-server/api/
- **USDA FoodData Central:** https://fdc.nal.usda.gov/api-guide

### Paquetes Flutter/Dart
- **drift:** https://pub.dev/packages/drift
- **fuzzy_bolt:** https://pub.dev/packages/fuzzy_bolt
- **riverpod:** https://riverpod.dev/
- **google_ml_kit:** https://pub.dev/packages/google_ml_kit

### Papers y Recursos
- "Algorithm-based mapping of products in a branded Canadian food and beverage database" - Frontiers in Nutrition 2022
- "Accuracy of Nutrient Calculations Using MyFitnessPal" - PMC 2019
- "Evaluating the Quality of AI-Enabled Food Image Recognition" - MDPI Nutrients 2024

---

*Corpus generado el: 2026-01-31*
*Listo para implementación en proyecto Flutter + Drift + Riverpod 3.0*
