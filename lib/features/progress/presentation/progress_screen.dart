import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../weight/presentation/weight_screen.dart';
import '../../summary/presentation/summary_screen.dart';
import '../../../diet/screens/coach/coach_screen.dart';

/// Provider for the active segment within Progreso tab
enum ProgressSegment { weight, summary, coach }

class ProgressSegmentNotifier extends Notifier<ProgressSegment> {
  @override
  ProgressSegment build() => ProgressSegment.weight;

  void setSegment(ProgressSegment segment) => state = segment;
}

final progressSegmentProvider =
    NotifierProvider<ProgressSegmentNotifier, ProgressSegment>(
  ProgressSegmentNotifier.new,
);

/// Unified Progress screen that consolidates Weight, Summary, and Coach
/// into a single tab with segmented navigation.
///
/// This reduces cognitive load by grouping related "progress tracking"
/// features under one roof, following the principle:
/// "one tab = one intent (track my progress)".
///
/// NOTE: This widget does NOT use its own Scaffold because each sub-screen
/// (WeightScreen, SummaryScreen, CoachScreen) already has its own
/// Scaffold + SliverAppBar. Adding another Scaffold would create a
/// double-header UX problem.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(progressSegmentProvider);
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Segmented control — acts as sub-navigation within this tab
        Container(
          color: colors.surface,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<ProgressSegment>(
              segments: const [
                ButtonSegment(
                  value: ProgressSegment.weight,
                  label: Text('Peso'),
                  icon: Icon(Icons.scale, size: 18),
                ),
                ButtonSegment(
                  value: ProgressSegment.summary,
                  label: Text('Resumen'),
                  icon: Icon(Icons.dashboard, size: 18),
                ),
                ButtonSegment(
                  value: ProgressSegment.coach,
                  label: Text('Coach'),
                  icon: Icon(Icons.auto_graph, size: 18),
                ),
              ],
              selected: {segment},
              onSelectionChanged: (selected) {
                ref
                    .read(progressSegmentProvider.notifier)
                    .setSegment(selected.first);
              },
              style: SegmentedButton.styleFrom(
                selectedForegroundColor: colors.onPrimary,
                selectedBackgroundColor: colors.primary,
                foregroundColor: colors.onSurfaceVariant,
                textStyle: AppTypography.labelMedium,
              ),
            ),
          ),
        ),

        // Content — each sub-screen provides its own Scaffold + AppBar
        Expanded(
          child: IndexedStack(
            index: segment.index,
            children: const [
              WeightScreen(),
              SummaryScreen(),
              CoachScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
