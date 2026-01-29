import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/diet/services/day_summary_calculator.dart';
import 'package:juan_tracker/features/targets/presentation/targets_screen.dart';
import 'food_search_screen.dart';

/// Pantalla principal del Diario con diseño mejorado
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final entriesAsync = ref.watch(dayEntriesStreamProvider);
    final summaryAsync = ref.watch(daySummaryProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar con fecha y acciones
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Diario'),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () => ref.read(selectedDateProvider.notifier).goToToday(),
                child: const Text('HOY'),
              ),
            ],
          ),

          // Selector de fecha horizontal (calendario semanal)
          SliverToBoxAdapter(
            child: _WeekCalendar(
              selectedDate: selectedDate,
              onDateSelected: (date) {
                ref.read(selectedDateProvider.notifier).date = date;
              },
            ),
          ),

          // Resumen del día con progreso
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: summaryAsync.when(
                data: (summary) => _DailySummaryCard(summary: summary),
                loading: () => const AppSkeleton(
                  width: double.infinity,
                  height: 200,
                ),
                error: (_, __) => AppError(
                  message: 'Error al cargar resumen',
                  onRetry: () => ref.invalidate(daySummaryProvider),
                ),
              ),
            ),
          ),

          // Lista de comidas
          entriesAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return SliverFillRemaining(
                  child: AppEmpty(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'Sin entradas hoy',
                    subtitle: 'Añade tu primera comida para empezar a trackear',
                    actionLabel: 'AÑADIR COMIDA',
                    onAction: () => _showAddEntry(context, ref, MealType.breakfast),
                  ),
                );
              }
              return _MealsListSliver(entries: entries);
            },
            loading: () => const SliverFillRemaining(
              child: AppLoading(message: 'Cargando entradas...'),
            ),
            error: (e, _) => SliverFillRemaining(
              child: AppError(
                message: 'Error al cargar entradas',
                details: e.toString(),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      floatingActionButton: AppFAB(
        onPressed: () => _showAddEntry(context, ref, MealType.snack),
        icon: Icons.add_rounded,
        label: 'Añadir',
      ),
    );
  }

  void _showAddEntry(BuildContext context, WidgetRef ref, MealType mealType) {
    ref.read(selectedMealTypeProvider.notifier).meal = mealType;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FoodSearchScreen(),
      ),
    );
  }
}

/// Calendario semanal horizontal
class _WeekCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekCalendar({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 14, // 2 semanas
        itemBuilder: (context, index) {
          final date = weekStart.add(Duration(days: index));
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isSameDay(date, now);
          final dayName = DateFormat('E', 'es').format(date)[0].toUpperCase();

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onDateSelected(date);
            },
            child: AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : isToday
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: isToday && !isSelected
                    ? Border.all(color: colors.primary)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayName,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: AppTypography.dataSmall.copyWith(
                      color: isSelected
                          ? colors.onPrimary
                          : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isToday)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.onPrimary
                            : colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Card de resumen diario con macros
class _DailySummaryCard extends StatelessWidget {
  final DaySummary summary;

  const _DailySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con calorías principales
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calorías',
                      style: AppTypography.labelMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${summary.consumed.kcal}',
                          style: AppTypography.dataLarge.copyWith(
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (summary.hasTargets) ...[
                          Text(
                            '/ ${summary.targets!.kcalTarget}',
                            style: AppTypography.dataSmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (summary.hasTargets)
                _MacroDonut(
                  progress: summary.progress.kcalPercent ?? 0,
                  remaining: summary.progress.kcalRemaining,
                ),
            ],
          ),

          if (!summary.hasTargets) ...[
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TargetsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.track_changes, color: colors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configura tus objetivos',
                            style: AppTypography.labelLarge.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'Define calorías y macros',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.onPrimaryContainer
                                  .withAlpha((0.7 * 255).round()),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.primary),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),

          // Macros
          Row(
            children: [
              Expanded(
                child: _MacroItem(
                  label: 'Proteína',
                  value: summary.consumed.protein.toStringAsFixed(0),
                  target: summary.targets?.proteinTarget.toStringAsFixed(0),
                  color: AppColors.error,
                  progress: summary.progress.proteinPercent ?? 0,
                ),
              ),
              Expanded(
                child: _MacroItem(
                  label: 'Carbs',
                  value: summary.consumed.carbs.toStringAsFixed(0),
                  target: summary.targets?.carbsTarget.toStringAsFixed(0),
                  color: AppColors.warning,
                  progress: summary.progress.carbsPercent ?? 0,
                ),
              ),
              Expanded(
                child: _MacroItem(
                  label: 'Grasa',
                  value: summary.consumed.fat.toStringAsFixed(0),
                  target: summary.targets?.fatTarget.toStringAsFixed(0),
                  color: AppColors.info,
                  progress: summary.progress.fatPercent ?? 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Donut de progreso calórico
class _MacroDonut extends StatelessWidget {
  final double progress;
  final int remaining;

  const _MacroDonut({
    required this.progress,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 8,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              colors.surfaceContainerHighest,
            ),
          ),
          CircularProgressIndicator(
            value: clampedProgress,
            strokeWidth: 8,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              clampedProgress > 1.0 ? AppColors.error : colors.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(clampedProgress * 100).toInt()}%',
                style: AppTypography.labelLarge.copyWith(
                  color: colors.onSurface,
                ),
              ),
              Text(
                '$remaining',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Item de macro individual
class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final String? target;
  final Color color;
  final double progress;

  const _MacroItem({
    required this.label,
    required this.value,
    this.target,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${value}g',
          style: AppTypography.dataSmall.copyWith(
            color: colors.onSurface,
          ),
        ),
        if (target != null)
          Text(
            '/${target}g',
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: color.withAlpha((0.2 * 255).round()),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Lista de comidas tipo Sliver
class _MealsListSliver extends StatelessWidget {
  final List<DiaryEntryModel> entries;

  const _MealsListSliver({required this.entries});

  @override
  Widget build(BuildContext context) {
    final meals = [
      MealType.breakfast,
      MealType.lunch,
      MealType.dinner,
      MealType.snack,
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= meals.length) return null;
          final mealType = meals[index];
          final mealEntries = entries
              .where((e) => e.mealType == mealType)
              .toList();

          return _MealSection(
            mealType: mealType,
            entries: mealEntries,
          );
        },
        childCount: meals.length,
      ),
    );
  }
}

/// Sección de tipo de comida
class _MealSection extends ConsumerWidget {
  final MealType mealType;
  final List<DiaryEntryModel> entries;

  const _MealSection({
    required this.mealType,
    required this.entries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final totals = _calculateTotals();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    _getMealIcon(),
                    size: 18,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mealType.displayName.toUpperCase(),
                    style: AppTypography.labelLarge.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
                if (entries.isNotEmpty)
                  Text(
                    '${totals.kcal} kcal',
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 8),
                AppIconButton(
                  icon: Icons.add_rounded,
                  onTap: () => _addEntry(context, ref),
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                ),
              ],
            ),

            // Entradas
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Sin entradas',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...entries.map((entry) => _EntryTile(entry: entry)),
          ],
        ),
      ),
    );
  }

  Macros _calculateTotals() {
    int kcal = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    for (final e in entries) {
      kcal += e.kcal;
      protein += e.protein ?? 0;
      carbs += e.carbs ?? 0;
      fat += e.fat ?? 0;
    }
    return Macros(kcal: kcal, protein: protein, carbs: carbs, fat: fat);
  }

  IconData _getMealIcon() {
    switch (mealType) {
      case MealType.breakfast:
        return Icons.wb_sunny_outlined;
      case MealType.lunch:
        return Icons.wb_cloudy_outlined;
      case MealType.dinner:
        return Icons.nights_stay_outlined;
      case MealType.snack:
        return Icons.cookie_outlined;
    }
  }

  void _addEntry(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    ref.read(selectedMealTypeProvider.notifier).meal = mealType;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FoodSearchScreen()),
    );
  }
}

/// Tile de entrada individual
class _EntryTile extends ConsumerWidget {
  final DiaryEntryModel entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_outline, color: colors.error),
      ),
      onDismissed: (_) => _deleteEntry(ref),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(
          entry.foodName,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _getSubtitle(),
          style: AppTypography.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${entry.kcal}',
              style: AppTypography.labelLarge.copyWith(
                color: colors.primary,
              ),
            ),
            Text(
              ' kcal',
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
        onTap: () => _editEntry(context, ref),
      ),
    );
  }

  String _getSubtitle() {
    final amount = entry.amount == entry.amount.roundToDouble()
        ? entry.amount.toInt().toString()
        : entry.amount.toString();

    String unitText;
    switch (entry.unit) {
      case ServingUnit.grams:
        unitText = 'g';
        break;
      case ServingUnit.portion:
        unitText = entry.amount > 1 ? 'porciones' : 'porción';
        break;
      case ServingUnit.milliliter:
        unitText = 'ml';
        break;
    }

    final parts = <String>['$amount $unitText'];

    if (entry.protein != null && entry.protein! > 0) {
      parts.add('P: ${entry.protein!.toStringAsFixed(0)}g');
    }
    if (entry.carbs != null && entry.carbs! > 0) {
      parts.add('C: ${entry.carbs!.toStringAsFixed(0)}g');
    }
    if (entry.fat != null && entry.fat! > 0) {
      parts.add('G: ${entry.fat!.toStringAsFixed(0)}g');
    }

    return parts.join(' • ');
  }

  void _editEntry(BuildContext context, WidgetRef ref) {
    ref.read(editingEntryProvider.notifier).editing = entry;
    ref.read(selectedMealTypeProvider.notifier).meal = entry.mealType;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FoodSearchScreen(isEditing: true),
      ),
    );
    ref.read(editingEntryProvider.notifier).editing = null;
  }

  Future<void> _deleteEntry(WidgetRef ref) async {
    final repo = ref.read(diaryRepositoryProvider);
    await repo.delete(entry.id);
  }
}
