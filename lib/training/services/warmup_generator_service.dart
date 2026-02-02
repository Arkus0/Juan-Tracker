/// Servicio para generar sets de calentamiento automáticamente
/// Basado en porcentajes del peso de trabajo
class WarmupGeneratorService {
  static final WarmupGeneratorService _instance = WarmupGeneratorService._internal();
  factory WarmupGeneratorService() => _instance;
  WarmupGeneratorService._internal();

  /// Genera sets de calentamiento para un peso objetivo
  /// 
  /// Parámetros:
  /// - targetWeight: Peso de trabajo (kg)
  /// - barWeight: Peso de la barra (default 20kg para barra olímpica)
  /// - includeEmptyBar: Incluir barra vacía (default true)
  /// 
  /// Retorna lista de (peso, reps) para calentamiento
  List<WarmupSet> generateWarmupSets({
    required double targetWeight,
    double barWeight = 20.0,
    bool includeEmptyBar = true,
  }) {
    if (targetWeight <= 0) return [];
    if (targetWeight <= barWeight) {
      // Si el peso es ligero, solo 1 set de calentamiento
      return [WarmupSet(weight: targetWeight * 0.5, reps: 10)];
    }

    final sets = <WarmupSet>[];
    
    // Set 1: Barra vacía (si se solicita y aplica)
    if (includeEmptyBar && targetWeight > barWeight * 1.5) {
      sets.add(WarmupSet(weight: barWeight, reps: 10));
    }
    
    // Set 2: 50% del peso objetivo
    final weight50 = _roundWeight((targetWeight * 0.5).clamp(barWeight, targetWeight));
    if (weight50 < targetWeight && (sets.isEmpty || weight50 > sets.last.weight)) {
      sets.add(WarmupSet(weight: weight50, reps: 5));
    }
    
    // Set 3: 75% del peso objetivo
    final weight75 = _roundWeight((targetWeight * 0.75).clamp(weight50, targetWeight));
    if (weight75 < targetWeight && weight75 > weight50) {
      sets.add(WarmupSet(weight: weight75, reps: 3));
    }
    
    // Set 4: 90% del peso objetivo (solo si el peso es muy pesado)
    if (targetWeight > 100) {
      final weight90 = _roundWeight(targetWeight * 0.9);
      if (weight90 < targetWeight && weight90 > weight75) {
        sets.add(WarmupSet(weight: weight90, reps: 1));
      }
    }

    return sets;
  }

  /// Genera warm-up para serie específica con historial
  /// Usa la primera serie incompleta como referencia
  List<WarmupSet> generateFromFirstWorkSet(List<double?> previousWeights, double barWeight) {
    // Encontrar el primer peso válido
    final targetWeight = previousWeights.firstWhere(
      (w) => w != null && w > 0,
      orElse: () => null,
    );
    
    if (targetWeight == null) return [];
    
    return generateWarmupSets(
      targetWeight: targetWeight,
      barWeight: barWeight,
      includeEmptyBar: targetWeight > barWeight * 1.5,
    );
  }

  /// Redondea el peso a múltiplo de 2.5kg (discos estándar)
  double _roundWeight(double weight) {
    return (weight / 2.5).round() * 2.5;
  }

  /// Determina si el ejercicio debería tener warm-up
  /// Basado en grupo muscular y si es compuesto
  bool shouldHaveWarmup(String muscleGroup, {bool isCompound = true}) {
    // Siempre calentar ejercicios compuestos pesados
    if (isCompound) return true;
    
    // Calentar grupos grandes
    final heavyMuscleGroups = [
      'Pecho',
      'Espalda', 
      'Piernas',
      'Gluteos',
      'Femoral',
      'Cuadriceps',
    ];
    
    return heavyMuscleGroups.any((mg) => 
      muscleGroup.toLowerCase().contains(mg.toLowerCase())
    );
  }
}

/// Modelo de un set de calentamiento
class WarmupSet {
  final double weight;
  final int reps;

  const WarmupSet({
    required this.weight,
    required this.reps,
  });

  @override
  String toString() => '${weight.toStringAsFixed(1)}kg × $reps';
}
