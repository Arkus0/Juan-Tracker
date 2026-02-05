/// Validador centralizado para entrada manual de peso corporal.
class WeightInputValidator {
  static const double minWeightKg = 20;
  static const double maxWeightKg = 500;

  const WeightInputValidator._();

  /// Parsea texto de usuario a `double` soportando coma decimal.
  static double? parse(String rawInput) {
    final normalized = rawInput.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  /// Valida un input textual y retorna mensaje de error o null si es válido.
  static String? validate(String rawInput) {
    final value = parse(rawInput);
    if (value == null) {
      return 'Ingresa un peso válido';
    }

    if (value < minWeightKg || value > maxWeightKg) {
      return 'Ingresa un peso válido ($minWeightKg-$maxWeightKg kg)';
    }

    return null;
  }
}
