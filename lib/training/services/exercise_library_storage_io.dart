import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'exercise_library_storage.dart';

class _ExerciseLibraryStorageIo implements ExerciseLibraryStorage {
  static const _fileName = 'exercises_user.json';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  @override
  Future<String?> readCustomJson() async {
    final file = await _file();
    if (!await file.exists()) return null;
    if (await file.length() == 0) return null;
    return file.readAsString();
  }

  @override
  Future<void> writeCustomJson(String json) async {
    final file = await _file();
    await file.writeAsString(json);
  }
}

ExerciseLibraryStorage exerciseLibraryStorage() => _ExerciseLibraryStorageIo();
