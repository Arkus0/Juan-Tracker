# Deuda Técnica de UI/UX - Juan Tracker

> Documento de seguimiento de deuda técnica post-PR1/PR2/PR3  
> Última actualización: Febrero 2026

---

## Resumen

Durante el esfuerzo de alineación visual (PR1-PR3), se migraron los componentes críticos al design system unificado. Este documento rastrea lo que queda por hacer.

### Estado General

| Categoría | Completado | Pendiente | Prioridad |
|-----------|------------|-----------|-----------|
| Core Design System | ✅ 100% | 0 | - |
| Core Widgets | ✅ 100% | 0 | - |
| Training - Session Widgets | ✅ 90% | ~5 archivos | Baja |
| Training - Screens | ⏳ 30% | ~15 archivos | Media |
| Training - Voice Widgets | ⏳ 10% | ~10 archivos | Baja |
| Training - Utils | ⏳ 50% | 1 archivo | Baja |

---

## Deuda Detallada

### 1. `training/utils/design_system.dart` 

**Estado:** ⚠️ Legacy - Coexiste con core design system

**Issues:**
- Define su propio `AppTypography` con `GoogleFonts.montserrat()` (líneas 430-606)
- Define su propio `AppColors` (dark theme) que conflictúa con el core
- Tema Material 3 con configuraciones específicas de Training

**Decisión:** Mantener por compatibilidad. Nuevos features deben usar el core design system.

**Migración futura:**
```dart
// Legacy (mantener funcionando)
import '../../utils/design_system.dart' show AppColors;

// Nuevo (usar en código nuevo)
import '../../../core/design_system/design_system.dart' show AppTypography;
```

---

### 2. Archivos con GoogleFonts Directo

Los siguientes archivos usan `GoogleFonts.montserrat()` directamente en lugar de `AppTypography`:

#### High Priority (usados frecuentemente)
| Archivo | Usos | Impacto |
|---------|------|---------|
| `screens/settings_screen.dart` | ~50 | Alta - Usada por todos los usuarios |
| `screens/session_detail_screen.dart` | ~10 | Media |
| `screens/create_edit_routine_screen.dart` | ~40 | Alta |
| `screens/external_session_screen.dart` | ~60 | Media |

#### Medium Priority
| Archivo | Usos | Impacto |
|---------|------|---------|
| `widgets/smart_import_sheet.dart` | ~30 | Media |
| `widgets/external_session_sheet.dart` | ~40 | Media |
| `widgets/routine_import_dialog.dart` | ~20 | Baja |
| `widgets/routine_import_preview_dialog.dart` | ~15 | Baja |

#### Low Priority (voice widgets - niche feature)
| Archivo | Usos | Impacto |
|---------|------|---------|
| `widgets/voice/voice_input_sheet.dart` | ~40 | Baja - Feature de voz |
| `widgets/voice/voice_training_button.dart` | ~15 | Baja |
| `widgets/voice/voice_feedback_widgets.dart` | ~15 | Baja |
| `widgets/voice/*.dart` | ~50 | Baja |

#### Other
| Archivo | Usos | Impacto |
|---------|------|---------|
| `widgets/routine/*.dart` | ~30 | Baja |
| `widgets/session/*.dart` (otros) | ~20 | Media |

**Total estimado:** ~400 usos de `GoogleFonts.montserrat()` en Training

---

### 3. Colores Hardcodeados

Archivos con `Colors.grey`, `Colors.white`, `Colors.red`, etc.:

- `training/screens/settings_screen.dart` - ~20 usos
- `training/widgets/smart_import_sheet*.dart` - ~15 usos
- `training/widgets/voice/*.dart` - ~30 usos
- Varios otros - ~50 usos

**Nota:** En tema oscuro (Training), `Colors.white` y `Colors.grey[xxx]` pueden funcionar, pero es mejor usar el `colorScheme` para consistencia.

---

### 4. Import Conflicts Resueltos

Los siguientes archivos tienen imports específicos con `show` para evitar conflictos:

✅ **Ya corregidos en PR2:**
- `training/widgets/session/exercise_card.dart`
- `training/widgets/session/rest_timer_bar.dart`

**Patrón establecido:**
```dart
// ✅ Correcto - Import selectivo
import '../../../core/design_system/design_system.dart' show AppTypography;
import '../../utils/design_system.dart' show AppColors;

// ❌ Incorrecto - Conflicto de nombres
// import '../../../core/design_system/design_system.dart'; // AppColors definido aquí
// import '../../utils/design_system.dart'; // AppColors definido aquí también
```

---

## Recomendaciones

### Para Nuevos Features

1. **Siempre usar core design system:**
   ```dart
   import '../../../core/design_system/design_system.dart';
   import '../../../core/widgets/widgets.dart';
   ```

2. **Nunca usar GoogleFonts directo** - Usar `AppTypography`

3. **Nunca hardcodear colores** - Usar `Theme.of(context).colorScheme`

### Para Modificaciones a Archivos Existentes

1. **Regla del "Boy Scout":** Si tocas un archivo, migra lo que esté cerca de tu cambio

2. **No migrar archivos enteros** - Solo las partes que modificas

3. **Preferir consistencia local** - Si el archivo usa `AppColors` del training, continuar así

### Para Migración Futura (PR4+)

Prioridad sugerida:

1. **Phase 1:** Screens más usadas (`settings_screen.dart`, `create_edit_routine_screen.dart`)
2. **Phase 2:** Session widgets restantes (`session_set_row.dart`, `focused_set_row.dart`)
3. **Phase 3:** Import/Export sheets (`smart_import_sheet*.dart`)
4. **Phase 4:** Voice widgets (baja prioridad - feature niche)
5. **Phase 5:** Unificar `training/utils/design_system.dart` con core (breaking change)

---

## Métricas

### Cobertura Design System

```
Core Widgets:        ████████████████████ 100%
Session Critical:    ███████████████████░  90%
Screens:             ███████░░░░░░░░░░░░░  30%
Voice Widgets:       ██░░░░░░░░░░░░░░░░░░  10%
Overall Training:    █████████░░░░░░░░░░░  45%
```

### Archivos Completamente Migrados ✅

- `core/widgets/*.dart` (todos)
- `core/design_system/*.dart` (todos)
- `training/widgets/session/exercise_card.dart`
- `training/widgets/session/rest_timer_bar.dart`
- `training/screens/history_screen.dart`
- `training/screens/train_selection_screen.dart`
- `training/screens/analysis_screen.dart`

---

## Notas

- Esta deuda técnica es **puramente visual/UX** - no afecta funcionalidad
- Los usuarios no notan diferencias significativas
- El esfuerzo de migración completa se estima en ~2-3 días de trabajo
- Se recomienda migración gradual como parte de otros features

*Documento creado post-PR3 - Febrero 2026*
