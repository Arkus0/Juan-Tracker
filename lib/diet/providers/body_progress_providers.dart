import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../models/body_progress_models.dart';
import '../repositories/body_progress_repository.dart';

/// Provider del repositorio de progreso corporal
final bodyProgressRepositoryProvider = Provider<BodyProgressRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BodyProgressRepository(db);
});

/// Stream de todas las medidas corporales
final bodyMeasurementsStreamProvider = StreamProvider<List<BodyMeasurementModel>>((ref) {
  final repo = ref.watch(bodyProgressRepositoryProvider);
  return repo.watchAllMeasurements();
});

/// Provider de la medida más reciente
final latestMeasurementProvider = FutureProvider<BodyMeasurementModel?>((ref) {
  final repo = ref.watch(bodyProgressRepositoryProvider);
  return repo.getLatestMeasurement();
});

/// Provider del resumen de medidas
final measurementsSummaryProvider = FutureProvider<BodyMeasurementsSummary>((ref) {
  final repo = ref.watch(bodyProgressRepositoryProvider);
  return repo.getMeasurementsSummary();
});

/// Stream de todas las fotos de progreso
final progressPhotosStreamProvider = StreamProvider<List<ProgressPhotoModel>>((ref) {
  final repo = ref.watch(bodyProgressRepositoryProvider);
  return repo.watchAllPhotos();
});

/// Stream de fotos por categoría
final photosByCategoryProvider = StreamProvider.family<List<ProgressPhotoModel>, PhotoCategory>((ref, category) {
  final repo = ref.watch(bodyProgressRepositoryProvider);
  return repo.watchPhotosByCategory(category);
});

/// Provider de las fotos más recientes por categoría
final latestPhotosByCategoryProvider = FutureProvider<Map<PhotoCategory, ProgressPhotoModel>>((ref) {
  final repo = ref.watch(bodyProgressRepositoryProvider);
  return repo.getLatestPhotosByCategory();
});

/// Notifier para gestionar el estado de medidas
class BodyMeasurementsNotifier extends AsyncNotifier<List<BodyMeasurementModel>> {
  @override
  Future<List<BodyMeasurementModel>> build() async {
    final repo = ref.read(bodyProgressRepositoryProvider);
    return repo.getRecentMeasurements(100);
  }

  /// Añade una nueva medida
  Future<void> addMeasurement({
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
    final repo = ref.read(bodyProgressRepositoryProvider);
    
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      await repo.createMeasurement(
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
      );
      return repo.getRecentMeasurements(100);
    });
  }

  /// Elimina una medida
  Future<void> deleteMeasurement(String id) async {
    final repo = ref.read(bodyProgressRepositoryProvider);
    
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      await repo.deleteMeasurement(id);
      return repo.getRecentMeasurements(100);
    });
  }
}

final bodyMeasurementsNotifierProvider = AsyncNotifierProvider<BodyMeasurementsNotifier, List<BodyMeasurementModel>>(
  BodyMeasurementsNotifier.new,
);

/// Notifier para gestionar fotos
class ProgressPhotosNotifier extends AsyncNotifier<List<ProgressPhotoModel>> {
  @override
  Future<List<ProgressPhotoModel>> build() async {
    final repo = ref.read(bodyProgressRepositoryProvider);
    return repo.getRecentPhotos(100);
  }

  /// Añade una nueva foto
  Future<void> addPhoto({
    required DateTime date,
    required String imagePath,
    PhotoCategory category = PhotoCategory.front,
    String? notes,
    String? measurementId,
  }) async {
    final repo = ref.read(bodyProgressRepositoryProvider);
    
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      await repo.createPhoto(
        date: date,
        imagePath: imagePath,
        category: category,
        notes: notes,
        measurementId: measurementId,
      );
      return repo.getRecentPhotos(100);
    });
  }

  /// Elimina una foto
  Future<void> deletePhoto(String id) async {
    final repo = ref.read(bodyProgressRepositoryProvider);
    
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      await repo.deletePhoto(id);
      return repo.getRecentPhotos(100);
    });
  }
}

final progressPhotosNotifierProvider = AsyncNotifierProvider<ProgressPhotosNotifier, List<ProgressPhotoModel>>(
  ProgressPhotosNotifier.new,
);

/// Notifier para la categoría seleccionada en la galería de fotos
class SelectedPhotoCategoryNotifier extends Notifier<PhotoCategory?> {
  @override
  PhotoCategory? build() => null;

  void select(PhotoCategory? category) => state = category;
  void clear() => state = null;
}

final selectedPhotoCategoryProvider = NotifierProvider<SelectedPhotoCategoryNotifier, PhotoCategory?>(
  SelectedPhotoCategoryNotifier.new,
);
