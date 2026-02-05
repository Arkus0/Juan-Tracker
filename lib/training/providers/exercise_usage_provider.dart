import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/library_exercise.dart';
import 'exercise_search_providers.dart';

export 'exercise_search_providers.dart' show exercisesProvider;

/// Provider que retorna los ejercicios más usados recientemente.
///
/// Mantiene un historial de los últimos 20 ejercicios seleccionados.
final recentExercisesProvider = FutureProvider<List<int>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final recentIds = prefs.getStringList('recent_exercise_ids') ?? [];
  return recentIds.map(int.parse).toList();
});

/// Provider que retorna los ejercicios más usados en rutinas.
///
/// Basado en frecuencia de uso histórico.
final popularExercisesProvider = FutureProvider<List<PopularExercise>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final usageData = prefs.getStringList('exercise_usage_count') ?? [];
  
  final List<PopularExercise> popular = [];
  for (final entry in usageData) {
    final parts = entry.split(':');
    if (parts.length == 2) {
      popular.add(PopularExercise(
        exerciseId: int.parse(parts[0]),
        useCount: int.parse(parts[1]),
      ));
    }
  }
  
  // Ordenar por uso
  popular.sort((a, b) => b.useCount.compareTo(a.useCount));
  return popular.take(10).toList();
});

/// Provider que combina recientes + populares con los ejercicios completos
final smartExerciseSectionsProvider = Provider<AsyncValue<ExerciseSections>>((ref) {
  final allExercisesAsync = ref.watch(exercisesProvider);
  final recentIdsAsync = ref.watch(recentExercisesProvider);
  final popularAsync = ref.watch(popularExercisesProvider);
  
  // Usar when para combinar los tres estados
  return allExercisesAsync.when(
    data: (allExercises) {
      return recentIdsAsync.when(
        data: (recentIds) {
          return popularAsync.when(
            data: (popularList) {
              // Mapear IDs a ejercicios completos
              final recentExercises = recentIds
                  .map((id) => allExercises.where((e) => e.id == id).firstOrNull)
                  .where((e) => e != null)
                  .cast<LibraryExercise>()
                  .take(5)
                  .toList();
              
              final popularExercises = popularList
                  .map((p) => allExercises.where((e) => e.id == p.exerciseId).firstOrNull)
                  .where((e) => e != null)
                  .cast<LibraryExercise>()
                  .take(5)
                  .toList();
              
              return AsyncValue.data(ExerciseSections(
                recent: recentExercises,
                popular: popularExercises,
              ));
            },
            loading: () => const AsyncValue.loading(),
            error: (e, s) => AsyncValue.error(e, s),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

/// Notifier para registrar uso de ejercicios
class ExerciseUsageNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Registra que un ejercicio fue usado.
  Future<void> recordUsage(int exerciseId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Actualizar recientes
    final recentIds = prefs.getStringList('recent_exercise_ids') ?? [];
    final recentList = recentIds.map(int.parse).toList();
    
    // Mover al principio o añadir
    recentList.remove(exerciseId);
    recentList.insert(0, exerciseId);
    
    // Mantener solo los últimos 20
    while (recentList.length > 20) {
      recentList.removeLast();
    }
    
    await prefs.setStringList(
      'recent_exercise_ids',
      recentList.map((id) => id.toString()).toList(),
    );
    
    // Actualizar contador de uso
    final usageData = prefs.getStringList('exercise_usage_count') ?? [];
    final usageMap = <String, int>{};
    
    for (final entry in usageData) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        usageMap[parts[0]] = int.parse(parts[1]);
      }
    }
    
    // Incrementar contador
    final currentCount = usageMap[exerciseId.toString()] ?? 0;
    usageMap[exerciseId.toString()] = currentCount + 1;
    
    // Guardar (mantener solo top 50)
    final sortedEntries = usageMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topEntries = sortedEntries.take(50).map(
      (e) => '${e.key}:${e.value}',
    ).toList();
    
    await prefs.setStringList('exercise_usage_count', topEntries);
  }
}

final exerciseUsageProvider = NotifierProvider<ExerciseUsageNotifier, void>(
  ExerciseUsageNotifier.new,
);

/// Modelos auxiliares
class PopularExercise {
  final int exerciseId;
  final int useCount;

  PopularExercise({required this.exerciseId, required this.useCount});
}

class ExerciseSections {
  final List<LibraryExercise> recent;
  final List<LibraryExercise> popular;

  ExerciseSections({
    required this.recent,
    required this.popular,
  });

  bool get hasRecent => recent.isNotEmpty;
  bool get hasPopular => popular.isNotEmpty;
}
