# PR #4: Entry Point y Navegacion Global

## Descripcion
Experiencia de entrada memorable y navegacion fluida entre modos con transiciones suaves y feedback tactil consistente.

## Cambios Principales

### Splash + Onboarding (Nuevo)
- Splash animado con logo
- Seleccion de objetivo principal
- Configuracion rapida (peso, altura, edad)
- Tour interactivo de 3 pasos

### Transiciones Entre Modos
- Animacion de morphing entre temas claro/oscuro
- Duracion: 400ms
- Curva: easeInOutCubic

### Feedback Tactil Global
| Accion | Haptic |
|--------|--------|
| Boton primario | mediumImpact |
| Check/exitoso | lightImpact |
| Error | heavyImpact |
| Swipe | selectionClick |

### Sistema de Notificaciones
- Toast: 2s (confirmaciones)
- Banner: 5s + undo (acciones importantes)
- Modal: Decisiones criticas

## Nuevos Archivos
- `lib/core/onboarding/`
- `lib/core/navigation/transitions.dart`
- `lib/core/feedback/haptics.dart`

## Testing
- [ ] Usuarios reales en onboarding
- [ ] Tiempo hasta primera accion util
- [ ] Retencion de configuracion

## Screenshots
[Pendiente]

## Breaking Changes
Ninguno
