import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/services/open_food_facts_service.dart';
import 'package:juan_tracker/diet/models/open_food_facts_model.dart';

void main() {
  group('OpenFoodFactsService', () {
    late OpenFoodFactsService service;

    setUp(() {
      service = OpenFoodFactsService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Rate limiting', () {
      test('should allow requests within rate limit', () {
        // Initial state should allow requests
        expect(service.canMakeRequest, isTrue);
      });

      test('should build correct API URL with parameters', () {
        // This is an internal test - verifying URL construction
        // In real usage, this would be called via searchProducts
        expect(OpenFoodFactsService.apiUrl, 
            equals('https://world.openfoodfacts.org/api/v2'));
      });
    });

    group('Search validation', () {
      test('should return empty response for empty query', () async {
        final response = await service.searchProducts('');
        expect(response.products, isEmpty);
        expect(response.hasMore, isFalse);
      });

      test('should return empty response for whitespace-only query', () async {
        final response = await service.searchProducts('   ');
        expect(response.products, isEmpty);
        expect(response.hasMore, isFalse);
      });
    });

    group('Barcode search', () {
      test('should return null for empty barcode', () async {
        final result = await service.searchByBarcode('');
        expect(result, isNull);
      });

      test('should return null for whitespace-only barcode', () async {
        final result = await service.searchByBarcode('   ');
        expect(result, isNull);
      });
    });

    group('URL construction', () {
      test('should use correct base URL', () {
        expect(OpenFoodFactsService.baseUrl, 
            equals('https://world.openfoodfacts.org'));
      });

      test('should use correct API version', () {
        expect(OpenFoodFactsService.apiUrl, 
            contains('/api/v2'));
      });
    });
  });

  group('OpenFoodFactsResult', () {
    final now = DateTime.now();

    test('should calculate hasValidNutrition correctly', () {
      final resultWithNutrition = OpenFoodFactsResult(
        code: '123',
        name: 'Test Product',
        kcalPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
        fetchedAt: now,
      );

      expect(resultWithNutrition.hasValidNutrition, isTrue);

      final resultWithoutNutrition = OpenFoodFactsResult(
        code: '456',
        name: 'Invalid Product',
        kcalPer100g: 0,
        proteinPer100g: 0,
        carbsPer100g: 0,
        fatPer100g: 0,
        fetchedAt: now,
      );

      expect(resultWithoutNutrition.hasValidNutrition, isFalse);
    });

    test('should convert to FoodModel correctly', () {
      final result = OpenFoodFactsResult(
        code: '123456789',
        name: 'Test Product',
        brand: 'Test Brand',
        kcalPer100g: 250,
        proteinPer100g: 20,
        carbsPer100g: 30,
        fatPer100g: 10,
        portionName: 'Serving',
        portionGrams: 100,
        fetchedAt: now,
      );

      final foodJson = result.toFoodModelJson();

      expect(foodJson['name'], equals('Test Product'));
      expect(foodJson['brand'], equals('Test Brand'));
      expect(foodJson['barcode'], equals('123456789'));
      expect(foodJson['kcalPer100g'], equals(250));
      expect(foodJson['proteinPer100g'], equals(20.0));
      expect(foodJson['carbsPer100g'], equals(30.0));
      expect(foodJson['fatPer100g'], equals(10.0));
      expect(foodJson['userCreated'], isFalse);
      expect(foodJson['verifiedSource'], equals('OFF'));
    });
  });
}
