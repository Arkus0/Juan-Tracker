import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_library_storage.dart';

class _ExerciseLibraryStorageWeb implements ExerciseLibraryStorage {
  static const _prefsKey = 'training_custom_exercises_json';

  @override
  Future<String?> readCustomJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }

  @override
  Future<void> writeCustomJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json);
  }
}

ExerciseLibraryStorage exerciseLibraryStorage() => _ExerciseLibraryStorageWeb();
