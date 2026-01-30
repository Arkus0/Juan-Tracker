# Roadmap de Profundidad - Juan Tracker

> Roadmap basado en análisis DEPTH_MATRIX con priorización del usuario.
> **Filosofía**: "Easy to Learn, Hard to Master" - Surface layer intacto, Power layer accesible.

---

## 📋 RESUMEN EJECUTIVO

| Fase | Features | Timeline Est. | Impacto Usuario |
|------|----------|---------------|-----------------|
| **Sprint 1** | Progression Suggestions + Info Density | 1 semana | 🔥 Alto |
| **Sprint 2** | Export CSV + Block Programming (modo pro) | 2 semanas | 🔥 Alto |
| **Sprint 3** | RPE Education + Training-Diet Linking | 2 semanas | ⚡ Medio-Alto |
| **Sprint 4** | Batch Edit + Android Widget | 2 semanas | ⚡ Medio |
| **Fase 2** | Smart Rules Builder + Avanzados | 1-2 meses | 🎯 Power Users |

---

## 🚨 PRIORIDAD CRÍTICA (P0)

### 1. Progression Suggestions en UI
**Estado**: Motor existe, solo falta UI  
**Impacto**: Máximo - Feature fantasma más valiosa  
**Esfuerzo**: ⭐ Bajo (1-2 días)

#### Implementación
```dart
// Nuevo provider: progression_suggestion_provider.dart
final progressionSuggestionProvider = Provider.family<ProgressionSuggestion?, String>(
  (ref, exerciseId) {
    final engine = ref.watch(progressionEngineProvider);
    return engine.getSuggestionFor(exerciseId);
  },
);

// UI en ExerciseCard durante sesión
class ProgressionSuggestionChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 16, color: AppColors.primary),
          Text('Siguiente: 82.5kg × 5', 
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
```

#### Acceptance Criteria
- [ ] Al iniciar ejercicio con historial, mostrar sugerencia del ProgressionEngine
- [ ] Formato: "Siguiente: {weight}kg × {reps}" o "Mantener: {weight}kg"
- [ ] Tapping sugerencia autocompleta el primer set
- [ ] Solo visible si hay suficiente historial (3+ sesiones)

---

### 3. Information Density Toggle
**Estado**: No existe  
**Impacto**: Alto para power users en gimnasio  
**Esfuerzo**: ⭐ Bajo (1-2 días)

#### Implementación
```dart
// Nuevo provider
final informationDensityProvider = StateNotifierProvider<InformationDensityNotifier, DensityMode>(...);

enum DensityMode { compact, comfortable, detailed }

// Theme extension
class DensityTheme {
  static ThemeData forMode(DensityMode mode) {
    return baseTheme.copyWith(
      visualDensity: mode == DensityMode.compact 
        ? VisualDensity.compact 
        : VisualDensity.standard,
      cardTheme: CardTheme(
        margin: EdgeInsets.symmetric(
          vertical: mode == DensityMode.compact ? 2 : 8,
          horizontal: mode == DensityMode.compact ? 8 : 16,
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: mode == DensityMode.compact,
        minVerticalPadding: mode == DensityMode.compact ? 0 : 8,
      ),
    );
  }
}
```

#### Ubicación del toggle
- Settings → Display → "Densidad de información"
- Opciones: Compacta (power user) / Cómoda (default) / Detallada

#### Acceptance Criteria
- [ ] Toggle en Settings con 3 opciones
- [ ] Modo Compacto: menos padding, cards más pequeños, fuente -1pt
- [ ] Modo Detallado: más espaciado, hints visuales adicionales
- [ ] Persistir preferencia en SharedPreferences

---

### 4. Export CSV con Filtros
**Estado**: Export básico existe  
**Impacto**: Alto para usuarios que usan spreadsheets  
**Esfuerzo**: ⭐⭐ Medio (3-4 días)

#### Implementación
```dart
// Nuevo screen: ExportScreen
class ExportScreen extends StatelessWidget {
  // Filtros:
  // - Tipo: Entrenamiento / Dieta / Ambos
  // - Ejercicios: Todos / Seleccionar específicos
  // - Rango de fechas: Última semana / Mes / Personalizado
  // - Columnas: Checkbox para cada campo
}

// Generación CSV
String generateTrainingCSV({
  required List<Session> sessions,
  required List<String> selectedExercises,
  required DateTimeRange range,
  required List<String> columns, // ['date', 'exercise', 'weight', 'reps', 'rpe', 'volume']
}) {
  // Usar csv package
}
```

#### Acceptance Criteria
- [ ] Screen dedicado para export con filtros
- [ ] Selección de ejercicios específicos (search + multi-select)
- [ ] Rango de fechas personalizable
- [ ] Columnas seleccionables (weight, reps, rpe, volume, etc.)
- [ ] Formato CSV compatible con Excel/Google Sheets (UTF-8 BOM)
- [ ] Compartir vía ShareSheet o guardar en Downloads

---

### 2. Block Programming (Modo Pro)
**Estado**: No existe  
**Impacto**: Crítico para usuarios avanzados  
**Esfuerzo**: ⭐⭐ Medio-Alto (1 semana)  
**Nota**: Modo opcional accesible desde menú de 3 puntos

#### Implementación
```dart
// Nuevo modelo: TrainingBlock
@DriftAccessor
class TrainingBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()(); // "Volumen Hipertrófia Q1"
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  IntColumn get type => intEnum<BlockType>()(); // accumulation, intensification, peaking, deload
  TextColumn get routineId => text()();
  TextColumn get progressionRules => text().nullable()(); // JSON de reglas
}

// UI - Modo Pro toggle en RoutineEditScreen
PopupMenuItem(
  value: 'enable_pro_mode',
  child: Row(
    children: [
      Icon(Icons.science),
      Text('Modo Pro (Periodización)'),
    ],
  ),
)

// Cuando está activo:
// - Mostrar campos de block programming
// - Permitir definir fases (mesociclos)
// - Auto-calcular deload weeks
```

#### Acceptance Criteria
- [ ] Menú de 3 puntos en crear/editar rutina con "Activar Modo Pro"
- [ ] Modo Pro habilita:
  - Definir bloques con fechas inicio/fin
  - Seleccionar tipo de bloque (acumulación/intensificación/peaking/deload)
  - Ver timeline visual del bloque
- [ ] Al crear sesión, mostrar en qué fase del bloque estás
- [ ] Persistir modo pro por rutina

---

## ⚡ PRIORIDAD ALTA (P1)

### 5. RPE Education
**Esfuerzo**: ⭐ Bajo  
**Implementación**: Tooltips contextuales

```dart
// En SetInputWidget, cuando RPE es null primera vez
Tooltip(
  message: 'RPE 10 = Máximo esfuerzo\nRPE 8 = 2 reps en reserva\nRPE 6 = 4 reps en reserva',
  child: IconButton(
    icon: Icon(Icons.help_outline),
    onPressed: () => showRPEGuide(context),
  ),
)

// Dialog educativo
void showRPEGuide(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Escala de Esfuerzo (RPE)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RPERow(value: 10, description: 'Máximo esfuerzo, no más reps'),
          _RPERow(value: 9, description: '1 rep en reserva'),
          _RPERow(value: 8, description: '2 reps en reserva'),
          _RPERow(value: 7, description: '3 reps en reserva'),
          // ...
        ],
      ),
    ),
  );
}
```

---

### 7. Training-Diet Linking
**Esfuerzo**: ⭐⭐ Medio  
**Implementación**: Cross-module analytics básico

```dart
// Nuevo provider: trainingDietCorrelationProvider
final trainingDietCorrelationProvider = FutureProvider<CorrelationData>((ref) async {
  final sessions = await ref.watch(recentSessionsProvider.future);
  final diary = await ref.watch(recentDiaryProvider.future);
  
  return CorrelationData(
    // Correlar volumen semanal con calorías promedio
    // Detectar: "Volumen sube pero fuerza baja + déficit calórico = overreaching?"
  );
});

// UI en AnalysisScreen - nueva pestaña "Correlaciones"
// Card: "Esta semana: Volumen +15%, Calorías -10%, Fuerza mantenida"
// Alerta si: Déficit agresivo + Intensidad alta > 2 semanas
```

#### Acceptance Criteria
- [ ] Nueva pestaña en Analysis: "Correlaciones"
- [ ] Mostrar volumen semanal vs calorías promedio (gráfico dual)
- [ ] Alerta contextual si se detecta patrón riesgoso
- [ ] Badge en home cuando hay insights nuevos

---

## 📱 PRIORIDAD MEDIA (P2) - Rediseñada

### Batch Edit Mode
**Esfuerzo**: ⭐⭐ Medio  
**Implementación**: Long-press para selección múltiple

```dart
// En SessionScreen
class BatchEditController extends StateNotifier<BatchEditState> {
  void toggleSetSelection(String setId);
  void updateSelectedSets({double? weight, int? reps, int? rpe});
  void deleteSelectedSets();
}

// UI: Modo batch activado vía long-press o botón en AppBar
// - Checkbox aparece en cada set
// - Bottom bar con acciones: Editar, Borrar, Copiar
```

---

### Android Widget
**Esfuerzo**: ⭐⭐⭐ Alto (requiere native code)  
**Funcionalidad**: 3 acciones rápidas

```kotlin
// Android: home_widget.xml
<LinearLayout>
    <Button android:id="@+id/btn_train" 
            android:text="Entrenar"
            android:drawableTop="@drawable/ic_dumbbell" />
    <Button android:id="@+id/btn_weight" 
            android:text="Peso"
            android:drawableTop="@drawable/ic_scale" />
    <Button android:id="@+id/btn_food" 
            android:text="Comida"
            android:drawableTop="@drawable/ic_food" />
</LinearLayout>

// Deep links:
// juantracker://training/start
// juantracker://weight/log
// juantracker://diary/add
```

---

## 🎯 FASE 2 - MÁS ADELANTE

Ordenados por preferencia del usuario:

### 1. Smart Rules Builder ⭐ (Prioridad máxima de esta fase)
**Concepto**: IF-THEN simple pero potente
```dart
// Ejemplos de reglas:
"IF últimos 3 sets RPE ≤ 7 THEN sugerir +2.5kg"
"IF semana 4 de bloque THEN auto-sugerir deload"
"IF no entreno en 3 días THEN notificación"
```

### 2. Macro Cycling
**Concepto**: High carb / Low carb days
```dart
// Targets por día de la semana:
Lunes (Pierna): High carb - 300g carbs
Martes (Descanso): Low carb - 100g carbs
```

### 3. Nutrient Timing
**Concepto**: Track de nutrientes peri-workout
```dart
// Campo opcional en diary entry:
// Timing: Pre-entreno / Post-entreno / Otra
```

### 4. Rest Pause Flags
**Concepto**: Flag en set para indicar técnica
```dart
enum SetTechnique {
  standard,
  restPause,    // Descanso corto entre mini-sets
  dropSet,      // Ya existe
  cluster,      // Descanso intra-set
}
```

### 5. Myo-reps
**Concepto**: Flag específico para myo-reps
```dart
// Myo-reps: 1 activation set + 5 mini-sets
// UI: Input especial para myo-reps con contador de mini-sets
```

---

## ❌ DESCARTADOS

| Feature | Razón |
|---------|-------|
| Velocity-Based Training (VBT) | Requiere hardware especializado |
| Multi-athlete support | Cambia modelo de negocio |
| Exercise comparison view | Overkill para uso individual |
| Keyboard shortcuts | Mobile-first, no tablets principal |
| Shake to undo | Poco descubrible, complejo de implementar bien |

---

## 📝 NOTAS DE IMPLEMENTACIÓN

### Patrón consistente para Power Features
```dart
// Todas las features avanzadas siguen este patrón:
// 1. Settings/Contextual menu para activar
// 2. UI adaptativa (no intrusiva para casuales)
// 3. Persistencia de preferencias
// 4. Tooltips educativos

// Ejemplo en RoutineEditScreen:
AppBar(
  actions: [
    PopupMenuButton(
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'pro_mode',
          child: Row(
            children: [
              Icon(Icons.science, color: isProMode ? AppColors.primary : null),
              Text('Modo Pro ${isProMode ? "(Activo)" : ""}'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block_programming',
          enabled: isProMode,
          child: Text('Configurar Bloque'),
        ),
      ],
    ),
  ],
)
```

---

*Documento vivo - actualizar según progreso*
