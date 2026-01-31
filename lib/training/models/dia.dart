import 'package:uuid/uuid.dart';
import 'ejercicio_en_rutina.dart';

class Dia {
  String nombre;
  List<EjercicioEnRutina> ejercicios;
  String progressionType; // 'none', 'lineal', 'double', 'percentage1RM'
  final String id;
  
  // 🆕 SCHEMA v9: Configuración de scheduling por día (solo modo Pro)
  
  /// Días de la semana asignados a este día de rutina (1=Lunes, 7=Domingo)
  /// Ej: [1, 3, 5] = Lunes, Miércoles, Viernes
  /// Usado cuando la rutina tiene schedulingMode = weeklyAnchored
  final List<int>? weekdays;
  
  /// Horas mínimas de descanso después de este día específico
  /// Si es null, usa el valor global de la rutina
  final int? minRestHours;

  Dia({
    required this.nombre,
    required this.ejercicios,
    this.progressionType = 'none',
    String? id,
    this.weekdays,
    this.minRestHours,
  }) : id = id ?? const Uuid().v4();

  /// Creates a DEEP copy of this day including all exercises.
  /// This ensures modifications don't affect the original object.
  /// 🎯 FIX: Usado para evitar que la edición de rutinas guarde cambios sin guardar explícito.
  Dia deepCopy() {
    return Dia(
      id: id,
      nombre: nombre,
      ejercicios: ejercicios.map((e) => e.deepCopy()).toList(),
      progressionType: progressionType,
      weekdays: weekdays != null ? List<int>.from(weekdays!) : null,
      minRestHours: minRestHours,
    );
  }

  Dia copyWith({
    String? id,
    String? nombre,
    List<EjercicioEnRutina>? ejercicios,
    String? progressionType,
    List<int>? weekdays,
    int? minRestHours,
  }) {
    return Dia(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ejercicios: ejercicios ?? this.ejercicios,
      progressionType: progressionType ?? this.progressionType,
      weekdays: weekdays ?? this.weekdays,
      minRestHours: minRestHours ?? this.minRestHours,
    );
  }

  /// Serializes the day to a JSON-compatible map for export.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'progressionType': progressionType,
      'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
      if (weekdays != null) 'weekdays': weekdays,
      if (minRestHours != null) 'minRestHours': minRestHours,
    };
  }

  /// Creates a Dia from a JSON map (for import).
  /// Note: IDs will be regenerated with new UUIDs for imported routines.
  factory Dia.fromJson(
    Map<String, dynamic> json, {
    String? newId,
    Map<String, String>? supersetIdMap,
  }) {
    const uuid = Uuid();
    supersetIdMap ??= {};

    // Parse exercises with new instance IDs and mapped superset IDs
    final ejercicios = <EjercicioEnRutina>[];
    final rawEjercicios = json['ejercicios'] as List<dynamic>? ?? [];

    for (final exJson in rawEjercicios) {
      final exMap = exJson as Map<String, dynamic>;
      final oldSupersetId = exMap['supersetId'] as String?;
      String? newSupersetId;

      // Map old superset IDs to new ones
      if (oldSupersetId != null) {
        if (supersetIdMap.containsKey(oldSupersetId)) {
          newSupersetId = supersetIdMap[oldSupersetId];
        } else {
          newSupersetId = uuid.v4();
          supersetIdMap[oldSupersetId] = newSupersetId;
        }
      }

      ejercicios.add(
        EjercicioEnRutina.fromJson(
          exMap,
          newInstanceId: uuid.v4(),
          newSupersetId: newSupersetId,
        ),
      );
    }

    // Parse scheduling fields (v3)
    final weekdaysJson = json['weekdays'] as List<dynamic>?;
    final weekdays = weekdaysJson?.cast<int>();
    final minRestHours = json['minRestHours'] as int?;

    return Dia(
      id: newId ?? uuid.v4(),
      nombre: json['nombre'] as String? ?? 'Día',
      progressionType: json['progressionType'] as String? ?? 'none',
      ejercicios: ejercicios,
      weekdays: weekdays,
      minRestHours: minRestHours,
    );
  }
}
