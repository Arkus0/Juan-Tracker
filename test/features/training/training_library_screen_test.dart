import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/features/training/presentation/training_library_screen.dart';
import 'package:juan_tracker/core/models/training_exercise.dart';
import 'package:juan_tracker/core/providers/exercise_providers.dart';

void main() {
  testWidgets('typing "banca" shows Press banca on top', (tester) async {
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

    final overrides = [
      filteredExercisesSourceProvider.overrideWithValue([
        pressBanca,
        pressInclinado,
        fondosBanco,
      ]),
      exerciseLibraryProvider.overrideWithValue(AsyncValue.data([
        pressBanca,
        pressInclinado,
        fondosBanco,
      ])),
    ];

    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const MaterialApp(home: Scaffold(body: TrainingLibraryScreen()))));
    await tester.pump();

    // Ensure initial list shows items
    expect(find.text('Press banca con barra'), findsOneWidget);

    // Enter text in the search TextField
    final textField = find.byType(TextField).first;
    await tester.enterText(textField, 'banca');
    await tester.pump(const Duration(milliseconds: 300));

    // Verify top item
    final firstTile = find.descendant(of: find.byType(ListView), matching: find.byType(Card)).first;
    expect(find.descendant(of: firstTile, matching: find.text('Press banca con barra')), findsOneWidget);

  });
}
