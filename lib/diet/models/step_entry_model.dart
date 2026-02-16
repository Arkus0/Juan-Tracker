/// Modelo para registro diario de pasos.
///
/// Almacena el conteo de pasos por día con fuente (manual por defecto).
class StepEntry {
  final String dateKey; // 'yyyy-MM-dd'
  final int steps;
  final String source; // 'manual', 'pedometer', etc.

  const StepEntry({
    required this.dateKey,
    required this.steps,
    this.source = 'manual',
  });

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'steps': steps,
        'source': source,
      };

  factory StepEntry.fromJson(Map<String, dynamic> json) => StepEntry(
        dateKey: json['dateKey'] as String,
        steps: json['steps'] as int,
        source: json['source'] as String? ?? 'manual',
      );

  StepEntry copyWith({int? steps, String? source}) => StepEntry(
        dateKey: dateKey,
        steps: steps ?? this.steps,
        source: source ?? this.source,
      );

  /// Estima kcal quemadas por pasos.
  ///
  /// Fórmula simple: pasos × 0.04 kcal/paso (ajustable por peso).
  /// Para 70kg, caminar quema ~0.04 kcal/paso. Para otros pesos
  /// se ajusta linealmente: 0.04 × (peso/70).
  double estimateKcal({double weightKg = 70}) {
    return steps * 0.04 * (weightKg / 70);
  }

  /// Convierte pasos a distancia estimada en km.
  ///
  /// Asume una zancada media de 0.75m.
  double get estimatedKm => steps * 0.75 / 1000;

  /// Formatea los pasos: 12345 → "12.345"
  String get formattedSteps {
    final s = steps.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  String toString() => 'StepEntry($dateKey: $steps pasos)';
}

/// Nivel de actividad inferido de los pasos diarios.
///
/// Basado en Tudor-Locke & Bassett (2004):
/// - < 5.000: Sedentario
/// - 5.000–7.499: Baja actividad
/// - 7.500–9.999: Algo activo
/// - 10.000–12.499: Activo
/// - ≥ 12.500: Muy activo
enum StepActivityLevel {
  sedentary(maxSteps: 4999, label: 'Sedentario', emoji: '🪑'),
  lowActive(maxSteps: 7499, label: 'Baja actividad', emoji: '🚶'),
  somewhatActive(maxSteps: 9999, label: 'Algo activo', emoji: '🚶‍♂️'),
  active(maxSteps: 12499, label: 'Activo', emoji: '🏃'),
  highlyActive(maxSteps: 999999, label: 'Muy activo', emoji: '🏃‍♂️');

  final int maxSteps;
  final String label;
  final String emoji;

  const StepActivityLevel({
    required this.maxSteps,
    required this.label,
    required this.emoji,
  });

  /// Obtiene el nivel de actividad para un conteo de pasos.
  static StepActivityLevel fromSteps(int steps) {
    if (steps < 5000) return sedentary;
    if (steps < 7500) return lowActive;
    if (steps < 10000) return somewhatActive;
    if (steps < 12500) return active;
    return highlyActive;
  }

  /// Multiplier TDEE equivalente (compatible con ActivityLevel).
  double get tdeeMultiplier => switch (this) {
        sedentary => 1.2,
        lowActive => 1.375,
        somewhatActive => 1.55,
        active => 1.725,
        highlyActive => 1.9,
      };
}
