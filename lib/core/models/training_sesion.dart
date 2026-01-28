import 'training_ejercicio.dart';

class Sesion {
  final String id;
  final DateTime fecha;
  final int? durationSeconds;
  final double totalVolume;
  final List<Ejercicio> ejerciciosCompletados;
  final String? rutinaId;
  final String? dayName;

  Sesion({
    required this.id,
    required this.fecha,
    this.durationSeconds,
    required this.totalVolume,
    List<Ejercicio>? ejerciciosCompletados,
    this.rutinaId,
    this.dayName,
  }) : ejerciciosCompletados = List.unmodifiable(
         ejerciciosCompletados ?? const [],
       );

  int get completedSetsCount =>
      ejerciciosCompletados.fold(0, (sum, e) => sum + e.completedSetsCount);

  String get formattedDuration => durationSeconds != null
      ? '${(durationSeconds! / 60).round()} MIN'
      : 'N/A';

  Sesion copyWith({
    DateTime? fecha,
    int? durationSeconds,
    double? totalVolume,
    List<Ejercicio>? ejerciciosCompletados,
    String? rutinaId,
    String? dayName,
  }) {
    return Sesion(
      id: id,
      fecha: fecha ?? this.fecha,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalVolume: totalVolume ?? this.totalVolume,
      ejerciciosCompletados:
          ejerciciosCompletados ?? this.ejerciciosCompletados,
      rutinaId: rutinaId ?? this.rutinaId,
      dayName: dayName ?? this.dayName,
    );
  }

  static double computeTotalVolume(List<Ejercicio> ejercicios) {
    return ejercicios.fold(0.0, (sum, e) => sum + e.totalVolume);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'fecha': fecha.toIso8601String(),
    'durationSeconds': durationSeconds,
    'totalVolume': totalVolume,
    'ejerciciosCompletados': ejerciciosCompletados
        .map((e) => e.toMap())
        .toList(),
    'rutinaId': rutinaId,
    'dayName': dayName,
  };

  factory Sesion.fromMap(Map<String, dynamic> map) {
    final rawEjercicios =
        map['ejerciciosCompletados'] as List<dynamic>? ?? const [];
    return Sesion(
      id: map['id'] as String? ?? '',
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt(),
      totalVolume: (map['totalVolume'] as num?)?.toDouble() ?? 0.0,
      ejerciciosCompletados: rawEjercicios
          .map((e) => Ejercicio.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      rutinaId: map['rutinaId'] as String?,
      dayName: map['dayName'] as String?,
    );
  }

  @override
  String toString() =>
      'Sesion(id: $id, fecha: $fecha, duration: $durationSeconds, totalVolume: $totalVolume)';
}
