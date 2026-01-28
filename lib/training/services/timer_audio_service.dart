import 'native_beep_service.dart';

/// Servicio singleton para reproducir beeps del timer.
///
/// 🔇 AUDIO FOCUS FIX:
/// Este servicio ahora delega al NativeBeepService que usa ToneGenerator
/// de Android con STREAM_NOTIFICATION. Esto permite que los beeps del timer
/// suenen SIN pausar la música del usuario (Spotify, YouTube Music, etc.).
///
/// Antes:
/// - Usaba just_audio (ExoPlayer/Media3) que solicita Audio Focus
/// - Al reproducir un beep, pausaba la música del usuario
///
/// Ahora:
/// - Usa ToneGenerator nativo con STREAM_NOTIFICATION
/// - NO solicita Audio Focus
/// - Los beeps son tipo "notificación" - cortos y no intrusivos
/// - La música del usuario continúa sin interrupción
class TimerAudioService {
  static final TimerAudioService _instance = TimerAudioService._internal();
  factory TimerAudioService() => _instance;
  TimerAudioService._internal();

  static TimerAudioService get instance => _instance;

  dynamic _nativeBeep = NativeBeepService.instance;
  bool _isInitialized = false;

  // Timestamp of last final beep played (ms since epoch)
  int _lastFinalBeepAt = 0;

  /// Inicializa el servicio de audio.
  /// Ahora es un no-op ya que el servicio nativo no requiere inicialización.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Reproduce un beep de baja intensidad (últimos 10-6 segundos)
  Future<void> playLowBeep() async {
    await _nativeBeep.playLowBeep();
  }

  /// Reproduce un beep de media intensidad (últimos 5-3 segundos)
  Future<void> playMediumBeep() async {
    await _nativeBeep.playMediumBeep();
  }

  /// Reproduce un beep de alta intensidad (últimos 2-1 segundos)
  Future<void> playHighBeep() async {
    await _nativeBeep.playHighBeep();
  }

  /// Reproduce el beep final (doble tono)
  /// Evita duplicados si se llama repetidamente en un corto intervalo.
  Future<void> playFinalBeep() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // If a final beep was played less than 2000ms ago, ignore this request
    if (now - _lastFinalBeepAt < 2000) return;
    _lastFinalBeepAt = now;

    // Use notification stream by default to avoid taking audio focus
    await _nativeBeep.playFinalBeep(useMusicStream: false);
  }

  /// Override native beep service for tests (visible for testing)
  /// Test helper to override native beep implementation. Accepts a dynamic
  /// so tests can provide lightweight fakes without extending the singleton.
  // Test helper to override native beep implementation. Intended for tests only.
  void setNativeBeepForTesting(dynamic service) {
    _nativeBeep = service;
  }

  /// Libera recursos
  Future<void> dispose() async {
    await _nativeBeep.dispose();
    _isInitialized = false;
  }
}
