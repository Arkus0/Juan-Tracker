import '../services/adaptive_coach_service.dart';

/// Modelo de dominio para objetivos diarios versionados
class TargetsModel {
  final String id;
  final DateTime validFrom; // Desde qué fecha aplica este objetivo
  final int kcalTarget;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;

  // Micronutrient targets (v16)
  final double? fiberTarget;     // g (recomendado: 25-30g)
  final double? sugarLimit;      // g (límite: <50g OMS)
  final double? saturatedFatLimit; // g (límite: <20g)
  final double? sodiumLimit;     // g (límite: <2.3g OMS)

  final String? notes;
  final DateTime createdAt;

  TargetsModel({
    required this.id,
    required this.validFrom,
    required this.kcalTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
    this.fiberTarget,
    this.sugarLimit,
    this.saturatedFatLimit,
    this.sodiumLimit,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Crea una copia con valores modificados
  TargetsModel copyWith({
    String? id,
    DateTime? validFrom,
    int? kcalTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
    double? fiberTarget,
    double? sugarLimit,
    double? saturatedFatLimit,
    double? sodiumLimit,
    String? notes,
    DateTime? createdAt,
  }) =>
      TargetsModel(
        id: id ?? this.id,
        validFrom: validFrom ?? this.validFrom,
        kcalTarget: kcalTarget ?? this.kcalTarget,
        proteinTarget: proteinTarget ?? this.proteinTarget,
        carbsTarget: carbsTarget ?? this.carbsTarget,
        fatTarget: fatTarget ?? this.fatTarget,
        fiberTarget: fiberTarget ?? this.fiberTarget,
        sugarLimit: sugarLimit ?? this.sugarLimit,
        saturatedFatLimit: saturatedFatLimit ?? this.saturatedFatLimit,
        sodiumLimit: sodiumLimit ?? this.sodiumLimit,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Calcula los macros totales (para verificación)
  double? get totalMacroGrams {
    final p = proteinTarget ?? 0;
    final c = carbsTarget ?? 0;
    final f = fatTarget ?? 0;
    final total = p + c + f;
    return total > 0 ? total : null;
  }

  /// Calcula las calorías aproximadas de los macros (para validación)
  int? get kcalFromMacros {
    final p = proteinTarget ?? 0;
    final c = carbsTarget ?? 0;
    final f = fatTarget ?? 0;
    // 4 kcal/g de proteína y carbs, 9 kcal/g de grasa
    return ((p * 4) + (c * 4) + (f * 9)).round();
  }

  /// Crea un TargetsModel desde un CoachPlan
  /// 
  /// Convierte el plan del Coach Adaptativo al formato tradicional de targets
  /// para compatibilidad con UI existente.
  factory TargetsModel.fromCoachPlan({
    required CoachPlan coachPlan,
    required int calculatedCalories,
  }) {
    // Importamos aquí para evitar dependencia circular
    // ignore: unused_import
    final macroGrams = coachPlan.macroPreset.calculateGrams(calculatedCalories);
    
    return TargetsModel(
      id: coachPlan.id,
      validFrom: coachPlan.startDate,
      kcalTarget: calculatedCalories,
      proteinTarget: macroGrams.protein.toDouble(),
      carbsTarget: macroGrams.carbs.toDouble(),
      fatTarget: macroGrams.fat.toDouble(),
      notes: coachPlan.notes ?? 'Generado por Coach Adaptativo',
    );
  }

  /// Devuelve el objetivo activo para una fecha dada desde una lista ordenada
  static TargetsModel? getActiveForDate(
    List<TargetsModel> allTargets,
    DateTime date,
  ) {
    if (allTargets.isEmpty) return null;

    // Ordenar por validFrom descendente
    final sorted = List<TargetsModel>.from(allTargets)
      ..sort((a, b) => b.validFrom.compareTo(a.validFrom));

    // Encontrar el primero cuya validFrom sea <= date
    for (final target in sorted) {
      if (target.validFrom.isBefore(date) ||
          target.validFrom.isAtSameMomentAs(date)) {
        return target;
      }
    }

    return null;
  }

  Map<String, dynamic> toDebugMap() => {
        'id': id,
        'validFrom': validFrom.toIso8601String(),
        'kcalTarget': kcalTarget,
        'proteinTarget': proteinTarget,
        'carbsTarget': carbsTarget,
        'fatTarget': fatTarget,
      };

  @override
  String toString() => 'TargetsModel(${toDebugMap()})';
}

/// Progreso contra objetivos para un día
class TargetsProgress {
  final TargetsModel? targets;
  final int kcalConsumed;
  final double proteinConsumed;
  final double carbsConsumed;
  final double fatConsumed;
  final double fiberConsumed;
  final double sugarConsumed;
  final double saturatedFatConsumed;
  final double sodiumConsumed;

  const TargetsProgress({
    this.targets,
    required this.kcalConsumed,
    required this.proteinConsumed,
    required this.carbsConsumed,
    required this.fatConsumed,
    this.fiberConsumed = 0,
    this.sugarConsumed = 0,
    this.saturatedFatConsumed = 0,
    this.sodiumConsumed = 0,
  });

  /// Porcentajes de progreso (0.0 - 1.0+)
  /// Retorna null si el objetivo es 0 o no existe (evita división por cero)
  double? get kcalPercent =>
      targets != null && targets!.kcalTarget > 0
          ? kcalConsumed / targets!.kcalTarget
          : null;

  double? get proteinPercent =>
      targets?.proteinTarget != null && targets!.proteinTarget! > 0
          ? proteinConsumed / targets!.proteinTarget!
          : null;

  double? get carbsPercent =>
      targets?.carbsTarget != null && targets!.carbsTarget! > 0
          ? carbsConsumed / targets!.carbsTarget!
          : null;

  double? get fatPercent =>
      targets?.fatTarget != null && targets!.fatTarget! > 0
          ? fatConsumed / targets!.fatTarget!
          : null;

  /// Porcentaje de fibra (meta mínima)
  double? get fiberPercent =>
      targets?.fiberTarget != null && targets!.fiberTarget! > 0
          ? fiberConsumed / targets!.fiberTarget!
          : null;

  /// Porcentaje de azúcar (límite máximo)
  double? get sugarPercent =>
      targets?.sugarLimit != null && targets!.sugarLimit! > 0
          ? sugarConsumed / targets!.sugarLimit!
          : null;

  /// Porcentaje de grasa saturada (límite máximo)
  double? get saturatedFatPercent =>
      targets?.saturatedFatLimit != null && targets!.saturatedFatLimit! > 0
          ? saturatedFatConsumed / targets!.saturatedFatLimit!
          : null;

  /// Porcentaje de sodio (límite máximo)
  double? get sodiumPercent =>
      targets?.sodiumLimit != null && targets!.sodiumLimit! > 0
          ? sodiumConsumed / targets!.sodiumLimit!
          : null;

  /// Calorías/macros restantes
  int? get kcalRemaining => targets != null
      ? targets!.kcalTarget - kcalConsumed
      : null;

  double? get proteinRemaining => targets?.proteinTarget != null
      ? targets!.proteinTarget! - proteinConsumed
      : null;

  Map<String, dynamic> toDebugMap() => {
        'targets': targets?.toDebugMap(),
        'kcalConsumed': kcalConsumed,
        'proteinConsumed': proteinConsumed,
        'carbsConsumed': carbsConsumed,
        'fatConsumed': fatConsumed,
        'kcalPercent': kcalPercent,
      };

  @override
  String toString() => 'TargetsProgress(${toDebugMap()})';
}
