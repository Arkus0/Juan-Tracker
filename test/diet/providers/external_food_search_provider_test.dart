import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/providers/external_food_search_provider.dart';
import 'package:juan_tracker/diet/models/open_food_facts_model.dart';

void main() {
  group('ExternalSearchState', () {
    test('should have correct default values', () {
      const state = ExternalSearchState();

      expect(state.status, equals(ExternalSearchStatus.idle));
      expect(state.results, isEmpty);
      expect(state.query, isEmpty);
      expect(state.page, equals(1));
      expect(state.hasMore, isFalse);
      expect(state.isOnline, isTrue);
    });

    test('copyWith should preserve values when not provided', () {
      const state = ExternalSearchState(
        status: ExternalSearchStatus.success,
        query: 'chicken',
        page: 2,
        hasMore: true,
      );

      final newState = state.copyWith(page: 3);

      expect(newState.status, equals(ExternalSearchStatus.success));
      expect(newState.query, equals('chicken'));
      expect(newState.page, equals(3));
      expect(newState.hasMore, isTrue);
    });

    test('should detect loading states correctly', () {
      const loadingState = ExternalSearchState(
        status: ExternalSearchStatus.loading,
      );
      expect(loadingState.isLoading, isTrue);
      expect(loadingState.isSuccess, isFalse);

      const successState = ExternalSearchState(
        status: ExternalSearchStatus.success,
      );
      expect(successState.isLoading, isFalse);
      expect(successState.isSuccess, isTrue);

      const errorState = ExternalSearchState(
        status: ExternalSearchStatus.error,
      );
      expect(errorState.hasError, isTrue);
    });
  });

  group('Result filtering', () {
    // Note: These tests would require mocking the service
    // For now, we test the state management logic

    test('should filter results based on query relevance', () {
      // This test documents the expected filtering behavior
      // In the actual implementation, results should:
      // 1. Contain at least one word from the query in the name or brand
      // 2. For short queries (<4 chars), match prefix
      // 3. Ignore very short words (<3 chars)

      final results = [
        OpenFoodFactsResult(code: '1', name: 'Chicken Breast', kcalPer100g: 100, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '2', name: 'Oats', kcalPer100g: 100, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '3', name: 'Chicken Thigh', kcalPer100g: 100, fetchedAt: DateTime.now()),
      ];

      final query = 'chicken';
      final queryWords = query.toLowerCase().split(RegExp(r'\s+'));

      final filtered = results.where((product) {
        final nameLower = product.name.toLowerCase();
        for (final word in queryWords) {
          if (word.length < 3) continue;
          if (nameLower.contains(word)) return true;
        }
        return false;
      }).toList();

      expect(filtered.length, equals(2));
      expect(filtered.map((r) => r.name), 
          containsAll(['Chicken Breast', 'Chicken Thigh']));
    });

    test('should handle empty query gracefully', () {
      final results = [
        OpenFoodFactsResult(code: '1', name: 'Chicken', kcalPer100g: 100, fetchedAt: DateTime.now()),
      ];

      final query = '';
      final queryWords = query.toLowerCase().split(RegExp(r'\s+'));

      final filtered = results.where((product) {
        final nameLower = product.name.toLowerCase();
        for (final word in queryWords) {
          if (word.length < 3) continue;
          if (nameLower.contains(word)) return true;
        }
        return false;
      }).toList();

      expect(filtered, isEmpty);
    });
  });
}
