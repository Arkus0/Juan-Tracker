import 'package:juan_tracker/training/features/exercises/search/exercise_aliases.dart';
import 'package:juan_tracker/training/features/exercises/search/exercise_search_engine.dart';
import 'package:juan_tracker/training/models/library_exercise.dart';

/// Resultado de búsqueda con puntuación para ordenamiento por relevancia
class ScoredExercise {
  final LibraryExercise exercise;
  final double score;
  final String matchType;

  const ScoredExercise({
    required this.exercise,
    required this.score,
    this.matchType = 'exact',
  });

  @override
  String toString() => '${exercise.name} (score: $score)';
}

/// Servicio de búsqueda inteligente de ejercicios con:
/// - Sinónimos en español/inglés
/// - Fuzzy matching para errores ortográficos
/// - Búsqueda por músculo y equipamiento
/// - Sugerencias cuando hay pocos resultados
class SmartExerciseSearchService {
  static final SmartExerciseSearchService _instance = SmartExerciseSearchService._internal();
  factory SmartExerciseSearchService() => _instance;
  SmartExerciseSearchService._internal();

  final ExerciseSearchEngine _engine = const ExerciseSearchEngine();

  /// Busca ejercicios con scoring inteligente
  /// 
  /// [query] - Término de búsqueda del usuario
  /// [allExercises] - Lista completa de ejercicios disponibles
  /// [filters] - Filtros opcionales (grupo muscular, equipamiento, favoritos)
  /// [limit] - Máximo de resultados a retornar
  List<ScoredExercise> search(
    String query,
    List<LibraryExercise> allExercises, {
    SearchFilters? filters,
    int limit = 50,
  }) {
    if (query.trim().isEmpty) {
      // Sin query, retornar todos los ejercicios filtrados
      final filtered = _applyFilters(allExercises, filters);
      return filtered
          .take(limit)
          .map((e) => ScoredExercise(exercise: e, score: 1.0, matchType: 'default'))
          .toList();
    }

    final results = _engine.search(
      query: query,
      allExercises: allExercises,
      filters: filters,
      limit: limit * 2, // Pedimos más para poder scorear
    );

    // Convertir a ScoredExercise con puntuaciones normalizadas
    ExerciseSearchIndex.build(allExercises);
    final queryInfo = _buildQueryInfo(query);

    return results.take(limit).map((exercise) {
      final entry = ExerciseSearchEntry.fromExercise(exercise);
      final rawScore = _engineScore(queryInfo, entry);
      final normalizedScore = _normalizeScore(rawScore);
      final matchType = _determineMatchType(queryInfo, entry);

      return ScoredExercise(
        exercise: exercise,
        score: normalizedScore,
        matchType: matchType,
      );
    }).toList();
  }

  /// Sugiere ejercicios alternativos cuando no hay resultados exactos
  /// 
  /// Útil cuando el usuario comete errores de ortografía o usa
  /// términos similares pero no exactos.
  List<ScoredExercise> suggestAlternatives(
    String query,
    List<LibraryExercise> allExercises, {
    SearchFilters? filters,
    int limit = 5,
  }) {
    if (query.length < 3) return [];

    final index = ExerciseSearchIndex.build(allExercises);
    final suggestions = _engine.suggest(query, index, filters: filters, limit: limit);

    return suggestions
        .map((e) => ScoredExercise(
              exercise: e,
              score: 0.5, // Score bajo porque es sugerencia
              matchType: 'suggestion',
            ))
        .toList();
  }

  /// Obtiene sugerencias de texto para autocompletar
  List<String> getTextSuggestions(
    String partial,
    List<LibraryExercise> allExercises, {
    int limit = 5,
  }) {
    if (partial.length < 2) return [];

    final normalized = normalize(partial);
    final suggestions = <String>{};

    // Buscar en aliases
    for (final entry in exerciseAliases.entries) {
      if (entry.key.startsWith(normalized)) {
        suggestions.add(entry.key);
        if (suggestions.length >= limit) break;
      }
      for (final alias in entry.value) {
        final aliasNorm = normalize(alias);
        if (aliasNorm.startsWith(normalized)) {
          suggestions.add(alias);
          if (suggestions.length >= limit) break;
        }
      }
    }

    // Buscar en nombres de ejercicios
    if (suggestions.length < limit) {
      for (final exercise in allExercises) {
        final nameNorm = normalize(exercise.name);
        if (nameNorm.startsWith(normalized)) {
          suggestions.add(exercise.name);
          if (suggestions.length >= limit) break;
        }
      }
    }

    return suggestions.toList();
  }

  /// Expande una query con todos sus sinónimos
  List<String> expandQuery(String query) {
    final normalized = normalize(query);
    final words = normalized.split(' ');
    final expanded = <String>{normalized};

    // Añadir sinónimos para cada palabra
    for (final word in words) {
      if (exerciseAliases.containsKey(word)) {
        for (final synonym in exerciseAliases[word]!) {
          final synonymNorm = normalize(synonym);
          expanded.add(normalized.replaceFirst(word, synonymNorm));
          expanded.add(synonymNorm);
        }
      }
      // También buscar en valores de aliases
      for (final entry in exerciseAliases.entries) {
        if (entry.value.any((v) => normalize(v) == word)) {
          expanded.add(entry.key);
          expanded.addAll(entry.value.map(normalize));
        }
      }
    }

    return expanded.toList();
  }

  /// Valida si una query tiene resultados potenciales
  bool hasPotentialResults(String query, List<LibraryExercise> allExercises) {
    if (query.length < 2) return true;
    
    final results = search(query, allExercises, limit: 1);
    return results.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  List<LibraryExercise> _applyFilters(
    List<LibraryExercise> exercises,
    SearchFilters? filters,
  ) {
    if (filters == null) return exercises;

    return exercises.where((e) {
      if (filters.favoritesOnly && !e.isFavorite) return false;
      
      if (filters.muscleGroup != null && filters.muscleGroup!.isNotEmpty) {
        final target = normalize(filters.muscleGroup!);
        if (normalize(e.muscleGroup) != target) return false;
      }
      
      if (filters.equipment != null && filters.equipment!.isNotEmpty) {
        final target = normalize(filters.equipment!);
        if (normalize(e.equipment) != target) return false;
      }
      
      return true;
    }).toList();
  }

  int _engineScore(_QueryInfo query, ExerciseSearchEntry entry) {
    // Reimplementación simplificada del scoring del engine
    final normalized = query.normalized;
    final nameNorm = entry.nameNorm;
    
    if (normalized == nameNorm) return 100;
    if (nameNorm.startsWith(normalized)) return 80;

    final tokenSet = entry.tokenSet;
    final tokens = query.allTokens;
    
    if (tokens.isNotEmpty) {
      final matches = tokens.where(tokenSet.contains).toList();
      if (matches.length == tokens.length) {
        return 60 - (matches.where(query.aliasTokens.contains).length * 3);
      }
      if (matches.isNotEmpty) {
        final missing = tokens.length - matches.length;
        return (40 - (missing * 5)).clamp(5, 40);
      }
    }

    // Fuzzy matching
    return _fuzzyScore(normalized, nameNorm) ?? 0;
  }

  int? _fuzzyScore(String query, String name) {
    if (query.isEmpty || name.isEmpty) return null;
    
    final maxDistance = (query.length * 0.25).round().clamp(1, 3);
    final distance = _levenshteinDistance(query, name, maxDistance);
    
    if (distance == null) return null;
    
    final maxLen = query.length > name.length ? query.length : name.length;
    final similarity = 1 - (distance / maxLen);
    
    if (similarity < 0.72) return null;
    
    return (20 + ((similarity - 0.72) * 100)).round().clamp(20, 35);
  }

  int? _levenshteinDistance(String s1, String s2, int maxDist) {
    if ((s1.length - s2.length).abs() > maxDist) return null;
    
    final m = s1.length;
    final n = s2.length;
    var prev = List<int>.generate(n + 1, (i) => i);
    var curr = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      var minInRow = curr[0];
      
      for (var j = 1; j <= n; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        curr[j] = [
          curr[j - 1] + 1,
          prev[j] + 1,
          prev[j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
        
        if (curr[j] < minInRow) minInRow = curr[j];
      }
      
      if (minInRow > maxDist) return null;
      
      final temp = prev;
      prev = curr;
      curr = temp;
    }
    
    return prev[n] <= maxDist ? prev[n] : null;
  }

  double _normalizeScore(int rawScore) {
    // Normalizar score de 0-100 a 0.0-1.0
    return (rawScore / 100).clamp(0.0, 1.0);
  }

  String _determineMatchType(_QueryInfo query, ExerciseSearchEntry entry) {
    final normalized = query.normalized;
    final nameNorm = entry.nameNorm;

    if (normalized == nameNorm) return 'exact';
    if (nameNorm.startsWith(normalized)) return 'prefix';
    if (query.allTokens.every(entry.tokenSet.contains)) return 'all_tokens';
    if (query.allTokens.any(entry.tokenSet.contains)) return 'some_tokens';
    return 'fuzzy';
  }

  _QueryInfo _buildQueryInfo(String query) {
    final normalized = normalize(query);
    final tokens = tokenize(normalized);
    final aliasTokens = <String>{};
    final expandedTokens = <String>{};

    void addAliases(String key) {
      if (expandedTokens.length >= 8) return;
      final aliasList = exerciseAliases[key];
      if (aliasList == null) return;
      
      for (final alias in aliasList) {
        final aliasNorm = normalize(alias);
        if (aliasNorm.isEmpty) continue;
        
        for (final token in tokenize(aliasNorm)) {
          if (expandedTokens.length >= 8) return;
          if (token.isEmpty) continue;
          expandedTokens.add(token);
          aliasTokens.add(token);
        }
      }
    }

    if (normalized.isNotEmpty) {
      addAliases(normalized);
    }
    for (final token in tokens) {
      addAliases(token);
    }

    return _QueryInfo(
      normalized: normalized,
      tokens: tokens,
      allTokens: {...tokens, ...expandedTokens}.toList(),
      aliasTokens: aliasTokens,
    );
  }
}

/// Información procesada de una query de búsqueda
class _QueryInfo {
  final String normalized;
  final List<String> tokens;
  final List<String> allTokens;
  final Set<String> aliasTokens;

  const _QueryInfo({
    required this.normalized,
    required this.tokens,
    required this.allTokens,
    required this.aliasTokens,
  });
}
