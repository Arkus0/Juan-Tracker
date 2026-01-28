import '../models/training_sesion.dart';
import '../models/training_rutina.dart';

abstract class ITrainingRepository {
  Future<void> saveSession(Sesion sesion);
  Stream<List<Sesion>> watchSessions();
  Future<void> deleteSession(String id);
  Future<List<Rutina>> getRutinas();
}
