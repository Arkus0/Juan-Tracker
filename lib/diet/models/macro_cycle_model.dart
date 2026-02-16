// Modelo de ciclado de macros por día de la semana (estilo MacroFactor).
//
// Permite configurar dos perfiles de macros: días de entrenamiento y días de descanso.
// Cada día de la semana se asigna a uno de estos perfiles.
//
// El ciclado mantiene el promedio semanal de calorías constante.

/// Tipo de día para ciclado de macros
enum DayType {
  training,
  rest,
  fasting;

  String get displayName => switch (this) {
    training => 'Entrenamiento',
    rest => 'Descanso',
    fasting => 'Ayuno',
  };

  String get shortName => switch (this) {
    training => 'E',
    rest => 'D',
    fasting => 'A',
  };
}

/// Configuración de macros para un tipo de día
class DayMacros {
  final int kcal;
  final double protein;  // gramos
  final double carbs;    // gramos
  final double fat;      // gramos

  const DayMacros({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Crea DayMacros desde un porcentaje relativo al base
  factory DayMacros.fromBase({
    required int baseKcal,
    required double baseProtein,
    required double baseCarbs,
    required double baseFat,
    required double kcalMultiplier, // e.g. 1.15 para +15%
  }) {
    final adjustedKcal = (baseKcal * kcalMultiplier).round();
    // Proteína se mantiene constante (muscular), solo varían carbs y grasa
    final extraKcal = adjustedKcal - baseKcal;
    // 60% del extra a carbs, 40% a grasa
    final extraCarbs = (extraKcal * 0.6) / 4; // 4 kcal/g
    final extraFat = (extraKcal * 0.4) / 9;   // 9 kcal/g

    return DayMacros(
      kcal: adjustedKcal,
      protein: baseProtein,
      carbs: baseCarbs + extraCarbs,
      fat: baseFat + extraFat,
    );
  }

  DayMacros copyWith({
    int? kcal,
    double? protein,
    double? carbs,
    double? fat,
  }) => DayMacros(
    kcal: kcal ?? this.kcal,
    protein: protein ?? this.protein,
    carbs: carbs ?? this.carbs,
    fat: fat ?? this.fat,
  );

  Map<String, dynamic> toJson() => {
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory DayMacros.fromJson(Map<String, dynamic> json) => DayMacros(
    kcal: json['kcal'] as int,
    protein: (json['protein'] as num).toDouble(),
    carbs: (json['carbs'] as num).toDouble(),
    fat: (json['fat'] as num).toDouble(),
  );
}

/// Configuración completa de ciclado de macros
class MacroCycleConfig {
  final String id;
  final bool enabled;
  
  /// Macros para días de entrenamiento
  final DayMacros trainingDayMacros;
  
  /// Macros para días de descanso
  final DayMacros restDayMacros;
  
  /// Macros para días de ayuno (típicamente 500-600 kcal o 0)
  final DayMacros? fastingDayMacros;
  
  /// Asignación de cada día de la semana (1=Lunes ... 7=Domingo)
  /// Usa estándar ISO (DateTime.monday=1, DateTime.sunday=7)
  final Map<int, DayType> weekdayAssignments;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  MacroCycleConfig({
    required this.id,
    this.enabled = true,
    required this.trainingDayMacros,
    required this.restDayMacros,
    this.fastingDayMacros,
    required this.weekdayAssignments,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Crea una configuración por defecto con distribución estándar
  /// (L-M-X-V entrenamiento, J-S-D descanso)
  factory MacroCycleConfig.defaultConfig({
    required String id,
    required int baseKcal,
    required double baseProtein,
    required double baseCarbs,
    required double baseFat,
  }) {
    return MacroCycleConfig(
      id: id,
      trainingDayMacros: DayMacros.fromBase(
        baseKcal: baseKcal,
        baseProtein: baseProtein,
        baseCarbs: baseCarbs,
        baseFat: baseFat,
        kcalMultiplier: 1.10, // +10% en training
      ),
      restDayMacros: DayMacros.fromBase(
        baseKcal: baseKcal,
        baseProtein: baseProtein,
        baseCarbs: baseCarbs,
        baseFat: baseFat,
        kcalMultiplier: 0.90, // -10% en rest
      ),
      weekdayAssignments: {
        DateTime.monday: DayType.training,
        DateTime.tuesday: DayType.training,
        DateTime.wednesday: DayType.training,
        DateTime.thursday: DayType.rest,
        DateTime.friday: DayType.training,
        DateTime.saturday: DayType.rest,
        DateTime.sunday: DayType.rest,
      },
    );
  }

  /// Obtiene el tipo de día para un DateTime dado
  DayType getDayType(DateTime date) {
    return weekdayAssignments[date.weekday] ?? DayType.rest;
  }

  /// Obtiene los macros aplicables para una fecha
  DayMacros getMacrosForDate(DateTime date) {
    final type = getDayType(date);
    return switch (type) {
      DayType.training => trainingDayMacros,
      DayType.rest => restDayMacros,
      DayType.fasting => fastingDayMacros ?? const DayMacros(kcal: 500, protein: 50, carbs: 30, fat: 15),
    };
  }

  /// Calcula el promedio semanal de kcal
  int get weeklyAvgKcal {
    int total = 0;
    for (final entry in weekdayAssignments.entries) {
      final macros = switch (entry.value) {
        DayType.training => trainingDayMacros,
        DayType.rest => restDayMacros,
        DayType.fasting => fastingDayMacros ?? const DayMacros(kcal: 500, protein: 50, carbs: 30, fat: 15),
      };
      total += macros.kcal;
    }
    return (total / 7).round();
  }

  /// Número de días de entrenamiento por semana
  int get trainingDaysCount =>
      weekdayAssignments.values.where((t) => t == DayType.training).length;

  /// Número de días de descanso por semana
  int get restDaysCount =>
      weekdayAssignments.values.where((t) => t == DayType.rest).length;

  /// Número de días de ayuno por semana
  int get fastingDaysCount =>
      weekdayAssignments.values.where((t) => t == DayType.fasting).length;

  MacroCycleConfig copyWith({
    String? id,
    bool? enabled,
    DayMacros? trainingDayMacros,
    DayMacros? restDayMacros,
    DayMacros? fastingDayMacros,
    Map<int, DayType>? weekdayAssignments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MacroCycleConfig(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    trainingDayMacros: trainingDayMacros ?? this.trainingDayMacros,
    restDayMacros: restDayMacros ?? this.restDayMacros,
    fastingDayMacros: fastingDayMacros ?? this.fastingDayMacros,
    weekdayAssignments: weekdayAssignments ?? this.weekdayAssignments,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
