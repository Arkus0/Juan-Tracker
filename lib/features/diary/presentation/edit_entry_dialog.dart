import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../diet/models/models.dart';

/// Diálogo para editar una entrada existente del diario
class EditEntryDialog extends ConsumerStatefulWidget {
  final DiaryEntryModel entry;

  const EditEntryDialog({super.key, required this.entry});

  @override
  ConsumerState<EditEntryDialog> createState() => _EditEntryDialogState();
}

class _EditEntryDialogState extends ConsumerState<EditEntryDialog> {
  late final TextEditingController _amountController;
  late MealType _mealType;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.entry.amount.toString());
    _mealType = widget.entry.mealType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final calculated = _calculateMacros();

    return AlertDialog(
      title: Text('Editar: ${entry.foodName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de tipo de comida
            _MealTypeSelector(
              selected: _mealType,
              onChanged: (v) => setState(() => _mealType = v),
            ),
            const SizedBox(height: 16),

            // Cantidad
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad (${entry.unit.name})',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Preview de macros calculados
            _MacroPreview(calculated: calculated),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saveEntry,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  ({int kcal, double protein, double carbs, double fat}) _calculateMacros() {
    final entry = widget.entry;
    final newAmount = double.tryParse(_amountController.text) ?? entry.amount;

    // Protección contra división por cero
    if (entry.amount <= 0 || newAmount <= 0) {
      return (kcal: 0, protein: 0.0, carbs: 0.0, fat: 0.0);
    }

    // Calcular factor de cambio
    final factor = newAmount / entry.amount;

    return (
      kcal: (entry.kcal * factor).round(),
      protein: (entry.protein ?? 0) * factor,
      carbs: (entry.carbs ?? 0) * factor,
      fat: (entry.fat ?? 0) * factor,
    );
  }

  void _saveEntry() {
    final newAmount = double.tryParse(_amountController.text) ?? widget.entry.amount;
    if (newAmount <= 0) return;

    final entry = widget.entry;

    // Protección contra división por cero
    if (entry.amount <= 0) return;

    final factor = newAmount / entry.amount;

    final updatedEntry = entry.copyWith(
      mealType: _mealType,
      amount: newAmount,
      kcal: (entry.kcal * factor).round(),
      protein: (entry.protein ?? 0) * factor,
      carbs: (entry.carbs ?? 0) * factor,
      fat: (entry.fat ?? 0) * factor,
    );

    Navigator.of(context).pop(updatedEntry);
  }
}

/// Selector de tipo de comida
class _MealTypeSelector extends StatelessWidget {
  final MealType selected;
  final Function(MealType) onChanged;

  const _MealTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MealType>(
      segments: const [
        ButtonSegment(
          value: MealType.breakfast,
          label: Text('Desayuno'),
          icon: Icon(Icons.wb_sunny),
        ),
        ButtonSegment(
          value: MealType.lunch,
          label: Text('Almuerzo'),
          icon: Icon(Icons.restaurant),
        ),
        ButtonSegment(
          value: MealType.dinner,
          label: Text('Cena'),
          icon: Icon(Icons.nights_stay),
        ),
        ButtonSegment(
          value: MealType.snack,
          label: Text('Snack'),
          icon: Icon(Icons.cookie),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

/// Preview de macros calculados
class _MacroPreview extends StatelessWidget {
  final ({int kcal, double protein, double carbs, double fat}) calculated;

  const _MacroPreview({required this.calculated});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${calculated.kcal} kcal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MacroItem(label: 'Proteína', value: '${calculated.protein.toStringAsFixed(1)}g'),
              _MacroItem(label: 'Carbs', value: '${calculated.carbs.toStringAsFixed(1)}g'),
              _MacroItem(label: 'Grasa', value: '${calculated.fat.toStringAsFixed(1)}g'),
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

  const _MacroItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
