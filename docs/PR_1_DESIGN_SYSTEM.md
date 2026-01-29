# PR #1: Unificacion de Design System

## Descripcion
Este PR establece la base del sistema de diseno unificado para Juan Tracker. Incluye tokens de diseno, componentes base y temas coherentes para las secciones de Nutricion y Entrenamiento.

## Cambios Principales

### Nuevos Archivos
- `lib/core/design_system/app_theme.dart` - Tokens y builders de tema
- `lib/core/design_system/app_animations.dart` - Animaciones reutilizables  
- `lib/core/widgets/app_card.dart` - Componente Card base

### Modificaciones
- `lib/app.dart` - Integracion de nuevos temas (pendiente)
- `lib/training/utils/design_system.dart` - Deprecacion gradual (pendiente)

## Caracteristicas del Nuevo Sistema

### Paleta Unificada
- **Primario**: Terracota `#DA5A2A` (consistente en ambos modos)
- **Semantico**: Success, Warning, Error estandarizados
- **Neutros**: Escalas claras y oscuras definidas

### Temas
1. **Nutricion (Claro)**: Fondo `#F5F3EE`, superficies blancas
2. **Entrenamiento (Oscuro)**: Fondo `#0E0F12`, superficies gris oscuro

### Componentes Base
- `AppCard` - Contenedor flexible con estados
- `AppStatCard` - Para estadisticas numericas
- `FadeInAnimation` - Animacion de entrada
- `ScaleAnimation` - Feedback tactil

## Testing
- [ ] Verificar contraste WCAG 2.1 AA
- [ ] Validar en modo claro y oscuro
- [ ] Probar componentes en diferentes tamanos de pantalla

## Screenshots
[Pendiente - adjuntar antes del merge]

## Breaking Changes
Ninguno - este PR solo agrega nuevos archivos. La migracion sera gradual en PRs posteriores.
