import 'package:flutter_test/flutter_test.dart';

import 'package:juan_tracker/core/models/training_ejercicio.dart';
import 'package:juan_tracker/core/models/training_serie_log.dart';

void main() {
  test('Ejercicio calculates maxWeight from completed sets only', () {
    final ejercicio = Ejercicio(
      id: 'e1',
      nombre: 'Press banca',
      logs: const [
        SerieLog(peso: 80, reps: 5, completed: true),
        SerieLog(peso: 100, reps: 1, completed: false),
        SerieLog(peso: 90, reps: 3, completed: true),
      ],
    );

    expect(ejercicio.completedSetsCount, 2);
    expect(ejercicio.maxWeight, 90);
  });
}
