import 'package:flutter_test/flutter_test.dart';

// ============================================================================
// PERF: Regression tests for pre-compiled regex patterns
// These tests ensure the optimized regex patterns produce identical results
// to the original inline RegExp patterns.
// ============================================================================

/// Voice input: matches amounts like "200g", "200 gramos", "150ml"
/// NOTA: Alternativas ordenadas de mayor a menor longitud para evitar matches parciales
final _voiceAmountRegex = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(gramos|gr|g|mililitros|ml|litros|l)?',
  caseSensitive: false,
);

/// Voice input: removes leading prepositions like "de " or "d'"
final _voicePrepositionRegex = RegExp(r"^(de\s+|d')", caseSensitive: false);

/// OCR: matches calorie values like "250 kcal" or "1000 kJ"
final _ocrKcalRegex = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(kcal|kJ)',
  caseSensitive: false,
);

/// OCR: matches protein values
final _ocrProteinRegex = RegExp(
  r'prote[ií]nas?[:\s]*(\d+(?:[.,]\d+)?)',
  caseSensitive: false,
);

/// OCR: matches carbohydrate values
final _ocrCarbsRegex = RegExp(
  r'(carbohidratos?|hidratos?|carbs?)[:\s]*(\d+(?:[.,]\d+)?)',
  caseSensitive: false,
);

/// OCR: matches fat values (permite palabras intermedias como "total", "saturadas")
final _ocrFatRegex = RegExp(
  r'(grasas?|l[ií]pidos?)[:\s]*(?:[a-zA-Z]+\s*)*(\d+(?:[.,]\d+)?)',
  caseSensitive: false,
);

/// OCR: identifies lines that are just numbers (barcodes, etc.)
final _ocrDigitsOnlyRegex = RegExp(r'^\d+$');

void main() {
  group('Voice input regex regression tests', () {
    // ==========================================================================
    // AMOUNT EXTRACTION
    // ==========================================================================

    test('extracts grams with "g" suffix', () {
      final match = _voiceAmountRegex.firstMatch('200g de pollo');
      expect(match, isNotNull);
      expect(match!.group(1), '200');
      expect(match.group(2), 'g');
    });

    test('extracts grams with "gramos" suffix', () {
      final match = _voiceAmountRegex.firstMatch('200 gramos de arroz');
      expect(match, isNotNull);
      expect(match!.group(1), '200');
      expect(match.group(2), 'gramos');
    });

    test('extracts decimal amounts', () {
      final match = _voiceAmountRegex.firstMatch('100,5g de queso');
      expect(match, isNotNull);
      expect(match!.group(1), '100,5');
    });

    test('extracts milliliters', () {
      final match = _voiceAmountRegex.firstMatch('250ml de leche');
      expect(match, isNotNull);
      expect(match!.group(1), '250');
      expect(match.group(2), 'ml');
    });

    test('extracts number without unit', () {
      final match = _voiceAmountRegex.firstMatch('2 huevos');
      expect(match, isNotNull);
      expect(match!.group(1), '2');
    });

    // ==========================================================================
    // PREPOSITION REMOVAL
    // ==========================================================================

    test('removes "de " preposition', () {
      final result = 'de pollo'.replaceFirst(_voicePrepositionRegex, '');
      expect(result, 'pollo');
    });

    test("removes \"d'\" preposition (Catalan)", () {
      final result = "d'ou".replaceFirst(_voicePrepositionRegex, '');
      expect(result, 'ou');
    });

    test('preserves text without preposition', () {
      final result = 'pollo'.replaceFirst(_voicePrepositionRegex, '');
      expect(result, 'pollo');
    });
  });

  group('OCR regex regression tests', () {
    // ==========================================================================
    // CALORIE EXTRACTION
    // ==========================================================================

    test('extracts kcal value', () {
      final match = _ocrKcalRegex.firstMatch('Energía: 250 kcal');
      expect(match, isNotNull);
      expect(match!.group(1), '250');
      expect(match.group(2), 'kcal');
    });

    test('extracts kJ value', () {
      final match = _ocrKcalRegex.firstMatch('Energía: 1046 kJ');
      expect(match, isNotNull);
      expect(match!.group(1), '1046');
      expect(match.group(2), 'kJ');
    });

    test('extracts decimal calorie value', () {
      final match = _ocrKcalRegex.firstMatch('Por 100g: 89,5 kcal');
      expect(match, isNotNull);
      expect(match!.group(1), '89,5');
    });

    // ==========================================================================
    // PROTEIN EXTRACTION
    // ==========================================================================

    test('extracts "proteínas" with accent', () {
      final match = _ocrProteinRegex.firstMatch('Proteínas: 25g');
      expect(match, isNotNull);
      expect(match!.group(1), '25');
    });

    test('extracts "proteinas" without accent', () {
      final match = _ocrProteinRegex.firstMatch('Proteinas 20g');
      expect(match, isNotNull);
      expect(match!.group(1), '20');
    });

    test('extracts "proteína" singular', () {
      final match = _ocrProteinRegex.firstMatch('Proteína: 15,5');
      expect(match, isNotNull);
      expect(match!.group(1), '15,5');
    });

    // ==========================================================================
    // CARBOHYDRATE EXTRACTION
    // ==========================================================================

    test('extracts "carbohidratos"', () {
      final match = _ocrCarbsRegex.firstMatch('Carbohidratos: 45g');
      expect(match, isNotNull);
      expect(match!.group(2), '45');
    });

    test('extracts "hidratos"', () {
      final match = _ocrCarbsRegex.firstMatch('Hidratos 30');
      expect(match, isNotNull);
      expect(match!.group(2), '30');
    });

    test('extracts "carbs" (English)', () {
      final match = _ocrCarbsRegex.firstMatch('Carbs: 22,5');
      expect(match, isNotNull);
      expect(match!.group(2), '22,5');
    });

    // ==========================================================================
    // FAT EXTRACTION
    // ==========================================================================

    test('extracts "grasas"', () {
      final match = _ocrFatRegex.firstMatch('Grasas: 12g');
      expect(match, isNotNull);
      expect(match!.group(2), '12');
    });

    test('extracts "grasa" singular', () {
      final match = _ocrFatRegex.firstMatch('Grasa total 8,5');
      expect(match, isNotNull);
      expect(match!.group(2), '8,5');
    });

    test('extracts "lípidos"', () {
      final match = _ocrFatRegex.firstMatch('Lípidos: 15g');
      expect(match, isNotNull);
      expect(match!.group(2), '15');
    });

    // ==========================================================================
    // DIGIT-ONLY DETECTION
    // ==========================================================================

    test('identifies digit-only lines (barcodes)', () {
      expect(_ocrDigitsOnlyRegex.hasMatch('8410000810004'), isTrue);
      expect(_ocrDigitsOnlyRegex.hasMatch('123456'), isTrue);
    });

    test('rejects lines with text', () {
      expect(_ocrDigitsOnlyRegex.hasMatch('Producto 123'), isFalse);
      expect(_ocrDigitsOnlyRegex.hasMatch('123g'), isFalse);
    });

    // ==========================================================================
    // INTEGRATION: FULL OCR TEXT
    // ==========================================================================

    test('extracts all values from typical nutrition label', () {
      const ocrText = '''
INFORMACIÓN NUTRICIONAL
Por 100g:
Energía: 250 kcal
Proteínas: 12,5g
Carbohidratos: 45g
Grasas: 8g
''';

      final kcal = _ocrKcalRegex.firstMatch(ocrText)?.group(1);
      final protein = _ocrProteinRegex.firstMatch(ocrText)?.group(1);
      final carbs = _ocrCarbsRegex.firstMatch(ocrText)?.group(2);
      final fat = _ocrFatRegex.firstMatch(ocrText)?.group(2);

      expect(kcal, '250');
      expect(protein, '12,5');
      expect(carbs, '45');
      expect(fat, '8');
    });
  });
}
