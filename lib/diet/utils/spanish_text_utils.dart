// Utilidades de procesamiento de texto en español para búsqueda de alimentos
//
// Incluye:
// - Sinónimos/aliases comunes en alimentación española
// - Stemming básico para español (plurales, sufijos)
// - Normalización de texto

// ============================================================================
// SINÓNIMOS DE ALIMENTOS - ESPAÑOL
// ============================================================================

/// Mapa bidireccional de sinónimos alimentarios.
/// Cada grupo contiene términos equivalentes que deben matchear entre sí.
/// 
/// Ejemplos de uso:
/// - "leche descremada" → también busca "desnatada"
/// - "pechuga de pollo" → también busca "pollo pechuga"
/// - "judías verdes" → también busca "ejotes", "habichuelas"
const List<Set<String>> _synonymGroups = [
  // === LÁCTEOS ===
  {'desnatada', 'descremada', '0% grasa', 'sin grasa'},
  {'semidesnatada', 'semidescremada', 'semi'},
  {'entera', 'completa', 'normal'},
  {'leche', 'lacteo', 'lácteo'},
  {'yogur', 'yogurt', 'iogurt'},
  {'queso', 'formatge'},
  {'nata', 'crema', 'crema de leche'},
  {'mantequilla', 'manteca'},
  {'requesón', 'ricota', 'ricotta', 'cottage'},
  
  // === CARNES ===
  {'pollo', 'gallina', 'ave'},
  {'pechuga', 'pecho'},
  {'muslo', 'contramuslo'},
  {'ternera', 'res', 'vacuno', 'vaca'},
  {'cerdo', 'puerco', 'cochino'},
  {'lomo', 'solomillo', 'filete'},
  {'carne picada', 'carne molida', 'picadillo'},
  {'jamón', 'pernil'},
  {'jamón serrano', 'jamón curado'},
  {'jamón york', 'jamón cocido', 'jamón dulce'},
  {'bacon', 'tocino', 'beicon', 'panceta'},
  {'salchicha', 'salchichas', 'butifarra'},
  {'chorizo', 'chistorra'},
  
  // === PESCADOS Y MARISCOS ===
  {'atún', 'bonito', 'tuna'},
  {'salmón', 'salmon'},
  {'merluza', 'pescadilla'},
  {'bacalao', 'abadejo'},
  {'sardina', 'sardinas', 'sardinilla'},
  {'anchoa', 'anchoas', 'boquerón', 'boquerones'},
  {'gambas', 'camarones', 'langostinos'},
  {'mejillones', 'mejillón'},
  {'calamar', 'calamares', 'chipirón', 'chipirones'},
  {'pulpo', 'pulpito'},
  
  // === HUEVOS ===
  {'huevo', 'huevos', 'blanquillo'},
  {'clara', 'claras'},
  {'yema', 'yemas'},
  
  // === VERDURAS Y HORTALIZAS ===
  {'tomate', 'jitomate'},
  {'patata', 'papa', 'patatas', 'papas'},
  {'cebolla', 'cebolleta'},
  {'ajo', 'ajos'},
  {'pimiento', 'pimentón', 'morrón'},
  {'zanahoria', 'zanahorias'},
  {'calabacín', 'calabacita', 'zucchini'},
  {'berenjena', 'berenjenas'},
  {'judías verdes', 'ejotes', 'habichuelas verdes', 'chauchas', 'vainitas'},
  {'espinaca', 'espinacas'},
  {'lechuga', 'ensalada'},
  {'col', 'repollo', 'berza'},
  {'brócoli', 'brécol', 'brocoli'},
  {'coliflor', 'coliflores'},
  {'champiñón', 'champiñones', 'setas', 'hongos'},
  {'pepino', 'pepinos'},
  {'aguacate', 'palta'},
  {'maíz', 'elote', 'choclo', 'mazorca'},
  {'guisantes', 'arvejas', 'chícharos', 'petit pois'},
  {'lentejas', 'lenteja'},
  {'garbanzos', 'garbanzo'},
  {'judías', 'alubias', 'frijoles', 'porotos', 'habichuelas'},
  {'remolacha', 'betabel', 'beterraga'},
  
  // === FRUTAS ===
  {'manzana', 'manzanas'},
  {'plátano', 'banana', 'banano', 'guineo'},
  {'naranja', 'naranjas'},
  {'mandarina', 'clementina', 'tangerina'},
  {'limón', 'lima'},
  {'fresa', 'fresas', 'frutilla', 'frutillas'},
  {'uva', 'uvas'},
  {'melocotón', 'durazno'},
  {'pera', 'peras'},
  {'piña', 'ananá', 'ananás'},
  {'sandía', 'patilla', 'melón de agua'},
  {'melón', 'melones'},
  {'kiwi', 'kiwis'},
  {'mango', 'mangos'},
  {'papaya', 'lechosa'},
  {'cereza', 'cerezas', 'guinda'},
  {'ciruela', 'ciruelas'},
  {'albaricoque', 'chabacano', 'damasco'},
  {'granada', 'granadas'},
  {'higo', 'higos', 'breva'},
  {'frutos rojos', 'berries', 'bayas'},
  {'arándano', 'arándanos', 'blueberry'},
  {'frambuesa', 'frambuesas'},
  {'mora', 'moras', 'zarzamora'},
  
  // === CEREALES Y GRANOS ===
  {'arroz', 'arroces'},
  {'arroz integral', 'arroz moreno', 'arroz brown'},
  {'pasta', 'fideos', 'macarrones'},
  {'espagueti', 'espaguetis', 'spaghetti'},
  {'pan', 'panes'},
  {'pan integral', 'pan de molde integral'},
  {'pan blanco', 'pan de molde'},
  {'baguette', 'barra de pan'},
  {'avena', 'oats', 'oatmeal'},
  {'trigo', 'harina de trigo'},
  {'maíz', 'harina de maíz', 'polenta'},
  {'quinoa', 'quinua'},
  {'cebada', 'cebadas'},
  {'centeno', 'centenos'},
  
  // === FRUTOS SECOS Y SEMILLAS ===
  {'almendra', 'almendras'},
  {'nuez', 'nueces'},
  {'cacahuete', 'cacahuetes', 'maní', 'manises'},
  {'avellana', 'avellanas'},
  {'pistacho', 'pistachos'},
  {'anacardo', 'anacardos', 'cajú', 'marañón'},
  {'semillas de chía', 'chía', 'chia'},
  {'semillas de lino', 'linaza'},
  {'semillas de girasol', 'pipas'},
  {'semillas de calabaza', 'pepitas'},
  
  // === ACEITES Y GRASAS ===
  {'aceite de oliva', 'aove', 'aceite oliva'},
  {'aceite de girasol', 'aceite girasol'},
  {'aceite de coco', 'aceite coco'},
  
  // === ENDULZANTES ===
  {'azúcar', 'azucar', 'sacarosa'},
  {'azúcar moreno', 'azúcar integral', 'azúcar panela'},
  {'miel', 'mieles'},
  {'stevia', 'estevia'},
  {'sacarina', 'edulcorante'},
  
  // === BEBIDAS ===
  {'agua', 'aguas'},
  {'café', 'coffee'},
  {'té', 'te', 'tea', 'infusión'},
  {'zumo', 'jugo', 'jumo'},
  {'refresco', 'gaseosa', 'soda'},
  {'cerveza', 'birra'},
  {'vino', 'vinos'},
  
  // === CONDIMENTOS Y SALSAS ===
  {'sal', 'sales'},
  {'pimienta', 'pimientas'},
  {'salsa de tomate', 'tomate frito', 'ketchup', 'catsup'},
  {'mayonesa', 'mahonesa', 'mayo'},
  {'mostaza', 'mostazas'},
  {'vinagre', 'vinagres'},
  
  // === PREPARACIONES COMUNES ===
  {'frito', 'frita', 'fritos', 'fritas'},
  {'asado', 'asada', 'horneado', 'horneada'},
  {'cocido', 'cocida', 'hervido', 'hervida'},
  {'plancha', 'a la plancha', 'grillado'},
  {'crudo', 'cruda', 'raw'},
  {'natural', 'al natural'},
  {'en conserva', 'enlatado', 'en lata'},
  
  // === MARCAS GENÉRICAS ===
  {'hacendado', 'mercadona'},
  {'carrefour', 'carrefour bio'},
  {'eroski', 'eroski basic'},
  {'dia', 'dia%'},
  {'aldi', 'milbona'},
  {'lidl', 'milbona'},
];

/// Mapa invertido: término → grupo de sinónimos
/// Se construye una sola vez al cargar el módulo
final Map<String, Set<String>> _synonymMap = _buildSynonymMap();

Map<String, Set<String>> _buildSynonymMap() {
  final map = <String, Set<String>>{};
  for (final group in _synonymGroups) {
    for (final term in group) {
      // Cada término mapea a todo su grupo (excepto a sí mismo)
      map[term.toLowerCase()] = group.map((s) => s.toLowerCase()).toSet();
    }
  }
  return map;
}

/// Obtiene sinónimos de un término
/// 
/// Retorna un Set con todos los términos equivalentes, incluyendo el original.
/// Si no hay sinónimos, retorna solo el término original.
Set<String> getSynonyms(String term) {
  final normalized = term.toLowerCase().trim();
  return _synonymMap[normalized] ?? {normalized};
}

/// Expande una query con todos los sinónimos posibles
/// 
/// Para FTS5, genera una query simple que busca el término original
/// y sus sinónimos más comunes (solo términos de una palabra).
/// 
/// Ejemplo: "leche descremada" → "leche* OR lacteo* OR descremada* OR desnatada*"
/// 
/// Nota: Solo incluye sinónimos de una palabra para evitar problemas
/// de sintaxis FTS5. Términos multi-palabra se ignoran.
String expandQueryWithSynonyms(String query) {
  final terms = query.toLowerCase().trim().split(RegExp(r'\s+'));
  if (terms.isEmpty) return '';
  
  final allTerms = <String>{};
  
  for (final term in terms) {
    if (term.length < 2) continue; // Ignorar términos muy cortos
    
    // Añadir término original
    allTerms.add(term);
    
    // Buscar sinónimos de una sola palabra
    final synonyms = getSynonyms(term);
    for (final syn in synonyms) {
      // Solo añadir sinónimos de una palabra (sin espacios)
      if (!syn.contains(' ') && syn.length >= 2) {
        allTerms.add(syn);
      }
    }
  }
  
  if (allTerms.isEmpty) return '';
  
  // Generar query con OR entre todos los términos
  // Ejemplo: "leche* OR lacteo* OR descremada* OR desnatada*"
  return allTerms.map((t) => '$t*').join(' OR ');
}

// ============================================================================
// STEMMING ESPAÑOL BÁSICO
// ============================================================================

/// Sufijos comunes en español para stemming
const List<String> _spanishSuffixes = [
  // Plurales
  'es', 's',
  // Diminutivos
  'ito', 'ita', 'itos', 'itas',
  'illo', 'illa', 'illos', 'illas',
  'ico', 'ica', 'icos', 'icas',
  'ín', 'ina',
  // Aumentativos
  'ón', 'ona', 'ones', 'onas',
  'azo', 'aza', 'azos', 'azas',
  // Género
  'o', 'a', 'os', 'as',
];

/// Palabras que no deben sufrir stemming (stopwords de alimentos)
const Set<String> _noStemWords = {
  'de', 'del', 'la', 'el', 'los', 'las', 'un', 'una',
  'con', 'sin', 'en', 'al', 'para', 'por',
  'y', 'o', 'e', 'u',
  'más', 'menos', 'muy', 'poco',
  'gramos', 'g', 'kg', 'ml', 'l', 'litros',
  'kcal', 'calorias', 'proteinas',
};

/// Excepciones de stemming: palabras que no deben reducirse
const Map<String, String> _stemExceptions = {
  // Mantener palabra completa
  'huevos': 'huevo',
  'huevo': 'huevo',
  'leche': 'leche',
  'pan': 'pan',
  'panes': 'pan',
  'arroz': 'arroz',
  'maíz': 'maiz',
  'nuez': 'nuez',
  'nueces': 'nuez',
  'pez': 'pez',
  'peces': 'pez',
  // Casos especiales
  'light': 'light',
  'zero': 'zero',
  'bio': 'bio',
  'eco': 'eco',
};

/// Aplica stemming básico a un término en español
/// 
/// Reduce palabras a su raíz removiendo sufijos comunes.
/// Ejemplo: "manzanas" → "manzan", "pollo" → "poll"
String stemSpanish(String word) {
  final normalized = word.toLowerCase().trim();
  
  // Palabra muy corta: no hacer stemming
  if (normalized.length <= 3) return normalized;
  
  // Palabra en excepciones
  if (_stemExceptions.containsKey(normalized)) {
    return _stemExceptions[normalized]!;
  }
  
  // Stopwords: no hacer stemming
  if (_noStemWords.contains(normalized)) return normalized;
  
  // Aplicar reglas de stemming (del más largo al más corto)
  String stemmed = normalized;
  for (final suffix in _spanishSuffixes) {
    if (normalized.endsWith(suffix) && normalized.length > suffix.length + 2) {
      final candidate = normalized.substring(0, normalized.length - suffix.length);
      // Asegurar que el stem tenga al menos 3 caracteres
      if (candidate.length >= 3) {
        stemmed = candidate;
        break; // Solo aplicar un sufijo
      }
    }
  }
  
  return stemmed;
}

/// Aplica stemming a todos los términos de una query
List<String> stemQuery(String query) {
  return query
    .toLowerCase()
    .trim()
    .split(RegExp(r'\s+'))
    .where((t) => t.isNotEmpty && t.length >= 2)
    .map(stemSpanish)
    .toList();
}

// ============================================================================
// NORMALIZACIÓN DE TEXTO
// ============================================================================

/// Caracteres acentuados y sus equivalentes sin acento
const Map<String, String> _accentMap = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', // Opcional: mantener ñ como n para búsqueda tolerante
};

/// Normaliza texto removiendo acentos y caracteres especiales
String normalizeText(String text) {
  String result = text.toLowerCase();
  
  // Remover acentos
  _accentMap.forEach((accented, plain) {
    result = result.replaceAll(accented, plain);
  });
  
  // Mantener solo letras, números y espacios
  result = result.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  
  // Normalizar espacios múltiples
  result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
  
  return result;
}

// ============================================================================
// API PÚBLICA - QUERY ENHANCEMENT
// ============================================================================

/// Resultado del procesamiento de query
class EnhancedQuery {
  /// Query original normalizada
  final String original;
  
  /// Query expandida con sinónimos (para FTS5)
  final String withSynonyms;
  
  /// Términos con stemming aplicado
  final List<String> stemmedTerms;
  
  /// Query alternativa solo con stems (para fallback)
  final String stemmedQuery;

  const EnhancedQuery({
    required this.original,
    required this.withSynonyms,
    required this.stemmedTerms,
    required this.stemmedQuery,
  });
  
  @override
  String toString() => 'EnhancedQuery(original: $original, '
      'withSynonyms: $withSynonyms, stemmed: $stemmedQuery)';
}

/// Procesa una query de búsqueda aplicando todas las mejoras
/// 
/// 1. Normaliza el texto (minúsculas, sin acentos)
/// 2. Expande con sinónimos
/// 3. Aplica stemming para query alternativa
EnhancedQuery enhanceQuery(String query) {
  final normalized = normalizeText(query);
  final withSynonyms = expandQueryWithSynonyms(normalized);
  final stemmed = stemQuery(normalized);
  final stemmedQuery = stemmed.map((s) => '$s*').join(' ');
  
  return EnhancedQuery(
    original: normalized,
    withSynonyms: withSynonyms,
    stemmedTerms: stemmed,
    stemmedQuery: stemmedQuery,
  );
}
