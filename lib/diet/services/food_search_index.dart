// Servicio de índice de búsqueda local para alimentos
//
// Implementa:
// - Trigram matching para búsqueda difusa (fuzzy search)
// - Búsqueda híbrida: local primero, API después
// - Scoring basado en TF-IDF simplificado
// - Índice en memoria para búsquedas instantáneas

import '../models/food_model.dart';
import '../models/open_food_facts_model.dart';

/// Resultado de búsqueda con scoring
class IndexedSearchResult {
  final String id;
  final String name;
  final String? brand;
  final double score;
  final bool isLocal;
  final FoodModel? localFood;
  final OpenFoodFactsResult? externalFood;

  const IndexedSearchResult({
    required this.id,
    required this.name,
    this.brand,
    required this.score,
    required this.isLocal,
    this.localFood,
    this.externalFood,
  });
}

/// Índice trigram para búsqueda difusa eficiente
class TrigramIndex {
  final Map<String, Set<String>> _trigramToIds = {};
  final Map<String, _Document> _documents = {};

  /// Extrae trigrams de un texto
  /// Ej: "pollo" → ["pol", "oll", "llo"]
  Set<String> _extractTrigrams(String text) {
    final trigrams = <String>{};
    final normalized = _normalize(text);
    
    // Padding para capturar inicio y final
    final padded = '  $normalized  ';
    
    for (int i = 0; i < padded.length - 2; i++) {
      trigrams.add(padded.substring(i, i + 3));
    }
    
    return trigrams;
  }

  /// Calcula similitud Jaccard entre dos sets de trigrams
  /// 1.0 = idénticos, 0.0 = sin coincidencia
  double _jaccardSimilarity(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    
    final intersection = a.intersection(b).length;
    final union = a.union(b).length;
    
    return intersection / union;
  }

  /// Añade un documento al índice
  void addDocument(String id, String name, String? brand, {FoodModel? localFood, OpenFoodFactsResult? externalFood}) {
    // Eliminar si ya existe
    removeDocument(id);
    
    final text = '$name ${brand ?? ''}';
    final trigrams = _extractTrigrams(text);
    
    _documents[id] = _Document(
      id: id,
      name: name,
      brand: brand,
      trigrams: trigrams,
      localFood: localFood,
      externalFood: externalFood,
    );
    
    // Indexar por trigrams
    for (final trigram in trigrams) {
      _trigramToIds.putIfAbsent(trigram, () => <String>{}).add(id);
    }
  }

  /// Elimina un documento del índice
  void removeDocument(String id) {
    final doc = _documents.remove(id);
    if (doc == null) return;
    
    for (final trigram in doc.trigrams) {
      _trigramToIds[trigram]?.remove(id);
    }
  }

  /// Busca documentos similares a la query
  List<IndexedSearchResult> search(String query, {int maxResults = 20, double minScore = 0.1}) {
    if (query.trim().isEmpty) return [];
    
    final queryTrigrams = _extractTrigrams(query);
    final candidateIds = <String>{};
    
    // Encontrar candidatos que compartan al menos un trigram
    for (final trigram in queryTrigrams) {
      final ids = _trigramToIds[trigram];
      if (ids != null) {
        candidateIds.addAll(ids);
      }
    }
    
    // Calcular score para cada candidato
    final results = <IndexedSearchResult>[];
    
    for (final id in candidateIds) {
      final doc = _documents[id];
      if (doc == null) continue;
      
      // Similitud trigram (Jaccard)
      final trigramScore = _jaccardSimilarity(queryTrigrams, doc.trigrams);
      
      // Bonus por coincidencia exacta de palabras
      double wordScore = 0;
      final queryWords = _normalize(query).split(RegExp(r'\s+'));
      final docWords = _normalize('${doc.name} ${doc.brand ?? ''}').split(RegExp(r'\s+'));
      
      for (final qw in queryWords) {
        if (qw.length < 2) continue;
        
        for (final dw in docWords) {
          if (dw.length < 2) continue;
          
          if (dw == qw) {
            wordScore += 1.0; // Coincidencia exacta
          } else if (dw.startsWith(qw)) {
            wordScore += 0.8; // Coincidencia al inicio
          } else if (dw.contains(qw)) {
            wordScore += 0.5; // Coincidencia parcial
          } else {
            // Fuzzy matching con Levenshtein normalizado
            final distance = _levenshteinDistance(qw, dw);
            final maxLen = qw.length > dw.length ? qw.length : dw.length;
            final similarity = 1 - (distance / maxLen);
            
            if (similarity > 0.7) {
              wordScore += similarity * 0.3;
            }
          }
        }
      }
      
      // Score combinado (ponderado)
      final finalScore = (trigramScore * 0.4) + (wordScore.clamp(0, 5) * 0.6);
      
      if (finalScore >= minScore) {
        results.add(IndexedSearchResult(
          id: doc.id,
          name: doc.name,
          brand: doc.brand,
          score: finalScore,
          isLocal: doc.localFood != null,
          localFood: doc.localFood,
          externalFood: doc.externalFood,
        ));
      }
    }
    
    // Ordenar por score descendente
    results.sort((a, b) => b.score.compareTo(a.score));
    
    return results.take(maxResults).toList();
  }

  /// Búsqueda rápida para autocompletar (prefijo)
  List<IndexedSearchResult> searchPrefix(String prefix, {int maxResults = 10}) {
    if (prefix.trim().isEmpty) return [];
    
    final normalizedPrefix = _normalize(prefix);
    final results = <IndexedSearchResult>[];
    
    for (final doc in _documents.values) {
      final docText = _normalize('${doc.name} ${doc.brand ?? ''}');
      
      if (docText.startsWith(normalizedPrefix)) {
        results.add(IndexedSearchResult(
          id: doc.id,
          name: doc.name,
          brand: doc.brand,
          score: 1.0, // Máximo score para prefijo exacto
          isLocal: doc.localFood != null,
          localFood: doc.localFood,
          externalFood: doc.externalFood,
        ));
      } else if (docText.contains(' $normalizedPrefix')) {
        // Coincidencia al inicio de palabra
        results.add(IndexedSearchResult(
          id: doc.id,
          name: doc.name,
          brand: doc.brand,
          score: 0.8,
          isLocal: doc.localFood != null,
          localFood: doc.localFood,
          externalFood: doc.externalFood,
        ));
      }
    }
    
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(maxResults).toList();
  }

  /// Limpia todo el índice
  void clear() {
    _trigramToIds.clear();
    _documents.clear();
  }

  /// Número de documentos indexados
  int get documentCount => _documents.length;

  // ===========================================================================
  // MÉTODOS PRIVADOS
  // ===========================================================================

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
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^\w\s]'), ' ');
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
}

/// Documento interno para el índice
class _Document {
  final String id;
  final String name;
  final String? brand;
  final Set<String> trigrams;
  final FoodModel? localFood;
  final OpenFoodFactsResult? externalFood;

  _Document({
    required this.id,
    required this.name,
    this.brand,
    required this.trigrams,
    this.localFood,
    this.externalFood,
  });
}

/// Servicio global de índice de búsqueda
class FoodSearchIndex {
  static final FoodSearchIndex _instance = FoodSearchIndex._internal();
  factory FoodSearchIndex() => _instance;
  FoodSearchIndex._internal();

  final TrigramIndex _localFoodsIndex = TrigramIndex();
  final TrigramIndex _cachedExternalIndex = TrigramIndex();

  /// Inicializa el índice con alimentos locales
  void indexLocalFoods(List<FoodModel> foods) {
    _localFoodsIndex.clear();
    
    for (final food in foods) {
      _localFoodsIndex.addDocument(
        food.id,
        food.name,
        food.brand,
        localFood: food,
      );
    }
  }

  /// Indexa alimentos externos cacheados
  void indexCachedExternalFoods(List<OpenFoodFactsResult> foods) {
    _cachedExternalIndex.clear();
    
    for (final food in foods) {
      _cachedExternalIndex.addDocument(
        food.code,
        food.name,
        food.brand,
        externalFood: food,
      );
    }
  }

  /// Añade un alimento local al índice
  void addLocalFood(FoodModel food) {
    _localFoodsIndex.addDocument(
      food.id,
      food.name,
      food.brand,
      localFood: food,
    );
  }

  /// Añade un alimento externo al índice
  void addExternalFood(OpenFoodFactsResult food) {
    _cachedExternalIndex.addDocument(
      food.code,
      food.name,
      food.brand,
      externalFood: food,
    );
  }

  /// Búsqueda híbrida: local + cache externo
  /// Retorna resultados ordenados por relevancia
  List<IndexedSearchResult> search(String query, {int maxResults = 20}) {
    // Buscar en ambos índices
    final localResults = _localFoodsIndex.search(query, maxResults: maxResults ~/ 2);
    final externalResults = _cachedExternalIndex.search(query, maxResults: maxResults ~/ 2);
    
    // Combinar y reordenar
    final allResults = [...localResults, ...externalResults];
    
    // Boost para alimentos locales (prioridad) y ordenar
    final boostedResults = allResults.map((result) {
      if (result.isLocal) {
        // Los locales tienen prioridad
        return IndexedSearchResult(
          id: result.id,
          name: result.name,
          brand: result.brand,
          score: result.score * 1.2,
          isLocal: result.isLocal,
          localFood: result.localFood,
          externalFood: result.externalFood,
        );
      }
      return result;
    }).toList();
    
    boostedResults.sort((a, b) => b.score.compareTo(a.score));
    
    // Eliminar duplicados (mismo nombre/marca)
    final seen = <String>{};
    final uniqueResults = <IndexedSearchResult>[];
    
    for (final result in boostedResults) {
      final key = '${result.name}|${result.brand ?? ''}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueResults.add(result);
      }
    }
    
    return uniqueResults.take(maxResults).toList();
  }

  /// Búsqueda rápida para autocompletar
  List<IndexedSearchResult> searchForAutocomplete(String query, {int maxResults = 10}) {
    final localResults = _localFoodsIndex.searchPrefix(query, maxResults: maxResults ~/ 2);
    final externalResults = _cachedExternalIndex.searchPrefix(query, maxResults: maxResults ~/ 2);
    
    final allResults = [...localResults, ...externalResults];
    allResults.sort((a, b) => b.score.compareTo(a.score));
    
    // Eliminar duplicados
    final seen = <String>{};
    final uniqueResults = <IndexedSearchResult>[];
    
    for (final result in allResults) {
      final key = '${result.name}|${result.brand ?? ''}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueResults.add(result);
      }
    }
    
    return uniqueResults.take(maxResults).toList();
  }

  /// Verifica si el índice tiene datos
  bool get hasData => _localFoodsIndex.documentCount > 0 || _cachedExternalIndex.documentCount > 0;

  /// Estadísticas del índice
  Map<String, int> get stats => {
    'localFoods': _localFoodsIndex.documentCount,
    'cachedExternal': _cachedExternalIndex.documentCount,
  };
}
