import 'package:flutter/services.dart';

/// Sistema de haptics global para feedback tactil consistente
abstract class AppHaptics {
  /// Feedback ligero - Para interacciones sutiles
  static void light() => HapticFeedback.lightImpact();

  /// Feedback medio - Para acciones principales
  static void medium() => HapticFeedback.mediumImpact();

  /// Feedback fuerte - Para acciones importantes o errores
  static void heavy() => HapticFeedback.heavyImpact();

  /// Feedback de seleccion
  static void selection() => HapticFeedback.selectionClick();

  /// Vibracion - Para notificaciones importantes
  static void vibrate() => HapticFeedback.vibrate();

  /// Boton primario presionado
  static void buttonPressed() => medium();

  /// Accion exitosa completada
  static void success() {
    medium();
    Future.delayed(const Duration(milliseconds: 50), light);
  }

  /// Accion de error
  static void error() => heavy();

  /// Swipe completado
  static void swipe() => selection();

  /// Serie completada en entrenamiento
  static void setCompleted() {
    medium();
    Future.delayed(const Duration(milliseconds: 100), light);
  }

  /// Ejercicio completado
  static void exerciseCompleted() => vibrate();

  /// Timer finalizado
  static void timerFinished() {
    vibrate();
    Future.delayed(const Duration(milliseconds: 200), vibrate);
  }
}
