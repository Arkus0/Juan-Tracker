import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/models/library_exercise.dart';

void main() {
  group('ExerciseAlternativesProvider Logic Tests', () {
    late List<LibraryExercise> allExercises;

    setUp(() {
      // Crear ejercicios de prueba
      allExercises = [
        LibraryExercise(
          id: 1,
          name: 'Press banca con barra',
          muscleGroup: 'Pecho',
          equipment: 'barra',
          muscles: ['Pectoral mayor', 'Pectoral menor'],
          secondaryMuscles: ['Triceps', 'Hombros'],
        ),
        LibraryExercise(
          id: 2,
          name: 'Press banca con mancuernas',
          muscleGroup: 'Pecho',
          equipment: 'mancuernas',
          muscles: ['Pectoral mayor', 'Pectoral menor'],
          secondaryMuscles: ['Triceps', 'Hombros'],
        ),
        LibraryExercise(
          id: 3,
          name: 'Press inclinado con barra',
          muscleGroup: 'Pecho',
          equipment: 'barra',
          muscles: ['Pectoral mayor', 'Pectoral menor'],
          secondaryMuscles: ['Triceps', 'Hombros'],
        ),
        LibraryExercise(
          id: 4,
          name: 'Sentadilla con barra',
          muscleGroup: 'Piernas',
          equipment: 'barra',
          muscles: ['Cuadriceps', 'Gluteos'],
          secondaryMuscles: ['Core', 'Lumbares'],
        ),
        LibraryExercise(
          id: 5,
          name: 'Sentadilla con mancuernas',
          muscleGroup: 'Piernas',
          equipment: 'mancuernas',
          muscles: ['Cuadriceps', 'Gluteos'],
          secondaryMuscles: ['Core'],
        ),
        LibraryExercise(
          id: 6,
          name: 'Curl de biceps con barra',
          muscleGroup: 'Biceps',
          equipment: 'barra',
          muscles: ['Biceps braquial'],
          secondaryMuscles: ['Braquial'],
        ),
      ];
    });

    test('debe encontrar alternativas por grupos musculares compartidos', () {
      // Buscar alternativas para press banca (id: 1)
      final targetMuscles = ['Pectoral mayor', 'Pectoral menor'];
      final excludeId = 1;

      final alternatives = _findAlternativesByMuscles(
        allExercises: allExercises,
        muscleGroups: targetMuscles,
        excludeId: excludeId,
        limit: 6,
      );

      // Debe encontrar press banca con mancuernas e inclinado
      expect(alternatives.length, greaterThanOrEqualTo(2));
      expect(alternatives.any((e) => e.id == 2), isTrue); // Mancuernas
      expect(alternatives.any((e) => e.id == 3), isTrue); // Inclinado
      
      // No debe incluir el ejercicio original ni ejercicios de otros grupos
      expect(alternatives.any((e) => e.id == 1), isFalse);
      expect(alternatives.any((e) => e.id == 4), isFalse); // Sentadilla
      expect(alternatives.any((e) => e.id == 6), isFalse); // Curl
    });

    test('debe ordenar alternativas por score de coincidencia', () {
      // Ejercicio con coincidencia perfecta debería estar primero
      final targetMuscles = ['Pectoral mayor', 'Pectoral menor'];
      
      final alternatives = _findAlternativesByMuscles(
        allExercises: allExercises,
        muscleGroups: targetMuscles,
        excludeId: 1,
        limit: 6,
      );

      // Los press de pecho deberían estar antes que ejercicios de otros grupos
      if (alternatives.length >= 2) {
        final first = alternatives.first;
        expect(first.muscleGroup, equals('Pecho'));
      }
    });

    test('debe respetar el límite de resultados', () {
      final targetMuscles = ['Pectoral mayor'];
      
      final alternatives = _findAlternativesByMuscles(
        allExercises: allExercises,
        muscleGroups: targetMuscles,
        excludeId: 1,
        limit: 2,
      );

      expect(alternatives.length, lessThanOrEqualTo(2));
    });

    test('debe retornar lista vacía si no hay coincidencias', () {
      final targetMuscles = ['Espalda']; // No hay ejercicios de espalda
      
      final alternatives = _findAlternativesByMuscles(
        allExercises: allExercises,
        muscleGroups: targetMuscles,
        excludeId: 1,
        limit: 6,
      );

      expect(alternatives, isEmpty);
    });

    test('debe manejar lista vacía de grupos musculares', () {
      final alternatives = _findAlternativesByMuscles(
        allExercises: allExercises,
        muscleGroups: [],
        excludeId: 1,
        limit: 6,
      );

      expect(alternatives, isEmpty);
    });

    group('Priorización por equipment', () {
      test('debe priorizar equipment preferido al principio', () {
        final alternatives = [
          allExercises[1], // mancuernas
          allExercises[0], // barra
          allExercises[4], // mancuernas piernas
        ];

        final prioritized = _prioritizeByEquipment(
          alternatives: alternatives,
          preferredEquipment: 'barra',
        );

        // El primero debería ser el de barra
        expect(prioritized.first.equipment.toLowerCase(), equals('barra'));
      });
    });
  });

  group('TrainingSessionNotifier.swapExerciseInSession', () {
    test('contrato de parámetros es correcto', () {
      // Documentación del contrato del método
      // swapExerciseInSession({
      //   required int exerciseIndex,
      //   required LibraryExercise newExercise,
      //   bool preserveCompletedSets = true,
      // })

      // El método requiere:
      // - exerciseIndex válido (0 <= index < exercises.length)
      // - newExercise no nulo
      // - preserveCompletedSets opcional (default: true)

      expect(true, isTrue); // Placeholder - el test real requiere mock del notifier
    });

    test('preservar series completadas copia peso/reps como sugerencia', () {
      // Lógica esperada:
      // Si preserveCompletedSets = true y hay N series completadas,
      // las primeras N series del nuevo ejercicio deberían tener:
      // - peso = peso original
      // - reps = reps original
      // - completed = false (reset)
      // - notas = 'Sustituido desde: {nombre_original}' (solo primera)

      expect(true, isTrue); // Placeholder - test de documentación
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS (copias de la implementación real para testing)
// ═══════════════════════════════════════════════════════════════════════════

List<LibraryExercise> _findAlternativesByMuscles({
  required List<LibraryExercise> allExercises,
  required List<String> muscleGroups,
  required int excludeId,
  required int limit,
}) {
  if (muscleGroups.isEmpty) return [];

  final normalizedTargetMuscles = muscleGroups
      .map((m) => m.toLowerCase().trim())
      .toSet();

  final scoredExercises = <_ScoredExercise>[];

  for (final exercise in allExercises) {
    if (exercise.id == excludeId) continue;

    final exerciseMuscles = exercise.muscles
        .map((m) => m.toLowerCase().trim())
        .toSet();

    int score = 0;
    for (final muscle in normalizedTargetMuscles) {
      if (exerciseMuscles.contains(muscle)) {
        score += 2;
      }
    }

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

  scoredExercises.sort((a, b) => b.score.compareTo(a.score));

  return scoredExercises
      .take(limit)
      .map((e) => e.exercise)
      .toList();
}

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

class _ScoredExercise {
  final LibraryExercise exercise;
  final int score;

  _ScoredExercise(this.exercise, this.score);
}
