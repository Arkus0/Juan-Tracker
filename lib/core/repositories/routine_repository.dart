import '../models/training_rutina.dart';

abstract class RoutineRepository {
  Stream<List<Rutina>> watchAll();
  Future<List<Rutina>> getAll();
  Future<void> saveRoutine(Rutina rutina);
  Future<void> deleteRoutine(String id);
}
