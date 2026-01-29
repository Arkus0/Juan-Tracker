# PR #3: Rediseño Seccion Entrenamiento

## Descripcion
Optimizacion de la experiencia de entrenamiento para uso en gimnasio: alta legibilidad, operabilidad con una mano, feedback inmediato.

## Cambios Principales

### MainScreen Mejorada
- Header con rutina del dia sugerida
- Calendario semanal de entrenamientos
- Acceso rapido a ultima sesion
- Stats de volumen semanal

### RutinasScreen Modernizada
- Grid de rutinas con preview visual
- Folders/colecciones
- Busqueda con filtros
- Tags de rutina

### TrainingSessionScreen Optimizada
- **Modo Focus**: Una serie dominante, input grande
- **Modo Lista**: Scroll con series como checkboxes
- Timer siempre visible (color teal)
- Feedback haptic en cada accion

### AnalysisScreen
- Dashboard de volumen
- Grafico de fuerza por ejercicio
- Heatmap de frecuencia muscular

## Nuevos Componentes
- `SetInputCard` - Input grande de peso/reps/RPE
- `RestTimerOverlay` - Timer pantalla completa
- `ExerciseProgress` - Barra de progreso
- `SessionStats` - Stats en tiempo real

## Testing
- [ ] Uso con manos sudadas
- [ ] Legibilidad en gimnasio (luz variable)
- [ ] Test de bateria (pantalla siempre encendida)

## Screenshots
[Pendiente]

## Breaking Changes
Ninguno - mejoras visuales manteniendo estructura actual
