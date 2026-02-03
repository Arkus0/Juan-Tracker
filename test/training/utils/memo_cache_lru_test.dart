import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/utils/performance_utils.dart';

/// Tests para verificar el comportamiento LRU de MemoCache
/// 
/// Verifica:
/// 1. Evicción LRU cuando se alcanza maxSize
/// 2. Actualización de timestamp en acceso
/// 3. Límites de memoria respetados
/// 4. Expiración de entradas
void main() {
  group('MemoCache LRU Tests', () {
    group('Basic LRU Behavior', () {
      test('debe evictar entrada LRU cuando se alcanza maxSize', () {
        final cache = MemoCache<String, String>(maxSize: 3);
        
        // Llenar cache
        cache.getOrCompute('key1', () => 'value1');
        cache.getOrCompute('key2', () => 'value2');
        cache.getOrCompute('key3', () => 'value3');
        
        // Verificar que están todas
        expect(cache.stats['size'], 3);
        
        // Acceder key1 para actualizar su LRU
        cache.getOrCompute('key1', () => 'should not compute');
        
        // Agregar key4 - debería evictar key2 (LRU)
        cache.getOrCompute('key4', () => 'value4');
        
        // Verificar tamaño
        expect(cache.stats['size'], 3);
        
        // key1 debería seguir ahí (fue accedido recientemente)
        var accessedKey1 = false;
        cache.getOrCompute('key1', () {
          accessedKey1 = true;
          return 'new value';
        });
        expect(accessedKey1, isFalse); // No debería recomputar
        
        // key2 debería haber sido evicted
        var recomputedKey2 = false;
        cache.getOrCompute('key2', () {
          recomputedKey2 = true;
          return 'new value2';
        });
        expect(recomputedKey2, isTrue); // Debería recomputar
      });

      test('debe actualizar LRU en cada acceso', () {
        final cache = MemoCache<String, String>(maxSize: 3);
        
        // Insertar en orden
        cache.getOrCompute('a', () => '1');
        cache.getOrCompute('b', () => '2');
        cache.getOrCompute('c', () => '3');
        
        // Acceder 'a' - ahora 'b' es LRU
        cache.getOrCompute('a', () => 'x');
        
        // Agregar 'd' - debería evictar 'b'
        cache.getOrCompute('d', () => '4');
        
        // 'a' debería existir
        expect(
          cache.getOrCompute('a', () => 'recomputed'),
          '1',
        );
        
        // 'b' debería haber sido evicted
        expect(
          cache.getOrCompute('b', () => 'recomputed'),
          'recomputed',
        );
      });
    });

    group('Memory Limits', () {
      test('nunca debe exceder maxSize', () {
        final cache = MemoCache<int, int>(maxSize: 10);
        
        // Insertar 100 items
        for (var i = 0; i < 100; i++) {
          cache.getOrCompute(i, () => i * 2);
        }
        
        // El tamaño debería estar limitado
        expect(cache.stats['size'], 10);
        expect(cache.stats['utilization'], '100.0%');
      });

      test('debe manejar maxSize = 1', () {
        final cache = MemoCache<String, String>(maxSize: 1);
        
        // Insertar 'a'
        expect(cache.getOrCompute('a', () => '1'), '1');
        expect(cache.stats['size'], 1);
        
        // Acceder 'a' nuevamente - cache hit
        expect(cache.getOrCompute('a', () => 'should-not-compute'), '1');
        
        // Insertar 'b' - evicta 'a'
        expect(cache.getOrCompute('b', () => '2'), '2');
        expect(cache.stats['size'], 1);
        
        // 'a' fue evicted, al acceder se recompute
        expect(cache.getOrCompute('a', () => 'recomputed-a'), 'recomputed-a');
        // Ahora 'a' está en cache, 'b' fue evicted
        
        // 'b' fue evicted, al acceder se recompute
        expect(cache.getOrCompute('b', () => 'recomputed-b'), 'recomputed-b');
      });

      test('debe manejar maxSize grande eficientemente', () {
        final cache = MemoCache<int, String>(maxSize: 1000);
        
        // Insertar 500 items
        for (var i = 0; i < 500; i++) {
          cache.getOrCompute(i, () => 'value $i');
        }
        
        expect(cache.stats['size'], 500);
        expect(cache.stats['utilization'], '50.0%');
      });
    });

    group('Expiration', () {
      test('debe expirar entradas después del tiempo especificado', () async {
        final cache = MemoCache<String, String>(
          expiration: const Duration(milliseconds: 100),
        );
        
        cache.getOrCompute('key', () => 'value');
        expect(
          cache.getOrCompute('key', () => 'new value'),
          'value',
        );
        
        // Esperar a que expire
        await Future.delayed(const Duration(milliseconds: 150));
        
        // Debería recomputar
        expect(
          cache.getOrCompute('key', () => 'new value'),
          'new value',
        );
      });

      test('debe mantener entradas no expiradas', () async {
        final cache = MemoCache<String, String>(
          expiration: const Duration(seconds: 1),
        );
        
        cache.getOrCompute('key1', () => 'value1');
        await Future.delayed(const Duration(milliseconds: 100));
        cache.getOrCompute('key2', () => 'value2');
        
        // Ambas deberían seguir válidas
        expect(
          cache.getOrCompute('key1', () => 'x'),
          'value1',
        );
        expect(
          cache.getOrCompute('key2', () => 'x'),
          'value2',
        );
      });
    });

    group('Invalidate and Clear', () {
      test('debe remover entrada específica', () {
        final cache = MemoCache<String, String>();
        
        cache.getOrCompute('a', () => '1');
        cache.getOrCompute('b', () => '2');
        
        cache.invalidate('a');
        
        expect(cache.stats['size'], 1);
        expect(
          cache.getOrCompute('a', () => 'recomputed'),
          'recomputed',
        );
      });

      test('debe limpiar todo el cache', () {
        final cache = MemoCache<String, String>(maxSize: 100);
        
        for (var i = 0; i < 50; i++) {
          cache.getOrCompute('key$i', () => 'value$i');
        }
        
        expect(cache.stats['size'], 50);
        
        cache.clear();
        
        expect(cache.stats['size'], 0);
        expect(cache.stats['utilization'], '0.0%');
      });
    });

    group('Edge Cases', () {
      test('debe manejar keys nulas o vacías', () {
        final cache = MemoCache<String?, String>();
        
        // Null key
        cache.getOrCompute(null, () => 'null value');
        expect(
          cache.getOrCompute(null, () => 'recomputed'),
          'null value',
        );
        
        // Empty key
        cache.getOrCompute('', () => 'empty value');
        expect(
          cache.getOrCompute('', () => 'recomputed'),
          'empty value',
        );
      });

      test('debe manejar valores complejos', () {
        final cache = MemoCache<String, Map<String, dynamic>>();
        
        final complexValue = {
          'nested': {
            'list': [1, 2, 3],
            'map': {'a': 'b'},
          },
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        cache.getOrCompute('complex', () => complexValue);
        
        expect(
          cache.getOrCompute('complex', () => {}),
          complexValue,
        );
      });

      test('debe evictar correctamente con patrón de acceso zigzag', () {
        final cache = MemoCache<String, String>(maxSize: 3);
        
        // Insertar A, B, C (orden de acceso: A -> B -> C)
        cache.getOrCompute('A', () => '1');
        cache.getOrCompute('B', () => '2');
        cache.getOrCompute('C', () => '3');
        
        // Acceso: A (A se vuelve más reciente, orden: B -> C -> A)
        expect(cache.getOrCompute('A', () => 'x'), '1');
        
        // Insertar D (evicta B - el LRU)
        expect(cache.getOrCompute('D', () => '4'), '4');
        
        // Cache ahora: C, A, D (B fue evicted)
        // Verificar B fue evicted
        expect(cache.getOrCompute('B', () => 'recomputed-b'), 'recomputed-b');
        
        // Cache ahora: A, D, B (C es LRU)
        // Acceso: C (lo vuelve a insertar, evicta A)
        expect(cache.getOrCompute('C', () => '3'), '3'); // Aún debería retornar '3' del compute anterior
        
        // Cache ahora: D, B, C
        // Insertar E (evicta D - el LRU)
        expect(cache.getOrCompute('E', () => '5'), '5');
        
        // Verificar estado final
        expect(cache.stats['size'], 3);
        
        // D fue evicted
        expect(cache.getOrCompute('D', () => 'recomputed-d'), 'recomputed-d');
        
        // C debería existir (fue accedido recientemente)
        expect(cache.getOrCompute('C', () => 'x'), '3');
        
        // E debería existir
        expect(cache.getOrCompute('E', () => 'x'), '5');
      });
    });

    group('Stats', () {
      test('debe reportar estadísticas correctas', () {
        final cache = MemoCache<String, String>(maxSize: 100);
        
        expect(cache.stats['size'], 0);
        expect(cache.stats['maxSize'], 100);
        expect(cache.stats['utilization'], '0.0%');
        
        for (var i = 0; i < 50; i++) {
          cache.getOrCompute('key$i', () => 'value');
        }
        
        expect(cache.stats['size'], 50);
        expect(cache.stats['utilization'], '50.0%');
      });
    });
  });
}
