import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/diary_providers.dart';
import '../../../core/providers/weight_providers.dart';
import '../../../core/tdee/tdee_engine.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(dayTotalsProvider);
    final latestWeightAsync = ref.watch(latestWeightProvider);

    final day = ref.watch(selectedDayProvider);
    final tdeeAsync = ref.watch(tdeeEstimateProvider(day));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            totalsAsync.when(
              data: (t) => Text('Kcal today: ${t.kcal}'),
              loading: () => const Text('Kcal today: —'),
              error: (e, st) => Text('Error: $e'),
            ),
            const SizedBox(height: 8),
            latestWeightAsync.when(
              data: (w) => Text('Last weight: ${w?.weightKg ?? '—'} kg'),
              loading: () => const Text('Last weight: —'),
              error: (e, st) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            tdeeAsync.when(
              data: (v) => Text('TDEE estimate: ${v.toStringAsFixed(0)} kcal'),
              loading: () => const Text('TDEE estimate: —'),
              error: (e, st) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
