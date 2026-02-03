import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/core/services/telemetry_service.dart';

/// Tests para TelemetryService
/// 
/// NOTA: TelemetryService es un singleton, por lo que los tests
/// deben manejar el estado compartido cuidadosamente.
void main() {
  group('TelemetryService Tests', () {
    late TelemetryService telemetry;

    setUp(() {
      // Crear nueva instancia para cada test
      telemetry = TelemetryService();
    });

    tearDown(() {
      // Limpiar pero no cerrar el stream (es singleton)
      telemetry.clear();
    });

    group('Record Metrics', () {
      test('debe registrar métrica básica', () {
        telemetry.recordMetric('test_metric', value: 100.0);
        
        final stats = telemetry.getStats('test_metric');
        expect(stats.count, 1);
        expect(stats.mean, 100.0);
      });

      test('debe registrar múltiples métricas', () {
        telemetry.recordMetric('latency', value: 10.0);
        telemetry.recordMetric('latency', value: 20.0);
        telemetry.recordMetric('latency', value: 30.0);
        
        final stats = telemetry.getStats('latency');
        expect(stats.count, 3);
        expect(stats.mean, 20.0);
        expect(stats.min, 10.0);
        expect(stats.max, 30.0);
      });

      test('debe manejar tags en métricas', () {
        telemetry.recordMetric(
          'request',
          value: 50.0,
          tags: {'endpoint': '/api/foods'},
        );
        
        final stats = telemetry.getStats('request');
        expect(stats.count, 1);
      });
    });

    group('Measure Operations', () {
      test('debe medir operación síncrona exitosa', () {
        final result = telemetry.measure('operation', () => 42);
        
        expect(result, 42);
        
        final stats = telemetry.getStats('operation');
        expect(stats.count, 1);
      });

      test('debe medir operación síncrona con error', () {
        expect(
          () => telemetry.measure('failing_op', () {
            throw Exception('Test error');
          }),
          throwsException,
        );
        
        final stats = telemetry.getStats('failing_op');
        expect(stats.count, 1);
      });

      test('debe medir operación asíncrona exitosa', () async {
        final result = await telemetry.measureAsync('async_op', () async {
          await Future.delayed(const Duration(milliseconds: 1));
          return 'done';
        });
        
        expect(result, 'done');
        
        final stats = telemetry.getStats('async_op');
        expect(stats.count, 1);
      });
    });

    group('Percentiles', () {
      test('debe calcular percentiles correctamente', () {
        for (var i = 1; i <= 100; i++) {
          telemetry.recordMetric('percentile_test', value: i.toDouble());
        }
        
        final stats = telemetry.getStats('percentile_test');
        // Allow for interpolation variance (e.g., p50 could be 50.5)
        expect(stats.p50, closeTo(50, 2.0));
        expect(stats.p95, closeTo(95, 2.0));
        expect(stats.p99, closeTo(99, 2.0));
      });
    });

    group('Memory Limit', () {
      test('debe mantener máximo 1000 puntos por métrica', () {
        for (var i = 0; i < 1500; i++) {
          telemetry.recordMetric('memory_test', value: i.toDouble());
        }
        
        final stats = telemetry.getStats('memory_test');
        expect(stats.count, 1000);
      });
    });

    group('Empty Stats', () {
      test('debe manejar métricas sin datos', () {
        final stats = telemetry.getStats('nonexistent');
        expect(stats.count, 0);
        expect(stats.mean, 0);
      });
    });

    group('All Stats', () {
      test('debe retornar estadísticas de todas las métricas', () {
        telemetry.recordMetric('metric_a', value: 10.0);
        telemetry.recordMetric('metric_b', value: 20.0);
        
        final allStats = telemetry.getAllStats();
        expect(allStats.length, 2);
      });
    });
  });
}
