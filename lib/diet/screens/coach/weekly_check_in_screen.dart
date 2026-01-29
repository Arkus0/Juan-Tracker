/// Pantalla de Check-in Semanal
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/coach_providers.dart';
import '../../services/adaptive_coach_service.dart';
import '../../../core/providers/database_provider.dart';

class WeeklyCheckInScreen extends ConsumerStatefulWidget {
  const WeeklyCheckInScreen({super.key});

  @override
  ConsumerState<WeeklyCheckInScreen> createState() =>
      _WeeklyCheckInScreenState();
}

class _WeeklyCheckInScreenState extends ConsumerState<WeeklyCheckInScreen> {
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final checkInAsync = ref.watch(weeklyCheckInProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Semanal'),
        centerTitle: true,
      ),
      body: checkInAsync.when(
        data: (checkIn) {
          if (checkIn == null) {
            return const Center(child: Text('No hay plan activo'));
          }
          return _buildContent(context, checkIn);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CheckInResult checkIn) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (checkIn.status == CheckInStatus.insufficientData) {
      return _InsufficientDataView(
        message: checkIn.errorMessage ?? 'Faltan datos',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Análisis de la semana',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDate(checkIn.weeklyData.startDate)} - '
            '${_formatDate(checkIn.weeklyData.endDate)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tus datos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DataRow(
                    icon: Icons.restaurant,
                    label: 'Ingesta media',
                    value: '${checkIn.weeklyData.avgDailyKcal.round()} kcal/dia',
                    color: colorScheme.primary,
                  ),
                  const Divider(height: 24),
                  _DataRow(
                    icon: Icons.trending_down,
                    label: 'Cambio de trend',
                    value: _formatWeightChange(checkIn.weeklyData.trendChangeKg),
                    color: _getChangeColor(checkIn.weeklyData.trendChangeKg),
                  ),
                  const Divider(height: 24),
                  _DataRow(
                    icon: Icons.local_fire_department,
                    label: 'TDEE estimado',
                    value: '${checkIn.estimatedTdee} kcal',
                    subtitle: 'Basado en tus datos reales',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: colorScheme.primaryContainer.withAlpha(51),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calculate, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Calculo',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...checkIn.explanation.allLines.map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          line,
                          style: theme.textTheme.bodyMedium,
                        ),
                      )),
                  if (checkIn.wasClamped)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              size: 20, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ajuste limitado por seguridad (max. 200 kcal/semana)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nuevos targets',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${checkIn.proposedTargets.kcalTarget} kcal',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _MacroRow(
                    label: 'Proteina',
                    value: checkIn.proposedTargets.proteinTarget,
                    unit: 'g',
                    color: Colors.red.shade400,
                  ),
                  _MacroRow(
                    label: 'Carbohidratos',
                    value: checkIn.proposedTargets.carbsTarget,
                    unit: 'g',
                    color: Colors.orange.shade400,
                  ),
                  _MacroRow(
                    label: 'Grasas',
                    value: checkIn.proposedTargets.fatTarget,
                    unit: 'g',
                    color: Colors.yellow.shade700,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _isApplying ? null : () => _applyCheckIn(checkIn),
            icon: _isApplying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(_isApplying ? 'APLICANDO...' : 'APLICAR NUEVOS TARGETS'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _applyCheckIn(CheckInResult checkIn) async {
    setState(() {
      _isApplying = true;
    });

    try {
      // Guardar el nuevo target
      final targetsRepo = ref.read(targetsRepositoryProvider);
      await targetsRepo.insert(checkIn.proposedTargets);

      // Actualizar el plan con el check-in aplicado
      await ref.read(coachPlanProvider.notifier).applyCheckIn(checkIn);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nuevos targets aplicados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatWeightChange(double change) {
    final sign = change > 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(2)} kg';
  }

  Color _getChangeColor(double change) {
    if (change.abs() < 0.05) return Colors.grey;
    return change < 0 ? Colors.green : Colors.red;
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(128),
                  ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value != null ? '${value!.round()} $unit' : '-',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsufficientDataView extends StatelessWidget {
  final String message;

  const _InsufficientDataView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights,
              size: 80,
              color: colorScheme.error.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'Faltan datos',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('VOLVER'),
            ),
          ],
        ),
      ),
    );
  }
}
