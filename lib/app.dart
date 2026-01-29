import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_constants.dart';
import 'core/design_system/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/settings/theme_provider.dart';

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
