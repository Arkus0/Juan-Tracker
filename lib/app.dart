import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_constants.dart';
import 'core/design_system/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/settings/theme_provider.dart';
import 'features/foods/presentation/database_loading_screen.dart';
import 'features/foods/presentation/market_selection_screen.dart';
import 'features/foods/providers/market_providers.dart';
import 'features/foods/services/food_database_loader.dart';

class JuanTrackerApp extends ConsumerWidget {
  const JuanTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    final brightness = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && 
         MediaQuery.platformBrightnessOf(context) == Brightness.dark)
        ? Brightness.light
        : Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildNutritionTheme(),
      darkTheme: buildTrainingTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

/// Estados del flujo de onboarding
enum _OnboardingState {
  loading,           // Verificando estado
  selectMarket,      // Mostrar selección de mercado
  loadingDatabase,   // Cargando base de datos
  complete,          // Ir a la app
}

/// App con flujo de onboarding integrado
/// 
/// Flujo:
/// 1. Verificar si hay mercado seleccionado
/// 2. Si no: mostrar pantalla de selección de mercado
/// 3. Verificar si la base de datos del mercado está cargada
/// 4. Si no: mostrar pantalla de carga
/// 5. Ir a la app principal
class JuanTrackerAppWithLoader extends ConsumerStatefulWidget {
  const JuanTrackerAppWithLoader({super.key});

  @override
  ConsumerState<JuanTrackerAppWithLoader> createState() => _JuanTrackerAppWithLoaderState();
}

class _JuanTrackerAppWithLoaderState extends ConsumerState<JuanTrackerAppWithLoader> {
  _OnboardingState _state = _OnboardingState.loading;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Cargar mercado guardado
    await ref.read(selectedMarketProvider.notifier).loadSavedMarket();
    final hasMarket = await ref.read(selectedMarketProvider.notifier).hasMarketSelected();
    
    if (!hasMarket) {
      setState(() {
        _state = _OnboardingState.selectMarket;
        _initialized = true;
      });
      return;
    }

    // Verificar si la base de datos está cargada
    final market = ref.read(selectedMarketProvider);
    if (market != null) {
      final loader = ref.read(foodDatabaseLoaderProvider);
      final isLoaded = await loader.isDatabaseLoaded(market);
      
      if (isLoaded) {
        setState(() {
          _state = _OnboardingState.complete;
          _initialized = true;
        });
        return;
      }
    }

    // Necesita cargar base de datos
    setState(() {
      _state = _OnboardingState.loadingDatabase;
      _initialized = true;
    });
  }

  void _onMarketSelected() {
    setState(() {
      _state = _OnboardingState.loadingDatabase;
    });
  }

  void _onDatabaseLoaded() {
    setState(() {
      _state = _OnboardingState.complete;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      // Pantalla de splash mientras inicializa
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildNutritionTheme(),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    switch (_state) {
      case _OnboardingState.loading:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildNutritionTheme(),
          home: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );

      case _OnboardingState.selectMarket:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildNutritionTheme(),
          home: MarketSelectionScreen(
            onMarketSelected: _onMarketSelected,
          ),
        );

      case _OnboardingState.loadingDatabase:
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildNutritionTheme(),
          home: DatabaseLoadingScreen(
            onComplete: _onDatabaseLoaded,
          ),
        );

      case _OnboardingState.complete:
        return const JuanTrackerApp();
    }
  }
}
