# Design System Lite - Juan Tracker

> Version: 1.0  
> Date: Febrero 2026  
> Source: Diet section as gold standard  
> Applies to: All UI modules (Diet, Training, Shared)

---

## 🎯 Philosophy

1. **Consistency over creativity** - Use established patterns
2. **Theme-first** - Always use `Theme.of(context)` values
3. **Token-based** - No magic numbers, use design tokens
4. **Accessibility** - WCAG 2.1 AA minimum
5. **Performance** - Pre-computed styles, minimize rebuilds

---

## 🎨 Color Usage

### Primary Rule
```dart
// ✅ CORRECT: Use theme
final colors = Theme.of(context).colorScheme;
backgroundColor: colors.surface,
foregroundColor: colors.onSurface,
accentColor: colors.primary,

// ❌ WRONG: Hardcoded colors
backgroundColor: Colors.grey[850],
foregroundColor: Colors.white,
accentColor: Color(0xFFD02A2A),
```

### Semantic Colors
| Purpose | Token | Hex (Light) | Hex (Dark) |
|---------|-------|-------------|------------|
| Primary | `colors.primary` | `#DA5A2A` | `#D02A2A` |
| Surface | `colors.surface` | `#FFFFFF` | `#16181D` |
| Background | `scaffoldBackgroundColor` | `#F5F3EE` | `#0E0F12` |
| Error | `colors.error` | `#EF4444` | `#E65B5B` |
| Success | `AppColors.success` | `#22C55E` | `#22C55E` |

---

## 🔤 Typography

### Hierarchy
```dart
// Display (rarely used)
AppTypography.displayLarge   // 48px, w800
AppTypography.displayMedium  // 36px, w700
AppTypography.displaySmall   // 28px, w700

// Headlines (screen titles)
AppTypography.headlineLarge  // 24px, w700
AppTypography.headlineMedium // 20px, w600  ← Use for screen titles
AppTypography.headlineSmall  // 18px, w600

// Titles (card headers, section titles)
AppTypography.titleLarge     // 16px, w600
AppTypography.titleMedium    // 14px, w600  ← Most common
AppTypography.titleSmall     // 12px, w600

// Body (content)
AppTypography.bodyLarge      // 16px, w400
AppTypography.bodyMedium     // 14px, w400  ← Default text
AppTypography.bodySmall      // 12px, w400

// Labels (buttons, chips)
AppTypography.labelLarge     // 14px, w600
AppTypography.labelMedium    // 12px, w600
AppTypography.labelSmall     // 10px, w600

// Data (numbers, stats)
AppTypography.dataLarge      // 32px, w800, tabular
AppTypography.dataMedium     // 24px, w700, tabular
AppTypography.dataSmall      // 18px, w700, tabular
```

### Usage Pattern
```dart
// ✅ CORRECT: Typography token + color from theme
Text(
  'Title',
  style: AppTypography.titleLarge.copyWith(
    color: colors.onSurface,
  ),
)

// ❌ WRONG: Direct font usage
Text(
  'Title',
  style: GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
)
```

---

## 📐 Spacing

### Tokens
```dart
AppSpacing.xs   // 4.0   - Icon padding, tight gaps
AppSpacing.sm   // 8.0   - Inline spacing, small padding
AppSpacing.md   // 12.0  - Component padding
AppSpacing.lg   // 16.0  - Card padding, section gaps  ← Most common
AppSpacing.xl   // 24.0  - Screen padding, large gaps
AppSpacing.xxl  // 32.0  - Section separators
AppSpacing.xxxl // 48.0  - Major section breaks
```

### Usage Patterns
```dart
// Card padding
padding: const EdgeInsets.all(AppSpacing.lg),

// List item spacing
padding: const EdgeInsets.symmetric(
  horizontal: AppSpacing.lg,
  vertical: AppSpacing.md,
),

// Section gaps
const SizedBox(height: AppSpacing.lg),

// Screen padding
padding: const EdgeInsets.all(AppSpacing.lg),
```

---

## ⬜ Components

### AppCard (Standard Card)
```dart
AppCard(
  onTap: () {},           // Optional
  padding: const EdgeInsets.all(AppSpacing.lg),  // Default
  isSelected: false,      // Optional selection state
  child: ...,             // Required
)
```

### AppButton (Standard Button)
```dart
// Primary button
AppButton.primary(
  label: 'Guardar',
  onPressed: () {},
  icon: Icons.save,       // Optional
)

// Secondary button
AppButton.secondary(
  label: 'Cancelar',
  onPressed: () {},
)
```

### AppStates (Loading, Empty, Error)
```dart
// Loading
const AppLoading(message: 'Cargando...')

// Empty
AppEmpty(
  icon: Icons.fitness_center_outlined,
  title: 'Sin rutinas',
  subtitle: 'Crea tu primera rutina para empezar',
  actionLabel: 'CREAR RUTINA',
  onAction: () {},
)

// Error
AppError(
  message: 'Error al cargar',
  details: error.toString(),  // Optional
  onRetry: () {},            // Optional
)
```

### Skeleton Loading
```dart
// Single placeholder
const AppSkeleton(width: 100, height: 20)

// List skeleton
const AppSkeletonList(itemCount: 5)

// Screen-specific skeleton
const DiarySkeleton()
```

---

## 🏗️ Layout Patterns

### Screen Structure
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Screen Title'),
            centerTitle: true,
            actions: [...],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: ...,  // Or use async value builders
          ),
        ],
      ),
    );
  }
}
```

### Async Data Pattern
```dart
asyncValue.when(
  data: (data) => _buildContent(data),
  loading: () => const AppSkeletonList(),
  error: (err, _) => AppError(
    message: 'Error al cargar',
    details: err.toString(),
    onRetry: () => ref.invalidate(provider),
  ),
)
```

---

## ♿ Accessibility

### Touch Targets
- Minimum: 48x48 dp
- Preferred: 56x56 dp (for gym/training contexts)

### Semantics
```dart
Semantics(
  button: true,
  label: 'Guardar entrada',
  child: IconButton(...),
)
```

### Contrast
- Text on background: 4.5:1 minimum (AA)
- Large text (18px+): 3:1 minimum
- UI components: 3:1 minimum

---

## 🎭 Theme Configuration

### Light Theme (Nutrition)
```dart
ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme(...),
  scaffoldBackgroundColor: AppColors.lightBackground,
  appBarTheme: AppBarTheme(
    centerTitle: true,
    elevation: 0,
    ...
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: colors.outline),
    ),
  ),
)
```

### Dark Theme (Training)
```dart
ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme(...),
  scaffoldBackgroundColor: AppColors.darkBackground,
  appBarTheme: AppBarTheme(
    centerTitle: true,  // CHANGED: Now consistent with light
    elevation: 0,
    ...
  ),
  // Same card theme as light, just different colors
)
```

---

## 📝 Code Style

### Imports
```dart
// Always import design system
import 'package:juan_tracker/core/design_system/design_system.dart';

// Import widgets
import 'package:juan_tracker/core/widgets/widgets.dart';
```

### Build Method Structure
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final colors = Theme.of(context).colorScheme;
  final asyncData = ref.watch(dataProvider);
  
  return Scaffold(
    body: asyncData.when(
      data: (data) => _buildContent(context, colors, data),
      loading: () => const AppSkeletonList(),
      error: (err, _) => AppError(...),
    ),
  );
}
```

### State Management
- Use `ConsumerWidget` for simple screens
- Use `ConsumerStatefulWidget` for complex state
- Always use `select` for granular rebuilds

---

## ❌ Anti-Patterns

```dart
// ❌ Don't use direct colors
Colors.grey[850]
Colors.white
Color(0xFFD02A2A)

// ❌ Don't use direct fonts
GoogleFonts.montserrat(...)

// ❌ Don't use magic numbers
const SizedBox(height: 32)  // Use AppSpacing.xxl
BorderRadius.circular(12)   // Use AppRadius.lg

// ❌ Don't skip theme
Container(color: Colors.black)

// ❌ Don't duplicate widget logic
// Instead: Extend or use shared components
```

---

## ✅ Migration Checklist

When updating Training (or any module):

- [ ] Replace hardcoded colors with theme
- [ ] Replace `GoogleFonts` with `AppTypography`
- [ ] Replace magic numbers with spacing/radius tokens
- [ ] Use `AppCard` instead of raw `Card`
- [ ] Use `AppEmpty`/`AppError`/`AppLoading` for states
- [ ] Ensure `centerTitle: true` in AppBars
- [ ] Add Semantics to custom interactive widgets
- [ ] Verify touch targets ≥ 48dp
- [ ] Run `flutter analyze` - no errors
- [ ] Run tests - all passing
