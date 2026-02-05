import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_constants.dart';
import 'core/design_system/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/settings/theme_provider.dart';
import 'features/foods/services/food_database_loader.dart';

class JuanTrackerApp extends ConsumerStatefulWidget {
  const JuanTrackerApp({super.key});

  @override
  ConsumerState<JuanTrackerApp> createState() => _JuanTrackerAppState();
}

class _JuanTrackerAppState extends ConsumerState<JuanTrackerApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapFoodDatabaseInBackground());
    });
  }

  Future<void> _bootstrapFoodDatabaseInBackground() async {
    try {
      await ref
          .read(foodBootstrapControllerProvider.notifier)
          .bootstrapIfNeeded();
    } catch (e, stackTrace) {
      // No bloquea arranque: solo registrar para diagnóstico.
      debugPrint('[AppBootstrap] Food DB bootstrap failed: $e');
      debugPrint(stackTrace.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    // UX-005: Configurar system overlays para edge-to-edge
    final brightness =
        themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark)
        ? Brightness.light
        : Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

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
