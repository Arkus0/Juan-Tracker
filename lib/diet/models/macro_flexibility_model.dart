// Modelo de configuración de rangos flexibles de macros
//
// Permite configurar tolerancias (±%) para cada macro.
// Dentro del rango: verde (en objetivo)
// Fuera pero cercano (±1.5x tolerancia): amarillo (aceptable)
// Muy fuera: rojo (necesita ajuste)

import 'dart:convert';

/// Configuración de rangos flexibles para macronutrientes.
///
/// MacroFactor muestra "zonas" en las barras de progreso
/// indicando si estás dentro del rango aceptable para cada macro.
class MacroFlexibilityConfig {
  /// Si los rangos flexibles están habilitados
  final bool enabled;

  /// Tolerancia para calorías (fracción, e.g. 0.05 = ±5%)
  final double kcalTolerance;

  /// Tolerancia para proteína (fracción, e.g. 0.10 = ±10%)
  final double proteinTolerance;

  /// Tolerancia para carbohidratos (fracción, e.g. 0.15 = ±15%)
  final double carbsTolerance;

  /// Tolerancia para grasa (fracción, e.g. 0.15 = ±15%)
  final double fatTolerance;

  const MacroFlexibilityConfig({
    this.enabled = true,
    this.kcalTolerance = 0.05,
    this.proteinTolerance = 0.10,
    this.carbsTolerance = 0.15,
    this.fatTolerance = 0.15,
  });

  /// Configuración por defecto (MacroFactor-like)
  static const defaults = MacroFlexibilityConfig();

  /// Configuración estricta (menor tolerancia)
  static const strict = MacroFlexibilityConfig(
    kcalTolerance: 0.03,
    proteinTolerance: 0.05,
    carbsTolerance: 0.10,
    fatTolerance: 0.10,
  );

  /// Configuración relajada (mayor tolerancia)
  static const relaxed = MacroFlexibilityConfig(
    kcalTolerance: 0.10,
    proteinTolerance: 0.15,
    carbsTolerance: 0.20,
    fatTolerance: 0.20,
  );

  MacroFlexibilityConfig copyWith({
    bool? enabled,
    double? kcalTolerance,
    double? proteinTolerance,
    double? carbsTolerance,
    double? fatTolerance,
  }) {
    return MacroFlexibilityConfig(
      enabled: enabled ?? this.enabled,
      kcalTolerance: kcalTolerance ?? this.kcalTolerance,
      proteinTolerance: proteinTolerance ?? this.proteinTolerance,
      carbsTolerance: carbsTolerance ?? this.carbsTolerance,
      fatTolerance: fatTolerance ?? this.fatTolerance,
    );
  }

  /// Calcula el rango de un macro dado su objetivo y tolerancia.
  MacroRange rangeForKcal(int target) =>
      MacroRange.fromTarget(target.toDouble(), kcalTolerance);

  MacroRange rangeForProtein(double target) =>
      MacroRange.fromTarget(target, proteinTolerance);

  MacroRange rangeForCarbs(double target) =>
      MacroRange.fromTarget(target, carbsTolerance);

  MacroRange rangeForFat(double target) =>
      MacroRange.fromTarget(target, fatTolerance);

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'kcalTolerance': kcalTolerance,
        'proteinTolerance': proteinTolerance,
        'carbsTolerance': carbsTolerance,
        'fatTolerance': fatTolerance,
      };

  factory MacroFlexibilityConfig.fromJson(Map<String, dynamic> json) {
    return MacroFlexibilityConfig(
      enabled: json['enabled'] as bool? ?? true,
      kcalTolerance: (json['kcalTolerance'] as num?)?.toDouble() ?? 0.05,
      proteinTolerance:
          (json['proteinTolerance'] as num?)?.toDouble() ?? 0.10,
      carbsTolerance: (json['carbsTolerance'] as num?)?.toDouble() ?? 0.15,
      fatTolerance: (json['fatTolerance'] as num?)?.toDouble() ?? 0.15,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory MacroFlexibilityConfig.fromJsonString(String json) {
    return MacroFlexibilityConfig.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }
}

/// Rango calculado para un macro específico.
///
/// Define el rango aceptable (zona verde) y el rango de advertencia
/// (zona amarilla) alrededor del objetivo.
class MacroRange {
  /// Valor objetivo central
  final double target;

  /// Límite inferior de la zona verde (aceptable)
  final double greenMin;

  /// Límite superior de la zona verde (aceptable)
  final double greenMax;

  /// Límite inferior de la zona amarilla (advertencia)
  final double yellowMin;

  /// Límite superior de la zona amarilla (advertencia)
  final double yellowMax;

  const MacroRange({
    required this.target,
    required this.greenMin,
    required this.greenMax,
    required this.yellowMin,
    required this.yellowMax,
  });

  /// Crea un rango a partir del objetivo y la tolerancia.
  ///
  /// Zona verde: target ± tolerance
  /// Zona amarilla: target ± (tolerance * 1.5)
  factory MacroRange.fromTarget(double target, double tolerance) {
    final greenDelta = target * tolerance;
    final yellowDelta = target * tolerance * 1.5;

    return MacroRange(
      target: target,
      greenMin: (target - greenDelta).clamp(0, double.infinity),
      greenMax: target + greenDelta,
      yellowMin: (target - yellowDelta).clamp(0, double.infinity),
      yellowMax: target + yellowDelta,
    );
  }

  /// Evalúa un valor consumido contra este rango.
  MacroZoneStatus evaluate(double consumed) {
    if (consumed >= greenMin && consumed <= greenMax) {
      return MacroZoneStatus.onTarget;
    }
    if (consumed >= yellowMin && consumed <= yellowMax) {
      return MacroZoneStatus.acceptable;
    }
    return MacroZoneStatus.offTarget;
  }
}

/// Estado de zona para un macro.
enum MacroZoneStatus {
  /// Dentro del rango verde (±tolerancia del objetivo)
  onTarget,

  /// Dentro del rango amarillo (fuera de verde pero aceptable)
  acceptable,

  /// Fuera de ambos rangos
  offTarget,
}
