# Search Benchmark Results

> This document tracks food search performance measurements.
> Run the benchmark from: Perfil → Herramientas de Desarrollo → Benchmark Búsqueda

---

## Optimizations Applied (PR1)

### 1. Reduced Debounce (300ms → 150ms)
- File: [food_search_provider.dart](../lib/diet/providers/food_search_provider.dart)
- Line: ~101 (`_debounceDuration`)
- Impact: 150ms reduction in perceived latency

### 2. Short Query Policy (< 3 chars → no DB scan)
- File: [food_search_provider.dart](../lib/diet/providers/food_search_provider.dart)
- Method: `_handleShortQuery()`
- Impact: Eliminates expensive DB scans for typing "le", "ar", etc.
- UI: Shows "Escribe 3+ caracteres" hint + recent foods

### 3. FTS5 AND Semantics (instead of OR)
- File: [database.dart](../lib/training/database/database.dart)
- Method: `searchFoodsFTS()`
- Before: `leche* OR desnatada*` (matches either term)
- After: `leche* desnatada*` (matches BOTH terms)
- Impact: More precise multi-word search results

---

## Baseline (Pre-Optimization)

> **Date:** TBD (run on real device/emulator)
> **Device:** TBD
> **Foods in DB:** TBD
> **FTS entries:** TBD

### Query Latencies

| Query | Len | DB p50 | DB p95 | Rank p50 | Rank p95 | Total p50 | Total p95 | Results | Path | SLA |
|-------|-----|--------|--------|----------|----------|-----------|-----------|---------|------|-----|
| Short (2 chars) "le" | 2 | - | - | - | - | - | - | - | - | N/A (short query) |
| Medium (5 chars) "leche" | 5 | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Multi-token "leche desnatada" | 15 | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Common food "arroz integral" | 14 | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| Miss (random) "xyzqwerty123" | 12 | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

### SLA Targets

| Metric | Target | Status |
|--------|--------|--------|
| TTFR (queries ≥3 chars) | p95 < 120ms | ⏳ Pending |
| Query latency (DB + ranking) | p95 < 80ms | ⏳ Pending |
| Typing jank | No sustained drops | ⏳ Pending |
| Short queries (<3 chars) | No full DB scan | ✅ Implemented |

---

## How to Run Benchmark

1. Launch app in **profile mode** (for accurate timings):
   ```bash
   flutter run --profile -d <device>
   ```

2. Navigate to: **Perfil** → **Herramientas de Desarrollo** → **Benchmark Búsqueda**
   (Debug section only visible in debug/profile builds)

3. Tap **"Ejecutar Benchmark"**

4. Wait for all 5 scenarios to complete (200 iterations each)

5. Tap **Copy** icon to copy Markdown results

6. Paste results into this document

---

## After Optimization (PR1)

> **Date:** TBD
> **Changes:** 
> - Debounce 150ms (was 300ms)
> - Short query policy (<3 chars shows recents)
> - FTS5 AND semantics for multi-word

### Query Latencies (After)

| Query | Len | DB p50 | DB p95 | Rank p50 | Rank p95 | Total p50 | Total p95 | Results | Path | SLA |
|-------|-----|--------|--------|----------|----------|-----------|-----------|---------|------|-----|
| TBD | - | - | - | - | - | - | - | - | - | - |

### Improvement Summary

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| TTFR p95 (leche) | TBD | TBD | TBD |
| TTFR p95 (multi-token) | TBD | TBD | TBD |
| DB time p95 | TBD | TBD | TBD |
| Debounce latency | 300ms | 150ms | -150ms |

---

## Known Issues (Fixed)

1. ~~**FTS5 uses OR semantics**~~ → Fixed: Now uses AND for multi-word queries
2. ~~**300ms debounce**~~ → Fixed: Reduced to 150ms
3. ~~**No short query optimization**~~ → Fixed: <3 chars shows recents, no DB scan

## Remaining Issues

4. **FTS5 table sync** - Uses `food_id` as UNINDEXED column, not rowid-based (potential perf issue)

---

## Optimization Roadmap

### PR1: Speed SLA ✅
- [x] Reduce debounce to 150ms
- [x] Short query policy: <3 chars → show recents only
- [x] FTS5: AND semantics for multi-word queries
- [ ] Verify SLA with actual measurements on device

### PR2: Relevance
- [ ] Deterministic ranking function
- [ ] Boost recents/frequent
- [ ] Unit tests with fixture data

### PR3: Batch Add UX
- [ ] Multi-select mode
- [ ] Cart/batch bottom sheet
- [ ] Preserve last-used grams

### PR4: Reliability
- [ ] Gate voice/OCR/barcode behind experimental flag if unreliable
