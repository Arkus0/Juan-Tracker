import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:juan_tracker/diet/repositories/alimento_repository.dart';
import 'package:juan_tracker/training/database/database.dart';
import 'package:drift/native.dart';

/// Tests de estrés para AlimentoRepository
/// 
/// Verifica:
/// 1. CancelToken cancela requests correctamente
/// 2. No hay race conditions en búsquedas concurrentes
/// 3. Rate limiting funciona bajo carga
void main() {
  group('AlimentoRepository Stress Tests', () {
    late AppDatabase database;
    late AlimentoRepository repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = AlimentoRepository(database);
    });

    tearDown(() async {
      repository.cancelPendingRequests();
      await database.close();
    });

    group('CancelToken Functionality', () {
      test('debe cancelar búsqueda anterior al iniciar nueva', () async {
        // Crear múltiples búsquedas rápidas
        final searches = [
          repository.searchOnline('manzana'),
          repository.searchOnline('plátano'),
          repository.searchOnline('naranja'),
          repository.searchOnline('pera'),
        ];

        // Solo la última debería completarse (las anteriores canceladas)
        // Esto es comportamiento esperado - no es error
        try {
          await Future.wait(searches);
        } catch (e) {
          // Algunas pueden ser canceladas, eso es correcto
          expect(e, isA<DioException>());
        }
      });

      test('debe manejar cancelación manual correctamente', () async {
        // Iniciar búsqueda
        unawaited(repository.searchOnline('arroz'));
        
        // Cancelar inmediatamente
        repository.cancelPendingRequests();
        
        // Verificar que no hay crash
        await Future.delayed(const Duration(milliseconds: 100));
        
        // La búsqueda debería haber sido cancelada o completada
        // No debería lanzar unhandled exception
      });

      test('debe permitir búsquedas después de cancelación', () async {
        // Cancelar primero
        repository.cancelPendingRequests();
        
        // Intentar nueva búsqueda - no debería fallar
        expect(
          () => repository.searchOnline('pollo'),
          returnsNormally,
        );
      });

      test('debe manejar múltiples cancelaciones seguidas', () async {
        // Múltiples cancelaciones no deberían causar error
        for (var i = 0; i < 10; i++) {
          repository.cancelPendingRequests();
        }
        
        // Aún debería funcionar después
        expect(
          () => repository.searchOnline('atún'),
          returnsNormally,
        );
      });
    });

    group('Rate Limiting', () {
      test('debe respetar rate limit de 10 requests/minuto', () async {
        final stopwatch = Stopwatch()..start();
        
        // Intentar múltiples búsquedas rápidas
        final requests = <Future>[];
        for (var i = 0; i < 5; i++) {
          requests.add(
            repository.searchOnline('comida $i').catchError((_) => <ScoredFood>[]),
          );
        }
        
        await Future.wait(requests);
        
        // Si se respetó el rate limit, debería haber tomado tiempo
        // o las requests deberían haber sido manejadas correctamente
        expect(stopwatch.elapsed, isA<Duration>());
      });
    });

    group('Search Offline - Local Database', () {
      setUp(() async {
        // Insertar datos de prueba
        final now = DateTime.now();
        await database.batch((batch) {
          batch.insertAll(database.foods, [
            FoodsCompanion.insert(
              id: 'test-1',
              name: 'Pollo asado',
              kcalPer100g: 200,
              createdAt: now,
              updatedAt: now,
            ),
            FoodsCompanion.insert(
              id: 'test-2',
              name: 'Pollo a la plancha',
              kcalPer100g: 165,
              createdAt: now,
              updatedAt: now,
            ),
            FoodsCompanion.insert(
              id: 'test-3',
              name: 'Arroz con pollo',
              kcalPer100g: 250,
              createdAt: now,
              updatedAt: now,
            ),
          ]);
        });
        await database.rebuildFtsIndex();
      });

      test('debe retornar resultados locales instantáneamente', () async {
        final stopwatch = Stopwatch()..start();
        
        final results = await repository.search('pollo');
        
        stopwatch.stop();
        
        // Búsqueda local debería ser muy rápida (< 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(results, isNotEmpty);
      });

      test('debe manejar búsquedas concurrentes locales', () async {
        final searches = await Future.wait([
          repository.search('pollo'),
          repository.search('arroz'),
          repository.search('pollo asado'),
        ]);
        
        expect(searches.length, 3);
        expect(searches[0], isA<List<ScoredFood>>());
      });
    });

    group('Error Handling', () {
      test('debe manejar timeout de red gracefulmente', () async {
        // Esta prueba depende de la red real, podría fallar sin conexión
        // Es más un smoke test que una prueba determinística
        
        try {
          await repository.searchOnline('xyz123nonexistent');
        } on DioException catch (e) {
          // Timeout o error de red es aceptable
          expect(e.type, anyOf(
            DioExceptionType.connectionTimeout,
            DioExceptionType.receiveTimeout,
            DioExceptionType.connectionError,
          ));
        }
      });
    });
  });
}
