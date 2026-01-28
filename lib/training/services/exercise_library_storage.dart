import 'exercise_library_storage_stub.dart'
    if (dart.library.io) 'exercise_library_storage_io.dart'
    if (dart.library.html) 'exercise_library_storage_web.dart';

abstract class ExerciseLibraryStorage {
  Future<String?> readCustomJson();
  Future<void> writeCustomJson(String json);
}

ExerciseLibraryStorage createExerciseLibraryStorage() =>
    exerciseLibraryStorage();
