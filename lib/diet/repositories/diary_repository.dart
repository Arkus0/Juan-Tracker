import 'package:juan_tracker/diet/models/diary_entry_model.dart';

/// Interfaz abstracta para el repositorio de entradas del diario
abstract class IDiaryRepository {
  /// Obtiene todas las entradas de una fecha
  Future<List<DiaryEntryModel>> getByDate(DateTime date);

  /// Stream de entradas de una fecha para reactividad
  Stream<List<DiaryEntryModel>> watchByDate(DateTime date);

  /// Obtiene entradas de un rango de fechas
  Future<List<DiaryEntryModel>> getByDateRange(DateTime from, DateTime to);

  /// Obtiene una entrada por ID
  Future<DiaryEntryModel?> getById(String id);

  /// Inserta una nueva entrada
  Future<void> insert(DiaryEntryModel entry);

  /// Actualiza una entrada existente
  Future<void> update(DiaryEntryModel entry);

  /// Elimina una entrada
  Future<void> delete(String id);

  /// Obtiene los totales diarios calculados
  Future<DailyTotals> getDailyTotals(DateTime date);

  /// Stream de totales diarios
  Stream<DailyTotals> watchDailyTotals(DateTime date);

  /// Obtiene el historial de entradas de un tipo de comida específico
  Future<List<DiaryEntryModel>> getHistoryByMealType(
    MealType mealType, {
    int limit = 50,
  });

  /// Obtiene las últimas entradas únicas (por foodId/foodName) para quick-add
  /// Útil para mostrar comidas recientes al usuario
  Future<List<DiaryEntryModel>> getRecentUniqueEntries({int limit = 5});
}
