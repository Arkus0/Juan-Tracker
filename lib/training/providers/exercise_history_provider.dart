import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_models.dart';
import '../models/sesion.dart';
import '../repositories/i_training_repository.dart';
import 'training_provider.dart';

/// {@template exercise_history_provider}
/// Provider cacheado para el historial expandido de ejercicios.
/// 
/// Evita N+1 queries cuando el usuario navega rápidamente entre
/// ejercicios en la vista de sesión de entrenamiento.
/// 
/// El cache tiene TTL de 5 minutos por ejercicio.
/// {@endtemplate}

/// Provider del repositorio de entrenamiento (ya existe en training_provider)
final _trainingRepoProvider = Provider<ITrainingRepository>((ref) {
  return ref.watch(trainingRepositoryProvider);
});

/// Cache de historial con TTL
class ExerciseHistoryCache {
  final Map<String, _CachedHistory> _cache = {};
  static const Duration _ttl = Duration(minutes: 5);

  /// Obtiene historial cacheado o null si expiró/no existe
  List<Sesion>? get(String exerciseName) {
    final cached = _cache[exerciseName];
    if (cached == null) return null;
    
    if (DateTime.now().difference(cached.timestamp) > _ttl) {
      _cache.remove(exerciseName);
      return null;
    }
    
    return cached.sessions;
  }

  /// Guarda historial en cache
  void set(String exerciseName, List<Sesion> sessions) {
    _cache[exerciseName] = _CachedHistory(
      sessions: sessions,
      timestamp: DateTime.now(),
    );
  }

  /// Invalida cache para un ejercicio específico
  void invalidate(String exerciseName) {
    _cache.remove(exerciseName);
  }

  /// Limpia todo el cache
  void clear() => _cache.clear();
}

class _CachedHistory {
  final List<Sesion> sessions;
  final DateTime timestamp;

  _CachedHistory({
    required this.sessions,
    required this.timestamp,
  });
}

/// Provider del cache (singleton)
final exerciseHistoryCacheProvider = Provider<ExerciseHistoryCache>(
  (ref) => ExerciseHistoryCache(),
);

/// Provider del historial expandido para un ejercicio específico.
/// 
/// Usa cache con TTL de 5 minutos para evitar queries repetidas.
final exerciseHistoryProvider = FutureProvider.family<List<Sesion>, String>(
  (ref, exerciseName) async {
    // Verificar cache primero
    final cache = ref.read(exerciseHistoryCacheProvider);
    final cached = cache.get(exerciseName);
    
    if (cached != null) {
      return cached;
    }
    
    // Fetch desde repositorio
    final repo = ref.read(_trainingRepoProvider);
    final sessions = await repo.getExpandedHistoryForExercise(
      exerciseName,
      limit: 5,
    );
    
    // Guardar en cache
    cache.set(exerciseName, sessions);
    
    return sessions;
  },
);

/// Provider de tendencia de fuerza para un ejercicio especÃ­fico
final exerciseStrengthTrendProvider =
    FutureProvider.family<List<StrengthDataPoint>, String>(
      (ref, exerciseName) async {
        final repo = ref.read(_trainingRepoProvider);
        return repo.getStrengthTrend(exerciseName, months: 6);
      },
    );
