import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../training/database/database.dart';
import '../models/body_progress_models.dart';

/// Repositorio para gestionar medidas corporales y fotos de progreso.
/// 
/// Proporciona operaciones CRUD y streams para:
/// - Medidas corporales (BodyMeasurements)
/// - Fotos de progreso (ProgressPhotos)
class BodyProgressRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  BodyProgressRepository(this._db);

  // ============================================================================
  // MEDIDAS CORPORALES
  // ============================================================================

  /// Obtiene todas las medidas ordenadas por fecha descendente
  Stream<List<BodyMeasurementModel>> watchAllMeasurements() {
    final query = _db.select(_db.bodyMeasurements)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    return query.watch().map((rows) => rows.map(_mapToMeasurementModel).toList());
  }

  /// Obtiene las últimas N medidas
  Future<List<BodyMeasurementModel>> getRecentMeasurements(int limit) async {
    final query = _db.select(_db.bodyMeasurements)
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_mapToMeasurementModel).toList();
  }

  /// Obtiene la medida más reciente
  Future<BodyMeasurementModel?> getLatestMeasurement() async {
    final query = _db.select(_db.bodyMeasurements)
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    return row != null ? _mapToMeasurementModel(row) : null;
  }

  /// Obtiene una medida específica por ID
  Future<BodyMeasurementModel?> getMeasurementById(String id) async {
    final query = _db.select(_db.bodyMeasurements)
      ..where((t) => t.id.equals(id));

    final row = await query.getSingleOrNull();
    return row != null ? _mapToMeasurementModel(row) : null;
  }

  /// Guarda una nueva medida
  Future<BodyMeasurementModel> saveMeasurement(BodyMeasurementModel measurement) async {
    final companion = BodyMeasurementsCompanion(
      id: Value(measurement.id),
      date: Value(measurement.date),
      weightKg: Value(measurement.weightKg),
      waistCm: Value(measurement.waistCm),
      chestCm: Value(measurement.chestCm),
      hipsCm: Value(measurement.hipsCm),
      leftArmCm: Value(measurement.leftArmCm),
      rightArmCm: Value(measurement.rightArmCm),
      leftThighCm: Value(measurement.leftThighCm),
      rightThighCm: Value(measurement.rightThighCm),
      leftCalfCm: Value(measurement.leftCalfCm),
      rightCalfCm: Value(measurement.rightCalfCm),
      neckCm: Value(measurement.neckCm),
      bodyFatPercentage: Value(measurement.bodyFatPercentage),
      notes: Value(measurement.notes),
      createdAt: Value(measurement.createdAt),
    );

    await _db.into(_db.bodyMeasurements).insertOnConflictUpdate(companion);
    return measurement;
  }

  /// Crea una nueva medida con ID automático
  Future<BodyMeasurementModel> createMeasurement({
    required DateTime date,
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? hipsCm,
    double? leftArmCm,
    double? rightArmCm,
    double? leftThighCm,
    double? rightThighCm,
    double? leftCalfCm,
    double? rightCalfCm,
    double? neckCm,
    double? bodyFatPercentage,
    String? notes,
  }) async {
    final measurement = BodyMeasurementModel(
      id: _uuid.v4(),
      date: date,
      weightKg: weightKg,
      waistCm: waistCm,
      chestCm: chestCm,
      hipsCm: hipsCm,
      leftArmCm: leftArmCm,
      rightArmCm: rightArmCm,
      leftThighCm: leftThighCm,
      rightThighCm: rightThighCm,
      leftCalfCm: leftCalfCm,
      rightCalfCm: rightCalfCm,
      neckCm: neckCm,
      bodyFatPercentage: bodyFatPercentage,
      notes: notes,
      createdAt: DateTime.now(),
    );

    return saveMeasurement(measurement);
  }

  /// Elimina una medida
  Future<void> deleteMeasurement(String id) async {
    await (_db.delete(_db.bodyMeasurements)..where((t) => t.id.equals(id))).go();
  }

  /// Obtiene resumen de medidas (primera, última, diferencias)
  Future<BodyMeasurementsSummary> getMeasurementsSummary() async {
    final allMeasurements = await getRecentMeasurements(1000);
    
    if (allMeasurements.isEmpty) {
      return const BodyMeasurementsSummary(totalMeasurements: 0);
    }

    final latest = allMeasurements.first;
    final first = allMeasurements.last;
    
    return BodyMeasurementsSummary(
      latest: latest,
      first: first,
      totalMeasurements: allMeasurements.length,
      overallDiff: latest.diff(first),
    );
  }

  // ============================================================================
  // FOTOS DE PROGRESO
  // ============================================================================

  /// Obtiene todas las fotos ordenadas por fecha descendente
  Stream<List<ProgressPhotoModel>> watchAllPhotos() {
    final query = _db.select(_db.progressPhotos)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    return query.watch().map((rows) => rows.map(_mapToPhotoModel).toList());
  }

  /// Obtiene fotos por categoría
  Stream<List<ProgressPhotoModel>> watchPhotosByCategory(PhotoCategory category) {
    final query = _db.select(_db.progressPhotos)
      ..where((t) => t.category.equals(category.name))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    return query.watch().map((rows) => rows.map(_mapToPhotoModel).toList());
  }

  /// Obtiene las últimas N fotos
  Future<List<ProgressPhotoModel>> getRecentPhotos(int limit) async {
    final query = _db.select(_db.progressPhotos)
      ..orderBy([(t) => OrderingTerm.desc(t.date)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_mapToPhotoModel).toList();
  }

  /// Obtiene la foto más reciente de cada categoría
  Future<Map<PhotoCategory, ProgressPhotoModel>> getLatestPhotosByCategory() async {
    final result = <PhotoCategory, ProgressPhotoModel>{};
    
    for (final category in PhotoCategory.values) {
      final query = _db.select(_db.progressPhotos)
        ..where((t) => t.category.equals(category.name))
        ..orderBy([(t) => OrderingTerm.desc(t.date)])
        ..limit(1);

      final row = await query.getSingleOrNull();
      if (row != null) {
        result[category] = _mapToPhotoModel(row);
      }
    }
    
    return result;
  }

  /// Guarda una nueva foto
  Future<ProgressPhotoModel> savePhoto(ProgressPhotoModel photo) async {
    final companion = ProgressPhotosCompanion(
      id: Value(photo.id),
      date: Value(photo.date),
      imagePath: Value(photo.imagePath),
      category: Value(photo.category.name),
      notes: Value(photo.notes),
      measurementId: Value(photo.measurementId),
      createdAt: Value(photo.createdAt),
    );

    await _db.into(_db.progressPhotos).insertOnConflictUpdate(companion);
    return photo;
  }

  /// Crea una nueva foto con ID automático
  Future<ProgressPhotoModel> createPhoto({
    required DateTime date,
    required String imagePath,
    PhotoCategory category = PhotoCategory.front,
    String? notes,
    String? measurementId,
  }) async {
    final photo = ProgressPhotoModel(
      id: _uuid.v4(),
      date: date,
      imagePath: imagePath,
      category: category,
      notes: notes,
      measurementId: measurementId,
      createdAt: DateTime.now(),
    );

    return savePhoto(photo);
  }

  /// Elimina una foto
  Future<void> deletePhoto(String id) async {
    await (_db.delete(_db.progressPhotos)..where((t) => t.id.equals(id))).go();
  }

  /// Obtiene fotos de una fecha específica
  Future<List<ProgressPhotoModel>> getPhotosByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _db.select(_db.progressPhotos)
      ..where((t) => t.date.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    final rows = await query.get();
    return rows.map(_mapToPhotoModel).toList();
  }

  // ============================================================================
  // MAPPERS
  // ============================================================================

  BodyMeasurementModel _mapToMeasurementModel(BodyMeasurement row) {
    return BodyMeasurementModel(
      id: row.id,
      date: row.date,
      weightKg: row.weightKg,
      waistCm: row.waistCm,
      chestCm: row.chestCm,
      hipsCm: row.hipsCm,
      leftArmCm: row.leftArmCm,
      rightArmCm: row.rightArmCm,
      leftThighCm: row.leftThighCm,
      rightThighCm: row.rightThighCm,
      leftCalfCm: row.leftCalfCm,
      rightCalfCm: row.rightCalfCm,
      neckCm: row.neckCm,
      bodyFatPercentage: row.bodyFatPercentage,
      notes: row.notes,
      createdAt: row.createdAt,
    );
  }

  ProgressPhotoModel _mapToPhotoModel(ProgressPhoto row) {
    return ProgressPhotoModel(
      id: row.id,
      date: row.date,
      imagePath: row.imagePath,
      category: PhotoCategory.fromString(row.category),
      notes: row.notes,
      measurementId: row.measurementId,
      createdAt: row.createdAt,
    );
  }
}
