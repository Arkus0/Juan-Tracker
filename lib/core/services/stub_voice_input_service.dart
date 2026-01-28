import 'i_voice_input_service.dart';
import '../models/training_sesion.dart';

class StubVoiceInputService implements IVoiceInputService {
  @override
  Future<Sesion?> listenAndParse() async => null;
}
