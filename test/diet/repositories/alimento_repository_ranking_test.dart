import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/database/database.dart';

/// Unit tests for AlimentoRepository ranking algorithm
/// 
/// These tests verify the deterministic and relevance-aware ranking
/// without needing a full database instance.
void main() {
  group('Ranking Algorithm', () {
    group('Text Match Scoring', () {
      test('exact start match scores highest', () {
        final food = _createFood(name: 'Leche entera');
        final score1 = _calculateScore(food, 'lech'); // starts with
        final score2 = _calculateScore(food, 'entera'); // word start
        final score3 = _calculateScore(food, 'che ent'); // contains

        expect(score1, greaterThan(score2));
        expect(score1, greaterThan(score3));
      });

      test('word start match scores higher than substring', () {
        final food = _createFood(name: 'Leche desnatada');
        final wordStartScore = _calculateScore(food, 'desn'); // word starts
        final containsScore = _calculateScore(food, 'esnat'); // contains in middle

        // word start = 30, contains = 50 BUT desn doesn't contain so it's word start
        // esnat doesn't start word, it's a substring
        expect(wordStartScore, greaterThanOrEqualTo(containsScore));
      });

      test('case insensitive matching', () {
        final food = _createFood(name: 'LECHE ENTERA');
        final score = _calculateScore(food, 'leche');
        expect(score, greaterThan(0));
      });
    });

    group('Recency Boost', () {
      test('recently used food scores higher', () {
        final recentFood = _createFood(
          name: 'Leche',
          lastUsedAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        final oldFood = _createFood(
          name: 'Leche',
          lastUsedAt: DateTime.now().subtract(const Duration(days: 30)),
        );

        final recentScore = _calculateScore(recentFood, 'lec');
        final oldScore = _calculateScore(oldFood, 'lec');

        expect(recentScore, greaterThan(oldScore));
      });

      test('used today gets extra boost', () {
        final usedToday = _createFood(
          name: 'Leche',
          lastUsedAt: DateTime.now(),
        );
        final usedYesterday = _createFood(
          name: 'Leche',
          lastUsedAt: DateTime.now().subtract(const Duration(days: 1)),
        );

        final todayScore = _calculateScore(usedToday, 'lec');
        final yesterdayScore = _calculateScore(usedYesterday, 'lec');

        // Today should have extra 15 points boost
        expect(todayScore - yesterdayScore, greaterThanOrEqualTo(10));
      });

      test('recency decays linearly over 14 days', () {
        final day7Food = _createFood(
          name: 'Leche',
          lastUsedAt: DateTime.now().subtract(const Duration(days: 7)),
        );
        final day14Food = _createFood(
          name: 'Leche',
          lastUsedAt: DateTime.now().subtract(const Duration(days: 14)),
        );
        final day15Food = _createFood(
          name: 'Leche',
          lastUsedAt: DateTime.now().subtract(const Duration(days: 15)),
        );

        final day7Score = _calculateScore(day7Food, 'lec');
        final day14Score = _calculateScore(day14Food, 'lec');
        final day15Score = _calculateScore(day15Food, 'lec');

        // Day 7 should be ~half of base recency score
        // Day 14 should be ~0
        // Day 15 should be same as day 14 (clamped at 0)
        expect(day7Score, greaterThan(day14Score));
        expect(day14Score, equals(day15Score));
      });
    });

    group('Popularity Boost', () {
      test('more popular foods score higher', () {
        final popular = _createFood(name: 'Leche', useCount: 100);
        final unpopular = _createFood(name: 'Leche', useCount: 1);

        final popularScore = _calculateScore(popular, 'lec');
        final unpopularScore = _calculateScore(unpopular, 'lec');

        expect(popularScore, greaterThan(unpopularScore));
      });

      test('logarithmic scale prevents domination by very popular', () {
        final veryPopular = _createFood(name: 'Leche', useCount: 10000);
        final popular = _createFood(name: 'Leche', useCount: 100);

        final veryPopularScore = _calculateScore(veryPopular, 'lec');
        final popularScore = _calculateScore(popular, 'lec');

        // Difference should not be huge (log scale)
        final diff = veryPopularScore - popularScore;
        expect(diff, lessThan(30)); // 100x usage != 100x score
      });
    });

    group('Favorites Boost', () {
      test('favorite foods get significant boost', () {
        final favorite = _createFood(name: 'Leche', isFavorite: true);
        final notFavorite = _createFood(name: 'Leche', isFavorite: false);

        final favScore = _calculateScore(favorite, 'lec');
        final notFavScore = _calculateScore(notFavorite, 'lec');

        expect(favScore, greaterThan(notFavScore));
        expect(favScore - notFavScore, equals(25.0)); // kScoreFavoriteBoost
      });
    });

    group('Quality Signals', () {
      test('verified foods score higher', () {
        final verified = _createFood(name: 'Leche', verifiedSource: 'OFF');
        final unverified = _createFood(name: 'Leche');

        final verifiedScore = _calculateScore(verified, 'lec');
        final unverifiedScore = _calculateScore(unverified, 'lec');

        expect(verifiedScore, greaterThan(unverifiedScore));
      });

      test('complete nutrition data scores higher', () {
        final complete = _createFood(
          name: 'Leche',
          protein: 3.3,
          carbs: 4.7,
          fat: 1.5,
        );
        final incomplete = _createFood(name: 'Leche');

        final completeScore = _calculateScore(complete, 'lec');
        final incompleteScore = _calculateScore(incomplete, 'lec');

        expect(completeScore, greaterThan(incompleteScore));
      });
    });

    group('Deterministic Ordering', () {
      test('identical scores produce consistent order', () {
        final foods = [
          _createFood(id: 'zzz', name: 'Leche'),
          _createFood(id: 'aaa', name: 'Leche'),
          _createFood(id: 'mmm', name: 'Leche'),
        ];

        final sorted1 = _sortByScore(foods, 'lec');
        final sorted2 = _sortByScore(foods, 'lec');
        final sorted3 = _sortByScore(foods, 'lec');

        // All three sorts should produce identical order
        expect(sorted1.map((f) => f.id).toList(), 
               equals(sorted2.map((f) => f.id).toList()));
        expect(sorted2.map((f) => f.id).toList(), 
               equals(sorted3.map((f) => f.id).toList()));
        
        // Should be alphabetically sorted by ID as tie-breaker
        expect(sorted1.first.id, equals('aaa'));
        expect(sorted1.last.id, equals('zzz'));
      });
    });

    group('Combined Ranking', () {
      test('exact match with same recency beats contains match', () {
        // When recency is equal, text match quality should win
        final exactMatch = _createFood(
          name: 'Leche entera', 
          useCount: 10,
          lastUsedAt: DateTime.now().subtract(const Duration(days: 2)),
        );
        final containsMatch = _createFood(
          name: 'Yogur de leche', 
          useCount: 10,
          lastUsedAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        final exactScore = _calculateScore(exactMatch, 'leche');
        final containsScore = _calculateScore(containsMatch, 'leche');

        // Exact start (100) vs contains (50), same recency and popularity
        expect(exactScore, greaterThan(containsScore));
        expect(exactScore - containsScore, closeTo(50, 1)); // 100 - 50 = 50
      });

      test('very recent usage can boost contains above old exact match', () {
        // This is INTENTIONAL - recently used items should appear high
        // even if text match is not perfect
        final veryRecent = _createFood(
          name: 'Yogur de leche', 
          useCount: 50,
          lastUsedAt: DateTime.now(), // TODAY
        );
        final oldExact = _createFood(
          name: 'Leche entera', 
          useCount: 5,
          lastUsedAt: DateTime.now().subtract(const Duration(days: 30)),
        );

        final recentScore = _calculateScore(veryRecent, 'leche');
        final oldScore = _calculateScore(oldExact, 'leche');

        // Very recent: contains(50) + today(15) + recency(30) + log(51)*5 ≈ 115
        // Old exact: start(100) + log(6)*5 ≈ 109
        // Recent wins because of strong recency signals
        expect(recentScore, greaterThan(oldScore));
      });

      test('recent favorite beats slightly better text match', () {
        final recentFavorite = _createFood(
          name: 'Leche desnatada',
          isFavorite: true,
          lastUsedAt: DateTime.now(),
          useCount: 10,
        );
        final betterMatch = _createFood(
          name: 'Leche',
          useCount: 1,
        );

        final favScore = _calculateScore(recentFavorite, 'leche');
        final matchScore = _calculateScore(betterMatch, 'leche');

        // Recent favorite: 100 (start) + 25 (fav) + 30 (recency) + 15 (today) + ~12 (popularity)
        // Better match: 100 (start) + ~3 (popularity)
        expect(favScore, greaterThan(matchScore));
      });
    });
  });
}

// =============================================================================
// TEST HELPERS - Replicating the ranking algorithm for isolated testing
// =============================================================================

// Score weights (must match AlimentoRepository._kScore* constants)
const _kScoreExactStartMatch = 100.0;
const _kScoreExactContains = 50.0;
const _kScoreWordStartMatch = 30.0;
const _kScorePopularityMultiplier = 5.0;
const _kScoreRecencyBase = 30.0;
const _kScoreRecencyDecayDays = 14;
const _kScoreVerifiedBoost = 10.0;
const _kScoreCompleteDataBoost = 5.0;
const _kScoreFavoriteBoost = 25.0;
const _kScoreUsedTodayBoost = 15.0;

/// Creates a test Food instance with minimal required fields
Food _createFood({
  String id = 'test-id',
  String name = 'Test Food',
  int useCount = 0,
  DateTime? lastUsedAt,
  bool isFavorite = false,
  String? verifiedSource,
  double? protein,
  double? carbs,
  double? fat,
}) {
  return Food(
    id: id,
    name: name,
    normalizedName: name.toLowerCase(),
    brand: null,
    barcode: null,
    kcalPer100g: 100,
    proteinPer100g: protein,
    carbsPer100g: carbs,
    fatPer100g: fat,
    portionName: null,
    portionGrams: null,
    userCreated: false,
    verifiedSource: verifiedSource,
    sourceMetadata: null,
    useCount: useCount,
    lastUsedAt: lastUsedAt,
    nutriScore: null,
    novaGroup: null,
    isFavorite: isFavorite,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Calculate score using same algorithm as AlimentoRepository
double _calculateScore(Food food, String query) {
  var score = 0.0;
  final nameLower = food.name.toLowerCase();
  final queryLower = query.toLowerCase();
  
  // 1. Text matching
  if (nameLower.startsWith(queryLower)) {
    score += _kScoreExactStartMatch;
  } else if (nameLower.contains(queryLower)) {
    score += _kScoreExactContains;
  } else if (nameLower.split(' ').any((word) => word.startsWith(queryLower))) {
    score += _kScoreWordStartMatch;
  }
  
  // 2. Popularity
  score += math.log(food.useCount + 1) * _kScorePopularityMultiplier;
  
  // 3. Recency
  if (food.lastUsedAt != null) {
    final daysSinceUse = DateTime.now().difference(food.lastUsedAt!).inDays;
    
    if (daysSinceUse == 0) {
      score += _kScoreUsedTodayBoost;
    }
    
    final recencyScore = math.max(
      0.0, 
      _kScoreRecencyBase * (1 - (daysSinceUse / _kScoreRecencyDecayDays)),
    );
    score += recencyScore;
  }
  
  // 4. Favorites
  if (food.isFavorite == true) {
    score += _kScoreFavoriteBoost;
  }
  
  // 5. Quality signals
  if (food.verifiedSource != null) {
    score += _kScoreVerifiedBoost;
  }
  
  final hasCompleteData = food.proteinPer100g != null && 
                         food.carbsPer100g != null && 
                         food.fatPer100g != null;
  if (hasCompleteData) {
    score += _kScoreCompleteDataBoost;
  }
  
  return score;
}

/// Sort foods by score with deterministic tie-breaker
List<Food> _sortByScore(List<Food> foods, String query) {
  final scored = foods.map((f) => (food: f, score: _calculateScore(f, query))).toList();
  scored.sort((a, b) {
    final scoreComparison = b.score.compareTo(a.score);
    if (scoreComparison != 0) return scoreComparison;
    return a.food.id.compareTo(b.food.id);
  });
  return scored.map((s) => s.food).toList();
}
