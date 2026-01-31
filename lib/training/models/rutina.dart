import 'package:uuid/uuid.dart';
import 'dia.dart';
import 'training_block.dart';

/// Modos de scheduling disponibles para rutinas
enum SchedulingMode {
  /// Modo secuencial tradicional: Día 1 → Día 2 → Día 3...
  sequential,
  
  /// Modo anclado a días de semana: Lunes=Pecho, Miércoles=Espalda...
  weeklyAnchored,
  
  /// Modo ciclo flotante: basado en horas de descanso entre sesiones
  floatingCycle,
}

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
  
  // 🆕 SCHEMA v9: Configuración de scheduling (solo modo Pro)
  
  /// Modo de scheduling para sugerencias inteligentes
  /// [sequential] (default): Rotación secuencial tradicional
  /// [weeklyAnchored]: Anclado a días específicos de la semana
  /// [floatingCycle]: Basado en tiempo transcurrido desde última sesión
  final SchedulingMode schedulingMode;
  
  /// Configuración adicional del scheduling en formato JSON
  /// Ej: {"minRestHours": 20, "autoAlternate": true, "maxRestHours": 72}
  final Map<String, dynamic>? schedulingConfig;
  
  /// Helper para obtener minRestHours del config o valor por defecto
  int get minRestHours => schedulingConfig?['minRestHours'] ?? 20;
  
  /// Helper para obtener maxRestHours del config o valor por defecto  
  int get maxRestHours => schedulingConfig?['maxRestHours'] ?? 72;
  
  /// Helper para verificar si usa auto-alternancia (para floatingCycle)
  bool get autoAlternate => schedulingConfig?['autoAlternate'] ?? true;

  Rutina({
    required this.id,
    required this.nombre,
    required this.dias,
    required this.creada,
    this.isProMode = false,
    this.blocks = const [],
    this.schedulingMode = SchedulingMode.sequential,
    this.schedulingConfig,
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
      schedulingMode: schedulingMode,
      schedulingConfig: schedulingConfig != null 
          ? Map<String, dynamic>.from(schedulingConfig!) 
          : null,
    );
  }

  Rutina copyWith({
    String? id,
    String? nombre,
    List<Dia>? dias,
    DateTime? creada,
    bool? isProMode,
    List<TrainingBlock>? blocks,
    SchedulingMode? schedulingMode,
    Map<String, dynamic>? schedulingConfig,
  }) {
    return Rutina(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      dias: dias ?? this.dias,
      creada: creada ?? this.creada,
      isProMode: isProMode ?? this.isProMode,
      blocks: blocks ?? this.blocks,
      schedulingMode: schedulingMode ?? this.schedulingMode,
      schedulingConfig: schedulingConfig ?? this.schedulingConfig,
    );
  }

  /// Serializes the routine to a JSON-compatible map for export.
  Map<String, dynamic> toJson() {
    return {
      'version': 3, // Schema version v3: añadido scheduling
      'exportDate': DateTime.now().toIso8601String(),
      'id': id,
      'nombre': nombre,
      'creada': creada.toIso8601String(),
      'dias': dias.map((d) => d.toJson()).toList(),
      'isProMode': isProMode,
      'schedulingMode': schedulingMode.name,
      if (schedulingConfig != null) 'schedulingConfig': schedulingConfig,
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

    // Parse scheduling config (v3)
    final schedulingModeStr = json['schedulingMode'] as String?;
    final schedulingMode = schedulingModeStr != null
        ? SchedulingMode.values.byName(schedulingModeStr)
        : SchedulingMode.sequential;
    final schedulingConfig = json['schedulingConfig'] as Map<String, dynamic>?;

    return Rutina(
      id: uuid.v4(), // Always generate new ID for imports
      nombre: json['nombre'] as String? ?? 'Rutina Importada',
      dias: dias,
      creada: DateTime.now(), // Use current date for imports
      isProMode: isProMode,
      blocks: blocks,
      schedulingMode: schedulingMode,
      schedulingConfig: schedulingConfig,
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
