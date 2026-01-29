import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test/test.dart';
import 'package:juan_tracker/core/models/training_exercise.dart';
import 'package:juan_tracker/core/providers/exercise_providers.dart';

void main() {
  group('filteredExercisesProvider', () {
    final pressBanca = TrainingExercise(
      id: 'press_banca',
      nombre: 'Press banca con barra',
      grupoMuscular: 'Pecho',
      musculosSecundarios: const [],
      equipo: 'Barra',
      nivel: 'basico',
      descripcion: '',
    );

    final pressInclinado = TrainingExercise(
      id: 'press_inclinado',
      nombre: 'Press inclinado con mancuernas',
      grupoMuscular: 'Pecho',
      musculosSecundarios: const [],
      equipo: 'Mancuernas',
      nivel: 'basico',
      descripcion: '',
    );

    final fondosBanco = TrainingExercise(
      id: 'fondos_banco',
      nombre: 'Fondos en banco',
      grupoMuscular: 'Pecho',
      musculosSecundarios: const [],
      equipo: 'Banco',
      nivel: 'basico',
      descripcion: '',
    );

    test('query "banca" returns press banca as top result', () {
      final container = ProviderContainer(overrides: [
        filteredExercisesSourceProvider.overrideWithValue([
          pressBanca,
          pressInclinado,
          fondosBanco,
        ]),
      ]);

      container.read(exerciseSearchQueryProvider.notifier).setQuery('banca');
      final filtered = container.read(filteredExercisesProvider);
      expect(filtered.map((e) => e.nombre), contains('Press banca con barra'));
      expect(filtered.first.nombre, equals('Press banca con barra'));

      container.dispose();
    });

    test('query "banco" returns banco related items', () {
      final container = ProviderContainer(overrides: [
        filteredExercisesSourceProvider.overrideWithValue([
          pressBanca,
          pressInclinado,
          fondosBanco,
        ]),
      ]);

      container.read(exerciseSearchQueryProvider.notifier).setQuery('banco');
      final filtered = container.read(filteredExercisesProvider);
      final names = filtered.map((e) => e.nombre).toList();
      expect(names, containsAll(['Press banca con barra', 'Fondos en banco']));
      container.dispose();
    });
  });
}
