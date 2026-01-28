import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/training_ejercicio.dart';
import '../models/training_serie_log.dart';
import '../models/training_sesion.dart';
import '../repositories/i_training_repository.dart';
import 'database_provider.dart';

class TrainingSessionState {
  final Sesion? activeSession;
  final Sesion? lastSession;
  final bool isSaving;
  final String? error;

  const TrainingSessionState({
    this.activeSession,
    this.lastSession,
    this.isSaving = false,
    this.error,
  });

  bool get isActive => activeSession != null;

  factory TrainingSessionState.idle() => const TrainingSessionState();

  factory TrainingSessionState.active(Sesion sesion) =>
      TrainingSessionState(activeSession: sesion);

  factory TrainingSessionState.finished(Sesion sesion) =>
      TrainingSessionState(lastSession: sesion);

  TrainingSessionState copyWith({
    Sesion? activeSession,
    bool clearActive = false,
    Sesion? lastSession,
    bool? isSaving,
    String? error,
  }) {
    return TrainingSessionState(
      activeSession: clearActive ? null : activeSession ?? this.activeSession,
      lastSession: lastSession ?? this.lastSession,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

class TrainingSessionController extends Notifier<TrainingSessionState> {
  late final ITrainingRepository _repo = ref.read(trainingRepositoryProvider);

  @override
  TrainingSessionState build() => TrainingSessionState.idle();

  void startSession({required String id, String? rutinaId, String? dayName}) {
    final now = DateTime.now();
    state = TrainingSessionState.active(
      Sesion(
        id: id,
        fecha: now,
        durationSeconds: null,
        totalVolume: 0.0,
        ejerciciosCompletados: const [],
        rutinaId: rutinaId,
        dayName: dayName,
      ),
    );
  }

  void addSet({
    required String ejercicioId,
    String? ejercicioNombre,
    required double peso,
    required int reps,
    int? rpe,
  }) {
    final current = state.activeSession;
    if (current == null) return;

    final newLog = SerieLog(peso: peso, reps: reps, rpe: rpe);
    final ejercicios = current.ejerciciosCompletados.toList();

    final index = ejercicios.indexWhere((e) => e.id == ejercicioId);
    if (index >= 0) {
      final existing = ejercicios[index];
      final updatedLogs = [...existing.logs, newLog];
      ejercicios[index] = existing.copyWith(
        nombre: ejercicioNombre ?? existing.nombre,
        logs: updatedLogs,
      );
    } else {
      ejercicios.add(
        Ejercicio(
          id: ejercicioId,
          nombre: ejercicioNombre ?? ejercicioId,
          logs: [newLog],
        ),
      );
    }

    final newTotal = Sesion.computeTotalVolume(ejercicios);
    state = TrainingSessionState.active(
      current.copyWith(
        ejerciciosCompletados: ejercicios,
        totalVolume: newTotal,
      ),
    );
  }

  void undoLastSet() {
    final current = state.activeSession;
    if (current == null) return;

    final ejercicios = current.ejerciciosCompletados.toList();
    for (var i = ejercicios.length - 1; i >= 0; i--) {
      final ejercicio = ejercicios[i];
      if (ejercicio.logs.isEmpty) continue;
      final updatedLogs = ejercicio.logs.toList()..removeLast();
      if (updatedLogs.isEmpty) {
        ejercicios.removeAt(i);
      } else {
        ejercicios[i] = ejercicio.copyWith(logs: updatedLogs);
      }
      break;
    }

    final newTotal = Sesion.computeTotalVolume(ejercicios);
    state = TrainingSessionState.active(
      current.copyWith(
        ejerciciosCompletados: ejercicios,
        totalVolume: newTotal,
      ),
    );
  }

  Future<void> finishSession() async {
    final current = state.activeSession;
    if (current == null) return;

    state = state.copyWith(isSaving: true, error: null);
    final duration = DateTime.now().difference(current.fecha).inSeconds;
    final finished = current.copyWith(
      durationSeconds: duration > 0 ? duration : current.durationSeconds,
    );

    try {
      await _repo.saveSession(finished);
      state = TrainingSessionState.finished(finished);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Future<void> addExternalSession(Sesion sesion) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.saveSession(sesion);
      state = TrainingSessionState.finished(sesion);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }
}

final trainingSessionControllerProvider =
    NotifierProvider<TrainingSessionController, TrainingSessionState>(
      TrainingSessionController.new,
    );
