import 'dart:async';

import '../models/training_rutina.dart';
import 'routine_repository.dart';

class InMemoryRoutineRepository implements RoutineRepository {
  final List<Rutina> _storage = [];
  final StreamController<List<Rutina>> _controller =
      StreamController<List<Rutina>>.broadcast();

  InMemoryRoutineRepository() {
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_storage));
  }

  @override
  Stream<List<Rutina>> watchAll() => _controller.stream;

  @override
  Future<List<Rutina>> getAll() async => List.unmodifiable(_storage);

  @override
  Future<void> saveRoutine(Rutina rutina) async {
    _storage.removeWhere((r) => r.id == rutina.id);
    _storage.add(rutina);
    _emit();
  }

  @override
  Future<void> deleteRoutine(String id) async {
    _storage.removeWhere((r) => r.id == id);
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}
