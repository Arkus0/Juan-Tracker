import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/features/exercises/search/exercise_search_engine.dart';
import 'package:juan_tracker/training/models/library_exercise.dart';

void main() {
  group('normalize/tokenize', () {
    test('normalize removes diacritics and trims/lowercases', () {
      expect(normalize('Press Báncá  '), equals('press banca'));
      expect(normalize(' Press, banca!'), equals('press banca'));
    });

    test('tokenize removes stopwords and splits tokens', () {
      expect(tokenize('Press de banca'), equals(['press', 'banca']));
      expect(tokenize('Press banca con barra'), contains('press'));
    });
  });

  group('ExerciseSearchEngine', () {
    final pressBanca = LibraryExercise(
      id: 1,
      name: 'Press banca con barra',
      muscleGroup: 'Pecho',
      equipment: 'Barra',
    );

    final pressInclinado = LibraryExercise(
      id: 2,
      name: 'Press inclinado con mancuernas',
      muscleGroup: 'Pecho',
      equipment: 'Mancuernas',
    );

    final fondosBanco = LibraryExercise(
      id: 3,
      name: 'Fondos en banco',
      muscleGroup: 'Pecho',
      equipment: 'Banco',
    );

    final engine = const ExerciseSearchEngine();

    test('query "banca" returns press banca', () {
      final index = ExerciseSearchIndex.build([pressBanca, pressInclinado, fondosBanco]);
      final results = engine.searchWithIndex('banca', index, limit: 10);
      final names = results.map((e) => e.name).toList();
      expect(names, contains('Press banca con barra'));
      // Press banca should be top result
      expect(names.first, equals('Press banca con barra'));
    });

    test('query "banco" returns banco-related exercises (press banca and fondos en banco)', () {
      final index = ExerciseSearchIndex.build([pressBanca, pressInclinado, fondosBanco]);
      final results = engine.searchWithIndex('banco', index, limit: 10);
      final names = results.map((e) => e.name).toList();
      expect(names, containsAll(['Press banca con barra', 'Fondos en banco']));
    });
  });
}
