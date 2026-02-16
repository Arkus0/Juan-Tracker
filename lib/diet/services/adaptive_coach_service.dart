/// Servicio de Coach Adaptativo estilo MacroFactor
library;

import '../models/targets_model.dart';
import '../models/weighin_model.dart';
import 'weight_trend_calculator.dart';

const double kKcalPerKg = 7700.0;
const int kMaxWeeklyKcalChange = 200;
const int kMinWeighInDays = 3;
const int kMinDiaryDays = 4;
const int kMinKcalTarget = 1200;
const int kMaxKcalTarget = 6000;

/// Presets de distribución de macros
enum MacroPreset {
  lowCarb('Low Carb', 'Bajo en carbohidratos, alto en grasas', 0.25, 0.45, 0.30),
  balanced('Balanceado', 'Distribución equilibrada', 0.30, 0.35, 0.35),
  highProtein('High Protein', 'Alto en proteínas para ganancia muscular', 0.40, 0.30, 0.30),
  highCarb('High Carb', 'Alto en carbohidratos para energía', 0.25, 0.50, 0.25),
  keto('Keto', 'Muy bajo en carbohidratos', 0.30, 0.05, 0.65),
  custom('Personalizado', 'Macros ajustados manualmente', 0.30, 0.35, 0.35);

  final String displayName;
  final String description;
  final double proteinPercent;
  final double carbsPercent;
  final double fatPercent;

  const MacroPreset(
    this.displayName,
    this.description,
    this.proteinPercent,
    this.carbsPercent,
    this.fatPercent,
  );

  /// Calcula los gramos de macros basado en las calorías totales
  MacroGrams calculateGrams(int totalKcal) {
    final proteinKcal = totalKcal * proteinPercent;
    final carbsKcal = totalKcal * carbsPercent;
    final fatKcal = totalKcal * fatPercent;

    return MacroGrams(
      protein: (proteinKcal / 4).round(),
      carbs: (carbsKcal / 4).round(),
      fat: (fatKcal / 9).round(),
    );
  }
}

/// Gramos de macros calculados
class MacroGrams {
  final int protein;
  final int carbs;
  final int fat;

  const MacroGrams({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  int get totalKcal => (protein * 4) + (carbs * 4) + (fat * 9);
}

/// Configuración del Coach Adaptativo
class AdaptiveCoachConfig {
  final int maxWeeklyKcalChange;
  final double kcalPerKg;
  final int minWeighInDays;
  final int minDiaryDays;
  final MacroPreset macroPreset;
  final double? proteinMultiplier; // Null si usamos presets
  final double? fatPercentage;     // Null si usamos presets

  const AdaptiveCoachConfig({
    this.maxWeeklyKcalChange = kMaxWeeklyKcalChange,
    this.kcalPerKg = kKcalPerKg,
    this.minWeighInDays = kMinWeighInDays,
    this.minDiaryDays = kMinDiaryDays,
    this.macroPreset = MacroPreset.balanced,
    this.proteinMultiplier,
    this.fatPercentage,
  });

  static const defaultConfig = AdaptiveCoachConfig();
}

enum WeightGoal { lose, maintain, gain }

enum CheckInStatus { ready, insufficientData, notEnoughTime, error }

/// Plan de Coach del usuario (persistido)
class CoachPlan {
  final String id;
  final WeightGoal goal;
  final double weeklyRateKg; // AHORA EN KG en lugar de %
  final int initialTdeeEstimate;
  final double startingWeight;
  final DateTime startDate;
  final DateTime? lastCheckInDate;
  final String? currentTargetId;
  final int? currentKcalTarget; // Necesario para clamps
  final String? notes;
  final MacroPreset macroPreset;
  final bool autoApplyCheckIn;

  const CoachPlan({
    required this.id,
    required this.goal,
    required this.weeklyRateKg,
    required this.initialTdeeEstimate,
    required this.startingWeight,
    required this.startDate,
    this.lastCheckInDate,
    this.currentTargetId,
    this.currentKcalTarget,
    this.notes,
    this.macroPreset = MacroPreset.balanced,
    this.autoApplyCheckIn = false,
  });

  /// Velocidad semanal en kg (ya no %)
  double get weeklyRateDisplay => weeklyRateKg;

  /// Ajuste diario en kcal (déficit o superávit)
  int get dailyAdjustmentKcal {
    // kg/semana * 7700 kcal/kg / 7 días = kcal/día
    return (weeklyRateKg * kKcalPerKg / 7).round();
  }

  /// Descripción del objetivo con kg/semana y kcal de ajuste
  String get goalDescription {
    final kgString = weeklyRateKg.abs().toStringAsFixed(2);
    final kcalString = dailyAdjustmentKcal.abs();
    
    switch (goal) {
      case WeightGoal.lose:
        return 'Perder $kgString kg/semana (${kcalString}kcal déficit)';
      case WeightGoal.maintain:
        return 'Mantener peso';
      case WeightGoal.gain:
        return 'Ganar $kgString kg/semana (${kcalString}kcal superávit)';
    }
  }

  /// Descripción corta para mostrar en cards
  String get goalDescriptionShort {
    final kgString = weeklyRateKg.abs().toStringAsFixed(1);
    
    switch (goal) {
      case WeightGoal.lose:
        return '-$kgString kg/semana';
      case WeightGoal.maintain:
        return 'Mantenimiento';
      case WeightGoal.gain:
        return '+$kgString kg/semana';
    }
  }

  CoachPlan copyWith({
    String? id,
    WeightGoal? goal,
    double? weeklyRateKg,
    int? initialTdeeEstimate,
    double? startingWeight,
    DateTime? startDate,
    DateTime? lastCheckInDate,
    String? currentTargetId,
    int? currentKcalTarget,
    String? notes,
    MacroPreset? macroPreset,
    bool? autoApplyCheckIn,
  }) {
    return CoachPlan(
      id: id ?? this.id,
      goal: goal ?? this.goal,
      weeklyRateKg: weeklyRateKg ?? this.weeklyRateKg,
      initialTdeeEstimate: initialTdeeEstimate ?? this.initialTdeeEstimate,
      startingWeight: startingWeight ?? this.startingWeight,
      startDate: startDate ?? this.startDate,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      currentTargetId: currentTargetId ?? this.currentTargetId,
      currentKcalTarget: currentKcalTarget ?? this.currentKcalTarget,
      notes: notes ?? this.notes,
      macroPreset: macroPreset ?? this.macroPreset,
      autoApplyCheckIn: autoApplyCheckIn ?? this.autoApplyCheckIn,
    );
  }
}

/// Datos de una semana para el check-in
class WeeklyData {
  final DateTime startDate;
  final DateTime endDate;
  final double avgDailyKcal;
  final double trendWeightStart;
  final double trendWeightEnd;
  final int daysWithDiaryEntries;
  final int daysWithWeighIns;

  const WeeklyData({
    required this.startDate,
    required this.endDate,
    required this.avgDailyKcal,
    required this.trendWeightStart,
    required this.trendWeightEnd,
    required this.daysWithDiaryEntries,
    required this.daysWithWeighIns,
  });

  double get trendChangeKg => trendWeightEnd - trendWeightStart;

  double get trendChangeWeeklyKg {
    final days = endDate.difference(startDate).inDays;
    if (days <= 0) return 0;
    return trendChangeKg / days * 7;
  }

  /// TDEE calculado basado en la fórmula:
  /// TDEE = AVG_kcal - (ΔTrendWeight * 7700 / días)
  double get calculatedTdee {
    final days = endDate.difference(startDate).inDays;
    if (days <= 0) return avgDailyKcal;
    final deltaKcal = trendChangeKg * kKcalPerKg / days;
    return avgDailyKcal - deltaKcal;
  }

  bool get hasEnoughData =>
      daysWithDiaryEntries >= kMinDiaryDays && daysWithWeighIns >= kMinWeighInDays;
}

/// Resultado del check-in semanal
class CheckInResult {
  final CheckInStatus status;
  final WeeklyData weeklyData;
  final int estimatedTdee;
  final TargetsModel proposedTargets;
  final CheckInExplanation explanation;
  final bool wasClamped;
  final String? errorMessage;
  final int dailyAdjustmentKcal;
  final MacroGrams macroGrams;

  const CheckInResult({
    required this.status,
    required this.weeklyData,
    required this.estimatedTdee,
    required this.proposedTargets,
    required this.explanation,
    required this.dailyAdjustmentKcal,
    required this.macroGrams,
    this.wasClamped = false,
    this.errorMessage,
  });

  CheckInResult.insufficientData(this.weeklyData, {required String reason})
      : status = CheckInStatus.insufficientData,
        estimatedTdee = 0,
        proposedTargets = TargetsModel(
          id: 'temp',
          validFrom: DateTime.now(),
          kcalTarget: 2000,
        ),
        explanation = CheckInExplanation.empty(),
        wasClamped = false,
        dailyAdjustmentKcal = 0,
        macroGrams = const MacroGrams(protein: 0, carbs: 0, fat: 0),
        errorMessage = reason;
}

/// Explicación transparente de los cálculos
class CheckInExplanation {
  final String line1; // "Ingesta media: 2400 kcal/día"
  final String line2; // "Cambio de peso: -0.3 kg"
  final String line3; // "TDEE estimado: 2733 kcal"
  final String line4; // "Ajuste objetivo: -550 kcal (déficit)"
  final String line5; // "Nuevo target: 2183 kcal"

  const CheckInExplanation({
    required this.line1,
    required this.line2,
    required this.line3,
    required this.line4,
    required this.line5,
  });

  CheckInExplanation.empty()
      : line1 = '',
        line2 = '',
        line3 = '',
        line4 = '',
        line5 = '';

  List<String> get allLines => [line1, line2, line3, line4, line5];
}

/// Servicio principal del Coach Adaptativo
class AdaptiveCoachService {
  final AdaptiveCoachConfig config;
  final WeightTrendCalculator trendCalculator;

  const AdaptiveCoachService({
    this.config = AdaptiveCoachConfig.defaultConfig,
    this.trendCalculator = const WeightTrendCalculator(),
  });

  /// Calcula el check-in semanal
  CheckInResult calculateCheckIn({
    required CoachPlan plan,
    required WeeklyData weeklyData,
    required double currentWeight,
    required DateTime checkInDate,
  }) {
    // Validar datos suficientes
    if (!weeklyData.hasEnoughData) {
      return CheckInResult.insufficientData(
        weeklyData,
        reason: 'Se necesitan al menos ${config.minDiaryDays} días de diario '
            'y ${config.minWeighInDays} pesajes. '
            'Tienes: ${weeklyData.daysWithDiaryEntries} días de diario, '
            '${weeklyData.daysWithWeighIns} pesajes.',
      );
    }

    // Calcular TDEE real basado en datos
    final calculatedTdee = weeklyData.calculatedTdee;

    // Calcular ajuste necesario para cumplir objetivo (en kcal, no %)
    final adjustment = plan.dailyAdjustmentKcal;

    // Nuevo target teórico
    int newTarget = (calculatedTdee + adjustment).round();

    // Aplicar clamps de seguridad
    bool wasClamped = false;
    final previousTarget = plan.currentKcalTarget ?? plan.initialTdeeEstimate;

    // Clamp 1: Máximo cambio por semana
    final maxChange = config.maxWeeklyKcalChange;
    final minAllowed = previousTarget - maxChange;
    final maxAllowed = previousTarget + maxChange;

    if (newTarget < minAllowed) {
      newTarget = minAllowed;
      wasClamped = true;
    } else if (newTarget > maxAllowed) {
      newTarget = maxAllowed;
      wasClamped = true;
    }

    // Clamp 2: Límites de salud absolutos
    if (newTarget < kMinKcalTarget) {
      newTarget = kMinKcalTarget;
      wasClamped = true;
    } else if (newTarget > kMaxKcalTarget) {
      newTarget = kMaxKcalTarget;
      wasClamped = true;
    }

    // Calcular macros usando el preset seleccionado
    final macroGrams = plan.macroPreset.calculateGrams(newTarget);

    // Crear explicación con info de déficit/superávit
    final adjustmentText = adjustment < 0 
        ? '${adjustment}kcal (déficit)'
        : adjustment > 0
            ? '+${adjustment}kcal (superávit)'
            : '0kcal (mantenimiento)';

    final explanation = CheckInExplanation(
      line1: 'Ingesta media: ${weeklyData.avgDailyKcal.round()} kcal/día',
      line2: 'Cambio de trend: ${weeklyData.trendChangeKg > 0 ? "+" : ""}'
          '${weeklyData.trendChangeKg.toStringAsFixed(2)} kg',
      line3: 'TDEE estimado: ${calculatedTdee.round()} kcal',
      line4: 'Ajuste objetivo: $adjustmentText',
      line5: 'Nuevo target: $newTarget kcal',
    );

    final proposedTargets = TargetsModel(
      id: 'coach_${checkInDate.millisecondsSinceEpoch}',
      validFrom: checkInDate,
      kcalTarget: newTarget,
      proteinTarget: macroGrams.protein.toDouble(),
      carbsTarget: macroGrams.carbs.toDouble(),
      fatTarget: macroGrams.fat.toDouble(),
      notes: 'Generado por Coach Adaptativo. TDEE estimado: ${calculatedTdee.round()}. '
          'Preset: ${plan.macroPreset.displayName}',
    );

    return CheckInResult(
      status: CheckInStatus.ready,
      weeklyData: weeklyData,
      estimatedTdee: calculatedTdee.round(),
      proposedTargets: proposedTargets,
      explanation: explanation,
      wasClamped: wasClamped,
      dailyAdjustmentKcal: adjustment,
      macroGrams: macroGrams,
    );
  }

  /// Calcula los datos semanales a partir de entradas crudas
  WeeklyData calculateWeeklyData({
    required DateTime startDate,
    required DateTime endDate,
    required List<int> dailyKcalList,
    required List<WeighInModel> weighIns,
  }) {
    // Calcular promedio de kcal
    final avgKcal = dailyKcalList.isEmpty
        ? 0.0
        : dailyKcalList.reduce((a, b) => a + b) / dailyKcalList.length;

    // Filtrar pesajes del período
    final periodWeighIns = weighIns.where((w) {
      final date = w.dateTime;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Calcular trend weights
    double trendStart = 0;
    double trendEnd = 0;

    if (weighIns.length >= 2) {
      final allTrend = trendCalculator.calculate(weighIns);
      trendEnd = allTrend.trendWeight;

      // Para el trend inicial, calcular solo con datos hasta startDate
      final earlyWeighIns = weighIns.where((w) =>
          w.dateTime.isBefore(startDate.add(const Duration(days: 1)))).toList();
      if (earlyWeighIns.length >= 2) {
        final earlyTrend = trendCalculator.calculate(earlyWeighIns);
        trendStart = earlyTrend.trendWeight;
      } else {
        trendStart = earlyWeighIns.isNotEmpty ? earlyWeighIns.first.weightKg : trendEnd;
      }
    } else if (weighIns.isNotEmpty) {
      trendStart = trendEnd = weighIns.first.weightKg;
    }

    return WeeklyData(
      startDate: startDate,
      endDate: endDate,
      avgDailyKcal: avgKcal,
      trendWeightStart: trendStart,
      trendWeightEnd: trendEnd,
      daysWithDiaryEntries: dailyKcalList.where((k) => k > 0).length,
      daysWithWeighIns: periodWeighIns.length,
    );
  }
}
