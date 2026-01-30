// Servicio de Full-Text Search (FTS) para alimentos
//
// Implementa búsqueda de texto completo usando SQLite FTS5 (simulado)
// En Flutter usamos un índice invertido en memoria para máxima velocidad
// Cuando se migre a Drift FTS5, este servicio actúa como wrapper

import '../models/food_model.dart';
import '../models/open_food_facts_model.dart';

/// Entrada en el índice invertido
class _Posting {
  final String documentId;
  final int position;
  final double weight;

  _Posting(this.documentId, this.position, this.weight);
}

/// Documento indexado
class _FTSDocument {
  final String id;
  final String title; // nombre del alimento
  final String? brand;
  final String content; // texto completo para búsqueda
  final DateTime indexedAt;
  final Map<String, dynamic> metadata;

  _FTSDocument({
    required this.id,
    required this.title,
    this.brand,
    required this.content,
    required this.indexedAt,
    this.metadata = const {},
  });
}

/// Resultado de búsqueda FTS
class FTSResult {
  final String id;
  final String title;
  final String? brand;
  final double score;
  final Map<String, dynamic> metadata;
  final List<String> matchedTerms;

  const FTSResult({
    required this.id,
    required this.title,
    this.brand,
    required this.score,
    required this.metadata,
    required this.matchedTerms,
  });
}

/// Servicio FTS (Full-Text Search)
class FoodFTSService {
  // Índice invertido: término -> lista de postings
  final Map<String, List<_Posting>> _invertedIndex = {};
  final Map<String, _FTSDocument> _documents = {};
  
  // Estadísticas para TF-IDF
  int _totalDocuments = 0;
  final Map<String, int> _documentFrequency = {};

  /// Tokeniza un texto en términos indexables
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sáéíóúñ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .map(_normalizeTerm)
        .toList();
  }

  /// Normaliza términos (quita acentos, etc.)
  String _normalizeTerm(String term) {
    return term
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  /// Indexa un alimento local
  void indexLocalFood(FoodModel food) {
    final content = '${food.name} ${food.brand ?? ''}';
    
    final doc = _FTSDocument(
      id: food.id,
      title: food.name,
      brand: food.brand,
      content: content,
      indexedAt: DateTime.now(),
      metadata: {
        'type': 'local',
        'kcal': food.kcalPer100g,
        'protein': food.proteinPer100g,
        'barcode': food.barcode,
      },
    );

    _indexDocument(doc);
  }

  /// Indexa un alimento externo
  void indexExternalFood(OpenFoodFactsResult food) {
    final content = '${food.name} ${food.brand ?? ''} ${food.ingredientsText ?? ''}';
    
    final doc = _FTSDocument(
      id: food.code,
      title: food.name,
      brand: food.brand,
      content: content,
      indexedAt: food.fetchedAt,
      metadata: {
        'type': 'external',
        'kcal': food.kcalPer100g,
        'protein': food.proteinPer100g,
        'imageUrl': food.imageUrl,
      },
    );

    _indexDocument(doc);
  }

  /// Indexa un documento
  void _indexDocument(_FTSDocument doc) {
    // Eliminar si ya existe
    if (_documents.containsKey(doc.id)) {
      _removeDocument(doc.id);
    }

    _documents[doc.id] = doc;
    _totalDocuments++;

    final terms = _tokenize(doc.content);
    final uniqueTerms = terms.toSet();

    // Actualizar frecuencia de documentos
    for (final term in uniqueTerms) {
      _documentFrequency[term] = (_documentFrequency[term] ?? 0) + 1;
    }

    // Añadir a índice invertido
    for (int i = 0; i < terms.length; i++) {
      final term = terms[i];
      
      // Peso según posición (título tiene más peso)
      double weight = 1.0;
      if (i < 3) weight = 3.0; // Primeros términos (título)
      
      _invertedIndex.putIfAbsent(term, () => []).add(
        _Posting(doc.id, i, weight),
      );
    }
  }

  /// Elimina un documento del índice
  void _removeDocument(String id) {
    final doc = _documents.remove(id);
    if (doc == null) return;

    _totalDocuments--;
    final terms = _tokenize(doc.content);
    final uniqueTerms = terms.toSet();

    for (final term in uniqueTerms) {
      _documentFrequency[term] = (_documentFrequency[term] ?? 1) - 1;
      if (_documentFrequency[term]! <= 0) {
        _documentFrequency.remove(term);
      }
    }

    // Eliminar postings
    for (final postings in _invertedIndex.values) {
      postings.removeWhere((p) => p.documentId == id);
    }
  }

  /// Calcula IDF (Inverse Document Frequency)
  double _idf(String term) {
    final df = _documentFrequency[term] ?? 0;
    if (df == 0) return 0;
    
    // IDF = log(N / df)
    return log(_totalDocuments / df);
  }

  static double log(double x) {
    // Aproximación simple de log natural
    if (x <= 1) return 0;
    double result = 0;
    double y = x;
    while (y > 1) {
      y /= 2.718281828459045;
      result++;
    }
    return result;
  }

  /// Búsqueda FTS con BM25-like scoring
  List<FTSResult> search(
    String query, {
    int maxResults = 20,
    double minScore = 0.01,
  }) {
    if (query.trim().isEmpty || _totalDocuments == 0) {
      return [];
    }

    final queryTerms = _tokenize(query);
    if (queryTerms.isEmpty) return [];

    // Calcular scores para documentos candidatos
    final scores = <String, double>{};
    final matchedTerms = <String, Set<String>>{};

    for (final term in queryTerms) {
      final postings = _invertedIndex[term];
      if (postings == null || postings.isEmpty) continue;

      final idf = _idf(term);
      if (idf == 0) continue;

      // Agrupar postings por documento para calcular TF
      final docTermFreq = <String, int>{};
      for (final posting in postings) {
        docTermFreq[posting.documentId] = (docTermFreq[posting.documentId] ?? 0) + 1;
      }

      // Calcular score BM25 para cada documento
      for (final docId in docTermFreq.keys) {
        final tf = docTermFreq[docId]!;
        
        // TF normalizado (simplificado)
        final doc = _documents[docId];
        final docLength = doc != null ? _tokenize(doc.content).length : 100;
        final avgLength = _averageDocumentLength;
        
        final tfNorm = tf / (tf + 1.2 * (0.25 + 0.75 * (docLength / avgLength)));
        
        final score = idf * tfNorm;
        scores[docId] = (scores[docId] ?? 0) + score;
        
        // Registrar término coincidente
        matchedTerms.putIfAbsent(docId, () => <String>{}).add(term);
      }
    }

    // Construir resultados
    final results = <FTSResult>[];
    for (final entry in scores.entries) {
      if (entry.value < minScore) continue;

      final doc = _documents[entry.key];
      if (doc == null) continue;

      // Bonus por alimentos locales
      double finalScore = entry.value;
      if (doc.metadata['type'] == 'local') {
        finalScore *= 1.3;
      }

      results.add(FTSResult(
        id: doc.id,
        title: doc.title,
        brand: doc.brand,
        score: finalScore,
        metadata: doc.metadata,
        matchedTerms: matchedTerms[entry.key]?.toList() ?? [],
      ));
    }

    // Ordenar por score
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.take(maxResults).toList();
  }

  /// Búsqueda por frase exacta
  List<FTSResult> searchPhrase(
    String phrase, {
    int maxResults = 20,
  }) {
    final terms = _tokenize(phrase);
    if (terms.isEmpty) return [];

    // Buscar documentos que contengan todos los términos en orden
    final candidates = <String, List<int>>{};

    for (int i = 0; i < terms.length; i++) {
      final term = terms[i];
      final postings = _invertedIndex[term];
      if (postings == null) return [];

      for (final posting in postings) {
        candidates.putIfAbsent(posting.documentId, () => []).add(posting.position);
      }
    }

    // Filtrar documentos con todos los términos en secuencia
    final results = <FTSResult>[];
    for (final entry in candidates.entries) {
      final positions = entry.value..sort();
      
      // Verificar si hay secuencia consecutiva
      bool hasConsecutive = false;
      for (int i = 0; i <= positions.length - terms.length; i++) {
        bool consecutive = true;
        for (int j = 0; j < terms.length - 1; j++) {
          if (positions[i + j + 1] != positions[i + j] + 1) {
            consecutive = false;
            break;
          }
        }
        if (consecutive) {
          hasConsecutive = true;
          break;
        }
      }

      if (hasConsecutive) {
        final doc = _documents[entry.key];
        if (doc != null) {
          results.add(FTSResult(
            id: doc.id,
            title: doc.title,
            brand: doc.brand,
            score: 10.0, // Score alto por coincidencia exacta
            metadata: doc.metadata,
            matchedTerms: terms,
          ));
        }
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(maxResults).toList();
  }

  /// Sugerencias de corrección ortográfica
  List<String> suggestCorrections(String term, {int maxSuggestions = 3}) {
    final normalized = _normalizeTerm(term.toLowerCase());
    final suggestions = <String, int>{};

    // Buscar términos similares (distancia de edición <= 2)
    for (final indexedTerm in _invertedIndex.keys) {
      final distance = _levenshteinDistance(normalized, indexedTerm);
      if (distance <= 2 && distance > 0) {
        suggestions[indexedTerm] = distance;
      }
    }

    // Ordenar por distancia y luego por frecuencia
    final sorted = suggestions.entries.toList()
      ..sort((a, b) {
        final distCompare = a.value.compareTo(b.value);
        if (distCompare != 0) return distCompare;
        
        final freqA = _documentFrequency[a.key] ?? 0;
        final freqB = _documentFrequency[b.key] ?? 0;
        return freqB.compareTo(freqA);
      });

    return sorted.take(maxSuggestions).map((e) => e.key).toList();
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1.length < s2.length) return _levenshteinDistance(s2, s1);
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

  double get _averageDocumentLength {
    if (_documents.isEmpty) return 100;
    
    int totalLength = 0;
    for (final doc in _documents.values) {
      totalLength += _tokenize(doc.content).length;
    }
    return totalLength / _documents.length;
  }

  /// Limpia el índice
  void clear() {
    _invertedIndex.clear();
    _documents.clear();
    _totalDocuments = 0;
    _documentFrequency.clear();
  }

  /// Estadísticas del índice
  Map<String, dynamic> get stats => {
    'totalDocuments': _totalDocuments,
    'uniqueTerms': _invertedIndex.length,
    'avgDocLength': _averageDocumentLength.toInt(),
  };
}
