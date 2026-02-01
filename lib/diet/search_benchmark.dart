/// Search Benchmark Runner for Juan Tracker
/// 
/// Debug-only utility to measure food search performance.
/// Runs standardized queries and reports p50/p95 latencies.
///
/// Usage:
///   final benchmark = SearchBenchmark(db, repository);
///   final results = await benchmark.runFullBenchmark();
///   print(results.toMarkdown());
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../training/database/database.dart';
import 'repositories/alimento_repository.dart';

// ============================================================================
// BENCHMARK RESULT MODELS
// ============================================================================

/// Results for a single query scenario
class QueryBenchmarkResult {
  final String queryName;
  final String query;
  final int iterations;
  final List<double> dbTimesMs;
  final List<double> rankingTimesMs;
  final List<double> totalTimesMs;
  final List<int> resultCounts;
  final bool usedFts;
  final String? error;

  QueryBenchmarkResult({
    required this.queryName,
    required this.query,
    required this.iterations,
    required this.dbTimesMs,
    required this.rankingTimesMs,
    required this.totalTimesMs,
    required this.resultCounts,
    required this.usedFts,
    this.error,
  });

  double get dbP50 => _percentile(dbTimesMs, 0.50);
  double get dbP95 => _percentile(dbTimesMs, 0.95);
  double get rankingP50 => _percentile(rankingTimesMs, 0.50);
  double get rankingP95 => _percentile(rankingTimesMs, 0.95);
  double get totalP50 => _percentile(totalTimesMs, 0.50);
  double get totalP95 => _percentile(totalTimesMs, 0.95);
  double get avgResultCount => resultCounts.isEmpty 
    ? 0 
    : resultCounts.reduce((a, b) => a + b) / resultCounts.length;

  double _percentile(List<double> data, double percentile) {
    if (data.isEmpty) return 0;
    final sorted = List<double>.from(data)..sort();
    final index = (percentile * (sorted.length - 1)).round();
    return sorted[index];
  }

  bool get meetsSla => totalP95 < 120; // Target: p95 < 120ms

  String toMarkdownRow() {
    final status = meetsSla ? '✅' : '❌';
    return '| $queryName | ${query.length} | '
        '${dbP50.toStringAsFixed(1)} | ${dbP95.toStringAsFixed(1)} | '
        '${rankingP50.toStringAsFixed(1)} | ${rankingP95.toStringAsFixed(1)} | '
        '${totalP50.toStringAsFixed(1)} | ${totalP95.toStringAsFixed(1)} | '
        '${avgResultCount.toStringAsFixed(0)} | ${usedFts ? 'FTS' : 'LIKE'} | $status |';
  }
}

/// Full benchmark run results
class BenchmarkResults {
  final DateTime runAt;
  final int foodCount;
  final int ftsIndexCount;
  final List<QueryBenchmarkResult> queryResults;
  final String deviceInfo;

  BenchmarkResults({
    required this.runAt,
    required this.foodCount,
    required this.ftsIndexCount,
    required this.queryResults,
    required this.deviceInfo,
  });

  bool get allMeetSla => queryResults.every((r) => r.meetsSla);
  
  int get passingQueries => queryResults.where((r) => r.meetsSla).length;

  String toMarkdown() {
    final buffer = StringBuffer();
    
    buffer.writeln('# Search Benchmark Results');
    buffer.writeln();
    buffer.writeln('> Generated: ${runAt.toIso8601String()}');
    buffer.writeln('> Device: $deviceInfo');
    buffer.writeln();
    buffer.writeln('## Database Stats');
    buffer.writeln();
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| Foods in DB | $foodCount |');
    buffer.writeln('| FTS index entries | $ftsIndexCount |');
    buffer.writeln('| SLA Target | p95 < 120ms TTFR |');
    buffer.writeln();
    buffer.writeln('## Query Latencies');
    buffer.writeln();
    buffer.writeln('| Query | Len | DB p50 | DB p95 | Rank p50 | Rank p95 | Total p50 | Total p95 | Results | Path | SLA |');
    buffer.writeln('|-------|-----|--------|--------|----------|----------|-----------|-----------|---------|------|-----|');
    
    for (final result in queryResults) {
      buffer.writeln(result.toMarkdownRow());
    }
    
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln();
    buffer.writeln('- **Queries passing SLA:** $passingQueries / ${queryResults.length}');
    buffer.writeln('- **Overall status:** ${allMeetSla ? '✅ ALL PASS' : '❌ NEEDS WORK'}');
    buffer.writeln();
    
    if (!allMeetSla) {
      buffer.writeln('### Failing Queries');
      buffer.writeln();
      for (final result in queryResults.where((r) => !r.meetsSla)) {
        buffer.writeln('- **${result.queryName}**: p95=${result.totalP95.toStringAsFixed(1)}ms (target <120ms)');
      }
    }
    
    return buffer.toString();
  }
}

// ============================================================================
// BENCHMARK RUNNER
// ============================================================================

/// Benchmark runner for food search performance
class SearchBenchmark {
  final AppDatabase db;
  final AlimentoRepository repository;
  
  static const int _defaultIterations = 200;

  SearchBenchmark(this.db, this.repository);

  /// Standard benchmark scenarios
  static const List<Map<String, String>> scenarios = [
    {'name': 'Short (2 chars)', 'query': 'le'},
    {'name': 'Medium (5 chars)', 'query': 'leche'},
    {'name': 'Multi-token', 'query': 'leche desnatada'},
    {'name': 'Common food', 'query': 'arroz integral'},
    {'name': 'Miss (random)', 'query': 'xyzqwerty123'},
  ];

  /// Run the full benchmark suite
  Future<BenchmarkResults> runFullBenchmark({
    int iterations = _defaultIterations,
    void Function(String)? onProgress,
  }) async {
    onProgress?.call('Gathering database stats...');
    
    // Get DB stats
    final foodCount = await _getFoodCount();
    final ftsCount = await _getFtsCount();
    
    onProgress?.call('Foods: $foodCount, FTS entries: $ftsCount');
    
    final results = <QueryBenchmarkResult>[];
    
    for (var i = 0; i < scenarios.length; i++) {
      final scenario = scenarios[i];
      final name = scenario['name']!;
      final query = scenario['query']!;
      
      onProgress?.call('Running "$name" ($query) - ${i + 1}/${scenarios.length}...');
      
      final result = await _runScenario(name, query, iterations);
      results.add(result);
      
      onProgress?.call('  → p95: ${result.totalP95.toStringAsFixed(1)}ms, '
          'results: ${result.avgResultCount.toStringAsFixed(0)}');
    }
    
    return BenchmarkResults(
      runAt: DateTime.now(),
      foodCount: foodCount,
      ftsIndexCount: ftsCount,
      queryResults: results,
      deviceInfo: _getDeviceInfo(),
    );
  }

  /// Run a single query scenario
  Future<QueryBenchmarkResult> _runScenario(
    String name,
    String query,
    int iterations,
  ) async {
    final dbTimes = <double>[];
    final rankingTimes = <double>[];
    final totalTimes = <double>[];
    final resultCounts = <int>[];
    bool usedFts = true;
    String? error;

    // Warmup run (not counted)
    try {
      await repository.search(query, limit: 50);
    } catch (e) {
      error = e.toString();
    }

    for (var i = 0; i < iterations; i++) {
      try {
        final totalStopwatch = Stopwatch()..start();
        final dbStopwatch = Stopwatch()..start();
        
        // Direct DB query (FTS)
        final dbResults = await db.searchFoodsFTS(query, limit: 50);
        dbStopwatch.stop();
        
        // Ranking/mapping time (simulated - repository does this)
        final rankingStopwatch = Stopwatch()..start();
        final results = await repository.search(query, limit: 50);
        rankingStopwatch.stop();
        totalStopwatch.stop();

        // Calculate ranking time by subtracting DB time
        final dbTimeMs = dbStopwatch.elapsedMicroseconds / 1000.0;
        final totalTimeMs = totalStopwatch.elapsedMicroseconds / 1000.0;
        final rankingTimeMs = (rankingStopwatch.elapsedMicroseconds / 1000.0) - dbTimeMs;

        dbTimes.add(dbTimeMs);
        rankingTimes.add(rankingTimeMs.clamp(0, double.infinity));
        totalTimes.add(totalTimeMs);
        resultCounts.add(results.length);
        
        // Check if FTS was used (if DB results match repository results)
        if (dbResults.isEmpty && results.isNotEmpty) {
          usedFts = false;
        }
      } catch (e) {
        // Log error but continue
        debugPrint('[Benchmark] Error in iteration $i: $e');
        error ??= e.toString();
      }
      
      // Small delay to prevent blocking
      if (i % 50 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    return QueryBenchmarkResult(
      queryName: name,
      query: query,
      iterations: iterations,
      dbTimesMs: dbTimes,
      rankingTimesMs: rankingTimes,
      totalTimesMs: totalTimes,
      resultCounts: resultCounts,
      usedFts: usedFts,
      error: error,
    );
  }

  Future<int> _getFoodCount() async {
    try {
      final result = await db.customSelect(
        'SELECT COUNT(*) as cnt FROM foods',
      ).getSingle();
      return result.data['cnt'] as int;
    } catch (e) {
      return -1;
    }
  }

  Future<int> _getFtsCount() async {
    try {
      final result = await db.customSelect(
        'SELECT COUNT(*) as cnt FROM foods_fts',
      ).getSingle();
      return result.data['cnt'] as int;
    } catch (e) {
      return -1;
    }
  }

  String _getDeviceInfo() {
    // Basic device info - could be enhanced with device_info_plus
    return 'Flutter ${kDebugMode ? 'debug' : 'profile/release'}';
  }
}

// ============================================================================
// QUICK BENCHMARK (for ad-hoc testing)
// ============================================================================

/// Run a quick benchmark and print results
Future<void> runQuickBenchmark(AppDatabase db, AlimentoRepository repository) async {
  if (!kDebugMode) {
    debugPrint('[Benchmark] Skipping benchmark in release mode');
    return;
  }

  debugPrint('\n${'=' * 60}');
  debugPrint('SEARCH BENCHMARK');
  debugPrint('=' * 60);

  final benchmark = SearchBenchmark(db, repository);
  final results = await benchmark.runFullBenchmark(
    iterations: 50, // Quick run with fewer iterations
    onProgress: (msg) => debugPrint('[Benchmark] $msg'),
  );

  debugPrint('\n${results.toMarkdown()}');
  debugPrint('=' * 60);
}
