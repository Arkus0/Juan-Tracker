import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/training/features/exercises/search/exercise_search_engine.dart';
import 'package:juan_tracker/training/models/library_exercise.dart';
import 'package:juan_tracker/training/services/exercise_library_service.dart';
import 'package:juan_tracker/training/services/smart_exercise_search_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO DE BÚSQUEDA
// ═══════════════════════════════════════════════════════════════════════════

/// Estado de los filtros de búsqueda
class SearchFiltersState {
  final String? muscleGroup;
  final String? equipment;
  final bool favoritesOnly;
  final String sortBy; // 'name', 'muscle', 'recent'

  const SearchFiltersState({
    this.muscleGroup,
    this.equipment,
    this.favoritesOnly = false,
    this.sortBy = 'name',
  });

  SearchFiltersState copyWith({
    String? muscleGroup,
    String? equipment,
    bool? favoritesOnly,
    String? sortBy,
    bool clearMuscleGroup = false,
    bool clearEquipment = false,
  }) {
    return SearchFiltersState(
      muscleGroup: clearMuscleGroup ? null : (muscleGroup ?? this.muscleGroup),
      equipment: clearEquipment ? null : (equipment ?? this.equipment),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  SearchFilters toEngineFilters() => SearchFilters(
        muscleGroup: muscleGroup,
        equipment: equipment,
        favoritesOnly: favoritesOnly,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Query actual de búsqueda
final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtros activos de búsqueda
final exerciseSearchFiltersProvider = StateProvider<SearchFiltersState>(
  (ref) => const SearchFiltersState(),
);

/// Todos los ejercicios disponibles
final allExercisesProvider = Provider<List<LibraryExercise>>((ref) {
  return ExerciseLibraryService.instance.exercises;
});

/// Resultados de búsqueda con scoring
final smartExerciseSearchResultsProvider = Provider<List<ScoredExercise>>((ref) {
  final query = ref.watch(exerciseSearchQueryProvider);
  final filters = ref.watch(exerciseSearchFiltersProvider);
  final exercises = ref.watch(allExercisesProvider);

  final service = SmartExerciseSearchService();
  return service.search(
    query,
    exercises,
    filters: filters.toEngineFilters(),
    limit: 100,
  );
});

/// Sugerencias cuando hay pocos o ningún resultado
final exerciseSearchSuggestionsProvider = Provider<List<ScoredExercise>>((ref) {
  final query = ref.watch(exerciseSearchQueryProvider);
  final filters = ref.watch(exerciseSearchFiltersProvider);
  final exercises = ref.watch(allExercisesProvider);
  final results = ref.watch(smartExerciseSearchResultsProvider);

  if (results.isNotEmpty || query.length < 3) return [];

  final service = SmartExerciseSearchService();
  return service.suggestAlternatives(
    query,
    exercises,
    filters: filters.toEngineFilters(),
    limit: 5,
  );
});

/// Sugerencias de autocompletado para el campo de búsqueda
final exerciseAutocompleteProvider = Provider.family<List<String>, String>((ref, partial) {
  final exercises = ref.watch(allExercisesProvider);
  
  if (partial.length < 2) return [];
  
  final service = SmartExerciseSearchService();
  return service.getTextSuggestions(partial, exercises, limit: 5);
});

/// Indica si la búsqueda actual tiene resultados
final hasSearchResultsProvider = Provider<bool>((ref) {
  return ref.watch(smartExerciseSearchResultsProvider).isNotEmpty;
});

/// Grupos musculares disponibles para filtrar
final availableMuscleGroupsProvider = Provider<List<String>>((ref) {
  final exercises = ref.watch(allExercisesProvider);
  final groups = exercises.map((e) => e.muscleGroup).toSet().toList();
  groups.sort();
  return groups;
});

/// Equipamiento disponible para filtrar
final availableEquipmentProvider = Provider<List<String>>((ref) {
  final exercises = ref.watch(allExercisesProvider);
  final equipment = exercises.map((e) => e.equipment).where((e) => e.isNotEmpty).toSet().toList();
  equipment.sort();
  return equipment;
});

/// Historial de búsquedas recientes (persistido en memoria durante la sesión)
final recentSearchesProvider = StateProvider<List<String>>((ref) => []);

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER PARA ACCIONES DE BÚSQUEDA
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier para manejar acciones complejas de búsqueda
class ExerciseSearchActions extends StateNotifier<void> {
  final Ref _ref;

  ExerciseSearchActions(this._ref) : super(null);

  /// Establece la query de búsqueda
  void setQuery(String query) {
    _ref.read(exerciseSearchQueryProvider.notifier).state = query;
    
    // Guardar en historial si es una búsqueda válida
    if (query.length >= 3) {
      _addToHistory(query);
    }
  }

  /// Limpia la búsqueda
  void clearSearch() {
    _ref.read(exerciseSearchQueryProvider.notifier).state = '';
  }

  /// Actualiza filtros
  void setFilters(SearchFiltersState filters) {
    _ref.read(exerciseSearchFiltersProvider.notifier).state = filters;
  }

  /// Establece filtro de grupo muscular
  void setMuscleGroup(String? muscle) {
    final current = _ref.read(exerciseSearchFiltersProvider);
    _ref.read(exerciseSearchFiltersProvider.notifier).state = 
        current.copyWith(muscleGroup: muscle, clearMuscleGroup: muscle == null);
  }

  /// Establece filtro de equipamiento
  void setEquipment(String? equipment) {
    final current = _ref.read(exerciseSearchFiltersProvider);
    _ref.read(exerciseSearchFiltersProvider.notifier).state = 
        current.copyWith(equipment: equipment, clearEquipment: equipment == null);
  }

  /// Toggle favoritos
  void toggleFavorites() {
    final current = _ref.read(exerciseSearchFiltersProvider);
    _ref.read(exerciseSearchFiltersProvider.notifier).state = 
        current.copyWith(favoritesOnly: !current.favoritesOnly);
  }

  /// Limpia todos los filtros
  void clearFilters() {
    _ref.read(exerciseSearchFiltersProvider.notifier).state = const SearchFiltersState();
  }

  void _addToHistory(String query) {
    final history = _ref.read(recentSearchesProvider);
    final normalized = query.toLowerCase().trim();
    
    if (history.any((h) => h.toLowerCase().trim() == normalized)) return;
    
    final newHistory = [query, ...history.take(9)]; // Máximo 10 recientes
    _ref.read(recentSearchesProvider.notifier).state = newHistory;
  }
}

/// Provider para acciones de búsqueda
final exerciseSearchActionsProvider = StateNotifierProvider<ExerciseSearchActions, void>(
  (ref) => ExerciseSearchActions(ref),
);
