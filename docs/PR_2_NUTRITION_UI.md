# PR #2: Rediseño Seccion Nutricion

## Descripcion
Modernizacion completa de la experiencia de tracking nutricional con mejor jerarquia visual, reduccion de carga cognitiva y micro-interacciones satisfactorias.

## Cambios Principales

### EntryScreen Redisenada
- Hero animation con logo animado
- Cards de modo con preview de datos
- Saludo dinamico segun hora
- Accesos rapidos a ultimas acciones

### DiaryScreen Mejorada  
- Calendario semanal horizontal (swiper)
- Resumen circular de macros (donut chart)
- Timeline vertical por comidas
- FAB expandible

### WeightScreen Simplificada
- Niveles de profundidad: Dashboard -> Detalle -> Tecnico
- `WeightHeroCard` con stats grandes
- `MiniTrendChart` simplificado
- `PhaseBadge` visual

### FoodSearchScreen
- Categorias visuales con iconos
- Historial reciente
- Scanner de codigo de barras integrado

## Nuevos Componentes
- `WeeklyCalendar` - Selector semanal
- `MacroDonut` - Grafico circular de macros
- `MealTimeline` - Lista tipo timeline
- `QuickAddSheet` - Bottom sheet rapido

## Testing
- [ ] Flujo completo de añadir comida < 10s
- [ ] Legibilidad en exteriores (brillo alto)
- [ ] VoiceOver/TalkBack

## Screenshots
[Pendiente]

## Breaking Changes
- Navegacion de WeightScreen modificada (niveles de profundidad)
