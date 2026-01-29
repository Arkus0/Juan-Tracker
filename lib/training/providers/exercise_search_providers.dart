import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/exercises/search/exercise_aliases.dart';
import '../features/exercises/search/exercise_search_engine.dart';
import '../models/library_exercise.dart';
import '../services/exercise_library_service.dart';

final exerciseSearchEngineProvider = Provider<ExerciseSearchEngine>((ref) {
  return const ExerciseSearchEngine();
});

final exercisesProvider = StreamProvider<List<LibraryExercise>>((ref) {
  final controller = StreamController<List<LibraryExercise>>.broadcast();
  final notifier = ExerciseLibraryService.instance.exercisesNotifier;

  void listener() {
    controller.add(List<LibraryExercise>.from(notifier.value));
  }

  notifier.addListener(listener);
  controller.add(List<LibraryExercise>.from(notifier.value));

  ref.onDispose(() {
    notifier.removeListener(listener);
    controller.close();
  });

  return controller.stream;
});

final exerciseSearchIndexProvider = Provider.autoDispose<ExerciseSearchIndex>((
  ref,
) {
  ref.keepAlive();
  final exercises =
      ref.watch(exercisesProvider).value ?? const <LibraryExercise>[];
  return ExerciseSearchIndex.build(exercises);
});

final exerciseSearchQueryProvider =
    NotifierProvider<ExerciseSearchQueryNotifier, String>(
      ExerciseSearchQueryNotifier.new,
    );

class ExerciseSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}
class ExerciseSearchFiltersState {
  final String? muscleGroup;
  final String? equipment;
  final bool favoritesOnly;

  const ExerciseSearchFiltersState({
    this.muscleGroup,
    this.equipment,
    this.favoritesOnly = false,
  });

  ExerciseSearchFiltersState copyWith({
    String? muscleGroup,
    String? equipment,
    bool? favoritesOnly,
  }) {
    return ExerciseSearchFiltersState(
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }
}

class ExerciseSearchFiltersNotifier
    extends Notifier<ExerciseSearchFiltersState> {
  @override
  ExerciseSearchFiltersState build() => const ExerciseSearchFiltersState();

  void setMuscleGroup(String? value) {
    state = state.copyWith(muscleGroup: value);
  }

  void setEquipment(String? value) {
    state = state.copyWith(equipment: value);
  }

  void setFavoritesOnly(bool value) {
    state = state.copyWith(favoritesOnly: value);
  }

  void clear() {
    state = const ExerciseSearchFiltersState();
  }
}

final exerciseSearchFiltersProvider =
    NotifierProvider<ExerciseSearchFiltersNotifier, ExerciseSearchFiltersState>(
      ExerciseSearchFiltersNotifier.new,
    );

final availableMuscleGroupsProvider = Provider<List<String>>((ref) {
  final exercises =
      ref.watch(exercisesProvider).value ?? const <LibraryExercise>[];
  final groups = exercises.map((e) => e.muscleGroup).toSet().toList();
  groups.sort();
  return groups;
});

final availableEquipmentProvider = Provider<List<String>>((ref) {
  final exercises =
      ref.watch(exercisesProvider).value ?? const <LibraryExercise>[];
  final equipment = exercises.map((e) => e.equipment).toSet().toList();
  equipment.sort();
  return equipment;
});

final exerciseSearchResultsProvider =
    FutureProvider.autoDispose<List<LibraryExercise>>((ref) async {
      final query = ref.watch(exerciseSearchQueryProvider);
      final filtersState = ref.watch(exerciseSearchFiltersProvider);
      final index = ref.watch(exerciseSearchIndexProvider);

      var cancelled = false;
      ref.onDispose(() {
        cancelled = true;
      });

      await Future.delayed(const Duration(milliseconds: 200));
      if (cancelled) return const <LibraryExercise>[];

      final normalizedQuery = normalize(query);
      final limit = normalizedQuery.isEmpty ? index.totalCount : 200;

      bool passesFilters(LibraryExercise exercise) {
        return _passesFilters(filtersState, exercise);
      }

      final base = index.sortedExercises;
      if (normalizedQuery.isEmpty) {
        return base.where(passesFilters).take(limit).toList();
      }

      final expandedQueries = _expandQuery(normalizedQuery);
      final scored = <_ScoredExercise>[];
      for (final exercise in base) {
        if (!passesFilters(exercise)) continue;
        var bestScore = 0;
        for (final term in expandedQueries) {
          final score = _scoreExercise(term, exercise);
          if (score > bestScore) {
            bestScore = score;
          }
        }
        if (bestScore > 0) {
          scored.add(_ScoredExercise(exercise, bestScore));
        }
      }

      scored.sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return a.exercise.name.toLowerCase().compareTo(
          b.exercise.name.toLowerCase(),
        );
      });

      return scored.take(limit).map((e) => e.exercise).toList();
    });

final exerciseSearchSuggestionsProvider =
    FutureProvider.autoDispose<List<LibraryExercise>>((ref) async {
      final query = ref.watch(exerciseSearchQueryProvider);
      if (query.trim().isEmpty) return const <LibraryExercise>[];

      final results = await ref.watch(exerciseSearchResultsProvider.future);
      if (results.isNotEmpty) return const <LibraryExercise>[];

      final filtersState = ref.watch(exerciseSearchFiltersProvider);
      final index = ref.watch(exerciseSearchIndexProvider);
      final normalizedQuery = normalize(query);
      final expandedQueries = _expandQuery(
        normalizedQuery,
        includeOriginal: false,
      );
      if (expandedQueries.isEmpty) return const <LibraryExercise>[];

      final suggestions = <LibraryExercise>[];
      for (final exercise in index.sortedExercises) {
        if (!_passesFilters(filtersState, exercise)) continue;
        final name = normalize(exercise.name);
        if (expandedQueries.any(name.contains)) {
          suggestions.add(exercise);
        }
      }

      return suggestions.take(3).toList();
    });

class _ScoredExercise {
  final LibraryExercise exercise;
  final int score;

  const _ScoredExercise(this.exercise, this.score);
}

bool _passesFilters(
  ExerciseSearchFiltersState filtersState,
  LibraryExercise exercise,
) {
  if (filtersState.favoritesOnly && !exercise.isFavorite) {
    return false;
  }
  if (filtersState.muscleGroup != null &&
      filtersState.muscleGroup!.isNotEmpty) {
    final target = normalize(filtersState.muscleGroup!);
    if (normalize(exercise.muscleGroup) != target) return false;
  }
  if (filtersState.equipment != null && filtersState.equipment!.isNotEmpty) {
    final target = normalize(filtersState.equipment!);
    if (normalize(exercise.equipment) != target) return false;
  }
  return true;
}

List<String> _expandQuery(
  String normalizedQuery, {
  bool includeOriginal = true,
}) {
  if (normalizedQuery.isEmpty) return const [];
  final expanded = <String>{};
  if (includeOriginal) {
    expanded.add(normalizedQuery);
  }

  void addAliases(String key) {
    final aliasList = exerciseAliases[key];
    if (aliasList == null) return;
    for (final alias in aliasList) {
      final aliasNorm = normalize(alias);
      if (aliasNorm.isNotEmpty) {
        expanded.add(aliasNorm);
      }
    }
  }

  addAliases(normalizedQuery);
  for (final token in tokenize(normalizedQuery)) {
    addAliases(token);
  }

  return expanded.toList();
}

int _scoreExercise(String term, LibraryExercise exercise) {
  if (term.isEmpty) return 0;

  final name = normalize(exercise.name);
  final muscleGroup = normalize(exercise.muscleGroup);
  final equipment = normalize(exercise.equipment);

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
  if (equipment.contains(term)) return 40;

  for (final muscle in exercise.muscles) {
    if (normalize(muscle).contains(term)) return 42;
  }
  for (final muscle in exercise.secondaryMuscles) {
    if (normalize(muscle).contains(term)) return 38;
  }

  return 0;
}
