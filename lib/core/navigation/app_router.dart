import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/home/presentation/entry_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../training/training_shell.dart';

/// Router personalizado con transiciones suaves
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _buildRoute(const EntryScreen(), settings);
      case '/nutrition':
        return _buildThemeTransitionRoute(
          const HomeScreen(),
          settings,
          brightness: Brightness.light,
        );
      case '/training':
        return _buildThemeTransitionRoute(
          const TrainingShell(),
          settings,
          brightness: Brightness.dark,
        );
      default:
        return _buildRoute(const EntryScreen(), settings);
    }
  }

  static PageRoute _buildRoute(Widget child, RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => child,
    );
  }

  /// Transición con cambio de tema (modo nutrición/entrenamiento)
  static PageRoute _buildThemeTransitionRoute(
    Widget child,
    RouteSettings settings, {
    required Brightness brightness,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade + Scale transition
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        final scaleAnimation = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

/// Extension para navegación con haptic feedback
extension NavigationExtension on BuildContext {
  void navigateWithHaptic(String route, {Object? arguments}) {
    HapticFeedback.selectionClick();
    Navigator.of(this).pushNamed(route, arguments: arguments);
  }

  void navigateReplacementWithHaptic(String route, {Object? arguments}) {
    HapticFeedback.mediumImpact();
    Navigator.of(this).pushReplacementNamed(route, arguments: arguments);
  }

  void popWithHaptic<T>([T? result]) {
    HapticFeedback.lightImpact();
    Navigator.of(this).pop(result);
  }
}
