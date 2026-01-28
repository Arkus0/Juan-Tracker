import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/training_sesion.dart';
import 'database_provider.dart';

final trainingSessionsProvider = StreamProvider.autoDispose<List<Sesion>>((
  ref,
) {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.watchSessions();
});

class TrainingStats {
  final int sesionesSemana;
  final int setsSemana;
  final double volumenSemana;
  final Sesion? ultimaSesion;

  const TrainingStats({
    required this.sesionesSemana,
    required this.setsSemana,
    required this.volumenSemana,
    required this.ultimaSesion,
  });

  factory TrainingStats.empty() => const TrainingStats(
    sesionesSemana: 0,
    setsSemana: 0,
    volumenSemana: 0,
    ultimaSesion: null,
  );
}

final trainingStatsProvider = Provider.autoDispose<TrainingStats>((ref) {
  final asyncSessions = ref.watch(trainingSessionsProvider);
  return asyncSessions.maybeWhen(
    data: (sessions) {
      if (sessions.isEmpty) return TrainingStats.empty();
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - DateTime.monday));
      final weekSessions = sessions
          .where((s) => !s.fecha.isBefore(weekStart))
          .toList();
      final sesionesSemana = weekSessions.length;
      final setsSemana = weekSessions.fold<int>(
        0,
        (sum, s) => sum + s.completedSetsCount,
      );
      final volumenSemana = weekSessions.fold<double>(
        0,
        (sum, s) => sum + s.totalVolume,
      );
      final ultimaSesion = sessions.isEmpty ? null : sessions.first;
      return TrainingStats(
        sesionesSemana: sesionesSemana,
        setsSemana: setsSemana,
        volumenSemana: volumenSemana,
        ultimaSesion: ultimaSesion,
      );
    },
    orElse: TrainingStats.empty,
  );
});
