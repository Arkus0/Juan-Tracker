class Rutina {
  final String id;
  final String nombre;
  final List<String> ejerciciosPlantilla;

  Rutina({
    required this.id,
    required this.nombre,
    List<String>? ejerciciosPlantilla,
  }) : ejerciciosPlantilla = List.unmodifiable(ejerciciosPlantilla ?? const []);

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'ejerciciosPlantilla': ejerciciosPlantilla,
  };

  factory Rutina.fromMap(Map<String, dynamic> map) {
    return Rutina(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      ejerciciosPlantilla:
          (map['ejerciciosPlantilla'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
    );
  }

  @override
  String toString() => 'Rutina(id: $id, nombre: $nombre)';
}
