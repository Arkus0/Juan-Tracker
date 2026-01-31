import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_constants.dart';
import 'core/design_system/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/settings/theme_provider.dart';
import 'features/foods/presentation/database_loading_screen.dart';

class JuanTrackerApp extends ConsumerWidget {
  const JuanTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    // UX-005: Configurar system overlays para edge-to-edge
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

/// App con pantalla de carga de base de datos integrada
/// 
/// Muestra una pantalla de carga en el primer lanzamiento mientras
/// se importan los ~600,000 productos de Open Food Facts.
class JuanTrackerAppWithLoader extends ConsumerStatefulWidget {
  const JuanTrackerAppWithLoader({super.key});

  @override
  ConsumerState<JuanTrackerAppWithLoader> createState() => _JuanTrackerAppWithLoaderState();
}

class _JuanTrackerAppWithLoaderState extends ConsumerState<JuanTrackerAppWithLoader> {
  bool _databaseReady = false;

  @override
  Widget build(BuildContext context) {
    if (!_databaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildNutritionTheme(),
        home: DatabaseLoadingScreen(
          onComplete: () => setState(() => _databaseReady = true),
        ),
      );
    }

    return const JuanTrackerApp();
  }
}
