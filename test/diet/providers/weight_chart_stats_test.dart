import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/providers/weight_trend_providers.dart';

/// Regression tests for WeightChartStats to ensure memoized calculations
/// produce identical results to the original inline calculations.
void main() {
  group('WeightChartStats regression tests', () {
    test('weightRange calculates correctly', () {
      const stats = WeightChartStats(
        minWeight: 70.0,
        maxWeight: 75.0,
        weeklyAverage: 72.5,
        daysTracking: 30,
        totalChange: 2.0,
      );

      expect(stats.weightRange, 5.0);
    });

    test('padding calculates correctly with positive range', () {
      const stats = WeightChartStats(
        minWeight: 70.0,
        maxWeight: 75.0,
        weeklyAverage: 72.5,
        daysTracking: 30,
        totalChange: 2.0,
      );

      // padding = weightRange * 0.1 = 5.0 * 0.1 = 0.5
      expect(stats.padding, 0.5);
    });

    test('padding returns 1.0 when range is zero', () {
      const stats = WeightChartStats(
        minWeight: 70.0,
        maxWeight: 70.0,
        weeklyAverage: 70.0,
        daysTracking: 30,
        totalChange: 0.0,
      );

      // When min == max, weightRange is 0, so padding should be 1.0
      expect(stats.padding, 1.0);
    });

    test('handles null weekly average', () {
      const stats = WeightChartStats(
        minWeight: 70.0,
        maxWeight: 75.0,
        weeklyAverage: null,
        daysTracking: 5,
        totalChange: 1.0,
      );

      expect(stats.weeklyAverage, isNull);
      expect(stats.minWeight, 70.0);
      expect(stats.maxWeight, 75.0);
    });

    test('handles negative total change (weight loss)', () {
      const stats = WeightChartStats(
        minWeight: 68.0,
        maxWeight: 75.0,
        weeklyAverage: 70.0,
        daysTracking: 60,
        totalChange: -5.0,
      );

      expect(stats.totalChange, -5.0);
      expect(stats.daysTracking, 60);
    });

    test('handles positive total change (weight gain)', () {
      const stats = WeightChartStats(
        minWeight: 70.0,
        maxWeight: 78.0,
        weeklyAverage: 75.0,
        daysTracking: 45,
        totalChange: 8.0,
      );

      expect(stats.totalChange, 8.0);
      expect(stats.weightRange, 8.0);
    });

    test('handles single day tracking', () {
      const stats = WeightChartStats(
        minWeight: 72.0,
        maxWeight: 72.0,
        weeklyAverage: null,
        daysTracking: 1,
        totalChange: 0.0,
      );

      expect(stats.daysTracking, 1);
      expect(stats.weeklyAverage, isNull);
      expect(stats.totalChange, 0.0);
    });

    test('handles very small weight differences', () {
      const stats = WeightChartStats(
        minWeight: 70.0,
        maxWeight: 70.1,
        weeklyAverage: 70.05,
        daysTracking: 7,
        totalChange: 0.1,
      );

      // weightRange = 0.1, padding = 0.01
      expect(stats.weightRange, closeTo(0.1, 0.001));
      expect(stats.padding, closeTo(0.01, 0.001));
    });

    test('handles very large weight range', () {
      const stats = WeightChartStats(
        minWeight: 50.0,
        maxWeight: 100.0,
        weeklyAverage: 75.0,
        daysTracking: 365,
        totalChange: -25.0,
      );

      expect(stats.weightRange, 50.0);
      expect(stats.padding, 5.0);
    });
  });
}
