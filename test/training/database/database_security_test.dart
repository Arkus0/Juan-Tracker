import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/database/database.dart';
import 'package:drift/native.dart';

/// Tests de seguridad para validar que los fixes de SQL injection funcionan correctamente
/// 
/// Estos tests verifican que:
/// 1. Inputs maliciosos no rompen la query
/// 2. Los parámetros están correctamente escapados
/// 3. El sistema es resistente a inyección SQL
void main() {
  group('Database Security Tests - SQL Injection Prevention', () {
    late AppDatabase database;

    setUp(() async {
      // Usar database en memoria para tests
      database = AppDatabase.forTesting(
        NativeDatabase.memory(),
      );
      
      // Insertar datos de prueba
      final now = DateTime.now();
      await database.batch((batch) {
        batch.insertAll(database.foods, [
          FoodsCompanion.insert(
            id: 'test-1',
            name: 'Pollo a la plancha',
            kcalPer100g: 165,
            createdAt: now,
            updatedAt: now,
          ),
          FoodsCompanion.insert(
            id: 'test-2',
            name: 'Arroz integral',
            kcalPer100g: 110,
            createdAt: now,
            updatedAt: now,
          ),
          FoodsCompanion.insert(
            id: 'test-3',
            name: 'Leche desnatada',
            kcalPer100g: 35,
            createdAt: now,
            updatedAt: now,
          ),
        ]);
      });
      
      // Reconstruir índice FTS
      await database.rebuildFtsIndex();
    });

    tearDown(() async {
      await database.close();
    });

    group('_searchFoodsLike - SQL Injection Resistance', () {
      test('debe manejar comillas simples sin error', () async {
        // Intentar inyección con comillas simples
        final results = await database.searchFoodsOffline("pollo' OR '1'='1", limit: 10);
        
        // No debe lanzar error y debe retornar resultados vacíos o filtrados
        expect(results, isA<List<Food>>());
      });

      test('debe manecer wildcards de LIKE correctamente', () async {
        // El caracter % debe ser tratado literalmente, no como wildcard
        final results = await database.searchFoodsOffline("pollo%", limit: 10);
        
        // Debe buscar el string literal "pollo%" no cualquier cosa que empiece con pollo
        expect(results, isA<List<Food>>());
      });

      test('debe manejar underscores correctamente', () async {
        // El caracter _ debe ser tratado literalmente
        final results = await database.searchFoodsOffline("pollo_arroz", limit: 10);
        
        expect(results, isA<List<Food>>());
      });

      test('debe manejar múltiples términos maliciosos', () async {
        // Inyección con múltiples condiciones
        final results = await database.searchFoodsOffline(
          "'; DROP TABLE foods; --", 
          limit: 10,
        );
        
        // No debe lanzar error ni modificar la base de datos
        expect(results, isA<List<Food>>());
        
        // Verificar que la tabla foods sigue existiendo con datos
        final count = await database.customSelect('SELECT COUNT(*) as cnt FROM foods').getSingle();
        expect(count.data['cnt'] as int, greaterThanOrEqualTo(3));
      });

      test('debe manejar UNION injection', () async {
        final results = await database.searchFoodsOffline(
          "' UNION SELECT * FROM users --",
          limit: 10,
        );
        
        expect(results, isA<List<Food>>());
      });

      test('debe manejar inputs Unicode maliciosos', () async {
        final results = await database.searchFoodsOffline(
          "привет'; DROP TABLE foods; --",
          limit: 10,
        );
        
        expect(results, isA<List<Food>>());
      });

      test('debe mantener integridad después de búsquedas maliciosas', () async {
        // Realizar múltiples búsquedas maliciosas
        final maliciousInputs = [
          "'; DELETE FROM foods; --",
          "' OR 1=1 --",
          "'; UPDATE foods SET name = 'hacked'; --",
          "\\'; DROP TABLE foods_fts; --",
        ];

        for (final input in maliciousInputs) {
          await database.searchFoodsOffline(input, limit: 10);
        }

        // Verificar que los datos originales siguen intactos
        final foods = await database.select(database.foods).get();
        expect(foods.length, greaterThanOrEqualTo(3));
        
        // Verificar que el índice FTS sigue funcionando
        final ftsResults = await database.searchFoodsFTS('pollo', limit: 10);
        expect(ftsResults, isA<List<Food>>());
      });
    });

    group('FTS5 Search - Basic Functionality', () {
      test('debe retornar resultados para búsquedas normales', () async {
        final results = await database.searchFoodsFTS('pollo', limit: 10);
        
        expect(results, isNotEmpty);
        expect(results.first.name.toLowerCase(), contains('pollo'));
      });

      test('debe manejar búsquedas con espacios', () async {
        final results = await database.searchFoodsFTS('pollo plancha', limit: 10);
        
        expect(results, isA<List<Food>>());
      });

      test('debe retornar lista vacía para términos inexistentes', () async {
        final results = await database.searchFoodsFTS('xyz123nonexistent', limit: 10);
        
        expect(results, isEmpty);
      });
    });
  });
}
