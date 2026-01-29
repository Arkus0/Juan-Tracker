# Plan de Mejora UX/UI - Juan Tracker

> Documento maestro para la refactorización visual de la aplicación.  
> **Fecha**: Enero 2026  
> **Autor**: Experto UX/UI Flutter  

---

## 🎯 Resumen Ejecutivo

La aplicación Juan Tracker tiene dos secciones principales (**Nutrición** y **Entrenamiento**) con diseños visuales inconsistentes entre sí. Este plan establece una unificación progresiva del design system, manteniendo la identidad de marca mientras mejoramos la experiencia de usuario.

### Problemas Identificados

| Problema | Impacto | Prioridad |
|----------|---------|-----------|
| Inconsistencia temática (claro vs oscuro) | Confusión de marca | Alta |
| EntryScreen básica sin valor emocional | Primera impresión débil | Alta |
| Information overload en WeightScreen | Cognitive load alto | Media |
| Falta de feedback visual en acciones clave | Usabilidad reducida | Media |
| Transiciones abruptas entre secciones | Percepción de calidad | Baja |

---

## 📋 Estructura de Pull Requests

```
PR #1: Unificación de Design System (Foundation)
├── Tema unificado "Adaptive Iron"
├── Tokens de diseño centralizados
├── Animaciones consistentes
└── Componentes base reutilizables

PR #2: Rediseño Sección Nutrición
├── DiaryScreen refactorizada
├── WeightScreen simplificada
├── FoodSearch mejorada
└── Micro-interacciones

PR #3: Rediseño Sección Entrenamiento  
├── MainScreen mejorada
├── RutinasScreen modernizada
├── SessionScreen optimizada
└── Análisis y gráficos

PR #4: Entry Point y Navegación Global
├── EntryScreen rediseñada
├── Transiciones entre modos
├── Onboarding mejorado
└── Feedback táctil global
```

---

## 🔧 PR #1: Unificación de Design System

### Objetivo
Crear un design system coherente que sirva de base para ambas secciones, permitiendo personalización por modo (Nutrición clara, Entrenamiento oscura) pero manteniendo consistencia estructural.

### Cambios Propuestos

#### 1.1 Nuevo Archivo: `lib/core/design_system/app_theme.dart`

```dart
/// Tema unificado con variantes por modo
/// 
/// - Modo Nutrición: Tema claro con acentos cálidos (naranja/dorado)
/// - Modo Entrenamiento: Tema oscuro "Iron" con acentos rojos

abstract class AppTheme {
  static ThemeData get nutritionTheme => _buildNutritionTheme();
  static ThemeData get trainingTheme => _buildTrainingTheme();
}
```

**Características:**
- Color primario unificado: `#DA5A2A` (terracota/naranja quemado)
- Esquema de semántica consistente (success, warning, error)
- Radios de borde estandarizados (12px base)
- Elevaciones definidas (0-4 niveles)
- Animaciones consistentes (200ms ease-in-out base)

#### 1.2 Nuevo Archivo: `lib/core/design_system/app_animations.dart`

```dart
/// Curvas y duraciones estandarizadas
abstract class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve spring = Curves.elasticOut;
}
```

#### 1.3 Componentes Base

Nuevos widgets reutilizables:

| Componente | Props | Uso |
|------------|-------|-----|
| `AppCard` | elevation, padding, child | Contenedores universales |
| `AppButton` | variant, size, onPressed | CTAs y acciones |
| `AppInput` | type, validator, hint | Formularios |
| `AppBadge` | color, label | Estados y etiquetas |
| `AppProgress` | value, type | Progreso visual |
| `AppSkeleton` | width, height | Estados de carga |

### Archivos Modificados
- `lib/app.dart` - Integración de nuevos temas
- `lib/training/utils/design_system.dart` - Refactor a nuevo sistema
- Todos los screens - Migración gradual a componentes base

### Testing
- [ ] Verificar contraste WCAG 2.1 AA en ambos temas
- [ ] Validar consistencia de tipografía
- [ ] Probar animaciones en dispositivos low-end

---

## 🥗 PR #2: Rediseño Sección Nutrición

### Objetivo
Modernizar la experiencia de tracking nutricional con mejor jerarquía visual, reducción de carga cognitiva y micro-interacciones satisfactorias.

### 2.1 EntryScreen Rediseñada

**Problema actual:** Pantalla estática sin personalidad

**Solución:** 
- Hero animation con logo animado
- Cards de modo con preview visual del contenido
- Personalización según hora del día (saludo dinámico)
- Accesos directos a últimas acciones

```dart
class EntryScreen extends StatelessWidget {
  // Nueva estructura:
  // 1. Header con saludo personalizado + fecha
  // 2. Grid de modos con preview de datos
  // 3. Accesos rápidos (última sesión, próxima rutina)
  // 4. Indicador de streak/constancia
}
```

**Mockup estructura:**
```
┌─────────────────────────────────┐
│  ¡Buenos días, Juan! 🌅        │
│  Miércoles, 29 de Enero         │
├─────────────────────────────────┤
│  ┌─────────────┐ ┌────────────┐ │
│  │   🍽️        │ │   💪       │ │
│  │  DIETA      │ │ENTRENAMIENTO│
│  │  1,850 kcal │ │ Push Day   │ │
│  │  ↓ 200g     │ │ Hoy 18:00  │ │
│  └─────────────┘ └────────────┘ │
├─────────────────────────────────┤
│  ⚡ Accesos Rápidos             │
│  • Registrar peso               │
│  • Iniciar rutina               │
│  • Añadir comida                │
├─────────────────────────────────┤
│  🔥 Racha: 12 días              │
└─────────────────────────────────┘
```

### 2.2 DiaryScreen Mejorada

**Problemas actuales:**
- Información densa en espacio reducido
- Falta de feedback al añadir/editar
- Selector de fecha poco intuitivo

**Mejoras:**

#### Timeline Vertical Mejorada
```dart
class DiaryScreen extends ConsumerWidget {
  // Nueva estructura:
  // 1. Calendario semanal horizontal (swiper)
  // 2. Resumen circular de macros (gráfico donut)
  // 3. Timeline vertical por comidas
  // 4. FAB expandible para añadir
}
```

**Componentes nuevos:**

| Componente | Descripción |
|------------|-------------|
| `WeeklyCalendar` | Selector semanal con swipe horizontal |
| `MacroDonut` | Gráfico circular de macros vs objetivos |
| `MealTimeline` | Lista tipo timeline con horarios |
| `QuickAddSheet` | Bottom sheet para añadir rápido |

#### Micro-interacciones
- **Añadir entrada:** Scale + fade in desde FAB
- **Completar macro:** Confetti sutil en el donut
- **Swipe delete:** Icono + undo con haptic
- **Pull refresh:** Animación de calendario girando

### 2.3 WeightScreen Simplificada

**Problema actual:** Demasiada densidad de información técnica visible de inmediato

**Solución - Niveles de profundidad:**

```
NIVEL 1 (Dashboard):
┌─────────────────────────────────┐
│  📊 PESO                        │
│  ┌────────┐ ┌────────┐ ┌──────┐ │
│  │  78.5  │ │  77.9  │ │ -0.6 │ │
│  │  ACTUAL│ │  TREND │ │ Δ7D  │ │
│  └────────┘ └────────┘ └──────┘ │
│  [====GRÁFICO SIMPLIFICADO====] │
└─────────────────────────────────┘

NIVEL 2 (Detalle - tap en stats):
┌─────────────────────────────────┐
│  • EMA: 77.8 kg                 │
│  • Kalman: 77.9 kg              │
│  • Tendencia: Perdiendo         │
└─────────────────────────────────┘

NIVEL 3 (Técnico - botón info):
┌─────────────────────────────────┐
│  Holt-Winters, Regresión, etc   │
└─────────────────────────────────┘
```

**Nuevos componentes:**
- `WeightHeroCard` - Stats principales grandes
- `MiniTrendChart` - Gráfico simplificado sin ejes
- `PhaseBadge` - Indicador visual de fase (↓, →, ↑)
- `PredictionCard` - Proyección con confianza

### 2.4 FoodSearchScreen Mejorada

**Mejoras:**
- Búsqueda con categorías visuales (iconos grandes)
- Historial reciente con imágenes placeholder
- Scanner de código de barras integrado
- OCR de etiquetas con preview en tiempo real

### Testing
- [ ] Verificar accesibilidad con VoiceOver/TalkBack
- [ ] Validar legibilidad en exteriores (brillo alto)
- [ ] Probar flujo completo de añadir comida

---

## 💪 PR #3: Rediseño Sección Entrenamiento

### Objetivo
Optimizar la experiencia de entrenamiento para uso en gimnasio: alta legibilidad, operabilidad con una mano, feedback inmediato.

### 3.1 MainScreen Mejorada

**Cambios:**
- Header con rutina del día sugerida
- Calendario semanal de entrenamientos
- Acceso rápido a última sesión
- Stats de volumen semanal

```dart
class MainScreen extends ConsumerWidget {
  // Nueva estructura:
  // 1. Header con nombre de app + settings
  // 2. Rutina sugerida del día (card grande)
  // 3. Calendario semanal de splits
  // 4. Grid de navegación:
  //    - Rutinas | Entrenar | Análisis | Ajustes
  // 5. Bottom bar con sesión activa (si existe)
}
```

### 3.2 RutinasScreen Modernizada

**Mejoras:**
- Grid de rutinas con preview visual
- Folders/colecciones de rutinas
- Búsqueda con filtros (frecuencia, split, etc)
- Tags de rutina (fuerza, hipertrofia, etc)

**Nuevo layout:**
```
┌─────────────────────────────────┐
│  MIS RUTINAS          [+] [🔍]  │
├─────────────────────────────────┤
│  [Fuerza] [Hipertrofia] [Todas] │ ← Filtros chips
├─────────────────────────────────┤
│  ┌─────────────────────────┐    │
│  │ 🏋️ PUSH PULL LEGS       │    │
│  │ ┌─────┐ ┌─────┐ ┌─────┐ │    │
│  │ │Push │ │Pull │ │Legs │ │    │
│  │ └─────┘ └─────┘ └─────┘ │    │
│  │ 6 días • 18 ejercicios  │    │
│  └─────────────────────────┘    │
│  ┌─────────────────────────┐    │
│  │ 🎯 FULL BODY            │    │
│  │ ...                     │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

### 3.3 TrainingSessionScreen Optimizada

**Problemas actuales:**
- Densidad de información alta durante ejercicio
- Timer poco prominente
- Falta de feedback de progreso

**Soluciones:**

#### Modo Focus (por defecto)
```
┌─────────────────────────────────┐
│ Press Banca          [⏱️ 0:45]  │
├─────────────────────────────────┤
│                                 │
│     ┌─────────────────────┐     │
│     │   80 KG  x  8 reps  │     │ ← FOCO
│     │   [    RPE 8.5    ] │     │
│     └─────────────────────┘     │
│                                 │
│  Serie 3 de 4                   │
│  ████░░░░ 75% completado       │
│                                 │
├─────────────────────────────────┤
│ [⏱️] [✓] [+] [-] [⚙️]          │
└─────────────────────────────────┘
```

#### Modo Lista (scroll)
- Lista compacta de ejercicios
- Series como checkboxes
- Swipe para opciones

#### Mejoras de Interacción
- **Timer:** Siempre visible, color teal brillante
- **Check serie:** Haptic + animación de check
- **Completar ejercicio:** Confetti + vibración de éxito
- **Descanso:** Pantalla negra con timer gigante (opcional)

#### Nuevos Componentes
| Componente | Función |
|------------|---------|
| `SetInputCard` | Input de peso/reps/RPE grande |
| `RestTimerOverlay` | Timer pantalla completa |
| `ExerciseProgress` | Barra de progreso por ejercicio |
| `SessionStats` | Volumen, tiempo, PRs en tiempo real |

### 3.4 AnalysisScreen Mejorada

**Mejoras:**
- Dashboard de volumen semanal/mensual
- Gráfico de fuerza por ejercicio
- Heatmap de frecuencia muscular
- Comparativa períodos

### Testing
- [ ] Usar con manos sudadas (touch targets)
- [ ] Probar en gimnasio con luz variable
- [ ] Validar legibilidad desde distancia
- [ ] Test de batería (pantalla siempre encendida)

---

## 🚪 PR #4: Entry Point y Navegación Global

### Objetivo
Crear una experiencia de entrada memorable y navegación fluida entre modos.

### 4.1 Splash + Onboarding

**Nuevo flujo de primera vez:**
```
1. Splash animado (logo Juan Tracker)
2. Bienvenida + selección de objetivo principal
3. Configuración rápida (peso, altura, edad)
4. Tour interactivo de 3 pasos:
   - "Este es tu diario"
   - "Aquí entrenas"  
   - "El coach te guía"
5. ¡Listo para empezar!
```

### 4.2 Transiciones Entre Modos

**Actual:** Cambio brusco entre temas claro/oscuro

**Nuevo:**
```dart
// Transición suave con morphing
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 400),
  pageBuilder: (context, animation, secondaryAnimation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Morphing entre colores de tema
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(_buildColorMatrix(animation.value)),
          child: child,
        );
      },
      child: destinationScreen,
    );
  },
);
```

### 4.3 Feedback Táctil Global

Implementar haptics consistentes:

| Acción | Haptic |
|--------|--------|
| Botón primario | `mediumImpact` |
| Check/éxito | `lightImpact` + vibración corta |
| Error | `heavyImpact` |
| Swipe | `selectionClick` |
| Long press | `heavyImpact` |

### 4.4 Notificaciones y Toasts

Sistema de feedback no intrusivo:
- **Toast:** Confirmaciones rápidas (2s)
- **Banner:** Acciones importantes (5s + undo)
- **Modal:** Decisiones críticas

### Testing
- [ ] Validar onboarding en usuarios reales
- [ ] Medir tiempo hasta primera acción útil
- [ ] Test de retención de configuración

---

## 📊 Métricas de Éxito

### Cuantitativas
| Métrica | Baseline | Target |
|---------|----------|--------|
| Tiempo para añadir comida | 15s | < 10s |
| Tiempo para iniciar sesión | 8s | < 5s |
| Tasa de completado de sesiones | 70% | > 85% |
| Uso diario activo | 40% | > 55% |

### Cualitativas
- SUS Score (System Usability Scale): > 75
- NPS (Net Promoter Score): > 40
- App Store rating: > 4.5★

---

## 🛠️ Plan de Implementación

### Fase 1: Foundation (PR #1)
**Duración:** 1 semana
**Recursos:** 1 developer senior

1. Crear `app_theme.dart` con ambas variantes
2. Crear `app_animations.dart`
3. Implementar componentes base
4. Tests visuales automatizados

### Fase 2: Nutrición (PR #2)
**Duración:** 1.5 semanas
**Recursos:** 1 developer senior + 1 junior

1. Rediseñar EntryScreen
2. Refactorizar DiaryScreen
3. Simplificar WeightScreen
4. Mejorar FoodSearch
5. QA y ajustes

### Fase 3: Entrenamiento (PR #3)
**Duración:** 1.5 semanas
**Recursos:** 1 developer senior

1. Optimizar SessionScreen
2. Rediseñar RutinasScreen
3. Mejorar AnalysisScreen
4. Testing en gimnasio real

### Fase 4: Navegación (PR #4)
**Duración:** 1 semana
**Recursos:** 1 developer junior

1. Implementar onboarding
2. Añadir transiciones
3. Configurar haptics globales
4. Sistema de feedback

---

## 📝 Notas de Implementación

### Compatibilidad
- Mantener soporte Android 8.0+
- No romper navegación existente
- Feature flags para cambios grandes

### Performance
- Evitar rebuilds innecesarios
- Usar `RepaintBoundary` en animaciones
- Precargar recursos pesados

### Accesibilidad
- WCAG 2.1 AA como mínimo
- Soporte para font scaling
- TalkBack/VoiceOver optimizado
- Reducir motion si `prefers-reduced-motion`

---

## ✅ Checklist Final

Antes de mergear cada PR:

- [ ] Código revisado (code review)
- [ ] Tests pasando
- [ ] Flutter analyze sin warnings
- [ ] Test en múltiples dispositivos
- [ ] Validación de accesibilidad
- [ ] Screenshots para changelog
- [ ] Documentación actualizada

---

*Última actualización: Enero 2026*  
*Próxima revisión: Post-implementación PR #1*
