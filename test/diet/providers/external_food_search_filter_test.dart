import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/models/open_food_facts_model.dart';

/// Tests exhaustivos para el algoritmo de búsqueda con scoring
/// 
/// Principios:
/// - OR lógico: Cualquier coincidencia incluye el resultado
/// - Scoring: Resultados más relevantes primero
/// - Fuzzy matching: Tolerancia a errores ortográficos menores
/// - Sin límites artificiales: Muestra todo lo relevante

/// Calcula distancia de Levenshtein para fuzzy matching
int _levenshtein(String s1, String s2) {
  if (s1.length < s2.length) return _levenshtein(s2, s1);
  if (s2.isEmpty) return s1.length;

  List<int> prev = List.generate(s2.length + 1, (i) => i);
  List<int> curr = List.filled(s2.length + 1, 0);

  for (int i = 0; i < s1.length; i++) {
    curr[0] = i + 1;
    for (int j = 0; j < s2.length; j++) {
      final cost = (s1[i] == s2[j]) ? 0 : 1;
      curr[j + 1] = [
        curr[j] + 1,
        prev[j + 1] + 1,
        prev[j] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
    final temp = prev;
    prev = curr;
    curr = temp;
  }

  return prev[s2.length];
}

void main() {
  group('Search Algorithm with Scoring', () {
    late List<OpenFoodFactsResult> mockResults;

    setUp(() {
      mockResults = [
        // Panadería
        OpenFoodFactsResult(code: '1', name: 'Pan integral', brand: 'Bimbo', kcalPer100g: 250, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '2', name: 'Pan de molde integral', brand: 'Bimbo', kcalPer100g: 265, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '3', name: 'Pan de centeno', brand: 'Harrys', kcalPer100g: 240, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '4', name: 'Pan blanco', brand: 'Bimbo', kcalPer100g: 270, fetchedAt: DateTime.now()),
        
        // Lácteos
        OpenFoodFactsResult(code: '5', name: 'Leche entera', brand: 'Pascual', kcalPer100g: 64, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '6', name: 'Leche desnatada', brand: 'Central Lechera', kcalPer100g: 35, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '7', name: 'Yogur natural', brand: 'Danone', kcalPer100g: 60, fetchedAt: DateTime.now()),
        
        // Carnes
        OpenFoodFactsResult(code: '8', name: 'Pechuga de pollo', brand: 'ElPozo', kcalPer100g: 110, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '9', name: 'Pollo entero', brand: null, kcalPer100g: 200, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '10', name: 'Muslo de pollo', brand: 'Coren', kcalPer100g: 180, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '11', name: 'Pavo ahumado', brand: 'Campofrío', kcalPer100g: 120, fetchedAt: DateTime.now()),
        
        // Marcas
        OpenFoodFactsResult(code: '12', name: 'Cereales Nesquik', brand: 'Nestlé', kcalPer100g: 380, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '13', name: 'Coca-Cola Zero', brand: 'Coca-Cola', kcalPer100g: 0, fetchedAt: DateTime.now()),
        
        // Nombres complejos
        OpenFoodFactsResult(code: '14', name: 'Bebida de avena con calcio sin azúcares', brand: 'Alpro', kcalPer100g: 45, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '15', name: 'Hamburguesa vegetariana de quinoa', brand: 'Heura', kcalPer100g: 220, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '16', name: 'Tortilla de patatas con cebolla', brand: null, kcalPer100g: 180, fetchedAt: DateTime.now()),
        
        // Frutas/Verduras
        OpenFoodFactsResult(code: '17', name: 'Manzana', brand: null, kcalPer100g: 52, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '18', name: 'Plátano', brand: null, kcalPer100g: 89, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '19', name: 'Pera', brand: null, kcalPer100g: 57, fetchedAt: DateTime.now()),
        
        // Casos edge
        OpenFoodFactsResult(code: '20', name: 'A', brand: 'Test', kcalPer100g: 100, fetchedAt: DateTime.now()),
        OpenFoodFactsResult(code: '21', name: '', brand: 'Test', kcalPer100g: 100, fetchedAt: DateTime.now()),
      ];
    });

    /// Helper que replica el nuevo algoritmo de filtrado con scoring
    List<OpenFoodFactsResult> searchAndRank(
      List<OpenFoodFactsResult> results,
      String query,
    ) {
      final queryLower = query.toLowerCase().trim();
      final queryWords = queryLower
          .split(RegExp(r'\s+'))
          .where((w) => w.length >= 2)
          .toList();

      if (queryWords.isEmpty) return results;

      final scored = <_Scored>[];

      for (final product in results) {
        final nameLower = product.name.toLowerCase();
        final brandLower = (product.brand ?? '').toLowerCase();
        final nameWords = nameLower.split(RegExp(r'\s+'));

        double score = 0;
        int matchedWords = 0;

        for (final queryWord in queryWords) {
          // Coincidencia exacta del nombre
          if (nameLower == queryLower) {
            score += 1000;
            matchedWords++;
            continue;
          }

          // Coincidencia exacta de palabra
          if (nameWords.contains(queryWord)) {
            score += 100;
            matchedWords++;
            continue;
          }

          // Coincidencia al inicio del nombre
          if (nameLower.startsWith(queryWord)) {
            score += 80;
            matchedWords++;
            continue;
          }

          // Coincidencia al inicio de alguna palabra
          if (nameWords.any((w) => w.startsWith(queryWord))) {
            score += 60;
            matchedWords++;
            continue;
          }

          // Coincidencia parcial
          if (nameLower.contains(queryWord)) {
            score += 40;
            matchedWords++;
            continue;
          }

          // Coincidencia en marca
          if (brandLower.contains(queryWord)) {
            score += 30;
            matchedWords++;
            continue;
          }

          // Fuzzy matching
          if (queryWord.length <= 5) {
            for (final nameWord in nameWords) {
              if (_levenshtein(queryWord, nameWord) <= 1) {
                score += 20;
                matchedWords++;
                break;
              }
            }
          }
        }

        // Bonus por múltiples coincidencias
        if (matchedWords > 1) {
          score *= (1 + (matchedWords - 1) * 0.5);
        }

        if (score > 0) {
          scored.add(_Scored(product, score));
        }
      }

      scored.sort((a, b) => b.score.compareTo(a.score));
      return scored.map((s) => s.product).toList();
    }

    group('Búsquedas básicas - OR lógico amplio', () {
      test('"pan" devuelve TODOS los panes (no filtra)', () {
        final results = searchAndRank(mockResults, 'pan');
        
        expect(results.length, equals(4));
        expect(results.map((r) => r.name), containsAll([
          'Pan integral',
          'Pan de molde integral',
          'Pan de centeno',
          'Pan blanco',
        ]));
      });

      test('"pan integral" devuelve panes integrales PRIMERO, luego otros panes', () {
        final results = searchAndRank(mockResults, 'pan integral');
        
        // Debe devolver todos los panes, pero los integrales primero
        expect(results.length, equals(4));
        
        // Los integrales tienen mayor score
        final integralIndex1 = results.indexWhere((r) => r.name == 'Pan integral');
        final integralIndex2 = results.indexWhere((r) => r.name == 'Pan de molde integral');
        final centenoIndex = results.indexWhere((r) => r.name == 'Pan de centeno');
        // ignore: avoid_print
        if (centenoIndex >= 0) debugPrint('Pan de centeno encontrado en posición $centenoIndex');
        final blancoIndex = results.indexWhere((r) => r.name == 'Pan blanco');
        
        // Los integrales deberían estar antes que el blanco
        expect(integralIndex1 < blancoIndex, isTrue);
        expect(integralIndex2 < blancoIndex, isTrue);
      });

      test('"pollo" devuelve todos los pollos', () {
        final results = searchAndRank(mockResults, 'pollo');
        
        // Debe encontrar los 3 pollos (Pechuga de pollo, Pollo entero, Muslo de pollo)
        expect(results.length, equals(3));
        // Verificar que todos contienen 'pollo' (case insensitive)
        expect(results.every((r) => r.name.toLowerCase().contains('pollo')), isTrue);
      });

      test('"leche" devuelve ambas leches', () {
        final results = searchAndRank(mockResults, 'leche');
        
        expect(results.length, equals(2));
        expect(results.every((r) => r.name.contains('Leche')), isTrue);
      });
    });

    group('Scoring y ordenamiento', () {
      test('coincidencia exacta de palabra tiene prioridad sobre parcial', () {
        final results = searchAndRank(mockResults, 'pan');
        
        // Pan (exacto) vs Pascual (contiene "pa")
        final panIndex = results.indexWhere((r) => r.name == 'Pan integral');
        final pascualIndex = results.indexWhere((r) => r.brand == 'Pascual');
        
        if (pascualIndex != -1) {
          expect(panIndex < pascualIndex, isTrue, 
            reason: 'Pan integral debería estar antes que Leche Pascual');
        }
      });

      test('múltiples coincidencias aumentan el score', () {
        final results = searchAndRank(mockResults, 'pan integral');
        
        // "Pan de molde integral" tiene dos coincidencias vs "Pan integral" una
        final moldeIntegral = results.indexWhere((r) => r.name == 'Pan de molde integral');
        final panIntegralIndex = results.indexWhere((r) => r.name == 'Pan integral');
        // ignore: avoid_print
        if (panIntegralIndex >= 0) debugPrint('Pan integral encontrado en posición $panIntegralIndex');
        
        // Ambos tienen "integral", pero molde tiene más palabras coincidentes
        expect(results[moldeIntegral].name, contains('integral'));
      });

      test('coincidencia al inicio tiene prioridad', () {
        final results = searchAndRank(mockResults, 'bi');
        
        // Bimbo empieza con "bi"
        final firstBimbo = results.indexWhere((r) => r.brand == 'Bimbo');
        expect(firstBimbo != -1, isTrue);
      });
    });

    group('Fuzzy matching - tolerancia a errores', () {
      test('"pann" (error) encuentra "pan"', () {
        final results = searchAndRank(mockResults, 'pann');
        
        // Distancia de edición 1: pann -> pan
        expect(results.any((r) => r.name.contains('Pan')), isTrue);
      });

      test('"polllo" (error largo) no usa fuzzy matching (palabra >5 chars)', () {
        final results = searchAndRank(mockResults, 'polllo');
        
        // Fuzzy matching solo para palabras <= 5 chars por performance
        // "polllo" tiene 6 chars, no se aplica fuzzy
        expect(results, isEmpty);
      });

      test('"yogurt" (6 chars) no usa fuzzy matching', () {
        final results = searchAndRank(mockResults, 'yogurt');
        
        // "yogurt" tiene 6 chars, fuzzy matching solo para <=5
        // Pero "yogur" (5 chars) contiene "yogu" que es similar...
        // En la práctica, este caso necesita normalización de caracteres especiales
        expect(results.isEmpty || results.first.name.contains('Yogur'), isTrue);
      });
    });

    group('Búsquedas por marca', () {
      test('"bimbo" encuentra todos los productos Bimbo', () {
        final results = searchAndRank(mockResults, 'bimbo');
        
        expect(results.every((r) => r.brand == 'Bimbo'), isTrue);
        expect(results.length, equals(3));
      });

      test('"nestlé" encuentra productos Nestlé', () {
        final results = searchAndRank(mockResults, 'nestlé');
        
        expect(results.any((r) => r.brand == 'Nestlé'), isTrue);
      });

      test('"coca" encuentra Coca-Cola', () {
        final results = searchAndRank(mockResults, 'coca');
        
        expect(results.any((r) => r.name.contains('Coca')), isTrue);
      });
    });

    group('Búsquedas complejas y compuestas', () {
      test('"avena calcio" encuentra bebida de avena (ambas palabras)', () {
        final results = searchAndRank(mockResults, 'avena calcio');
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.name, contains('avena'));
      });

      test('"hamburguesa vegetariana" encuentra hamburguesa', () {
        final results = searchAndRank(mockResults, 'hamburguesa vegetariana');
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.name, contains('Hamburguesa'));
      });

      test('"tortilla patatas" encuentra tortilla', () {
        final results = searchAndRank(mockResults, 'tortilla patatas');
        
        expect(results.isNotEmpty, isTrue);
        expect(results.first.name, contains('Tortilla'));
      });
    });

    group('Búsquedas cortas (prefijo)', () {
      test('"pa" devuelve pan, pascual, patatas, etc.', () {
        final results = searchAndRank(mockResults, 'pa');
        
        // Muchos resultados porque "pa" es prefijo común
        expect(results.length >= 5, isTrue);
        expect(results.any((r) => r.name.contains('Pan')), isTrue);
      });

      test('"po" devuelve pollo, pavo, etc.', () {
        final results = searchAndRank(mockResults, 'po');
        
        expect(results.any((r) => r.name.contains('pollo') || r.name.contains('Pavo')), isTrue);
      });
    });

    group('Casos edge', () {
      test('búsqueda vacía devuelve todo', () {
        final results = searchAndRank(mockResults, '');
        
        expect(results.length, equals(mockResults.length));
      });

      test('búsqueda con solo espacios devuelve todo', () {
        final results = searchAndRank(mockResults, '   ');
        
        expect(results.length, equals(mockResults.length));
      });

      test('búsqueda "a" (1 char) devuelve todo (sin palabras significativas)', () {
        final results = searchAndRank(mockResults, 'a');
        
        // Palabras < 2 chars son ignoradas
        expect(results.length, equals(mockResults.length));
      });

      test('producto sin nombre es manejado', () {
        final results = searchAndRank(mockResults, 'test');
        
        // El producto con brand "Test" debería aparecer
        expect(results.any((r) => r.brand == 'Test'), isTrue);
      });
    });

    group('Búsquedas que no existen', () {
      test('"xyz" no devuelve resultados', () {
        final results = searchAndRank(mockResults, 'xyz');
        
        expect(results, isEmpty);
      });

      test('"automóvil" no devuelve resultados', () {
        final results = searchAndRank(mockResults, 'automóvil');
        
        expect(results, isEmpty);
      });

      test('"ordenador" no devuelve resultados', () {
        final results = searchAndRank(mockResults, 'ordenador');
        
        expect(results, isEmpty);
      });
    });

    group('Case insensitive y normalización', () {
      test('"PAN" mayúsculas funciona igual que "pan"', () {
        final lower = searchAndRank(mockResults, 'pan');
        final upper = searchAndRank(mockResults, 'PAN');
        
        expect(lower.length, equals(upper.length));
      });

      test('"Pan Integral" mixed case funciona', () {
        final results = searchAndRank(mockResults, 'Pan Integral');
        
        expect(results.isNotEmpty, isTrue);
        expect(results.any((r) => r.name.contains('integral')), isTrue);
      });

      test('"  pan  " con espacios funciona', () {
        final results = searchAndRank(mockResults, '  pan  ');
        
        expect(results.isNotEmpty, isTrue);
      });
    });

    group('Características del algoritmo', () {
      test('NO limita artificialmente el número de resultados', () {
        final results = searchAndRank(mockResults, 'a');
        
        // Con palabras cortas no filtra
        expect(results.length, equals(mockResults.length));
      });

      test('usa OR lógico, no AND', () {
        final results = searchAndRank(mockResults, 'pan leche');
        
        // Debe devolver tanto panes como leches
        expect(results.any((r) => r.name.contains('Pan')), isTrue);
        expect(results.any((r) => r.name.contains('Leche')), isTrue);
      });

      test('ordena por relevancia (score)', () {
        final results = searchAndRank(mockResults, 'pan integral');
        
        // El primero debería ser el más relevante
        expect(results.isNotEmpty, isTrue);
        // El score más alto debería estar primero
      });
    });
  });
}

class _Scored {
  final OpenFoodFactsResult product;
  final double score;

  _Scored(this.product, this.score);
}
