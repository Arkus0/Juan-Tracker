// Weight Screen - Simplified version
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';

import 'package:intl/intl.dart';

class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Peso'),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _MainStatsSection(),
            ),
          ),
          _WeighInsListSliver(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
    );
  }
}

class _MainStatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);

    return trendAsync.when(
      data: (result) {
        if (result == null) {
          return AppEmpty(
            icon: Icons.scale_outlined,
            title: 'Sin registros',
            subtitle: 'Registra tu primer peso',
          );
        }
        return Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'Ultimo',
                value: result.latestWeight.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.scale_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: 'Tendencia',
                value: result.trendWeight.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.trending_flat,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: 'Semana',
                value: result.weeklyRate.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ),
          ],
        );
      },
      loading: () => const AppLoading(),
      error: (_, _) => AppError(
        message: 'Error al cargar',
        onRetry: () => ref.invalidate(weightTrendProvider),
      ),
    );
  }
}

class _WeighInsListSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighInsAsync = ref.watch(recentWeighInsProvider);

    return weighInsAsync.when(
      data: (weighIns) {
        if (weighIns.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final w = weighIns[index];
              return ListTile(
                leading: Icon(Icons.scale, color: Theme.of(context).colorScheme.primary),
                title: Text(' kg'),
                subtitle: Text(DateFormat('d MMM', 'es').format(w.dateTime)),
              );
            },
            childCount: weighIns.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: AppLoading()),
      error: (e, _) => SliverToBoxAdapter(
        child: AppError(message: 'Error: '),
      ),
    );
  }
}
