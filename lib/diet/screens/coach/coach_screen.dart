/// Pantalla principal del Coach Adaptativo
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/app_router.dart';
// import '../../../core/app_constants.dart';
import '../../providers/coach_providers.dart';
import '../../services/adaptive_coach_service.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(coachPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Adaptativo'),
        centerTitle: true,
      ),
      body: plan == null
          ? _EmptyCoachState(onCreatePlan: () => _navigateToSetup(context))
          : _ActiveCoachState(
              plan: plan,
              onCheckIn: () => _navigateToCheckIn(context),
              onEditPlan: () => _navigateToSetup(context, plan: plan, ref: ref),
            ),
    );
  }

  void _navigateToSetup(BuildContext context, {CoachPlan? plan, WidgetRef? ref}) {
    // Guardar el plan en edición si existe
    if (plan != null && ref != null) {
      ref.read(editingPlanProvider.notifier).setPlan(plan);
    }
    context.goToCoachSetup();
  }

  void _navigateToCheckIn(BuildContext context) {
    context.goToCoachCheckIn();
  }
}

/// Estado vacío - sin plan activo
class _EmptyCoachState extends StatelessWidget {
  final VoidCallback onCreatePlan;

  const _EmptyCoachState({required this.onCreatePlan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_graph,
            size: 80,
            color: colorScheme.primary.withAlpha(128),
          ),
          const SizedBox(height: 24),
          Text(
            'Coach Adaptativo',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'El Coach ajusta tus objetivos calóricos automáticamente '
            'basándose en tu progreso real, como MacroFactor.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _InfoCard(
            title: '¿Cómo funciona?',
            items: const [
              '1. Define tu objetivo (perder, mantener, ganar)',
              '2. Elige velocidad en kg/semana (no %!)',
              '3. Selecciona preset de macros (low carb, high protein...)',
              '4. Registra peso y comida diariamente',
              '5. Haz check-in semanal para ajustar targets',
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onCreatePlan,
            icon: const Icon(Icons.add),
            label: const Text('CREAR PLAN'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _showLearnMore(context),
            child: const Text('Saber más sobre el algoritmo'),
          ),
        ],
      ),
    );
  }

  void _showLearnMore(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('El Algoritmo'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fórmula:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('TDEE = AVG_kcal - (ΔPeso × 7700 / días)'),
              SizedBox(height: 16),
              Text(
                'Velocidad en kg/semana:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• 0.25-0.5 kg/semana = pérdida saludable\n'
                '• 0.25-0.5 kg/semana = ganancia limpia\n'
                '• Se calcula el déficit/superávit en kcal',
              ),
              SizedBox(height: 16),
              Text(
                'Presets de macros:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Low Carb: menos carbs, más grasa\n'
                '• Balanced: distribución 30/35/35\n'
                '• High Protein: 40% proteína para músculo',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }
}

/// Estado activo - con plan en marcha
class _ActiveCoachState extends StatelessWidget {
  final CoachPlan plan;
  final VoidCallback onCheckIn;
  final VoidCallback onEditPlan;

  const _ActiveCoachState({
    required this.plan,
    required this.onCheckIn,
    required this.onEditPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final daysSinceStart = DateTime.now().difference(plan.startDate).inDays;
    final lastCheckIn = plan.lastCheckInDate;
    final daysSinceCheckIn = lastCheckIn != null
        ? DateTime.now().difference(lastCheckIn).inDays
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta del plan actual
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu objetivo',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.onSurface.withAlpha(179),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan.goalDescriptionShort,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onEditPlan,
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar plan',
                      color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _StatRow(
                    label: 'Velocidad',
                    value: '${plan.weeklyRateKg.abs().toStringAsFixed(2)} kg/semana',
                  ),
                  _StatRow(
                    label: 'Ajuste diario',
                    value: '${plan.dailyAdjustmentKcal} kcal ${
                      plan.goal == WeightGoal.lose 
                          ? 'déficit' 
                          : plan.goal == WeightGoal.gain 
                              ? 'superávit' 
                              : ''
                    }',
                    highlight: true,
                  ),
                  _StatRow(
                    label: 'Macros',
                    value: plan.macroPreset.displayName,
                  ),
                  _StatRow(
                    label: 'Días activo',
                    value: '$daysSinceStart días',
                  ),
                  _StatRow(
                    label: 'Peso inicial',
                    value: '${plan.startingWeight.toStringAsFixed(1)} kg',
                  ),
                  _StatRow(
                    label: 'Último check-in',
                    value: daysSinceCheckIn != null
                        ? 'Hace $daysSinceCheckIn días'
                        : 'Nunca',
                  ),
                  if (plan.currentKcalTarget != null)
                    _StatRow(
                      label: 'Target actual',
                      value: '${plan.currentKcalTarget} kcal',
                      highlight: true,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botón de check-in
          if (daysSinceCheckIn == null || daysSinceCheckIn >= 6)
            FilledButton.icon(
              onPressed: onCheckIn,
              icon: const Icon(Icons.fact_check),
              label: const Text('CHECK-IN SEMANAL'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _showWaitDialog(context, 7 - daysSinceCheckIn),
              icon: const Icon(Icons.timer),
              label: Text(
                'CHECK-IN EN ${7 - daysSinceCheckIn} DÍAS',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),

          const SizedBox(height: 16),

          // Nota informativa
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Recomendación',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Haz check-in una vez por semana, el mismo día. '
                  'Usa tus pesos de la mañana en ayunas para mayor consistencia.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(204),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón para eliminar plan
          TextButton.icon(
            onPressed: () => _confirmDeletePlan(context),
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            label: Text(
              'Eliminar plan',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showWaitDialog(BuildContext context, int daysRemaining) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Espera un poco más'),
        content: Text(
          'Para obtener mejores resultados, espera al menos 7 días '
          'entre check-ins. Quedan $daysRemaining días.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlan(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar plan?'),
        content: const Text(
          'Se eliminará tu plan actual y el historial de check-ins. '
          'Los targets guardados no se verán afectados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Ejecutar eliminación
              final container = ProviderScope.containerOf(context);
              container.read(coachPlanProvider.notifier).deletePlan();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withAlpha(128),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(179),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
