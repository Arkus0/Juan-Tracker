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

// Tables

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
    },
  );

  @override
  int get schemaVersion => 6;
}
