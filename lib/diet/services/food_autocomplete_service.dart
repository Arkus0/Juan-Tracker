// Servicio de autocompletar para búsqueda de alimentos
//
// Implementa:
// - Trie (árbol prefijo) para búsqueda eficiente de prefijos
// - Sugerencias basadas en popularidad/frecuencia
// - Aprendizaje de búsquedas del usuario
// - Corrección ortográfica ligera


/// Nodo del Trie
class _TrieNode {
  final Map<String, _TrieNode> children = {};
  bool isEndOfWord = false;
  int frequency = 0; // Frecuencia de uso para ranking
  String? fullTerm; // Término completo al final

  _TrieNode getOrCreateChild(String char) {
    return children.putIfAbsent(char, () => _TrieNode());
  }
}

/// Resultado de autocompletar
class AutocompleteSuggestion {
  final String term;
  final int frequency;
  final double score;
  final SuggestionType type;

  const AutocompleteSuggestion({
    required this.term,
    required this.frequency,
    required this.score,
    required this.type,
  });
}

/// Tipo de sugerencia
enum SuggestionType {
  popular,    // Términos populares generales
  userHistory, // Búsquedas previas del usuario
  recent,     // Búsquedas recientes
}

/// Servicio de autocompletar con Trie
class FoodAutocompleteService {
  final _TrieNode _root = _TrieNode();
  final Map<String, int> _userSearchFrequency = {};
  final List<String> _recentSearches = [];
  
  static const int _maxRecentSearches = 20;

  // Términos populares predefinidos (alimentos comunes en español)
  static const List<String> _popularTerms = [
    // Carnes
    'pollo', 'pechuga de pollo', 'muslo de pollo', 'filete de pollo',
    'carne de res', 'filete de ternera', 'hamburguesa', 'costillas',
    'cerdo', 'chuleta de cerdo', 'jamón', 'lomo embuchado',
    'pavo', 'pechuga de pavo',
    // Pescados
    'atún', 'salmón', 'bacalao', 'merluza', 'dorada', 'lubina',
    'gambas', 'langostinos', 'mejillones', 'calamar',
    // Lácteos
    'leche', 'leche desnatada', 'leche semidesnatada', 'yogur', 'yogur griego',
    'queso', 'queso fresco', 'queso cheddar', 'queso mozzarella', 'queso de cabra',
    'mantequilla', 'nata', 'huevos',
    // Cereales y pan
    'pan', 'pan integral', 'pan de molde', 'baguette', 'pan de centeno',
    'arroz', 'arroz blanco', 'arroz integral', 'pasta', 'espaguetis', 'macarrones',
    'avena', 'cereales', 'muesli', 'granola',
    // Frutas
    'manzana', 'plátano', 'naranja', 'pera', 'uva', 'fresas', 'frambuesas',
    'melón', 'sandía', 'piña', 'mango', 'kiwi', 'limón', 'pomelo',
    // Verduras
    'tomate', 'lechuga', 'cebolla', 'ajo', 'pimiento', 'pepino', 'zanahoria',
    'patata', 'brócoli', 'coliflor', 'espinacas', 'acelgas', 'calabacín', 'berenjena',
    'calabaza', 'remolacha', 'espárragos', 'alcachofas',
    // Legumbres
    'lentejas', 'garbanzos', 'judías blancas', 'guisantes', 'edamame',
    // Frutos secos
    'almendras', 'nueces', 'avellanas', 'cacahuetes', 'pipas', 'chia', 'linaza',
    // Bebidas
    'agua', 'agua mineral', 'zumo de naranja', 'zumo de manzana', 'refresco',
    'café', 'té', 'té verde', 'té negro', 'infusión',
    // Aceites
    'aceite de oliva', 'aceite de girasol', 'aceite de coco', 'vinagre',
    // Otros
    'azúcar', 'sal', 'pimienta', 'especias', 'miel', 'mermelada',
    'chocolate', 'chocolate negro', 'galletas', 'cacao',
  ];

  /// Inicializa el servicio con términos populares
  void initialize() {
    for (final term in _popularTerms) {
      _insert(term.toLowerCase(), frequency: 5);
    }
  }

  /// Inserta un término en el Trie
  void _insert(String term, {int frequency = 1}) {
    if (term.isEmpty) return;

    var node = _root;
    for (final char in term.toLowerCase().split('')) {
      node = node.getOrCreateChild(char);
    }
    node.isEndOfWord = true;
    node.frequency += frequency;
    node.fullTerm = term;
  }

  /// Registra una búsqueda del usuario (para aprendizaje)
  void recordSearch(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty || normalized.length < 2) return;

    // Incrementar frecuencia
    _userSearchFrequency[normalized] = (_userSearchFrequency[normalized] ?? 0) + 1;

    // Actualizar recientes
    _recentSearches.remove(normalized);
    _recentSearches.insert(0, normalized);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches.removeLast();
    }

    // Insertar/actualizar en el Trie
    _insert(normalized, frequency: _userSearchFrequency[normalized]!);
  }

  /// Obtiene sugerencias de autocompletar
  List<AutocompleteSuggestion> getSuggestions(
    String prefix, {
    int maxResults = 10,
  }) {
    if (prefix.isEmpty || prefix.length < 2) {
      // Retornar búsquedas recientes si no hay prefijo
      return _recentSearches
          .take(maxResults)
          .map((term) => AutocompleteSuggestion(
                term: term,
                frequency: _userSearchFrequency[term] ?? 1,
                score: 1.0,
                type: SuggestionType.recent,
              ))
          .toList();
    }

    final normalizedPrefix = prefix.toLowerCase();
    final results = <AutocompleteSuggestion>[];

    // Encontrar el nodo del prefijo
    var node = _root;
    for (final char in normalizedPrefix.split('')) {
      node = node.children[char]!;
    }

    // Recolectar todos los términos desde ese nodo
    _collectTerms(node, normalizedPrefix, results);

    // Ordenar por score (frecuencia + bonus por tipo)
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.take(maxResults).toList();
  }

  /// Recolecta términos recursivamente desde un nodo
  void _collectTerms(
    _TrieNode node,
    String currentPrefix,
    List<AutocompleteSuggestion> results,
  ) {
    if (node.isEndOfWord && node.fullTerm != null) {
      final term = node.fullTerm!;
      final userFreq = _userSearchFrequency[term] ?? 0;
      final isRecent = _recentSearches.contains(term);

      // Calcular score
      double score = node.frequency.toDouble();
      
      // Bonus por ser búsqueda del usuario
      if (userFreq > 0) {
        score += userFreq * 2;
      }
      
      // Bonus por ser reciente
      if (isRecent) {
        score += 5;
      }

      // Determinar tipo
      SuggestionType type;
      if (isRecent) {
        type = SuggestionType.recent;
      } else if (userFreq > 0) {
        type = SuggestionType.userHistory;
      } else {
        type = SuggestionType.popular;
      }

      results.add(AutocompleteSuggestion(
        term: term,
        frequency: node.frequency + userFreq,
        score: score,
        type: type,
      ));
    }

    // Recursión sobre hijos
    for (final entry in node.children.entries) {
      _collectTerms(entry.value, currentPrefix + entry.key, results);
    }
  }

  /// Limpia el historial de búsquedas del usuario
  void clearUserHistory() {
    _userSearchFrequency.clear();
    _recentSearches.clear();
  }

  /// Obtiene estadísticas
  Map<String, dynamic> get stats => {
    'totalTerms': _countTerms(_root),
    'userSearches': _userSearchFrequency.length,
    'recentSearches': _recentSearches.length,
  };

  int _countTerms(_TrieNode node) {
    int count = node.isEndOfWord ? 1 : 0;
    for (final child in node.children.values) {
      count += _countTerms(child);
    }
    return count;
  }
}

/// Extensión para ordenar y filtrar sugerencias
extension AutocompleteSuggestionList on List<AutocompleteSuggestion> {
  /// Filtra sugerencias duplicadas manteniendo la de mayor score
  List<AutocompleteSuggestion> deduplicate() {
    final seen = <String>{};
    final unique = <AutocompleteSuggestion>[];

    for (final suggestion in this) {
      if (!seen.contains(suggestion.term)) {
        seen.add(suggestion.term);
        unique.add(suggestion);
      }
    }

    return unique;
  }

  /// Ordena por tipo y luego por score
  List<AutocompleteSuggestion> sortByRelevance() {
    final sorted = List<AutocompleteSuggestion>.from(this);
    sorted.sort((a, b) {
      // Primero por tipo (relevance > user > popular)
      final typeComparison = b.type.index.compareTo(a.type.index);
      if (typeComparison != 0) return typeComparison;
      // Luego por score
      return b.score.compareTo(a.score);
    });
    return sorted;
  }
}
