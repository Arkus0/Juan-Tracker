/// Calculadora de 1RM (One Rep Max)
///
/// Implementa múltiples fórmulas científicas para estimar el 1RM
/// basado en peso y reps realizadas.
///
/// Referencias:
/// - Brzycki (1993): Peso / (1.0278 - 0.0278 × reps)
/// - Epley: Peso × (1 + reps/30)
/// - Lombardi: Peso × reps^0.10
/// - Mayhew et al.: Peso × 100 / (52.2 + 41.9 × e^(-0.055×reps))
/// - O'Conner et al.: Peso × (1 + reps/40)
/// - Wathen: Peso × 100 / (48.8 + 53.8 × e^(-0.075×reps))
library;

class OneRMCalculator {
  /// Fórmulas disponibles
  static const Map<String, OneRMFormula> formulas = {
    'brzycki': OneRMFormula.brzycki,
    'epley': OneRMFormula.epley,
    'lombardi': OneRMFormula.lombardi,
    'mayhew': OneRMFormula.mayhew,
    'oconner': OneRMFormula.oconner,
    'wathen': OneRMFormula.wathen,
    'average': OneRMFormula.average,
  };

  /// Calcula 1RM usando la fórmula especificada.
  ///
  /// [weight]: Peso levantado
  /// [reps]: Repeticiones realizadas (debe ser >= 1)
  /// [formula]: Fórmula a usar (default: average)
  static double calculate({
    required double weight,
    required int reps,
    OneRMFormula formula = OneRMFormula.average,
  }) {
    if (reps < 1) return weight;
    if (reps == 1) return weight;
    if (weight <= 0) return 0;

    switch (formula) {
      case OneRMFormula.brzycki:
        return _brzycki(weight, reps);
      case OneRMFormula.epley:
        return _epley(weight, reps);
      case OneRMFormula.lombardi:
        return _lombardi(weight, reps);
      case OneRMFormula.mayhew:
        return _mayhew(weight, reps);
      case OneRMFormula.oconner:
        return _oconner(weight, reps);
      case OneRMFormula.wathen:
        return _wathen(weight, reps);
      case OneRMFormula.average:
        return _average(weight, reps);
    }
  }

  /// Calcula todas las fórmulas y retorna un resumen.
  static OneRMResult calculateAll({
    required double weight,
    required int reps,
  }) {
    final results = <OneRMFormula, double>{};
    
    for (final formula in OneRMFormula.values) {
      if (formula != OneRMFormula.average) {
        results[formula] = calculate(weight: weight, reps: reps, formula: formula);
      }
    }
    
    final average = results.values.reduce((a, b) => a + b) / results.length;
    
    return OneRMResult(
      weight: weight,
      reps: reps,
      results: results,
      average: average,
      recommended: average,
    );
  }

  /// Fórmula de Brzycki (1993) - Más precisa para 1-10 reps
  static double _brzycki(double weight, int reps) {
    return weight / (1.0278 - 0.0278 * reps);
  }

  /// Fórmula de Epley - Buena para >5 reps
  static double _epley(double weight, int reps) {
    return weight * (1 + reps / 30);
  }

  /// Fórmula de Lombardi - Buena para rango amplio
  static double _lombardi(double weight, int reps) {
    return weight * reps.toDouble().pow(0.10);
  }

  /// Fórmula de Mayhew et al. - Precisa para fuerza atlética
  static double _mayhew(double weight, int reps) {
    return weight * 100 / (52.2 + 41.9 * e(-0.055 * reps));
  }

  /// Fórmula de O'Conner et al.
  static double _oconner(double weight, int reps) {
    return weight * (1 + reps / 40);
  }

  /// Fórmula de Wathen - Precisa para fuerza general
  static double _wathen(double weight, int reps) {
    return weight * 100 / (48.8 + 53.8 * e(-0.075 * reps));
  }

  /// Promedio de todas las fórmulas (recomendado)
  static double _average(double weight, int reps) {
    final results = [
      _brzycki(weight, reps),
      _epley(weight, reps),
      _lombardi(weight, reps),
      _mayhew(weight, reps),
      _oconner(weight, reps),
      _wathen(weight, reps),
    ];
    return results.reduce((a, b) => a + b) / results.length;
  }

  /// Calcula el peso objetivo para un % del 1RM.
  ///
  /// Ejemplo: oneRM = 100kg, percentage = 0.75 → 75kg
  static double calculateWeightForPercentage({
    required double oneRM,
    required double percentage,
  }) {
    return oneRM * percentage;
  }

  /// Calcula tabla de porcentajes completa para un 1RM.
  static Map<int, double> calculatePercentageTable(double oneRM) {
    return {
      100: oneRM,
      95: oneRM * 0.95,
      90: oneRM * 0.90,
      85: oneRM * 0.85,
      80: oneRM * 0.80,
      75: oneRM * 0.75,
      70: oneRM * 0.70,
      65: oneRM * 0.65,
      60: oneRM * 0.60,
      55: oneRM * 0.55,
      50: oneRM * 0.50,
    };
  }

  /// Recomienda peso y reps basado en objetivo.
  static TrainingRecommendation recommend({
    required double oneRM,
    required TrainingGoal goal,
  }) {
    switch (goal) {
      case TrainingGoal.strength:
        return TrainingRecommendation(
          sets: 3,
          reps: 3,
          weight: oneRM * 0.90,
          percentage: 90,
          description: 'Fuerza máxima',
        );
      case TrainingGoal.power:
        return TrainingRecommendation(
          sets: 3,
          reps: 5,
          weight: oneRM * 0.85,
          percentage: 85,
          description: 'Potencia',
        );
      case TrainingGoal.hypertrophy:
        return TrainingRecommendation(
          sets: 3,
          reps: 8,
          weight: oneRM * 0.75,
          percentage: 75,
          description: 'Hipertrofia',
        );
      case TrainingGoal.endurance:
        return TrainingRecommendation(
          sets: 3,
          reps: 12,
          weight: oneRM * 0.65,
          percentage: 65,
          description: 'Resistencia',
        );
    }
  }
}

/// Fórmulas disponibles
enum OneRMFormula {
  brzycki,
  epley,
  lombardi,
  mayhew,
  oconner,
  wathen,
  average,
}

/// Extensión para cálculos matemáticos
extension on double {
  double pow(double exponent) {
    return _pow(this, exponent);
  }
}

double _pow(double base, double exponent) {
  // Implementación simple de potencia
  if (exponent == 0) return 1;
  if (exponent == 1) return base;
  if (exponent == 0.5) return _sqrt(base);
  if (exponent == 0.10) return _pow10(base);
  
  double result = 1;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

double _sqrt(double x) {
  if (x < 0) return double.nan;
  if (x == 0) return 0;
  
  double guess = x / 2;
  for (int i = 0; i < 10; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}

double _pow10(double x) {
  // x^0.10 = 10^(0.10 * log10(x))
  // Aproximación: x^0.1 para valores típicos de peso
  if (x <= 0) return 0;
  
  // Aproximación polinomial para x^0.1
  final logX = _ln(x);
  return _exp(0.1 * logX);
}

double _ln(double x) {
  // Aproximación de logaritmo natural
  if (x <= 0) return double.negativeInfinity;
  
  double n = 0;
  double a = x;
  
  while (a > 1) {
    a /= 2.718281828459045;
    n++;
  }
  
  a -= 1;
  double sum = 0;
  double term = a;
  
  for (int i = 1; i <= 20; i++) {
    sum += term / i;
    term *= -a;
  }
  
  return n + sum;
}

double _exp(double x) {
  // Aproximación de e^x
  double sum = 1;
  double term = 1;
  
  for (int i = 1; i <= 20; i++) {
    term *= x / i;
    sum += term;
  }
  
  return sum;
}

double e(double exponent) {
  return _exp(exponent);
}

/// Resultado del cálculo de 1RM
class OneRMResult {
  final double weight;
  final int reps;
  final Map<OneRMFormula, double> results;
  final double average;
  final double recommended;

  const OneRMResult({
    required this.weight,
    required this.reps,
    required this.results,
    required this.average,
    required this.recommended,
  });

  /// 1RM redondeado a múltiplo de 0.5 o 1.0 según magnitud
  double get rounded {
    if (recommended < 20) return (recommended * 2).round() / 2;
    return recommended.round().toDouble();
  }

  /// Variación entre fórmulas (indica confiabilidad)
  double get variation {
    final values = results.values.toList();
    if (values.isEmpty) return 0;
    
    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) / values.length;
    return _sqrt(variance);
  }

  /// Confianza del cálculo (0-100%)
  double get confidence {
    // Menos reps = más confianza
    // Menos variación entre fórmulas = más confianza
    final repsConfidence = reps <= 5 ? 1.0 : (reps <= 10 ? 0.8 : 0.6);
    final variationFactor = 1 - (variation / recommended).clamp(0.0, 0.5);
    return (repsConfidence * variationFactor * 100).round().toDouble();
  }
}

/// Objetivos de entrenamiento
enum TrainingGoal {
  strength,    // Fuerza máxima (1-5 reps, 85-100%)
  power,       // Potencia (3-6 reps, 75-90%)
  hypertrophy, // Hipertrofia (6-12 reps, 65-85%)
  endurance,   // Resistencia (12+ reps, <70%)
}

/// Recomendación de entrenamiento
class TrainingRecommendation {
  final int sets;
  final int reps;
  final double weight;
  final int percentage;
  final String description;

  const TrainingRecommendation({
    required this.sets,
    required this.reps,
    required this.weight,
    required this.percentage,
    required this.description,
  });
}
