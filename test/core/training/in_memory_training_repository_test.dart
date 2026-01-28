import 'package:flutter_test/flutter_test.dart';

import 'package:juan_tracker/core/models/training_sesion.dart';
import 'package:juan_tracker/core/repositories/in_memory_training_repository.dart';

void main() {
  test('in-memory repo saves, streams, and deletes sessions', () async {
    final repo = InMemoryTrainingRepository();
    final session = Sesion(
      id: 's1',
      fecha: DateTime(2026, 1, 1),
      durationSeconds: 1200,
      totalVolume: 1000,
      ejerciciosCompletados: const [],
    );

    final stream = repo.watchSessions();
    final expectation = expectLater(
      stream,
      emitsInOrder([
        predicate<List<Sesion>>((list) => list.isEmpty),
        predicate<List<Sesion>>(
          (list) => list.length == 1 && list.first.id == 's1',
        ),
        predicate<List<Sesion>>((list) => list.isEmpty),
      ]),
    );

    await repo.saveSession(session);
    await repo.deleteSession(session.id);
    await expectation;
  });
}
