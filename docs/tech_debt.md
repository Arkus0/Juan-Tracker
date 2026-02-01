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
| **Training - Session Widgets** | **✅ 100%** | **0** | **-** |
| Training - Screens | ✅ 70% | ~11 archivos | Media |
| Training - Voice Widgets | ⏳ 10% | ~10 archivos | Baja |
| Training - Utils | ⏳ 50% | 1 archivo | Baja |

---

## Progreso de Migración

### ✅ Fase 1 Completada (Febrero 2026)

Los siguientes archivos de **alta prioridad** fueron migrados exitosamente:

| Archivo | Estado | Usos Migrados |
|---------|--------|---------------|
| `screens/settings_screen.dart` | ✅ Completo | ~50 |
| `screens/create_edit_routine_screen.dart` | ✅ Completo | ~40 |
| `screens/session_detail_screen.dart` | ✅ Completo | ~10 |
| `screens/external_session_screen.dart` | ✅ Completo | ~60 |

**Total Fase 1:** ~160 usos de `GoogleFonts.montserrat()` eliminados

### ✅ Fase 2 Completada (Febrero 2026)

Todos los **session widgets** fueron migrados exitosamente:

| Archivo | Usos Migrados |
|---------|---------------|
| `widgets/session/session_set_row.dart` | ~9 |
| `widgets/session/focused_set_row.dart` | ~8 |
| `widgets/session/progression_suggestion_chip.dart` | ~4 |
| `widgets/session/advanced_options_modal.dart` | ~5 |
| `widgets/session/log_input.dart` | ~4 |
| `widgets/session/session_modifiers.dart` | ~3 |
| `widgets/session/numpad_input_modal.dart` | ~12 |
| `widgets/session/quick_actions_menu.dart` | ~12 |
| `widgets/session/tolerance_feedback_widgets.dart` | ~18 |
| `widgets/session/progression_preview.dart` | ~24 |
| `widgets/session/rest_timer_panel.dart` | ~1 |

**Total Fase 2:** ~100 usos de `GoogleFonts.montserrat()` eliminados

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

### 2. Archivos con GoogleFonts Directo (Pendientes)

Los siguientes archivos aún usan `GoogleFonts.montserrat()` directamente:

#### Medium Priority (Import/Export)
| Archivo | Usos | Impacto |
|---------|------|---------|
| `widgets/smart_import_sheet.dart` | ~30 | Media |
| `widgets/external_session_sheet.dart` | ~40 | Media |
| `widgets/routine_import_dialog.dart` | ~20 | Baja |
| `widgets/routine_import_preview_dialog.dart` | ~15 | Baja |

#### Low Priority (Voice Widgets - niche feature)
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

**Total estimado restante:** ~140 usos de `GoogleFonts.montserrat()` en Training

---

### 3. Colores Hardcodeados (Pendientes)

Archivos con `Colors.grey`, `Colors.white`, `Colors.red`, etc.:

- `training/widgets/smart_import_sheet*.dart` - ~15 usos
- `training/widgets/voice/*.dart` - ~30 usos
- Varios otros - ~50 usos

**Nota:** Los archivos de Fase 1 y Fase 2 ya fueron migrados a usar `Theme.of(context).colorScheme`.

---

### 4. Import Conflicts Resueltos

Los siguientes archivos tienen imports específicos con `show` para evitar conflictos:

✅ **Ya corregidos en PR2:**
- `training/widgets/session/exercise_card.dart`
- `training/widgets/session/rest_timer_bar.dart`

✅ **Ya corregidos en Fase 1 (Screens):**
- `training/screens/settings_screen.dart`
- `training/screens/create_edit_routine_screen.dart`
- `training/screens/session_detail_screen.dart`
- `training/screens/external_session_screen.dart`

✅ **Ya corregidos en Fase 2 (Session Widgets):**
- `training/widgets/session/session_set_row.dart`
- `training/widgets/session/focused_set_row.dart`
- `training/widgets/session/progression_suggestion_chip.dart`
- `training/widgets/session/advanced_options_modal.dart`
- `training/widgets/session/log_input.dart`
- `training/widgets/session/session_modifiers.dart`
- `training/widgets/session/numpad_input_modal.dart`
- `training/widgets/session/quick_actions_menu.dart`
- `training/widgets/session/tolerance_feedback_widgets.dart`
- `training/widgets/session/progression_preview.dart`
- `training/widgets/session/rest_timer_panel.dart`

**Patrón establecido:**
```dart
// ✅ Correcto - Import selectivo con prefijo
import '../../../core/design_system/design_system.dart' as core show AppTypography;
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
   import '../../../core/design_system/design_system.dart' as core show AppTypography;
   import '../../../core/widgets/widgets.dart';
   ```

2. **Nunca usar GoogleFonts directo** - Usar `core.AppTypography`

3. **Nunca hardcodear colores** - Usar `Theme.of(context).colorScheme`

### Para Modificaciones a Archivos Existentes

1. **Regla del "Boy Scout":** Si tocas un archivo, migra lo que esté cerca de tu cambio

2. **No migrar archivos enteros** - Solo las partes que modificas

3. **Preferir consistencia local** - Si el archivo usa `AppColors` del training, continuar así

### Para Migración Futura (Fase 3+)

Prioridad sugerida:

1. **Fase 3:** Import/Export sheets (`smart_import_sheet*.dart`)
2. **Fase 4:** Voice widgets (baja prioridad - feature niche)
3. **Fase 5:** Unificar `training/utils/design_system.dart` con core (breaking change)

---

## Métricas

### Cobertura Design System

```
Core Widgets:        ████████████████████ 100%
Session Critical:    ████████████████████ 100%  (+10% después de Fase 2)
Screens:             ██████████████░░░░░░  70%
Voice Widgets:       ██░░░░░░░░░░░░░░░░░░  10%
Overall Training:    ███████████████░░░░░  75%  (+15% después de Fase 2)
```

### Archivos Completamente Migrados ✅

**Core:**
- `core/widgets/*.dart` (todos)
- `core/design_system/*.dart` (todos)

**Session Widgets (Fase 2):**
- `training/widgets/session/exercise_card.dart`
- `training/widgets/session/rest_timer_bar.dart`
- `training/widgets/session/session_set_row.dart`
- `training/widgets/session/focused_set_row.dart`
- `training/widgets/session/progression_suggestion_chip.dart`
- `training/widgets/session/advanced_options_modal.dart`
- `training/widgets/session/log_input.dart`
- `training/widgets/session/session_modifiers.dart`
- `training/widgets/session/numpad_input_modal.dart`
- `training/widgets/session/quick_actions_menu.dart`
- `training/widgets/session/tolerance_feedback_widgets.dart`
- `training/widgets/session/progression_preview.dart`
- `training/widgets/session/rest_timer_panel.dart`

**Screens (Fase 1):**
- `training/screens/history_screen.dart`
- `training/screens/train_selection_screen.dart`
- `training/screens/analysis_screen.dart`
- `training/screens/settings_screen.dart`
- `training/screens/create_edit_routine_screen.dart`
- `training/screens/session_detail_screen.dart`
- `training/screens/external_session_screen.dart`

---

## Notas

- Esta deuda técnica es **puramente visual/UX** - no afecta funcionalidad
- Los usuarios no notan diferencias significativas
- El esfuerzo de migración completa se estima en ~1 día de trabajo adicional
- Se recomienda migración gradual como parte de otros features

*Documento actualizado post-Fase 2 - Febrero 2026*
