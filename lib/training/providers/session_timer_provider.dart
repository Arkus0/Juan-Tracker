import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'training_provider.dart';

/// Proveedor del tiempo transcurrido de la sesión.
/// 
/// Actualiza automáticamente cada segundo mientras haya una sesión activa.
/// Se basa en el `startTime` del TrainingState.
final sessionTimerProvider = StreamProvider<Duration>((ref) {
  final startTime = ref.watch(
    trainingSessionProvider.select((s) => s.startTime)
  );
  
  if (startTime == null) {
    return Stream.value(Duration.zero);
  }
  
  // Stream que emite el tiempo transcurrido cada segundo
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return DateTime.now().difference(startTime);
  });
});

/// Formatea una duración a formato legible HH:MM:SS
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Extiende Duration con formato corto
extension DurationFormatting on Duration {
  /// Formato corto: "45:30" o "1:15:30"
  String get formatted => formatDuration(this);
  
  /// Formato corto sin segundos: "45m" o "1h 15m"
  String get formattedShort {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
  
  /// Indica si la sesión lleva más de 1 hora (para alertas)
  bool get isLongSession => inMinutes >= 60;
  
  /// Indica si la sesión lleva más de 2 horas (para alertas de sobreentrenamiento)
  bool get isVeryLongSession => inMinutes >= 120;
}
