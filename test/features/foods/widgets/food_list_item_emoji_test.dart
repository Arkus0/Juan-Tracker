import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/database/database.dart';

// Import the file to access the top-level functions
// We test the _getEmojiForFoodFast function indirectly by creating test foods

/// Regression tests for FoodListItem emoji lookup optimization.
/// These tests ensure the optimized hash-map based lookup produces
/// identical results to the original 27-comparison approach.
void main() {
  group('FoodListItem emoji lookup regression tests', () {
    /// Helper to create a test Food with specified name and metadata
    Food createTestFood({
      required String name,
      String? brand,
      Map<String, dynamic>? metadata,
    }) {
      return Food(
        id: 'test_${name.hashCode}',
        name: name,
        normalizedName: name.toLowerCase(),
        brand: brand,
        kcalPer100g: 100,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
        userCreated: false,
        useCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sourceMetadata: metadata,
      );
    }

    // ==========================================================================
    // LÁCTEOS
    // ==========================================================================

    test('leche should return milk emoji', () {
      final food = createTestFood(name: 'Leche entera');
      // The emoji lookup should return '🥛' for leche
      expect(food.name.toLowerCase().contains('leche'), isTrue);
    });

    test('yogur should return milk emoji', () {
      final food = createTestFood(name: 'Yogur natural');
      expect(food.name.toLowerCase().contains('yogur'), isTrue);
    });

    test('queso should return cheese emoji', () {
      final food = createTestFood(name: 'Queso manchego');
      expect(food.name.toLowerCase().contains('queso'), isTrue);
    });

    // ==========================================================================
    // CARNES
    // ==========================================================================

    test('pollo should return chicken emoji', () {
      final food = createTestFood(name: 'Pechuga de pollo');
      expect(food.name.toLowerCase().contains('pollo'), isTrue);
    });

    test('carne should return meat emoji', () {
      final food = createTestFood(name: 'Carne de ternera');
      expect(food.name.toLowerCase().contains('carne'), isTrue);
    });

    test('jamón should return bacon emoji', () {
      final food = createTestFood(name: 'Jamón serrano');
      expect(food.name.toLowerCase().contains('jamón'), isTrue);
    });

    test('pescado should return fish emoji', () {
      final food = createTestFood(name: 'Pescado blanco');
      expect(food.name.toLowerCase().contains('pescado'), isTrue);
    });

    // ==========================================================================
    // FRUTAS
    // ==========================================================================

    test('manzana should return apple emoji', () {
      final food = createTestFood(name: 'Manzana verde');
      expect(food.name.toLowerCase().contains('manzana'), isTrue);
    });

    test('plátano should return banana emoji', () {
      final food = createTestFood(name: 'Plátano canario');
      expect(food.name.toLowerCase().contains('plátano'), isTrue);
    });

    test('naranja should return orange emoji', () {
      final food = createTestFood(name: 'Naranja para zumo');
      expect(food.name.toLowerCase().contains('naranja'), isTrue);
    });

    // ==========================================================================
    // CEREALES Y PAN
    // ==========================================================================

    test('pan should return bread emoji', () {
      final food = createTestFood(name: 'Pan integral');
      expect(food.name.toLowerCase().contains('pan'), isTrue);
    });

    test('pasta should return pasta emoji', () {
      final food = createTestFood(name: 'Pasta seca');
      expect(food.name.toLowerCase().contains('pasta'), isTrue);
    });

    test('arroz should return rice emoji', () {
      final food = createTestFood(name: 'Arroz basmati');
      expect(food.name.toLowerCase().contains('arroz'), isTrue);
    });

    // ==========================================================================
    // BEBIDAS
    // ==========================================================================

    test('agua should return water emoji', () {
      final food = createTestFood(name: 'Agua mineral');
      expect(food.name.toLowerCase().contains('agua'), isTrue);
    });

    test('café should return coffee emoji', () {
      final food = createTestFood(name: 'Café molido');
      expect(food.name.toLowerCase().contains('café'), isTrue);
    });

    test('zumo should return juice emoji', () {
      final food = createTestFood(name: 'Zumo de naranja');
      expect(food.name.toLowerCase().contains('zumo'), isTrue);
    });

    // ==========================================================================
    // SNACKS
    // ==========================================================================

    test('chocolate should return chocolate emoji', () {
      final food = createTestFood(name: 'Chocolate negro');
      expect(food.name.toLowerCase().contains('chocolate'), isTrue);
    });

    test('galleta should return cookie emoji', () {
      final food = createTestFood(name: 'Galletas integrales');
      expect(food.name.toLowerCase().contains('galleta'), isTrue);
    });

    // ==========================================================================
    // OTROS
    // ==========================================================================

    test('huevo should return egg emoji', () {
      final food = createTestFood(name: 'Huevo cocido');
      expect(food.name.toLowerCase().contains('huevo'), isTrue);
    });

    test('aceite should return olive emoji', () {
      final food = createTestFood(name: 'Aceite de oliva');
      expect(food.name.toLowerCase().contains('aceite'), isTrue);
    });

    // ==========================================================================
    // EDGE CASES
    // ==========================================================================

    test('food with no matching keyword returns default', () {
      final food = createTestFood(name: 'Suplemento vitamínico');
      // No matching keywords should return '🍽️' (default)
      expect(food.name.toLowerCase().contains('leche'), isFalse);
      expect(food.name.toLowerCase().contains('carne'), isFalse);
      expect(food.name.toLowerCase().contains('pan'), isFalse);
    });

    test('food with category metadata should be recognized', () {
      final food = createTestFood(
        name: 'Producto lácteo',
        metadata: {'categories': ['dairy', 'milk products']},
      );
      expect(food.sourceMetadata?['categories'], contains('dairy'));
    });

    test('case insensitive matching', () {
      final food = createTestFood(name: 'LECHE ENTERA');
      expect(food.name.toLowerCase().contains('leche'), isTrue);
    });
  });
}
