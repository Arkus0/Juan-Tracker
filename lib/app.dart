import 'package:flutter/material.dart';
import 'core/app_constants.dart';
import 'core/design_system/app_theme.dart';
import 'features/home/presentation/entry_screen.dart';

class JuanTrackerApp extends StatelessWidget {
  const JuanTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // Tema principal para Nutricion (claro)
      theme: buildNutritionTheme(),
      // Tema oscuro para Entrenamiento
      darkTheme: buildTrainingTheme(),
      // Usamos light como default para la seccion de nutricion
      themeMode: ThemeMode.light,
      home: const EntryScreen(),
    );
  }
}
