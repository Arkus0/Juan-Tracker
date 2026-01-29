import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_constants.dart';
import 'core/design_system/app_theme.dart';
import 'core/settings/theme_provider.dart';
import 'features/home/presentation/entry_screen.dart';
import 'core/onboarding/splash_wrapper.dart';

class JuanTrackerApp extends ConsumerWidget {
  const JuanTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildNutritionTheme(),
      darkTheme: buildTrainingTheme(),
      themeMode: themeMode,
      home: const SplashWrapper(child: EntryScreen()),
    );
  }
}
