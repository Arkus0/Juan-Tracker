import 'package:logger/logger.dart';

/// Servicio para parsear texto OCR de etiquetas nutricionales
/// y extraer valores de macros
class FoodLabelParserService {
  static final FoodLabelParserService instance = FoodLabelParserService._();
  FoodLabelParserService._();

  final _logger = Logger();

  /// Patrones comunes en etiquetas nutricionales (español e inglés)
  final Map<String, List<RegExp>> _patterns = {
    'energy': [
      RegExp(r'(?:valor\s+)?energ[íi]a[\s:]*([0-9]+)[\s\.]*(?:kcal|cal)', caseSensitive: false),
      RegExp(r'energy[\s:]*([0-9]+)[\s\.]*(?:kcal|cal)', caseSensitive: false),
      RegExp(r'([0-9]+)[\s\.]*(?:kcal|cal)', caseSensitive: false),
    ],
    'protein': [
      RegExp(r'prote[íi]nas?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'protein[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'prot\.?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
    ],
    'carbs': [
      RegExp(r'(?:hidratos?\s+de\s+)?carbono|carbohidratos?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'carbohydrates?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'carbs?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'of\s+which\s+sugars?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'de\s+los\s+cuales\s+az[úu]cares?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
    ],
    'fat': [
      RegExp(r'grasas?\s*(?:totales?)?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'(?:total\s+)?fat[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'lipidos?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
    ],
    'saturatedFat': [
      RegExp(r'grasas?\s*saturadas?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'saturated\s*fat[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
    ],
    'fiber': [
      RegExp(r'fibra[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
      RegExp(r'fibre?[\s:]*([0-9]+[\.,]?[0-9]*)\s*g', caseSensitive: false),
    ],
    'sodium': [
      RegExp(r'sodio[\s:]*([0-9]+[\.,]?[0-9]*)\s*(?:mg|g)', caseSensitive: false),
      RegExp(r'sodium[\s:]*([0-9]+[\.,]?[0-9]*)\s*(?:mg|g)', caseSensitive: false),
    ],
    'servingSize': [
      RegExp(r'porci[oó]n[\s:]*([0-9]+[\.,]?[0-9]*)\s*(?:g|ml)', caseSensitive: false),
      RegExp(r'serving\s*size[\s:]*([0-9]+[\.,]?[0-9]*)\s*(?:g|ml)', caseSensitive: false),
      RegExp(r'(?:por|per)\s*([0-9]+[\.,]?[0-9]*)\s*(?:g|ml)', caseSensitive: false),
    ],
  };

  /// Parsea texto de etiqueta y extrae valores nutricionales
  ParsedLabelResult parse(String text) {
    _logger.d('Parsing label text: $text');

    final result = ParsedLabelResult();

    // Extraer nombre del producto (primera línea no vacía)
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      result.name = _cleanName(lines.first);
    }

    // Buscar valores nutricionales
    for (final entry in _patterns.entries) {
      final key = entry.key;
      final patterns = entry.value;

      for (final pattern in patterns) {
        final match = pattern.firstMatch(text);
        if (match != null && match.groupCount >= 1) {
          final valueStr = match.group(1)?.replaceAll(',', '.') ?? '0';
          final value = double.tryParse(valueStr) ?? 0;

          switch (key) {
            case 'energy':
              if (result.kcal == 0) result.kcal = value.round();
              break;
            case 'protein':
              if (result.protein == 0) result.protein = value;
              break;
            case 'carbs':
              if (result.carbs == 0) result.carbs = value;
              break;
            case 'fat':
              if (result.fat == 0) result.fat = value;
              break;
            case 'saturatedFat':
              result.saturatedFat = value;
              break;
            case 'fiber':
              result.fiber = value;
              break;
            case 'sodium':
              result.sodium = value;
              break;
            case 'servingSize':
              result.servingSize = value;
              break;
          }
          break; // Solo tomar el primer match para cada categoría
        }
      }
    }

    // Detectar si es por porción o por 100g
    result.isPerServing = _isPerServing(text);

    _logger.d('Parsed result: $result');
    return result;
  }

  /// Limpia el nombre del producto
  String _cleanName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Detecta si los valores son por porción o por 100g
  bool _isPerServing(String text) {
    final lowerText = text.toLowerCase();
    
    // Indicadores de por porción
    final servingIndicators = [
      'por porción',
      'por ración',
      'por envase',
      'per serving',
      'per portion',
    ];

    for (final indicator in servingIndicators) {
      if (lowerText.contains(indicator)) return true;
    }

    // Indicadores de por 100g
    final per100Indicators = [
      'por 100g',
      'por 100 ml',
      'per 100g',
      'per 100ml',
      '100g',
      '100 ml',
    ];

    for (final indicator in per100Indicators) {
      if (lowerText.contains(indicator)) return false;
    }

    // Por defecto, asumimos por 100g
    return false;
  }

  /// Convierte valores por porción a por 100g
  ParsedLabelResult convertToPer100g(ParsedLabelResult result) {
    if (!result.isPerServing || result.servingSize <= 0) {
      return result;
    }

    final factor = 100.0 / result.servingSize;

    return ParsedLabelResult()
      ..name = result.name
      ..kcal = (result.kcal * factor).round()
      ..protein = result.protein * factor
      ..carbs = result.carbs * factor
      ..fat = result.fat * factor
      ..saturatedFat = result.saturatedFat * factor
      ..fiber = result.fiber * factor
      ..sodium = result.sodium * factor
      ..servingSize = result.servingSize
      ..isPerServing = false;
  }
}

/// Resultado del parsing de etiqueta
class ParsedLabelResult {
  String name = '';
  int kcal = 0;
  double protein = 0;
  double carbs = 0;
  double fat = 0;
  double saturatedFat = 0;
  double fiber = 0;
  double sodium = 0;
  double servingSize = 0;
  bool isPerServing = false;

  bool get hasData => kcal > 0 || protein > 0 || carbs > 0 || fat > 0;

  @override
  String toString() {
    return 'ParsedLabelResult(name: $name, kcal: $kcal, P: $protein, C: $carbs, G: $fat, perServing: $isPerServing)';
  }
}
