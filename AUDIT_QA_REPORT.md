# Auditoría QA - Juan Tracker
## Flutter Fitness & Nutrition App
**Fecha:** 2026-01-31
**Versión analizada:** Commit d87f07a
**Auditor:** Claude (QA Lead + UX Auditor)

---

## 1. MAPA DE FLUJOS

### 1.1 Onboarding / Primera Apertura
```
main.dart → app.dart → SplashWrapper
    ├── Splash (1500ms animación)
    │   └── [Primera vez?] → OnboardingScreen (4 páginas)
    │                             └── [Skip/Finish] → EntryScreen
    └── [Ya onboarded] → EntryScreen
                              ├── [TAP NUTRICIÓN] → /nutrition (HomeScreen)
                              └── [TAP ENTRENAMIENTO] → /training (TrainingShell)
```

### 1.2 Flujo Entrenamiento
```
EntryScreen → TrainingShell (init libraries)
    └── MainScreen (4 tabs: Rutinas, Entrenar, Análisis, Ajustes)

CREAR RUTINA:
RutinasScreen
    └── [FAB +] → CreateEditRoutineScreen
                      ├── [+ Día] → Nuevo día expansible
                      ├── [+ Ejercicio] → BibliotecaBottomSheet
                      │                      └── Seleccionar → Añade a día
                      ├── [Editar ejercicio] → Series, reps, descanso
                      └── [Guardar] → Volver a RutinasScreen

INICIAR SESIÓN:
TrainSelectionScreen
    ├── [Sesión activa?] → TrainingSessionScreen (continuar)
    └── [Sin sesión] → Seleccionar rutina/día → TrainingSessionScreen

REGISTRAR SETS:
TrainingSessionScreen
    ├── Lista de ejercicios con sets
    ├── [TAP set] → FocusSessionScreen (modal focus)
    ├── [Input peso/reps] → Actualiza log
    ├── [Añadir set] → Inserta set adicional
    ├── [Rest timer] → RestTimerDialog
    ├── [+ Ejercicio] → SearchExerciseScreen
    └── [Finalizar] → Guarda sesión → HistoryScreen

HISTORIAL:
HistoryScreen
    └── Lista sesiones completadas → Detalle sesión
```

### 1.3 Flujo Dieta
```
EntryScreen → HomeScreen (5 tabs: Diario, Peso, Resumen, Coach, Perfil)

AÑADIR ALIMENTO:
DiaryScreen
    ├── Selector de fecha (calendario)
    ├── Lista entradas del día (por comida)
    ├── [FAB +] → FoodSearchScreen
    │               ├── Búsqueda local (debounce 300ms)
    │               ├── Búsqueda Open Food Facts
    │               ├── [Escanear código] → BarcodeScannerScreen
    │               ├── [OCR etiqueta] → Cámara/Galería → Parser
    │               ├── [Voz] → Speech-to-text
    │               ├── [Crear nuevo] → _CreateFoodDialog
    │               └── [Seleccionar] → AddEntryDialog
    │                                       └── Cantidad, comida → Guardar
    └── [Swipe entrada] → Editar/Eliminar

EDITAR ENTRADA:
DiaryScreen → [TAP entrada] → EditEntryDialog
                                  ├── Cambiar cantidad
                                  ├── Cambiar tipo comida
                                  └── [Guardar] → Recalcula macros

VER DÍA / SUMATORIO:
DiaryScreen muestra:
    - Totales del día (kcal, P, C, F)
    - Breakdown por comida (Desayuno, Almuerzo, Cena, Snack)
    - Barra de progreso vs targets
```

### 1.4 Flujo Peso / Check-ins
```
WeightScreen
    ├── Stats principales (último, tendencia, semana)
    ├── Gráfica evolución 30 días
    ├── Contexto de progreso
    ├── Lista registros (swipe para borrar)
    └── [FAB +] → AddWeightDialog
                      ├── Input peso (20-500 kg)
                      ├── Selector fecha (hasta 365 días atrás)
                      └── [Guardar] → Insertar registro
```

### 1.5 Flujo Coach Adaptativo
```
CoachScreen
    ├── [Sin plan] → PlanSetupScreen (crear plan)
    └── [Con plan] → Vista plan actual
                        ├── Objetivos actuales
                        ├── [Check-in semanal] → WeeklyCheckInScreen
                        │                            └── Aplica ajustes
                        └── [Editar plan] → PlanSetupScreen
```

---

## 2. TEST PLAN MANUAL (30-60 min)

### 2.1 HAPPY PATH (15 escenarios)

| ID | Escenario | Pasos | Resultado Esperado | Qué Podría Fallar |
|----|-----------|-------|-------------------|-------------------|
| HP-01 | Primera apertura | Instalar, abrir app | Ver splash → onboarding → entry screen | Splash no termina, onboarding loop |
| HP-02 | Crear rutina simple | Rutinas → + → Nombre → + Día → + Ejercicio → Guardar | Rutina aparece en lista | No guarda, ejercicios vacíos |
| HP-03 | Iniciar entrenamiento | Entrenar → Seleccionar rutina/día → Iniciar | Ver pantalla sesión con ejercicios | Sesión anterior no terminada bloquea |
| HP-04 | Registrar set completo | En sesión → Input peso (80) → Input reps (10) → Marcar completado | Set aparece verde, timer inicia | Datos no persisten, timer no arranca |
| HP-05 | Finalizar sesión | Completar todos sets → Finalizar | Sesión en historial con duración | Sesión se pierde, duración incorrecta |
| HP-06 | Añadir alimento local | Diario → + → Buscar "pollo" → Seleccionar → 150g → Guardar | Entrada aparece, kcal calculados | Macros incorrectos, fecha errónea |
| HP-07 | Quick add calorías | Diario → + → Rápido → "Café" 50kcal → Guardar | Entrada aparece como quick add | No guarda, no suma al total |
| HP-08 | Escanear código barras | Diario → + → Escanear → Apuntar a barcode | Producto encontrado en Open Food Facts | Cámara no abre, producto no encontrado |
| HP-09 | Registrar peso hoy | Peso → + → 75.5 → Guardar | Peso aparece en lista y gráfica | No guarda, gráfica no actualiza |
| HP-10 | Ver resumen diario | Resumen → Ver totales | Totales coinciden con entradas | Números incorrectos, datos desync |
| HP-11 | Cambiar fecha diario | Diario → Tap fecha → Seleccionar ayer | Ver entradas de ayer | Entradas de hoy persisten en UI |
| HP-12 | Editar entrada diario | Diario → Tap entrada → Cambiar a 200g → Guardar | Macros recalculados proporcional | Macros mal calculados |
| HP-13 | Eliminar entrada | Diario → Swipe entrada izq → Confirmar | Entrada desaparece, totales actualizan | Total no actualiza, undo no funciona |
| HP-14 | Ver historial entrenamientos | Análisis → BITÁCORA | Lista sesiones ordenadas por fecha | Sesiones duplicadas, orden incorrecto |
| HP-15 | Crear alimento custom | Diario → + → Crear "X" → Datos → Guardar | Alimento en biblioteca, usado en entrada | No guarda, macros 0 |

### 2.2 EDGE CASES (15 escenarios)

| ID | Escenario | Pasos | Resultado Esperado | Qué Podría Fallar |
|----|-----------|-------|-------------------|-------------------|
| EC-01 | App crash mid-session | Iniciar sesión → Registrar 3 sets → Force close → Reabrir | Sesión restaurada con 3 sets | Sets perdidos, sesión fantasma |
| EC-02 | Peso extremo (límites) | Peso → + → "19.9" → Guardar | Error "peso válido 20-500" | Guarda valor inválido |
| EC-03 | Cantidad 0 gramos | AddEntry → "0" gramos → Guardar | Error o no permitir | Guarda kcal=0, divide por 0 |
| EC-04 | Cantidad negativa | AddEntry → "-50" gramos → Guardar | Error o no permitir | Macros negativos |
| EC-05 | Fecha futura peso | Peso → + → Seleccionar mañana | No permitir fecha futura | Permite y muestra predicción errónea |
| EC-06 | Doble tap guardar | Crear entrada → Tap Guardar 2x rápido | Una sola entrada guardada | Entrada duplicada |
| EC-07 | Editar entrada inexistente | Abrir edit dialog → Otro proceso borra entrada → Guardar | Error graceful, no crash | Crash, entrada zombi |
| EC-08 | Buscar con caracteres especiales | Buscar "café & leche" | Resultados relevantes o vacío | Crash regex, SQL injection |
| EC-09 | Sesión sin ejercicios | Crear rutina vacía → Iniciar sesión | Error "añade ejercicios" o no permite | Sesión vacía sin sentido |
| EC-10 | Eliminar rutina con sesión activa | Mientras sesión activa → Rutinas → Eliminar esa rutina | Sesión continúa con datos archivados | Sesión corrupta, crash |
| EC-11 | Cambiar fecha mientras edita | Abrir AddEntry en día 15 → Cambiar a día 16 → Guardar | Entrada en día 15 (original) | Entrada en día 16 (incorrecto) |
| EC-12 | Múltiples pesos mismo día | Registrar peso 8am → Registrar peso 8pm | Ambos guardados, tendencia usa último | Solo uno visible, promedio incorrecto |
| EC-13 | Offline + sync | Modo avión → Añadir entrada → Restaurar conexión | Datos locales, sync si aplica | Pérdida de datos |
| EC-14 | Input peso con coma | Peso → + → "75,5" (coma europea) | Acepta como 75.5 | Error parse, no guarda |
| EC-15 | Back durante guardado async | Crear entrada → Guardar → Back inmediato | Entrada guardada, pantalla anterior | Operación cancelada, estado inconsistente |

---

## 3. MATRIZ DE HALLAZGOS

| ID | Flujo | Escenario | Severidad | Probabilidad | Impacto | Síntoma Usuario | Causa Raíz | Evidencia | Pasos Reproducción | Fix Mínimo | Test Regresión |
|-----|-------|-----------|-----------|--------------|---------|-----------------|------------|-----------|-------------------|------------|----------------|
| BUG-001 | Workout | Sesión activa se pierde al crash | Critical | Media | Pérdida de datos | "Perdí todo mi entrenamiento" | `trainingSessionProvider` guarda con debounce 500ms, si crash antes de flush no persiste | `session_persistence_service.dart:35-55` | 1. Iniciar sesión 2. Añadir 5 sets 3. Force close antes de 500ms | Guardar inmediatamente en cada updateLog, no solo debounce | Integration: Simular kill + verificar restore |
| BUG-002 | Workout | Timer de descanso no persiste | Major | Alta | UX confusa | "El timer se reinició solo" | `RestTimerController` usa SharedPreferences pero no sincroniza con sesión activa al restaurar | `training_provider.dart` RestTimerState + `session_persistence_service.dart` | 1. Iniciar sesión 2. Completar set 3. Timer arranca 4. Minimizar app 5. Volver | Persistir `restEndTime` en DB junto con sesión | Unit: Verificar timer restore |
| BUG-003 | Dieta | Editar entrada usa factor incorrecto | Major | Media | Datos incorrectos | Macros no cuadran al editar | `edit_entry_dialog.dart:111` calcula factor `newAmount/entry.amount`, pero si entry.amount original fue modificado previamente, el factor es sobre el amount actual, no sobre 100g base | `edit_entry_dialog.dart:82-99, 111` | 1. Añadir 50g pollo (100kcal/100g) = 50kcal 2. Editar a 100g 3. Esperar 100kcal 4. Ver resultado | Guardar `kcalPer100g` original en entry y recalcular desde base | Unit: Test edición secuencial |
| BUG-004 | Dieta | Cambiar fecha no limpia editingEntryProvider | Major | Media | Datos en fecha incorrecta | "Guardé comida en día equivocado" | `selectedDateProvider` cambia pero `editingEntryProvider` mantiene referencia al entry antiguo | `database_provider.dart:44-56` vs `diary_screen.dart` | 1. Editar entrada día 15 2. Cambiar a día 16 (sin cerrar edit) 3. Guardar | Reset `editingEntryProvider` al cambiar fecha o validar fecha en save | Widget: Test navegación fechas con diálogo abierto |
| BUG-005 | Peso | Swipe delete sin confirmación | Major | Alta | Pérdida de datos | "Borré peso sin querer" | `Dismissible.onDismissed` ejecuta delete sin confirm dialog | `weight_screen.dart:594-609` | 1. Lista pesos 2. Swipe accidental 3. Peso eliminado | Añadir `confirmDismiss` con dialog | Widget: Verificar confirm antes de delete |
| BUG-006 | Workout | Sesiones activas múltiples (corrupción) | Critical | Baja | Estado inconsistente | App se comporta raro | `getActiveSession()` usa `.get().first` pero puede haber múltiples por bug previo | `session_repository.dart:471-475` | Bug legacy o race condition en saves paralelos | Limpiar sesiones activas extra en init, log warning | Integration: Detectar y limpiar múltiples activas |
| BUG-007 | Dieta | Provider `currentMealTypeProvider` es estático | Minor | Alta | UX subóptima | Sugerencia desactualizada | `Provider` se evalúa una vez, no reactivo a cambios de hora | `database_provider.dart:258-260` | 1. Abrir app 10:30 (breakfast) 2. Dejar abierta hasta 12:00 3. Añadir comida → Sugiere breakfast | Usar timer o invalidar periódicamente | Unit: Mock hora y verificar cambio |
| BUG-008 | Workout | Weight 5x tolerance no previene guardado | Minor | Baja | Datos incorrectos | "Guardé 800kg sin querer" | `SuspiciousDataProvider` muestra warning pero no bloquea, usuario puede ignorar | `session_tolerance_provider.dart` suspiciousDataProvider | 1. Último peso 80kg 2. Ingresar 800kg 3. Ignorar warning 4. Guardar | Hacer warning modal con confirmación explícita | Unit: Verificar confirmación para valores sospechosos |
| BUG-009 | Dieta | `foodSearchResultsProvider` no cachea | Minor | Alta | Performance | Búsquedas lentas en biblioteca grande | `FutureProvider.autoDispose` recalcula en cada keystroke post-debounce | `database_provider.dart:70-74` | Escribir, borrar, reescribir misma query | Añadir cache por query reciente | Performance: Medir tiempo con 1000+ foods |
| BUG-010 | Workout | Rutina eliminada rompe historial | Major | Baja | Datos incompletos | "Sesión sin nombre de rutina" | `Sessions.routineId` es nullable pero UI asume nombre disponible | `session_repository.dart:73-83` + `history_screen.dart` | 1. Crear rutina + sesiones 2. Eliminar rutina 3. Ver historial | Mostrar "Rutina eliminada" o archivar nombre en sesión | Widget: Verificar render con rutinaId vacío |
| BUG-011 | Dieta | Open Food Facts duplica en biblioteca | Minor | Media | Datos duplicados | "Tengo el mismo producto 3 veces" | `_selectOpenFoodResult` busca por barcode, pero si no tiene barcode, no detecta duplicado | `food_search_screen.dart:470-524` | 1. Buscar "leche" 2. Guardar resultado sin barcode 3. Repetir | Buscar también por nombre normalizado + marca | Unit: Verificar detección duplicados |
| BUG-012 | Core | Timezone no normalizado en fechas | Critical | Baja | Datos incorrectos | "Entradas aparecen en día incorrecto" | `DiaryEntryModel` trunca a día local pero DB no normaliza timezone | `diary_entry_model.dart:91` `DateTime(date.year, date.month, date.day)` | 1. Viajar entre zonas horarias 2. Registrar entrada 3. Comparar fechas | Usar UTC internamente, convertir solo para display | Unit: Test con diferentes timezones |
| BUG-013 | Workout | Session dayIndex puede quedar null | Minor | Media | Smart suggestions fallan | "No me sugiere siguiente día" | `saveActiveSession` no siempre incluye dayIndex | `session_repository.dart:455-466` + `training_provider.dart` smartSuggestionProvider | Iniciar sesión ad-hoc sin rutina | Defaultear dayIndex a 0 o manejar null en suggestions | Unit: Verificar suggestions con dayIndex null |
| BUG-014 | Dieta | Recetas no actualizan si ingrediente cambia | Major | Baja | Datos desactualizados | "La receta tiene macros viejos" | `RecipeItems` guarda snapshots, no referencia live | `database.dart` RecipeItems schema | 1. Crear receta 2. Editar ingrediente 3. Ver receta → valores originales | Recalcular al abrir o añadir botón "actualizar" | Unit: Verificar recalculo |
| BUG-015 | Workout | Undo set no revierte timer | Minor | Media | UX inconsistente | "Deshice set pero timer sigue" | `undoLastSet()` remueve log pero no cancela rest timer iniciado | `training_provider.dart` undoLastSet vs startRestForExercise | 1. Completar set 2. Timer arranca 3. Undo 4. Timer continúa | Cancelar timer en undoLastSet | Unit: Verificar estado timer post-undo |

---

## 4. BUGS SILENCIOSOS

### 4.1 Calorías/Macros/Porciones

| ID | Bug | Archivo | Impacto | Verificación |
|----|-----|---------|---------|--------------|
| SILENT-001 | **Edición acumulativa de macros**: Al editar una entrada, el factor se calcula sobre el `amount` actual, no sobre la base original. Editar 50g→100g→150g da resultados diferentes que editar 50g→150g directo. | `edit_entry_dialog.dart:111` | Macros incorrectos en ediciones múltiples | Comparar: editar 50→150 vs 50→100→150 |
| SILENT-002 | **Porción sin gramos**: Si `food.portionGrams` es null y usuario selecciona "porción", `grams` = `amount` (asume 1 porción = 1g). | `diary_entry_model.dart:83-84` | Macros muy bajos | Crear food sin portionGrams, añadir 1 porción |
| SILENT-003 | **Redondeo kcal**: `kcal` es `int`, se redondea con `.round()`. En cantidades pequeñas (5g de algo con 10kcal/100g = 0.5 → 1 kcal o 0 kcal según timing). | `diary_entry_model.dart:98` | ±1 kcal por entrada, acumulativo | Añadir muchas entradas pequeñas |
| SILENT-004 | **DailyTotals no usa nulls correctamente**: `protein ?? 0` en suma, pero si TODOS son null, el total es 0.0, no null. No distingue "no hay datos" de "cero gramos". | `diary_entry_model.dart:227-228` | Usuario cree que registró 0g proteína | Añadir solo entries sin proteína |

### 4.2 Series/Reps/Peso/RPE

| ID | Bug | Archivo | Impacto | Verificación |
|----|-----|---------|---------|--------------|
| SILENT-005 | **Peso 0 permitido**: No hay validación mínima de peso en sets. `weight: 0` es válido y se guarda. | `training_provider.dart` updateLog | Sets con peso 0 afectan PRs y progresión | Ingresar peso 0, verificar que guarda |
| SILENT-006 | **RPE > 10 o < 1**: No hay clamp en input de RPE. Valores fuera de rango se guardan. | `training_provider.dart` SerieLog | Análisis de RPE incorrecto | Ingresar RPE 15, verificar guardado |
| SILENT-007 | **isWarmup no afecta volumen**: Sets de warmup se cuentan igual en análisis de volumen muscular. | `analytics_repository.dart` getMuscleVolumePeriod | Volumen inflado | Hacer 3 warmup sets, verificar cálculo volumen |
| SILENT-008 | **Dropsets cuentan como sets normales**: `isDropset=true` pero análisis de progresión los trata igual. | `progression_provider.dart` | Progresión calculada incorrectamente | Hacer sesión con dropsets, verificar sugerencia siguiente sesión |

### 4.3 Fechas/Días (Timezone)

| ID | Bug | Archivo | Impacto | Verificación |
|----|-----|---------|---------|--------------|
| SILENT-009 | **Entradas cerca de medianoche**: Usuario en zona -5 registra a 23:30, `DateTime.now()` local. Si viaja a zona +3, la entrada "salta" de día. | `diary_entry_model.dart:91` | Entradas en día incorrecto | Simular cambio timezone |
| SILENT-010 | **WeighIn usa datetime completo**: `measuredAt` incluye hora, pero lista ordena solo por fecha. Dos pesos mismo día pueden tener orden inconsistente. | `weight_screen.dart` list rendering | Último peso no es el más reciente del día | Registrar peso 8am, luego 10am, verificar "último" |
| SILENT-011 | **selectedDateProvider no trunca hora**: `setDate()` trunca, pero `goToToday()` usa `DateTime.now()` con hora. | `database_provider.dart:48-49` | Comparaciones de fecha fallan | Llamar goToToday(), comparar con entry.date |

### 4.4 Duplicados/Historial

| ID | Bug | Archivo | Impacto | Verificación |
|----|-----|---------|---------|--------------|
| SILENT-012 | **Historial ejercicio case-sensitive**: `getHistoryForExercise(exerciseName)` busca por nombre exacto. "Press Banca" ≠ "press banca". | `session_repository.dart:333-385` | Historial vacío para mismo ejercicio | Cambiar capitalización nombre ejercicio |
| SILENT-013 | **recentFoodsProvider puede tener duplicados**: `getRecentUniqueEntries` agrupa por `foodId`, pero entries sin foodId (quick add) se tratan como únicos. | `database_provider.dart:175-188` | Quick adds duplicados en sugerencias | Hacer múltiples quick add mismo nombre |

### 4.5 Borrados/Estados a Medias

| ID | Bug | Archivo | Impacto | Verificación |
|----|-----|---------|---------|--------------|
| SILENT-014 | **Sesión fantasma post-crash**: Si app crashea después de `_saveState()` pero antes de `finishSession()`, hay sesión activa en DB que nunca se completa. | `session_repository.dart` | Bloquea inicio nueva sesión o confunde | Simular crash, verificar `completedAt IS NULL` |
| SILENT-015 | **FTS index desync**: `FoodsFts` se actualiza manualmente. Si `insertFood` falla después de insert pero antes de `insertFoodFts`, búsqueda no encuentra. | `database.dart` food insert flow | Alimento existe pero no aparece en búsqueda | Simular error en insertFoodFts |
| SILENT-016 | **ConsumptionPatterns huérfanos**: Si food se borra (SET NULL en DiaryEntries), pero cascade no limpia todos los patterns. | `database.dart` foreign keys | Patterns para foods inexistentes | Borrar food, verificar patterns |

---

## 5. CHECKLIST DE CALIDAD PARA BETA

### 5.1 Estabilidad

- [ ] **Sin crashes en happy paths**: Todos los HP-01 a HP-15 completan sin error
- [ ] **Manejo de errores de red**: Búsqueda Open Food Facts muestra estado offline
- [ ] **Recuperación de sesión**: BUG-001 corregido, sesión sobrevive a crash
- [ ] **Sin ANR**: Operaciones de DB no bloquean UI (verificar con profiler)
- [ ] **Memory leaks**: Sin leaks en navegación repetida (verificar con DevTools)

### 5.2 Integridad de Datos

- [ ] **Macros correctos**: SILENT-001 corregido, ediciones calculan desde base
- [ ] **Fechas consistentes**: SILENT-009/010/011 corregidos, timezone manejado
- [ ] **Sin duplicados**: SILENT-012/013 corregidos, unicidad garantizada
- [ ] **Cascades funcionan**: Borrar rutina no corrompe historial
- [ ] **Transacciones atómicas**: Operaciones multi-tabla son todo-o-nada

### 5.3 Coherencia de Navegación

- [ ] **Back button predecible**: Siempre vuelve al estado anterior esperado
- [ ] **Deep links funcionan**: `/nutrition/diary`, `/training/session` abren correcto
- [ ] **Sin estados imposibles**: No se puede editar entry eliminado
- [ ] **Modales se cierran limpio**: Sin providers huérfanos post-dismiss
- [ ] **Tabs preservan estado**: Cambiar tab y volver mantiene scroll/datos

### 5.4 Comportamiento Offline

- [ ] **CRUD local funciona**: Añadir/editar/borrar sin conexión
- [ ] **Búsqueda local funciona**: FTS5 disponible offline
- [ ] **Indicador claro**: Usuario sabe que está offline
- [ ] **Sin pérdida de datos**: Todo persiste en SQLite local
- [ ] **Sync futuro**: Estructura lista para sync (aunque no implementado)

### 5.5 Mensajes de Error

- [ ] **Validación clara**: "Peso debe ser 20-500 kg", no "Error de validación"
- [ ] **Errores accionables**: "Revisa tu conexión" con botón retry
- [ ] **Sin stacktraces**: Errores técnicos loggeados, no mostrados
- [ ] **Confirmaciones destructivas**: "¿Eliminar peso?" antes de borrar
- [ ] **Feedback de éxito**: "Peso registrado" confirma acción

### 5.6 Rendimiento Básico

- [ ] **Inicio < 3s**: Splash + init en tiempo razonable
- [ ] **Scroll suave**: 60fps en listas (DiaryScreen, HistoryScreen)
- [ ] **Búsqueda < 500ms**: Resultados aparecen rápido post-debounce
- [ ] **Guardado < 1s**: Save de sesión/entrada no bloquea
- [ ] **Sin jank**: Transiciones de página fluidas

---

## 6. TOP 10 PUNTOS DONDE USUARIO SE PIERDE O NO CONFÍA

| # | Situación | Por qué se pierde/desconfía | Fix UX Mínimo |
|---|-----------|---------------------------|---------------|
| 1 | **Timer de descanso desaparece al minimizar** | Vuelve y el timer se reinició, no sabe cuánto descansar | Persistir timer, mostrar tiempo restante al volver |
| 2 | **Swipe elimina peso sin confirmar** | Gesto accidental borra dato importante | Añadir `confirmDismiss` con diálogo |
| 3 | **No sabe si sesión se guardó** | Cerró app, no hay indicador de guardado automático | Añadir badge "guardado" o timestamp último save |
| 4 | **Edita cantidad pero macros "parecen raros"** | Bug de cálculo acumulativo, números no cuadran | Mostrar "X kcal/100g" como referencia |
| 5 | **Busca alimento pero no aparece** | Escribió diferente capitalización o con acento | Normalizar búsqueda, mostrar "también buscamos..." |
| 6 | **Añade entrada pero no ve el total actualizar** | Stream no emitió, o hubo lag | Refresh pull-to-refresh, o indicador loading |
| 7 | **Inicia sesión pero ve ejercicios de sesión anterior** | Sesión activa no terminada, confusión | Mostrar claramente "Continuar sesión del [fecha]?" |
| 8 | **Calendario muestra días sin marcar** | No sabe qué días tiene entries | Puntos o indicadores en días con datos |
| 9 | **Crea rutina pero no sabe cómo empezar** | Flujo de "Entrenar" no es obvio | CTA claro "Empezar con esta rutina" post-crear |
| 10 | **Escanea código pero producto tiene datos raros** | Open Food Facts tiene datos incorrectos/incompletos | Permitir editar antes de guardar, mostrar confianza |

---

## 7. FIXES UX MÍNIMOS (Sin Cambiar Arquitectura)

### 7.1 Copys/Mensajes

```dart
// En weight_screen.dart - Mejorar validación
if (value == null || value < 20 || value > 500) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Ingresa un peso entre 20 y 500 kg'),
      action: SnackBarAction(label: 'OK', onPressed: () {}),
    ),
  );
  return;
}

// En training_session_screen.dart - Indicar auto-save
AppBar(
  title: Text('Sesión activa'),
  actions: [
    Tooltip(
      message: 'Guardado automático',
      child: Icon(Icons.cloud_done, size: 20),
    ),
  ],
)
```

### 7.2 Validaciones

```dart
// En add_entry_dialog.dart - Validar cantidad
void _save() {
  final amount = double.tryParse(_amountController.text);
  if (amount == null || amount <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La cantidad debe ser mayor a 0')),
    );
    return;
  }
  if (amount > 10000) { // Sanity check
    final confirm = await showDialog<bool>(...);
    if (confirm != true) return;
  }
  // ... save
}
```

### 7.3 Confirmaciones

```dart
// En weight_screen.dart - Confirmar antes de eliminar
Dismissible(
  key: Key(w.id),
  direction: DismissDirection.endToStart,
  confirmDismiss: (direction) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar registro?'),
        content: Text('${w.weightKg} kg del ${DateFormat('d MMM').format(w.dateTime)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
  },
  onDismissed: ...
)
```

### 7.4 Disabled States

```dart
// En add_entry_dialog.dart - Deshabilitar guardar si inválido
FilledButton(
  onPressed: _isValid() ? _save : null, // null = disabled
  child: const Text('Guardar'),
)

bool _isValid() {
  final amount = double.tryParse(_amountController.text);
  return amount != null && amount > 0;
}
```

### 7.5 Indicadores Visuales

```dart
// En diary_screen.dart - Marcar días con entries en calendario
TableCalendar(
  ...
  calendarBuilders: CalendarBuilders(
    markerBuilder: (context, day, events) {
      final hasEntries = ref.watch(calendarEntryDaysProvider).value?.contains(
        DateTime(day.year, day.month, day.day)
      ) ?? false;
      if (!hasEntries) return null;
      return Positioned(
        bottom: 1,
        child: Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      );
    },
  ),
)
```

---

## 8. ANEXO: ARCHIVOS CRÍTICOS REVISADOS

| Archivo | Líneas | Rol | Hallazgos |
|---------|--------|-----|-----------|
| `lib/training/providers/training_provider.dart` | ~800 | Estado sesión entrenamiento | BUG-002, SILENT-005-008 |
| `lib/training/repositories/session_repository.dart` | 569 | Persistencia sesiones | BUG-001, BUG-006, SILENT-012, SILENT-014 |
| `lib/training/services/session_persistence_service.dart` | 99 | Debounce save | BUG-001 |
| `lib/diet/providers/summary_providers.dart` | ~300 | Targets y totales | Dependencias complejas |
| `lib/diet/repositories/drift_diet_repositories.dart` | ~400 | CRUD dieta | OK, bien estructurado |
| `lib/features/diary/presentation/diary_screen.dart` | ~600 | UI diario | BUG-004 |
| `lib/features/diary/presentation/edit_entry_dialog.dart` | 233 | Edición entradas | BUG-003, SILENT-001 |
| `lib/features/weight/presentation/weight_screen.dart` | 629 | UI peso | BUG-005, EC-02 |
| `lib/features/diary/presentation/food_search_screen.dart` | 1335 | Búsqueda alimentos | BUG-011 |
| `lib/core/providers/database_provider.dart` | 440 | Providers core | BUG-007, SILENT-009-011 |
| `lib/diet/models/diary_entry_model.dart` | 319 | Modelo entrada | SILENT-002, SILENT-003, SILENT-004 |
| `lib/training/database/database.dart` | 868 | Schema DB | SILENT-015, SILENT-016 |

---

**Fin del informe de auditoría.**

*Este documento debe revisarse y validarse con pruebas manuales en dispositivo real antes de proceder a beta.*
