import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_constants.dart';
import 'features/home/presentation/entry_screen.dart';

class JuanTrackerApp extends StatelessWidget {
  const JuanTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFDA5A2A);
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F3EE),
        textTheme: GoogleFonts.oswaldTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const EntryScreen(),
    );
  }
}
