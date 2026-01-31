import 'dart:convert';

import 'package:drift/drift.dart';

import 'database_connection.dart';

part 'database.g.dart';

// ============================================================================
// TYPE CONVERTERS
// ============================================================================

/// Convierte `List<String>` a JSON string para almacenamiento SQL
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    try {
      return List<String>.from(json.decode(fromDb));
    } catch (e) {
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}

/// Convierte `Map<String, dynamic>` a JSON string para almacenamiento SQL
class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    if (fromDb.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(json.decode(fromDb));
    } catch (e) {
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return json.encode(value);
  }
}

/// Convierte MealType a string para almacenamiento SQL
class MealTypeConverter extends TypeConverter<MealType, String> {
  const MealTypeConverter();

  @override
  MealType fromSql(String fromDb) {
    return MealType.values.byName(fromDb);
  }

  @override
  String toSql(MealType value) {
    return value.name;
  }
}

/// Tipos de comida para el diario
enum MealType { breakfast, lunch, dinner, snack }

/// Unidades de medida para cantidades
enum ServingUnit { grams, portion, milliliter }

/// Convierte ServingUnit a string para almacenamiento SQL
class ServingUnitConverter extends TypeConverter<ServingUnit, String> {
  const ServingUnitConverter();

  @override
  ServingUnit fromSql(String fromDb) {
    return ServingUnit.values.byName(fromDb);
  }

  @override
  String toSql(ServingUnit value) {
    return value.name;
  }
}

// ============================================================================
// TRAINING TABLES
// ============================================================================

// 1. Routines
class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. Routine Days
class RoutineDays extends Table {
  TextColumn get id => text()();
  TextColumn get routineId =>
      text().references(Routines, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get progressionType => text().withDefault(
    const Constant('none'),
  )(); // 'none', 'lineal', 'double', 'percentage1RM'
  IntColumn get dayIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// 3. Routine Exercises
class RoutineExercises extends Table {
  TextColumn get id => text()(); // instanceId
  TextColumn get dayId =>
      text().references(RoutineDays, #id, onDelete: KeyAction.cascade)();

  // Library Data Embed
  TextColumn get libraryId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get musclesPrimary => text().map(const StringListConverter())();
  TextColumn get musclesSecondary => text().map(const StringListConverter())();
  TextColumn get equipment => text()();
  TextColumn get localImagePath => text().nullable()();

  // Routine Params
  IntColumn get series => integer()();
  TextColumn get repsRange => text()();
  IntColumn get suggestedRestSeconds => integer().nullable()();
  TextColumn get notes => text().nullable()();

  TextColumn get supersetId => text().nullable()();
  IntColumn get exerciseIndex => integer()();

  // Progression Config (v3)
  TextColumn get progressionType =>
      text().withDefault(const Constant('none'))();
  RealColumn get weightIncrement => real().withDefault(const Constant(2.5))();
  IntColumn get targetRpe => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 4. Sessions
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get routineId =>
      text().nullable()(); // Can be null if ad-hoc or deleted routine
  TextColumn get dayName => text().nullable()(); // Name of the day trained (v3)
  IntColumn get dayIndex => integer()
      .nullable()(); // Index of day in routine for smart suggestions (v3)
  DateTimeColumn get startTime => dateTime()();
  IntColumn get durationSeconds => integer().nullable()();
  BoolColumn get isBadDay =>
      boolean().withDefault(const Constant(false))(); // Flag para día malo (v4)

  // Active Session Flag: If completedAt is null, it's an active session.
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 5. Session Exercises
@TableIndex(name: 'session_exercises_name_idx', columns: {#name})
class SessionExercises extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();

  TextColumn get libraryId => text().nullable()();
  TextColumn get name => text()();

  // Snapshot Data
  TextColumn get musclesPrimary => text().map(const StringListConverter())();
  TextColumn get musclesSecondary => text().map(const StringListConverter())();
  TextColumn get equipment => text().nullable()(); // Made nullable just in case

  TextColumn get notes => text().nullable()();
  IntColumn get exerciseIndex => integer()();

  // Target vs Completed
  BoolColumn get isTarget => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 6. Sets
class WorkoutSets extends Table {
  TextColumn get id => text()(); // Changed from Int to Text (UUID)
  TextColumn get sessionExerciseId =>
      text().references(SessionExercises, #id, onDelete: KeyAction.cascade)();

  IntColumn get setIndex => integer()();

  RealColumn get weight => real()();
  IntColumn get reps => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(true))();
  IntColumn get rpe => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get restSeconds => integer().nullable()();

  BoolColumn get isFailure => boolean().withDefault(const Constant(false))();
  BoolColumn get isDropset => boolean().withDefault(const Constant(false))();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// 7. Exercise Notes
class ExerciseNotes extends Table {
  TextColumn get exerciseName => text()();
  TextColumn get note => text()();

  @override
  Set<Column> get primaryKey => {exerciseName};
}

// 8. User Profile (for TDEE calculation)
class UserProfiles extends Table {
  TextColumn get id => text()();
  IntColumn get age => integer().nullable()();
  TextColumn get gender => text().nullable()(); // 'male', 'female'
  RealColumn get heightCm => real().nullable()();
  RealColumn get currentWeightKg => real().nullable()();
  TextColumn get activityLevel => text().withDefault(const Constant('moderatelyActive'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// DIET TABLES (Schema v5)
// ============================================================================

/// Alimentos guardados en la base de datos
/// Pueden ser del sistema (seed), del usuario o verificados de fuentes externas
@TableIndex(name: 'foods_name_idx', columns: {#name})
@TableIndex(name: 'foods_barcode_idx', columns: {#barcode})
class Foods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get barcode => text().nullable()();

  // Valores nutricionales por 100g
  IntColumn get kcalPer100g => integer()();
  RealColumn get proteinPer100g => real().nullable()();
  RealColumn get carbsPer100g => real().nullable()();
  RealColumn get fatPer100g => real().nullable()();

  // Valores nutricionales por porción (opcional)
  TextColumn get portionName => text().nullable()(); // ej: "taza", "unidad", "rebanada"
  RealColumn get portionGrams => real().nullable()(); // gramos que representa 1 porción

  // Flags de origen y verificación
  BoolColumn get userCreated =>
      boolean().withDefault(const Constant(true))();
  TextColumn get verifiedSource => text().nullable()(); // 'usda', 'edamam', etc.
  TextColumn get sourceMetadata =>
      text().map(const JsonMapConverter()).nullable()(); // datos crudos de la fuente

  // 🆕 NUEVO: Campos para sistema de búsqueda inteligente
  TextColumn get normalizedName => text().nullable()(); // nombre normalizado para búsqueda
  IntColumn get useCount => integer().withDefault(const Constant(0))(); // contador de uso
  DateTimeColumn get lastUsedAt => dateTime().nullable()(); // última vez usado
  TextColumn get nutriScore => text().nullable()(); // Nutri-Score (a-e)
  IntColumn get novaGroup => integer().nullable()(); // Grupo NOVA (1-4)

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Entradas del diario de alimentos
/// Almacena tanto referencias a Foods como "quick add" libre
@TableIndex(name: 'diary_date_idx', columns: {#date})
@TableIndex(name: 'diary_date_meal_idx', columns: {#date, #mealType})
class DiaryEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()(); // Truncado a día
  TextColumn get mealType => text().map(const MealTypeConverter())();

  // Referencia opcional a Food (null si es quickAdd)
  TextColumn get foodId =>
      text().nullable().references(Foods, #id, onDelete: KeyAction.setNull)();

  // Información del alimento (denormalizada para historial)
  TextColumn get foodName => text()(); // Nombre mostrado (de Food o custom)
  TextColumn get foodBrand => text().nullable()();

  // Cantidad consumida
  RealColumn get amount => real()(); // cantidad numérica
  TextColumn get unit =>
      text().map(const ServingUnitConverter())(); // unidad de medida

  // Valores nutricionales calculados para esta entrada (desnormalizado)
  IntColumn get kcal => integer()();
  RealColumn get protein => real().nullable()();
  RealColumn get carbs => real().nullable()();
  RealColumn get fat => real().nullable()();

  // Para quickAdd libre: macros originales ingresados por usuario
  BoolColumn get isQuickAdd => boolean().withDefault(const Constant(false))();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Registros de peso corporal
@TableIndex(name: 'weighin_date_idx', columns: {#measuredAt})
class WeighIns extends Table {
  TextColumn get id => text()();
  DateTimeColumn get measuredAt => dateTime()(); // Fecha y hora exacta del pesaje
  RealColumn get weightKg => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Objetivos diarios versionados por fecha de inicio
/// Permite cambiar objetivos a lo largo del tiempo manteniendo historial
@TableIndex(name: 'targets_validfrom_idx', columns: {#validFrom})
class Targets extends Table {
  TextColumn get id => text()();
  DateTimeColumn get validFrom => dateTime()(); // Desde qué fecha aplica
  IntColumn get kcalTarget => integer()();
  RealColumn get proteinTarget => real().nullable()();
  RealColumn get carbsTarget => real().nullable()();
  RealColumn get fatTarget => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recetas / Comidas compuestas
/// Una receta es un Food especial que agrupa otros foods
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();

  // Totales calculados (se actualizan al modificar ingredientes)
  IntColumn get totalKcal => integer()();
  RealColumn get totalProtein => real().nullable()();
  RealColumn get totalCarbs => real().nullable()();
  RealColumn get totalFat => real().nullable()();
  RealColumn get totalGrams => real()(); // Peso total de la receta

  // Porciones
  IntColumn get servings => integer().withDefault(const Constant(1))();
  TextColumn get servingName => text().nullable()(); // ej: "porción", "taza"

  BoolColumn get userCreated =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ingredientes de una receta
class RecipeItems extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get foodId =>
      text().references(Foods, #id, onDelete: KeyAction.cascade)();

  RealColumn get amount => real()(); // cantidad en gramos o unidades
  TextColumn get unit =>
      text().map(const ServingUnitConverter())();

  // Datos snapshot del food en el momento de agregarlo
  TextColumn get foodNameSnapshot => text()();
  IntColumn get kcalPer100gSnapshot => integer()();
  RealColumn get proteinPer100gSnapshot => real().nullable()();
  RealColumn get carbsPer100gSnapshot => real().nullable()();
  RealColumn get fatPer100gSnapshot => real().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// 🆕 NUEVO: TABLAS PARA SISTEMA DE BÚSQUEDA INTELIGENTE (Schema v7)
// ============================================================================

/// Tabla FTS5 para búsqueda de texto completo en alimentos
/// Esta es una tabla virtual que mantiene un índice invertido de los alimentos
@TableIndex(name: 'foods_fts_idx', columns: {#name, #brand})
class FoodsFts extends Table {
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  
  // rowid se mapea automáticamente al id de Foods
}

/// Historial de búsquedas para sugerencias y análisis
@TableIndex(name: 'search_history_query_idx', columns: {#normalizedQuery})
@TableIndex(name: 'search_history_date_idx', columns: {#searchedAt})
class SearchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get query => text()(); // Query original
  TextColumn get normalizedQuery => text()(); // Query normalizado (lowercase, trimmed)
  TextColumn get selectedFoodId => text().nullable()(); // ID del alimento seleccionado (si aplica)
  DateTimeColumn get searchedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get hasResults => boolean().withDefault(const Constant(true))();
}

/// Patrones de consumo para ML predictivo
/// Almacena cuándo y qué alimentos consume el usuario para sugerencias inteligentes
@TableIndex(name: 'consumption_patterns_unique_idx', columns: {#foodId, #hourOfDay, #dayOfWeek})
class ConsumptionPatterns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get foodId => text().references(Foods, #id, onDelete: KeyAction.cascade)();
  IntColumn get hourOfDay => integer()(); // 0-23
  IntColumn get dayOfWeek => integer()(); // 1-7 (lunes=1, domingo=7)
  TextColumn get mealType => text().map(const MealTypeConverter()).nullable()();
  IntColumn get frequency => integer().withDefault(const Constant(1))(); // Cuántas veces se ha consumido
  DateTimeColumn get lastConsumedAt => dateTime()();
}

@DriftDatabase(
  tables: [
    // Training
    Routines,
    RoutineDays,
    RoutineExercises,
    Sessions,
    SessionExercises,
    WorkoutSets,
    ExerciseNotes,
    // User Profile
    UserProfiles,
    // Diet
    Foods,
    DiaryEntries,
    WeighIns,
    Targets,
    Recipes,
    RecipeItems,
    // 🆕 Search System
    FoodsFts,
    SearchHistory,
    ConsumptionPatterns,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Named constructor for tests to allow injecting a custom [QueryExecutor]
  /// such as an in-memory database via [NativeDatabase.memory()].
  AppDatabase.forTesting(super.executor);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // 🆕 Crear tabla FTS5 virtual
      await _createFts5Tables(m);
    },
    onUpgrade: (m, from, to) async {
      // Migration path to version 2: add supersetId column to routine_exercises
      if (from < 2) {
        try {
          await m.addColumn(routineExercises, routineExercises.supersetId);
        } catch (e) {
          // Column might already exist
        }
      }
      // Migration path to version 3: add progression columns and session day info
      if (from < 3) {
        try {
          await m.addColumn(routineExercises, routineExercises.progressionType);
          await m.addColumn(routineExercises, routineExercises.weightIncrement);
          await m.addColumn(routineExercises, routineExercises.targetRpe);
          await m.addColumn(sessions, sessions.dayName);
          await m.addColumn(sessions, sessions.dayIndex);
        } catch (e) {
          // Columns might already exist in some edge cases
        }
      }
      // Migration path to version 4: add isBadDay flag for error tolerance
      if (from < 4) {
        try {
          await m.addColumn(sessions, sessions.isBadDay);
        } catch (e) {
          // Column might already exist
        }
      }
      // Migration path to version 5: add Diet tables (Foods, DiaryEntries, WeighIns, Targets, Recipes, RecipeItems)
      if (from < 5) {
        try {
          await m.createTable(foods);
          await m.createTable(diaryEntries);
          await m.createTable(weighIns);
          await m.createTable(targets);
          await m.createTable(recipes);
          await m.createTable(recipeItems);
        } catch (e) {
          // Tables might already exist
        }
      }
      // Migration path to version 6: add UserProfiles table
      if (from < 6) {
        try {
          await m.createTable(userProfiles);
        } catch (e) {
          // Table might already exist
        }
      }
      // 🆕 Migration path to version 7: add Search System tables (FoodsFts, SearchHistory, ConsumptionPatterns)
      if (from < 7) {
        try {
          // Agregar columnas nuevas a Foods
          await m.addColumn(foods, foods.normalizedName);
          await m.addColumn(foods, foods.useCount);
          await m.addColumn(foods, foods.lastUsedAt);
          await m.addColumn(foods, foods.nutriScore);
          await m.addColumn(foods, foods.novaGroup);
          
          // Crear tablas de búsqueda
          await m.createTable(searchHistory);
          await m.createTable(consumptionPatterns);
          
          // Crear tabla FTS5 virtual y triggers
          await _createFts5Tables(m);
        } catch (e) {
          // Tables or columns might already exist
        }
      }
    },
  );

  /// 🆕 Crea tabla FTS5 virtual para búsqueda de alimentos
  /// Usa un enfoque external content con sincronización manual
  Future<void> _createFts5Tables(Migrator m) async {
    // Crear tabla virtual FTS5 sin content_rowid
    // Usamos 'id' como columna UNINDEXED para almacenar el UUID
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS foods_fts USING fts5(
        name,
        brand,
        food_id UNINDEXED
      )
    ''');
  }
  
  /// 🆕 Inserta entrada en FTS5 para un alimento
  Future<void> insertFoodFts(String foodId, String name, String? brand) async {
    await customStatement('''
      INSERT INTO foods_fts(name, brand, food_id) VALUES (?, ?, ?)
    ''', [name, brand, foodId]);
  }
  
  /// 🆕 Actualiza entrada en FTS5 para un alimento
  Future<void> updateFoodFts(String foodId, String name, String? brand) async {
    await customStatement('''
      UPDATE foods_fts SET name = ?, brand = ? WHERE food_id = ?
    ''', [name, brand, foodId]);
  }
  
  /// 🆕 Elimina entrada en FTS5 para un alimento
  Future<void> deleteFoodFts(String foodId) async {
    await customStatement('''
      DELETE FROM foods_fts WHERE food_id = ?
    ''', [foodId]);
  }

  @override
  int get schemaVersion => 7;

  // ============================================================================
  // 🆕 NUEVO: MÉTODOS DE BÚSQUEDA FTS5
  // ============================================================================

  /// Búsqueda FTS5 con ranking por relevancia
  Future<List<Food>> searchFoodsFTS(String query, {int limit = 50}) async {
    if (query.trim().isEmpty) return [];
    
    // Normalizar query para FTS (agregar wildcard para búsqueda por prefijo)
    final ftsQuery = '${query.trim()}*';
    
    // Usar SQL directo y mapear resultados manualmente
    // JOIN entre foods_fts (que contiene food_id) y foods
    final results = await customSelect(
      'SELECT f.id, f.name, f.normalized_name, f.brand, f.barcode, '
      'f.kcal_per_100g, f.protein_per_100g, f.carbs_per_100g, f.fat_per_100g, '
      'f.portion_name, f.portion_grams, f.user_created, f.verified_source, '
      'f.source_metadata, f.use_count, f.last_used_at, f.nutri_score, f.nova_group, '
      'f.created_at, f.updated_at FROM foods f '
      'INNER JOIN foods_fts fts ON f.id = fts.food_id '
      'WHERE fts MATCH ? '
      'ORDER BY rank '
      'LIMIT ?',
      variables: [Variable(ftsQuery), Variable(limit)],
    ).get();
    
    return results.map((row) => _mapRowToFood(row)).toList();
  }
  
  /// Mapea una fila de query a Food
  Food _mapRowToFood(QueryRow row) {
    return Food(
      id: row.read<String>('id'),
      name: row.read<String>('name'),
      normalizedName: row.read<String?>('normalized_name'),
      brand: row.read<String?>('brand'),
      barcode: row.read<String?>('barcode'),
      kcalPer100g: row.read<int>('kcal_per_100g'),
      proteinPer100g: row.read<double?>('protein_per_100g'),
      carbsPer100g: row.read<double?>('carbs_per_100g'),
      fatPer100g: row.read<double?>('fat_per_100g'),
      portionName: row.read<String?>('portion_name'),
      portionGrams: row.read<double?>('portion_grams'),
      userCreated: row.read<bool>('user_created'),
      verifiedSource: row.read<String?>('verified_source'),
      sourceMetadata: _jsonFromString(row.read<String?>('source_metadata')),
      useCount: row.read<int>('use_count'),
      lastUsedAt: _dateTimeFromString(row.read<String?>('last_used_at')),
      nutriScore: row.read<String?>('nutri_score'),
      novaGroup: row.read<int?>('nova_group'),
      createdAt: DateTime.parse(row.read<String>('created_at')),
      updatedAt: DateTime.parse(row.read<String>('updated_at')),
    );
  }
  
  /// Helper para convertir string JSON a Map
  Map<String, dynamic>? _jsonFromString(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }
  
  /// Helper para convertir string a DateTime
  DateTime? _dateTimeFromString(String? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  /// Búsqueda por prefijo (para autocompletado rápido)
  Future<List<Food>> searchFoodsByPrefix(String prefix, {int limit = 10}) async {
    final normalized = prefix.toLowerCase().trim();
    
    return (select(foods)
      ..where((f) => f.normalizedName.like('$normalized%'))
      ..orderBy([
        (f) => OrderingTerm.desc(f.useCount),
        (f) => OrderingTerm.asc(f.normalizedName),
      ])
      ..limit(limit))
      .get();
  }

  /// Búsqueda offline completa (FTS + fallback a LIKE)
  Future<List<Food>> searchFoodsOffline(String query, {int limit = 50}) async {
    // Intentar FTS primero
    final ftsResults = await searchFoodsFTS(query, limit: limit);
    if (ftsResults.isNotEmpty) return ftsResults;
    
    // Fallback a LIKE en nombre y marca
    final normalized = query.toLowerCase().trim();
    return (select(foods)
      ..where((f) => 
        f.normalizedName.like('%$normalized%') | 
        f.brand.like('%$normalized%')
      )
      ..orderBy([
        (f) => OrderingTerm.desc(f.useCount),
        (f) => OrderingTerm.desc(f.lastUsedAt),
      ])
      ..limit(limit))
      .get();
  }

  /// Sugerencias de autocompletado basadas en historial y alimentos populares
  Future<List<String>> getSearchSuggestions(String prefix, {int limit = 10}) async {
    final normalized = prefix.toLowerCase().trim();
    
    // 1. Buscar en historial de búsquedas
    final historial = await (select(searchHistory)
      ..where((h) => h.normalizedQuery.like('$normalized%'))
      ..orderBy([(h) => OrderingTerm.desc(h.searchedAt)])
      ..limit(limit))
      .map((h) => h.query)
      .get();
    
    // 2. Buscar en nombres de alimentos populares
    final populares = await (select(foods)
      ..where((f) => f.normalizedName.like('$normalized%'))
      ..orderBy([(f) => OrderingTerm.desc(f.useCount)])
      ..limit(limit))
      .map((f) => f.name)
      .get();
    
    // Combinar sin duplicados manteniendo orden
    return {...historial, ...populares}.take(limit).toList();
  }

  /// Alimentos más usados recientemente (para sugerencias predictivas)
  Future<List<Food>> getHabitualFoods({
    int? hourOfDay,
    int? dayOfWeek,
    int limit = 20,
  }) async {
    // Si tenemos contexto temporal, buscar patrones de consumo
    if (hourOfDay != null && dayOfWeek != null) {
      final patrones = await (select(consumptionPatterns)
        ..where((p) => p.hourOfDay.equals(hourOfDay) & p.dayOfWeek.equals(dayOfWeek))
        ..orderBy([(p) => OrderingTerm.desc(p.frequency)])
        ..limit(limit))
        .get();
      
      if (patrones.isNotEmpty) {
        final foodIds = patrones.map((p) => p.foodId).toList();
        return (select(foods)
          ..where((f) => f.id.isIn(foodIds)))
          .get();
      }
    }
    
    // Fallback: alimentos más usados globalmente
    return (select(foods)
      ..where((f) => f.useCount.isBiggerThanValue(0))
      ..orderBy([
        (f) => OrderingTerm.desc(f.useCount),
        (f) => OrderingTerm.desc(f.lastUsedAt),
      ])
      ..limit(limit))
      .get();
  }

  /// Registrar uso de un alimento (para estadísticas y ML predictivo)
  Future<void> recordFoodUsage(String foodId, {MealType? mealType}) async {
    final now = DateTime.now();
    
    // Actualizar contador del alimento con SQL directo
    await customStatement(
      'UPDATE foods SET use_count = use_count + 1, last_used_at = ? WHERE id = ?',
      [now.toIso8601String(), foodId],
    );
    
    // Actualizar patrón de consumo con SQL directo (UPSERT)
    await customStatement('''
      INSERT INTO consumption_patterns (food_id, hour_of_day, day_of_week, meal_type, frequency, last_consumed_at)
      VALUES (?, ?, ?, ?, 1, ?)
      ON CONFLICT(food_id, hour_of_day, day_of_week) DO UPDATE SET
        frequency = frequency + 1,
        last_consumed_at = excluded.last_consumed_at,
        meal_type = excluded.meal_type
    ''', [foodId, now.hour, now.weekday, mealType?.name, now.toIso8601String()]);
  }

  /// Guardar búsqueda en historial
  Future<void> saveSearchHistory(String query, {String? selectedFoodId, bool hasResults = true}) async {
    await into(searchHistory).insert(
      SearchHistoryCompanion(
        query: Value(query),
        normalizedQuery: Value(query.toLowerCase().trim()),
        selectedFoodId: Value(selectedFoodId),
        hasResults: Value(hasResults),
      ),
    );
  }

  /// Limpiar historial de búsquedas antiguo (mantener últimos 100)
  Future<void> cleanupOldSearchHistory() async {
    await customStatement('''
      DELETE FROM search_history 
      WHERE id NOT IN (
        SELECT id FROM search_history 
        ORDER BY searched_at DESC 
        LIMIT 100
      )
    ''');
  }
}
