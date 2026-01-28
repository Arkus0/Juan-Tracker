import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:juan_tracker/core/models/training_ejercicio.dart';
import 'package:juan_tracker/core/models/training_sesion.dart';
import 'package:juan_tracker/core/models/training_serie_log.dart';
import 'package:juan_tracker/features/training/presentation/session_detail_screen.dart';

void main() {
  testWidgets('Session detail shows exercises, series, and metrics', (
    tester,
  ) async {
    final session = Sesion(
      id: 's1',
      fecha: DateTime(2026, 1, 15, 10, 30),
      durationSeconds: 1200,
      totalVolume: 300.0,
      ejerciciosCompletados: [
        Ejercicio(
          id: 'e1',
          nombre: 'Sentadilla',
          logs: const [
            SerieLog(peso: 100, reps: 5, completed: true),
            SerieLog(peso: 80, reps: 8, completed: true),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: SessionDetailScreen(session: session)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detalle de sesion'), findsOneWidget);
    expect(find.text('Sesion 15/01/2026'), findsOneWidget);
    expect(find.text('Duracion: 20 MIN'), findsOneWidget);
    expect(find.text('Series: 2'), findsOneWidget);
    expect(find.text('Volumen: 300.0'), findsOneWidget);
    expect(find.text('Sentadilla'), findsOneWidget);
    expect(find.textContaining('100 x 5'), findsOneWidget);
    expect(find.textContaining('80 x 8'), findsOneWidget);
  });
}
