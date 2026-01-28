import '../../../core/models/training_ejercicio.dart';
import '../../../core/models/training_exercise.dart';

List<Ejercicio> buildEjerciciosFromIds(
  List<String> ids,
  List<TrainingExercise> library,
) {
  final List<Ejercicio> ejercicios = [];
  for (final id in ids) {
    TrainingExercise? match;
    for (final ex in library) {
      if (ex.id == id) {
        match = ex;
        break;
      }
    }
    ejercicios.add(Ejercicio(id: id, nombre: match?.nombre ?? id));
  }
  return ejercicios;
}
