import 'package:flutter/material.dart';

/// Colores asignados a cada grupo muscular para identificación visual rápida.
///
/// Usa colores distintivos y consistentes en toda la app.
class ExerciseColors {
  // Paleta de colores por grupo muscular
  static const Color pecho = Color(0xFFE53935);           // Rojo
  static const Color espalda = Color(0xFF43A047);         // Verde
  static const Color piernas = Color(0xFF1E88E5);         // Azul
  static const Color hombros = Color(0xFFFDD835);         // Amarillo/Dorado
  static const Color biceps = Color(0xFF8E24AA);          // Púrpura
  static const Color triceps = Color(0xFFFF9800);         // Naranja
  static const Color core = Color(0xFF00ACC1);            // Cyan
  static const Color cardio = Color(0xFF78909C);          // Gris azulado
  static const Color antebrazo = Color(0xFF795548);       // Marrón
  static const Color gemelos = Color(0xFFEC407A);         // Rosa
  static const Color cuello = Color(0xFF5E35B1);          // Púrpura oscuro
  static const Color fullBody = Color(0xFF3949AB);        // Índigo
  static const Color otros = Color(0xFF607D8B);           // Gris

  /// Obtiene el color para un grupo muscular.
  static Color forMuscleGroup(String? muscleGroup) {
    if (muscleGroup == null) return otros;
    
    final normalized = muscleGroup.toLowerCase().trim();
    
    return switch (normalized) {
      // Pecho
      'pecho' || 'chest' || 'pectorales' || 'pectoral' => pecho,
      
      // Espalda
      'espalda' || 'back' || 'dorsales' || 'lats' || 'trapecio' || 'traps' || 
      'romboides' || 'infraespinoso' || 'deltoides posterior' => espalda,
      
      // Piernas
      'piernas' || 'legs' || 'cuadriceps' || 'quads' || 'femoral' || 
      'hamstrings' || 'isquiotibiales' || 'gluteos' || 'glutes' || 
      'aductores' || 'abductores' || 'hip' || 'cadera' => piernas,
      
      // Hombros
      'hombros' || 'shoulders' || 'deltoides' || 'delts' || 
      'deltoides anterior' || 'deltoides lateral' => hombros,
      
      // Bíceps
      'biceps' || 'bíceps' || 'antebrazo' || 'forearms' => biceps,
      
      // Tríceps
      'triceps' || 'tríceps' || 'brazo' || 'arm' => triceps,
      
      // Core
      'abdomen' || 'abdominales' || 'abs' || 'core' || 'oblicuos' || 
      ' lumbar' || 'lumbares' || 'lower back' => core,
      
      // Cardio
      'cardio' || 'aerobico' || 'aeróbico' || 'hiit' => cardio,
      
      // Gemelos
      'gemelos' || 'calves' || 'pantorrilla' || 'soleo' => gemelos,
      
      // Cuello
      'cuello' || 'neck' => cuello,
      
      // Full body
      'cuerpo completo' || 'full body' || 'total body' || 'compound' => fullBody,
      
      // Por defecto
      _ => otros,
    };
  }

  /// Obtiene el icono para un grupo muscular.
  static IconData iconFor(String? muscleGroup) {
    if (muscleGroup == null) return Icons.fitness_center;
    
    final normalized = muscleGroup.toLowerCase().trim();
    
    return switch (normalized) {
      'pecho' || 'chest' || 'pectorales' => Icons.favorite,
      'espalda' || 'back' => Icons.keyboard_backspace,
      'piernas' || 'legs' || 'cuadriceps' || 'femoral' => Icons.directions_walk,
      'hombros' || 'shoulders' || 'deltoides' => Icons.accessibility_new,
      'biceps' || 'bíceps' => Icons.arrow_upward,
      'triceps' || 'tríceps' => Icons.arrow_downward,
      'abdomen' || 'abdominales' || 'abs' || 'core' => Icons.circle,
      'cardio' => Icons.directions_run,
      'gemelos' || 'calves' => Icons.directions_walk,
      _ => Icons.fitness_center,
    };
  }

  /// Obtiene el color con opacidad para backgrounds.
  static Color backgroundFor(String? muscleGroup, {double opacity = 0.15}) {
    return forMuscleGroup(muscleGroup).withAlpha((opacity * 255).round());
  }
}

/// Extensión para facilitar el uso en LibraryExercise
extension LibraryExerciseColors on dynamic {
  Color get muscleColor => ExerciseColors.forMuscleGroup(
    this is Map ? this['muscleGroup'] : null,
  );
  
  IconData get muscleIcon => ExerciseColors.iconFor(
    this is Map ? this['muscleGroup'] : null,
  );
}
