class SerieLog {
  final double peso;
  final int reps;
  final bool completed;
  final int? rpe;

  const SerieLog({
    required this.peso,
    required this.reps,
    this.completed = true,
    this.rpe,
  });

  double get volume => completed ? peso * reps : 0.0;

  Map<String, dynamic> toMap() => {
    'peso': peso,
    'reps': reps,
    'completed': completed,
    'rpe': rpe,
  };

  factory SerieLog.fromMap(Map<String, dynamic> map) {
    return SerieLog(
      peso: (map['peso'] as num?)?.toDouble() ?? 0.0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      completed: map['completed'] as bool? ?? true,
      rpe: (map['rpe'] as num?)?.toInt(),
    );
  }

  @override
  String toString() =>
      'SerieLog(peso: $peso, reps: $reps, completed: $completed, rpe: $rpe)';
}
