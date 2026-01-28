class TrainingExercise {
  final String id;
  final String nombre;
  final String grupoMuscular;
  final List<String> musculosSecundarios;
  final String equipo;
  final String nivel;
  final String descripcion;

  TrainingExercise({
    required this.id,
    required this.nombre,
    required this.grupoMuscular,
    required this.musculosSecundarios,
    required this.equipo,
    required this.nivel,
    required this.descripcion,
  });

  TrainingExercise copyWith({
    String? nombre,
    String? grupoMuscular,
    List<String>? musculosSecundarios,
    String? equipo,
    String? nivel,
    String? descripcion,
  }) {
    return TrainingExercise(
      id: id,
      nombre: nombre ?? this.nombre,
      grupoMuscular: grupoMuscular ?? this.grupoMuscular,
      musculosSecundarios: musculosSecundarios ?? this.musculosSecundarios,
      equipo: equipo ?? this.equipo,
      nivel: nivel ?? this.nivel,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'grupoMuscular': grupoMuscular,
    'musculosSecundarios': musculosSecundarios,
    'equipo': equipo,
    'nivel': nivel,
    'descripcion': descripcion,
  };

  factory TrainingExercise.fromMap(Map<String, dynamic> map) {
    return TrainingExercise(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      grupoMuscular: map['grupoMuscular'] as String? ?? '',
      musculosSecundarios:
          (map['musculosSecundarios'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      equipo: map['equipo'] as String? ?? '',
      nivel: map['nivel'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
    );
  }

  @override
  String toString() => 'TrainingExercise(id: $id, nombre: $nombre)';
}
