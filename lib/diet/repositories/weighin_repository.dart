import 'package:juan_tracker/diet/models/weighin_model.dart';

/// Interfaz abstracta para el repositorio de pesos corporales
abstract class IWeighInRepository {
  /// Obtiene todos los registros de peso ordenados por fecha
  Future<List<WeighInModel>> getAll({int? limit});

  /// Stream de todos los registros para reactividad
  Stream<List<WeighInModel>> watchAll();

  /// Obtiene registros en un rango de fechas
  Future<List<WeighInModel>> getByDateRange(DateTime from, DateTime to);

  /// Stream de registros en un rango de fechas
  Stream<List<WeighInModel>> watchByDateRange(DateTime from, DateTime to);

  /// Obtiene el registro más reciente
  Future<WeighInModel?> getLatest();

  /// Obtiene un registro por ID
  Future<WeighInModel?> getById(String id);

  /// Inserta un nuevo registro
  Future<void> insert(WeighInModel weighIn);

  /// Actualiza un registro existente
  Future<void> update(WeighInModel weighIn);

  /// Elimina un registro
  Future<void> delete(String id);

  /// Calcula el trend de peso a partir de registros recientes
  Future<WeightTrend?> calculateTrend({int days = 30});
}
