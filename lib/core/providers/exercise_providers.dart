import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/training_exercise.dart';
import 'database_provider.dart';

// Search helpers from training feature
import 'package:juan_tracker/training/features/exercises/search/exercise_aliases.dart';
import 'package:juan_tracker/training/features/exercises/search/exercise_search_engine.dart' show normalize, tokenize;

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
  final rawQuery = ref.watch(exerciseSearchQueryProvider).trim();
  final queryNorm = normalize(rawQuery);
  final muscle = ref.watch(exerciseFilterMuscleProvider);
  final equipment = ref.watch(exerciseFilterEquipmentProvider);

  bool passesFilters(TrainingExercise e) {
    if (muscle != null && muscle.isNotEmpty && e.grupoMuscular != muscle) {
      return false;
    }
    if (equipment != null && equipment.isNotEmpty && e.equipo != equipment) {
      return false;
    }
    return true;
  }

  if (queryNorm.isEmpty) {
    return exercises.where(passesFilters).toList();
  }

  List<String> expandQuery(String normalized) {
    final expanded = <String>{};
    if (normalized.isEmpty) return [];
    expanded.add(normalized);

    void addAliases(String key) {
      final aliasList = exerciseAliases[key];
      if (aliasList == null) return;
      for (final alias in aliasList) {
        final aliasNorm = normalize(alias);
        if (aliasNorm.isNotEmpty) {
          expanded.addAll(tokenize(aliasNorm));
        }
      }
    }

    addAliases(normalized);
    for (final token in tokenize(normalized)) {
      addAliases(token);
    }

    return expanded.toList();
  }

  int scoreExercise(String term, TrainingExercise e) {
    final name = normalize(e.nombre);
    final muscleGroup = normalize(e.grupoMuscular);
    final equip = normalize(e.equipo);

    if (name == term) return 100;
    if (name.startsWith(term)) return 90;
    if (name.contains(term)) return 75;

    final termTokens = tokenize(term);
    final nameTokens = tokenize(name);
    if (termTokens.isNotEmpty) {
      var matches = 0;
      for (final token in termTokens) {
        if (nameTokens.contains(token)) {
          matches++;
        } else if (nameTokens.any((n) => n.startsWith(token))) {
          matches++;
        }
      }
      if (matches == termTokens.length) return 70;
      if (matches > 0) return 55;
    }

    if (muscleGroup == term) return 60;
    if (muscleGroup.contains(term)) return 45;
    if (equip.contains(term)) return 40;

    return 0;
  }

  final expanded = expandQuery(queryNorm);

  final scored = <MapEntry<TrainingExercise, int>>[];
  for (final e in exercises) {
    if (!passesFilters(e)) continue;
    var best = 0;
    for (final term in expanded) {
      final s = scoreExercise(term, e);
      if (s > best) best = s;
    }
    if (best > 0) {
      scored.add(MapEntry(e, best));
    }
  }

  scored.sort((a, b) {
    final sc = b.value.compareTo(a.value);
    if (sc != 0) return sc;
    return a.key.nombre.toLowerCase().compareTo(b.key.nombre.toLowerCase());
  });

  return scored.map((e) => e.key).toList();
});
