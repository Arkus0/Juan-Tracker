# PR1: Align Training Visual System with Diet

## Summary
This PR brings the Training section's UI/UX up to the same standard as the Diet section by aligning it with the core design system.

## Changes Made

### 1. Core Widget Alignment (`lib/training/widgets/common/app_widgets.dart`)
- **Re-exported core widgets** instead of duplicating them:
  - `AppEmpty` - Empty state component
  - `AppError` - Error state with retry
  - `AppLoading` - Loading indicator
  - `AppCard` - Consistent card styling
  - All other shared widgets from `lib/core/widgets/`
- **Added Training-specific widgets** that follow the design system:
  - `TrainingCard` - Card with theme-based styling
  - `TrainingStat` - Metric display component
  - `TrainingActionChip` - Compact action button
  - `TrainingSectionHeader` - Section header with optional action
  - `TrainingInfoRow` - Label-value pair
  - `TrainingLoadingOverlay` - Full-screen loading
  - `ScaleButton` - Tactile feedback button (kept from original)
  - `showTrainingConfirmDialog` - Unified dialog styling

### 2. Screen Updates

#### `lib/training/screens/train_selection_screen.dart`
**Before:**
- Hardcoded colors: `Colors.grey[850]`, `Colors.grey[900]`, `Colors.white`
- Direct `GoogleFonts.montserrat()` usage
- Custom `EmptyStateWidget`, `ErrorStateWidget`, `AppLoadingIndicator`
- Magic numbers for spacing

**After:**
- Theme-based colors: `Theme.of(context).colorScheme`
- Typography tokens: `AppTypography.headlineMedium`, etc.
- Core widgets: `AppEmpty`, `AppError`, `AppLoading`
- Spacing tokens: `AppSpacing.lg`, `AppSpacing.xl`, etc.
- Unified dialog styling with proper theme integration

#### `lib/training/screens/analysis_screen.dart`
**Before:**
- `GoogleFonts.montserrat()` for all text
- Hardcoded colors in dialogs and snackbars
- Inconsistent AppBar styling

**After:**
- `AppTypography` tokens for all text
- Theme-based colors
- Consistent `centerTitle: true` AppBar
- Unified snackbar styling

#### `lib/training/screens/rutinas_screen.dart`
- Already used core design system - no changes needed
- Verified consistent usage of `AppCard`, `AppTypography`, `AppSpacing`

#### `lib/training/widgets/analysis/session_list_view.dart`
- Updated to use core widgets: `AppLoading`, `AppEmpty`, `AppError`
- Added proper imports for design system

### 3. Documentation
- Created `docs/parity_matrix.md` - Comprehensive comparison of Diet vs Training
- Created `docs/design_system.md` - Design System Lite standard for future development

## Files Modified
1. `lib/training/widgets/common/app_widgets.dart` - Re-export core widgets
2. `lib/training/screens/train_selection_screen.dart` - Design system alignment
3. `lib/training/screens/analysis_screen.dart` - Design system alignment
4. `lib/training/widgets/analysis/session_list_view.dart` - Core widget usage

## Files Created
1. `docs/parity_matrix.md` - Comparison matrix
2. `docs/design_system.md` - Design system documentation

## Verification
- ✅ `flutter analyze` - No errors in modified files
- ✅ `flutter test` - 140+ tests passing (5 pre-existing failures unrelated to changes)
- ✅ Consistent use of `AppColors` from core design system
- ✅ Consistent use of `AppTypography` instead of direct `GoogleFonts`
- ✅ Consistent use of `AppSpacing` instead of magic numbers
- ✅ Consistent use of `AppRadius` for border radius

## Visual Changes

### Before (Training)
- Hardcoded dark theme colors
- Inconsistent text styling
- Mixed widget patterns
- Dialogs with hardcoded colors

### After (Training)
- Theme-aware colors (works with light/dark mode)
- Consistent typography hierarchy
- Unified widget patterns from core library
- Dialogs using theme colors
- Consistent spacing throughout

## Migration Guide for Future Changes

When updating Training UI:
1. Import design system: `import 'package:juan_tracker/core/design_system/design_system.dart';`
2. Import widgets: `import 'package:juan_tracker/core/widgets/widgets.dart';`
3. Use `Theme.of(context).colorScheme` for colors
4. Use `AppTypography` for text styles
5. Use `AppSpacing` for padding/margins
6. Use `AppRadius` for border radius
7. Use `AppEmpty`, `AppError`, `AppLoading` for states
8. Use `AppCard` for card components

## Next Steps (PR2 - UX Improvements)
1. Streamline navigation flows in Training
2. Add better feedback for user actions
3. Improve accessibility with Semantics
4. Optimize touch targets (≥48dp)
5. Add golden tests for key screens
