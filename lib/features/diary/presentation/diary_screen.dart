import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';
import 'food_search_screen.dart';

/// Pantalla principal del Diario
/// Muestra el día actual con totales y entradas agrupadas por tipo de comida
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final entriesAsync = ref.watch(dayEntriesStreamProvider);
    final totalsAsync = ref.watch(dailyTotalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diario'),
        centerTitle: true,
        actions: [
          // Botón "Hoy"
          TextButton(
            onPressed: () => ref.read(selectedDateProvider.notifier).goToToday(),
            child: const Text('HOY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector de fecha
          _DateSelector(
            selectedDate: selectedDate,
            onPrevious: () => ref.read(selectedDateProvider.notifier).previousDay(),
            onNext: () => ref.read(selectedDateProvider.notifier).nextDay(),
          ),

          // Totales del día
          totalsAsync.when(
            data: (totals) => _DailyTotalsCard(totals: totals),
            loading: () => const _DailyTotalsCard(totals: DailyTotals.empty),
            error: (_, __) => const _DailyTotalsCard(totals: DailyTotals.empty),
          ),

          const Divider(height: 1),

          // Lista de comidas
          Expanded(
            child: entriesAsync.when(
              data: (entries) => _MealsList(entries: entries),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de fecha con navegación
class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DateSelector({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(selectedDate, DateTime.now());
    final dateText = isToday
        ? 'Hoy, ${DateFormat('d MMM', 'es').format(selectedDate)}'
        : DateFormat('EEEE d MMM', 'es').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Día anterior',
          ),
          Expanded(
            child: Text(
              dateText.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Día siguiente',
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Card con los totales del día
class _DailyTotalsCard extends StatelessWidget {
  final DailyTotals totals;

  const _DailyTotalsCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Kcal principal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${totals.kcal}',
                style: GoogleFonts.montserrat(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kcal',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MacroItem(
                label: 'Proteína',
                value: '${totals.protein.toStringAsFixed(0)}g',
                color: Colors.red.shade400,
              ),
              _MacroItem(
                label: 'Carbs',
                value: '${totals.carbs.toStringAsFixed(0)}g',
                color: Colors.amber.shade600,
              ),
              _MacroItem(
                label: 'Grasa',
                value: '${totals.fat.toStringAsFixed(0)}g',
                color: Colors.blue.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroItem({
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Lista de secciones de comidas
class _MealsList extends StatelessWidget {
  final List<DiaryEntryModel> entries;

  const _MealsList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _MealSection(
          mealType: MealType.breakfast,
          entries: entries.where((e) => e.mealType == MealType.breakfast).toList(),
        ),
        _MealSection(
          mealType: MealType.lunch,
          entries: entries.where((e) => e.mealType == MealType.lunch).toList(),
        ),
        _MealSection(
          mealType: MealType.dinner,
          entries: entries.where((e) => e.mealType == MealType.dinner).toList(),
        ),
        _MealSection(
          mealType: MealType.snack,
          entries: entries.where((e) => e.mealType == MealType.snack).toList(),
        ),
      ],
    );
  }
}

/// Sección de un tipo de comida (Desayuno, Almuerzo, etc.)
class _MealSection extends ConsumerWidget {
  final MealType mealType;
  final List<DiaryEntryModel> entries;

  const _MealSection({
    required this.mealType,
    required this.entries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totals = _calculateTotals();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la sección
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(_getMealIcon(), size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      mealType.displayName.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Totales de la comida
              if (entries.isNotEmpty)
                Text(
                  '${totals.kcal} kcal',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 8),
              // Botón añadir
              _AddButton(
                onPressed: () => _showAddEntry(context, ref),
              ),
            ],
          ),
        ),

        // Lista de entradas
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Sin entradas',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          )
        else
          ...entries.map((entry) => _EntryTile(entry: entry)),

        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
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
    return Macros(
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
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

  void _showAddEntry(BuildContext context, WidgetRef ref) {
    ref.read(selectedMealTypeProvider.notifier).state = mealType;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FoodSearchScreen(),
      ),
    );
  }
}

/// Botón pequeño de añadir
class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.add, size: 18),
        ),
      ),
    );
  }
}

/// Tile de una entrada individual
class _EntryTile extends ConsumerWidget {
  final DiaryEntryModel entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteEntry(ref),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.foodName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '${entry.kcal} kcal',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _getSubtitle(),
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => _editEntry(context, ref),
        ),
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
        unitText = 'porción';
        if (entry.amount > 1) unitText = 'porciones';
        break;
      case ServingUnit.milliliter:
        unitText = 'ml';
        break;
    }

    final parts = <String>['$amount $unitText'];
    
    if (entry.protein != null && entry.protein! > 0) {
      parts.add('P: ${entry.protein!.toStringAsFixed(1)}g');
    }
    if (entry.carbs != null && entry.carbs! > 0) {
      parts.add('C: ${entry.carbs!.toStringAsFixed(1)}g');
    }
    if (entry.fat != null && entry.fat! > 0) {
      parts.add('G: ${entry.fat!.toStringAsFixed(1)}g');
    }

    return parts.join(' • ');
  }

  Future<void> _editEntry(BuildContext context, WidgetRef ref) async {
    ref.read(editingEntryProvider.notifier).state = entry;
    ref.read(selectedMealTypeProvider.notifier).state = entry.mealType;
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FoodSearchScreen(isEditing: true),
      ),
    );
    
    ref.read(editingEntryProvider.notifier).state = null;
  }

  Future<void> _deleteEntry(WidgetRef ref) async {
    final repo = ref.read(diaryRepositoryProvider);
    await repo.delete(entry.id);
  }
}
