import 'package:drift/drift.dart';
import 'package:juan_tracker/training/database/database.dart' as db;
import 'package:juan_tracker/diet/models/models.dart' as models;
import 'repositories.dart';

// ============================================================================
// MAPEO ENTIDADES DRIFT ↔ MODELOS DE DOMINIO
// ============================================================================

extension FoodMapping on db.Food {
  models.FoodModel toModel() => models.FoodModel(
        id: id,
        name: name,
        brand: brand,
        barcode: barcode,
        kcalPer100g: kcalPer100g,
        proteinPer100g: proteinPer100g,
        carbsPer100g: carbsPer100g,
        fatPer100g: fatPer100g,
        portionName: portionName,
        portionGrams: portionGrams,
        userCreated: userCreated,
        verifiedSource: verifiedSource,
        sourceMetadata: sourceMetadata,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension FoodModelMapping on models.FoodModel {
  db.FoodsCompanion toCompanion() => db.FoodsCompanion(
        id: Value(id),
        name: Value(name),
        normalizedName: Value(name.toLowerCase()),
        brand: Value(brand),
        barcode: Value(barcode),
        kcalPer100g: Value(kcalPer100g),
        proteinPer100g: Value(proteinPer100g),
        carbsPer100g: Value(carbsPer100g),
        fatPer100g: Value(fatPer100g),
        portionName: Value(portionName),
        portionGrams: Value(portionGrams),
        userCreated: Value(userCreated),
        verifiedSource: Value(verifiedSource),
        sourceMetadata: Value(sourceMetadata),
        useCount: const Value(0),
        lastUsedAt: Value(updatedAt),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
      );
}

extension DiaryEntryMapping on db.DiaryEntry {
  models.DiaryEntryModel toModel() => models.DiaryEntryModel(
        id: id,
        date: date,
        mealType: _convertDbMealType(mealType),
        foodId: foodId,
        foodName: foodName,
        foodBrand: foodBrand,
        amount: amount,
        unit: _convertDbServingUnit(unit),
        kcal: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        isQuickAdd: isQuickAdd,
        notes: notes,
        createdAt: createdAt,
      );
}

models.MealType _convertDbMealType(db.MealType value) => models.MealType.values.byName(value.name);
models.ServingUnit _convertDbServingUnit(db.ServingUnit value) => models.ServingUnit.values.byName(value.name);

extension DiaryEntryModelMapping on models.DiaryEntryModel {
  db.DiaryEntriesCompanion toCompanion() => db.DiaryEntriesCompanion(
        id: Value(id),
        date: Value(DateTime(date.year, date.month, date.day)),
        mealType: Value(_convertModelMealType(mealType)),
        foodId: Value(foodId),
        foodName: Value(foodName),
        foodBrand: Value(foodBrand),
        amount: Value(amount),
        unit: Value(_convertModelServingUnit(unit)),
        kcal: Value(kcal),
        protein: Value(protein),
        carbs: Value(carbs),
        fat: Value(fat),
        isQuickAdd: Value(isQuickAdd),
        notes: Value(notes),
        createdAt: Value(createdAt),
      );
}

db.MealType _convertModelMealType(models.MealType value) => db.MealType.values.byName(value.name);
db.ServingUnit _convertModelServingUnit(models.ServingUnit value) => db.ServingUnit.values.byName(value.name);

extension WeighInMapping on db.WeighIn {
  models.WeighInModel toModel() => models.WeighInModel(
        id: id,
        dateTime: measuredAt,
        weightKg: weightKg,
        note: note,
        createdAt: createdAt,
      );
}

extension WeighInModelMapping on models.WeighInModel {
  db.WeighInsCompanion toCompanion() => db.WeighInsCompanion(
        id: Value(id),
        measuredAt: Value(dateTime),
        weightKg: Value(weightKg),
        note: Value(note),
        createdAt: Value(createdAt),
      );
}

extension TargetsMapping on db.Target {
  models.TargetsModel toModel() => models.TargetsModel(
        id: id,
        validFrom: validFrom,
        kcalTarget: kcalTarget,
        proteinTarget: proteinTarget,
        carbsTarget: carbsTarget,
        fatTarget: fatTarget,
        notes: notes,
        createdAt: createdAt,
      );
}

extension TargetsModelMapping on models.TargetsModel {
  db.TargetsCompanion toCompanion() => db.TargetsCompanion(
        id: Value(id),
        validFrom: Value(validFrom),
        kcalTarget: Value(kcalTarget),
        proteinTarget: Value(proteinTarget),
        carbsTarget: Value(carbsTarget),
        fatTarget: Value(fatTarget),
        notes: Value(notes),
        createdAt: Value(createdAt),
      );
}

// ============================================================================
// IMPLEMENTACIONES DRIFT
// ============================================================================

/// Implementación Drift de IFoodRepository
class DriftFoodRepository implements IFoodRepository {
  final db.AppDatabase _db;

  DriftFoodRepository(this._db);

  @override
  Future<List<models.FoodModel>> getAll() async {
    final foods = await _db.select(_db.foods).get();
    return foods.map((f) => f.toModel()).toList();
  }

  @override
  Stream<List<models.FoodModel>> watchAll() {
    return _db.select(_db.foods).watch().map(
          (foods) => foods.map((f) => f.toModel()).toList(),
        );
  }

  @override
  Future<models.FoodModel?> getById(String id) async {
    final query = _db.select(_db.foods)..where((f) => f.id.equals(id));
    final food = await query.getSingleOrNull();
    return food?.toModel();
  }

  @override
  Future<List<models.FoodModel>> search(String query, {int limit = 20}) async {
    final lowerQuery = query.toLowerCase();
    final foods = await (_db.select(_db.foods)
          ..where(
            (f) =>
                f.name.lower().contains(lowerQuery) |
                f.brand.lower().contains(lowerQuery),
          )
          ..limit(limit))
        .get();
    return foods.map((f) => f.toModel()).toList();
  }

  @override
  Future<models.FoodModel?> findByBarcode(String barcode) async {
    final query = _db.select(_db.foods)
      ..where((f) => f.barcode.equals(barcode));
    final food = await query.getSingleOrNull();
    return food?.toModel();
  }

  @override
  Future<void> insert(models.FoodModel food) async {
    await _db.into(_db.foods).insert(food.toCompanion());
  }

  @override
  Future<void> update(models.FoodModel food) async {
    await _db.update(_db.foods).replace(food.toCompanion());
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.foods)..where((f) => f.id.equals(id))).go();
  }

  @override
  Future<List<models.FoodModel>> getUserCreated() async {
    final foods = await (_db.select(_db.foods)
          ..where((f) => f.userCreated.equals(true)))
        .get();
    return foods.map((f) => f.toModel()).toList();
  }

  @override
  Future<List<models.FoodModel>> getVerifiedSources() async {
    final foods = await (_db.select(_db.foods)
          ..where((f) => f.verifiedSource.isNotNull()))
        .get();
    return foods.map((f) => f.toModel()).toList();
  }
}

/// Implementación Drift de IDiaryRepository
class DriftDiaryRepository implements IDiaryRepository {
  final db.AppDatabase _db;

  DriftDiaryRepository(this._db);

  @override
  Future<List<models.DiaryEntryModel>> getByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final entries = await (_db.select(_db.diaryEntries)
          ..where((e) => e.date.equals(startOfDay))
          ..orderBy([(e) => OrderingTerm(expression: e.createdAt)]))
        .get();
    return entries.map((e) => e.toModel()).toList();
  }

  @override
  Stream<List<models.DiaryEntryModel>> watchByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    return (_db.select(_db.diaryEntries)
          ..where((e) => e.date.equals(startOfDay))
          ..orderBy([(e) => OrderingTerm(expression: e.createdAt)]))
        .watch()
        .map((entries) => entries.map((e) => e.toModel()).toList());
  }

  @override
  Future<List<models.DiaryEntryModel>> getByDateRange(DateTime from, DateTime to) async {
    final entries = await (_db.select(_db.diaryEntries)
          ..where(
            (e) => e.date.isBetweenValues(
              DateTime(from.year, from.month, from.day),
              DateTime(to.year, to.month, to.day),
            ),
          )
          ..orderBy([(e) => OrderingTerm(expression: e.date)]))
        .get();
    return entries.map((e) => e.toModel()).toList();
  }

  @override
  Future<models.DiaryEntryModel?> getById(String id) async {
    final query = _db.select(_db.diaryEntries)..where((e) => e.id.equals(id));
    final entry = await query.getSingleOrNull();
    return entry?.toModel();
  }

  @override
  Future<void> insert(models.DiaryEntryModel entry) async {
    await _db.into(_db.diaryEntries).insert(entry.toCompanion());
  }

  @override
  Future<void> update(models.DiaryEntryModel entry) async {
    await _db.update(_db.diaryEntries).replace(entry.toCompanion());
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.diaryEntries)..where((e) => e.id.equals(id))).go();
  }

  @override
  Future<models.DailyTotals> getDailyTotals(DateTime date) async {
    final entries = await getByDate(date);
    return models.DailyTotals.fromEntries(entries);
  }

  @override
  Stream<models.DailyTotals> watchDailyTotals(DateTime date) {
    return watchByDate(date).map((entries) => models.DailyTotals.fromEntries(entries));
  }

  @override
  Future<List<models.DiaryEntryModel>> getHistoryByMealType(
    models.MealType mealType, {
    int limit = 50,
  }) async {
    final entries = await (_db.select(_db.diaryEntries)
          ..where((e) => e.mealType.equals(mealType.name))
          ..orderBy([(e) => OrderingTerm.desc(e.date)])
          ..limit(limit))
        .get();
    return entries.map((e) => e.toModel()).toList();
  }

  @override
  Future<List<models.DiaryEntryModel>> getRecentUniqueEntries({int limit = 7}) async {
    // UX-002: Obtener entradas de los últimos 7 días (más amplio)
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final entries = await (_db.select(_db.diaryEntries)
          ..where((e) => e.date.isBiggerOrEqualValue(
                DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day),
              ))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
          ..limit(100))
        .get();

    // UX-002: Agrupar por alimento y contar frecuencia
    final frequencyMap = <String, int>{};
    final entryMap = <String, db.DiaryEntry>{};

    for (final entry in entries) {
      final key = entry.foodId ?? entry.foodName;
      frequencyMap[key] = (frequencyMap[key] ?? 0) + 1;
      // Guardar la entrada más reciente de cada alimento
      entryMap.putIfAbsent(key, () => entry);
    }

    // Convertir a lista y ordenar por frecuencia (descendente) y luego por recencia
    final sortedEntries = entryMap.entries.toList()
      ..sort((a, b) {
        // Primero por frecuencia
        final freqCompare = frequencyMap[b.key]!.compareTo(frequencyMap[a.key]!);
        if (freqCompare != 0) return freqCompare;
        // Desempate por fecha
        return b.value.createdAt.compareTo(a.value.createdAt);
      });

    // Tomar los primeros 'limit' elementos
    final limitedEntries = sortedEntries.take(limit).map((e) => e.value).toList();

    return limitedEntries.map((e) => e.toModel()).toList();
  }
}

/// Implementación Drift de IWeighInRepository
///
/// Auto-sincroniza el peso más reciente con UserProfile.currentWeightKg
/// después de cada mutación (insert/update/delete).
class DriftWeighInRepository implements IWeighInRepository {
  final db.AppDatabase _db;
  final IUserProfileRepository? _userProfileRepo;

  DriftWeighInRepository(this._db, [this._userProfileRepo]);

  /// Sincroniza el peso más reciente con el perfil de usuario
  Future<void> _syncLatestWeightToProfile() async {
    if (_userProfileRepo == null) return;

    final latest = await getLatest();
    if (latest != null) {
      await _userProfileRepo.updateWeight(latest.weightKg);
    }
  }

  @override
  Future<List<models.WeighInModel>> getAll({int? limit}) async {
    final query = _db.select(_db.weighIns)
      ..orderBy([(w) => OrderingTerm.desc(w.measuredAt)]);
    if (limit != null) {
      query.limit(limit);
    }
    final weighIns = await query.get();
    return weighIns.map((w) => w.toModel()).toList();
  }

  @override
  Stream<List<models.WeighInModel>> watchAll() {
    return (_db.select(_db.weighIns)
          ..orderBy([(w) => OrderingTerm.desc(w.measuredAt)]))
        .watch()
        .map((weighIns) => weighIns.map((w) => w.toModel()).toList());
  }

  @override
  Future<List<models.WeighInModel>> getByDateRange(DateTime from, DateTime to) async {
    final weighIns = await (_db.select(_db.weighIns)
          ..where((w) => w.measuredAt.isBetweenValues(from, to))
          ..orderBy([(w) => OrderingTerm.desc(w.measuredAt)]))
        .get();
    return weighIns.map((w) => w.toModel()).toList();
  }

  @override
  Stream<List<models.WeighInModel>> watchByDateRange(DateTime from, DateTime to) {
    return (_db.select(_db.weighIns)
          ..where((w) => w.measuredAt.isBetweenValues(from, to))
          ..orderBy([(w) => OrderingTerm.desc(w.measuredAt)]))
        .watch()
        .map((weighIns) => weighIns.map((w) => w.toModel()).toList());
  }

  @override
  Future<models.WeighInModel?> getLatest() async {
    final query = _db.select(_db.weighIns)
      ..orderBy([(w) => OrderingTerm.desc(w.measuredAt)])
      ..limit(1);
    final weighIn = await query.getSingleOrNull();
    return weighIn?.toModel();
  }

  @override
  Future<models.WeighInModel?> getById(String id) async {
    final query = _db.select(_db.weighIns)..where((w) => w.id.equals(id));
    final weighIn = await query.getSingleOrNull();
    return weighIn?.toModel();
  }

  @override
  Future<void> insert(models.WeighInModel weighIn) async {
    await _db.into(_db.weighIns).insert(weighIn.toCompanion());
    // Auto-sync: actualizar perfil con el peso más reciente
    await _syncLatestWeightToProfile();
  }

  @override
  Future<void> update(models.WeighInModel weighIn) async {
    await _db.update(_db.weighIns).replace(weighIn.toCompanion());
    // Auto-sync: actualizar perfil con el peso más reciente
    await _syncLatestWeightToProfile();
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.weighIns)..where((w) => w.id.equals(id))).go();
    // Auto-sync: actualizar perfil con el peso más reciente (o null si no hay más)
    await _syncLatestWeightToProfile();
  }

  @override
  Future<models.WeightTrend?> calculateTrend({int days = 30}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final to = DateTime.now();
    final entries = await getByDateRange(from, to);
    if (entries.isEmpty) return null;
    return models.WeightTrend.fromEntries(entries);
  }
}

/// Implementación Drift de ITargetsRepository
class DriftTargetsRepository implements ITargetsRepository {
  final db.AppDatabase _db;
  final IDiaryRepository _diaryRepo;

  DriftTargetsRepository(this._db, this._diaryRepo);

  @override
  Future<List<models.TargetsModel>> getAll() async {
    final targets = await (_db.select(_db.targets)
          ..orderBy([(t) => OrderingTerm.desc(t.validFrom)]))
        .get();
    return targets.map((t) => t.toModel()).toList();
  }

  @override
  Stream<List<models.TargetsModel>> watchAll() {
    return (_db.select(_db.targets)
          ..orderBy([(t) => OrderingTerm.desc(t.validFrom)]))
        .watch()
        .map((targets) => targets.map((t) => t.toModel()).toList());
  }

  @override
  Future<models.TargetsModel?> getActiveForDate(DateTime date) async {
    final targets = await getAll();
    return models.TargetsModel.getActiveForDate(targets, date);
  }

  @override
  Future<models.TargetsModel?> getCurrent() async {
    return getActiveForDate(DateTime.now());
  }

  @override
  Future<void> insert(models.TargetsModel target) async {
    await _db.into(_db.targets).insert(target.toCompanion());
  }

  @override
  Future<void> update(models.TargetsModel target) async {
    await _db.update(_db.targets).replace(target.toCompanion());
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.targets)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<models.TargetsProgress> getProgressForDate(DateTime date) async {
    final targets = await getActiveForDate(date);
    final totals = await _diaryRepo.getDailyTotals(date);

    return models.TargetsProgress(
      targets: targets,
      kcalConsumed: totals.kcal,
      proteinConsumed: totals.protein,
      carbsConsumed: totals.carbs,
      fatConsumed: totals.fat,
    );
  }
}
