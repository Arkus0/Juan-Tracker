import 'exercise_library_storage.dart';

class _InMemoryExerciseLibraryStorage implements ExerciseLibraryStorage {
  String? _cache;

  @override
  Future<String?> readCustomJson() async => _cache;

  @override
  Future<void> writeCustomJson(String json) async {
    _cache = json;
  }
}

ExerciseLibraryStorage exerciseLibraryStorage() =>
    _InMemoryExerciseLibraryStorage();
