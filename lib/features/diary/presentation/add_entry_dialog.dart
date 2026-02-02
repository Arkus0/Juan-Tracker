import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';

/// Diálogo para añadir una entrada desde un alimento existente
class AddEntryDialog extends ConsumerStatefulWidget {
  final FoodModel food;
  /// Cantidad inicial en gramos (para pre-rellenar desde voz/OCR)
  final double? initialAmount;
  /// Unidad inicial
  final ServingUnit? initialUnit;

  const AddEntryDialog({
    super.key, 
    required this.food,
    this.initialAmount,
    this.initialUnit,
  });

  @override
  ConsumerState<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends ConsumerState<AddEntryDialog> {
  late final TextEditingController _amountController;
  ServingUnit _selectedUnit = ServingUnit.grams;

  @override
  void initState() {
    super.initState();
    // Usar cantidad inicial si se proporciona
    final initialValue = widget.initialAmount?.toStringAsFixed(0) ?? '100';
    _amountController = TextEditingController(text: initialValue);
    _selectedUnit = widget.initialUnit ?? ServingUnit.grams;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final calculated = _calculateMacros();

    return AlertDialog(
      title: Text(food.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cantidad y unidad
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campo de cantidad
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                // Selector de unidad
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<ServingUnit>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unidad',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: ServingUnit.grams,
                        child: Text('Gramos'),
                      ),
                      if (food.portionName != null)
                        DropdownMenuItem(
                          value: ServingUnit.portion,
                          child: Text(food.portionName!),
                        ),
                      const DropdownMenuItem(
                        value: ServingUnit.milliliter,
                        child: Text('Mililitros'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info de porción si existe
            if (food.portionGrams != null && food.portionName != null)
              Text(
                '1 ${food.portionName} = ${food.portionGrams}g',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
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
          onPressed: () => _saveEntry(),
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Macros _calculateMacros() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final food = widget.food;

    // Calcular gramos totales
    double grams;
    if (_selectedUnit == ServingUnit.portion && food.portionGrams != null) {
      grams = amount * food.portionGrams!;
    } else {
      grams = amount; // gramos o ml (asumiendo densidad 1g/ml)
    }

    return food.macrosForGrams(grams);
  }

  void _saveEntry() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final date = ref.read(selectedDateProvider);
    final existingEntry = ref.read(editingEntryProvider);

    // Usar el mealType seleccionado en el provider
    final mealType = ref.read(selectedMealTypeProvider);
    
    final entry = DiaryEntryModel.fromFood(
      id: existingEntry?.id ?? const Uuid().v4(),
      date: date,
      mealType: mealType,
      food: widget.food,
      amount: amount,
      unit: _selectedUnit,
    );

    Navigator.of(context).pop(entry);
  }
}

/// Preview de macros calculados
class _MacroPreview extends StatelessWidget {
  final Macros calculated;

  const _MacroPreview({required this.calculated});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha((0.3 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${calculated.kcal}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              const Text('kcal'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MacroPill(
                label: 'Proteína',
                value: '${calculated.protein?.toStringAsFixed(1) ?? 0}g',
                color: Colors.red.shade400,
              ),
              _MacroPill(
                label: 'Carbs',
                value: '${calculated.carbs?.toStringAsFixed(1) ?? 0}g',
                color: Colors.amber.shade600,
              ),
              _MacroPill(
                label: 'Grasa',
                value: '${calculated.fat?.toStringAsFixed(1) ?? 0}g',
                color: Colors.blue.shade400,
              ),
            ],
          ),
        ],
      ),
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
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK ADD DIALOG
// ============================================================================

/// Diálogo para añadir entrada rápida sin crear alimento permanente
class QuickAddDialog extends ConsumerStatefulWidget {
  const QuickAddDialog({super.key});

  @override
  ConsumerState<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends ConsumerState<QuickAddDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _kcalController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir Rápido'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Comida de trabajo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Kcal (obligatorio)
            TextField(
              controller: _kcalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kcal *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Macros opcionales
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Proteína (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Grasa (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
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

  void _saveEntry() {
    final name = _nameController.text.trim();
    final kcal = int.tryParse(_kcalController.text) ?? 0;

    if (name.isEmpty || kcal <= 0) {
      // Mostrar error
      return;
    }

    final date = ref.read(selectedDateProvider);
    final existingEntry = ref.read(editingEntryProvider);
    final mealType = ref.read(selectedMealTypeProvider);

    final entry = DiaryEntryModel.quickAdd(
      id: existingEntry?.id ?? const Uuid().v4(),
      date: date,
      mealType: mealType,
      name: name,
      kcal: kcal,
      protein: double.tryParse(_proteinController.text),
      carbs: double.tryParse(_carbsController.text),
      fat: double.tryParse(_fatController.text),
    );

    Navigator.of(context).pop(entry);
  }
}
