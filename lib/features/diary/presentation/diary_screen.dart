import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/router/app_router.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/diet/services/day_summary_calculator.dart';
import 'package:juan_tracker/features/targets/presentation/targets_screen.dart';
import 'food_search_screen.dart';

enum DiaryViewMode { list, calendar }

/// Notifier para controlar el modo de vista del diario
class DiaryViewModeNotifier extends Notifier<DiaryViewMode> {
  @override
  DiaryViewMode build() => DiaryViewMode.list;

  void toggle() {
    state = state == DiaryViewMode.list 
        ? DiaryViewMode.calendar 
        : DiaryViewMode.list;
  }

  void setMode(DiaryViewMode mode) => state = mode;
}

final diaryViewModeProvider = NotifierProvider<DiaryViewModeNotifier, DiaryViewMode>(
  DiaryViewModeNotifier.new,
);

/// Pantalla principal del Diario con diseño mejorado y vista de calendario
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final entriesAsync = ref.watch(dayEntriesStreamProvider);
    final summaryAsync = ref.watch(daySummaryProvider);
    final viewMode = ref.watch(diaryViewModeProvider);

    return Scaffold(
      // UX-005: Edge-to-edge support
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          // App Bar con fecha y acciones
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Diario'),
            centerTitle: true,
            actions: [
              // Toggle vista
              Semantics(
                button: true,
                label: viewMode == DiaryViewMode.list 
                    ? 'Cambiar a vista calendario' 
                    : 'Cambiar a vista lista',
                child: IconButton(
                  icon: Icon(
                    viewMode == DiaryViewMode.list 
                        ? Icons.calendar_month 
                        : Icons.list,
                  ),
                  tooltip: viewMode == DiaryViewMode.list 
                      ? 'Vista calendario' 
                      : 'Vista lista',
                  onPressed: () {
                    ref.read(diaryViewModeProvider.notifier).toggle();
                  },
                ),
              ),
              Semantics(
                button: true,
                label: 'Ir al día de hoy',
                child: TextButton(
                  onPressed: () => ref.read(selectedDateProvider.notifier).goToToday(),
                  child: const Text('HOY'),
                ),
              ),
            ],
          ),

          // Selector de fecha horizontal (calendario semanal) - solo en vista lista
          if (viewMode == DiaryViewMode.list)
            SliverToBoxAdapter(
              child: _WeekCalendar(
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  ref.read(selectedDateProvider.notifier).setDate(date);
                },
              ),
            ),

          // Vista de calendario mensual
          if (viewMode == DiaryViewMode.calendar)
            SliverToBoxAdapter(
              child: _MonthCalendar(
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  ref.read(selectedDateProvider.notifier).setDate(date);
                  // Volver a vista lista al seleccionar
                  ref.read(diaryViewModeProvider.notifier).setMode(DiaryViewMode.list);
                },
              ),
            ),

          // Resumen del día con progreso - solo en vista lista
          if (viewMode == DiaryViewMode.list)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: summaryAsync.when(
                  data: (summary) => _DailySummaryCard(summary: summary),
                  loading: () => const DiarySkeleton(),
                  error: (_, _) => AppError(
                    message: 'Error al cargar resumen',
                    onRetry: () => ref.invalidate(daySummaryProvider),
                  ),
                ),
              ),
            ),

          // 🎯 HIGH-003: Smart Suggestions - Sugerencias basadas en hora/historial
          if (viewMode == DiaryViewMode.list)
            SliverToBoxAdapter(
              child: _SmartSuggestionsSection(
                onSuggestionTap: (suggestion) => _quickAddFromSuggestion(context, ref, suggestion),
              ),
            ),

          // Quick Add - Comidas recientes (UX-003)
          if (viewMode == DiaryViewMode.list)
            SliverToBoxAdapter(
              child: _QuickAddSection(
                onQuickAdd: (entry) => _quickAddEntry(context, ref, entry),
              ),
            ),

          // Lista de comidas - solo en vista lista
          if (viewMode == DiaryViewMode.list)
            entriesAsync.when(
              // 🎯 MED-006: Empty state educativo con contexto temporal
              data: (entries) {
                if (entries.isEmpty) {
                  final hour = DateTime.now().hour;
                  final mealSuggestion = hour < 11
                      ? 'desayuno'
                      : hour < 15
                          ? 'almuerzo'
                          : hour < 19
                              ? 'merienda'
                              : 'cena';
                  final suggestedMealType = hour < 11
                      ? MealType.breakfast
                      : hour < 15
                          ? MealType.lunch
                          : hour < 19
                              ? MealType.snack
                              : MealType.dinner;

                  return SliverFillRemaining(
                    child: AppEmpty(
                      icon: Icons.restaurant_menu_outlined,
                      title: '¡Empieza a registrar tu día!',
                      subtitle:
                          'Registrar lo que comes te ayuda a entender tus patrones '
                          'y alcanzar tus objetivos. Tus comidas frecuentes se guardarán '
                          'para añadirlas más rápido la próxima vez.',
                      actionLabel: 'AÑADIR $mealSuggestion'.toUpperCase(),
                      onAction: () => _showAddEntry(context, ref, suggestedMealType),
                    ),
                  );
                }
                return _MealsListSliver(entries: entries);
              },
              loading: () => const SliverFillRemaining(
                child: DiarySkeleton(),
              ),
              error: (e, _) => SliverFillRemaining(
                child: AppError(
                  message: 'Error al cargar entradas',
                  details: e.toString(),
                ),
              ),
            ),

          // Espacio en vista calendario
          if (viewMode == DiaryViewMode.calendar)
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
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
    context.pushTo(AppRouter.nutritionFoods);
  }

  /// 🎯 HIGH-003: Quick add desde sugerencia inteligente
  Future<void> _quickAddFromSuggestion(BuildContext context, WidgetRef ref, SmartFoodSuggestion suggestion) async {
    HapticFeedback.mediumImpact();

    final selectedDate = ref.read(selectedDateProvider);
    final repo = ref.read(diaryRepositoryProvider);
    final currentMealType = ref.read(currentMealTypeProvider);

    // Crear nueva entrada basada en la sugerencia
    final newEntry = suggestion.toEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: selectedDate,
      mealType: currentMealType,
    );

    await repo.insert(newEntry);

    if (context.mounted) {
      AppSnackbar.showWithUndo(
        context,
        message: '${suggestion.foodName} añadido a ${currentMealType.displayName}',
        onUndo: () async {
          await repo.delete(newEntry.id);
        },
      );
    }
  }

  /// Quick add: copia una entrada existente al día seleccionado
  Future<void> _quickAddEntry(BuildContext context, WidgetRef ref, DiaryEntryModel template) async {
    HapticFeedback.mediumImpact();

    final selectedDate = ref.read(selectedDateProvider);
    final repo = ref.read(diaryRepositoryProvider);

    // Crear nueva entrada basada en la plantilla
    final newEntry = DiaryEntryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: selectedDate,
      mealType: MealType.snack, // Default a snack para quick add
      foodId: template.foodId,
      foodName: template.foodName,
      foodBrand: template.foodBrand,
      amount: template.amount,
      unit: template.unit,
      kcal: template.kcal,
      protein: template.protein,
      carbs: template.carbs,
      fat: template.fat,
      isQuickAdd: template.isQuickAdd,
      notes: null,
      createdAt: DateTime.now(),
    );

    await repo.insert(newEntry);

    if (context.mounted) {
      AppSnackbar.showWithUndo(
        context,
        message: '${template.foodName} añadido',
        onUndo: () async {
          await repo.delete(newEntry.id);
        },
      );
    }
  }
}

/// Vista de calendario mensual
/// 🎯 MED-002: Añade indicadores de cumplimiento
class _MonthCalendar extends ConsumerWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthCalendar({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final entryDaysAsync = ref.watch(calendarEntryDaysProvider);

    // 🎯 MED-002: Cargar días con entradas para marcadores
    final entryDays = entryDaysAsync.when(
      data: (days) => days,
      loading: () => <DateTime>{},
      error: (_, __) => <DateTime>{},
    );

    return Card(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: selectedDate,
              selectedDayPredicate: (day) => isSameDay(day, selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                onDateSelected(selectedDay);
              },
              // 🎯 MED-002: Cargar eventos para marcadores
              eventLoader: (day) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                return entryDays.contains(normalizedDay) ? [true] : [];
              },
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'es_ES',
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: colorScheme.onSurface,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface,
                ),
                titleTextStyle: AppTypography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: colorScheme.onSurface),
                holidayTextStyle: TextStyle(color: colorScheme.onSurface),
                defaultTextStyle: TextStyle(color: colorScheme.onSurface),
                selectedDecoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                selectedTextStyle: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                markersMaxCount: 1,
                markerSize: 6,
                markerDecoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                weekendStyle: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // 🎯 MED-002: Leyenda de marcadores
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Día con registros',
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
    final dates = List.generate(14, (i) => weekStart.add(Duration(days: i)));

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        // Performance: itemExtent fijo evita cálculos de layout por item
        itemExtent: 52,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
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
                    : (isToday ? colors.primaryContainer : colors.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: (isToday && !isSelected) ? Border.all(color: colors.primary) : null,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${date.day}',
                        style: AppTypography.dataSmall.copyWith(
                          color: isSelected ? colors.onPrimary : colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isToday)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected ? colors.onPrimary : colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
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

/// Card de resumen diario con macros - CRIT-04: Muestra RESTANTE prominentemente
class _DailySummaryCard extends StatelessWidget {
  final DaySummary summary;

  const _DailySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasTargets = summary.hasTargets;
    final kcalRemaining = summary.progress.kcalRemaining ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con calorías - CRIT-04: Mostrar RESTANTE como dato principal
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasTargets ? 'Te quedan' : 'Consumido',
                      style: AppTypography.labelMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          hasTargets ? '$kcalRemaining' : '${summary.consumed.kcal}',
                          style: AppTypography.dataLarge.copyWith(
                            color: _getKcalColor(kcalRemaining, hasTargets, colors),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kcal',
                          style: AppTypography.dataSmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    // Mostrar consumido como secundario cuando hay targets
                    if (hasTargets) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Consumido: ${summary.consumed.kcal} / ${summary.targets!.kcalTarget}',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasTargets)
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

          // Macros - QW-02: Mostrar RESTANTES en lugar de CONSUMIDOS
          Row(
            children: [
              Expanded(
                child: _MacroItem(
                  label: 'Proteína',
                  value: _calculateRemaining(
                    summary.targets?.proteinTarget,
                    summary.consumed.protein,
                  ),
                  target: summary.targets?.proteinTarget?.toStringAsFixed(0),
                  color: AppColors.error,
                  progress: summary.progress.proteinPercent ?? 0,
                  showRemaining: summary.hasTargets,
                ),
              ),
              Expanded(
                child: _MacroItem(
                  label: 'Carbs',
                  value: _calculateRemaining(
                    summary.targets?.carbsTarget,
                    summary.consumed.carbs,
                  ),
                  target: summary.targets?.carbsTarget?.toStringAsFixed(0),
                  color: AppColors.warning,
                  progress: summary.progress.carbsPercent ?? 0,
                  showRemaining: summary.hasTargets,
                ),
              ),
              Expanded(
                child: _MacroItem(
                  label: 'Grasa',
                  value: _calculateRemaining(
                    summary.targets?.fatTarget,
                    summary.consumed.fat,
                  ),
                  target: summary.targets?.fatTarget?.toStringAsFixed(0),
                  color: AppColors.info,
                  progress: summary.progress.fatPercent ?? 0,
                  showRemaining: summary.hasTargets,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Color del texto de kcal basado en estado
  Color _getKcalColor(int remaining, bool hasTargets, ColorScheme colors) {
    if (!hasTargets) return colors.primary;
    if (remaining <= 0) return AppColors.error;  // Pasó el objetivo
    if (remaining < 200) return AppColors.warning;  // Poco margen
    return colors.primary;  // OK
  }

  /// Calcula el valor restante de un macro
  String _calculateRemaining(double? target, double consumed) {
    if (target == null) return consumed.toStringAsFixed(0);
    final remaining = (target - consumed).clamp(0, double.infinity);
    return remaining.toStringAsFixed(0);
  }
}

/// Donut de progreso calórico
class _MacroDonut extends StatelessWidget {
  final double progress;
  final int? remaining;

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
                '${remaining ?? '--'}',
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

/// Item de macro individual - QW-02: Soporta mostrar RESTANTE
class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final String? target;
  final Color color;
  final double? progress;
  final bool showRemaining;

  const _MacroItem({
    required this.label,
    required this.value,
    this.target,
    required this.color,
    required this.progress,
    this.showRemaining = false,
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
              showRemaining ? '$label rest.' : label,
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
        if (target != null && !showRemaining)
          Text(
            '/${target}g',
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        if (target != null && showRemaining)
          Text(
            'de ${target}g',
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (progress ?? 0).clamp(0.0, 1.0),
            minHeight: 4,
            // QW-10: Mejor contraste en light mode
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? color.withAlpha((0.3 * 255).round())
                : color.withAlpha((0.2 * 255).round()),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// 🎯 HIGH-003: Sección de sugerencias inteligentes basadas en hora e historial
class _SmartSuggestionsSection extends ConsumerWidget {
  final void Function(SmartFoodSuggestion) onSuggestionTap;

  const _SmartSuggestionsSection({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(smartFoodSuggestionsProvider);
    final contextMessage = ref.watch(mealContextMessageProvider);
    final currentMealType = ref.watch(currentMealTypeProvider);
    final colors = Theme.of(context).colorScheme;

    return suggestionsAsync.when(
      data: (suggestions) {
        if (suggestions.isEmpty) {
          // Sin historial para este tipo de comida - no mostrar nada
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con contexto temporal
              Row(
                children: [
                  Icon(
                    _getMealIcon(currentMealType),
                    size: 16,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      contextMessage.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    currentMealType.displayName,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Grid de sugerencias
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: suggestions.take(3).map((suggestion) {
                  return _SmartSuggestionChip(
                    suggestion: suggestion,
                    onTap: () => onSuggestionTap(suggestion),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  IconData _getMealIcon(MealType mealType) {
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
}

/// Chip de sugerencia inteligente con contexto
class _SmartSuggestionChip extends StatelessWidget {
  final SmartFoodSuggestion suggestion;
  final VoidCallback onTap;

  const _SmartSuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: AppColors.goldAccent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 16,
                color: AppColors.goldAccent,
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.foodName.length > 18
                        ? '${suggestion.foodName.substring(0, 18)}...'
                        : suggestion.foodName,
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${suggestion.kcal} kcal',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          suggestion.reason,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.goldAccent,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sección de Quick Add - Comidas recientes para añadir con 1 tap (UX-003)
class _QuickAddSection extends ConsumerWidget {
  final void Function(DiaryEntryModel) onQuickAdd;

  const _QuickAddSection({required this.onQuickAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentFoodsAsync = ref.watch(recentFoodsProvider);
    final colors = Theme.of(context).colorScheme;

    return recentFoodsAsync.when(
      data: (recentFoods) {
        if (recentFoods.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'AÑADIR RÁPIDO',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentFoods.length,
                  // Performance: prototypeItem calcula tamaño una sola vez
                  prototypeItem: recentFoods.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: _QuickAddChip(
                            food: recentFoods.first,
                            onTap: () {},
                          ),
                        )
                      : null,
                  itemBuilder: (context, index) {
                    final food = recentFoods[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < recentFoods.length - 1 ? AppSpacing.sm : 0,
                      ),
                      child: _QuickAddChip(
                        food: food,
                        onTap: () => onQuickAdd(food),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Chip individual para quick add
class _QuickAddChip extends StatelessWidget {
  final DiaryEntryModel food;
  final VoidCallback onTap;

  const _QuickAddChip({
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.foodName.length > 15
                        ? '${food.foodName.substring(0, 15)}...'
                        : food.foodName,
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${food.kcal} kcal',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onPrimaryContainer.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
/// MD-002: Usa provider memoizado para totales, evita cálculos en build
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
    // MD-002: Usar provider memoizado en lugar de calcular en cada build
    final totals = ref.watch(mealTotalsProvider(mealType));

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
                  onPressed: () => _addEntry(context, ref),
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

  // MD-002: Eliminado _calculateTotals(), ahora usa provider memoizado
  // Los totales se calculan una sola vez por cambio de datos, no en cada build

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
