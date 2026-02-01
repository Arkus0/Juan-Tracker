/// Search Benchmark Screen - Debug only
/// 
/// Hidden screen for running food search performance benchmarks.
/// Access via long-press on version number in settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/widgets/app_card.dart';
import '../repositories/alimento_repository.dart';
import '../search_benchmark.dart';

// ============================================================================
// PROVIDERS (Riverpod 3 Notifier pattern)
// ============================================================================

/// Notifier for benchmark results
class BenchmarkResultsNotifier extends Notifier<BenchmarkResults?> {
  @override
  BenchmarkResults? build() => null;
  
  void setResults(BenchmarkResults? results) => state = results;
  void clear() => state = null;
}

/// Notifier for running state
class BenchmarkRunningNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setRunning(bool running) => state = running;
}

/// Notifier for progress messages
class BenchmarkProgressNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void setProgress(String message) => state = message;
  void clear() => state = '';
}

/// Provider for benchmark results
final benchmarkResultsProvider = NotifierProvider<BenchmarkResultsNotifier, BenchmarkResults?>(
  BenchmarkResultsNotifier.new,
);

/// Provider for benchmark running state
final benchmarkRunningProvider = NotifierProvider<BenchmarkRunningNotifier, bool>(
  BenchmarkRunningNotifier.new,
);

/// Provider for progress messages
final benchmarkProgressProvider = NotifierProvider<BenchmarkProgressNotifier, String>(
  BenchmarkProgressNotifier.new,
);

/// Debug screen for running search benchmarks
class SearchBenchmarkScreen extends ConsumerWidget {
  const SearchBenchmarkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(benchmarkResultsProvider);
    final isRunning = ref.watch(benchmarkRunningProvider);
    final progress = ref.watch(benchmarkProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔬 Search Benchmark'),
        actions: [
          if (results != null)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copiar Markdown',
              onPressed: () => _copyResults(context, results),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Benchmark de Búsqueda',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ejecuta 200 queries por escenario y mide:\n'
                    '• Tiempo de DB (FTS5)\n'
                    '• Tiempo de ranking/mapping\n'
                    '• TTFR total (Time To First Results)\n\n'
                    'SLA objetivo: p95 < 120ms para queries ≥3 chars',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Run button
            FilledButton.icon(
              onPressed: isRunning ? null : () => _runBenchmark(context, ref),
              icon: isRunning 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
              label: Text(isRunning ? 'Ejecutando...' : 'Ejecutar Benchmark'),
            ),

            // Progress
            if (isRunning && progress.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          progress,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Results
            if (results != null)
              Expanded(
                child: _ResultsView(results: results),
              )
            else if (!isRunning)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pulsa "Ejecutar" para iniciar el benchmark',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _runBenchmark(BuildContext context, WidgetRef ref) async {
    ref.read(benchmarkRunningProvider.notifier).setRunning(true);
    ref.read(benchmarkProgressProvider.notifier).setProgress('Iniciando...');
    ref.read(benchmarkResultsProvider.notifier).clear();

    try {
      final db = ref.read(appDatabaseProvider);
      final repository = ref.read(alimentoRepositoryProvider);
      
      final benchmark = SearchBenchmark(db, repository);
      final results = await benchmark.runFullBenchmark(
        iterations: 200,
        onProgress: (msg) {
          ref.read(benchmarkProgressProvider.notifier).setProgress(msg);
        },
      );

      ref.read(benchmarkResultsProvider.notifier).setResults(results);
    } catch (e) {
      debugPrint('[Benchmark] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      ref.read(benchmarkRunningProvider.notifier).setRunning(false);
      ref.read(benchmarkProgressProvider.notifier).clear();
    }
  }

  void _copyResults(BuildContext context, BenchmarkResults results) {
    Clipboard.setData(ClipboardData(text: results.toMarkdown()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resultados copiados al portapapeles')),
    );
  }
}

/// Results display widget
class _ResultsView extends StatelessWidget {
  final BenchmarkResults results;

  const _ResultsView({required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView(
      children: [
        // Summary card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    results.allMeetSla ? Icons.check_circle : Icons.warning,
                    color: results.allMeetSla 
                      ? Colors.green 
                      : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    results.allMeetSla ? 'TODOS PASAN SLA' : 'NECESITA TRABAJO',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: results.allMeetSla 
                        ? Colors.green 
                        : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatRow(
                label: 'Queries pasando SLA',
                value: '${results.passingQueries} / ${results.queryResults.length}',
              ),
              _StatRow(
                label: 'Alimentos en DB',
                value: results.foodCount.toString(),
              ),
              _StatRow(
                label: 'Entradas FTS',
                value: results.ftsIndexCount.toString(),
              ),
              _StatRow(
                label: 'Ejecutado',
                value: _formatTime(results.runAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Individual query results
        Text(
          'Resultados por Query',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        ...results.queryResults.map((r) => _QueryResultCard(result: r)),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueryResultCard extends StatelessWidget {
  final QueryBenchmarkResult result;

  const _QueryResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meetsSla = result.meetsSla;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.queryName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '"${result.query}" (${result.query.length} chars)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: meetsSla 
                      ? Colors.green.withAlpha(30)
                      : Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    meetsSla ? '✅ PASS' : '❌ FAIL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: meetsSla ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Metrics grid
            Row(
              children: [
                Expanded(
                  child: _MetricColumn(
                    label: 'DB',
                    p50: result.dbP50,
                    p95: result.dbP95,
                  ),
                ),
                Expanded(
                  child: _MetricColumn(
                    label: 'Ranking',
                    p50: result.rankingP50,
                    p95: result.rankingP95,
                  ),
                ),
                Expanded(
                  child: _MetricColumn(
                    label: 'Total',
                    p50: result.totalP50,
                    p95: result.totalP95,
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resultados: ${result.avgResultCount.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Path: ${result.usedFts ? 'FTS5' : 'LIKE'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: result.usedFts 
                      ? Colors.green 
                      : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final double p50;
  final double p95;
  final bool highlight;

  const _MetricColumn({
    required this.label,
    required this.p50,
    required this.p95,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p95Color = p95 < 120 ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'p50: ${p50.toStringAsFixed(1)}ms',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          'p95: ${p95.toStringAsFixed(1)}ms',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: highlight ? FontWeight.bold : null,
            color: highlight ? p95Color : null,
          ),
        ),
      ],
    );
  }
}
