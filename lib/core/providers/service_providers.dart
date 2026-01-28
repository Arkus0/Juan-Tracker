import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/i_timer_service.dart';
import '../services/i_voice_input_service.dart';
import '../services/stub_timer_service.dart';
import '../services/stub_voice_input_service.dart';

final timerServiceProvider = Provider<ITimerService>((ref) {
  final service = StubTimerService();
  ref.onDispose(service.dispose);
  return service;
});

final voiceInputServiceProvider = Provider<IVoiceInputService>((ref) {
  return StubVoiceInputService();
});
