import '../models/training_sesion.dart';

abstract class IVoiceInputService {
  Future<Sesion?> listenAndParse();
}
