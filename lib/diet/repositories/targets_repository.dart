import 'package:juan_tracker/diet/models/targets_model.dart';

/// Interfaz abstracta para el repositorio de objetivos
abstract class ITargetsRepository {
  /// Obtiene todos los objetivos ordenados por fecha de validez
  Future<List<TargetsModel>> getAll();

  /// Stream de todos los objetivos
  Stream<List<TargetsModel>> watchAll();

  /// Obtiene el objetivo activo para una fecha específica
  Future<TargetsModel?> getActiveForDate(DateTime date);

  /// Obtiene el objetivo más reciente (el que está activo ahora)
  Future<TargetsModel?> getCurrent();

  /// Inserta un nuevo objetivo (versionado)
  Future<void> insert(TargetsModel target);

  /// Actualiza un objetivo existente
  Future<void> update(TargetsModel target);

  /// Elimina un objetivo
  Future<void> delete(String id);

  /// Obtiene el progreso contra objetivos para una fecha
  Future<TargetsProgress> getProgressForDate(DateTime date);
}
