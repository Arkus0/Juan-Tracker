import 'package:drift/drift.dart';
import '../../core/models/user_profile_model.dart';
import '../../training/database/database.dart';

/// Interfaz del repositorio de perfiles de usuario
abstract class IUserProfileRepository {
  Future<UserProfileModel?> get();
  Future<void> save(UserProfileModel profile);
  Future<void> updateWeight(double weightKg);
  Future<void> delete();
}

/// Implementación Drift del repositorio de perfiles
class DriftUserProfileRepository implements IUserProfileRepository {
  final AppDatabase db;

  DriftUserProfileRepository(this.db);

  @override
  Future<UserProfileModel?> get() async {
    final result = await db.select(db.userProfiles).get();
    
    if (result.isEmpty) return null;
    
    final row = result.first;
    return _mapToModel(row);
  }

  @override
  Future<void> save(UserProfileModel profile) async {
    final companion = UserProfilesCompanion(
      id: const Value('user_profile'), // Singleton - solo un perfil
      age: Value(profile.age),
      gender: Value(profile.gender?.name),
      heightCm: Value(profile.heightCm),
      currentWeightKg: Value(profile.currentWeightKg),
      activityLevel: Value(profile.activityLevel.name),
      createdAt: Value(profile.createdAt ?? DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    await db.into(db.userProfiles).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> updateWeight(double weightKg) async {
    final existing = await get();
    
    if (existing != null) {
      await save(existing.copyWith(currentWeightKg: weightKg));
    }
  }

  @override
  Future<void> delete() async {
    await db.delete(db.userProfiles).go();
  }

  UserProfileModel _mapToModel(UserProfile row) {
    // Parseo seguro de enums con fallback
    Gender? gender;
    if (row.gender != null) {
      try {
        gender = Gender.values.byName(row.gender!);
      } catch (e) {
        gender = null; // Fallback si el valor es inválido
      }
    }

    ActivityLevel activityLevel;
    try {
      activityLevel = ActivityLevel.values.byName(row.activityLevel);
    } catch (e) {
      activityLevel = ActivityLevel.moderatelyActive; // Fallback seguro
    }

    return UserProfileModel(
      id: row.id,
      age: row.age,
      gender: gender,
      heightCm: row.heightCm,
      currentWeightKg: row.currentWeightKg,
      activityLevel: activityLevel,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
