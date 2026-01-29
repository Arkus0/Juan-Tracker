import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/weighin_model.dart';
import 'package:juan_tracker/diet/services/weight_trend_calculator.dart';

void main() {
  group('WeightTrendCalculator - Multi-Modelo', () {
    const calculator = WeightTrendCalculator();

    group('EMA (Exponential Moving Average)', () {
      test('debe lanzar error con lista vacía', () {
        expect(
          () => calculator.calculate([]),
          throwsArgumentError,
        );
      });

      test('con un solo registro, EMA = peso registrado', () {
        final entries = [
          _createWeighIn(DateTime(2024, 1, 15), 75.0),
        ];

        final result = calculator.calculate(entries);

        expect(result.emaWeight, 75.0);
        expect(result.emaHistory.length, 1);
      });

      test('EMA suaviza fluctuaciones diarias', () {
        final entries = [
          _createWeighIn(DateTime(2024, 1, 10), 75.0),
          _createWeighIn(DateTime(2024, 1, 11), 76.0),
          _createWeighIn(DateTime(2024, 1, 12), 75.0),
          _createWeighIn(DateTime(2024, 1, 13), 76.0),
          _createWeighIn(DateTime(2024, 1, 14), 75.0),
        ];

        final result = calculator.calculate(entries);

        // El EMA debería estar cerca de 75.2 (entre 75 y 76)
        expect(result.emaWeight, closeTo(75.2, 0.5));
      });
    });

    group('Holt-Winters (Nivel + Tendencia)', () {
      test('con datos estables, tendencia ≈ 0', () {
        final entries = <WeighInModel>[];
        for (int i = 0; i < 10; i++) {
          entries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            75.0,
          ));
        }

        final result = calculator.calculate(entries);

        expect(result.hwTrend.abs(), lessThan(0.1));
        expect(result.hwLevel, closeTo(75.0, 0.5));
      });

      test('detecta tendencia ascendente', () {
        final entries = <WeighInModel>[];
        for (int i = 0; i < 14; i++) {
          entries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            70.0 + (i * 0.2), // +0.2kg por día
          ));
        }

        final result = calculator.calculate(entries);

        // Tendencia debería ser aproximadamente +0.2 kg/día
        expect(result.hwTrend, greaterThan(0.1));
        expect(result.hwTrend, lessThan(0.3));

        // Predicción a 7 días debería ser mayor que el nivel actual
        expect(result.hwPrediction7d, greaterThan(result.hwLevel));
      });

      test('detecta tendencia descendente', () {
        final entries = <WeighInModel>[];
        for (int i = 0; i < 14; i++) {
          entries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            80.0 - (i * 0.15), // -0.15kg por día
          ));
        }

        final result = calculator.calculate(entries);

        // Tendencia negativa
        expect(result.hwTrend, lessThan(-0.05));
        expect(result.hwTrend, greaterThan(-0.25));
      });
    });

    group('Filtro de Kalman', () {
      test('estimación Kalman es más estable que peso bruto', () {
        // Datos con mucho ruido alrededor de 75kg
        final entries = [
          _createWeighIn(DateTime(2024, 1, 1), 74.2),
          _createWeighIn(DateTime(2024, 1, 2), 75.8),
          _createWeighIn(DateTime(2024, 1, 3), 74.5),
          _createWeighIn(DateTime(2024, 1, 4), 75.5),
          _createWeighIn(DateTime(2024, 1, 5), 74.8),
          _createWeighIn(DateTime(2024, 1, 6), 75.2),
          _createWeighIn(DateTime(2024, 1, 7), 75.0),
        ];

        final result = calculator.calculate(entries);

        // Kalman debería filtrar el ruido y dar un valor cercano a 75
        expect(result.kalmanWeight, closeTo(75.0, 0.5));

        // Confianza debería ser alta con datos consistentes
        expect(result.kalmanConfidence, greaterThan(0.5));
      });

      test('confianza aumenta con más datos consistentes', () {
        final entriesShort = [
          _createWeighIn(DateTime(2024, 1, 1), 75.0),
          _createWeighIn(DateTime(2024, 1, 2), 75.2),
        ];

        final entriesLong = <WeighInModel>[];
        for (int i = 0; i < 20; i++) {
          entriesLong.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            75.0 + (i * 0.01),
          ));
        }

        final resultShort = calculator.calculate(entriesShort);
        final resultLong = calculator.calculate(entriesLong);

        // Más datos = mayor confianza
        expect(resultLong.kalmanConfidence, greaterThan(resultShort.kalmanConfidence));
      });
    });

    group('Regresión Lineal', () {
      test('R² cercano a 1 con tendencia lineal perfecta', () {
        final entries = <WeighInModel>[];
        for (int i = 0; i < 14; i++) {
          entries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            70.0 + (i * 0.1), // Tendencia lineal perfecta
          ));
        }

        final result = calculator.calculate(entries);

        // R² debería ser muy alto (> 0.95)
        expect(result.regressionR2, greaterThan(0.95));

        // Pendiente debería ser aproximadamente 0.1
        expect(result.regressionSlope, closeTo(0.1, 0.05));
      });

      test('R² bajo con datos aleatorios', () {
        // Datos aleatorios sin tendencia clara
        final entries = [
          _createWeighIn(DateTime(2024, 1, 1), 75.0),
          _createWeighIn(DateTime(2024, 1, 2), 74.0),
          _createWeighIn(DateTime(2024, 1, 3), 76.0),
          _createWeighIn(DateTime(2024, 1, 4), 73.0),
          _createWeighIn(DateTime(2024, 1, 5), 77.0),
        ];

        final result = calculator.calculate(entries);

        // R² debería ser bajo
        expect(result.regressionR2, lessThan(0.5));
      });
    });

    group('Detección de Fase', () {
      test('detecta fase de pérdida de peso', () {
        final entries = <WeighInModel>[];
        for (int i = 0; i < 14; i++) {
          entries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            80.0 - (i * 0.3), // Perdiendo 0.3kg por día = 2.1kg/semana
          ));
        }

        final result = calculator.calculate(entries);

        expect(result.phase, WeightPhase.losing);
        expect(result.weeklyRate, lessThan(0));
        expect(result.weeklyRate.abs(), greaterThan(1.0));
      });

      test('detecta fase de ganancia de peso', () {
        final entries = <WeighInModel>[];
        for (int i = 0; i < 14; i++) {
          entries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            70.0 + (i * 0.2), // Ganando 0.2kg por día
          ));
        }

        final result = calculator.calculate(entries);

        expect(result.phase, WeightPhase.gaining);
        expect(result.weeklyRate, greaterThan(0));
      });

      test('detecta fase estable (plateau)', () {
        final entries = <WeighInModel>[];
        for (int i = 0; i < 20; i++) {
          entries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            75.0 + (i % 2 == 0 ? 0.1 : -0.1), // Fluctuando ±100g
          ));
        }

        final result = calculator.calculate(entries);

        expect(result.phase, WeightPhase.maintaining);
        expect(result.weeklyRate.abs(), lessThan(0.3));
        expect(result.daysInPhase, greaterThan(5));
      });

      test('insufficient data con menos de 3 registros', () {
        final entries = [
          _createWeighIn(DateTime(2024, 1, 1), 75.0),
          _createWeighIn(DateTime(2024, 1, 2), 75.2),
        ];

        final result = calculator.calculate(entries);

        expect(result.phase, WeightPhase.insufficientData);
      });
    });

    group('Integración - Criterio de Aceptación', () {
      test('insertar 10 weigh-ins ve trend estable', () {
        // Datos realistas fluctuando alrededor de 75kg (sin tendencia clara)
        final entries = [
          _createWeighIn(DateTime(2024, 1, 1), 75.2),
          _createWeighIn(DateTime(2024, 1, 2), 74.8),
          _createWeighIn(DateTime(2024, 1, 3), 75.0),
          _createWeighIn(DateTime(2024, 1, 4), 75.1),
          _createWeighIn(DateTime(2024, 1, 5), 74.9),
          _createWeighIn(DateTime(2024, 1, 6), 75.1),
          _createWeighIn(DateTime(2024, 1, 7), 74.8),
          _createWeighIn(DateTime(2024, 1, 8), 75.0),
          _createWeighIn(DateTime(2024, 1, 9), 75.2),
          _createWeighIn(DateTime(2024, 1, 10), 75.0),
        ];

        final result = calculator.calculate(entries);

        // Todos los modelos deberían coincidir aproximadamente
        expect(result.emaWeight, closeTo(75.0, 1.0));
        expect(result.kalmanWeight, closeTo(75.0, 1.0));
        expect(result.hwLevel, closeTo(75.0, 1.0));

        // Varianza pequeña entre peso actual y tendencia
        expect((result.latestWeight - result.trendWeight).abs(), lessThan(0.5));

        // Con datos estables, deberíamos detectar plateau o losing leve
        expect(result.phase, anyOf(
          WeightPhase.maintaining,
          WeightPhase.losing, // Puede detectar losing si el último valor es menor
        ));

        // Confianza razonable
        expect(result.kalmanConfidence, greaterThan(0.5));
      });

      test('predicción confiable solo con suficientes datos', () {
        // Pocos datos
        final fewEntries = <WeighInModel>[];
        for (int i = 0; i < 5; i++) {
          fewEntries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            75.0 + (i * 0.1),
          ));
        }

        // Muchos datos
        final manyEntries = <WeighInModel>[];
        for (int i = 0; i < 21; i++) {
          manyEntries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            75.0 + (i * 0.1),
          ));
        }

        final resultFew = calculator.calculate(fewEntries);
        final resultMany = calculator.calculate(manyEntries);

        // Con pocos datos, predicción no es confiable
        expect(resultFew.isPredictionReliable, isFalse);
        expect(resultFew.hwPrediction30d, isNull);

        // Con muchos datos, predicción es confiable
        expect(resultMany.isPredictionReliable, isTrue);
        expect(resultMany.hwPrediction30d, isNotNull);
      });
    });

    group('Configuración personalizada', () {
      test('Kalman con menos ruido de proceso es más reactivo', () {
        final entries = <WeighInModel>[];
        for (int i = 0; i < 10; i++) {
          entries.add(_createWeighIn(
            DateTime(2024, 1, 1).add(Duration(days: i)),
            75.0 + (i * 0.5), // Cambio rápido
          ));
        }

        const configFast = TrendConfig(kalmanProcessNoise: 0.1);
        const configSlow = TrendConfig(kalmanProcessNoise: 0.001);

        final calcFast = WeightTrendCalculator(config: configFast);
        final calcSlow = WeightTrendCalculator(config: configSlow);

        final resultFast = calcFast.calculate(entries);
        final resultSlow = calcSlow.calculate(entries);

        // Con más ruido de proceso, sigue más de cerca los cambios
        expect(
          (resultFast.kalmanWeight - resultFast.latestWeight).abs(),
          lessThan((resultSlow.kalmanWeight - resultSlow.latestWeight).abs()),
        );
      });
    });

    group('ChartDataPoint', () {
      test('generateChartData genera puntos correctamente', () {
        final entries = [
          _createWeighIn(DateTime(2024, 1, 10), 75.0, note: 'Inicio'),
          _createWeighIn(DateTime(2024, 1, 11), 75.2),
          _createWeighIn(DateTime(2024, 1, 12), 75.1),
        ];

        final chartData = calculator.generateChartData(entries);

        expect(chartData.length, 3);
        expect(chartData.first.date, DateTime(2024, 1, 10));
        expect(chartData.first.weight, 75.0);
        expect(chartData.first.note, 'Inicio');
      });
    });
  });
}

// Helper para crear weigh-ins en tests
WeighInModel _createWeighIn(DateTime date, double weight, {String? note}) {
  return WeighInModel(
    id: 'test-${date.millisecondsSinceEpoch}',
    dateTime: date,
    weightKg: weight,
    note: note,
  );
}
