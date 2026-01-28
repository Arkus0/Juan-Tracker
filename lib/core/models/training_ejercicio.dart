import 'training_serie_log.dart';

class Ejercicio {
  final String id;
  final String nombre;
  final List<SerieLog> logs;

  Ejercicio({required this.id, required this.nombre, List<SerieLog>? logs})
    : logs = List.unmodifiable(logs ?? const []);

  int get completedSetsCount => logs.where((l) => l.completed).length;

  double get totalVolume => logs.fold(0.0, (sum, l) => sum + l.volume);

  double get maxWeight => logs
      .where((l) => l.completed)
      .fold(0.0, (max, l) => l.peso > max ? l.peso : max);

  Ejercicio copyWith({String? nombre, List<SerieLog>? logs}) {
    return Ejercicio(
      id: id,
      nombre: nombre ?? this.nombre,
      logs: logs ?? this.logs,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'logs': logs.map((l) => l.toMap()).toList(),
  };

  factory Ejercicio.fromMap(Map<String, dynamic> map) {
    final rawLogs = map['logs'] as List<dynamic>? ?? const [];
    return Ejercicio(
      id: map['id'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      logs: rawLogs
          .map((e) => SerieLog.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  @override
  String toString() => 'Ejercicio(id: $id, nombre: $nombre, logs: $logs)';
}
