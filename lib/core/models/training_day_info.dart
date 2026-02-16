/// Información ligera sobre entrenamiento de un día.
///
/// DTO del módulo core para que el módulo de dieta pueda
/// consultar si el usuario entrenó sin importar modelos
/// del módulo de entrenamiento directamente.
class TrainingDayInfo {
  /// Si el usuario completó al menos una sesión ese día
  final bool didTrain;

  /// Grupos musculares principales (nombres en español: Pecho, Espalda…)
  final List<String> muscleGroups;

  /// Duración total en minutos
  final int? durationMinutes;

  /// Volumen total (kg × reps) de la sesión
  final double? totalVolume;

  /// Cantidad de sesiones completadas ese día
  final int sessionsCount;

  /// Nombre del día de rutina (ej. "Push", "Piernas")
  final String? dayName;

  const TrainingDayInfo({
    required this.didTrain,
    required this.muscleGroups,
    this.durationMinutes,
    this.totalVolume,
    this.sessionsCount = 0,
    this.dayName,
  });

  /// Día de descanso (sin sesiones)
  const TrainingDayInfo.rest()
      : didTrain = false,
        muscleGroups = const [],
        durationMinutes = null,
        totalVolume = null,
        sessionsCount = 0,
        dayName = null;

  /// Resumen corto para UI (ej. "Pecho, Espalda · 45 min")
  String get shortSummary {
    if (!didTrain) return 'Descanso';
    final parts = <String>[];
    if (muscleGroups.isNotEmpty) {
      parts.add(muscleGroups.take(3).join(', '));
    } else if (dayName != null) {
      parts.add(dayName!);
    }
    if (durationMinutes != null && durationMinutes! > 0) {
      parts.add('${durationMinutes}min');
    }
    return parts.join(' · ');
  }
}
