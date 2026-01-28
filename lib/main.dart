import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'package:flutter/foundation.dart';
import 'training/services/timer_audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure DateFormat locale data is available (used throughout the app)
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: JuanTrackerApp()));

  // Debug-only quick beep to validate native beep implementation
  if (kDebugMode) {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await TimerAudioService.instance.playLowBeep();
      } catch (_) {}
    });
  }
}
