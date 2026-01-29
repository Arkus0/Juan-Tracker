import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';

/// Pantalla de resumen con totales y estadísticas
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalsAsync = ref.watch(dailyTotalsProvider);
    final targetsAsync = ref.watch(currentTargetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de totales del día
            totalsAsync.when(
              data: (totals) => _DailySummaryCard(totals: totals),
              loading: () => const _DailySummaryCard(totals: DailyTotals.empty),
              error: (e, st) => const _DailySummaryCard(totals: DailyTotals.empty),
            ),
            const SizedBox(height: 24),

            // Objetivos actuales
            Text(
              'OBJETIVOS',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            targetsAsync.when(
              data: (targets) => _TargetsCard(targets: targets),
              loading: () => const _TargetsCard(),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
            const SizedBox(height: 24),

            // Progreso hacia objetivos
            if (targetsAsync.hasValue && totalsAsync.hasValue)
              _ProgressSection(
                totals: totalsAsync.value!,
                targets: targetsAsync.value,
              ),
          ],
        ),
      ),
    );
  }
}

/// Card con resumen del día
class _DailySummaryCard extends StatelessWidget {
  final DailyTotals totals;

  const _DailySummaryCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withAlpha((0.3 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Hoy has consumido',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${totals.kcal}',
                  style: GoogleFonts.montserrat(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('kcal'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MacroStat(
                  label: 'Proteína',
                  value: '${totals.protein.toStringAsFixed(0)}g',
                  color: Colors.red.shade400,
                ),
                _MacroStat(
                  label: 'Carbohidratos',
                  value: '${totals.carbs.toStringAsFixed(0)}g',
                  color: Colors.amber.shade600,
                ),
                _MacroStat(
                  label: 'Grasa',
                  value: '${totals.fat.toStringAsFixed(0)}g',
                  color: Colors.blue.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Card de objetivos
class _TargetsCard extends StatelessWidget {
  final TargetsModel? targets;

  const _TargetsCard({this.targets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (targets == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No tienes objetivos configurados.\nConfigúralos para ver tu progreso.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TargetRow(
              icon: Icons.local_fire_department,
              label: 'Calorías',
              value: '${targets!.kcalTarget} kcal',
              color: Colors.orange,
            ),
            if (targets!.proteinTarget != null)
              _TargetRow(
                icon: Icons.fitness_center,
                label: 'Proteína',
                value: '${targets!.proteinTarget!.toStringAsFixed(0)}g',
                color: Colors.red,
              ),
            if (targets!.carbsTarget != null)
              _TargetRow(
                icon: Icons.grain,
                label: 'Carbohidratos',
                value: '${targets!.carbsTarget!.toStringAsFixed(0)}g',
                color: Colors.amber,
              ),
            if (targets!.fatTarget != null)
              _TargetRow(
                icon: Icons.water_drop,
                label: 'Grasa',
                value: '${targets!.fatTarget!.toStringAsFixed(0)}g',
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TargetRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Sección de progreso hacia objetivos
class _ProgressSection extends StatelessWidget {
  final DailyTotals totals;
  final TargetsModel? targets;

  const _ProgressSection({
    required this.totals,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    if (targets == null) return const SizedBox.shrink();



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESO',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        _ProgressBar(
          label: 'Calorías',
          current: totals.kcal.toDouble(),
          target: targets!.kcalTarget.toDouble(),
          color: Colors.orange,
        ),
        if (targets!.proteinTarget != null)
          _ProgressBar(
            label: 'Proteína',
            current: totals.protein,
            target: targets!.proteinTarget!,
            color: Colors.red,
          ),
        if (targets!.carbsTarget != null)
          _ProgressBar(
            label: 'Carbohidratos',
            current: totals.carbs,
            target: targets!.carbsTarget!,
            color: Colors.amber,
          ),
        if (targets!.fatTarget != null)
          _ProgressBar(
            label: 'Grasa',
            current: totals.fat,
            target: targets!.fatTarget!,
            color: Colors.blue,
          ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / target).clamp(0.0, 1.0);
    final percentage = ((current / target) * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)} ($percentage%)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withAlpha((0.2 * 255).round()),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PROVIDERS ADICIONALES PARA SUMMARY
// ============================================================================

/// Provider de objetivos actuales
final currentTargetsProvider = FutureProvider<TargetsModel?>((ref) async {
  final repo = ref.watch(targetsRepositoryProvider);
  return repo.getCurrent();
});
