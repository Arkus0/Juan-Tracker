import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';

import 'training/services/timer_audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // UX-005: Edge-to-edge rendering para Android 15+
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  // OPT-5: Inicializar en paralelo para reducir cold start ~20-50ms
  // DateFormat y SharedPreferences son independientes
  final initFutures = await Future.wait([
    initializeDateFormatting('es'),
    SharedPreferences.getInstance(),
  ]);
  
  final prefs = initFutures[1] as SharedPreferences;
  
  runApp(
    ProviderScope(
      overrides: getProviderOverrides(prefs),
      child: const JuanTrackerAppWithLoader(),
    ),
  );

  // Debug-only quick beep to validate native beep implementation
  if (kDebugMode) {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await TimerAudioService.instance.playLowBeep();
      } catch (e, stack) {
        debugPrint('[Main] Audio beep test failed: $e');
        debugPrint(stack.toString());
      }
    });
  }
}
