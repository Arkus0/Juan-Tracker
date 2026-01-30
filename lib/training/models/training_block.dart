import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Tipo de bloque de entrenamiento según periodización clásica
enum BlockType {
  /// Fase de acumulación de volumen (hipertrofia)
  accumulation('accumulation', 'Acumulación', Icons.trending_up),

  /// Fase de intensificación (fuerza)
  intensification('intensification', 'Intensificación', Icons.fitness_center),

  /// Fase de peaking (preparación para competición/test)
  peaking('peaking', 'Peaking', Icons.emoji_events),

  /// Fase de descarga/deload
  deload('deload', 'Deload', Icons.battery_charging_full),

  /// Bloque personalizado
  custom('custom', 'Personalizado', Icons.settings);

  final String value;
  final String label;
  final IconData icon;

  const BlockType(this.value, this.label, this.icon);

  /// Convierte un string a BlockType, retorna [custom] si no coincide
  static BlockType fromString(String? value) {
    return values.firstWhere(
      (v) => v.value == value,
      orElse: () => BlockType.custom,
    );
  }
}

/// Configuración de progresión para un bloque
class BlockProgressionConfig {
  /// Incremento de peso por semana en kg (opcional)
  final double? weeklyWeightIncrement;

  /// RPE objetivo promedio
  final double? targetRpe;

  /// Volumen objetivo (sets por semana por grupo muscular)
  /// Key: nombre del grupo muscular (ej: "pecho", "espalda")
  /// Value: número de sets semanales objetivo
  final Map<String, int>? targetVolume;

  const BlockProgressionConfig({
    this.weeklyWeightIncrement,
    this.targetRpe,
    this.targetVolume,
  });

  /// Crea una copia con modificaciones
  BlockProgressionConfig copyWith({
    double? weeklyWeightIncrement,
    double? targetRpe,
    Map<String, int>? targetVolume,
  }) {
    return BlockProgressionConfig(
      weeklyWeightIncrement: weeklyWeightIncrement ?? this.weeklyWeightIncrement,
      targetRpe: targetRpe ?? this.targetRpe,
      targetVolume: targetVolume ?? this.targetVolume,
    );
  }

  /// Serializa a JSON
  Map<String, dynamic> toJson() {
    return {
      if (weeklyWeightIncrement != null)
        'weeklyWeightIncrement': weeklyWeightIncrement,
      if (targetRpe != null) 'targetRpe': targetRpe,
      if (targetVolume != null) 'targetVolume': targetVolume,
    };
  }

  /// Crea desde JSON
  factory BlockProgressionConfig.fromJson(Map<String, dynamic> json) {
    return BlockProgressionConfig(
      weeklyWeightIncrement: json['weeklyWeightIncrement'] as double?,
      targetRpe: json['targetRpe'] as double?,
      targetVolume: json['targetVolume'] != null
          ? Map<String, int>.from(json['targetVolume'] as Map)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockProgressionConfig &&
          runtimeType == other.runtimeType &&
          weeklyWeightIncrement == other.weeklyWeightIncrement &&
          targetRpe == other.targetRpe &&
          targetVolume == other.targetVolume;

  @override
  int get hashCode =>
      weeklyWeightIncrement.hashCode ^ targetRpe.hashCode ^ targetVolume.hashCode;
}

/// Representa un bloque de entrenamiento (mesociclo)
class TrainingBlock {
  /// ID único del bloque
  final String id;

  /// Nombre descriptivo del bloque (ej: "Bloque de Fuerza 1")
  String name;

  /// Tipo de bloque según periodización
  BlockType type;

  /// Fecha de inicio del bloque
  DateTime startDate;

  /// Fecha de fin del bloque
  DateTime endDate;

  /// Notas adicionales sobre el bloque
  String? notes;

  /// Objetivos del bloque (ej: "Aumentar 5kg en banca", "Mejorar técnica")
  List<String> goals;

  /// Configuración de progresión específica del bloque
  BlockProgressionConfig? progressionConfig;

  TrainingBlock({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.notes,
    this.goals = const [],
    this.progressionConfig,
  });

  /// Crea un nuevo bloque con ID generado automáticamente
  factory TrainingBlock.create({
    required String name,
    required BlockType type,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    List<String> goals = const [],
    BlockProgressionConfig? progressionConfig,
  }) {
    const uuid = Uuid();
    return TrainingBlock(
      id: uuid.v4(),
      name: name,
      type: type,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
      goals: goals,
      progressionConfig: progressionConfig,
    );
  }

  /// Duración del bloque en semanas (redondeada hacia abajo)
  int get durationWeeks => endDate.difference(startDate).inDays ~/ 7;

  /// Semana actual (1-based) si el bloque está activo, null en otro caso
  int? get currentWeek {
    final now = DateTime.now();
    if (now.isBefore(startDate) || now.isAfter(endDate)) return null;
    return now.difference(startDate).inDays ~/ 7 + 1;
  }

  /// Verifica si el bloque está activo actualmente
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Verifica si el bloque ya ha sido completado
  bool get isCompleted => DateTime.now().isAfter(endDate);

  /// Verifica si el bloque aún no ha comenzado
  bool get isPending => DateTime.now().isBefore(startDate);

  /// Progreso del bloque como valor entre 0.0 y 1.0
  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;
    final total = endDate.difference(startDate).inDays;
    final elapsed = now.difference(startDate).inDays;
    return elapsed / total;
  }

  /// Porcentaje de progreso formateado (ej: "45%")
  String get progressPercentage => '${(progress * 100).round()}%';

  /// Crea una copia del bloque con modificaciones
  TrainingBlock copyWith({
    String? id,
    String? name,
    BlockType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    List<String>? goals,
    BlockProgressionConfig? progressionConfig,
  }) {
    return TrainingBlock(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      goals: goals ?? this.goals,
      progressionConfig: progressionConfig ?? this.progressionConfig,
    );
  }

  /// Serializa el bloque a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      'goals': goals,
      if (progressionConfig != null)
        'progressionConfig': progressionConfig!.toJson(),
    };
  }

  /// Crea un bloque desde JSON
  factory TrainingBlock.fromJson(Map<String, dynamic> json) {
    return TrainingBlock(
      id: json['id'] as String,
      name: json['name'] as String,
      type: BlockType.fromString(json['type'] as String?),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      notes: json['notes'] as String?,
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      progressionConfig: json['progressionConfig'] != null
          ? BlockProgressionConfig.fromJson(
              json['progressionConfig'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toString() {
    return 'TrainingBlock{id: $id, name: $name, type: ${type.label}, '
        'weeks: $durationWeeks, active: $isActive}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingBlock &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Extensiones útiles para trabajar con listas de bloques
extension TrainingBlockListExtensions on List<TrainingBlock> {
  /// Retorna el bloque activo actualmente, o null si no hay ninguno
  TrainingBlock? get activeBlock {
    final now = DateTime.now();
    try {
      return firstWhere(
        (b) =>
            now.isAfter(b.startDate.subtract(const Duration(days: 1))) &&
            now.isBefore(b.endDate.add(const Duration(days: 1))),
      );
    } catch (_) {
      return null;
    }
  }

  /// Retorna todos los bloques pendientes (que aún no inician)
  List<TrainingBlock> get pendingBlocks =>
      where((b) => b.isPending).toList();

  /// Retorna todos los bloques completados
  List<TrainingBlock> get completedBlocks =>
      where((b) => b.isCompleted).toList();

  /// Ordena los bloques por fecha de inicio
  List<TrainingBlock> sortedByStartDate() {
    final copy = List<TrainingBlock>.from(this);
    copy.sort((a, b) => a.startDate.compareTo(b.startDate));
    return copy;
  }

  /// Verifica si hay bloques solapados en el tiempo
  bool get hasOverlappingBlocks {
    final sorted = sortedByStartDate();
    for (var i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].endDate.isAfter(sorted[i + 1].startDate)) {
        return true;
      }
    }
    return false;
  }
}
