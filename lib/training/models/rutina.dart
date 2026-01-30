import 'package:uuid/uuid.dart';
import 'dia.dart';
import 'training_block.dart';

class Rutina {
  final String id;
  String nombre;
  List<Dia> dias;
  final DateTime creada;

  /// Modo Pro activado (periodización por bloques)
  final bool isProMode;

  /// Lista de bloques de entrenamiento (solo si [isProMode] = true)
  final List<TrainingBlock> blocks;

  /// Bloque activo actualmente (null si no hay bloque activo o modo Pro desactivado)
  TrainingBlock? get activeBlock => isProMode ? blocks.activeBlock : null;

  /// Verifica si hay un bloque activo actualmente en modo Pro
  bool get hasActiveBlock => activeBlock != null;

  Rutina({
    required this.id,
    required this.nombre,
    required this.dias,
    required this.creada,
    this.isProMode = false,
    this.blocks = const [],
  });

  /// Creates a DEEP copy of this routine including all days and exercises.
  /// This ensures modifications don't affect the original object.
  /// 🎯 FIX CRÍTICO: Usado para evitar que la edición de rutinas guarde cambios
  /// cuando el usuario hace "Back" en lugar de "Guardar".
  Rutina deepCopy() {
    return Rutina(
      id: id,
      nombre: nombre,
      dias: dias.map((d) => Dia.fromJson(d.toJson())).toList(),
      creada: creada,
      isProMode: isProMode,
      blocks: blocks.map((b) => b.copyWith()).toList(),
    );
  }

  Rutina copyWith({
    String? id,
    String? nombre,
    List<Dia>? dias,
    DateTime? creada,
    bool? isProMode,
    List<TrainingBlock>? blocks,
  }) {
    return Rutina(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      dias: dias ?? this.dias,
      creada: creada ?? this.creada,
      isProMode: isProMode ?? this.isProMode,
      blocks: blocks ?? this.blocks,
    );
  }

  /// Serializes the routine to a JSON-compatible map for export.
  Map<String, dynamic> toJson() {
    return {
      'version': 2, // Schema version for future compatibility
      'exportDate': DateTime.now().toIso8601String(),
      'id': id,
      'nombre': nombre,
      'creada': creada.toIso8601String(),
      'dias': dias.map((d) => d.toJson()).toList(),
      'isProMode': isProMode,
      if (isProMode) 'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  /// Creates a Rutina from a JSON map (for import).
  /// Generates new UUIDs for all entities to avoid conflicts.
  factory Rutina.fromJson(Map<String, dynamic> json) {
    const uuid = Uuid();

    // Parse days with new IDs
    final rawDias = json['dias'] as List<dynamic>? ?? [];
    final dias = rawDias.map((d) {
      // Each day parses its exercises with proper superset mapping
      return Dia.fromJson(d as Map<String, dynamic>);
    }).toList();

    // Parse blocks if present (Pro mode)
    final isProMode = json['isProMode'] as bool? ?? false;
    final rawBlocks = json['blocks'] as List<dynamic>? ?? [];
    final blocks = isProMode
        ? rawBlocks
            .map((b) => TrainingBlock.fromJson(b as Map<String, dynamic>))
            .toList()
        : <TrainingBlock>[];

    return Rutina(
      id: uuid.v4(), // Always generate new ID for imports
      nombre: json['nombre'] as String? ?? 'Rutina Importada',
      dias: dias,
      creada: DateTime.now(), // Use current date for imports
      isProMode: isProMode,
      blocks: blocks,
    );
  }

  /// Validates JSON structure before attempting to parse.
  /// Returns null if valid, error message if invalid.
  static String? validateJson(Map<String, dynamic> json) {
    if (json['nombre'] == null || (json['nombre'] as String).trim().isEmpty) {
      return 'La rutina debe tener un nombre';
    }
    if (json['dias'] == null || json['dias'] is! List) {
      return 'La rutina debe tener una lista de días';
    }

    final dias = json['dias'] as List;
    if (dias.isEmpty) {
      return 'La rutina debe tener al menos un día';
    }

    for (var i = 0; i < dias.length; i++) {
      if (dias[i] is! Map) {
        return 'Día ${i + 1} tiene formato inválido';
      }
      final dia = dias[i] as Map;
      if (dia['ejercicios'] != null && dia['ejercicios'] is! List) {
        return 'Los ejercicios del día ${i + 1} tienen formato inválido';
      }
    }

    return null; // Valid
  }
}
