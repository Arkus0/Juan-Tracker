import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../../diet/utils/spanish_text_utils.dart';
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
      debugPrint('[StringListConverter] JSON parse error: $e | Data: $fromDb');
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
      debugPrint('[JsonMapConverter] JSON parse error: $e | Data: $fromDb');
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
    try {
      return MealType.values.byName(fromDb);
    } catch (e) {
      debugPrint(
        '[MealTypeConverter] Unknown value "$fromDb", defaulting to snack',
      );
      return MealType.snack; // Default seguro
    }
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
    try {
      return ServingUnit.values.byName(fromDb);
    } catch (e) {
      debugPrint(
        '[ServingUnitConverter] Unknown value "$fromDb", defaulting to grams',
      );
      return ServingUnit.grams; // Default seguro
    }
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

  // 🆕 Schema v9: Modo de scheduling para sugerencias inteligentes
  // 'sequential' (default), 'weeklyAnchored', 'floatingCycle'
  TextColumn get schedulingMode =>
      text().withDefault(const Constant('sequential'))();

  // 🆕 Schema v9: Configuración JSON adicional para scheduling
  // Ej: {"minRestHours": 20, "autoAlternate": true}
  TextColumn get schedulingConfig => text().nullable()();

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

  // 🆕 Schema v9: Días de la semana asignados (JSON array [1,3,5] = Lunes, Miércoles, Viernes)
  TextColumn get weekdays => text().nullable()();

  // 🆕 Schema v9: Horas mínimas de descanso después de este día específico
  IntColumn get minRestHours => integer().nullable()();

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
  TextColumn get setType =>
      text().withDefault(const Constant('normal'))();

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
  BoolColumn get isRestPause => boolean().withDefault(const Constant(false))();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  BoolColumn get isMyoReps => boolean().withDefault(const Constant(false))();
  BoolColumn get isAmrap => boolean().withDefault(const Constant(false))();

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
  TextColumn get activityLevel =>
      text().withDefault(const Constant('moderatelyActive'))();
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

  // Micronutrientes por 100g (v16)
  RealColumn get fiberPer100g => real().nullable()();
  RealColumn get sugarPer100g => real().nullable()();
  RealColumn get saturatedFatPer100g => real().nullable()();
  RealColumn get sodiumPer100g => real().nullable()();

  // Valores nutricionales por porción (opcional)
  TextColumn get portionName =>
      text().nullable()(); // ej: "taza", "unidad", "rebanada"
  RealColumn get portionGrams =>
      real().nullable()(); // gramos que representa 1 porción

  // Flags de origen y verificación
  BoolColumn get userCreated => boolean().withDefault(const Constant(true))();
  TextColumn get verifiedSource =>
      text().nullable()(); // 'usda', 'edamam', etc.
  TextColumn get sourceMetadata => text()
      .map(const JsonMapConverter())
      .nullable()(); // datos crudos de la fuente

  // 🆕 NUEVO: Campos para sistema de búsqueda inteligente
  TextColumn get normalizedName =>
      text().nullable()(); // nombre normalizado para búsqueda
  IntColumn get useCount =>
      integer().withDefault(const Constant(0))(); // contador de uso
  DateTimeColumn get lastUsedAt => dateTime().nullable()(); // última vez usado
  TextColumn get nutriScore => text().nullable()(); // Nutri-Score (a-e)
  IntColumn get novaGroup => integer().nullable()(); // Grupo NOVA (1-4)

  // 🆕 NUEVO: Campo para favoritos
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // marcado como favorito

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

  // Micronutrientes (v16)
  RealColumn get fiber => real().nullable()();
  RealColumn get sugar => real().nullable()();
  RealColumn get saturatedFat => real().nullable()();
  RealColumn get sodium => real().nullable()();

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
  DateTimeColumn get measuredAt =>
      dateTime()(); // Fecha y hora exacta del pesaje
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

  // Micronutrient targets (v16)
  RealColumn get fiberTarget => real().nullable()();
  RealColumn get sugarLimit => real().nullable()();
  RealColumn get saturatedFatLimit => real().nullable()();
  RealColumn get sodiumLimit => real().nullable()();

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
  RealColumn get totalFiber => real().nullable()();
  RealColumn get totalSugar => real().nullable()();
  RealColumn get totalSaturatedFat => real().nullable()();
  RealColumn get totalSodium => real().nullable()();
  RealColumn get totalGrams => real()(); // Peso total de la receta

  // Porciones
  IntColumn get servings => integer().withDefault(const Constant(1))();
  TextColumn get servingName => text().nullable()(); // ej: "porción", "taza"

  BoolColumn get userCreated => boolean().withDefault(const Constant(true))();
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
  TextColumn get unit => text().map(const ServingUnitConverter())();

  // Datos snapshot del food en el momento de agregarlo
  TextColumn get foodNameSnapshot => text()();
  IntColumn get kcalPer100gSnapshot => integer()();
  RealColumn get proteinPer100gSnapshot => real().nullable()();
  RealColumn get carbsPer100gSnapshot => real().nullable()();
  RealColumn get fatPer100gSnapshot => real().nullable()();
  RealColumn get fiberPer100gSnapshot => real().nullable()();
  RealColumn get sugarPer100gSnapshot => real().nullable()();
  RealColumn get saturatedFatPer100gSnapshot => real().nullable()();
  RealColumn get sodiumPer100gSnapshot => real().nullable()();
  RealColumn get portionGramsSnapshot => real().nullable()();

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
  TextColumn get normalizedQuery =>
      text()(); // Query normalizado (lowercase, trimmed)
  TextColumn get selectedFoodId =>
      text().nullable()(); // ID del alimento seleccionado (si aplica)
  DateTimeColumn get searchedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get hasResults => boolean().withDefault(const Constant(true))();
}

/// Patrones de consumo para ML predictivo
/// Almacena cuándo y qué alimentos consume el usuario para sugerencias inteligentes
@TableIndex(
  name: 'consumption_patterns_unique_idx',
  columns: {#foodId, #hourOfDay, #dayOfWeek},
)
class ConsumptionPatterns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get foodId =>
      text().references(Foods, #id, onDelete: KeyAction.cascade)();
  IntColumn get hourOfDay => integer()(); // 0-23
  IntColumn get dayOfWeek => integer()(); // 1-7 (lunes=1, domingo=7)
  TextColumn get mealType => text().map(const MealTypeConverter()).nullable()();
  IntColumn get frequency => integer().withDefault(
    const Constant(1),
  )(); // Cuántas veces se ha consumido
  DateTimeColumn get lastConsumedAt => dateTime()();
}

// ============================================================================
// 🆕 NUEVO: MEAL TEMPLATES (Schema v12)
// ============================================================================

/// Plantillas de comidas guardadas para quick-add
/// Permite guardar una comida completa (ej: "Desayuno típico") para añadirla con 1 toque
@TableIndex(name: 'meal_templates_name_idx', columns: {#name})
class MealTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()(); // Nombre de la plantilla: "Desayuno típico"
  TextColumn get mealType =>
      text().map(const MealTypeConverter())(); // Tipo de comida sugerido
  IntColumn get useCount =>
      integer().withDefault(const Constant(0))(); // Para ordenar por uso
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Items de una plantilla de comida
/// Cada item representa un alimento con su cantidad
class MealTemplateItems extends Table {
  TextColumn get id => text()();
  TextColumn get templateId =>
      text().references(MealTemplates, #id, onDelete: KeyAction.cascade)();
  TextColumn get foodId =>
      text().references(Foods, #id, onDelete: KeyAction.cascade)();

  RealColumn get amount => real()(); // Cantidad en gramos
  TextColumn get unit => text().map(const ServingUnitConverter())();

  // Snapshot del alimento al momento de crear la plantilla (para mostrar aunque se borre el food)
  TextColumn get foodNameSnapshot => text()();
  IntColumn get kcalPer100gSnapshot => integer()();
  RealColumn get proteinPer100gSnapshot => real().nullable()();
  RealColumn get carbsPer100gSnapshot => real().nullable()();
  RealColumn get fatPer100gSnapshot => real().nullable()();
  RealColumn get fiberPer100gSnapshot => real().nullable()();
  RealColumn get sugarPer100gSnapshot => real().nullable()();
  RealColumn get saturatedFatPer100gSnapshot => real().nullable()();
  RealColumn get sodiumPer100gSnapshot => real().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// 🆕 NUEVO: BODY PROGRESS - MEDIDAS Y FOTOS (Schema v13)
// ============================================================================

/// Medidas corporales registradas por el usuario
/// Permite trackear evolución de cintura, pecho, brazos, etc.
@TableIndex(name: 'body_measurements_date_idx', columns: {#date})
class BodyMeasurements extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()(); // Fecha de la medición

  // Medidas principales (todas en cm)
  RealColumn get weightKg =>
      real().nullable()(); // Peso al momento de la medición
  RealColumn get waistCm => real().nullable()(); // Cintura
  RealColumn get chestCm => real().nullable()(); // Pecho
  RealColumn get hipsCm => real().nullable()(); // Cadera
  RealColumn get leftArmCm => real().nullable()(); // Brazo izquierdo
  RealColumn get rightArmCm => real().nullable()(); // Brazo derecho
  RealColumn get leftThighCm => real().nullable()(); // Muslo izquierdo
  RealColumn get rightThighCm => real().nullable()(); // Muslo derecho
  RealColumn get leftCalfCm => real().nullable()(); // Pantorrilla izquierda
  RealColumn get rightCalfCm => real().nullable()(); // Pantorrilla derecha
  RealColumn get neckCm => real().nullable()(); // Cuello

  // Cálculo automático de grasa corporal (opcional)
  RealColumn get bodyFatPercentage => real().nullable()();

  // Metadatos
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Fotos de progreso del usuario
/// Almacena referencias a imágenes guardadas localmente
@TableIndex(name: 'progress_photos_date_idx', columns: {#date})
class ProgressPhotos extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()(); // Fecha de la foto

  // Ruta de la imagen guardada localmente
  TextColumn get imagePath => text()();

  // Categoría de la foto (front, side, back, etc.)
  TextColumn get category => text().withDefault(const Constant('front'))();
  // Valores posibles: 'front', 'side', 'back', 'upper', 'lower', 'other'

  // Notas opcionales
  TextColumn get notes => text().nullable()();

  // Relación opcional con medidas del mismo día
  TextColumn get measurementId => text().nullable().references(
    BodyMeasurements,
    #id,
    onDelete: KeyAction.setNull,
  )();

  DateTimeColumn get createdAt => dateTime()();

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
    // 🆕 Search System
    FoodsFts,
    SearchHistory,
    ConsumptionPatterns,
    // 🆕 Meal Templates (v12)
    MealTemplates,
    MealTemplateItems,
    // 🆕 Body Progress (v13)
    BodyMeasurements,
    ProgressPhotos,
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
      // Migration path to version 8: Fix FTS5 structure (TEXT id instead of INTEGER rowid)
      if (from < 8 && from >= 7) {
        try {
          // Eliminar triggers antiguos
          await customStatement('DROP TRIGGER IF EXISTS foods_fts_insert');
          await customStatement('DROP TRIGGER IF EXISTS foods_fts_update');
          await customStatement('DROP TRIGGER IF EXISTS foods_fts_delete');
          // Eliminar tabla FTS antigua
          await customStatement('DROP TABLE IF EXISTS foods_fts');
          // Recrear con estructura correcta
          await _createFts5Tables(m);
        } catch (e) {
          debugPrint('Migration v8 FTS rebuild error: $e');
        }
      }
      // 🆕 Migration path to version 9: Add scheduling mode columns
      if (from < 9) {
        try {
          // Añadir columnas de scheduling a Routines
          await m.addColumn(routines, routines.schedulingMode);
          await m.addColumn(routines, routines.schedulingConfig);

          // Añadir columnas de scheduling a RoutineDays
          await m.addColumn(routineDays, routineDays.weekdays);
          await m.addColumn(routineDays, routineDays.minRestHours);
        } catch (e) {
          debugPrint('Migration v9 scheduling columns error: $e');
        }
      }
      // 🆕 Migration path to version 10: Fix FTS5 table and add isFavorite column
      if (from < 10) {
        try {
          // Añadir columna isFavorite a foods
          await m.addColumn(foods, foods.isFavorite);

          // Recrear tabla FTS5 con estructura correcta
          await customStatement('DROP TABLE IF EXISTS foods_fts');
          await _createFts5Tables(m);
        } catch (e) {
          debugPrint('Migration v10 FTS fix error: $e');
        }
      }
      // 🆕 Migration path to version 11: Recreate FTS5 with fixes
      if (from < 11) {
        try {
          // Forzar recreación completa de FTS5 con el nuevo formato de búsqueda
          await customStatement('DROP TABLE IF EXISTS foods_fts');
          await _createFts5Tables(m);
          debugPrint('Migration v11: FTS5 table recreated successfully');
        } catch (e) {
          debugPrint('Migration v11 FTS recreate error: $e');
        }
      }
      // 🆕 Migration path to version 12: Add Meal Templates tables
      if (from < 12) {
        try {
          await m.createTable(mealTemplates);
          await m.createTable(mealTemplateItems);
          debugPrint(
            'Migration v12: MealTemplates tables created successfully',
          );
        } catch (e) {
          debugPrint('Migration v12 MealTemplates error: $e');
        }
      }
      // 🆕 Migration path to version 13: Add Body Progress tables (measurements and photos)
      if (from < 13) {
        try {
          await m.createTable(bodyMeasurements);
          await m.createTable(progressPhotos);
          debugPrint(
            'Migration v13: BodyMeasurements and ProgressPhotos tables created successfully',
          );
        } catch (e) {
          debugPrint('Migration v13 BodyProgress error: $e');
        }
      }
      // 🆕 Migration path to version 14: Add isRestPause column to WorkoutSets
        if (from < 14) {
          try {
            await m.addColumn(workoutSets, workoutSets.isRestPause);
            debugPrint('Migration v14: isRestPause column added successfully');
          } catch (e) {
            debugPrint('Migration v14 isRestPause error: $e');
          }
        }
        // ðŸ†• Migration path to version 15: Add setType to RoutineExercises and Myo/AMRAP flags
        if (from < 15) {
          try {
            await m.addColumn(routineExercises, routineExercises.setType);
            await m.addColumn(workoutSets, workoutSets.isMyoReps);
            await m.addColumn(workoutSets, workoutSets.isAmrap);
            debugPrint(
              'Migration v15: setType + myo/amrap columns added successfully',
            );
          } catch (e) {
            debugPrint('Migration v15 setType/myo/amrap error: $e');
          }
        }
        // 🆕 Migration path to version 16: Micronutrients expansion
        if (from < 16) {
          try {
            // Foods: añadir micronutrientes por 100g
            await m.addColumn(foods, foods.fiberPer100g);
            await m.addColumn(foods, foods.sugarPer100g);
            await m.addColumn(foods, foods.saturatedFatPer100g);
            await m.addColumn(foods, foods.sodiumPer100g);

            // DiaryEntries: añadir micronutrientes por entrada
            await m.addColumn(diaryEntries, diaryEntries.fiber);
            await m.addColumn(diaryEntries, diaryEntries.sugar);
            await m.addColumn(diaryEntries, diaryEntries.saturatedFat);
            await m.addColumn(diaryEntries, diaryEntries.sodium);

            // Targets: añadir objetivos de micronutrientes
            await m.addColumn(targets, targets.fiberTarget);
            await m.addColumn(targets, targets.sugarLimit);
            await m.addColumn(targets, targets.saturatedFatLimit);
            await m.addColumn(targets, targets.sodiumLimit);

            // RecipeItems: añadir snapshots de micronutrientes
            await m.addColumn(recipeItems, recipeItems.fiberPer100gSnapshot);
            await m.addColumn(recipeItems, recipeItems.sugarPer100gSnapshot);
            await m.addColumn(recipeItems, recipeItems.saturatedFatPer100gSnapshot);
            await m.addColumn(recipeItems, recipeItems.sodiumPer100gSnapshot);

            // MealTemplateItems: añadir snapshots de micronutrientes
            await m.addColumn(mealTemplateItems, mealTemplateItems.fiberPer100gSnapshot);
            await m.addColumn(mealTemplateItems, mealTemplateItems.sugarPer100gSnapshot);
            await m.addColumn(mealTemplateItems, mealTemplateItems.saturatedFatPer100gSnapshot);
            await m.addColumn(mealTemplateItems, mealTemplateItems.sodiumPer100gSnapshot);

            debugPrint(
              'Migration v16: Micronutrient columns added successfully',
            );
          } catch (e) {
            debugPrint('Migration v16 micronutrients error: $e');
          }
        }
        // 🆕 Migration path to version 17: Recipe micronutrient totals + portionGramsSnapshot
        if (from < 17) {
          try {
            // Recipes: añadir totales de micronutrientes
            await m.addColumn(recipes, recipes.totalFiber);
            await m.addColumn(recipes, recipes.totalSugar);
            await m.addColumn(recipes, recipes.totalSaturatedFat);
            await m.addColumn(recipes, recipes.totalSodium);

            // RecipeItems: añadir portionGramsSnapshot
            await m.addColumn(recipeItems, recipeItems.portionGramsSnapshot);

            debugPrint(
              'Migration v17: Recipe micro columns + portionGramsSnapshot added',
            );
          } catch (e) {
            debugPrint('Migration v17 error: $e');
          }
        }
      },
    );

  /// 🆕 Crea tabla FTS5 virtual para búsqueda de alimentos
  /// Usa un enfoque external content con sincronización manual
  ///
  /// SEGURIDAD: Realiza backup de datos existentes antes de recrear la tabla
  /// para permitir recuperación en caso de error durante la migración.
  Future<void> _createFts5Tables(Migrator m) async {
    // Verificar si existe tabla previa para backup
    List<QueryRow> existingData = [];
    try {
      existingData = await customSelect(
        'SELECT food_id, name, brand FROM foods_fts LIMIT 10000',
      ).get();
      if (existingData.isNotEmpty) {
        debugPrint(
          '[FTS] Backing up ${existingData.length} existing FTS entries before migration',
        );
      }
    } catch (e) {
      // Tabla no existe o está corrupta - continuar sin backup
      debugPrint('[FTS] No existing table to backup: $e');
    }

    try {
      // Eliminar tabla si existe para asegurar estructura correcta
      // ( FTS5 no permite ALTER TABLE, así que recreamos siempre )
      await customStatement('DROP TABLE IF EXISTS foods_fts');

      // Crear tabla virtual FTS5 sin content_rowid
      // Usamos 'food_id' como columna UNINDEXED para almacenar el UUID
      await customStatement('''
        CREATE VIRTUAL TABLE foods_fts USING fts5(
          food_id UNINDEXED,
          name,
          brand
        )
      ''');

      // Poblar índice FTS con datos existentes
      await rebuildFtsIndex();

      // Verificar que la migración fue exitosa
      final countResult = await customSelect(
        'SELECT COUNT(*) as cnt FROM foods_fts',
      ).getSingle();
      final newCount = countResult.data['cnt'] as int;

      if (newCount == 0 && existingData.isNotEmpty) {
        debugPrint(
          '[FTS] WARNING: Migration resulted in empty index, attempting restore from backup',
        );
        // Intentar restaurar desde backup
        for (final row in existingData) {
          try {
            await insertFoodFts(
              row.data['food_id'] as String,
              row.data['name'] as String,
              row.data['brand'] as String?,
            );
          } catch (e) {
            debugPrint('[FTS] Failed to restore entry: $e');
          }
        }
      }

      debugPrint('[FTS] Migration successful: $newCount entries in index');
    } catch (e) {
      debugPrint('[FTS] CRITICAL ERROR during FTS migration: $e');
      // Intentar recuperación con estructura mínima
      try {
        await customStatement('DROP TABLE IF EXISTS foods_fts');
        await customStatement('''
          CREATE VIRTUAL TABLE foods_fts USING fts5(
            food_id UNINDEXED,
            name,
            brand
          )
        ''');
        debugPrint('[FTS] Recovered with empty index');
      } catch (recoveryError) {
        debugPrint('[FTS] FAILED TO RECOVER: $recoveryError');
        rethrow; // No podemos continuar sin FTS
      }
    }
  }

  /// 🆕 Inserta o actualiza entrada en FTS5 para un alimento
  Future<void> insertFoodFts(String foodId, String name, String? brand) async {
    await customStatement(
      '''
      INSERT OR REPLACE INTO foods_fts(food_id, name, brand)
      VALUES (?, ?, ?)
    ''',
      [foodId, name, brand ?? ''],
    );
  }

  /// Reconstruye el índice FTS desde la tabla foods
  ///
  /// Público para poder llamarlo desde FoodDatabaseLoader después de la carga inicial.
  /// Also fixes any foods missing normalizedName for LIKE fallback search.
  Future<void> rebuildFtsIndex() async {
    debugPrint('[rebuildFtsIndex] Starting FTS index rebuild...');

    // First, fix any foods missing normalizedName (for LIKE fallback)
    await customStatement('''
      UPDATE foods SET normalized_name = LOWER(name)
      WHERE normalized_name IS NULL
    ''');

    // Clear and rebuild FTS index
    await customStatement('DELETE FROM foods_fts');
    await customStatement('''
      INSERT INTO foods_fts(food_id, name, brand)
      SELECT id, name, COALESCE(brand, '') FROM foods
    ''');

    // Verify the rebuild
    final count = await customSelect(
      'SELECT COUNT(*) as cnt FROM foods_fts',
    ).getSingle();
    debugPrint(
      '[rebuildFtsIndex] FTS index rebuilt with ${count.data['cnt']} entries',
    );
  }

  @override
  int get schemaVersion => 17;

  // ============================================================================
  // 🆕 NUEVO: MÉTODOS DE BÚSQUEDA FTS5
  // ============================================================================

  /// Búsqueda FTS5 con ranking por relevancia
  ///
  /// Optimizations applied:
  /// - Multi-word queries use AND semantics (all terms must match)
  /// - Single-word queries use prefix matching
  /// - Results ordered by FTS5 rank (relevance)
  /// - Uses AND-first strategy with OR fallback for zero results
  /// - Synonym expansion as final fallback
  Future<List<Food>> searchFoodsFTS(String query, {int limit = 50}) async {
    if (query.trim().isEmpty) return [];

    // Normalizar query para FTS5
    // Remove special characters that could break FTS syntax
    // FTS5 special chars que causan errores: ' " - * ( ) : \ % _ [ ] ^ ~ { } | & < > = ! @ # $
    var sanitized = query.trim().toLowerCase();
    // Remover caracteres especiales de FTS5 reemplazándolos por espacio
    const specialChars = "\"'\\-*():;%_[]^~{}|&<>!=@#\$";
    for (final char in specialChars.split('')) {
      sanitized = sanitized.replaceAll(char, ' ');
    }
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (sanitized.isEmpty) return [];

    final terms = sanitized
        .split(' ')
        .where((t) => t.isNotEmpty && t.length >= 2)
        .toList();
    if (terms.isEmpty) return [];

    if (kDebugMode) {
      debugPrint('[searchFoodsFTS] Query: "$query" -> terms: $terms');
    }

    try {
      // Strategy: Progressive fallback for maximum findability
      // 1. AND exact (most precise) - "leche desnatada" finds items with BOTH terms
      // 2. OR fallback (any term) - relaxes to items with ANY term
      // 3. Synonym expansion (final fallback) - expands with Spanish food synonyms

      // 1. Try AND semantics first (space = AND in FTS5)
      final andQuery = terms.map((t) => '$t*').join(' ');
      if (kDebugMode) {
        debugPrint('[searchFoodsFTS] Step 1 - AND query: "$andQuery"');
      }
      var results = await _executeFtsQuery(andQuery, limit);

      if (results.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[searchFoodsFTS] AND found ${results.length} results');
        }
        return results;
      }

      // 2. Try OR fallback (any term matches)
      if (terms.length > 1) {
        final orQuery = terms.map((t) => '$t*').join(' OR ');
        if (kDebugMode) {
          debugPrint('[searchFoodsFTS] Step 2 - OR query: "$orQuery"');
        }
        results = await _executeFtsQuery(orQuery, limit);

        if (results.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('[searchFoodsFTS] OR found ${results.length} results');
          }
          return results;
        }
      }

      // 3. Try with synonyms expanded (finds "descremada" when searching "desnatada")
      final enhanced = enhanceQuery(query);
      if (enhanced.withSynonyms.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[searchFoodsFTS] Step 3 - Synonym query: "${enhanced.withSynonyms}"',
          );
        }
        results = await _executeFtsQuery(enhanced.withSynonyms, limit);

        if (results.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              '[searchFoodsFTS] Synonyms found ${results.length} results',
            );
          }
          return results;
        }
      }

      if (kDebugMode) {
        debugPrint('[searchFoodsFTS] All strategies returned 0 results');
      }
      return results;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[searchFoodsFTS] FTS search error: $e, falling back to LIKE',
        );
      }
      return _searchFoodsLike(query, limit: limit);
    }
  }

  /// Helper to execute FTS query and map results
  Future<List<Food>> _executeFtsQuery(String ftsQuery, int limit) async {
    // FTS5 con food_id UNINDEXED: buscamos en FTS y obtenemos food_ids
    final ftsResults = await customSelect(
      'SELECT food_id FROM foods_fts WHERE foods_fts MATCH ? LIMIT ?',
      variables: [Variable(ftsQuery), Variable(limit)],
    ).get();

    if (ftsResults.isEmpty) return [];

    // Obtener los alimentos por sus IDs
    final foodIds = ftsResults.map((r) => r.data['food_id'] as String).toList();
    final placeholders = List.filled(foodIds.length, '?').join(',');

    final results = await customSelect(
      'SELECT id, name, normalized_name, brand, barcode, '
      'kcal_per100g, protein_per100g, carbs_per100g, fat_per100g, '
      'fiber_per100g, sugar_per100g, saturated_fat_per100g, sodium_per100g, '
      'portion_name, portion_grams, user_created, verified_source, '
      'source_metadata, use_count, last_used_at, nutri_score, nova_group, '
      'is_favorite, created_at, updated_at '
      'FROM foods WHERE id IN ($placeholders)',
      variables: foodIds.map((id) => Variable(id)).toList(),
    ).get();

    return results.map((row) => _mapRowToFood(row)).toList();
  }

  /// Búsqueda fallback usando LIKE (cuando FTS falla)
  ///
  /// SEGURIDAD: Todos los parámetros de usuario están completamente parametrizados
  /// para prevenir SQL injection. Los términos se escapan mediante placeholders ?
  Future<List<Food>> _searchFoodsLike(String query, {int limit = 50}) async {
    final normalized = query.toLowerCase().trim();
    final terms = normalized.split(' ').where((t) => t.isNotEmpty).toList();

    if (terms.isEmpty) return [];

    if (kDebugMode) {
      debugPrint(
        '[_searchFoodsLike] Fallback LIKE search for: $normalized (${terms.length} terms)',
      );
    }

    // Construir WHERE clause con placeholders parametrizados
    // Cada término necesita 2 placeholders: uno para name, uno para brand
    final whereConditions = <String>[];
    final variables = <Variable<Object>>[];

    for (final term in terms) {
      // Escapar caracteres especiales de LIKE para evitar comportamiento inesperado
      final escapedTerm = term.replaceAll('%', '\\%').replaceAll('_', '\\_');
      whereConditions.add(
        "(LOWER(name) LIKE ? ESCAPE '\\' OR LOWER(COALESCE(brand, '')) LIKE ? ESCAPE '\\')",
      );
      // Dos placeholders por término
      variables.add(Variable('%$escapedTerm%'));
      variables.add(Variable('%$escapedTerm%'));
    }

    final whereClause = whereConditions.join(' AND ');

    // Añadir límite al final (con tipo explícito para type safety)
    variables.add(Variable<int>(limit));

    final results = await customSelect(
      'SELECT id, name, normalized_name, brand, barcode, '
      'kcal_per100g, protein_per100g, carbs_per100g, fat_per100g, '
      'fiber_per100g, sugar_per100g, saturated_fat_per100g, sodium_per100g, '
      'portion_name, portion_grams, user_created, verified_source, '
      'source_metadata, use_count, last_used_at, nutri_score, nova_group, '
      'is_favorite, created_at, updated_at FROM foods '
      'WHERE $whereClause '
      'ORDER BY use_count DESC, last_used_at DESC '
      'LIMIT ?',
      variables: variables,
    ).get();

    if (kDebugMode) {
      debugPrint('[_searchFoodsLike] Found ${results.length} results');
    }
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
      kcalPer100g: row.read<int>('kcal_per100g'),
      proteinPer100g: row.read<double?>('protein_per100g'),
      carbsPer100g: row.read<double?>('carbs_per100g'),
      fatPer100g: row.read<double?>('fat_per100g'),
      fiberPer100g: row.read<double?>('fiber_per100g'),
      sugarPer100g: row.read<double?>('sugar_per100g'),
      saturatedFatPer100g: row.read<double?>('saturated_fat_per100g'),
      sodiumPer100g: row.read<double?>('sodium_per100g'),
      portionName: row.read<String?>('portion_name'),
      portionGrams: row.read<double?>('portion_grams'),
      userCreated: row.read<bool>('user_created'),
      verifiedSource: row.read<String?>('verified_source'),
      sourceMetadata: _jsonFromString(row.read<String?>('source_metadata')),
      useCount: row.read<int>('use_count'),
      lastUsedAt: _dateTimeFromString(row.read<String?>('last_used_at')),
      nutriScore: row.read<String?>('nutri_score'),
      novaGroup: row.read<int?>('nova_group'),
      isFavorite: row.read<bool>('is_favorite'),
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
  Future<List<Food>> searchFoodsByPrefix(
    String prefix, {
    int limit = 10,
  }) async {
    final normalized = prefix.toLowerCase().trim();

    return (select(foods)
          ..where(
            (f) =>
                f.normalizedName.like('$normalized%') |
                f.name.lower().like('$normalized%'),
          )
          ..orderBy([
            (f) => OrderingTerm.desc(f.useCount),
            (f) => OrderingTerm.asc(f.name),
          ])
          ..limit(limit))
        .get();
  }

  /// Búsqueda offline completa (FTS + fallback a LIKE)
  Future<List<Food>> searchFoodsOffline(String query, {int limit = 50}) async {
    // Intentar FTS primero
    final ftsResults = await searchFoodsFTS(query, limit: limit);
    if (ftsResults.isNotEmpty) return ftsResults;

    // Fallback a LIKE - use the robust _searchFoodsLike method
    return _searchFoodsLike(query, limit: limit);
  }

  /// Sugerencias de autocompletado basadas en historial y alimentos populares
  Future<List<String>> getSearchSuggestions(
    String prefix, {
    int limit = 10,
  }) async {
    final normalized = prefix.toLowerCase().trim();

    // 1. Buscar en historial de búsquedas
    final historial =
        await (select(searchHistory)
              ..where((h) => h.normalizedQuery.like('$normalized%'))
              ..orderBy([(h) => OrderingTerm.desc(h.searchedAt)])
              ..limit(limit))
            .map((h) => h.query)
            .get();

    // 2. Buscar en nombres de alimentos populares
    final populares =
        await (select(foods)
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
      final patrones =
          await (select(consumptionPatterns)
                ..where(
                  (p) =>
                      p.hourOfDay.equals(hourOfDay) &
                      p.dayOfWeek.equals(dayOfWeek),
                )
                ..orderBy([(p) => OrderingTerm.desc(p.frequency)])
                ..limit(limit))
              .get();

      if (patrones.isNotEmpty) {
        final foodIds = patrones.map((p) => p.foodId).toList();
        return (select(foods)..where((f) => f.id.isIn(foodIds))).get();
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
    await customStatement(
      '''
      INSERT INTO consumption_patterns (food_id, hour_of_day, day_of_week, meal_type, frequency, last_consumed_at)
      VALUES (?, ?, ?, ?, 1, ?)
      ON CONFLICT(food_id, hour_of_day, day_of_week) DO UPDATE SET
        frequency = frequency + 1,
        last_consumed_at = excluded.last_consumed_at,
        meal_type = excluded.meal_type
    ''',
      [foodId, now.hour, now.weekday, mealType?.name, now.toIso8601String()],
    );
  }

  /// Guardar búsqueda en historial
  Future<void> saveSearchHistory(
    String query, {
    String? selectedFoodId,
    bool hasResults = true,
  }) async {
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

  // ============================================================================
  // DETECCIÓN Y LIMPIEZA DE DUPLICADOS
  // ============================================================================

  /// Modelo para representar un grupo de duplicados
  ///
  /// Retorna grupos de alimentos con el mismo nombre normalizado y marca.
  /// Cada grupo tiene: nombre, marca, lista de IDs duplicados, y el ID del "maestro"
  /// (el que tiene mayor useCount).
  Future<List<DuplicateGroup>> findDuplicateFoods() async {
    // Buscar grupos con mismo nombre+marca que tengan más de 1 entrada
    final results = await customSelect('''
      SELECT 
        LOWER(TRIM(name)) as norm_name,
        COALESCE(LOWER(TRIM(brand)), '') as norm_brand,
        GROUP_CONCAT(id) as ids,
        COUNT(*) as cnt,
        MAX(use_count) as max_use
      FROM foods
      GROUP BY LOWER(TRIM(name)), COALESCE(LOWER(TRIM(brand)), '')
      HAVING COUNT(*) > 1
      ORDER BY cnt DESC
    ''').get();

    final groups = <DuplicateGroup>[];

    for (final row in results) {
      final ids = (row.data['ids'] as String).split(',');
      final normName = row.data['norm_name'] as String;
      final normBrand = row.data['norm_brand'] as String;
      final maxUse = row.data['max_use'] as int? ?? 0;

      // Encontrar el ID maestro (el con mayor useCount)
      String? masterId;
      for (final id in ids) {
        final food = await (select(
          foods,
        )..where((f) => f.id.equals(id))).getSingleOrNull();
        if (food != null && food.useCount == maxUse) {
          masterId = id;
          break;
        }
      }

      groups.add(
        DuplicateGroup(
          normalizedName: normName,
          normalizedBrand: normBrand,
          foodIds: ids,
          masterId: masterId ?? ids.first,
          count: ids.length,
        ),
      );
    }

    return groups;
  }

  /// Fusionar un grupo de duplicados
  ///
  /// 1. Actualiza todas las referencias en diary_entries al ID maestro
  /// 2. Suma los useCount de todos los duplicados al maestro
  /// 3. Elimina los duplicados (excepto el maestro)
  /// 4. Actualiza el índice FTS
  Future<int> mergeDuplicateGroup(DuplicateGroup group) async {
    if (group.foodIds.length < 2) return 0;

    final duplicateIds = group.foodIds
        .where((id) => id != group.masterId)
        .toList();
    if (duplicateIds.isEmpty) return 0;

    // 1. Actualizar diary_entries para apuntar al maestro
    for (final dupId in duplicateIds) {
      await customStatement(
        'UPDATE diary_entries SET food_id = ? WHERE food_id = ?',
        [group.masterId, dupId],
      );
    }

    // 2. Sumar useCount al maestro
    final totalUseCount = await customSelect(
      'SELECT SUM(use_count) as total FROM foods WHERE id IN (${duplicateIds.map((_) => '?').join(',')})',
      variables: duplicateIds.map((id) => Variable(id)).toList(),
    ).getSingle();

    final additionalCount = (totalUseCount.data['total'] as int?) ?? 0;
    if (additionalCount > 0) {
      await customStatement(
        'UPDATE foods SET use_count = use_count + ? WHERE id = ?',
        [additionalCount, group.masterId],
      );
    }

    // 3. Eliminar duplicados del índice FTS
    for (final dupId in duplicateIds) {
      await customStatement('DELETE FROM foods_fts WHERE food_id = ?', [dupId]);
    }

    // 4. Eliminar duplicados de la tabla foods
    final placeholders = duplicateIds.map((_) => '?').join(',');
    await customStatement(
      'DELETE FROM foods WHERE id IN ($placeholders)',
      duplicateIds,
    );

    return duplicateIds.length;
  }

  /// Limpiar todos los duplicados de la base de datos
  ///
  /// Retorna el número total de registros eliminados.
  Future<int> cleanupAllDuplicates() async {
    final groups = await findDuplicateFoods();
    var totalRemoved = 0;

    for (final group in groups) {
      totalRemoved += await mergeDuplicateGroup(group);
    }

    return totalRemoved;
  }
}

/// Modelo para representar un grupo de alimentos duplicados
class DuplicateGroup {
  final String normalizedName;
  final String normalizedBrand;
  final List<String> foodIds;
  final String masterId;
  final int count;

  const DuplicateGroup({
    required this.normalizedName,
    required this.normalizedBrand,
    required this.foodIds,
    required this.masterId,
    required this.count,
  });

  @override
  String toString() =>
      'DuplicateGroup($normalizedName, $normalizedBrand, $count duplicados)';
}
