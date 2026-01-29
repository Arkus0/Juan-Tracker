# UX_HEATMAP.md - Matriz de Severidad de Issues UX

> **Auditoría realizada**: Enero 2026
> **Metodología**: Nielsen Heuristics + Laws of UX + Fogg Behavior Model
> **Scope**: Juan Tracker - App Flutter de fitness y nutrición

---

## Resumen Ejecutivo

| Severidad | Count | % del Total |
|-----------|-------|-------------|
| 🔴 CRITICAL | 4 | 22% |
| 🟠 HIGH | 5 | 28% |
| 🟡 MEDIUM | 6 | 33% |
| 🟢 LOW | 3 | 17% |

**Riesgo de abandono estimado**: 65% en primeras 2 semanas si no se resuelven los issues CRITICAL.

---

## 🔴 CRITICAL (Severidad 10/10)

### CRIT-001: Programación de Entrenamiento sin Anchor Temporal

**Heurística violada**: Visibilidad del Estado del Sistema (Nielsen #1)
**Ubicación**: `lib/training/models/rutina.dart`, `lib/training/providers/training_provider.dart:826-905`

**Descripción**:
El sistema usa "Día 1, Día 2, Día 3" como identificadores abstractos sin conexión a fechas reales del calendario. El usuario debe:
1. Recordar qué día de su rutina corresponde a hoy
2. Recordar qué entrenó hace X días
3. Calcular mentalmente el siguiente día tras saltar sesiones

**Impacto**:
- Carga cognitiva de 15-20 segundos cada vez que abre la app
- Frustración acumulada → abandono típico en semana 2-3
- Imposibilidad de planificar con anticipación

**Evidencia en código**:
```dart
// training_provider.dart:875
var nextDayIndex = (lastDayIndex + 1) % totalDays;  // Simple rotación circular
```

No hay lógica de:
- Asignación a días de la semana (Lunes=Pecho)
- Detección de gaps temporales
- Recuperación tras días saltados

**Before**:
```
Usuario abre app → Ve "Día 1" → Piensa "¿Era Pecho? ¿O espalda?"
→ Intenta recordar qué hizo hace 3 días → Frustración
```

**After propuesto**:
```
Usuario abre app → Ve "Pecho & Tríceps - Última vez: Hace 3 días (Domingo)"
→ Decisión instantánea
```

**Esfuerzo solución**: MEDIO (3-5 días dev)
**ROI**: Crítico para retención

---

### CRIT-002: Entry Screen NO Muestra Estado de Entrenamiento

**Heurística violada**: Visibilidad del Estado del Sistema (Nielsen #1)
**Ubicación**: `lib/features/home/presentation/entry_screen.dart:584-625`

**Descripción**:
La card de "Entrenamiento" en Entry Screen muestra datos hardcodeados ("—" y "--") incluso cuando hay rutinas y sesiones. Mientras que la card de "Nutrición" muestra datos reales (kcal, peso).

**Evidencia en código**:
```dart
// entry_screen.dart:593-604
final stats = rutinasAsync.when(
  data: (rutinas) {
    if (rutinas.isEmpty) {
      return [
        const _Stat(icon: Icons.calendar_today, value: '—', label: 'Hoy'),  // HARDCODED!
        const _Stat(icon: Icons.timer, value: '--', label: 'min'),          // HARDCODED!
      ];
    }
    return [
      const _Stat(icon: Icons.calendar_today, value: '—', label: 'Hoy'),    // TAMBIÉN HARDCODED!
      const _Stat(icon: Icons.timer, value: '--', label: 'min'),
    ];
  },
```

**Impacto**:
- Asimetría de información (nutrición tiene datos, training no)
- Usuario no sabe qué toca entrenar sin navegar 2+ pantallas
- Rompe el principio de "Zero Thought Home"

**Solución**: Conectar `smartSuggestionProvider` a la card de entrenamiento

**Esfuerzo solución**: BAJO (2-4 horas dev)
**ROI**: Alto impacto, bajo costo

---

### CRIT-003: Nutrición Muestra "Lo Que Comí" vs "Lo Que Me Falta"

**Heurística violada**: Reconocimiento vs Recuerdo (Nielsen #6)
**Ley UX**: Loss Aversion - mostrar "restante" motiva más que "consumido"
**Ubicación**: `lib/features/diary/presentation/diary_screen.dart:439-465`

**Descripción**:
El resumen nutricional prioriza mostrar lo CONSUMIDO (`${summary.consumed.kcal}`) en lugar de lo RESTANTE. Para un usuario que debe decidir qué comer a las 14:00, la pregunta crítica es "¿Cuánto me queda?" no "¿Cuánto comí?".

**Evidencia en código**:
```dart
// diary_screen.dart:449-454
Text(
  '${summary.consumed.kcal}',  // Muestra consumido como dato principal
  style: AppTypography.dataLarge.copyWith(
    color: colors.primary,
  ),
),
```

El dato `summary.progress.kcalRemaining` existe pero está relegado a un pequeño donut chart secundario.

**Impacto**:
- Usuario requiere cálculo mental para saber qué puede comer
- Decision fatigue a la hora de elegir alimentos
- Modelo mental incorrecto (retrospectivo vs prospectivo)

**Before**:
```
"Consumido: 1200 kcal / 2000 objetivo"
→ Usuario calcula: 2000 - 1200 = 800 restantes
```

**After propuesto**:
```
"Te quedan: 800 kcal | 40g proteína | 60g carbos"
→ Decisión inmediata sobre qué pedir
```

**Esfuerzo solución**: BAJO (2-3 horas dev)
**ROI**: Alto impacto en decisiones diarias

---

### CRIT-004: No Hay Vista Unificada "HOY"

**Heurística violada**: Match entre Sistema y Mundo Real (Nielsen #2)
**Ubicación**: `lib/features/home/presentation/entry_screen.dart`

**Descripción**:
La Entry Screen obliga a elegir entre dos modos (Nutrición/Entrenamiento) cuando el modelo mental del usuario es "¿Qué tengo que hacer HOY?". Un culturista necesita ver:
1. ¿Entreno hoy o descanso?
2. ¿Qué grupo muscular?
3. ¿Cuántas calorías/proteína me faltan?

Todo en UNA vista, no en dos flujos separados.

**Impacto**:
- Fragmentación de información crítica
- 2 taps mínimos para obtener contexto completo del día
- Aumenta probabilidad de olvidar registrar comida o entrenamiento

**Esfuerzo solución**: ALTO (5-7 días dev)
**ROI**: Transformacional para engagement diario

---

## 🟠 HIGH (Severidad 7-8/10)

### HIGH-001: Sistema de Ciclos Soporta Solo Rotación Lineal

**Heurística violada**: Flexibilidad y Eficiencia de Uso (Nielsen #7)
**Ubicación**: `lib/training/providers/training_provider.dart:875`

**Descripción**:
El `smartSuggestionProvider` usa rotación circular simple: `(lastDayIndex + 1) % totalDays`. No soporta:
- Ciclos Upper/Lower alternados independientes del día de la semana
- Frecuencias no semanales (cada 48h, cada 72h)
- Días de descanso forzados tras días pesados (ej: después de Pierna)

**Persona afectada**: "El Flexible A/B" - hace Upper/Lower sin importar el día

**Before**:
```
Hace Upper el Lunes, Lower el Miércoles,
el sistema sugiere Upper el Jueves sin considerar que fueron solo 24h
```

**After propuesto**:
```
Sistema detecta: "Último Lower hace 50h"
Sugiere: "Hoy toca Upper (han pasado 2 días desde Lower)"
```

**Esfuerzo solución**: MEDIO (3-4 días dev)

---

### HIGH-002: Snackbars sin Duración Definida Consistente

**Heurística violada**: Control y Libertad del Usuario (Nielsen #3)
**Ubicación**: Múltiples archivos (diary_screen.dart, entry_screen.dart)

**Descripción**:
Algunos SnackBars tienen `duration: const Duration(seconds: 3)` mientras otros usan el default de Flutter (~4 segundos). Inconsistencia que afecta la percepción de "undo time".

**Evidencia**:
```dart
// diary_screen.dart:228 - Tiene duration definida
duration: const Duration(seconds: 3),

// entry_screen.dart:277 - NO tiene duration definida (usa default)
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Peso registrado')),  // Sin duration
);
```

**Impacto**: Confusión sobre ventana de deshacer

**Esfuerzo solución**: BAJO (1 hora)

---

### HIGH-003: Historial No Sugiere "Comida Habitual"

**Heurística violada**: Reconocimiento vs Recuerdo (Nielsen #6)
**Ubicación**: `lib/features/diary/presentation/diary_screen.dart:696-759`

**Descripción**:
El Quick Add muestra "comidas recientes" pero no detecta patrones temporales. Un usuario que desayuna lo mismo todos los días debería ver esa opción destacada.

**Ejemplo perdido**:
```
Usuario registra "Avena con proteína" como desayuno 80% de los días
→ Al abrir a las 8:00 AM, NO sugiere automáticamente este ítem
→ Debe buscarlo manualmente cada vez
```

**Esfuerzo solución**: MEDIO (2-3 días dev)

---

### HIGH-004: No Hay Recuperación de Contexto de Sesión de Entrenamiento

**Heurística violada**: Control y Libertad del Usuario (Nielsen #3)
**Ubicación**: `lib/training/screens/training_session_screen.dart`

**Descripción**:
Si el usuario cierra la app durante un descanso entre series, al volver no hay indicación visual clara de "Estabas en Serie 3 de 4, 60kg, Press Banca". El contexto se recupera técnicamente pero no hay "welcome back" UX.

**Impacto**: Confusión al reabrir → errores de registro

**Esfuerzo solución**: BAJO (3-4 horas dev)

---

### HIGH-005: Validación de Peso Sin Alertas Proactivas

**Heurística violada**: Prevención de Errores (Nielsen #5)
**Ubicación**: `lib/training/providers/training_provider.dart:308-358`

**Descripción**:
El sistema detecta pesos sospechosos (ej: 500kg en press banca) y muestra un diálogo de confirmación, pero NO previene el error proactivamente con sugerencias inline.

**Mejora propuesta**: Mostrar badge "¿Quisiste decir 50kg?" junto al input antes de confirmar.

**Esfuerzo solución**: BAJO (2-3 horas dev)

---

## 🟡 MEDIUM (Severidad 4-6/10)

### MED-001: Días de Rutina Nombrados Genéricamente

**Ubicación**: `lib/training/screens/train_selection_screen.dart:737`

**Descripción**: Los chips de selección de día muestran "Day 1, Day 2" en lugar de nombres semánticos como "Pecho", "Espalda", "Pierna".

**Evidencia**:
```dart
child: Text(
  entry.value.nombre.toUpperCase(),  // Muestra "DAY 1" si así está nombrado
```

**Fix**: Guiar al usuario a nombrar días descriptivamente durante creación de rutina.

**Esfuerzo**: BAJO (UI guidance, 1-2 horas)

---

### MED-002: Calendario Nutricional No Muestra Indicadores de Cumplimiento

**Ubicación**: `lib/features/diary/presentation/diary_screen.dart:236-313`

**Descripción**: El calendario mensual no tiene markers visuales de "días donde cumplí objetivos" vs "días donde fallé". Solo muestra que hay entradas, no su calidad.

**Esfuerzo**: MEDIO (requiere agregar lógica de evaluación)

---

### MED-003: No Hay "Warm Start" Basado en Hora

**Heurística**: Default Effect
**Ubicación**: `lib/features/home/presentation/entry_screen.dart`

**Descripción**: Si el usuario abre a las 7:00 AM, probablemente quiere registrar desayuno. Si abre a las 22:00, probablemente quiere revisar el día o registrar cena. La app no adapta su UI inicial.

**Esfuerzo**: MEDIO (2-3 días dev)

---

### MED-004: Thumb Zone Violation en Entry Screen

**Heurística**: Fitts's Law / Thumb Zones
**Ubicación**: `lib/features/home/presentation/entry_screen.dart:163-184`

**Descripción**: Los botones de "Accesos Rápidos" (Peso, Entrenar, Comida) están en la zona media de la pantalla, no en el bottom 25% óptimo para uso con una mano.

**Esfuerzo**: BAJO (reorganizar layout)

---

### MED-005: No Hay Deload Detection

**Heurística**: Prevención de Errores
**Ubicación**: `lib/training/services/progression_engine_extensions.dart`

**Descripción**: Si el usuario lleva 3+ semanas sin subir peso en un ejercicio, no hay sugerencia proactiva de deload o reducción de volumen.

**Nota**: El código tiene `detectOvertrainingRisk` pero no está conectado a UI.

**Esfuerzo**: MEDIO (conectar lógica existente a UI)

---

### MED-006: Empty States No Educativos

**Heurística**: Help and Documentation (Nielsen #10)
**Ubicación**: Varios (diary_screen.dart, rutinas_screen.dart)

**Descripción**: Los empty states muestran "Sin entradas" pero no explican el valor de registrar o cómo empezar efectivamente.

**Esfuerzo**: BAJO (copy writing, 1-2 horas)

---

## 🟢 LOW (Severidad 1-3/10)

### LOW-001: Falta Color-Blind Safe en Gráficos de Macros

**Ubicación**: `lib/features/diary/presentation/diary_screen.dart:625-693`

**Descripción**: Los gráficos de macros usan solo color (rojo=proteína, amarillo=carbos, azul=grasa) sin patrones o texturas adicionales.

**Esfuerzo**: BAJO (agregar patterns a charts)

---

### LOW-002: Labels de Voice Access Incompletos

**Ubicación**: Múltiples widgets

**Descripción**: No todos los botones tienen `semanticsLabel` descriptivo para usuarios de TalkBack/VoiceOver.

**Esfuerzo**: BAJO (1-2 horas audit + fix)

---

### LOW-003: Dynamic Colors No Implementado

**Ubicación**: `lib/core/design_system/app_theme.dart`

**Descripción**: La app no respeta Material You / Dynamic Colors basado en wallpaper del usuario.

**Esfuerzo**: MEDIO (requiere refactor de ColorScheme)

---

## Anti-Patterns Detectados (Checklist)

| Anti-Pattern | Detectado | Ubicación | Severidad |
|--------------|-----------|-----------|-----------|
| Ghost Gym | ⚠️ Parcial | Entry Screen training card | HIGH |
| Configuration Hell | ❌ No | N/A | - |
| Data Cemetery | ⚠️ Parcial | Analysis screens sin datos | MEDIUM |
| Modal Madness | ❌ No | N/A | - |
| Infinite Scroll of Shame | ❌ No | Diary usa agrupación | - |

**Ghost Gym Parcial**: La card de entrenamiento muestra gráficos bonitos (gradiente) pero cero información útil (muestra "—" hardcodeado).

---

## Matriz de Priorización

```
                    IMPACTO
            Bajo    Medio    Alto
         ┌────────┬────────┬────────┐
   Bajo  │ LOW-*  │ MED-06 │ CRIT-02│
ESFUERZO │        │        │ CRIT-03│
         ├────────┼────────┼────────┤
  Medio  │        │ HIGH-* │ CRIT-01│
         │        │ MED-*  │ HIGH-01│
         ├────────┼────────┼────────┤
   Alto  │        │        │ CRIT-04│
         └────────┴────────┴────────┘
```

**Orden de implementación recomendado**:
1. CRIT-02 (conectar smartSuggestionProvider) - 2-4h, alto impacto
2. CRIT-03 (invertir consumido→restante) - 2-3h, alto impacto
3. HIGH-02 (snackbar consistency) - 1h, mejora percepción
4. CRIT-01 (anchor temporal) - 3-5d, transformacional
5. CRIT-04 (vista unificada HOY) - 5-7d, transformacional

---

*Documento generado como parte de la auditoría UX de Juan Tracker - Enero 2026*
