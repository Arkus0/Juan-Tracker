import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/open_food_facts_model.dart';
import 'package:juan_tracker/diet/services/open_food_facts_service.dart';

void main() {
  group('OpenFoodFactsResult', () {
    test('fromApiJson normaliza correctamente datos básicos', () {
      final json = {
        'code': '123456789',
        'product': {
          'product_name': 'Yogur Natural',
          'brands': 'Danone, Nestle',
          'image_url': 'https://example.com/image.jpg',
          'serving_size': '125g',
          'nutriments': {
            'energy-kcal_100g': 65.0,
            'proteins_100g': 3.5,
            'carbohydrates_100g': 4.8,
            'fat_100g': 3.2,
          },
        },
      };

      final result = OpenFoodFactsResult.fromApiJson(json);

      expect(result.code, '123456789');
      expect(result.name, 'Yogur Natural');
      expect(result.brand, 'Danone'); // Primera marca
      expect(result.imageUrl, 'https://example.com/image.jpg');
      expect(result.kcalPer100g, 65.0);
      expect(result.proteinPer100g, 3.5);
      expect(result.carbsPer100g, 4.8);
      expect(result.fatPer100g, 3.2);
      expect(result.portionName, '125g');
      expect(result.portionGrams, 125.0);
    });

    test('fromApiJson maneja fallback de nombres vacíos', () {
      final json = {
        'code': '123',
        'product': {
          'generic_name': 'Producto Genérico',
          'nutriments': {'energy-kcal_100g': 100},
        },
      };

      final result = OpenFoodFactsResult.fromApiJson(json);
      expect(result.name, 'Producto Genérico');
    });

    test('fromApiJson maneja nombre vacío con default', () {
      final json = {
        'code': '123',
        'product': {
          'nutriments': {'energy-kcal_100g': 100},
        },
      };

      final result = OpenFoodFactsResult.fromApiJson(json);
      expect(result.name, 'Producto sin nombre');
    });

    test('extractKcal convierte correctamente desde kJ', () {
      final json = {
        'code': '123',
        'product': {
          'nutriments': {
            'energy_100g': 1700.0, // kJ
          },
        },
      };

      final result = OpenFoodFactsResult.fromApiJson(json);
      expect(result.kcalPer100g, closeTo(406, 1)); // 1700 / 4.184 ≈ 406
    });

    test('extractKcal usa energy-kj_100g si no hay otra fuente', () {
      final json = {
        'code': '123',
        'product': {
          'nutriments': {
            'energy-kj_100g': 418.4,
          },
        },
      };

      final result = OpenFoodFactsResult.fromApiJson(json);
      expect(result.kcalPer100g, closeTo(100, 1)); // 418.4 / 4.184 ≈ 100
    });

    test('hasValidNutrition es true con kcal > 0', () {
      final result = OpenFoodFactsResult(
        code: '123',
        name: 'Test',
        kcalPer100g: 100,
        fetchedAt: DateTime.now(),
      );
      expect(result.hasValidNutrition, true);
    });

    test('hasValidNutrition es true con proteína > 0', () {
      final result = OpenFoodFactsResult(
        code: '123',
        name: 'Test',
        kcalPer100g: 0,
        proteinPer100g: 10,
        fetchedAt: DateTime.now(),
      );
      expect(result.hasValidNutrition, true);
    });

    test('hasValidNutrition es false sin datos', () {
      final result = OpenFoodFactsResult(
        code: '123',
        name: 'Test',
        kcalPer100g: 0,
        fetchedAt: DateTime.now(),
      );
      expect(result.hasValidNutrition, false);
    });

    test('toCacheJson y fromCacheJson serializan correctamente', () {
      final original = OpenFoodFactsResult(
        code: '123',
        name: 'Test Product',
        brand: 'Test Brand',
        kcalPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
        portionName: 'serving',
        portionGrams: 100,
        fetchedAt: DateTime(2024, 1, 15),
      );

      final json = original.toCacheJson();
      final restored = OpenFoodFactsResult.fromCacheJson(json);

      expect(restored.code, original.code);
      expect(restored.name, original.name);
      expect(restored.brand, original.brand);
      expect(restored.kcalPer100g, original.kcalPer100g);
      expect(restored.proteinPer100g, original.proteinPer100g);
      expect(restored.carbsPer100g, original.carbsPer100g);
      expect(restored.fatPer100g, original.fatPer100g);
      expect(restored.portionName, original.portionName);
      expect(restored.portionGrams, original.portionGrams);
      expect(restored.fetchedAt, original.fetchedAt);
    });
  });

  group('OpenFoodFactsSearchResponse', () {
    test('fromApiJson filtra productos sin datos nutricionales', () {
      final json = {
        'count': 3,
        'page': 1,
        'page_size': 24,
        'products': [
          {
            'code': '1',
            'product_name': 'Producto válido',
            'nutriments': {'energy-kcal_100g': 100},
          },
          {
            'code': '2',
            'product_name': 'Producto sin datos',
            'nutriments': {},
          },
          {
            'code': '3',
            'product_name': 'Otro válido',
            'nutriments': {'proteins_100g': 10},
          },
        ],
      };

      final response = OpenFoodFactsSearchResponse.fromApiJson(json);

      expect(response.products.length, 2); // Filtra el que no tiene datos
      expect(response.count, 3);
      expect(response.page, 1);
      expect(response.hasMore, false);
    });

    test('empty constructor crea respuesta vacía', () {
      const response = OpenFoodFactsSearchResponse.empty();

      expect(response.products, isEmpty);
      expect(response.count, 0);
      expect(response.hasMore, false);
    });
  });

  group('OpenFoodFactsService', () {
    test('puede instanciarse sin parámetros', () {
      final service = OpenFoodFactsService();
      expect(service, isNotNull);
      addTearDown(service.dispose);
    });

    test('puede instanciarse con cliente personalizado', () {
      final service = OpenFoodFactsService(
        timeout: const Duration(seconds: 5),
      );
      expect(service, isNotNull);
      addTearDown(service.dispose);
    });
  });
}
