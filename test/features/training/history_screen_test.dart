import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:juan_tracker/core/models/training_sesion.dart';
import 'package:juan_tracker/core/providers/database_provider.dart';
import 'package:juan_tracker/core/repositories/in_memory_training_repository.dart';
import 'package:juan_tracker/features/training/presentation/history_screen.dart';

void main() {
  testWidgets('History screen groups sessions and shows headers', (
    tester,
  ) async {
    final repo = InMemoryTrainingRepository();
    final now = DateTime.now();
    final startOfWeek = _startOfWeek(now);

    final thisWeek = startOfWeek.add(const Duration(days: 1, hours: 10));
    final lastWeek = startOfWeek.subtract(const Duration(days: 1, hours: 3));
    final older = _previousMonthDate(now);

    await repo.saveSession(
      Sesion(
        id: 's1',
        fecha: thisWeek,
        durationSeconds: 1200,
        totalVolume: 300,
        ejerciciosCompletados: const [],
      ),
    );
    await repo.saveSession(
      Sesion(
        id: 's2',
        fecha: lastWeek,
        durationSeconds: 900,
        totalVolume: 200,
        ejerciciosCompletados: const [],
      ),
    );
    await repo.saveSession(
      Sesion(
        id: 's3',
        fecha: older,
        durationSeconds: 600,
        totalVolume: 100,
        ejerciciosCompletados: const [],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [trainingRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('ESTA SEMANA'), findsOneWidget);
    expect(find.text('SEMANA PASADA'), findsOneWidget);
    final olderLabel = '${_monthName(older.month)} ${older.year}';
    expect(find.text(olderLabel), findsOneWidget);
  });
}

DateTime _startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final delta = normalized.weekday - DateTime.monday;
  return normalized.subtract(Duration(days: delta));
}

DateTime _previousMonthDate(DateTime now) {
  final year = now.month == 1 ? now.year - 1 : now.year;
  final month = now.month == 1 ? 12 : now.month - 1;
  return DateTime(year, month, 15, 10);
}

String _monthName(int month) {
  const months = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];
  return months[month - 1];
}
