import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'diet/providers/reminder_providers.dart';
import 'diet/services/diet_reminder_service.dart';

import 'training/services/timer_audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // UX-005: Edge-to-edge rendering para Android 15+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // OPT-5: Inicializar en paralelo para reducir cold start ~20-50ms
  // DateFormat y SharedPreferences son independientes
  final initFutures = await Future.wait([
    initializeDateFormatting('es'),
    SharedPreferences.getInstance(),
  ]);

  final prefs = initFutures[1] as SharedPreferences;

  // Inicializar servicio de recordatorios de dieta (timezone + canal)
  await DietReminderService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: getProviderOverrides(prefs),
      child: const JuanTrackerAppWithLoader(),
    ),
  );

  // Reprogramar recordatorios activos sin bloquear el primer frame.
  unawaited(_rescheduleDietRemindersInBackground(prefs));

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

Future<void> _rescheduleDietRemindersInBackground(
  SharedPreferences prefs,
) async {
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  try {
    await container.read(dietRemindersProvider.notifier).rescheduleAll();
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint('[Main] Reminder reschedule failed: $e');
      debugPrint(stack.toString());
    }
  } finally {
    container.dispose();
  }
}
