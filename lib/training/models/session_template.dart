import 'package:uuid/uuid.dart';

class SessionTemplate {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<SessionTemplateExercise> exercises;

  SessionTemplate({
    String? id,
    required this.name,
    required this.createdAt,
    required this.exercises,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory SessionTemplate.fromJson(Map<String, dynamic> json) {
    return SessionTemplate(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Plantilla',
      createdAt: DateTime.parse(json['createdAt'] as String),
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map(
            (e) => SessionTemplateExercise.fromJson(
              (e as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class SessionTemplateExercise {
  final String libraryId;
  final String name;
  final List<String> musclesPrimary;
  final List<String> musclesSecondary;
  final int? suggestedRestSeconds;
  final List<SessionTemplateSet> sets;

  const SessionTemplateExercise({
    required this.libraryId,
    required this.name,
    this.musclesPrimary = const [],
    this.musclesSecondary = const [],
    this.suggestedRestSeconds,
    this.sets = const [],
  });

  Map<String, dynamic> toJson() => {
    'libraryId': libraryId,
    'name': name,
    'musclesPrimary': musclesPrimary,
    'musclesSecondary': musclesSecondary,
    'suggestedRestSeconds': suggestedRestSeconds,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  factory SessionTemplateExercise.fromJson(Map<String, dynamic> json) {
    return SessionTemplateExercise(
      libraryId: json['libraryId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      musclesPrimary:
          (json['musclesPrimary'] as List<dynamic>? ?? []).cast<String>(),
      musclesSecondary:
          (json['musclesSecondary'] as List<dynamic>? ?? []).cast<String>(),
      suggestedRestSeconds: json['suggestedRestSeconds'] as int?,
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map(
            (e) => SessionTemplateSet.fromJson(
              (e as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
    );
  }
}

class SessionTemplateSet {
  final double weight;
  final int reps;
  final bool isWarmup;
  final bool isFailure;
  final bool isDropset;
  final bool isRestPause;
  final bool isMyoReps;
  final bool isAmrap;

  const SessionTemplateSet({
    required this.weight,
    required this.reps,
    this.isWarmup = false,
    this.isFailure = false,
    this.isDropset = false,
    this.isRestPause = false,
    this.isMyoReps = false,
    this.isAmrap = false,
  });

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'reps': reps,
    'isWarmup': isWarmup,
    'isFailure': isFailure,
    'isDropset': isDropset,
    'isRestPause': isRestPause,
    'isMyoReps': isMyoReps,
    'isAmrap': isAmrap,
  };

  factory SessionTemplateSet.fromJson(Map<String, dynamic> json) {
    return SessionTemplateSet(
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      reps: json['reps'] as int? ?? 0,
      isWarmup: json['isWarmup'] as bool? ?? false,
      isFailure: json['isFailure'] as bool? ?? false,
      isDropset: json['isDropset'] as bool? ?? false,
      isRestPause: json['isRestPause'] as bool? ?? false,
      isMyoReps: json['isMyoReps'] as bool? ?? false,
      isAmrap: json['isAmrap'] as bool? ?? false,
    );
  }
}
