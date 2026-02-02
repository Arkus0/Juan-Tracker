import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../training/database/database.dart';
import '../models/meal_template.dart';

/// Repositorio para gestionar plantillas de comidas
/// 
/// Permite crear, leer, actualizar y eliminar plantillas de comidas.
/// Las plantillas permiten guardar una comida completa para repetirla fácilmente.
class MealTemplateRepository {
  final AppDatabase _db;

  MealTemplateRepository(this._db);

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  /// Obtiene todas las plantillas ordenadas por uso (más usadas primero)
  Future<List<MealTemplateModel>> getAll() async {
    final templates = await (_db.select(_db.mealTemplates)
      ..orderBy([
        (t) => OrderingTerm.desc(t.useCount),
        (t) => OrderingTerm.desc(t.lastUsedAt),
      ]))
      .get();

    return Future.wait(templates.map((t) => _loadTemplateWithItems(t)));
  }

  /// Obtiene plantillas por tipo de comida
  Future<List<MealTemplateModel>> getByMealType(MealType mealType) async {
    final templates = await (_db.select(_db.mealTemplates)
      ..where((t) => t.mealType.equals(mealType.name))
      ..orderBy([
        (t) => OrderingTerm.desc(t.useCount),
        (t) => OrderingTerm.desc(t.lastUsedAt),
      ]))
      .get();

    return Future.wait(templates.map((t) => _loadTemplateWithItems(t)));
  }

  /// Obtiene las N plantillas más usadas
  Future<List<MealTemplateModel>> getTopUsed({int limit = 5}) async {
    final templates = await (_db.select(_db.mealTemplates)
      ..orderBy([
        (t) => OrderingTerm.desc(t.useCount),
        (t) => OrderingTerm.desc(t.lastUsedAt),
      ])
      ..limit(limit))
      .get();

    return Future.wait(templates.map((t) => _loadTemplateWithItems(t)));
  }

  /// Obtiene una plantilla por ID
  Future<MealTemplateModel?> getById(String id) async {
    final template = await (_db.select(_db.mealTemplates)
      ..where((t) => t.id.equals(id)))
      .getSingleOrNull();

    if (template == null) return null;
    return _loadTemplateWithItems(template);
  }

  /// Crea una nueva plantilla a partir de entradas del diario
  /// 
  /// [name] - Nombre de la plantilla
  /// [mealType] - Tipo de comida sugerido
  /// [entries] - Lista de entradas del diario a incluir
  Future<MealTemplateModel> createFromDiaryEntries({
    required String name,
    required MealType mealType,
    required List<DiaryEntry> entries,
  }) async {
    final now = DateTime.now();
    final templateId = DateTime.now().millisecondsSinceEpoch.toString();

    // Crear la plantilla
    await _db.into(_db.mealTemplates).insert(MealTemplatesCompanion.insert(
      id: templateId,
      name: name,
      mealType: mealType,
      createdAt: now,
      updatedAt: now,
    ));

    // Crear los items
    final items = <MealTemplateItemModel>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      
      // Skip entries sin foodId (quickAdd entries)
      final foodId = entry.foodId;
      if (foodId == null) continue;
      
      // Obtener el food para los snapshots
      final food = await (_db.select(_db.foods)
        ..where((f) => f.id.equals(foodId)))
        .getSingleOrNull();

      if (food == null) continue;

      final item = MealTemplateItemModel(
        id: '${templateId}_$i',
        templateId: templateId,
        foodId: foodId,
        amount: entry.amount,
        unit: entry.unit,
        foodName: food.name,
        kcalPer100g: food.kcalPer100g,
        proteinPer100g: food.proteinPer100g,
        carbsPer100g: food.carbsPer100g,
        fatPer100g: food.fatPer100g,
        sortOrder: i,
      );

      await _db.into(_db.mealTemplateItems).insert(
        MealTemplateItemsCompanion.insert(
          id: item.id,
          templateId: templateId,
          foodId: item.foodId,
          amount: item.amount,
          unit: item.unit,
          foodNameSnapshot: item.foodName,
          kcalPer100gSnapshot: item.kcalPer100g,
          proteinPer100gSnapshot: Value(item.proteinPer100g),
          carbsPer100gSnapshot: Value(item.carbsPer100g),
          fatPer100gSnapshot: Value(item.fatPer100g),
          sortOrder: Value(i),
        ),
      );

      items.add(item);
    }

    return MealTemplateModel(
      id: templateId,
      name: name,
      mealType: mealType,
      useCount: 0,
      lastUsedAt: null,
      createdAt: now,
      updatedAt: now,
      items: items,
    );
  }

  /// Actualiza el nombre de una plantilla
  Future<void> updateName(String id, String newName) async {
    await (_db.update(_db.mealTemplates)..where((t) => t.id.equals(id)))
      .write(MealTemplatesCompanion(
        name: Value(newName),
        updatedAt: Value(DateTime.now()),
      ));
  }

  /// Elimina una plantilla y sus items
  Future<void> delete(String id) async {
    // Los items se eliminan automáticamente por CASCADE
    await (_db.delete(_db.mealTemplates)..where((t) => t.id.equals(id))).go();
  }

  /// Marca una plantilla como usada (incrementa contador y actualiza fecha)
  Future<void> markAsUsed(String id) async {
    final template = await getById(id);
    if (template == null) return;

    await (_db.update(_db.mealTemplates)..where((t) => t.id.equals(id)))
      .write(MealTemplatesCompanion(
        useCount: Value(template.useCount + 1),
        lastUsedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  /// Carga una plantilla con todos sus items
  Future<MealTemplateModel> _loadTemplateWithItems(MealTemplate template) async {
    final items = await (_db.select(_db.mealTemplateItems)
      ..where((i) => i.templateId.equals(template.id))
      ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
      .get();

    return MealTemplateModel(
      id: template.id,
      name: template.name,
      mealType: template.mealType,
      useCount: template.useCount,
      lastUsedAt: template.lastUsedAt,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
      items: items.map((i) => MealTemplateItemModel(
        id: i.id,
        templateId: i.templateId,
        foodId: i.foodId,
        amount: i.amount,
        unit: i.unit,
        foodName: i.foodNameSnapshot,
        kcalPer100g: i.kcalPer100gSnapshot,
        proteinPer100g: i.proteinPer100gSnapshot,
        carbsPer100g: i.carbsPer100gSnapshot,
        fatPer100g: i.fatPer100gSnapshot,
        sortOrder: i.sortOrder,
      )).toList(),
    );
  }
}

/// Provider para el repositorio de plantillas de comidas
final mealTemplateRepositoryProvider = Provider<MealTemplateRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MealTemplateRepository(db);
});
