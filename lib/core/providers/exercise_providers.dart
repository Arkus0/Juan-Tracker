import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/training_exercise.dart';
import 'database_provider.dart';

final exerciseLibraryProvider = StreamProvider<List<TrainingExercise>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchAll();
});

class ExerciseSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;

  void clear() => state = '';
}

class ExerciseFilterMuscle extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? value) => state = value;

  void clear() => state = null;
}

class ExerciseFilterEquipment extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? value) => state = value;

  void clear() => state = null;
}

final exerciseSearchQueryProvider =
    NotifierProvider<ExerciseSearchQuery, String>(ExerciseSearchQuery.new);
final exerciseFilterMuscleProvider =
    NotifierProvider<ExerciseFilterMuscle, String?>(ExerciseFilterMuscle.new);
final exerciseFilterEquipmentProvider =
    NotifierProvider<ExerciseFilterEquipment, String?>(
      ExerciseFilterEquipment.new,
    );

final exerciseMuscleOptionsProvider = Provider<List<String>>((ref) {
  final exercises = ref.watch(filteredExercisesSourceProvider);
  final set = <String>{};
  for (final e in exercises) {
    if (e.grupoMuscular.isNotEmpty) set.add(e.grupoMuscular);
  }
  final list = set.toList()..sort();
  return list;
});

final exerciseEquipmentOptionsProvider = Provider<List<String>>((ref) {
  final exercises = ref.watch(filteredExercisesSourceProvider);
  final set = <String>{};
  for (final e in exercises) {
    if (e.equipo.isNotEmpty) set.add(e.equipo);
  }
  final list = set.toList()..sort();
  return list;
});

final filteredExercisesSourceProvider = Provider<List<TrainingExercise>>((ref) {
  final asyncExercises = ref.watch(exerciseLibraryProvider);
  return asyncExercises.maybeWhen(data: (items) => items, orElse: () => []);
});

final filteredExercisesProvider = Provider<List<TrainingExercise>>((ref) {
  final exercises = ref.watch(filteredExercisesSourceProvider);
  final query = ref.watch(exerciseSearchQueryProvider).trim().toLowerCase();
  final muscle = ref.watch(exerciseFilterMuscleProvider);
  final equipment = ref.watch(exerciseFilterEquipmentProvider);

  return exercises.where((e) {
    if (muscle != null && muscle.isNotEmpty && e.grupoMuscular != muscle) {
      return false;
    }
    if (equipment != null && equipment.isNotEmpty && e.equipo != equipment) {
      return false;
    }
    if (query.isEmpty) return true;
    final hay = '${e.nombre} ${e.grupoMuscular} ${e.equipo}'.toLowerCase();
    return hay.contains(query);
  }).toList();
});
