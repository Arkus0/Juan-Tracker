/// Tests para cálculos de tendencia de peso en isolate (MA-003)
///
/// Verifica que calculateAsync funciona correctamente
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/services/weight_trend_calculator.dart';

void main() {
  group('WeightTrendCalculator MA-003 Isolate Tests', () {
    late WeightTrendCalculator calculator;

    setUp(() {
      calculator = const WeightTrendCalculator();
    });

    test('calculateAsync devuelve mismo resultado que calculate para datos pequeños', () async {
      // Para listas pequeñas (<50), calculateAsync usa calculate sincrónicamente
      final entries = [
        WeighInModel(
          id: '1',
          dateTime: DateTime(2024, 1, 1),
          weightKg: 80.0,
        ),
        WeighInModel(
          id: '2',
          dateTime: DateTime(2024, 1, 2),
          weightKg: 79.8,
        ),
        WeighInModel(
          id: '3',
          dateTime: DateTime(2024, 1, 3),
          weightKg: 79.5,
        ),
      ];

      final syncResult = calculator.calculate(entries);
      final asyncResult = await calculator.calculateAsync(entries);

      // Ambos métodos deben dar el mismo resultado
      expect(asyncResult.emaWeight, closeTo(syncResult.emaWeight, 0.001));
      expect(asyncResult.kalmanWeight, closeTo(syncResult.kalmanWeight, 0.001));
      expect(asyncResult.hwLevel, closeTo(syncResult.hwLevel, 0.001));
    });

    test('calculateAsync lanza error con lista vacía', () async {
      expect(
        () => calculator.calculateAsync([]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('calculateAsync funciona con lista grande de datos', () async {
      // Crear 60 entradas de peso (más del umbral de 50 para usar isolate)
      final entries = List.generate(60, (index) {
        return WeighInModel(
          id: 'entry_$index',
          dateTime: DateTime(2024, 1, 1).add(Duration(days: index)),
          weightKg: 80.0 - (index * 0.1), // Pérdida de 100g por día
        );
      });

      final result = await calculator.calculateAsync(entries);

      // Verificar que se calculó correctamente
      expect(result.entries.length, equals(60));
      expect(result.emaWeight, isNotNull);
      expect(result.kalmanWeight, isNotNull);
      expect(result.hwLevel, isNotNull);
      expect(result.hwTrend, lessThan(0)); // Tendencia a la baja
    });

    test('calculateAsync mantiene configuración personalizada', () async {
      const customConfig = TrendConfig(
        emaPeriod: 14,
        holtWintersPeriod: 14,
        kalmanProcessNoise: 0.05,
      );

      final customCalculator = const WeightTrendCalculator(config: customConfig);

      final entries = List.generate(20, (index) {
        return WeighInModel(
          id: 'entry_$index',
          dateTime: DateTime(2024, 1, 1).add(Duration(days: index)),
          weightKg: 80.0,
        );
      });

      final result = await customCalculator.calculateAsync(entries);

      expect(result.entries.length, equals(20));
    });
  });
}
