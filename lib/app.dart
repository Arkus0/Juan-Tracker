import 'package:flutter/material.dart';

import 'core/app_constants.dart';
import 'features/home/presentation/home_screen.dart';

class JuanTrackerApp extends StatelessWidget {
  const JuanTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
