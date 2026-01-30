import '../models/user_profile_model.dart';

/// Calculadora TDEE usando fórmula Mifflin-St Jeor
/// 
/// Referencia:
/// Mifflin, M. D., et al. (1990). A new predictive equation for resting energy 
/// expenditure in healthy individuals. The American Journal of Clinical Nutrition.
class TdeeCalculator {
  const TdeeCalculator._();

  /// Calcula el BMR (Basal Metabolic Rate) usando Mifflin-St Jeor
  /// 
  /// Fórmula:
  /// - Hombres: (10 × peso kg) + (6.25 × altura cm) - (5 × edad) + 5
  /// - Mujeres: (10 × peso kg) + (6.25 × altura cm) - (5 × edad) - 161
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    double bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    
    if (gender == Gender.male) {
      bmr += 5;
    } else {
      bmr -= 161;
    }
    
    return bmr;
  }

  /// Calcula TDEE (Total Daily Energy Expenditure) multiplicando BMR por factor de actividad
  static double calculateTDEE({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    return bmr * activityLevel.multiplier;
  }

  /// Calcula TDEE completo desde un perfil de usuario
  /// 
  /// Retorna null si faltan datos requeridos
  static double? calculateTDEEFromProfile(UserProfileModel profile) {
    if (!profile.isComplete) return null;

    final bmr = calculateBMR(
      weightKg: profile.currentWeightKg!,
      heightCm: profile.heightCm!,
      age: profile.age!,
      gender: profile.gender!,
    );

    return calculateTDEE(
      bmr: bmr,
      activityLevel: profile.activityLevel,
    );
  }

  /// Calcula el déficit/superávit calórico necesario para alcanzar un objetivo de peso
  /// 
  /// [weeklyWeightChangeKg]: Cuántos kg quiere perder/ganar por semana
  /// (positivo = ganar, negativo = perder)
  /// 
  /// Retorna ajuste diario en kcal (positivo = superávit, negativo = déficit)
  static int calculateDailyAdjustment(double weeklyWeightChangeKg) {
    // 1 kg de grasa ≈ 7700 kcal
    // Semana = 7 días
    final totalWeeklyKcal = weeklyWeightChangeKg * 7700;
    final dailyKcal = totalWeeklyKcal / 7;
    return dailyKcal.round();
  }

  /// Calcula el target calórico diario para alcanzar un objetivo
  /// 
  /// [tdee]: Gasto energético total diario
  /// [weeklyWeightChangeKg]: Objetivo de cambio de peso semanal
  static int calculateTargetKcal({
    required double tdee,
    required double weeklyWeightChangeKg,
  }) {
    final adjustment = calculateDailyAdjustment(weeklyWeightChangeKg);
    return (tdee + adjustment).round();
  }

  /// Genera una recomendación de macros basada en el objetivo
  /// 
  /// Retorna porcentajes: {protein, carbs, fat}
  static Map<String, double> suggestMacros({
    required double targetKcal,
    required double weightKg,
    required WeightGoal goal,
  }) {
    // Proteína: 2g por kg de peso corporal (estándar para fitness)
    final proteinGrams = weightKg * 2.0;
    final proteinKcal = proteinGrams * 4;
    final proteinPercent = proteinKcal / targetKcal;

    // Grasas: mínimo 0.8g por kg, ideal 1g por kg
    final fatGrams = weightKg * 1.0;
    final fatKcal = fatGrams * 9;
    final fatPercent = fatKcal / targetKcal;

    // Carbs: el resto de las calorías
    final carbsPercent = 1.0 - proteinPercent - fatPercent;

    return {
      'protein': proteinPercent.clamp(0.15, 0.45),
      'carbs': carbsPercent.clamp(0.20, 0.60),
      'fat': fatPercent.clamp(0.20, 0.40),
    };
  }

  /// Valida si los datos del perfil son razonables
  /// 
  /// Retorna mensaje de error o null si es válido
  static String? validateProfile({
    int? age,
    double? heightCm,
    double? weightKg,
  }) {
    if (age != null) {
      if (age < 10 || age > 120) {
        return 'La edad debe estar entre 10 y 120 años';
      }
    }

    if (heightCm != null) {
      if (heightCm < 50 || heightCm > 250) {
        return 'La altura debe estar entre 50 y 250 cm';
      }
    }

    if (weightKg != null) {
      if (weightKg < 20 || weightKg > 500) {
        return 'El peso debe estar entre 20 y 500 kg';
      }
    }

    return null;
  }
}

enum WeightGoal { lose, maintain, gain }

extension WeightGoalExtension on WeightGoal {
  String get displayName {
    return switch (this) {
      WeightGoal.lose => 'Perder peso',
      WeightGoal.maintain => 'Mantener peso',
      WeightGoal.gain => 'Ganar peso',
    };
  }

  String get description {
    return switch (this) {
      WeightGoal.lose => 'Déficit calórico para pérdida de grasa',
      WeightGoal.maintain => 'Balance calórico para mantenimiento',
      WeightGoal.gain => 'Superávit calórico para ganancia muscular',
    };
  }
}
