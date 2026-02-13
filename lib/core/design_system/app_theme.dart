// ============================================================================
// DESIGN SYSTEM - JUAN TRACKER
// ============================================================================
// Sistema de diseño unificado para las secciones de Nutrición y Entrenamiento.
// 
// FILOSOFÍA:
// - Consistencia visual entre modos (claro/oscuro)
// - Jerarquía clara de información
// - Accesibilidad como prioridad (WCAG 2.1 AA)
// - Animaciones sutiles y funcionales
//
// AUTOR: UX/UI Flutter Expert
// FECHA: Enero 2026
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores semánticos de la aplicación
abstract class AppColors {
  // ═══════════════════════════════════════════════════════════════════════════
  // PALETA PRIMARIA - Terracota/Naranja Quemado
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFFDA5A2A);
  static const Color primaryLight = Color(0xFFE87A4A);
  static const Color primaryDark = Color(0xFFB84A1A);
  static const Color primaryContainer = Color(0xFFFFEDE6);

  // ═══════════════════════════════════════════════════════════════════════════
  // PALETA SECUNDARIA - Teal/Cyan
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color secondary = Color(0xFF2A9D8F);
  static const Color secondaryLight = Color(0xFF4DBFAF);
  static const Color secondaryDark = Color(0xFF1F7A6E);
  static const Color secondaryContainer = Color(0xFFE6F5F3);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMÁNTICOS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFF86EFAC);
  static const Color successContainer = Color(0xFFDCFCE7);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorContainer = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF93C5FD);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTROS - MODO CLARO
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color lightBackground = Color(0xFFF5F3EE);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFF0EFEA);
  static const Color lightSurfaceContainer = Color(0xFFFAFAF8);
  
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextTertiary = Color(0xFF999999);
  static const Color lightTextDisabled = Color(0xFFCCCCCC);

  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightBorderFocus = primary;
  static const Color lightDivider = Color(0xFFEEEEEE);

  // ═══════════════════════════════════════════════════════════════════════════
  // NEUTROS - MODO OSCURO (Entrenamiento)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color darkBackground = Color(0xFF0E0F12);
  static const Color darkSurface = Color(0xFF16181D);
  static const Color darkSurfaceVariant = Color(0xFF1E2128);
  static const Color darkSurfaceContainer = Color(0xFF232834);
  
  static const Color darkTextPrimary = Color(0xFFF2F4F7);
  static const Color darkTextSecondary = Color(0xFFA0A7B4);
  static const Color darkTextTertiary = Color(0xFF7E8796);
  static const Color darkTextDisabled = Color(0xFF5C6676);

  static const Color darkBorder = Color(0xFF2A2F39);
  static const Color darkBorderFocus = Color(0xFFD02A2A);
  static const Color darkDivider = Color(0xFF1F2430);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES ESPECÍFICOS ENTRENAMIENTO
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color ironRed = Color(0xFFD02A2A);
  static const Color ironRedLight = Color(0xFFDC3A3A);
  static const Color ironTeal = Color(0xFF38BDF8);
  static const Color ironGreen = Color(0xFF22C55E);

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORES DE CELEBRACIÓN Y LOGROS (UX-004)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color goldAccent = Color(0xFFF6C453);
  static const Color goldSubtle = Color(0x26F6C453);
  static const Color goldDark = Color(0xFFD4A73A);
  static const Color completedGreen = Color(0xFF22C55E);
  static const Color completedGreenBright = Color(0xFF4ADE80);

  // ═══════════════════════════════════════════════════════════════════════════
  // ALIASES PARA COMPATIBILIDAD
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color bgElevated = darkSurfaceVariant;
  static const Color bgDeep = darkBackground;
  static const Color textSecondary = darkTextSecondary;
  static const Color textTertiary = darkTextTertiary;
  static const Color textPrimary = darkTextPrimary;
}

/// Espaciado estandarizado
abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

/// Radios de borde estandarizados
abstract class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
  static const double round = 9999.0; // Alias para full
}

/// Elevaciones (sombras) - Constantes estáticas para evitar recreación
abstract class AppElevation {
  // Constantes pre-calculadas para mejor rendimiento
  static const Color _shadow05 = Color(0x0D000000); // 0.05 * 255 = 13 = 0x0D
  static const Color _shadow08 = Color(0x14000000); // 0.08 * 255 = 20 = 0x14
  static const Color _shadow12 = Color(0x1F000000); // 0.12 * 255 = 31 = 0x1F
  static const Color _shadow16 = Color(0x29000000); // 0.16 * 255 = 41 = 0x29

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: _shadow05,
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: _shadow08,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> level3 = [
    BoxShadow(
      color: _shadow12,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> level4 = [
    BoxShadow(
      color: _shadow16,
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

/// Duraciones de animación
abstract class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
}

/// Curvas de animación
abstract class AppCurves {
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;
}

/// Tipografía estandarizada
abstract class AppTypography {
  /// Font family para casos donde se necesita crear estilos dinámicos
  static const String fontFamily = 'Montserrat';
  
  static TextTheme get textTheme => GoogleFonts.montserratTextTheme();

  // Display
  static TextStyle get displayLarge => GoogleFonts.montserrat(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );
  
  static TextStyle get displayMedium => GoogleFonts.montserrat(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  
  static TextStyle get displaySmall => GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // Headlines
  static TextStyle get headlineLarge => GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  
  static TextStyle get headlineMedium => GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get headlineSmall => GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  // Titles
  static TextStyle get titleLarge => GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get titleMedium => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get titleSmall => GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  // Body
  static TextStyle get bodyLarge => GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle get bodySmall => GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Labels
  static TextStyle get labelLarge => GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  
  static TextStyle get labelMedium => GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  
  static TextStyle get labelSmall => GoogleFonts.montserrat(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // Data (números/tabular)
  static TextStyle get dataLarge => GoogleFonts.montserrat(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  
  static TextStyle get dataMedium => GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  
  static TextStyle get dataSmall => GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// ============================================================================
/// BUILDERS DE TEMA
/// ============================================================================

/// Tema para modo Nutrición (claro)
ThemeData buildNutritionTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.secondaryDark,
    tertiary: AppColors.info,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.infoContainer,
    onTertiaryContainer: AppColors.info,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.errorLight,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    surfaceContainerHighest: AppColors.lightSurfaceContainer,
    onSurfaceVariant: AppColors.lightTextSecondary,
    outline: AppColors.lightBorder,
    outlineVariant: AppColors.lightDivider,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.darkSurface,
    onInverseSurface: AppColors.darkTextPrimary,
    inversePrimary: AppColors.primaryLight,
    surfaceTint: AppColors.primary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.lightBackground,

    // Accessibility: visible focus ring for keyboard/switch navigation
    focusColor: AppColors.primary.withValues(alpha: 0.2),
    hoverColor: AppColors.primary.withValues(alpha: 0.08),
    splashColor: AppColors.primary.withValues(alpha: 0.12),

    // Typography
    textTheme: AppTypography.textTheme.apply(
      bodyColor: AppColors.lightTextPrimary,
      displayColor: AppColors.lightTextPrimary,
    ),
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTypography.headlineMedium.copyWith(
        color: AppColors.lightTextPrimary,
      ),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    ),
    
    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppTypography.labelLarge,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.outline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    ),
    
    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurfaceContainer,
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),
    
    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    
    // Bottom Nav
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: AppColors.lightTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightSurfaceContainer,
      selectedColor: scheme.primaryContainer,
      labelStyle: AppTypography.labelMedium,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    ),
    
    // Dividers
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: 1,
      space: AppSpacing.lg,
    ),
    
    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    
    // Bottom Sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
    ),
  );
}

/// Tema para modo Entrenamiento (oscuro)
ThemeData buildTrainingTheme() {
  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.ironRed,
    onPrimary: Colors.white,
    primaryContainer: AppColors.ironRed.withValues(alpha: 0.2),
    onPrimaryContainer: AppColors.ironRedLight,
    secondary: AppColors.ironTeal,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.ironTeal.withValues(alpha: 0.2),
    onSecondaryContainer: AppColors.ironTeal,
    tertiary: AppColors.ironGreen,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.ironGreen.withValues(alpha: 0.2),
    onTertiaryContainer: AppColors.ironGreen,
    error: AppColors.errorLight,
    onError: Colors.white,
    errorContainer: AppColors.error.withValues(alpha: 0.3),
    onErrorContainer: AppColors.errorLight,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerHighest: AppColors.darkSurfaceVariant,
    onSurfaceVariant: AppColors.darkTextSecondary,
    outline: AppColors.darkBorder,
    outlineVariant: AppColors.darkDivider,
    shadow: Colors.black,
    scrim: Colors.black.withValues(alpha: 0.8),
    inverseSurface: AppColors.lightSurface,
    onInverseSurface: AppColors.lightTextPrimary,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.ironRed,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.darkBackground,

    // Accessibility: visible focus ring for keyboard/switch navigation
    focusColor: AppColors.ironRed.withValues(alpha: 0.3),
    hoverColor: AppColors.ironRed.withValues(alpha: 0.1),
    splashColor: AppColors.ironRed.withValues(alpha: 0.15),

    // Typography
    textTheme: GoogleFonts.montserratTextTheme().apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    ),
    
    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: AppTypography.headlineMedium.copyWith(
        color: AppColors.darkTextPrimary,
        fontSize: 18,
      ),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    ),
    
    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    
    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    
    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    
    // Bottom Nav
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: AppColors.darkTextTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    
    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurfaceContainer,
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    
    // Bottom Sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
    ),
  );
}

/// Extensión para acceder fácilmente al tema
extension ThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get typography => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
