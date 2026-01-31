// Router configuration usando go_router para deep linking (Fase B)
//
// Soporta navegación declarativa y deep links para:
// - juantracker://nutrition/diary
// - juantracker://training/session/123
// - https://juantracker.app/nutrition/weight

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/entry_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/today_screen.dart';
import '../../features/diary/presentation/diary_screen.dart';
import '../../features/foods/presentation/food_search_unified_screen.dart';
import '../../features/foods/presentation/foods_screen.dart';
import '../../features/weight/presentation/weight_screen.dart';
import '../../features/summary/presentation/summary_screen.dart';

import '../../features/training/presentation/history_screen.dart';
import '../../features/training/presentation/training_routines_screen.dart';
import '../../features/training/presentation/training_library_screen.dart';
import '../../training/screens/training_session_screen.dart';
import '../../diet/screens/coach/coach_screen.dart';
import '../../diet/screens/coach/plan_setup_screen.dart';
import '../../diet/screens/coach/weekly_check_in_screen.dart';
import '../../core/onboarding/splash_wrapper.dart';
import '../../training/training_shell.dart';

/// Provider para acceder al router desde cualquier parte de la app
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

/// Clase estática con la configuración del router
class AppRouter {
  AppRouter._();

  // Nombres de rutas para navegación tipada
  static const String root = '/';
  static const String entry = '/entry';
  static const String nutrition = '/nutrition';
  static const String nutritionDiary = '/nutrition/diary';
  static const String nutritionFoods = '/nutrition/foods';
  static const String nutritionFoodSearch = '/nutrition/food-search';
  static const String nutritionExternalSearch = '/nutrition/external-search';
  static const String nutritionWeight = '/nutrition/weight';
  static const String nutritionSummary = '/nutrition/summary';

  static const String nutritionCoach = '/nutrition/coach';
  static const String nutritionCoachSetup = '/nutrition/coach/setup';
  static const String nutritionCoachCheckin = '/nutrition/coach/checkin';
  static const String training = '/training';
  static const String trainingHistory = '/training/history';
  static const String trainingRoutines = '/training/routines';
  static const String trainingLibrary = '/training/library';
  static const String trainingSession = '/training/session';
  static const String trainingSessionDetail = '/training/session/detail';
  
  // Helper para navegar a detalle de sesión (requiere objeto Sesion)
  static String trainingSessionDetailWithId(String id) => '/training/session/detail/$id';

  /// Helper para crear páginas con transición fade
  static CustomTransitionPage<void> _fadePage({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Router principal configurado con todas las rutas
  static final GoRouter router = GoRouter(
    initialLocation: root,
    debugLogDiagnostics: true,
    routes: [
      // Ruta raíz con splash wrapper
      GoRoute(
        path: root,
        builder: (context, state) => const SplashWrapper(
          child: EntryScreen(),
        ),
      ),

      // Entry screen (selector de modo)
      GoRoute(
        path: entry,
        builder: (context, state) => const EntryScreen(),
      ),

      // Today screen (vista unificada HOY) - FASE 6
      GoRoute(
        path: '/today',
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const TodayScreen(),
        ),
      ),

      // === NUTRICIÓN ===
      // Transición fade desde EntryScreen
      GoRoute(
        path: nutrition,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),

      GoRoute(
        path: nutritionDiary,
        builder: (context, state) => const DiaryScreen(),
      ),

      GoRoute(
        path: nutritionFoods,
        builder: (context, state) => const FoodsScreen(),
      ),

      GoRoute(
        path: nutritionFoodSearch,
        builder: (context, state) => const FoodSearchUnifiedScreen(),
      ),

      GoRoute(
        path: nutritionWeight,
        builder: (context, state) => const WeightScreen(),
      ),

      GoRoute(
        path: nutritionSummary,
        builder: (context, state) => const SummaryScreen(),
      ),

      // Coach Adaptativo
      GoRoute(
        path: nutritionCoach,
        builder: (context, state) => const CoachScreen(),
      ),

      GoRoute(
        path: nutritionCoachSetup,
        builder: (context, state) => const PlanSetupScreen(),
      ),

      GoRoute(
        path: nutritionCoachCheckin,
        builder: (context, state) => const WeeklyCheckInScreen(),
      ),

      // === ENTRENAMIENTO ===
      // Transición fade desde EntryScreen (usa TrainingShell internamente)
      GoRoute(
        path: training,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const TrainingShell(),
        ),
      ),

      GoRoute(
        path: trainingHistory,
        builder: (context, state) => const HistoryScreen(),
      ),

      GoRoute(
        path: trainingRoutines,
        builder: (context, state) => const TrainingRoutinesScreen(),
      ),

      GoRoute(
        path: trainingLibrary,
        builder: (context, state) => const TrainingLibraryScreen(),
      ),

      // Sesión de entrenamiento activa
      // Nota: TrainingSessionScreen no acepta sessionId, maneja su propio estado
      GoRoute(
        path: trainingSession,
        builder: (context, state) => const TrainingSessionScreen(),
      ),

      // Detalle de sesión completada
      // Requiere el objeto Sesion completo, no solo ID
      // Por ahora redirige a historial (deep link complejo requiere provider)
      GoRoute(
        path: trainingSessionDetail,
        builder: (context, state) => const HistoryScreen(),
      ),
    ],

    // Manejo de errores (ruta no encontrada)
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.path,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(root),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Extensiones útiles para navegación
extension GoRouterExtension on BuildContext {
  /// Navega a una ruta específica (reemplaza la ruta actual)
  void goTo(String location) => go(location);

  /// Navega a una ruta manteniendo el stack (push)
  void pushTo(String location) => push(location);

  /// Navega a nutrición
  void goToNutrition() => go(AppRouter.nutrition);

  /// Navega al diario
  void goToDiary() => go(AppRouter.nutritionDiary);

  /// Navega a los alimentos
  void goToFoods() => go(AppRouter.nutritionFoods);

  /// Navega a búsqueda de alimentos
  void goToFoodSearch() => push(AppRouter.nutritionFoodSearch);

  /// Navega a búsqueda externa (Open Food Facts)
  void goToExternalSearch({String? barcode}) {
    final uri = barcode != null
        ? '${AppRouter.nutritionExternalSearch}?barcode=$barcode'
        : AppRouter.nutritionExternalSearch;
    push(uri);
  }

  /// Navega a entrenamiento
  void goToTraining() => go(AppRouter.training);

  /// Navega al historial de entrenamiento
  void goToTrainingHistory() => go(AppRouter.trainingHistory);

  /// Navega a la pantalla de sesión de entrenamiento
  void goToTrainingSession() => go(AppRouter.trainingSession);

  /// Navega a la biblioteca de ejercicios
  void goToTrainingLibrary() => go(AppRouter.trainingLibrary);

  /// Navega a las rutinas
  void goToTrainingRoutines() => go(AppRouter.trainingRoutines);

  /// Navega al coach
  void goToCoach() => go(AppRouter.nutritionCoach);

  /// Navega al setup del coach (push)
  void goToCoachSetup() => push(AppRouter.nutritionCoachSetup);

  /// Navega al check-in semanal (push)
  void goToCoachCheckIn() => push(AppRouter.nutritionCoachCheckin);

  /// Navega a la pantalla de resumen
  void goToSummary() => go(AppRouter.nutritionSummary);

  /// Navega a la pantalla de peso
  void goToWeight() => go(AppRouter.nutritionWeight);

  /// Navega a Today Screen (vista HOY unificada)
  void goToToday() => go('/today');

  /// Vuelve atrás
  void goBack() => pop();
}
