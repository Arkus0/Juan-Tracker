// Router configuration usando go_router para deep linking (Fase B)
//
// Soporta navegación declarativa y deep links para:
// - juantracker://nutrition/diary
// - juantracker://training/session/123
// - https://juantracker.app/nutrition/weight

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/entry_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/today_screen.dart';
import '../../features/foods/presentation/food_search_unified_screen.dart';
import '../../features/foods/presentation/foods_screen.dart';
import '../../features/home/providers/home_providers.dart';

import '../../training/models/sesion.dart';
import '../../training/providers/analysis_provider.dart';
import '../../training/providers/main_provider.dart';
import '../../training/providers/training_provider.dart';
import '../../training/screens/search_exercise_screen.dart';
import '../../training/screens/session_detail_screen.dart';
import '../../training/screens/training_session_screen.dart';
import '../../diet/screens/coach/plan_setup_screen.dart';
import '../../diet/screens/coach/weekly_check_in_screen.dart';
import '../../diet/screens/macro_cycle_screen.dart';
import '../../diet/screens/recipe_list_screen.dart';
import '../../diet/screens/recipe_editor_screen.dart';
import '../../diet/screens/search_benchmark_screen.dart';
import '../../core/onboarding/splash_wrapper.dart';
import '../../training/training_shell.dart';
import '../../features/settings/presentation/body_progress_screen.dart';

/// Provider para acceder al router desde cualquier parte de la app
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

final trainingSessionByIdProvider = FutureProvider.family<Sesion?, String>((
  ref,
  sessionId,
) async {
  final repository = ref.watch(trainingRepositoryProvider);
  return repository.getSesionById(sessionId);
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
  static const String nutritionMacroCycle = '/nutrition/macro-cycle';
  static const String nutritionRecipes = '/nutrition/recipes';
  static const String nutritionRecipeNew = '/nutrition/recipes/new';
  static const String nutritionRecipeEdit = '/nutrition/recipes/:id';
  static const String training = '/training';
  static const String trainingHistory = '/training/history';
  static const String trainingRoutines = '/training/routines';
  static const String trainingLibrary = '/training/library';
  static const String trainingAnalysis = '/training/analysis';
  static const String trainingSettings = '/training/settings';
  static const String trainingSession = '/training/session';
  static const String trainingSessionDetail = '/training/session/detail';

  static const String bodyProgress = '/body-progress';

  // Debug routes (only available in debug mode)
  static const String debugSearchBenchmark = '/debug/search-benchmark';

  /// Helper para crear páginas con transición fade
  static CustomTransitionPage<void> _fadePage({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
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
        builder: (context, state) => const SplashWrapper(child: EntryScreen()),
      ),

      // Entry screen (selector de modo)
      GoRoute(path: entry, builder: (context, state) => const EntryScreen()),

      // Today screen (vista unificada HOY) - FASE 6
      GoRoute(
        path: '/today',
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const TodayScreen()),
      ),

      // === NUTRICIÓN ===
      // Transición fade desde EntryScreen
      GoRoute(
        path: nutrition,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const HomeScreen()),
      ),

      GoRoute(
        path: nutritionDiary,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const _NutritionTabEntry(tab: HomeTab.diary),
        ),
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
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const _NutritionTabEntry(tab: HomeTab.weight),
        ),
      ),

      GoRoute(
        path: nutritionSummary,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const _NutritionTabEntry(tab: HomeTab.summary),
        ),
      ),

      // Coach Adaptativo
      GoRoute(
        path: nutritionCoach,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const _NutritionTabEntry(tab: HomeTab.coach),
        ),
      ),

      GoRoute(
        path: nutritionCoachSetup,
        builder: (context, state) => const PlanSetupScreen(),
      ),

      GoRoute(
        path: nutritionCoachCheckin,
        builder: (context, state) => const WeeklyCheckInScreen(),
      ),

      // Ciclado de macros
      GoRoute(
        path: nutritionMacroCycle,
        builder: (context, state) => const MacroCycleScreen(),
      ),

      // Recetas
      GoRoute(
        path: nutritionRecipes,
        builder: (context, state) => const RecipeListScreen(),
      ),
      GoRoute(
        path: nutritionRecipeNew,
        builder: (context, state) => const RecipeEditorScreen(),
      ),
      GoRoute(
        path: '/nutrition/recipes/:id',
        builder: (context, state) => RecipeEditorScreen(
          recipeId: state.pathParameters['id'],
        ),
      ),

      // === DEBUG ROUTES (only in debug mode) ===
      if (kDebugMode)
        GoRoute(
          path: debugSearchBenchmark,
          builder: (context, state) => const SearchBenchmarkScreen(),
        ),

      // === PROGRESO CORPORAL ===
      GoRoute(
        path: bodyProgress,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const BodyProgressScreen(),
        ),
      ),

      // === ENTRENAMIENTO ===
      // Transición fade desde EntryScreen (usa TrainingShell internamente)
      GoRoute(
        path: training,
        pageBuilder: (context, state) =>
            _fadePage(key: state.pageKey, child: const TrainingShell()),
      ),

      GoRoute(
        path: trainingHistory,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const _TrainingAnalysisEntry(),
        ),
      ),

      GoRoute(
        path: trainingRoutines,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const _TrainingTabEntry(index: 0),
        ),
      ),

      GoRoute(
        path: trainingLibrary,
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'];
          return SearchExerciseScreen(isPickerMode: mode == 'picker');
        },
      ),

      GoRoute(
        path: trainingAnalysis,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const _TrainingTabEntry(index: 2),
        ),
      ),

      GoRoute(
        path: trainingSettings,
        pageBuilder: (context, state) => _fadePage(
          key: state.pageKey,
          child: const _TrainingTabEntry(index: 3),
        ),
      ),

      // Sesión de entrenamiento activa
      // Transición "expand into battle mode": scale + slide-up + fade
      GoRoute(
        path: trainingSession,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const TrainingSessionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Scale desde 0.92 → 1.0 (efecto "expandir")
            final scale = Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
            // Slide-up sutil
            final slideUp = Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
            return SlideTransition(
              position: slideUp,
              child: ScaleTransition(
                scale: scale,
                child: FadeTransition(opacity: animation, child: child),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        ),
      ),

      // Detalle de sesión completada
      // Requiere el objeto Sesion completo, no solo ID
      GoRoute(
        path: trainingSessionDetail,
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is Sesion) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: SessionDetailScreen(sesion: extra),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 300),
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const _MissingSessionDetailScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),

      // Detalle de sesión completada por ID (deep link estable)
      GoRoute(
        path: '$trainingSessionDetail/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'];
          if (sessionId == null || sessionId.isEmpty) {
            return const _MissingSessionDetailScreen();
          }
          return _SessionDetailByIdScreen(sessionId: sessionId);
        },
      ),
    ],

    // Manejo de errores (ruta no encontrada)
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.path,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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

  /// Navega al detalle de sesión (push con extra)
  void pushToTrainingSessionDetail(Sesion sesion) =>
      push(AppRouter.trainingSessionDetail, extra: sesion);

  /// Navega al detalle por ID (útil para deep links estables).
  void goToTrainingSessionDetailById(String sessionId) =>
      push('${AppRouter.trainingSessionDetail}/$sessionId');

  /// Navega a la biblioteca de ejercicios
  void goToTrainingLibrary() => go(AppRouter.trainingLibrary);

  /// Navega a biblioteca en modo selector (retorna ejercicio al hacer pop).
  void goToTrainingLibraryPicker() =>
      go('${AppRouter.trainingLibrary}?mode=picker');

  /// Navega a las rutinas
  void goToTrainingRoutines() => go(AppRouter.trainingRoutines);

  /// Navega a análisis de entrenamiento
  void goToTrainingAnalysis() => go(AppRouter.trainingAnalysis);

  /// Navega a ajustes de entrenamiento
  void goToTrainingSettings() => go(AppRouter.trainingSettings);

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

  /// Navega a la pantalla de progreso corporal (medidas + fotos)
  void goToBodyProgress() => push(AppRouter.bodyProgress);

  /// Vuelve atrás
  void goBack() => pop();
}

class _MissingSessionDetailScreen extends StatelessWidget {
  const _MissingSessionDetailScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de sesión')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sesión no encontrada. Abre el historial y selecciona una sesión.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _SessionDetailByIdScreen extends ConsumerWidget {
  final String sessionId;

  const _SessionDetailByIdScreen({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(trainingSessionByIdProvider(sessionId));

    return sessionAsync.when(
      data: (session) {
        if (session == null) {
          return const _MissingSessionDetailScreen();
        }
        return SessionDetailScreen(sesion: session);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Detalle de sesión')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const _MissingSessionDetailScreen(),
    );
  }
}

class _NutritionTabEntry extends ConsumerStatefulWidget {
  final HomeTab tab;

  const _NutritionTabEntry({required this.tab});

  @override
  ConsumerState<_NutritionTabEntry> createState() => _NutritionTabEntryState();
}

class _NutritionTabEntryState extends ConsumerState<_NutritionTabEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeTabProvider.notifier).setTab(widget.tab);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

class _TrainingTabEntry extends ConsumerStatefulWidget {
  final int index;

  const _TrainingTabEntry({required this.index});

  @override
  ConsumerState<_TrainingTabEntry> createState() => _TrainingTabEntryState();
}

class _TrainingTabEntryState extends ConsumerState<_TrainingTabEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).setIndex(widget.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const TrainingShell();
  }
}

class _TrainingAnalysisEntry extends ConsumerStatefulWidget {
  const _TrainingAnalysisEntry();

  @override
  ConsumerState<_TrainingAnalysisEntry> createState() =>
      _TrainingAnalysisEntryState();
}

class _TrainingAnalysisEntryState
    extends ConsumerState<_TrainingAnalysisEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).setIndex(2);
      ref.read(analysisTabIndexProvider.notifier).setIndex(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const TrainingShell();
  }
}
