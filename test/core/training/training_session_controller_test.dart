import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:juan_tracker/core/models/training_sesion.dart';
import 'package:juan_tracker/core/providers/database_provider.dart';
import 'package:juan_tracker/core/providers/training_session_controller.dart';
import 'package:juan_tracker/core/repositories/in_memory_training_repository.dart';

void main() {
  test('training controller handles add, undo, and finish', () async {
    final repo = InMemoryTrainingRepository();
    final container = ProviderContainer(
      overrides: [trainingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      trainingSessionControllerProvider.notifier,
    );
    controller.startSession(id: 's1');
    controller.addSet(
      ejercicioId: 'sentadilla',
      ejercicioNombre: 'Sentadilla',
      peso: 100,
      reps: 5,
    );
    controller.addSet(
      ejercicioId: 'sentadilla',
      ejercicioNombre: 'Sentadilla',
      peso: 110,
      reps: 3,
    );

    var state = container.read(trainingSessionControllerProvider);
    expect(state.activeSession, isNotNull);
    expect(state.activeSession!.completedSetsCount, 2);
    expect(state.activeSession!.totalVolume, closeTo(830.0, 0.01));

    controller.undoLastSet();
    state = container.read(trainingSessionControllerProvider);
    expect(state.activeSession!.completedSetsCount, 1);
    expect(state.activeSession!.totalVolume, closeTo(500.0, 0.01));

    await controller.finishSession();
    state = container.read(trainingSessionControllerProvider);
    expect(state.activeSession, isNull);
    expect(state.lastSession, isNotNull);

    final saved = await repo.watchSessions().firstWhere(
      (list) => list.isNotEmpty,
    );
    expect(saved.first.id, 's1');
    expect(saved.first, isA<Sesion>());
  });
}
