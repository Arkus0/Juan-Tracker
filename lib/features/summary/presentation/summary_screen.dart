import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/home_button.dart';
import '../../../diet/providers/diet_providers.dart';
import '../../../diet/services/day_summary_calculator.dart';

/// Pantalla de resumen tipo "budget" con progreso detallado.
///
/// Muestra:
/// - Consumo del día vs objetivos
/// - Barras de progreso visuales
/// - Historial reciente
/// - Acceso rápido a gestión de objetivos
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(daySummaryProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: HomeButton(),
        ),
      ),
      body: summaryAsync.when(
        data: (summary) => _SummaryContent(
          summary: summary,
          selectedDate: selectedDate,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

/// Contenido principal del resumen.
class _SummaryContent extends StatelessWidget {
  final DaySummary summary;
  final DateTime selectedDate;

  const _SummaryContent({
    required this.summary,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fecha del resumen
          _DateHeader(date: selectedDate),
          const SizedBox(height: 16),

          // Card principal de budget
          _BudgetCard(summary: summary),
          const SizedBox(height: 24),

          // Si no hay targets, mostrar CTA prominente
          if (!summary.hasTargets) ...[
            _CreateTargetsCTA(),
            const SizedBox(height: 24),
          ],

          // Desglose detallado
          Text(
            'DESGLOSE',
            style: _sectionStyle(context),
          ),
          const SizedBox(height: 12),
          _MacroBreakdown(summary: summary),
          const SizedBox(height: 24),

          // Estado del día
          Text(
            'ESTADO DEL DÍA',
            style: _sectionStyle(context),
          ),
          const SizedBox(height: 12),
          _DayStatusCard(summary: summary),
          const SizedBox(height: 24),

          // Biblioteca de Alimentos
          Text(
            'BIBLIOTECA',
            style: _sectionStyle(context),
          ),
          const SizedBox(height: 12),
          _LibraryCard(),
        ],
      ),
    );
  }

  TextStyle _sectionStyle(BuildContext context) {
    return GoogleFonts.montserrat(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Header con la fecha actual.
class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(date, DateTime.now());
    final dateText = isToday
        ? 'Hoy, ${DateFormat('d MMMM', 'es').format(date)}'
        : DateFormat('EEEE d MMMM yyyy', 'es').format(date);

    return Row(
      children: [
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          dateText,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Card principal de budget con calorías y progreso.
class _BudgetCard extends StatelessWidget {
  final DaySummary summary;

  const _BudgetCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasTarget = summary.hasTargets;
    final targetKcal = summary.targets?.kcalTarget ?? 0;
    final consumedKcal = summary.consumed.kcal;
    final remainingKcal = hasTarget ? targetKcal - consumedKcal : 0;
    final progress = hasTarget ? (consumedKcal / targetKcal).clamp(0.0, 1.0) : 0.0;
    final percentage = hasTarget ? ((consumedKcal / targetKcal) * 100).round() : 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'CALORÍAS',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Números principales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$consumedKcal',
                  style: GoogleFonts.montserrat(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasTarget)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '/ $targetKcal',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasTarget ? 'consumidas' : 'kcal consumidas',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            // Barra de progreso
            if (hasTarget) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.orange.shade100,
                  valueColor: AlwaysStoppedAnimation(
                    _getProgressColor(progress),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Información de progreso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BudgetStat(
                    label: 'Restantes',
                    value: '$remainingKcal',
                    unit: 'kcal',
                    color: remainingKcal >= 0 ? Colors.green : Colors.red,
                  ),
                  _BudgetStat(
                    label: 'Progreso',
                    value: '$percentage',
                    unit: '%',
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withAlpha((0.5 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sin objetivo configurado',
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.5) return Colors.green;
    if (progress < 0.8) return Colors.orange;
    if (progress <= 1.0) return Colors.red.shade400;
    return Colors.red.shade700;
  }
}

/// Estadística individual del budget.
class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _BudgetStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// CTA para crear objetivos cuando no hay ninguno.
class _CreateTargetsCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      elevation: 0,
      child: InkWell(
        onTap: () => context.pushTo(AppRouter.nutritionCoach),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.track_changes,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configura tus objetivos',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define calorías y macros para ver tu progreso y mantenerte en track.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desglose detallado de macros con barras de progreso.
class _MacroBreakdown extends StatelessWidget {
  final DaySummary summary;

  const _MacroBreakdown({required this.summary});

  @override
  Widget build(BuildContext context) {
    final targets = summary.targets;

    return Column(
      children: [
        _MacroProgressBar(
          label: 'Proteína',
          icon: Icons.fitness_center,
          consumed: summary.consumed.protein,
          target: targets?.proteinTarget,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 16),
        _MacroProgressBar(
          label: 'Carbohidratos',
          icon: Icons.grain,
          consumed: summary.consumed.carbs,
          target: targets?.carbsTarget,
          color: Colors.amber.shade600,
        ),
        const SizedBox(height: 16),
        _MacroProgressBar(
          label: 'Grasa',
          icon: Icons.water_drop,
          consumed: summary.consumed.fat,
          target: targets?.fatTarget,
          color: Colors.blue.shade400,
        ),
      ],
    );
  }
}

/// Barra de progreso individual para un macro.
class _MacroProgressBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double consumed;
  final double? target;
  final Color color;

  const _MacroProgressBar({
    required this.label,
    required this.icon,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = target != null && target! > 0;
    final progress = hasTarget ? (consumed / target!).clamp(0.0, 1.0) : 0.0;
    final percentage = hasTarget ? ((consumed / target!) * 100).round() : 0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    hasTarget
                        ? '${consumed.toStringAsFixed(0)} / ${target!.toStringAsFixed(0)}g ($percentage%)'
                        : '${consumed.toStringAsFixed(0)}g',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (hasTarget) ...[
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
            ],
          ),
        ),
      ],
    );
  }
}

/// Card con estado del día (análisis rápido).
class _DayStatusCard extends StatelessWidget {
  final DaySummary summary;

  const _DayStatusCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _calculateStatus();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: status.color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(status.icon, color: status.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _calculateStatus() {
    if (!summary.hasTargets) {
      return _StatusInfo(
        icon: Icons.info_outline,
        color: Colors.blue,
        title: 'Sin objetivo',
        message: 'Configura un objetivo para ver análisis del día.',
      );
    }

    if (!summary.hasConsumption) {
      return _StatusInfo(
        icon: Icons.restaurant_outlined,
        color: Colors.orange,
        title: 'Día vacío',
        message: 'Aún no has registrado consumo para este día.',
      );
    }

    final kcalPercent = summary.progress.kcalPercent ?? 0;
    if (kcalPercent < 0.5) {
      return _StatusInfo(
        icon: Icons.trending_down,
        color: Colors.green,
        title: 'Por debajo del objetivo',
        message: 'Tienes muchas calorías disponibles para el resto del día.',
      );
    } else if (kcalPercent < 0.9) {
      return _StatusInfo(
        icon: Icons.trending_flat,
        color: Colors.orange,
        title: 'En rango',
        message: 'Vas bien, mantén el control para llegar a tu objetivo.',
      );
    } else if (kcalPercent <= 1.0) {
      return _StatusInfo(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        title: 'Cerca del objetivo',
        message: '¡Bien! Estás muy cerca de tu objetivo diario.',
      );
    } else {
      return _StatusInfo(
        icon: Icons.warning_amber,
        color: Colors.red,
        title: 'Por encima del objetivo',
        message: 'Has superado tu objetivo calórico para hoy.',
      );
    }
  }
}

/// Card para acceder a la biblioteca de alimentos
class _LibraryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
      child: InkWell(
        onTap: () => context.pushTo(AppRouter.nutritionFoods),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tus Alimentos',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestionar biblioteca de alimentos guardados',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusInfo {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  _StatusInfo({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}
