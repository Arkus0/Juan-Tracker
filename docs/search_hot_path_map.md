# Search Hot Path Map

> This document maps the complete flow from user text input to search results display.
> Last updated: 2026-02-01

---

## Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌───────────────────┐    ┌──────────────────┐
│ UI Text Change  │───►│ FoodSearchNotif. │───►│ AlimentoRepository│───►│ AppDatabase      │
│ (TextField)     │    │ (debounce+cancel)│    │ (search+ranking)  │    │ (FTS5 query)     │
└─────────────────┘    └──────────────────┘    └───────────────────┘    └──────────────────┘
        │                       │                       │                       │
        │ onChanged             │ 300ms debounce        │ FTS5 + fallback       │ SQL query
        ▼                       ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌───────────────────┐    ┌──────────────────┐
│ UI Update       │◄───│ State Update     │◄───│ ScoredFood list   │◄───│ List<Food>       │
│ (ListView)      │    │ (results)        │    │ (with scores)     │    │ (raw results)    │
└─────────────────┘    └──────────────────┘    └───────────────────┘    └──────────────────┘
```

---

## Layer 1: UI Layer

### File: [food_search_unified_screen.dart](../lib/features/foods/presentation/food_search_unified_screen.dart)

| Component | Line | Function | Purpose |
|-----------|------|----------|---------|
| `_searchController` | ~90 | TextEditingController | Captures user text input |
| `_onSearchChanged()` | ~393 | Event handler | Called on every text change |
| `searchQueryProvider` | ~400 | Sync provider | Stores current query string |
| `foodSearchProvider` | ~403 | Triggers search | Calls `search(query)` on notifier |

**Critical Path:**
```dart
void _onSearchChanged(String value) {
  // 1. Update mode to "search"
  ref.read(foodInputModeProvider.notifier).setMode(FoodInputMode.search);
  // 2. Store query in sync provider
  ref.read(searchQueryProvider.notifier).setQuery(trimmed);
  // 3. Trigger search (has internal debounce)
  ref.read(foodSearchProvider.notifier).search(trimmed);
}
```

---

## Layer 2: State Management (Riverpod)

### File: [food_search_provider.dart](../lib/diet/providers/food_search_provider.dart)

| Component | Line | Function | Purpose |
|-----------|------|----------|---------|
| `FoodSearchNotifier` | ~93 | Notifier class | Manages search state |
| `_debounceDuration` | ~97 | 300ms | Debounce timer constant |
| `search()` | ~111 | Entry point | Starts debounced search |
| `_performSearch()` | ~156 | Actual search | Calls repository after debounce |
| `FoodSearchState` | ~28 | State class | Holds results, status, etc. |

**Critical Path:**
```dart
void search(String query) {
  // 1. Cancel previous timer/request
  _debounceTimer?.cancel();
  _cancelToken?.cancel();

  // 2. Length check: < 2 chars → idle, no search
  if (trimmed.length < 2) {
    state = state.copyWith(status: SearchStatus.idle);
    return;
  }

  // 3. Set loading state immediately
  state = state.copyWith(status: SearchStatus.loading);

  // 4. Debounce 300ms, then call _performSearch()
  _debounceTimer = Timer(_debounceDuration, () async {
    await _performSearch(trimmed);
  });
}
```

**Performance Concerns:**
- ⚠️ 300ms debounce may feel sluggish for local search
- ⚠️ No short-query optimization (2-char minimum, but still queries DB)
- ✅ Cancellation of previous request via CancelToken

---

## Layer 3: Repository

### File: [alimento_repository.dart](../lib/diet/repositories/alimento_repository.dart)

| Component | Line | Function | Purpose |
|-----------|------|----------|---------|
| `search()` | ~116 | Main search | Local FTS5 search |
| `_applyFilters()` | ~200+ | Post-filter | Applies SearchFilters |
| `_calculateBaseScore()` | ~350+ | Scoring | Computes relevance score |
| `_applyRanking()` | ~430+ | Sorting | Sorts by score desc |
| `searchOnline()` | ~160 | OFF API | Open Food Facts search |

**Critical Path:**
```dart
Future<List<ScoredFood>> search(String query, {filters, limit = 50}) async {
  // 1. Normalize query
  final normalizedQuery = query.toLowerCase().trim();

  // 2. FTS5 search (delegated to AppDatabase)
  var localResults = await _db.searchFoodsFTS(normalizedQuery, limit: limit);

  // 3. Apply filters (in-memory)
  if (filters != null) {
    localResults = _applyFilters(localResults, filters);
  }

  // 4. Convert to ScoredFood with base score
  final scoredResults = localResults.map((f) => ScoredFood(
    food: f,
    score: _calculateBaseScore(f, normalizedQuery),
  )).toList();

  // 5. Apply ranking (sort by score)
  return _applyRanking(scoredResults, normalizedQuery).take(limit).toList();
}
```

**Performance Concerns:**
- ⚠️ Ranking done in-memory after full fetch
- ⚠️ `_calculateBaseScore()` called for each result (N iterations)
- ⚠️ No pagination offset support currently
- ✅ Limit applied at DB level

---

## Layer 4: Database (Drift + SQLite)

### File: [database.dart](../lib/training/database/database.dart)

| Component | Line | Function | Purpose |
|-----------|------|----------|---------|
| `searchFoodsFTS()` | ~705 | FTS5 query | Main FTS search |
| `_searchFoodsLike()` | ~750 | Fallback | LIKE-based fallback |
| `_mapRowToFood()` | ~780 | Mapping | QueryRow → Food |
| `searchFoodsByPrefix()` | ~830 | Prefix | Fast prefix search |

**FTS5 Query Construction:**
```dart
Future<List<Food>> searchFoodsFTS(String query, {int limit = 50}) async {
  // 1. Sanitize: remove special FTS chars
  final sanitized = query.toLowerCase()
    .replaceAll(RegExp(r'["\-*()]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

  // 2. Split into terms
  final terms = sanitized.split(' ').where((t) => t.isNotEmpty).toList();

  // 3. Build FTS query with prefix matching
  final ftsQuery = terms.map((t) => '$t*').join(' OR ');

  // 4. Execute FTS query with JOIN
  final results = await customSelect(
    'SELECT f.* FROM foods f '
    'INNER JOIN foods_fts fts ON f.id = fts.food_id '
    'WHERE fts MATCH ? '
    'ORDER BY rank '
    'LIMIT ?',
    variables: [Variable(ftsQuery), Variable(limit)],
  ).get();

  return results.map((row) => _mapRowToFood(row)).toList();
}
```

**Performance Concerns:**
- ⚠️ FTS query uses `OR` between terms (less precise)
- ⚠️ `ORDER BY rank` is correct for FTS5, but rank is relative
- ⚠️ JOIN on `food_id` (non-rowid) may be slower than rowid-based
- ⚠️ `_mapRowToFood()` reads all columns (potential optimization)
- ✅ LIMIT applied at SQL level
- ✅ FTS5 prefix matching (`term*`)

---

## FTS5 Table Schema

### File: [database.dart](../lib/training/database/database.dart) (Lines ~432-450)

```sql
-- Virtual FTS5 table (defined in migrations)
CREATE VIRTUAL TABLE foods_fts USING fts5(
  food_id UNINDEXED,  -- Links to foods.id (not rowid!)
  name,
  brand
);
```

**Synchronization:**
```dart
// Insert into FTS index
await customStatement('''
  INSERT INTO foods_fts(food_id, name, brand)
  SELECT id, name, COALESCE(brand, '') FROM foods
''');
```

**Performance Concerns:**
- ⚠️ `food_id UNINDEXED` means JOINs use food_id, not implicit rowid
- ⚠️ No tokenizer configured (uses default unicode61)
- ⚠️ No prefix index defined (could add `prefix="2 3"`)
- ⚠️ Sync is manual (could get out of sync)

---

## Timing Breakdown (Estimated)

| Phase | Expected Time | Notes |
|-------|---------------|-------|
| UI → Notifier | ~0ms | Synchronous |
| Debounce wait | 300ms | Fixed delay ⚠️ |
| FTS5 query | 5-50ms | Depends on DB size |
| Row mapping | 0.5ms × N | N = result count |
| Score calculation | 0.1ms × N | In-memory |
| Ranking sort | O(N log N) | In-memory |
| UI rebuild | 16ms | Single frame |

**Total TTFR (worst case):** ~300ms debounce + 50ms DB + 10ms mapping/ranking = **360ms**

This exceeds the 120ms SLA!

---

## Identified Bottlenecks

### 🔴 Critical

1. **300ms debounce is too long for local search**
   - Local FTS5 should be <50ms
   - Debounce 150ms max, or no debounce for local

2. **No short query optimization**
   - Queries like "le" (2 chars) still hit DB
   - Should show recents/frequent instead

3. **FTS5 uses OR (not AND)**
   - "leche desnatada" finds anything with "leche" OR "desnatada"
   - Should require ALL terms for multi-word queries

### 🟡 Medium

4. **Full column mapping**
   - `_mapRowToFood()` reads all 20+ columns
   - Could read subset for list view

5. **In-memory scoring/ranking**
   - Done after fetching all results
   - Could leverage FTS5 rank + SQL ordering

6. **No pagination offset**
   - `loadMore()` re-runs full query
   - Should use OFFSET or cursor

### 🟢 Low

7. **FTS tokenizer not configured**
   - Default unicode61 is fine for Spanish
   - Could add porter stemmer for better matching

8. **No FTS prefix index**
   - Could speed up prefix queries
   - `prefix="2 3"` in FTS5 table definition

---

## Optimization Roadmap

### Phase 1: Meet SLA (FTS5 + Speed)

1. Reduce debounce to 150ms (or eliminate for local)
2. Short query policy: <3 chars → show recents only
3. FTS5: AND semantics for multi-word
4. Verify FTS5 table sync is working

### Phase 2: Relevance

1. Deterministic ranking function
2. Boost recents/frequent
3. Unit tests with fixture data

### Phase 3: UX

1. Multi-add batch mode
2. Preserve last-used grams

### Phase 4: Reliability

1. Voice/OCR/barcode gate or fix

---

## Files Summary

| Layer | File | Key Functions |
|-------|------|---------------|
| UI | `lib/features/foods/presentation/food_search_unified_screen.dart` | `_onSearchChanged()` |
| State | `lib/diet/providers/food_search_provider.dart` | `FoodSearchNotifier.search()`, `_performSearch()` |
| Repository | `lib/diet/repositories/alimento_repository.dart` | `search()`, `_calculateBaseScore()` |
| Database | `lib/training/database/database.dart` | `searchFoodsFTS()`, `_searchFoodsLike()` |

---

*Next step: Create benchmark runner to capture baseline metrics.*
