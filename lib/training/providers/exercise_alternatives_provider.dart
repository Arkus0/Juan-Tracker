import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_exercise.dart';
import '../services/alternativas_service.dart';
import '../services/exercise_library_service.dart';

/// {@template exercise_alternatives_provider}
/// Provider para obtener alternativas de ejercicios basadas en grupos musculares.
/// 
/// Filtra ejercicios del catálogo completo que compartan al menos un grupo muscular
/// principal con el ejercicio original, excluyendo el ejercicio mismo.
/// 
/// Orden de prioridad:
/// 1. Alternativas definidas explícitamente en alternativas.json
/// 2. Fallback: ejercicios del mismo grupo muscular (limitado a 6)
/// {@endtemplate}

/// Provider que expone el servicio de alternativas inicializado
final _alternativasServiceProvider = Provider<AlternativasService>((ref) {
  return AlternativasService.instance;
});

/// Provider que expone la biblioteca de ejercicios
final _libraryServiceProvider = Provider<ExerciseLibraryService>((ref) {
  return ExerciseLibraryService.instance;
});

/// Provider familia para obtener alternativas de un ejercicio específico
/// 
/// Uso: ref.watch(exerciseAlternativesProvider(exerciseId: 123, excludeId: 123))
final exerciseAlternativesProvider = Provider.family<
  List<LibraryExercise>,
  ({int exerciseId, List<String> muscleGroups, String? equipment})
>((ref, params) {
  final service = ref.watch(_alternativasServiceProvider);
  final library = ref.watch(_libraryServiceProvider);
  
  // Si la biblioteca no está cargada, retornar lista vacía
  if (!library.isLoaded) return [];
  
  final allExercises = library.exercises;
  
  // 1. Intentar obtener alternativas definidas explícitamente
  var alternatives = service.getAlternativas(
    exerciseId: params.exerciseId,
    allExercises: allExercises,
  );
  
  // 2. Si no hay alternativas definidas o son pocas, usar fallback por grupos musculares
  if (alternatives.isEmpty) {
    alternatives = _findAlternativesByMuscles(
      allExercises: allExercises,
      muscleGroups: params.muscleGroups,
      excludeId: params.exerciseId,
      limit: 8,
    );
  }
  
  // 3. Priorizar por equipment similar si se proporciona
  if (params.equipment != null && alternatives.length > 1) {
    alternatives = _prioritizeByEquipment(
      alternatives: alternatives,
      preferredEquipment: params.equipment!,
    );
  }
  
  return alternatives;
});

/// Provider para obtener alternativas filtradas por equipment disponible
/// 
/// Uso típico: "El banco está ocupado, muéstrame opciones con mancuernas"
final exerciseAlternativesByEquipmentProvider = Provider.family<
  List<LibraryExercise>,
  ({
    int exerciseId,
    List<String> muscleGroups,
    String preferredEquipment,
    List<String> availableEquipment,
  })
>((ref, params) {
  final baseAlternatives = ref.watch(exerciseAlternativesProvider((
    exerciseId: params.exerciseId,
    muscleGroups: params.muscleGroups,
    equipment: params.preferredEquipment,
  )));
  
  // Filtrar solo equipment disponible
  return baseAlternatives
      .where((e) => params.availableEquipment.contains(e.equipment.toLowerCase()))
      .toList();
});

/// Busca alternativas basadas en grupos musculares compartidos
List<LibraryExercise> _findAlternativesByMuscles({
  required List<LibraryExercise> allExercises,
  required List<String> muscleGroups,
  required int excludeId,
  required int limit,
}) {
  if (muscleGroups.isEmpty) return [];
  
  // Normalizar grupos musculares para comparación
  final normalizedTargetMuscles = muscleGroups
      .map((m) => m.toLowerCase().trim())
      .toSet();
  
  // Puntuar cada ejercicio por coincidencia de músculos
  final scoredExercises = <_ScoredExercise>[];
  
  for (final exercise in allExercises) {
    if (exercise.id == excludeId) continue;
    
    final exerciseMuscles = exercise.muscles
        .map((m) => m.toLowerCase().trim())
        .toSet();
    
    // Calcular score: +2 por músculo principal compartido, +1 por secundario
    int score = 0;
    for (final muscle in normalizedTargetMuscles) {
      if (exerciseMuscles.contains(muscle)) {
        score += 2;
      }
    }
    
    // Añadir puntos por músculos secundarios compartidos
    final secondaryMuscles = exercise.secondaryMuscles
        .map((m) => m.toLowerCase().trim())
        .toSet();
    for (final muscle in normalizedTargetMuscles) {
      if (secondaryMuscles.contains(muscle)) {
        score += 1;
      }
    }
    
    if (score > 0) {
      scoredExercises.add(_ScoredExercise(exercise, score));
    }
  }
  
  // Ordenar por score descendente y tomar los primeros N
  scoredExercises.sort((a, b) => b.score.compareTo(a.score));
  
  return scoredExercises
      .take(limit)
      .map((e) => e.exercise)
      .toList();
}

/// Reordena alternativas priorizando el equipment preferido
List<LibraryExercise> _prioritizeByEquipment({
  required List<LibraryExercise> alternatives,
  required String preferredEquipment,
}) {
  final normalizedPreferred = preferredEquipment.toLowerCase().trim();
  
  return [...alternatives]..sort((a, b) {
    final aMatches = a.equipment.toLowerCase() == normalizedPreferred;
    final bMatches = b.equipment.toLowerCase() == normalizedPreferred;
    
    if (aMatches && !bMatches) return -1;
    if (!aMatches && bMatches) return 1;
    return 0;
  });
}

/// Clase auxiliar para puntuar ejercicios
class _ScoredExercise {
  final LibraryExercise exercise;
  final int score;
  
  _ScoredExercise(this.exercise, this.score);
}

/// Provider para verificar si un ejercicio tiene alternativas disponibles
final hasAlternativesProvider = Provider.family<bool, int>((ref, exerciseId) {
  final service = ref.watch(_alternativasServiceProvider);
  return service.hasAlternativas(exerciseId);
});
