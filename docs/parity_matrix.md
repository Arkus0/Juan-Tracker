# Parity Matrix: Diet vs Training UI/UX

> Generated: Febrero 2026  
> Base: Diet section as gold standard  
> Target: Training section alignment

---

## 📊 Summary

| Category | Diet Score | Training Score | Gap |
|----------|-----------|----------------|-----|
| Visual Polish | ⭐⭐⭐⭐⭐ | ⭐⭐⭐☆☆ | High |
| Spacing/Typography | ⭐⭐⭐⭐⭐ | ⭐⭐⭐☆☆ | Medium |
| Component Consistency | ⭐⭐⭐⭐⭐ | ⭐⭐☆☆☆ | High |
| Navigation Clarity | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐☆ | Low |
| Empty States | ⭐⭐⭐⭐⭐ | ⭐⭐⭐☆☆ | Medium |
| Loading States | ⭐⭐⭐⭐⭐ | ⭐⭐⭐☆☆ | Medium |
| Error States | ⭐⭐⭐⭐⭐ | ⭐⭐⭐☆☆ | Medium |
| Accessibility | ⭐⭐⭐⭐⭐ | ⭐⭐⭐☆☆ | Medium |

---

## 🔍 Detailed Comparison

### 1. Visual Polish

#### Diet (Does Well)
- **File**: `lib/features/diary/presentation/diary_screen.dart`
- Uses consistent `AppCard` with theme-based borders
- Proper use of `colorScheme` from Theme
- Consistent icon sizing and colors
- Well-balanced visual hierarchy

```dart
// Good: Using theme
AppCard(
  padding: EdgeInsets.zero,
  child: Column(...),
)

// Good: Color scheme usage
style: AppTypography.bodySmall.copyWith(
  color: colors.onSurfaceVariant,
)
```

#### Training (Does Worse)
- **Files**: 
  - `lib/training/screens/train_selection_screen.dart` (line 802-860)
  - `lib/training/screens/analysis_screen.dart`
  - `lib/training/widgets/common/app_widgets.dart`
  
- Hardcoded colors: `Colors.grey[850]`, `Colors.grey[900]`
- Inconsistent card backgrounds
- Mixed use of theme vs hardcoded values

```dart
// Bad: Hardcoded colors
Card(
  color: Colors.grey[850],  // ❌ Not theme-based
  ...
)

// Bad: Direct GoogleFonts without typography token
style: GoogleFonts.montserrat(
  color: Colors.white,  // ❌ Not from theme
  ...
)
```

---

### 2. Spacing & Typography

#### Diet (Does Well)
- Consistent use of `AppSpacing` tokens (`xs`, `sm`, `md`, `lg`, `xl`)
- Typography via `AppTypography` (headlineMedium, titleLarge, etc.)
- Pre-computed styles, no runtime font generation

```dart
// Good: Spacing tokens
padding: const EdgeInsets.all(AppSpacing.lg),

// Good: Typography tokens
style: AppTypography.titleMedium.copyWith(
  fontWeight: FontWeight.w600,
),
```

#### Training (Does Worse)
- **File**: `lib/training/utils/design_system.dart` has tokens but not consistently used
- Direct `GoogleFonts.montserrat()` calls throughout codebase
- Magic numbers for spacing

```dart
// Bad: Direct font usage (appears 50+ times)
style: GoogleFonts.montserrat(
  fontSize: 16,
  fontWeight: FontWeight.w800,
  color: Colors.white,
)

// Bad: Magic spacing
const SizedBox(height: 32),  // ❌ Should be AppSpacing.xxl
```

---

### 3. Component Consistency

#### Diet (Does Well)
- Shared widgets: `AppCard`, `AppButton`, `AppEmpty`, `AppLoading`, `AppError`
- Skeleton loaders: `DiarySkeleton`, `SummarySkeleton`
- All in `lib/core/widgets/`

```dart
// Good: Using shared component
AppEmpty(
  icon: Icons.fitness_center_outlined,
  title: 'Tu primer paso...',
  subtitle: 'Una rutina bien estructurada...',
  actionLabel: 'CREAR MI PRIMERA RUTINA',
  onAction: () => _navigateToCreate(context),
)
```

#### Training (Does Worse)
- Duplicated empty state: `EmptyStateWidget` in `lib/training/widgets/common/app_widgets.dart`
- Duplicated error state: `ErrorStateWidget`
- Duplicated loading: `AppLoadingIndicator`, `ShimmerLoadingCard`
- Inconsistent with core widgets styling

```dart
// Bad: Duplicated component (Training)
EmptyStateWidget(
  icon: Icons.add_circle_outline_rounded,
  title: 'CREA TU RUTINA',
  subtitle: 'Ve a la pestana Rutinas...',
  // ❌ Different styling than AppEmpty
)
```

---

### 4. Navigation Clarity

#### Diet (Does Well)
- Clear app bar with `centerTitle: true`
- Consistent back button behavior
- `HomeButton` widget for quick return
- Clear tab labels and indicators

```dart
SliverAppBar(
  floating: true,
  snap: true,
  title: const Text('Diario'),
  centerTitle: true,
  leading: const Padding(
    padding: EdgeInsets.all(8.0),
    child: HomeButton(),
  ),
)
```

#### Training (Does Worse)
- `centerTitle: false` in Training theme
- Inconsistent back behavior
- Some screens lack proper navigation affordances

```dart
// Inconsistent: AppBarTheme in training
centerTitle: false,  // ❌ Different from Diet
```

---

### 5. Empty States

#### Diet (Does Well)
- `AppEmpty` in `lib/core/widgets/app_states.dart`
- Consistent icon size (64), color handling
- Proper action button integration

```dart
// AppEmpty implementation
Icon(
  icon,
  size: 64,
  color: colors.onSurfaceVariant.withAlpha((0.5 * 255).round()),
),
Text(
  title,
  style: AppTypography.headlineSmall.copyWith(
    color: colors.onSurface,
  ),
)
```

#### Training (Does Worse)
- `EmptyStateWidget` uses different styling
- Icon size 80 (vs 64)
- Uses `AppColors.textTertiary` directly instead of theme
- Inconsistent padding

---

### 6. Loading States

#### Diet (Does Well)
- `AppLoading` with consistent spinner
- `AppSkeleton` with shimmer effect
- Context-specific skeletons: `DiarySkeleton`, `SummarySkeleton`

```dart
// Good: Consistent loading
AppLoading(message: 'Cargando rutinas...')

// Good: Skeleton with shimmer
AppSkeleton(width: double.infinity, height: 90)
```

#### Training (Does Worse)
- `AppLoadingIndicator` (different styling)
- `ShimmerLoadingCard` (different gradient colors)
- Inconsistent spinner colors

---

### 7. Error States

#### Diet (Does Well)
- `AppError` with retry button
- Consistent error icon and colors
- Optional details expansion

```dart
AppError(
  message: 'Error al cargar rutinas',
  details: err.toString(),
  onRetry: () => ref.invalidate(rutinasStreamProvider),
)
```

#### Training (Does Worse)
- `ErrorStateWidget` with different styling
- Uses `GoogleFonts.montserrat` directly
- Inconsistent error icon color handling

---

### 8. Accessibility

#### Diet (Does Well)
- `Semantics` widgets for screen readers
- Proper `label` attributes
- Focus management

```dart
Semantics(
  button: true,
  label: 'Ir al día de hoy',
  child: TextButton(...),
)
```

#### Training (Does Worse)
- Limited Semantics usage
- Some touch targets may be small
- Missing labels on interactive elements

---

## 📁 Affected Files

### High Priority (PR1)

| File | Issue | Action |
|------|-------|--------|
| `lib/training/widgets/common/app_widgets.dart` | Duplicated widgets | Unify with core |
| `lib/training/screens/train_selection_screen.dart` | Hardcoded colors | Use theme tokens |
| `lib/training/screens/analysis_screen.dart` | Direct font usage | Use AppTypography |
| `lib/training/screens/rutinas_screen.dart` | Inconsistent styling | Apply design system |

### Medium Priority (PR2)

| File | Issue | Action |
|------|-------|--------|
| `lib/training/widgets/session/exercise_card.dart` | Complex, inconsistent | Refactor with tokens |
| `lib/training/widgets/session/rest_timer_bar.dart` | Direct font usage | Use typography tokens |
| `lib/training/utils/design_system.dart` | Fragmented | Align with core |

---

## ✅ Checklist for Alignment

### Must Fix (PR1)
- [ ] Replace `EmptyStateWidget` → `AppEmpty`
- [ ] Replace `ErrorStateWidget` → `AppError`
- [ ] Replace `AppLoadingIndicator` → `AppLoading`
- [ ] Remove hardcoded `Colors.grey[xxx]` in Training screens
- [ ] Replace direct `GoogleFonts` calls with `AppTypography`
- [ ] Use `AppSpacing` instead of magic numbers
- [ ] Use `AppRadius` instead of hardcoded values

### Should Fix (PR2)
- [ ] Unify card styling (use `AppCard`)
- [ ] Unify dialog styling
- [ ] Unify bottom sheet styling
- [ ] Add Semantics to interactive elements
- [ ] Ensure touch targets ≥ 48dp

### Nice to Have (PR3)
- [ ] Animation consistency
- [ ] Performance optimizations
