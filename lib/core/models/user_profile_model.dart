/// Modelo de perfil de usuario para cálculo TDEE y configuración
class UserProfileModel {
  final String? id;
  final int? age;
  final Gender? gender;
  final double? heightCm;
  final double? currentWeightKg;
  final ActivityLevel activityLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfileModel({
    this.id,
    this.age,
    this.gender,
    this.heightCm,
    this.currentWeightKg,
    this.activityLevel = ActivityLevel.moderatelyActive,
    this.createdAt,
    this.updatedAt,
  });

  UserProfileModel copyWith({
    String? id,
    int? age,
    Gender? gender,
    double? heightCm,
    double? currentWeightKg,
    ActivityLevel? activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isComplete {
    return age != null &&
        gender != null &&
        heightCm != null &&
        currentWeightKg != null;
  }

  Map<String, dynamic> toDebugMap() => {
        'id': id,
        'age': age,
        'gender': gender?.name,
        'heightCm': heightCm,
        'currentWeightKg': currentWeightKg,
        'activityLevel': activityLevel.name,
        'isComplete': isComplete,
      };

  @override
  String toString() => 'UserProfileModel(${toDebugMap()})';
}

enum Gender { male, female }

enum ActivityLevel {
  sedentary, // 1.2 - Poco o ningún ejercicio
  lightlyActive, // 1.375 - 1-3 días/semana
  moderatelyActive, // 1.55 - 3-5 días/semana
  veryActive, // 1.725 - 6-7 días/semana
  extremelyActive, // 1.9 - 2x día o trabajo físico
}

extension ActivityLevelExtension on ActivityLevel {
  double get multiplier {
    return switch (this) {
      ActivityLevel.sedentary => 1.2,
      ActivityLevel.lightlyActive => 1.375,
      ActivityLevel.moderatelyActive => 1.55,
      ActivityLevel.veryActive => 1.725,
      ActivityLevel.extremelyActive => 1.9,
    };
  }

  String get displayName {
    return switch (this) {
      ActivityLevel.sedentary => 'Sedentario',
      ActivityLevel.lightlyActive => 'Ligero (1-3 días/semana)',
      ActivityLevel.moderatelyActive => 'Moderado (3-5 días/semana)',
      ActivityLevel.veryActive => 'Activo (6-7 días/semana)',
      ActivityLevel.extremelyActive => 'Muy activo (2x día)',
    };
  }

  String get description {
    return switch (this) {
      ActivityLevel.sedentary => 'Poco o ningún ejercicio, trabajo de escritorio',
      ActivityLevel.lightlyActive => 'Ejercicio ligero 1-3 días por semana',
      ActivityLevel.moderatelyActive => 'Ejercicio moderado 3-5 días por semana',
      ActivityLevel.veryActive => 'Ejercicio intenso 6-7 días por semana',
      ActivityLevel.extremelyActive =>
        'Ejercicio muy intenso 2 veces al día o trabajo físico pesado',
    };
  }
}

extension GenderExtension on Gender {
  String get displayName {
    return switch (this) {
      Gender.male => 'Hombre',
      Gender.female => 'Mujer',
    };
  }
}
