/// Tipo de serie/estimulo para un ejercicio en la rutina.
///
/// Se usa para marcar metodos avanzados como dropset, rest-pause, myo reps o AMRAP.
enum TrainingSetType {
  normal('normal', 'Normal'),
  dropSet('dropset', 'Drop set'),
  restPause('rest_pause', 'Rest-pause'),
  myoReps('myo_reps', 'Myo reps'),
  amrap('amrap', 'AMRAP');

  final String value;
  final String label;

  const TrainingSetType(this.value, this.label);

  static TrainingSetType fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TrainingSetType.normal;
    }
    for (final type in TrainingSetType.values) {
      if (type.value == value || type.name == value) return type;
    }
    return TrainingSetType.normal;
  }

  bool get isDefault => this == TrainingSetType.normal;

  String get shortLabel => switch (this) {
    TrainingSetType.normal => 'NORMAL',
    TrainingSetType.dropSet => 'DROP',
    TrainingSetType.restPause => 'R-P',
    TrainingSetType.myoReps => 'MYO',
    TrainingSetType.amrap => 'AMRAP',
  };
}
