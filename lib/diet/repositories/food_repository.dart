import 'package:juan_tracker/diet/models/food_model.dart';

/// Interfaz abstracta para el repositorio de alimentos
/// La capa de UI solo conoce esta interfaz, no la implementación
abstract class IFoodRepository {
  /// Obtiene todos los alimentos
  Future<List<FoodModel>> getAll();

  /// Stream de todos los alimentos para reactividad
  Stream<List<FoodModel>> watchAll();

  /// Obtiene un alimento por ID
  Future<FoodModel?> getById(String id);

  /// Busca alimentos por nombre o marca
  Future<List<FoodModel>> search(String query, {int limit = 20});

  /// Busca por código de barras
  Future<FoodModel?> findByBarcode(String barcode);

  /// Inserta un nuevo alimento
  Future<void> insert(FoodModel food);

  /// Actualiza un alimento existente
  Future<void> update(FoodModel food);

  /// Elimina un alimento
  Future<void> delete(String id);

  /// Obtiene alimentos creados por el usuario
  Future<List<FoodModel>> getUserCreated();

  /// Obtiene alimentos de fuentes verificadas
  Future<List<FoodModel>> getVerifiedSources();
}
