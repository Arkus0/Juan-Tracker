import '../models/training_exercise.dart';

abstract class ExerciseRepository {
  Stream<List<TrainingExercise>> watchAll();
  Future<List<TrainingExercise>> getAll();
  Future<void> addExercise(TrainingExercise exercise);
  Future<void> deleteExercise(String id);
}
