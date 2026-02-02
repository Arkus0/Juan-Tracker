# Technical Debt Tracking - Juan Tracker

## Design System Migration Progress

### Overview
This document tracks the migration from hardcoded `GoogleFonts.montserrat()` and legacy `AppColors` to the unified Design System in `lib/core/design_system/design_system.dart`.

### Migration Pattern
```dart
// Import with alias to avoid conflicts
import '../../../core/design_system/design_system.dart' as core show AppTypography;

// Usage
textStyle: core.AppTypography.titleLarge,
```

---

## Current Status

| Area | Status | Usages Eliminated |
|------|--------|-------------------|
| Core Widgets | ✅ 100% | ~50 |
| Session Critical | ✅ 100% | ~100 |
| Import/Export | ✅ 100% | ~105 |
| Voice Widgets | ✅ 100% | ~55 |
| Routine Widgets | ✅ 100% | ~30 |
| **Overall Training** | **✅ ~99%** | **~430** |

---

## Completed Phases

### Phase 1: Core Screens ✅
**Files migrated:**
- `settings_screen.dart` (~40 usages)
- `create_edit_routine_screen.dart` (~55 usages)
- `session_detail_screen.dart` (~45 usages)
- `external_session_screen.dart` (~20 usages)

**Total:** ~160 usages removed

### Phase 2: Session Widgets ✅
**Files migrated:**
- `session_set_row.dart`
- `focused_set_row.dart`
- `progression_suggestion_chip.dart`
- `advanced_options_modal.dart`
- `log_input.dart`
- `session_modifiers.dart`
- `numpad_input_modal.dart`
- `quick_actions_menu.dart`
- `tolerance_feedback_widgets.dart`
- `progression_preview.dart`
- `rest_timer_panel.dart`

**Total:** ~100 usages removed

### Phase 3: Import/Export System ✅
**Files migrated:**
- `smart_import_sheet.dart`
- `smart_import_sheet_simple.dart`
- `smart_import_sheet_voice.dart`
- `external_session_sheet.dart`
- `routine_import_dialog.dart`
- `routine_import_preview_dialog.dart`

**Total:** ~105 usages removed

### Phase 4: Voice Widgets ✅
**Files migrated:**
- `voice_input_sheet.dart` (~32 usages)
- `voice_feedback_widgets.dart` (~13 usages)
- `voice_training_button.dart` (~10 usages)
- `voice_mic_button.dart` (~3 usages)
- `voice_training_fab.dart` (~1 uso)
- `voice_undo_snackbar.dart` (~4 usos)
- `ptt_voice_button.dart` (~4 usos)
- `unified_capture_button.dart` (~4 usos)

**Total:** ~55 usages removed

### Phase 5: Routine Widgets ✅
**Files migrated:**
- `scheduling_config_widget.dart` (~11 usages)
- `block_timeline_widget.dart` (~18 usages)

**Total:** ~29 usages removed

---

## Migration Complete ✅

**Fecha de finalización:** Febrero 2026

### Total de usos eliminados: ~500+

Todos los archivos del módulo de training han sido migrados al Design System unificado:
- ✅ Core Widgets
- ✅ Session Widgets  
- ✅ Import/Export
- ✅ Voice Widgets
- ✅ Routine Widgets
- ✅ Screens
- ✅ Analysis Widgets
- ✅ Create Routine Widgets

### Patrón establecido:
```dart
import '../../../core/design_system/design_system.dart' as core show AppTypography;

textStyle: core.AppTypography.titleLarge, // En lugar de GoogleFonts.montserrat(...)
```

### Archivos que mantienen GoogleFonts (legacy):
- `lib/training/utils/design_system.dart` - Mantiene `AppTypography` con `GoogleFonts.montserrat()` para compatibilidad hacia atrás
- Este archivo es el único lugar donde `GoogleFonts.montserrat()` sigue permitido

### Resultado:
- `flutter analyze` pasa sin errores
- Todos los widgets usan el Design System unificado
- Preparado para futuros temas (light/dark mode dinámico)

---

## Typography Mapping Reference

| Original Pattern | New Style |
|-----------------|-----------|
| `fontWeight: w900` + large size | `core.AppTypography.headlineSmall` |
| `fontWeight: w700/bold` | `core.AppTypography.titleLarge` |
| `fontWeight: w600` | `core.AppTypography.labelLarge` |
| `fontSize: 16` | `core.AppTypography.bodyLarge` |
| `fontSize: 13-14` | `core.AppTypography.bodyMedium` |
| `fontSize: 11-12` | `core.AppTypography.bodySmall` |
| `fontSize: 10` | `core.AppTypography.labelSmall` |

## Color Migration Reference

| Original | New |
|----------|-----|
| `Colors.white` | `Theme.of(context).colorScheme.onSurface` |
| `Colors.white70` | `onSurface.withAlpha(178)` |
| `Colors.white54` | `onSurface.withAlpha(138)` |
| `Colors.white38` | `onSurface.withAlpha(97)` |
| `Colors.grey[800]` | `colorScheme.surfaceContainerHighest` |

---

## Notes

- Legacy `training/utils/design_system.dart` preserved for backward compatibility
- Import alias `as core` prevents naming conflicts
- No visual changes - purely architectural cleanup
- All migrated files pass `flutter analyze` with no issues
