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
import 'package:juan_tracker/diet/providers/adherence_providers.dart';
import 'package:juan_tracker/diet/providers/meal_template_providers.dart';
import 'package:juan_tracker/diet/providers/quick_actions_provider.dart';
import 'package:juan_tracker/diet/services/day_summary_calculator.dart';
import 'package:juan_tracker/features/diary/presentation/edit_entry_dialog.dart';
import 'package:juan_tracker/features/diary/presentation/quick_add_sheet.dart';
import 'package:juan_tracker/diet/providers/coach_nudge_providers.dart';
import 'package:juan_tracker/diet/providers/coach_providers.dart';
import 'package:juan_tracker/features/home/providers/home_providers.dart';
import 'package:juan_tracker/training/database/database.dart' as db;

enum DiaryViewMode { list, calendar, timeline }

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

/// Notifier para controlar qué secciones de comida están expandidas
class ExpandedMealsNotifier extends Notifier<Set<MealType>> {
  bool _userToggled = false;

  @override
  Set<MealType> build() => <MealType>{};

  void toggle(MealType mealType) {
    _userToggled = true;
    final current = Set<MealType>.from(state);
    if (current.contains(mealType)) {
      current.remove(mealType);
    } else {
      current.add(mealType);
    }
    state = current;
  }

  void autoSetFromEntries(List<DiaryEntryModel> entries) {
    if (_userToggled) return;
    final withEntries = <MealType>{};
    for (final entry in entries) {
      withEntries.add(entry.mealType);
    }
    if (withEntries.length != state.length ||
        !withEntries.containsAll(state)) {
      state = withEntries;
    }
  }

  void resetAuto() {
    _userToggled = false;
    state = <MealType>{};
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

    // Auto-apply check-in: escuchar resultado y mostrar snackbar
    ref.listen<AsyncValue<AutoApplyResult?>>(
      autoApplyCheckInProvider,
      (prev, next) {
        next.whenData((result) {
          if (result != null && context.mounted) {
            AppSnackbar.show(
              context,
              message: '🤖 Coach actualizó targets: '
                  '${result.previousKcal} → ${result.newKcal} kcal',
            );
          }
        });
      },
    );

    // Reset auto-expansión al cambiar de fecha
    ref.listen<DateTime>(selectedDateProvider, (prev, next) {
      if (prev == null) return;
      if (prev.year != next.year ||
          prev.month != next.month ||
          prev.day != next.day) {
        ref.read(expandedMealsProvider.notifier).resetAuto();
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        heroTag: 'quick_add_fab',
        onPressed: () => QuickAddSheet.show(context),
        tooltip: 'Entrada rápida',
        child: const Icon(Icons.bolt),
      ),
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

          // Coach Smart Nudges
          const SliverToBoxAdapter(
            child: _CoachNudgesSection(),
          ),

          // Acciones rápidas
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
              ref
                  .read(expandedMealsProvider.notifier)
                  .autoSetFromEntries(entries);
              // Vista timeline: orden cronológico
              if (viewMode == DiaryViewMode.timeline) {
                final sorted = List<DiaryEntryModel>.from(entries)
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                if (sorted.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: AppEmpty(
                        icon: Icons.schedule,
                        title: 'Sin registros hoy',
                        subtitle: 'Añade tu primera comida del día',
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final entry = sorted[index];
                        return _TimelineEntryTile(
                          entry: entry,
                          isFirst: index == 0,
                          isLast: index == sorted.length - 1,
                        );
                      },
                      childCount: sorted.length,
                    ),
                  ),
                );
              }

              // Vista clásica: agrupar por tipo de comida
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
    final countLabel =
        entries.length == 1 ? '1 alimento' : '${entries.length} alimentos';

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
                      ).withAlpha((0.2 * 255).round()),
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
                            '${totals.kcal} kcal · $countLabel',
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
                  if (!isExpanded)
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip:
                          'Añadir a ${mealType.displayName.toLowerCase()}',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showAddEntry(context, ref, mealType),
                      color: colors.primary,
                    ),
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

            if (entries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: _MealMacrosRow(totals: totals),
              ),

            if (entries.isEmpty)
              ListTile(
                leading: Icon(
                  Icons.add_circle_outline,
                  color: colors.onSurfaceVariant.withAlpha((0.5 * 255).round()),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: Text('¿Eliminar "${entry.foodName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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

class _MealMacrosRow extends StatelessWidget {
  final _MealTotals totals;

  const _MealMacrosRow({required this.totals});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MacroPill(
          label: 'P',
          value: '${totals.protein.toStringAsFixed(0)}g',
          color: AppColors.error,
        ),
        const SizedBox(width: AppSpacing.xs),
        _MacroPill(
          label: 'C',
          value: '${totals.carbs.toStringAsFixed(0)}g',
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.xs),
        _MacroPill(
          label: 'G',
          value: '${totals.fat.toStringAsFixed(0)}g',
          color: AppColors.info,
        ),
      ],
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$label $value',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tile de entrada individual
class _EntryTile extends StatefulWidget {
  final DiaryEntryModel entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EntryTile({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final entry = widget.entry;

    final detailChips = <Widget>[
      _MacroPill(
        label: 'Cantidad',
        value: '${entry.amount.toStringAsFixed(0)} ${entry.unit.name}',
        color: colors.primary,
      ),
    ];

    if (entry.protein != null && entry.protein! > 0) {
      detailChips.add(
        _MacroPill(
          label: 'P',
          value: '${entry.protein!.toStringAsFixed(0)}g',
          color: AppColors.error,
        ),
      );
    }
    if (entry.carbs != null && entry.carbs! > 0) {
      detailChips.add(
        _MacroPill(
          label: 'C',
          value: '${entry.carbs!.toStringAsFixed(0)}g',
          color: AppColors.warning,
        ),
      );
    }
    if (entry.fat != null && entry.fat! > 0) {
      detailChips.add(
        _MacroPill(
          label: 'G',
          value: '${entry.fat!.toStringAsFixed(0)}g',
          color: AppColors.info,
        ),
      );
    }

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: Icon(Icons.delete, color: colors.onError),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: Column(
        children: [
          ListTile(
            title: Text(
              entry.foodName,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: !_expanded
                ? Text(
                    '${entry.kcal} kcal',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.kcal}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.onSurfaceVariant,
                  ),
                  tooltip: _expanded ? 'Ocultar detalles' : 'Ver detalles',
                  onPressed: () {
                    setState(() => _expanded = !_expanded);
                  },
                ),
              ],
            ),
            onTap: widget.onTap,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: detailChips,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDurations.fast,
          ),
        ],
      ),
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
    final adherenceAsync = ref.watch(monthAdherenceProvider(selectedDate));

    final entryDays = entryDaysAsync.when(
      data: (days) => days,
      loading: () => <DateTime>{},
      error: (_, _) => <DateTime>{},
    );

    final adherenceData = adherenceAsync.when(
      data: (data) => data,
      loading: () => MonthAdherenceData.empty,
      error: (_, _) => MonthAdherenceData.empty,
    );

    final hasAdherence = adherenceData.targetKcal != null;

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
              onPageChanged: (focusedDay) {
                // Trigger re-fetch de adherencia para el nuevo mes
                ref.read(monthAdherenceProvider(focusedDay));
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
                // Marcar invisible para usar calendarBuilders
                markerDecoration: hasAdherence
                    ? const BoxDecoration()
                    : BoxDecoration(
                        color: colorScheme.tertiary,
                        shape: BoxShape.circle,
                      ),
              ),
              calendarBuilders: hasAdherence
                  ? CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return null;
                        final normalizedDay = DateTime(
                          day.year,
                          day.month,
                          day.day,
                        );
                        final status = adherenceData.dayStatus[normalizedDay];
                        final dotColor = status != null
                            ? MonthAdherenceData.colorForStatus(
                                status, colorScheme)
                            : colorScheme.tertiary;

                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    )
                  : const CalendarBuilders(),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                weekendStyle: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Leyenda de colores
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: hasAdherence
                  ? _AdherenceLegend()
                  : Row(
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

/// Leyenda de colores de adherencia para el calendario.
class _AdherenceLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: Colors.green, label: '±10%'),
        const SizedBox(width: 12),
        _LegendDot(color: Colors.amber.shade600, label: '±25%'),
        const SizedBox(width: 12),
        _LegendDot(color: Colors.red.shade400, label: '>25%'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DailySummaryCard extends ConsumerStatefulWidget {
  final DaySummary summary;

  const _DailySummaryCard({required this.summary});

  @override
  ConsumerState<_DailySummaryCard> createState() => _DailySummaryCardState();
}

class _DailySummaryCardState extends ConsumerState<_DailySummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
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
                  ],
                ),
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

          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(_expanded ? 'Ocultar detalles' : 'Ver macros y micros'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: colors.primary,
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.lg),
                if (hasTargets) ...[
                  Row(
                    children: [
                      _MacroDonut(
                        progress: summary.progress.kcalPercent ?? 0,
                        remaining: summary.progress.kcalRemaining,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Consumido: ${summary.consumed.kcal} / ${summary.targets!.kcalTarget} kcal',
                          style: AppTypography.labelSmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
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
                if (_hasMicronutrientData(summary))
                  _MicronutrientSection(summary: summary),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDurations.fast,
          ),
        ],
      ),
    );
  }

  bool _hasMicronutrientData(DaySummary summary) {
    final c = summary.consumed;
    final t = summary.targets;
    return (c.fiber > 0 || c.sugar > 0 || c.saturatedFat > 0 || c.sodium > 0) ||
        (t?.fiberTarget != null ||
            t?.sugarLimit != null ||
            t?.saturatedFatLimit != null ||
            t?.sodiumLimit != null);
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

/// Sección expandible de micronutrientes (fibra, azúcar, grasa sat., sodio)
class _MicronutrientSection extends StatefulWidget {
  final DaySummary summary;

  const _MicronutrientSection({required this.summary});

  @override
  State<_MicronutrientSection> createState() => _MicronutrientSectionState();
}

class _MicronutrientSectionState extends State<_MicronutrientSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final consumed = widget.summary.consumed;
    final targets = widget.summary.targets;
    final progress = widget.summary.progress;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),

        // Botón para expandir/colapsar
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Micronutrientes',
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Contenido expandible
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              children: [
                _MicroRow(
                  icon: Icons.grass,
                  label: 'Fibra',
                  consumed: consumed.fiber,
                  target: targets?.fiberTarget,
                  unit: 'g',
                  percent: progress.fiberPercent,
                  color: const Color(0xFF4CAF50), // Verde
                  isLimit: false,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MicroRow(
                  icon: Icons.cookie_outlined,
                  label: 'Azúcar',
                  consumed: consumed.sugar,
                  target: targets?.sugarLimit,
                  unit: 'g',
                  percent: progress.sugarPercent,
                  color: const Color(0xFFFF9800), // Naranja
                  isLimit: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MicroRow(
                  icon: Icons.water_drop_outlined,
                  label: 'Grasa sat.',
                  consumed: consumed.saturatedFat,
                  target: targets?.saturatedFatLimit,
                  unit: 'g',
                  percent: progress.saturatedFatPercent,
                  color: const Color(0xFFF44336), // Rojo
                  isLimit: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MicroRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Sodio',
                  consumed: consumed.sodium,
                  target: targets?.sodiumLimit,
                  unit: 'mg',
                  percent: progress.sodiumPercent,
                  color: const Color(0xFF9C27B0), // Púrpura
                  isLimit: true,
                ),
              ],
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

/// Fila individual de micronutriente con barra de progreso
class _MicroRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double consumed;
  final double? target;
  final String unit;
  final double? percent;
  final Color color;
  final bool isLimit; // true = límite (rojo al exceder), false = objetivo (verde al alcanzar)

  const _MicroRow({
    required this.icon,
    required this.label,
    required this.consumed,
    this.target,
    required this.unit,
    this.percent,
    required this.color,
    this.isLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pct = percent ?? 0;
    final isOver = isLimit && pct > 1.0;
    final barColor = isOver ? AppColors.error : color;

    return Row(
      children: [
        Icon(icon, size: 16, color: barColor),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isOver ? AppColors.error : colors.onSurfaceVariant,
              fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: barColor.withAlpha((0.15 * 255).round()),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 72,
          child: Text(
            target != null
                ? '${consumed.toStringAsFixed(0)}/${target!.toStringAsFixed(0)}$unit'
                : '${consumed.toStringAsFixed(0)}$unit',
            style: AppTypography.labelSmall.copyWith(
              color: isOver ? AppColors.error : colors.onSurfaceVariant,
              fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
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
              color: AppColors.error.withAlpha((0.7 * 255).round()),
            ),
          ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (progress ?? 0).clamp(0.0, 1.0),
            minHeight: 4,
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
            icon: Icons.schedule,
            label: 'Cronología',
            isSelected: viewMode == DiaryViewMode.timeline,
            onTap: () => onModeChanged(DiaryViewMode.timeline),
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
// QUICK ACTIONS CARD (Acciones rápidas)
// ============================================================================

/// Card compacta que abre un sheet con acciones rápidas.
class _QuickActionsCard extends ConsumerWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final yesterday = ref.watch(yesterdayMealsProvider).asData?.value;
    final templates =
        ref.watch(topMealTemplatesProvider).asData?.value ?? [];
    final recents =
        ref.watch(quickRecentFoodsProvider).asData?.value ?? [];

    final subtitleParts = <String>[];
    if (yesterday != null && yesterday.entryCount > 0) {
      subtitleParts.add('Ayer: ${yesterday.entryCount}');
    }
    if (templates.isNotEmpty) {
      subtitleParts.add('${templates.length} plantillas');
    }
    if (recents.isNotEmpty) {
      subtitleParts.add('${recents.length} recientes');
    }
    final subtitle =
        subtitleParts.isEmpty ? 'Plantillas y recientes' : subtitleParts.join(' · ');

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showQuickActionsSheet(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withAlpha((0.6 * 255).round()),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.bolt,
                  size: 18,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acciones rápidas',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => const _QuickActionsSheet(),
    );
  }
}

class _QuickActionsSheet extends ConsumerWidget {
  const _QuickActionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final selectedDate = ref.watch(selectedDateProvider);
    final yesterdayAsync = ref.watch(yesterdayMealsProvider);
    final recentsAsync = ref.watch(quickRecentFoodsProvider);
    final templatesAsync = ref.watch(topMealTemplatesProvider);

    final yesterday = yesterdayAsync.asData?.value;
    final templates = templatesAsync.asData?.value ?? [];
    final recents = recentsAsync.asData?.value ?? [];
    final hasAny = (yesterday != null && !yesterday.isEmpty) ||
        templates.isNotEmpty ||
        recents.isNotEmpty;

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg + bottomPadding,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Acciones rápidas',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Plantillas, recientes y repetir comidas',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!hasAny)
                const AppEmpty(
                  icon: Icons.bolt,
                  title: 'Sin atajos aún',
                  subtitle: 'Aparecerán cuando tengas historial de comidas.',
                ),

              if (hasAny) ...[
                if (yesterday != null && !yesterday.isEmpty) ...[
                  const _QuickActionsSectionHeader(
                    icon: Icons.history_rounded,
                    title: 'Repetir ayer',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _RepeatYesterdayButton(
                    entryCount: yesterday.entryCount,
                    totalKcal: yesterday.totalKcal,
                    sourceDate: DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day - 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (templates.isNotEmpty) ...[
                  const _QuickActionsSectionHeader(
                    icon: Icons.bookmark_outline,
                    title: 'Plantillas guardadas',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: templates.take(4).map((template) {
                      return _TemplateChip(template: template);
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (recents.isNotEmpty) ...[
                  const _QuickActionsSectionHeader(
                    icon: Icons.history,
                    title: 'Añadir rápido',
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _QuickActionsSectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
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
      color: colors.secondaryContainer.withAlpha((0.5 * 255).round()),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Copiar comidas'),
        content: Text(
          '¿Añadir $entryCount alimentos ($totalKcal kcal) al $targetDateLabel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
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
      fiber: food.fiber,
      sugar: food.sugar,
      saturatedFat: food.saturatedFat,
      sodium: food.sodium,
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

// ============================================================================
// COACH SMART NUDGES
// ============================================================================

/// Sección que muestra nudges inteligentes del coach.
/// Se oculta automáticamente si no hay nudges activos.
class _CoachNudgesSection extends ConsumerWidget {
  const _CoachNudgesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nudges = ref.watch(coachNudgesProvider);

    if (nudges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          ...nudges.map((nudge) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _CoachNudgeTile(nudge: nudge),
              )),
        ],
      ),
    );
  }
}

/// Tile individual de un nudge del coach.
/// Color de fondo sutil según el tipo de nudge.
class _CoachNudgeTile extends StatelessWidget {
  final CoachNudge nudge;

  const _CoachNudgeTile({required this.nudge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bgColor, fgColor) = _nudgeColors(cs);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Text(nudge.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              nudge.message,
              style: AppTypography.bodySmall.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _nudgeColors(ColorScheme cs) {
    return switch (nudge.type) {
      NudgeType.warning => (
          cs.errorContainer.withAlpha((0.6 * 255).round()),
          cs.onErrorContainer,
        ),
      NudgeType.info => (
          cs.primaryContainer.withAlpha((0.5 * 255).round()),
          cs.onPrimaryContainer,
        ),
      NudgeType.positive => (
          cs.tertiaryContainer.withAlpha((0.6 * 255).round()),
          cs.onTertiaryContainer,
        ),
      NudgeType.reminder => (
          cs.secondaryContainer.withAlpha((0.5 * 255).round()),
          cs.onSecondaryContainer,
        ),
    };
  }
}

// ============================================================================
// VISTA TIMELINE (cronológica)
// ============================================================================

/// Tile de una entrada en la vista timeline
class _TimelineEntryTile extends ConsumerWidget {
  final DiaryEntryModel entry;
  final bool isFirst;
  final bool isLast;

  const _TimelineEntryTile({
    required this.entry,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final timeStr = DateFormat('HH:mm').format(entry.createdAt);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline vertical con hora
          SizedBox(
            width: 56,
            child: Column(
              children: [
                // Hora
                Text(
                  timeStr,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                // Línea vertical
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: isLast
                          ? Colors.transparent
                          : colors.outline.withAlpha((0.3 * 255).round()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                onTap: () => _onTap(context, ref),
                child: Row(
                  children: [
                    // Icono de comida
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _mealColor.withAlpha((0.15 * 255).round()),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(_mealIcon, size: 16, color: _mealColor),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Info del alimento
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.foodName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                '${entry.amount.round()}${entry.unit == ServingUnit.grams ? 'g' : entry.unit == ServingUnit.milliliter ? 'ml' : ' porc'}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.mealType.displayName,
                                style: AppTypography.labelSmall.copyWith(
                                  color: _mealColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Calorías
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.kcal}',
                          style: AppTypography.dataSmall.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: AppTypography.labelSmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _mealColor => switch (entry.mealType) {
        MealType.breakfast => const Color(0xFFFF9800),
        MealType.lunch => const Color(0xFF4CAF50),
        MealType.dinner => const Color(0xFF2196F3),
        MealType.snack => const Color(0xFF9C27B0),
      };

  IconData get _mealIcon => switch (entry.mealType) {
        MealType.breakfast => Icons.free_breakfast,
        MealType.lunch => Icons.lunch_dining,
        MealType.dinner => Icons.dinner_dining,
        MealType.snack => Icons.cookie,
      };

  void _onTap(BuildContext context, WidgetRef ref) {
    // Mismo comportamiento que en la vista por comidas
    ref.read(selectedMealTypeProvider.notifier).meal = entry.mealType;
  }
}
