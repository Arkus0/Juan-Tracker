/// Pantalla para crear/editar el plan del Coach
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/coach_providers.dart';
import '../../services/adaptive_coach_service.dart';

class PlanSetupScreen extends ConsumerStatefulWidget {
  final CoachPlan? existingPlan;

  const PlanSetupScreen({super.key, this.existingPlan});

  @override
  ConsumerState<PlanSetupScreen> createState() => _PlanSetupScreenState();
}

class _PlanSetupScreenState extends ConsumerState<PlanSetupScreen> {
  late WeightGoal _goal;
  late double _weeklyRatePercent;
  late final TextEditingController _tdeeController;
  late final TextEditingController _weightController;
  bool _isLoading = false;

  final List<_GoalOption> _goalOptions = [
    _GoalOption(
      goal: WeightGoal.lose,
      title: 'Perder peso',
      subtitle: 'Déficit calórico para pérdida de grasa',
      icon: Icons.trending_down,
      color: Colors.green,
    ),
    _GoalOption(
      goal: WeightGoal.maintain,
      title: 'Mantener peso',
      subtitle: 'Balance calórico para mantenimiento',
      icon: Icons.trending_flat,
      color: Colors.blue,
    ),
    _GoalOption(
      goal: WeightGoal.gain,
      title: 'Ganar peso',
      subtitle: 'Superávit calórico para ganancia muscular',
      icon: Icons.trending_up,
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final plan = widget.existingPlan;
    _goal = plan?.goal ?? WeightGoal.lose;
    _weeklyRatePercent = plan?.weeklyRatePercent ?? -0.005;
    _tdeeController = TextEditingController(
      text: plan?.initialTdeeEstimate.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: plan?.startingWeight.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _tdeeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPlan == null ? 'Nuevo Plan' : 'Editar Plan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selección de objetivo
            Text(
              '1. Elige tu objetivo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._goalOptions.map((option) => _GoalCard(
                  option: option,
                  isSelected: _goal == option.goal,
                  onTap: () => setState(() => _goal = option.goal),
                )),

            const SizedBox(height: 24),

            // Tasa de cambio
            Text(
              '2. Velocidad de cambio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Porcentaje de tu peso corporal por semana',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(height: 16),
            _buildRateSlider(),

            const SizedBox(height: 24),

            // TDEE estimado
            Text(
              '3. Estimación inicial de TDEE',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes usar una calculadora online o tu mejor estimación',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tdeeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'TDEE estimado (kcal)',
                suffixText: 'kcal',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Peso actual
            Text(
              '4. Tu peso actual',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Peso actual (kg)',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // Resumen
            Card(
              color: colorScheme.primaryContainer.withAlpha(51),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Objetivo', _getGoalDescription()),
                    _buildSummaryRow('Velocidad', _getRateDescription()),
                    _buildSummaryRow(
                        'TDEE inicial', '${_tdeeController.text} kcal'),
                    _buildSummaryRow(
                        'Peso inicial', '${_weightController.text} kg'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botón guardar
            FilledButton.icon(
              onPressed: _isLoading ? null : _savePlan,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading
                  ? 'GUARDANDO...'
                  : (widget.existingPlan == null ? 'CREAR PLAN' : 'ACTUALIZAR')),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRateSlider() {
    final minRate = _goal == WeightGoal.lose
        ? -0.01
        : _goal == WeightGoal.gain
            ? 0.0025
            : 0.0;
    final maxRate = _goal == WeightGoal.lose
        ? -0.0025
        : _goal == WeightGoal.gain
            ? 0.01
            : 0.0;

    // Si cambió el objetivo, ajustar la tasa
    if (_goal == WeightGoal.maintain) {
      _weeklyRatePercent = 0.0;
    } else if (_weeklyRatePercent == 0.0 ||
        (_goal == WeightGoal.lose && _weeklyRatePercent > 0) ||
        (_goal == WeightGoal.gain && _weeklyRatePercent < 0)) {
      _weeklyRatePercent = _goal == WeightGoal.lose ? -0.005 : 0.005;
    }

    if (_goal == WeightGoal.maintain) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Mantenimiento: sin cambio de peso'),
          ),
        ),
      );
    }

    return Column(
      children: [
        Slider(
          value: _weeklyRatePercent.abs(),
          min: minRate.abs(),
          max: maxRate.abs(),
          divisions: 7,
          label: '${(_weeklyRatePercent.abs() * 100).toStringAsFixed(2)}%',
          onChanged: (value) {
            setState(() {
              _weeklyRatePercent =
                  _goal == WeightGoal.lose ? -value : value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _goal == WeightGoal.lose ? 'Lento' : 'Conservador',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${(_weeklyRatePercent.abs() * 100).toStringAsFixed(1)}%/semana',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              _goal == WeightGoal.lose ? 'Agresivo' : 'Rápido',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  String _getGoalDescription() {
    switch (_goal) {
      case WeightGoal.lose:
        return 'Perder peso';
      case WeightGoal.maintain:
        return 'Mantener peso';
      case WeightGoal.gain:
        return 'Ganar peso';
    }
  }

  String _getRateDescription() {
    if (_goal == WeightGoal.maintain) return '0% (mantenimiento)';
    final percent = (_weeklyRatePercent.abs() * 100).toStringAsFixed(1);
    return '$percent% por semana';
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePlan() async {
    final tdee = int.tryParse(_tdeeController.text);
    final weight = double.tryParse(_weightController.text);

    if (tdee == null || tdee < 1000 || tdee > 6000) {
      _showError('TDEE inválido. Debe estar entre 1000 y 6000 kcal.');
      return;
    }

    if (weight == null || weight < 30 || weight > 300) {
      _showError('Peso inválido. Debe estar entre 30 y 300 kg.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(coachPlanProvider.notifier).createPlan(
            goal: _goal,
            weeklyRatePercent: _weeklyRatePercent,
            initialTdeeEstimate: tdee,
            startingWeight: weight,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class _GoalOption {
  final WeightGoal goal;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _GoalOption({
    required this.goal,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _GoalCard extends StatelessWidget {
  final _GoalOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? option.color.withAlpha(26)
          : colorScheme.surfaceContainerHighest.withAlpha(77),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: option.color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: option.color.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  option.icon,
                  color: option.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: option.color,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
