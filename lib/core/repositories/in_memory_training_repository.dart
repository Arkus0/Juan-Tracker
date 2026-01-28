import 'dart:async';

import '../models/training_sesion.dart';
import '../models/training_rutina.dart';
import 'i_training_repository.dart';

class InMemoryTrainingRepository implements ITrainingRepository {
  final List<Sesion> _storage = [];
  final StreamController<List<Sesion>> _controller;

  InMemoryTrainingRepository()
    : _controller = StreamController<List<Sesion>>.broadcast() {
    _controller.onListen = _emit;
    _emit();
  }

  void _emit() {
    final snapshot = List<Sesion>.unmodifiable(_storage);
    _controller.add(snapshot);
  }

  @override
  Future<void> saveSession(Sesion sesion) async {
    _storage.removeWhere((s) => s.id == sesion.id);
    _storage.add(sesion);
    _storage.sort((a, b) => b.fecha.compareTo(a.fecha));
    _emit();
  }

  @override
  Stream<List<Sesion>> watchSessions() => _controller.stream;

  @override
  Future<void> deleteSession(String id) async {
    _storage.removeWhere((s) => s.id == id);
    _emit();
  }

  @override
  Future<List<Rutina>> getRutinas() async {
    return [
      Rutina(
        id: 'r1',
        nombre: 'Rutina ejemplo',
        ejerciciosPlantilla: const ['Sentadilla', 'Press banca'],
      ),
    ];
  }

  void dispose() {
    _controller.close();
  }
}
