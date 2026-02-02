import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/utils/spanish_text_utils.dart';

void main() {
  group('Sinónimos de Alimentos', () {
    test('encuentra sinónimos de desnatada/descremada', () {
      final synonyms = getSynonyms('desnatada');
      expect(synonyms, contains('descremada'));
      expect(synonyms, contains('desnatada'));
      expect(synonyms, contains('0% grasa'));
    });

    test('encuentra sinónimos de patata/papa', () {
      final synonyms = getSynonyms('patata');
      expect(synonyms, contains('papa'));
      expect(synonyms, contains('patatas'));
    });

    test('encuentra sinónimos de plátano/banana', () {
      final synonyms = getSynonyms('plátano');
      expect(synonyms, contains('banana'));
      expect(synonyms, contains('banano'));
    });

    test('encuentra sinónimos de judías verdes', () {
      final synonyms = getSynonyms('judías verdes');
      expect(synonyms, contains('ejotes'));
      expect(synonyms, contains('habichuelas verdes'));
    });

    test('retorna solo el término si no hay sinónimos', () {
      final synonyms = getSynonyms('xyznotexists');
      expect(synonyms, equals({'xyznotexists'}));
    });

    test('es case-insensitive', () {
      final lowerSynonyms = getSynonyms('desnatada');
      final upperSynonyms = getSynonyms('DESNATADA');
      expect(lowerSynonyms, equals(upperSynonyms));
    });
  });

  group('Expansión de Query con Sinónimos', () {
    test('expande término simple con sinónimos', () {
      final expanded = expandQueryWithSynonyms('desnatada');
      // Debe contener términos con OR
      expect(expanded, contains('desnatada'));
      expect(expanded, contains('descremada'));
      expect(expanded, contains('OR'));
    });

    test('expande múltiples términos', () {
      final expanded = expandQueryWithSynonyms('leche desnatada');
      // Debería tener todos los términos con OR
      expect(expanded, contains('leche'));
      expect(expanded, contains('desnatada'));
      expect(expanded, contains('OR'));
    });

    test('término sin sinónimos solo tiene wildcard', () {
      final expanded = expandQueryWithSynonyms('proteina');
      expect(expanded, equals('proteina*'));
    });

    test('ignora términos de 1 caracter', () {
      final expanded = expandQueryWithSynonyms('a y o');
      expect(expanded, isEmpty);
    });
    
    test('incluye términos de 2+ caracteres', () {
      // "de" y "la" tienen 2 caracteres, se incluyen como OR
      final expanded = expandQueryWithSynonyms('de la');
      expect(expanded, contains('de*'));
      expect(expanded, contains('la*'));
      expect(expanded, contains('OR'));
    });
    
    test('no incluye sinónimos multi-palabra', () {
      // "0% grasa" tiene espacio, no debe incluirse
      final expanded = expandQueryWithSynonyms('desnatada');
      expect(expanded, isNot(contains('0%')));
      expect(expanded, isNot(contains('grasa')));
    });
  });

  group('Stemming Español', () {
    test('reduce plurales simples -s', () {
      expect(stemSpanish('manzanas'), equals('manzana'));
      expect(stemSpanish('naranjas'), equals('naranja'));
    });

    test('reduce plurales -es', () {
      expect(stemSpanish('tomates'), equals('tomat'));
    });

    test('no hace stemming en palabras cortas', () {
      expect(stemSpanish('pan'), equals('pan'));
      expect(stemSpanish('sal'), equals('sal'));
    });

    test('respeta excepciones', () {
      expect(stemSpanish('huevos'), equals('huevo'));
      expect(stemSpanish('nueces'), equals('nuez'));
      expect(stemSpanish('panes'), equals('pan'));
    });

    test('no modifica stopwords', () {
      expect(stemSpanish('gramos'), equals('gramos'));
      expect(stemSpanish('de'), equals('de'));
    });

    test('stemQuery procesa múltiples palabras', () {
      final stems = stemQuery('manzanas rojas');
      expect(stems, contains('manzana'));
      expect(stems, contains('roja'));
    });
  });

  group('Normalización de Texto', () {
    test('convierte a minúsculas', () {
      expect(normalizeText('POLLO'), equals('pollo'));
    });

    test('remueve acentos', () {
      expect(normalizeText('plátano'), equals('platano'));
      expect(normalizeText('jamón'), equals('jamon'));
      expect(normalizeText('café'), equals('cafe'));
    });

    test('remueve caracteres especiales', () {
      expect(normalizeText('pollo (100g)'), equals('pollo 100g'));
      expect(normalizeText('leche-desnatada'), equals('leche desnatada'));
    });

    test('normaliza espacios múltiples', () {
      expect(normalizeText('pollo   asado'), equals('pollo asado'));
    });
  });

  group('EnhancedQuery', () {
    test('procesa query completa correctamente', () {
      final enhanced = enhanceQuery('leche desnatada');
      
      expect(enhanced.original, equals('leche desnatada'));
      expect(enhanced.withSynonyms, contains('OR'));
      expect(enhanced.stemmedTerms, isNotEmpty);
    });

    test('query con acentos se normaliza', () {
      final enhanced = enhanceQuery('plátano');
      
      expect(enhanced.original, equals('platano'));
    });

    test('query simple sin sinónimos', () {
      final enhanced = enhanceQuery('proteina');
      
      expect(enhanced.original, equals('proteina'));
      expect(enhanced.withSynonyms, equals('proteina*'));
    });
  });

  group('Casos de Uso Reales', () {
    test('búsqueda de leche funciona con variantes', () {
      // Usuario busca "leche descremada" pero DB tiene "leche desnatada"
      final enhanced = enhanceQuery('leche descremada');
      
      // El query expandido debe incluir "desnatada"
      expect(enhanced.withSynonyms.toLowerCase(), contains('desnatada'));
    });

    test('búsqueda de patatas funciona con "papas"', () {
      final enhanced = enhanceQuery('papas fritas');
      
      expect(enhanced.withSynonyms.toLowerCase(), contains('patata'));
    });

    test('búsqueda con plurales', () {
      // Usuario busca "manzana" pero DB tiene "manzanas"
      final enhanced = enhanceQuery('manzana');
      
      // El stemming debería ayudar a matchear
      expect(enhanced.stemmedTerms, contains('manzan'));
    });

    test('búsqueda de frutas latinoamericanas', () {
      final enhanced = enhanceQuery('banana');
      
      expect(enhanced.withSynonyms.toLowerCase(), contains('plátano'));
    });
  });
}
