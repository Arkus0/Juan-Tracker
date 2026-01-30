/// Servicio para mejorar el scoring de búsquedas de alimentos en español
///
/// No realiza múltiples búsquedas a la API (para no saturar rate limits),
/// sino que mejora el ranking/scoring de los resultados obtenidos.
class FoodSearchExpander {
  // ===========================================================================
  // MAPA DE SINÓNIMOS Y TÉRMINOS EQUIVALENTES EN ESPAÑOL
  // ===========================================================================

  /// Sinónimos para mejorar el scoring de resultados
  /// Clave: término principal → Valores: variantes/sinónimos
  static const Map<String, List<String>> _synonyms = {
    // Carnes
    'pechuga': ['pechuga', 'filete', 'muslo', 'contramuslo'],
    'pollo': ['pollo', 'ave'],
    'carne': ['carne', 'filete', 'chuleta', 'solomillo'],
    'res': ['res', 'vaca', 'ternera'],
    'cerdo': ['cerdo', 'puerco', 'lomo'],
    'pavo': ['pavo', 'pavita'],

    // Pescados
    'atún': ['atún', 'atun'],
    'salmón': ['salmón', 'salmon', 'trucha'],
    'bacalao': ['bacalao', 'merluza'],
    'merluza': ['merluza', 'pescadilla'],

    // Lácteos
    'leche': ['leche', 'lácteo'],
    'yogur': ['yogur', 'yogurt', 'yogourt'],
    'queso': ['queso'],

    // Huevos
    'huevo': ['huevo', 'huevos'],

    // Cereales y pan
    'pan': ['pan', 'barra', 'baguette'],
    'arroz': ['arroz', 'grano'],
    'pasta': ['pasta', 'espagueti', 'macarrón', 'fideo', 'tallarín'],
    'avena': ['avena', 'copos'],

    // Frutas
    'manzana': ['manzana', 'reineta', 'golden'],
    'plátano': ['plátano', 'platano', 'banana'],
    'naranja': ['naranja', 'mandarina', 'clementina'],

    // Verduras
    'tomate': ['tomate', 'jitomate'],
    'pimiento': ['pimiento', 'pimientos', 'morrón'],
    'calabacín': ['calabacín', 'calabacin', 'zucchini'],
    'brócoli': ['brócoli', 'brocoli', 'coliflor'],
    'patata': ['patata', 'papa', 'patatas'],
    'zanahoria': ['zanahoria', 'zanahorias'],

    // Legumbres
    'frijol': ['frijol', 'judía', 'alubia', 'haba'],
    'lenteja': ['lenteja', 'lentejas'],
    'garbanzo': ['garbanzo', 'garbanzos'],

    // Frutos secos
    'almendra': ['almendra', 'almendras'],
    'nuez': ['nuez', 'nueces'],
    'avellana': ['avellana', 'avellanas'],
    'cacahuete': ['cacahuete', 'cacahuates', 'maní'],

    // Aceites y grasas
    'aceite': ['aceite', 'aceites'],
    'aceite de oliva': ['aceite de oliva', 'aove', 'aceite virgen'],
    'mantequilla': ['mantequilla', 'manteca'],

    // Bebidas
    'agua': ['agua', 'bebida'],
    'zumo': ['zumo', 'jugo'],
    'refresco': ['refresco', 'gaseosa', 'soda'],
    'café': ['café', 'cafe'],
    'té': ['té', 'te', 'infusión'],

    // Otros
    'azúcar': ['azúcar', 'azucar'],
    'sal': ['sal', 'sodio'],
    'miel': ['miel', 'jarabe', 'sirope'],
  };

  /// Términos que indican preparaciones procesadas a penalizar
  static const Set<String> _processedTerms = {
    'congelado',
    'precocinado',
    'preparado',
    'microondas',
    'frito',
    'rebozado',
    'empanado',
    'salsa',
    'adobado',
    'marinado',
    'especiado',
    'condimentado',
  };

  /// Marcas de supermercados españolas comunes (para priorizar)
  static const Set<String> _spanishSupermarketBrands = {
    'mercadona',
    'hacendado',
    'carrefour',
    'dia',
    'lidl',
    'aldi',
    'eroski',
    'caprabo',
    'consum',
    'masymas',
    'bm',
    'froiz',
    'el corte inglés',
    'hipercor',
    'ecuador',
    'ifa',
    'supercor',
    'alcampo',
    'auchan',
    'sorli',
  };

  /// Palabras vacías en español (no aportan significado para scoring)
  static const Set<String> _stopWords = {
    'de',
    'del',
    'la',
    'el',
    'los',
    'las',
    'un',
    'una',
    'unos',
    'unas',
    'y',
    'o',
    'con',
    'sin',
    'para',
    'por',
    'en',
    'a',
    'al',
    'fresco',
    'fresca',
    'natural',
    'naturales',
    'ecológico',
    'bio',
  };

  // ===========================================================================
  // MÉTODOS PÚBLICOS
  // ===========================================================================

  /// Verifica si un producto parece ser de un supermercado español
  bool isSpanishProduct(String name, String? brand) {
    final searchText = '${name.toLowerCase()} ${brand?.toLowerCase() ?? ''}';

    for (final brandName in _spanishSupermarketBrands) {
      if (searchText.contains(brandName)) {
        return true;
      }
    }

    return false;
  }

  /// Verifica si un producto es una preparación procesada (a penalizar)
  bool isProcessedProduct(String name) {
    final nameLower = name.toLowerCase();

    for (final term in _processedTerms) {
      if (nameLower.contains(term)) {
        return true;
      }
    }

    return false;
  }

  /// Calcula un score de relevancia española para un producto
  ///
  /// Devuelve un bonus/penalización que se suma al scoring base.
  /// Valores típicos: -30 a +100
  double calculateSpanishRelevance(String productName, String? brand, String query) {
    double score = 0;

    final normalizedProduct = _normalize(productName);
    final normalizedQuery = _normalize(query);
    final queryWords = _extractMeaningfulWords(normalizedQuery);

    // Bonus por ser producto español (+50)
    if (isSpanishProduct(productName, brand)) {
      score += 50;
    }

    // Penalización por ser procesado (-30)
    if (isProcessedProduct(productName)) {
      score -= 30;
    }

    // Scoring por coincidencia con sinónimos de la búsqueda
    for (final word in queryWords) {
      final synonyms = _getSynonyms(word);

      for (final term in synonyms) {
        // Coincidencia exacta del nombre completo
        if (normalizedProduct == term) {
          score += 100;
        }
        // Coincidencia al inicio
        else if (normalizedProduct.startsWith(term)) {
          score += 50;
        }
        // Coincidencia de palabra completa
        else if (normalizedProduct.split(' ').contains(term)) {
          score += 30;
        }
        // Coincidencia parcial
        else if (normalizedProduct.contains(term)) {
          score += 15;
        }
      }
    }

    return score;
  }

  /// Extrae palabras clave significativas de una query para búsqueda
  ///
  /// Útil para mostrar sugerencias o resaltar términos
  List<String> extractKeyTerms(String query) {
    final normalized = _normalize(query);
    return _extractMeaningfulWords(normalized);
  }

  // ===========================================================================
  // MÉTODOS PRIVADOS
  // ===========================================================================

  /// Normaliza un texto (minúsculas, sin tildes)
  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  /// Extrae palabras significativas de una búsqueda
  List<String> _extractMeaningfulWords(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2 && !_stopWords.contains(w))
        .toList();
  }

  /// Obtiene sinónimos para un término
  List<String> _getSynonyms(String word) {
    final normalized = _normalize(word);

    // Buscar coincidencia exacta
    if (_synonyms.containsKey(normalized)) {
      return _synonyms[normalized]!;
    }

    // Buscar coincidencia parcial
    for (final entry in _synonyms.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    // Si no hay sinónimos, devolver la palabra original
    return [word];
  }
}
