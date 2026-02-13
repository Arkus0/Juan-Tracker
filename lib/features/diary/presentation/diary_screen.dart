import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/router/app_router.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/diet/models/meal_template.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/diet/providers/meal_template_providers.dart';
import 'package:juan_tracker/diet/providers/quick_actions_provider.dart';
import 'package:juan_tracker/diet/services/day_summary_calculator.dart';
import 'package:juan_tracker/features/diary/presentation/edit_entry_dialog.dart';
import 'package:juan_tracker/features/home/providers/home_providers.dart';
import 'package:juan_tracker/training/database/database.dart' as db;

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

final diaryViewModeProvider =
    NotifierProvider<DiaryViewModeNotifier, DiaryViewMode>(
      DiaryViewModeNotifier.new,
    );

/// Notifier para controlar qué secciones de comida están expandidas.
///
/// Progressive disclosure: only the "current" meal (based on time of day)
/// starts expanded. Users can expand others on demand. This reduces
/// initial visual density from ~4 expanded sections to ~1.
class ExpandedMealsNotifier extends Notifier<Set<MealType>> {
  @override
  Set<MealType> build() {
    // Smart default: expand only the meal that's relevant right now
    final hour = DateTime.now().hour;
    if (hour < 11) return {MealType.breakfast};
    if (hour < 15) return {MealType.lunch};
    if (hour < 20) return {MealType.dinner};
    return {MealType.snack};
  }

  void toggle(MealType mealType) {
    final current = Set<MealType>.from(state);
    if (current.contains(mealType)) {
      current.remove(mealType);
    } else {
      current.add(mealType);
    }
    state = current;
  }
}

final expandedMealsProvider =
    NotifierProvider<ExpandedMealsNotifier, Set<MealType>>(
      ExpandedMealsNotifier.new,
    );

/// Pantalla principal del Diario con diseño estilo FatSecret
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final entriesAsync = ref.watch(dayEntriesStreamProvider);
    final summaryAsync = ref.watch(daySummaryProvider);
    final viewMode = ref.watch(diaryViewModeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Diario'),
            centerTitle: true,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: HomeButton(),
            ),
            actions: [
              // Toggle de vista con indicadores visuales claros
              _ViewModeToggle(
                viewMode: viewMode,
                onModeChanged: (mode) {
                  ref.read(diaryViewModeProvider.notifier).setMode(mode);
                },
              ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: 'Ir al día de hoy',
                child: TextButton(
                  onPressed: () =>
                      ref.read(selectedDateProvider.notifier).goToToday(),
                  child: const Text('HOY'),
                ),
              ),
            ],
          ),

          // Selector de fecha horizontal - solo en vista lista
          if (viewMode == DiaryViewMode.list)
            SliverToBoxAdapter(
              child: _WeekCalendar(
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  ref.read(selectedDateProvider.notifier).setDate(date);
                },
              ),
            ),

          // Vista de calendario mensual (arriba)
          if (viewMode == DiaryViewMode.calendar)
            SliverToBoxAdapter(
              child: _MonthCalendar(
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  ref.read(selectedDateProvider.notifier).setDate(date);
                },
              ),
            ),

          // Resumen del día
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

          // Quick Actions: Repetir ayer + Recientes
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _QuickActionsCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Secciones de comidas - siempre visibles
          entriesAsync.when(
            data: (entries) {
              // Agrupar entradas por tipo de comida
              final entriesByMeal = <MealType, List<DiaryEntryModel>>{};
              for (final entry in entries) {
                entriesByMeal.putIfAbsent(entry.mealType, () => []).add(entry);
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Desayuno
                    _MealSection(
                      mealType: MealType.breakfast,
                      entries: entriesByMeal[MealType.breakfast] ?? [],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Almuerzo
                    _MealSection(
                      mealType: MealType.lunch,
                      entries: entriesByMeal[MealType.lunch] ?? [],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Cena
                    _MealSection(
                      mealType: MealType.dinner,
                      entries: entriesByMeal[MealType.dinner] ?? [],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Snacks
                    _MealSection(
                      mealType: MealType.snack,
                      entries: entriesByMeal[MealType.snack] ?? [],
                    ),

                    const SizedBox(height: 100),
                  ]),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: DiarySkeleton()),
            error: (e, _) => SliverFillRemaining(
              child: AppError(
                message: 'Error al cargar entradas',
                details: e.toString(),
              ),
            ),
          ),

          // Espacio en vista calendario
          if (viewMode == DiaryViewMode.calendar)
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Sección de comida expandible (estilo FatSecret)
class _MealSection extends ConsumerWidget {
  final MealType mealType;
  final List<DiaryEntryModel> entries;

  const _MealSection({required this.mealType, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final expandedMeals = ref.watch(expandedMealsProvider);
    final isExpanded = expandedMeals.contains(mealType);

    // T5: Totals calculated per build. This is O(n) where n ~ 3-10 entries
    // per meal type. Total work is ~40 operations per rebuild, which is
    // acceptable. Rebuilds only occur when entries actually change.
    final totals = _calculateTotals(entries);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header expandible
          InkWell(
            onTap: () {
              ref.read(expandedMealsProvider.notifier).toggle(mealType);
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom: isExpanded
                  ? Radius.zero
                  : const Radius.circular(AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // Icono de comida
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _getMealColor(
                        mealType,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _getMealIcon(mealType),
                      color: _getMealColor(mealType),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Nombre y totales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealType.displayName,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (entries.isNotEmpty)
                          Text(
                            '${totals.kcal} kcal · P:${totals.protein.toStringAsFixed(0)}g · C:${totals.carbs.toStringAsFixed(0)}g · G:${totals.fat.toStringAsFixed(0)}g',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          )
                        else
                          Text(
                            'Sin alimentos',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.onSurfaceVariant.withAlpha(
                                (0.7 * 255).round(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Icono expandir/colapsar
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.onSurfaceVariant,
                  ),

                  // Menú de opciones (solo si hay entries)
                  if (entries.isNotEmpty)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: colors.onSurfaceVariant,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'save_template',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_add_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Guardar como plantilla'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'save_template') {
                          _showSaveAsTemplateDialog(
                            context,
                            ref,
                            mealType,
                            entries,
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ),

          // Contenido expandible
          if (isExpanded) ...[
            const Divider(height: 1),

            if (entries.isEmpty)
              ListTile(
                leading: Icon(
                  Icons.add_circle_outline,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                title: Text(
                  'Añadir ${mealType.displayName.toLowerCase()}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant.withAlpha(
                      (0.7 * 255).round(),
                    ),
                  ),
                ),
                onTap: () => _showAddEntry(context, ref, mealType),
              )
            else
              ...entries.map(
                (entry) => _EntryTile(
                  entry: entry,
                  onTap: () => _editEntry(context, ref, entry),
                  onDelete: () => _deleteEntry(context, ref, entry),
                ),
              ),

            // Botón añadir más
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextButton.icon(
                onPressed: () => _showAddEntry(context, ref, mealType),
                icon: const Icon(Icons.add),
                label: Text('Añadir a ${mealType.displayName.toLowerCase()}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddEntry(BuildContext context, WidgetRef ref, MealType mealType) {
    ref.read(selectedMealTypeProvider.notifier).meal = mealType;
    context.pushTo(AppRouter.nutritionFoodSearch);
  }

  void _editEntry(
    BuildContext context,
    WidgetRef ref,
    DiaryEntryModel entry,
  ) async {
    final result = await showDialog<DiaryEntryModel>(
      context: context,
      builder: (ctx) => EditEntryDialog(entry: entry),
    );

    if (result != null) {
      // T2 FIX: Add error handling to prevent silent failures
      try {
        await ref.read(diaryRepositoryProvider).update(result);
        if (context.mounted) {
          AppSnackbar.show(context, message: 'Entrada actualizada');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(context, message: 'Error al guardar: $e');
        }
      }
    }
  }

  void _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    DiaryEntryModel entry,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar entrada',
      message: '¿Eliminar "${entry.foodName}"?',
      confirmLabel: 'Eliminar',
      isDestructive: true,
    );

    if (confirmed) {
      // T2 FIX: Add error handling to prevent silent failures
      try {
        await ref.read(diaryRepositoryProvider).delete(entry.id);
        if (context.mounted) {
          AppSnackbar.show(context, message: 'Entrada eliminada');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(context, message: 'Error al eliminar: $e');
        }
      }
    }
  }

  void _showSaveAsTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    MealType mealType,
    List<DiaryEntryModel> entries,
  ) async {
    final nameController = TextEditingController(
      text: '${mealType.displayName} favorito',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar como plantilla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se guardarán ${entries.length} alimento(s):',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...entries
                .take(3)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      '• ${e.foodName}',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ),
            if (entries.length > 3)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '... y ${entries.length - 3} más',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la plantilla',
                hintText: 'Ej: Desayuno típico',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(nameController.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && context.mounted) {
      // Convertir DiaryEntryModel a DiaryEntry de la DB
      final dbEntries = await _convertToDbEntries(ref, entries);

      // Convertir MealType a db.MealType
      final dbMealType = _convertToDbMealType(mealType);

      final template = await ref
          .read(saveMealAsTemplateProvider.notifier)
          .save(name: result.trim(), mealType: dbMealType, entries: dbEntries);

      if (context.mounted) {
        if (template != null) {
          AppSnackbar.show(
            context,
            message: 'Plantilla "${template.name}" guardada',
          );
        } else {
          AppSnackbar.showError(
            context,
            message: 'Error al guardar la plantilla',
          );
        }
      }
    }
  }

  /// Convierte DiaryEntryModel a DiaryEntry de la DB
  Future<List<db.DiaryEntry>> _convertToDbEntries(
    WidgetRef ref,
    List<DiaryEntryModel> entries,
  ) async {
    if (entries.isEmpty) return [];

    final database = ref.read(appDatabaseProvider);
    final ids = entries.map((entry) => entry.id).toSet().toList();
    final fetchedEntries = await (database.select(
      database.diaryEntries,
    )..where((e) => e.id.isIn(ids))).get();

    final entriesById = {
      for (final dbEntry in fetchedEntries) dbEntry.id: dbEntry,
    };

    return entries
        .map((entry) => entriesById[entry.id])
        .whereType<db.DiaryEntry>()
        .toList();
  }

  /// Convierte MealType de modelo a MealType de DB
  db.MealType _convertToDbMealType(MealType mealType) => switch (mealType) {
    MealType.breakfast => db.MealType.breakfast,
    MealType.lunch => db.MealType.lunch,
    MealType.dinner => db.MealType.dinner,
    MealType.snack => db.MealType.snack,
  };

  IconData _getMealIcon(MealType type) {
    return switch (type) {
      MealType.breakfast => Icons.wb_sunny_outlined,
      MealType.lunch => Icons.wb_cloudy_outlined,
      MealType.dinner => Icons.nights_stay_outlined,
      MealType.snack => Icons.cookie_outlined,
    };
  }

  Color _getMealColor(MealType type) {
    return switch (type) {
      MealType.breakfast => Colors.orange,
      MealType.lunch => Colors.blue,
      MealType.dinner => Colors.indigo,
      MealType.snack => Colors.green,
    };
  }

  _MealTotals _calculateTotals(List<DiaryEntryModel> entries) {
    int kcal = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final entry in entries) {
      kcal += entry.kcal;
      protein += entry.protein ?? 0;
      carbs += entry.carbs ?? 0;
      fat += entry.fat ?? 0;
    }

    return _MealTotals(kcal: kcal, protein: protein, carbs: carbs, fat: fat);
  }
}

class _MealTotals {
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;

  _MealTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

/// Tile de entrada individual
class _EntryTile extends StatelessWidget {
  final DiaryEntryModel entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EntryTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: '${entry.foodName}, ${entry.kcal} calorías, deslizar para eliminar',
      child: Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => ConfirmDialog.show(
        context: context,
        title: 'Eliminar',
        message: '¿Eliminar "${entry.foodName}"?',
        confirmLabel: 'Eliminar',
        isDestructive: true,
      ),
      background: Container(
        color: colors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Icon(Icons.delete, color: colors.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(
          entry.foodName,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${entry.amount.toStringAsFixed(0)} ${entry.unit.name} · ${entry.kcal} kcal',
          style: AppTypography.bodySmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.kcal}',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            ),
            if (entry.protein != null && entry.protein! > 0)
              Text(
                'P:${entry.protein!.toStringAsFixed(0)}g',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
      ), // end Semantics
    );
  }
}

// ============================================================================
// WIDGETS EXISTENTES (Mantenidos del archivo original)
// ============================================================================

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
                    : (isToday
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: (isToday && !isSelected)
                    ? Border.all(color: colors.primary)
                    : null,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 52),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${date.day}',
                        style: AppTypography.dataSmall.copyWith(
                          color: isSelected
                              ? colors.onPrimary
                              : colors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
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

    final entryDays = entryDaysAsync.when(
      data: (days) => days,
      loading: () => <DateTime>{},
      error: (_, _) => <DateTime>{},
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

class _DailySummaryCard extends ConsumerWidget {
  final DaySummary summary;

  const _DailySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final hasTargets = summary.hasTargets;
    final kcalRemaining = summary.progress.kcalRemaining ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          hasTargets
                              ? '$kcalRemaining'
                              : '${summary.consumed.kcal}',
                          style: AppTypography.dataLarge.copyWith(
                            color: _getKcalColor(
                              kcalRemaining,
                              hasTargets,
                              colors,
                            ),
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
                ref.read(homeTabProvider.notifier).goToCoach();
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
                            'Configura tu plan en Coach',
                            style: AppTypography.labelLarge.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'Define calorías y macros',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.onPrimaryContainer.withAlpha(
                                (0.7 * 255).round(),
                              ),
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
                  isOver: _isOverTarget(
                    summary.targets?.proteinTarget,
                    summary.consumed.protein,
                  ),
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
                  isOver: _isOverTarget(
                    summary.targets?.carbsTarget,
                    summary.consumed.carbs,
                  ),
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
                  isOver: _isOverTarget(
                    summary.targets?.fatTarget,
                    summary.consumed.fat,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getKcalColor(int remaining, bool hasTargets, ColorScheme colors) {
    if (!hasTargets) return colors.primary;
    if (remaining <= 0) return AppColors.error;
    if (remaining < 200) return AppColors.warning;
    return colors.primary;
  }

  /// Calcula el valor restante o exceso de un macro
  /// Si hay exceso, retorna el valor con + prefijo (ej: "+15")
  String _calculateRemaining(double? target, double consumed) {
    if (target == null) return consumed.toStringAsFixed(0);
    final remaining = target - consumed;
    if (remaining < 0) {
      // Exceso: mostrar como "+X"
      return '+${(-remaining).toStringAsFixed(0)}';
    }
    return remaining.toStringAsFixed(0);
  }

  /// Verifica si un macro está en exceso
  bool _isOverTarget(double? target, double consumed) {
    if (target == null) return false;
    return consumed > target;
  }
}

class _MacroDonut extends StatelessWidget {
  final double progress;
  final int? remaining;

  const _MacroDonut({required this.progress, required this.remaining});

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
          // Solo el % centrado
          Text(
            '${(clampedProgress * 100).toInt()}%',
            style: AppTypography.titleMedium.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final String? target;
  final Color color;
  final double? progress;
  final bool showRemaining;
  final bool isOver;

  const _MacroItem({
    required this.label,
    required this.value,
    this.target,
    required this.color,
    required this.progress,
    this.showRemaining = false,
    this.isOver = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Cuando hay exceso, usar color de error
    final displayColor = isOver ? AppColors.error : color;
    final labelText = isOver
        ? '$label exceso'
        : (showRemaining ? '$label rest.' : label);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              labelText,
              style: AppTypography.labelSmall.copyWith(
                color: isOver ? AppColors.error : colors.onSurfaceVariant,
                fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${value}g',
          style: AppTypography.dataSmall.copyWith(
            color: isOver ? AppColors.error : colors.onSurface,
            fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (target != null && !showRemaining && !isOver)
          Text(
            '/${target}g',
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        if (target != null && showRemaining && !isOver)
          Text(
            'de ${target}g',
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        if (target != null && isOver)
          Text(
            'obj: ${target}g',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.error.withValues(alpha: 0.7),
            ),
          ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (progress ?? 0).clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? color.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Toggle de modo de vista con indicadores visuales claros
class _ViewModeToggle extends StatelessWidget {
  final DiaryViewMode viewMode;
  final ValueChanged<DiaryViewMode> onModeChanged;

  const _ViewModeToggle({required this.viewMode, required this.onModeChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: Icons.view_list,
            label: 'Lista',
            isSelected: viewMode == DiaryViewMode.list,
            onTap: () => onModeChanged(DiaryViewMode.list),
          ),
          _ToggleButton(
            icon: Icons.calendar_month,
            label: 'Calendario',
            isSelected: viewMode == DiaryViewMode.calendar,
            onTap: () => onModeChanged(DiaryViewMode.calendar),
          ),
        ],
      ),
    );
  }
}

/// Botón individual del toggle
class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Vista $label${isSelected ? " (activa)" : ""}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// QUICK ACTIONS CARD (Repetir ayer + Recientes)
// ============================================================================

/// Card con acciones rápidas: Repetir ayer + chips de alimentos recientes.
///
/// Progressive disclosure: "Repetir ayer" is always visible (primary action).
/// Templates and recent foods are collapsed under an expandable section
/// to reduce initial visual density.
class _QuickActionsCard extends ConsumerStatefulWidget {
  const _QuickActionsCard();

  @override
  ConsumerState<_QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends ConsumerState<_QuickActionsCard> {
  bool _showExtras = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final yesterdayAsync = ref.watch(yesterdayMealsProvider);
    final recentsAsync = ref.watch(quickRecentFoodsProvider);
    final templatesAsync = ref.watch(topMealTemplatesProvider);

    // Check if there's anything to show in the expandable section
    final hasTemplates = templatesAsync.valueOrNull?.isNotEmpty ?? false;
    final hasRecents = recentsAsync.valueOrNull?.isNotEmpty ?? false;
    final hasExtras = hasTemplates || hasRecents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary action: Repetir ayer — always visible
        yesterdayAsync.when(
          data: (yesterday) {
            if (yesterday.isEmpty) return const SizedBox.shrink();

            final yesterdayDate = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day - 1,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RepeatYesterdayButton(
                entryCount: yesterday.entryCount,
                totalKcal: yesterday.totalKcal,
                sourceDate: yesterdayDate,
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),

        // Expand/collapse toggle for secondary actions
        if (hasExtras)
          GestureDetector(
            onTap: () => setState(() => _showExtras = !_showExtras),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    _showExtras ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showExtras
                        ? 'Ocultar atajos'
                        : 'Plantillas y recientes',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Expandable section: templates + recents
        if (_showExtras) ...[
          // Templates
          templatesAsync.when(
            data: (templates) {
              if (templates.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark_outline,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Plantillas guardadas',
                          style: AppTypography.labelSmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: templates.take(4).map((template) {
                      return _TemplateChip(template: template);
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Recents
          recentsAsync.when(
            data: (recents) {
              if (recents.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Añadir rápido (toca para elegir comida)',
                          style: AppTypography.labelSmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: recents.take(6).map((food) {
                      return _RecentFoodChip(food: food);
                    }).toList(),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

/// Botón para repetir todas las comidas del día anterior
class _RepeatYesterdayButton extends ConsumerWidget {
  final int entryCount;
  final int totalKcal;
  final DateTime sourceDate;

  const _RepeatYesterdayButton({
    required this.entryCount,
    required this.totalKcal,
    required this.sourceDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    // Formato corto para la fecha: "Lun 27"
    final dayLabel = DateFormat('E d', 'es').format(sourceDate);

    return Material(
      color: colors.secondaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => _repeatYesterday(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.content_copy_rounded,
                size: 18,
                color: colors.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Copiar del $dayLabel',
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$entryCount alimentos · $totalKcal kcal',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSecondaryContainer.withAlpha(
                        (0.7 * 255).round(),
                      ),
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

  Future<void> _repeatYesterday(BuildContext context, WidgetRef ref) async {
    final selectedDate = ref.read(selectedDateProvider);
    final targetDateLabel = DateFormat('EEEE d', 'es').format(selectedDate);

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Copiar comidas',
      message: '¿Añadir $entryCount alimentos ($totalKcal kcal) al $targetDateLabel?',
      confirmLabel: 'Añadir',
    );

    if (confirmed && context.mounted) {
      final repeatFn = ref.read(repeatYesterdayProvider);
      final count = await repeatFn();

      if (context.mounted) {
        if (count == 0) {
          AppSnackbar.show(context, message: 'Ya tienes esas comidas añadidas');
        } else if (count < entryCount) {
          AppSnackbar.show(
            context,
            message:
                '$count alimentos añadidos (${entryCount - count} ya existían)',
          );
        } else {
          AppSnackbar.show(context, message: '$count alimentos añadidos');
        }
      }
    }
  }
}

/// Chip para un alimento reciente - permite añadir rápido eligiendo la comida
class _RecentFoodChip extends ConsumerWidget {
  final QuickRecentFood food;

  const _RecentFoodChip({required this.food});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: '${food.kcal} kcal · Toca para añadir',
      child: ActionChip(
        avatar: Icon(Icons.add_circle_outline, size: 14, color: colors.primary),
        label: Text(
          food.name.length > 15
              ? '${food.name.substring(0, 15)}...'
              : food.name,
          style: AppTypography.labelSmall,
        ),
        onPressed: () => _showMealSelector(context, ref),
        backgroundColor: colors.surfaceContainerHighest,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showMealSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿A qué comida añadir?',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${food.name} · ${food.kcal} kcal',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...MealType.values.map(
                (mealType) => ListTile(
                  leading: Icon(_getMealIcon(mealType)),
                  title: Text(mealType.displayName),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _addToMeal(context, ref, mealType);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMealIcon(MealType mealType) {
    return switch (mealType) {
      MealType.breakfast => Icons.wb_sunny,
      MealType.lunch => Icons.restaurant,
      MealType.dinner => Icons.nights_stay,
      MealType.snack => Icons.cookie,
    };
  }

  Future<void> _addToMeal(
    BuildContext context,
    WidgetRef ref,
    MealType mealType,
  ) async {
    final diaryRepo = ref.read(diaryRepositoryProvider);
    final selectedDate = ref.read(selectedDateProvider);

    // Crear entrada del diario con el alimento reciente usando su última cantidad
    final entry = DiaryEntryModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_quick',
      date: selectedDate,
      mealType: mealType,
      foodId: food.id,
      foodName: food.name,
      foodBrand: food.brand,
      amount: food.lastAmount,
      unit: food.lastUnit,
      kcal: food.kcal,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      createdAt: DateTime.now(),
    );

    await diaryRepo.insert(entry);

    if (context.mounted) {
      AppSnackbar.show(
        context,
        message: '${food.name} añadido a ${mealType.displayName}',
      );
    }
  }
}

/// Chip para una plantilla de comida - permite añadir rápido eligiendo la comida destino
class _TemplateChip extends ConsumerWidget {
  final MealTemplateModel template;

  const _TemplateChip({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: '${template.itemCount} items · ${template.totalKcal} kcal',
      child: ActionChip(
        avatar: Icon(Icons.bookmark, size: 14, color: colors.tertiary),
        label: Text(
          template.name.length > 15
              ? '${template.name.substring(0, 15)}...'
              : template.name,
          style: AppTypography.labelSmall,
        ),
        onPressed: () => _showMealSelector(context, ref),
        backgroundColor: colors.tertiaryContainer.withAlpha(
          (0.5 * 255).round(),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showMealSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿A qué comida añadir la plantilla?',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${template.name} · ${template.itemCount} items · ${template.totalKcal} kcal',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...MealType.values.map(
                (mealType) => ListTile(
                  leading: Icon(_getMealIcon(mealType)),
                  title: Text(mealType.displayName),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _applyTemplate(context, ref, mealType);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMealIcon(MealType mealType) {
    return switch (mealType) {
      MealType.breakfast => Icons.wb_sunny,
      MealType.lunch => Icons.restaurant,
      MealType.dinner => Icons.nights_stay,
      MealType.snack => Icons.cookie,
    };
  }

  Future<void> _applyTemplate(
    BuildContext context,
    WidgetRef ref,
    MealType mealType,
  ) async {
    final selectedDate = ref.read(selectedDateProvider);

    // Convertir MealType de diary a db
    final dbMealType = switch (mealType) {
      MealType.breakfast => db.MealType.breakfast,
      MealType.lunch => db.MealType.lunch,
      MealType.dinner => db.MealType.dinner,
      MealType.snack => db.MealType.snack,
    };

    final success = await ref
        .read(useMealTemplateProvider.notifier)
        .apply(
          templateId: template.id,
          date: selectedDate,
          mealType: dbMealType,
        );

    if (context.mounted) {
      if (success) {
        AppSnackbar.show(
          context,
          message:
              '${template.itemCount} items añadidos a ${mealType.displayName}',
        );
      } else {
        AppSnackbar.showError(context, message: 'Error al aplicar plantilla');
      }
    }
  }
}
