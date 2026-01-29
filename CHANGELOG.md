# Changelog

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased] - 2026-01-29

### Added - Fase A: UX/UI Improvements
- **UX-001**: Onboarding con opción de skip
  - Indicadores visuales de progreso
  - Botón "Saltar" accesible
- **UX-002**: Quick Add optimizado con accesos directos inteligentes
- **UX-003**: Timer de descanso accesible
  - Touch targets mínimos de 64dp
  - Gestos de swipe para acciones rápidas
  - Feedback háptico en acciones
- **UX-004**: Celebraciones al completar series
  - Animación de confetti para PRs
  - Scale animation en checkbox de completado
  - `CelebrationController` singleton
- **UX-005**: Edge-to-edge rendering para Android 15+
  - `SystemUiMode.edgeToEdge`
  - Navigation bar transparente
- **UX-006**: TalkBack labels en todas las acciones críticas

### Added - Fase B: GoRouter Navigation
- Implementación de `go_router` v14.8.1 para navegación declarativa
- Configuración de deep links:
  - Esquema personalizado: `juantracker://`
  - HTTPS: `https://juantracker.app`
- 17 rutas configuradas cubriendo nutrición y entrenamiento
- Extensiones de navegación: `context.goToDiary()`, `context.goToTraining()`, etc.
- Página de error 404 personalizada

### Added - Fase C: Performance Optimizations
- **PC-001**: Debounce de 300ms en búsqueda de alimentos
  - Reduce queries a base de datos
  - Mejora responsividad del input
- **PC-002**: RepaintBoundary en gráficos de fuerza
  - Aisla repaints del árbol de widgets
  - Mejora rendimiento en scroll

### Added - Tests de Integración
- 17 nuevos tests para features recientes:
  - `rest_timer_bar_test.dart` - Tests de timer UX-003
  - `celebration_overlay_test.dart` - Tests de celebraciones UX-004
  - `meal_totals_provider_test.dart` - Tests de providers MD-002
  - `weight_trend_isolate_test.dart` - Tests de isolates MA-003
- 12 nuevos tests para GoRouter (Fase B+):
  - `app_router_test.dart` - Tests de integración para rutas y deep links
- Todos los tests pasando (201 total)

### Added - Fase B+: GoRouter Migration & Transitions
- Migración completa de `Navigator.push` a `context.go()` / `context.push()`
- Pantallas migradas:
  - `entry_screen.dart` - Navegación a nutrición/entrenamiento
  - `coach_screen.dart` - Navegación a setup y check-in
  - `diary_screen.dart` - Navegación a búsqueda de alimentos
  - `summary_screen.dart` - Navegación a targets
- Transiciones personalizadas con `CustomTransitionPage`:
  - Fade transition (400ms) entre EntryScreen y modos
- Extensiones de navegación ampliadas:
  - `pushTo()` - Navegación manteniendo stack
  - `goBack()` - Volver atrás
  - `goToFoods()`, `goToWeight()`, `goToCoachSetup()`, etc.

### Fixed
- Test `widget_test.dart` arreglado (timer pendiente del SplashWrapper)
- Warnings de analyzer: unused imports
- Exports limpios en barrel files

### Changed
- Actualizado `app.dart` para usar `MaterialApp.router`
- Mejorado manejo de imports con prefijos (`as diet`) para evitar conflictos
- Optimizados comentarios de documentación en tests

### Fixed
- Warnings de analyzer: unused elements, unnecessary underscores, dangling doc comments
- Import conflict: `MealType` ambiguo entre core y diet models

---

## [1.0.0] - 2026-01-15

### Added
- Release inicial con features completos de nutrición y entrenamiento
- Base de datos Drift con schema v5
- Coach Adaptativo (MacroFactor-style)
- Integración Open Food Facts + OCR
- Sistema de rutinas y sesiones de entrenamiento
- Timer de descanso con foreground service nativo
- Análisis de tendencias multi-modelo (EMA, Kalman, Holt-Winters)

---

## Notas de Versión

### Convenciones de Commit
- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `perf`: Mejora de performance
- `refactor`: Refactorización de código
- `test`: Tests
- `docs`: Documentación
- `style`: Cambios de estilo (formato, etc)

### Tags de Issues
- `UX-XXX`: UX/UI improvements
- `MD-XXX`: Memoization/Data optimizations
- `MA-XXX`: Memory/Architecture
- `PC-XXX`: Performance

---

*Este changelog documenta los cambios desde Enero 2026.*
