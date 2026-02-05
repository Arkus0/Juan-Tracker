import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/models/ejercicio.dart';
import 'package:juan_tracker/training/models/serie_log.dart';
import 'package:juan_tracker/training/models/sesion.dart';
import 'package:juan_tracker/training/providers/deload_alerts_provider.dart';
import 'package:juan_tracker/training/providers/training_provider.dart';

void main() {
  group('deloadAlertsProvider', () {
    test(
      'no crashea y detecta alerta crítica para tendencia descendente',
      () async {
        final sessions = _buildSessionsForExercise(
          exerciseName: 'Press banca',
          weights: [100, 99, 98, 97],
          startDate: DateTime(2026, 1, 1),
        );

        final container = ProviderContainer(
          overrides: [
            sesionesHistoryStreamProvider.overrideWithValue(
              AsyncValue.data(sessions),
            ),
          ],
        );
        addTearDown(container.dispose);

        final alerts = container.read(deloadAlertsProvider);

        expect(alerts, isNotEmpty);
        expect(alerts.first.exerciseName, 'Press banca');
        expect(alerts.first.severity, AlertSeverity.critical);
      },
    );

    test('limita el total de alertas para no saturar UI', () async {
      final allSessions = <Sesion>[];
      for (var i = 0; i < 6; i++) {
        allSessions.addAll(
          _buildSessionsForExercise(
            exerciseName: 'Ejercicio $i',
            weights: [80, 79, 78, 77],
            startDate: DateTime(2026, 1, 1).add(Duration(days: i)),
          ),
        );
      }

      final container = ProviderContainer(
        overrides: [
          sesionesHistoryStreamProvider.overrideWithValue(
            AsyncValue.data(allSessions),
          ),
        ],
      );
      addTearDown(container.dispose);

      final alerts = container.read(deloadAlertsProvider);

      expect(alerts.length, lessThanOrEqualTo(4));
    });
  });
}

List<Sesion> _buildSessionsForExercise({
  required String exerciseName,
  required List<double> weights,
  required DateTime startDate,
}) {
  return List.generate(weights.length, (index) {
    final date = startDate.add(Duration(days: index * 7));
    final exercise = Ejercicio(
      id: 'ex-$exerciseName-$index',
      libraryId: 'lib-$exerciseName',
      nombre: exerciseName,
      series: 1,
      reps: 5,
      logs: [
        SerieLog(
          id: 'set-$exerciseName-$index',
          peso: weights[index],
          reps: 5,
          completed: true,
        ),
      ],
    );

    return Sesion(
      id: 's-$exerciseName-$index',
      rutinaId: 'rutina-test',
      fecha: date,
      ejerciciosCompletados: [exercise],
      ejerciciosObjetivo: const [],
    );
  });
}
