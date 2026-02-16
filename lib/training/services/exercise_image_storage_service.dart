import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Servicio para persistir imÃ¡genes locales de ejercicios.
/// Copia la imagen a storage de la app para evitar rutas temporales.
class ExerciseImageStorageService {
  static final ExerciseImageStorageService instance =
      ExerciseImageStorageService._();
  ExerciseImageStorageService._();

  Future<String> persistImage({
    required String sourcePath,
    required int exerciseId,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(directory.path, 'exercise_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = path.extension(sourcePath).isNotEmpty
        ? path.extension(sourcePath)
        : '.jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'exercise_${exerciseId}_$timestamp$ext';
    final targetPath = path.join(imagesDir.path, fileName);

    final saved = await File(sourcePath).copy(targetPath);
    return saved.path;
  }

  Future<void> deleteImageIfExists(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignorar errores de borrado
    }
  }
}
