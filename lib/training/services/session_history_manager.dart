import 'dart:collection';

import '../models/ejercicio.dart';
import '../models/serie_log.dart';
import '../repositories/i_training_repository.dart';

/// Manager responsable de cargar y cachear el historial de ejercicios
/// durante una sesión de entrenamiento.
/// 
/// Extraído de TrainingSessionNotifier para reducir la complejidad
/// del God Object y mejorar testabilidad.
class SessionHistoryManager {
  final ITrainingRepository _repository;
  
  /// Cache de historial: key = exerciseName, value = logs de última sesión
  final Map<String, List<SerieLog>> _historyCache = {};
  
  /// LRU tracker para limitar tamaño del cache
  final ListQueue<String> _accessOrder = ListQueue();
  static const int _maxCacheSize = 50;

  SessionHistoryManager(this._repository);

  /// Carga el historial para todos los ejercicios de la sesión
  /// 
  /// [exercises] - Lista de ejercicios de la sesión actual
  /// Retorna un Map con el historial cacheado para cada ejercicio
  Future<Map<String, List<SerieLog>>> loadHistoryForExercises(
    List<Ejercicio> exercises,
  ) async {
    final historyMap = <String, List<SerieLog>>{};

    for (final exercise in exercises) {
      final historyKey = _getHistoryKey(exercise);
      
      // Verificar si ya está en cache
      if (_historyCache.containsKey(historyKey)) {
        historyMap[historyKey] = _historyCache[historyKey]!;
        _updateLRU(historyKey);
        continue;
      }

      // Cargar desde repositorio
      final historyList = await _repository.getHistoryForExercise(exercise.nombre);
      
      if (historyList.isNotEmpty) {
        // getHistoryForExercise retorna lista ordenada (newest first)
        final lastSession = historyList.first;
        try {
          final match = lastSession.ejerciciosCompletados.firstWhere(
            (e) => e.nombre == exercise.nombre,
          );
          final logs = match.logs;
          historyMap[historyKey] = logs;
          _addToCache(historyKey, logs);
        } catch (e) {
          // Ejercicio no encontrado en historial
          historyMap[historyKey] = [];
        }
      } else {
        historyMap[historyKey] = [];
      }
    }

    return historyMap;
  }

  /// Obtiene el historial para un ejercicio específico desde el cache
  List<SerieLog>? getHistory(String exerciseName) {
    if (_historyCache.containsKey(exerciseName)) {
      _updateLRU(exerciseName);
      return _historyCache[exerciseName];
    }
    return null;
  }

  /// Obtiene el último peso conocido para un ejercicio
  /// 
  /// Útil para validación de datos y sugerencias de peso
  double getLastKnownWeight(String exerciseKey) {
    final historyLogs = _historyCache[exerciseKey];
    if (historyLogs != null && historyLogs.isNotEmpty) {
      // Buscar el primer log con peso > 0
      for (final log in historyLogs) {
        if (log.peso > 0) return log.peso;
      }
    }
    return 0.0;
  }

  /// Obtiene el último peso conocido para un ejercicio por nombre
  /// (fallback si no está en cache por key completo)
  double getLastKnownWeightByName(String exerciseName) {
    var weight = getLastKnownWeight(exerciseName);
    if (weight > 0) return weight;
    
    // Buscar en cache por nombre
    for (final entry in _historyCache.entries) {
      if (entry.key.contains(exerciseName) || exerciseName.contains(entry.key)) {
        for (final log in entry.value) {
          if (log.peso > 0) return log.peso;
        }
      }
    }
    return 0.0;
  }

  /// Invalida una entrada del cache
  void invalidateCache(String exerciseKey) {
    _historyCache.remove(exerciseKey);
    _accessOrder.remove(exerciseKey);
  }

  /// Limpia todo el cache
  void clearCache() {
    _historyCache.clear();
    _accessOrder.clear();
  }

  /// Genera una key consistente para identificar ejercicios en el historial
  String _getHistoryKey(Ejercicio exercise) {
    // Usar libraryId si no está vacío, sino fallback a nombre
    final libraryId = exercise.libraryId;
    if (libraryId.isNotEmpty) {
      return 'lib:$libraryId';
    }
    return 'name:${exercise.nombre}';
  }

  /// Añade una entrada al cache con LRU tracking
  void _addToCache(String key, List<SerieLog> logs) {
    // Evictar si es necesario
    if (_historyCache.length >= _maxCacheSize && _accessOrder.isNotEmpty) {
      final lruKey = _accessOrder.first;
      _historyCache.remove(lruKey);
      _accessOrder.removeFirst();
    }

    _historyCache[key] = logs;
    _accessOrder.add(key);
  }

  /// Actualiza el orden LRU cuando se accede a una entrada
  void _updateLRU(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Estadísticas del cache para debugging
  Map<String, dynamic> get stats => {
    'cacheSize': _historyCache.length,
    'maxSize': _maxCacheSize,
    'utilization': '${((_historyCache.length / _maxCacheSize) * 100).toStringAsFixed(1)}%',
    'cachedExercises': _historyCache.keys.toList(),
  };
}
