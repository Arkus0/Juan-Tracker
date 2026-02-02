import 'package:uuid/uuid.dart';

/// {@template training_program}
/// Modelo de programa de entrenamiento tipo Golden Age/Boostcamp.
/// 
/// Diferencia clave con [Rutina]: un Programa tiene progresión automática
/// y estructura semanal (no solo lista de ejercicios).
/// {@endtemplate}
class TrainingProgram {
  final String id;
  final String name;
  final String description;
  final String author; // "Reg Park (1951)", "Steve Reeves", etc.
  final String era; // "1950s", "1960s", "1970s"
  final ProgramType type;
  final List<ProgramWeek> weeks;
  final ProgressionConfig progression;
  final List<String> tags; // ["strength", "hypertrophy", "beginner"]
  final bool isPublicDomain; // true para Golden Age

  const TrainingProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.author,
    required this.era,
    required this.type,
    required this.weeks,
    required this.progression,
    this.tags = const [],
    this.isPublicDomain = true,
  });

  /// Número total de días de entrenamiento en el programa
  int get totalDays => weeks.fold(0, (sum, w) => sum + w.days.length);

  /// Duración típica en semanas antes de deload o cambio
  int get durationWeeks => weeks.length;

  factory TrainingProgram.fromJson(Map<String, dynamic> json) {
    return TrainingProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      era: json['era'] as String,
      type: ProgramType.values.byName(json['type'] as String),
      weeks: (json['weeks'] as List)
          .map((w) => ProgramWeek.fromJson(w as Map<String, dynamic>))
          .toList(),
      progression:
          ProgressionConfig.fromJson(json['progression'] as Map<String, dynamic>),
      tags: (json['tags'] as List).map((t) => t as String).toList(),
      isPublicDomain: json['isPublicDomain'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'era': era,
      'type': type.name,
      'weeks': weeks.map((w) => w.toJson()).toList(),
      'progression': progression.toJson(),
      'tags': tags,
      'isPublicDomain': isPublicDomain,
    };
  }

  TrainingProgram copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    String? era,
    ProgramType? type,
    List<ProgramWeek>? weeks,
    ProgressionConfig? progression,
    List<String>? tags,
    bool? isPublicDomain,
  }) {
    return TrainingProgram(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      era: era ?? this.era,
      type: type ?? this.type,
      weeks: weeks ?? this.weeks,
      progression: progression ?? this.progression,
      tags: tags ?? this.tags,
      isPublicDomain: isPublicDomain ?? this.isPublicDomain,
    );
  }
}

enum ProgramType {
  linear, // +peso fijo cada sesión (Reg Park)
  doubleProgression, // +reps primero, luego peso (Reeves)
  density, // mismo peso, menos descanso (Gironda 8x8)
  rpeBased, // basado en esfuerzo percibido
}

/// Configuración de progresión automática
class ProgressionConfig {
  final double weightIncrement; // kg a añadir
  final int minReps; // para double progression
  final int maxReps;
  final int setsToProgress; // cuántas series deben cumplir objetivo
  final int deloadAfterWeeks; // semanas antes de deload forzado
  final double deloadPercentage; // % de peso a reducir en deload

  const ProgressionConfig({
    this.weightIncrement = 2.5,
    this.minReps = 8,
    this.maxReps = 12,
    this.setsToProgress = 2,
    this.deloadAfterWeeks = 4,
    this.deloadPercentage = 0.10,
  });

  factory ProgressionConfig.fromJson(Map<String, dynamic> json) {
    return ProgressionConfig(
      weightIncrement: (json['weightIncrement'] as num).toDouble(),
      minReps: json['minReps'] as int,
      maxReps: json['maxReps'] as int,
      setsToProgress: json['setsToProgress'] as int,
      deloadAfterWeeks: json['deloadAfterWeeks'] as int,
      deloadPercentage: (json['deloadPercentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightIncrement': weightIncrement,
      'minReps': minReps,
      'maxReps': maxReps,
      'setsToProgress': setsToProgress,
      'deloadAfterWeeks': deloadAfterWeeks,
      'deloadPercentage': deloadPercentage,
    };
  }
}

/// Semana dentro de un programa (puede ser repetible)
class ProgramWeek {
  final int weekNumber;
  final String? name; // "Week 1 - Acumulación", "Deload", etc.
  final List<ProgramDay> days;

  const ProgramWeek({
    required this.weekNumber,
    this.name,
    required this.days,
  });

  factory ProgramWeek.fromJson(Map<String, dynamic> json) {
    return ProgramWeek(
      weekNumber: json['weekNumber'] as int,
      name: json['name'] as String?,
      days: (json['days'] as List)
          .map((d) => ProgramDay.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'name': name,
      'days': days.map((d) => d.toJson()).toList(),
    };
  }
}

/// Día de entrenamiento dentro de una semana
class ProgramDay {
  final int dayNumber; // 1, 2, 3...
  final String name; // "A", "Push", "Lunes", etc.
  final String focus; // "Pecho y brazos", "Full body"
  final List<ProgramExercise> exercises;

  const ProgramDay({
    required this.dayNumber,
    required this.name,
    required this.focus,
    required this.exercises,
  });

  factory ProgramDay.fromJson(Map<String, dynamic> json) {
    return ProgramDay(
      dayNumber: json['dayNumber'] as int,
      name: json['name'] as String,
      focus: json['focus'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => ProgramExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'name': name,
      'focus': focus,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

/// Ejercicio dentro de un día de programa
class ProgramExercise {
  final String exerciseId; // Referencia a LibraryExercise
  final String exerciseName; // Snapshot por si cambia la biblioteca
  final int sets;
  final int minReps;
  final int maxReps;
  final double? startWeightPercent; // % de 1RM estimado (opcional)
  final String? notes; // "Descanso 3min", "Último set AMRAP", etc.

  const ProgramExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.minReps,
    required this.maxReps,
    this.startWeightPercent,
    this.notes,
  });

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    return ProgramExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: json['sets'] as int,
      minReps: json['minReps'] as int,
      maxReps: json['maxReps'] as int,
      startWeightPercent: json['startWeightPercent'] != null
          ? (json['startWeightPercent'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets,
      'minReps': minReps,
      'maxReps': maxReps,
      'startWeightPercent': startWeightPercent,
      'notes': notes,
    };
  }

  /// Crea un ejercicio de programa desde la biblioteca actual
  factory ProgramExercise.fromLibrary({
    required int libraryId,
    required String name,
    required int sets,
    required int targetReps,
    String? notes,
  }) {
    return ProgramExercise(
      exerciseId: libraryId.toString(),
      exerciseName: name,
      sets: sets,
      minReps: targetReps,
      maxReps: targetReps,
      notes: notes,
    );
  }
}

/// Estado de instancia de programa activo por usuario
class ActiveProgramInstance {
  final String id;
  final String programId;
  final String programName;
  final int currentWeek;
  final int currentDay;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, double> exerciseWeights; // exerciseId -> peso actual
  final bool isDeloadWeek;

  const ActiveProgramInstance({
    required this.id,
    required this.programId,
    required this.programName,
    this.currentWeek = 1,
    this.currentDay = 1,
    required this.startedAt,
    this.completedAt,
    this.exerciseWeights = const {},
    this.isDeloadWeek = false,
  });

  factory ActiveProgramInstance.start({
    required String programId,
    required String programName,
    Map<String, double>? initialWeights,
  }) {
    return ActiveProgramInstance(
      id: const Uuid().v4(),
      programId: programId,
      programName: programName,
      startedAt: DateTime.now(),
      exerciseWeights: initialWeights ?? {},
    );
  }

  ActiveProgramInstance advanceDay({int totalDaysInWeek = 3}) {
    var nextDay = currentDay + 1;
    var nextWeek = currentWeek;
    var isDeload = isDeloadWeek;

    if (nextDay > totalDaysInWeek) {
      nextDay = 1;
      nextWeek = currentWeek + 1;
      // Lógica de deload podría ir aquí
    }

    return copyWith(
      currentWeek: nextWeek,
      currentDay: nextDay,
      isDeloadWeek: isDeload,
    );
  }

  ActiveProgramInstance updateWeight(String exerciseId, double weight) {
    final newWeights = Map<String, double>.from(exerciseWeights);
    newWeights[exerciseId] = weight;
    return copyWith(exerciseWeights: newWeights);
  }

  ActiveProgramInstance copyWith({
    String? id,
    String? programId,
    String? programName,
    int? currentWeek,
    int? currentDay,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, double>? exerciseWeights,
    bool? isDeloadWeek,
  }) {
    return ActiveProgramInstance(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      currentWeek: currentWeek ?? this.currentWeek,
      currentDay: currentDay ?? this.currentDay,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      exerciseWeights: exerciseWeights ?? this.exerciseWeights,
      isDeloadWeek: isDeloadWeek ?? this.isDeloadWeek,
    );
  }
}
