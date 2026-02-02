# Exercise Library Audit Report

> Auditoría técnica de la biblioteca de ejercicios de Juan Tracker
> **Fecha:** Febrero 2026  
> **Auditor:** Code Review Assistant

---

## 1. Resumen Ejecutivo

| Métrica | Valor | Estado |
|---------|-------|--------|
| Total ejercicios | 200 | ✅ |
| Mapeos de alternativas | 70 (35%) | 🟡 |
| Campos obligatorios completos | 100% | ✅ |
| IDs únicos | 100% | ✅ |
| Imágenes disponibles | 0 (0%) | 🔴 |

**Veredicto general:** La biblioteca es funcional pero tiene áreas de mejora significativas.

---

## 2. Estructura de Datos

### 2.1 Schema Actual (exercises_local.json)

```json
{
  "id": "string (unique)",
  "nombre": "string",
  "grupoMuscular": "string (categoría)",
  "musculosSecundarios": ["string"],
  "equipo": "string",
  "nivel": "basico|intermedio|avanzado",
  "descripcion": "string (vacío en 95%)"
}
```

**Problemas identificados:**
- ❌ **Campo `id` inconsistente:** Algunos son strings descriptivos (`"press_banca_con_barra"`), otros podrían ser numéricos. El sistema asigna IDs numéricos secuenciales en runtime (1-200).
- ❌ **Sin campo `muscles` (primarios):** El JSON tiene `grupoMuscular` pero no la lista detallada de músculos primarios que sí existe en el modelo `LibraryExercise.muscles`.
- ❌ **Descripciones vacías:** ~95% de ejercicios tienen `"descripcion": ""` - oportunidad de contenido.
- ❌ **Sin imágenes:** Ningún ejercicio tiene URLs de imágenes o referencias locales.

### 2.2 Distribución por Grupo Muscular

| Grupo | Count | % | Evaluación |
|-------|-------|---|------------|
| Pecho | 53 | 26.5% | ✅ Excelente cobertura |
| Espalda | 39 | 19.5% | ✅ Buena cobertura |
| Hombros | 22 | 11% | ✅ Adecuado |
| Piernas | 16 | 8% | 🟡 Bajo (solo cuádriceps) |
| Triceps | 14 | 7% | ✅ Adecuado |
| Core | 12 | 6% | ✅ Adecuado |
| Biceps | 12 | 6% | ✅ Adecuado |
| Full body | 10 | 5% | ✅ Adecuado |
| Femoral | 6 | 3% | 🔴 Muy bajo |
| Gemelos | 6 | 3% | 🔴 Muy bajo |
| Gluteos | 6 | 3% | 🔴 Muy bajo |
| Trapecio | 4 | 2% | 🔴 Muy bajo |

**Hallazgos críticos:**
- **Desbalance piernas:** Solo 16 ejercicios de "Piernas" (cuádriceps) vs 6 de femorales. Ratio 2.7:1 debería ser más cercano a 1:1.
- **Glúteos subrepresentados:** Solo 6 ejercicios específicos, tendencia importante en fitness femenino.

### 2.3 Distribución por Equipment

| Equipment | Count | % | Notas |
|-----------|-------|---|-------|
| Mancuernas | 51 | 25.5% | ✅ Versátil |
| Máquina | 46 | 23% | ✅ Gimnasio completo |
| Barra | 45 | 22.5% | ✅ Strength training |
| Peso corporal | 24 | 12% | ✅ Calistenia |
| Cable | 21 | 10.5% | ✅ Isolación |
| Kettlebell | 6 | 3% | 🟡 Especializado |
| Lastre | 3 | 1.5% | 🔴 Raro |
| Bandas | 2 | 1% | 🔴 Muy raro |
| Rueda | 2 | 1% | 🔴 Muy raro |

**Distribución saludable:** Las 4 categorías principales representan 83.5% de los ejercicios.

---

## 3. Sistema de Alternativas

### 3.1 Cobertura

- **Mapeos explícitos:** 70 ejercicios (35%)
- **Fallback por muscleGroup:** 100% (todos los ejercicios tienen grupo muscular)

### 3.2 Calidad del Fallback

El algoritmo `_findAlternativesByMuscles` implementado en `exercise_alternatives_provider.dart`:

```dart
// Scoring:
// +2 puntos por cada músculo primario compartido
// +1 punto por cada músculo secundario compartido
```

**Limitaciones identificadas:**
- 🟡 **Sin consideración de movimiento:** Un press de banca y un press militar comparten tríceps/hombros pero son patrones de movimiento completamente diferentes.
- 🟡 **Sin metadatos de dificultad:** No se considera el nivel (básico/intermedio/avanzado) al sugerir alternativas.

### 3.3 Recomendaciones

```dart
// Mejora propuesta: Añadir patrón de movimiento
enum MovementPattern {
  horizontalPush,   // Press banca
  verticalPush,     // Press militar
  horizontalPull,   // Remo
  verticalPull,     // Dominadas
  kneeDominant,     // Sentadilla
  hipDominant,      // Peso muerto
  // etc.
}
```

---

## 4. Problemas de Calidad de Datos

### 4.1 Inconsistencias de Nomenclatura

**Equipo:**
- `"barra"` vs `"Barra"` (normalizado en código, OK)
- `"mancuernas"` (plural consistente)
- `"maquina"` (sin tilde, inconsistente con español)

**Grupos musculares:**
- `"Piernas"` es muy genérico; debería separarse en `"Cuadriceps"`, `"Femorales"`

### 4.2 IDs Instables

Los IDs del JSON son strings descriptivos, pero el código asigna IDs numéricos secuenciales. Esto crea:
- Fragilidad si se reordena el JSON
- Imposibilidad de referenciar ejercicios estables entre versiones

**Recomendación:** Asignar IDs numéricos estables en el JSON:
```json
{
  "id": 101,
  "nombre": "Press banca con barra",
  // ...
}
```

---

## 5. Nueva Funcionalidad: Quick Exercise Swap

### 5.1 Implementación

**Archivos creados:**
- `lib/training/providers/exercise_alternatives_provider.dart` - Lógica de búsqueda
- `lib/training/widgets/session/exercise_swap_bottom_sheet.dart` - UI

**Archivos modificados:**
- `lib/training/providers/training_provider.dart` - Método `swapExerciseInSession()`
- `lib/training/widgets/session/exercise_card.dart` - Integración en menú

### 5.2 Features

- ✅ **Búsqueda por músculos compartidos** (puntuación ponderada)
- ✅ **Filtro por equipment** (barra, mancuernas, máquina, etc.)
- ✅ **Preservación de sets completados** (copia peso/reps como sugerencia)
- ✅ **Solo afecta sesión activa** (rutina base intacta)
- ✅ **Sin servidor** (100% offline)

### 5.3 Tests

- `test/training/providers/exercise_alternatives_provider_test.dart`
  - 8/8 tests passing
  - Cobertura de algoritmo de scoring
  - Tests de priorización por equipment

---

## 6. Recomendaciones de Mejora

### Prioridad Alta (ROI alto)

| Mejora | Impacto | Esfuerzo |
|--------|---------|----------|
| Añadir 20+ ejercicios de femorales/glúteos | 🟡 Alto | 🟡 Medio |
| Poblar campo `descripcion` para top 50 ejercicios | 🟡 Medio | 🟡 Medio |
| Estabilizar IDs numéricos en JSON | 🔴 Crítico | 🟢 Bajo |

### Prioridad Media

| Mejora | Impacto | Esfuerzo |
|--------|---------|----------|
| Añadir campo `movementPattern` | 🟡 Medio | 🟡 Medio |
| Expandir alternativas.json a 150+ mapeos | 🟡 Medio | 🟢 Bajo |
| Normalizar términos de equipo | 🟢 Bajo | 🟢 Bajo |

### Prioridad Baja

| Mejora | Impacto | Esfuerzo |
|--------|---------|----------|
| Añadir imágenes (URLs o assets locales) | 🟡 Alto | 🔴 Alto |
| Añadir videos instructivos | 🟡 Alto | 🔴 Alto |
| Tagging por nivel de dificultad efectivo | 🟢 Bajo | 🟡 Medio |

---

## 7. Métricas de Uso Sugeridas

Para futuras mejoras basadas en datos, recomendaría trackear:

```dart
// En ExerciseLibraryService
final Map<int, int> _searchFrequency = {}; // ID -> veces buscado
final Map<int, int> _selectionFrequency = {}; // ID -> veces seleccionado
final Map<int, int> _swapFrequency = {}; // ID original -> veces sustituido
```

Esto permitiría:
- Identificar ejercicios "problema" (muy sustituidos → calidad cuestionable)
- Detectar gaps de búsqueda (términos buscados sin resultados)
- Priorizar ejercicios populares para añadir descripciones/imágenes

---

## 8. Conclusión

La biblioteca de ejercicios es **funcional y adecuada** para el uso actual, con 200 ejercicios cubriendo los grupos musculares principales. Sin embargo, presenta oportunidades claras de mejora:

1. **Balance muscular:** Incrementar cobertura de femorales y glúteos
2. **Estabilidad de datos:** Migrar a IDs numéricos estables
3. **Contenido enriquecido:** Añadir descripciones e imágenes
4. **Sistema de alternativas:** Expandir mapeos explícitos y considerar patrones de movimiento

La nueva funcionalidad **Quick Exercise Swap** implementada en este PR aprovecha eficientemente la estructura existente y proporciona valor inmediato al usuario sin requerir cambios en el schema de datos.

---

*Auditoría completada: Febrero 2026*
