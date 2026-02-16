import 'dart:async';
import 'package:flutter/foundation.dart';

/// Servicio de telemetría para monitoreo de rendimiento en producción
///
/// Recopila métricas anónimas de:
/// - Tiempo de búsqueda de alimentos
/// - Tiempo de carga de base de datos
/// - Uso de cache (hit/miss rates)
/// - Errores de SQL y rendimiento
///
/// TODO: Enviar métricas a servicio de analytics en producción
class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();
  factory TelemetryService() => _instance;
  static TelemetryService get instance => _instance;
  TelemetryService._internal();

  final Map<String, List<MetricDataPoint>> _metrics = {};
  final _metricController = StreamController<MetricEvent>.broadcast();

  Stream<MetricEvent> get metricStream => _metricController.stream;

  /// Registra un punto de datos de métrica
  void recordMetric(
    String name, {
    required double value,
    Map<String, dynamic>? tags,
  }) {
    final point = MetricDataPoint(
      timestamp: DateTime.now(),
      value: value,
      tags: tags ?? {},
    );

    _metrics.putIfAbsent(name, () => []).add(point);

    // Mantener solo últimos 1000 puntos por métrica para evitar memory leak
    if (_metrics[name]!.length > 1000) {
      _metrics[name]!.removeAt(0);
    }

    _metricController.add(MetricEvent(name: name, dataPoint: point));

    if (kDebugMode) {
      debugPrint(
        '[Telemetry] $name: ${value.toStringAsFixed(2)}ms ${tags ?? ''}',
      );
    }
  }

  /// Registra un evento discreto como métrica de contador.
  /// Mantiene compatibilidad con la API legacy usada en training.
  void trackEvent(String name, [Map<String, dynamic>? props]) {
    recordMetric('event_$name', value: 1, tags: props);
  }

  /// Registra una traza de diagnóstico en debug.
  void breadcrumb(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      debugPrint('[Telemetry][Breadcrumb] $message ${data ?? {}}');
    }
  }

  /// Registra error con contexto mínimo y sin lanzar excepción.
  void error(String message, [Object? error, StackTrace? st]) {
    if (kDebugMode) {
      final details = <String>[
        message,
        if (error != null) 'error=$error',
        if (st != null) 'stack=$st',
      ].join(' | ');
      debugPrint('[Telemetry][Error] $details');
    }
    recordMetric(
      'error_${message.replaceAll(' ', '_')}',
      value: 1,
      tags: {if (error != null) 'error_type': error.runtimeType.toString()},
    );
  }

  /// Mide el tiempo de ejecución de una función async
  Future<T> measureAsync<T>(
    String metricName,
    Future<T> Function() operation, {
    Map<String, dynamic>? tags,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      recordMetric(
        metricName,
        value: stopwatch.elapsedMilliseconds.toDouble(),
        tags: {...?tags, 'success': true},
      );
      return result;
    } catch (e) {
      recordMetric(
        metricName,
        value: stopwatch.elapsedMilliseconds.toDouble(),
        tags: {...?tags, 'success': false, 'error': e.runtimeType.toString()},
      );
      rethrow;
    }
  }

  /// Mide el tiempo de ejecución de una función sync
  T measure<T>(
    String metricName,
    T Function() operation, {
    Map<String, dynamic>? tags,
  }) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      recordMetric(
        metricName,
        value: stopwatch.elapsedMilliseconds.toDouble(),
        tags: {...?tags, 'success': true},
      );
      return result;
    } catch (e) {
      recordMetric(
        metricName,
        value: stopwatch.elapsedMilliseconds.toDouble(),
        tags: {...?tags, 'success': false, 'error': e.runtimeType.toString()},
      );
      rethrow;
    }
  }

  /// Obtiene estadísticas de una métrica
  MetricStats getStats(String name) {
    final points = _metrics[name] ?? [];
    if (points.isEmpty) {
      return MetricStats.empty();
    }

    final values = points.map((p) => p.value).toList()..sort();
    final sum = values.reduce((a, b) => a + b);

    return MetricStats(
      count: values.length,
      mean: sum / values.length,
      min: values.first,
      max: values.last,
      p50: values[(values.length * 0.5).floor()],
      p95: values[(values.length * 0.95).floor()],
      p99: values[(values.length * 0.99).floor()],
    );
  }

  /// Obtiene todas las métricas registradas
  Map<String, MetricStats> getAllStats() {
    return {for (var name in _metrics.keys) name: getStats(name)};
  }

  /// Limpia todas las métricas (útil para testing)
  void clear() {
    _metrics.clear();
  }

  void dispose() {
    _metricController.close();
  }
}

/// Punto de datos de métrica
class MetricDataPoint {
  final DateTime timestamp;
  final double value;
  final Map<String, dynamic> tags;

  const MetricDataPoint({
    required this.timestamp,
    required this.value,
    required this.tags,
  });
}

/// Evento de métrica para streams
class MetricEvent {
  final String name;
  final MetricDataPoint dataPoint;

  const MetricEvent({required this.name, required this.dataPoint});
}

/// Estadísticas de métrica
class MetricStats {
  final int count;
  final double mean;
  final double min;
  final double max;
  final double p50;
  final double p95;
  final double p99;

  const MetricStats({
    required this.count,
    required this.mean,
    required this.min,
    required this.max,
    required this.p50,
    required this.p95,
    required this.p99,
  });

  factory MetricStats.empty() => const MetricStats(
    count: 0,
    mean: 0,
    min: 0,
    max: 0,
    p50: 0,
    p95: 0,
    p99: 0,
  );

  @override
  String toString() =>
      'count=$count, mean=${mean.toStringAsFixed(2)}, '
      'min=${min.toStringAsFixed(2)}, max=${max.toStringAsFixed(2)}, '
      'p50=${p50.toStringAsFixed(2)}, p95=${p95.toStringAsFixed(2)}, '
      'p99=${p99.toStringAsFixed(2)}';
}

/// Nombres de métricas estándar
class MetricNames {
  // Búsqueda de alimentos
  static const String foodSearchLocal = 'food_search_local';
  static const String foodSearchRemote = 'food_search_remote';
  static const String foodSearchTotal = 'food_search_total';

  // Base de datos
  static const String dbLoadFoods = 'db_load_foods';
  static const String dbRebuildFts = 'db_rebuild_fts';
  static const String dbMigration = 'db_migration';

  // Cache
  static const String cacheHit = 'cache_hit';
  static const String cacheMiss = 'cache_miss';
  static const String cacheEviction = 'cache_eviction';

  // Entrenamiento
  static const String sessionSave = 'session_save';
  static const String sessionRestore = 'session_restore';
  static const String timerOperation = 'timer_operation';

  // UI
  static const String screenLoad = 'screen_load';
  static const String widgetBuild = 'widget_build';
}
