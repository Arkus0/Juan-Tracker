import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_snackbar.dart';import '../../core/providers/database_provider.dart';
import '../../diet/repositories/drift_diet_repositories.dart';import '../models/recipe_model.dart';
import '../models/food_model.dart';
import '../models/diary_entry_model.dart' show ServingUnit;
import '../providers/recipe_providers.dart';

/// Pantalla de creación/edición de recetas
///
/// Permite agregar ingredientes buscando alimentos, ajustar cantidades,
/// ver macros en tiempo real y guardar la receta.
class RecipeEditorScreen extends ConsumerStatefulWidget {
  final String? recipeId; // null = nueva

  const RecipeEditorScreen({super.key, this.recipeId});

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _servingsController;
  late final TextEditingController _servingNameController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(recipeEditorProvider);
    _nameController = TextEditingController(text: state.name);
    _descController = TextEditingController(text: state.description ?? '');
    _servingsController =
        TextEditingController(text: state.servings.toString());
    _servingNameController =
        TextEditingController(text: state.servingName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _servingsController.dispose();
    _servingNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(recipeEditorProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(editorState.isEditing ? 'Editar Receta' : 'Nueva Receta'),
        actions: [
          if (editorState.isValid)
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: 'Guardar como alimento',
              onPressed: editorState.isSaving ? null : _saveAsFood,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Guardar receta',
            onPressed: editorState.isSaving || !editorState.isValid
                ? null
                : _save,
          ),
        ],
      ),
      body: editorState.isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nombre y descripción
                  _RecipeInfoSection(
                    nameController: _nameController,
                    descController: _descController,
                    servingsController: _servingsController,
                    servingNameController: _servingNameController,
                    onNameChanged: (v) =>
                        ref.read(recipeEditorProvider.notifier).setName(v),
                    onDescChanged: (v) =>
                        ref.read(recipeEditorProvider.notifier).setDescription(v),
                    onServingsChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) {
                        ref.read(recipeEditorProvider.notifier).setServings(n);
                      }
                    },
                    onServingNameChanged: (v) =>
                        ref.read(recipeEditorProvider.notifier).setServingName(v),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Resumen nutricional en vivo
                  _NutritionSummaryCard(state: editorState),
                  const SizedBox(height: AppSpacing.md),

                  // Ingredientes
                  _IngredientsSection(
                    items: editorState.items,
                    onRemove: (index) => ref
                        .read(recipeEditorProvider.notifier)
                        .removeIngredient(index),
                    onUpdateAmount: (index, amount) => ref
                        .read(recipeEditorProvider.notifier)
                        .updateIngredientAmount(index, amount),
                    onAdd: _showAddIngredientSheet,
                  ),

                  // Error message
                  if (editorState.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        editorState.errorMessage!,
                        style: AppTypography.labelMedium.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 80), // espacio para FAB
                ],
              ),
            ),
    );
  }

  Future<void> _save() async {
    final result =
        await ref.read(recipeEditorProvider.notifier).save();
    if (result != null && mounted) {
      AppSnackbar.show(context, message: '"${result.name}" guardada');
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveAsFood() async {
    final food =
        await ref.read(recipeEditorProvider.notifier).saveAsFood();
    if (food != null && mounted) {
      AppSnackbar.show(
        context,
        message: '"${food.name}" guardada como alimento. Búscala en el diario.',
      );
      Navigator.of(context).pop();
    }
  }

  void _showAddIngredientSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AddIngredientSheet(
        onAdd: (food, amount, unit) {
          ref
              .read(recipeEditorProvider.notifier)
              .addIngredient(food, amount, unit);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ============================================================================
// SECCIÓN: Información de la receta
// ============================================================================

class _RecipeInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final TextEditingController servingsController;
  final TextEditingController servingNameController;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onDescChanged;
  final ValueChanged<String> onServingsChanged;
  final ValueChanged<String> onServingNameChanged;

  const _RecipeInfoSection({
    required this.nameController,
    required this.descController,
    required this.servingsController,
    required this.servingNameController,
    required this.onNameChanged,
    required this.onDescChanged,
    required this.onServingsChanged,
    required this.onServingNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Información', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la receta *',
                hintText: 'Ej: Ensalada César, Batido proteico...',
                border: OutlineInputBorder(),
              ),
              onChanged: onNameChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: onDescChanged,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Porciones',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: onServingsChanged,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: servingNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de porción',
                      hintText: 'porción, taza, plato...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: onServingNameChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SECCIÓN: Resumen nutricional en vivo
// ============================================================================

class _NutritionSummaryCard extends StatelessWidget {
  final RecipeEditorState state;

  const _NutritionSummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text('Nutrición por porción', style: AppTypography.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.items.isEmpty)
              Text(
                'Añade ingredientes para ver el resumen',
                style: AppTypography.labelMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            else ...[
              // Fila de macros principales
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NutrientPill(
                    label: 'kcal',
                    value: '${state.kcalPerServing}',
                    color: colors.primary,
                  ),
                  _NutrientPill(
                    label: 'Proteína',
                    value: '${state.proteinPerServing.toStringAsFixed(1)}g',
                    color: const Color(0xFF4CAF50),
                  ),
                  _NutrientPill(
                    label: 'Carbos',
                    value: '${state.carbsPerServing.toStringAsFixed(1)}g',
                    color: const Color(0xFFFF9800),
                  ),
                  _NutrientPill(
                    label: 'Grasa',
                    value: '${state.fatPerServing.toStringAsFixed(1)}g',
                    color: const Color(0xFFF44336),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Totales
              Text(
                'Total: ${state.totalKcal} kcal · ${state.totalGrams.toStringAsFixed(0)}g',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NutrientPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutrientPill({
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
          style: AppTypography.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SECCIÓN: Lista de ingredientes
// ============================================================================

class _IngredientsSection extends StatelessWidget {
  final List<RecipeItemModel> items;
  final void Function(int index) onRemove;
  final void Function(int index, double amount) onUpdateAmount;
  final VoidCallback onAdd;

  const _IngredientsSection({
    required this.items,
    required this.onRemove,
    required this.onUpdateAmount,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, size: 18, color: colors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text('Ingredientes', style: AppTypography.titleSmall),
                const Spacer(),
                Text(
                  '${items.length}',
                  style: AppTypography.labelMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Lista de ingredientes
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: Text(
                    'Sin ingredientes. Toca + para añadir.',
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _IngredientTile(
                  item: item,
                  onRemove: () => onRemove(index),
                  onTap: () => _showEditAmountDialog(
                    context,
                    item,
                    index,
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.sm),
            // Botón añadir
            Center(
              child: FilledButton.tonal(
                onPressed: onAdd,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 4),
                    Text('Añadir ingrediente'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAmountDialog(
    BuildContext context,
    RecipeItemModel item,
    int index,
  ) {
    final controller = TextEditingController(text: item.amount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.foodNameSnapshot, style: AppTypography.titleMedium),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Cantidad (${item.unit.name})',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                onUpdateAmount(index, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
    controller.dispose;
  }
}

class _IngredientTile extends StatelessWidget {
  final RecipeItemModel item;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _IngredientTile({
    required this.item,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodNameSnapshot,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.amount}${_unitSuffix(item.unit)} · ${item.calculatedKcal} kcal',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Macros compactos
            Text(
              'P${item.calculatedProtein?.toStringAsFixed(0) ?? '-'} '
              'C${item.calculatedCarbs?.toStringAsFixed(0) ?? '-'} '
              'G${item.calculatedFat?.toStringAsFixed(0) ?? '-'}',
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: colors.error),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  String _unitSuffix(ServingUnit unit) {
    return switch (unit) {
      ServingUnit.grams => 'g',
      ServingUnit.portion => ' porc.',
      ServingUnit.milliliter => 'ml',
    };
  }
}

// ============================================================================
// BOTTOM SHEET: Añadir ingrediente (búsqueda inline simplificada)
// ============================================================================

class _AddIngredientSheet extends ConsumerStatefulWidget {
  final void Function(FoodModel food, double amount, ServingUnit unit) onAdd;

  const _AddIngredientSheet({required this.onAdd});

  @override
  ConsumerState<_AddIngredientSheet> createState() =>
      _AddIngredientSheetState();
}

class _AddIngredientSheetState extends ConsumerState<_AddIngredientSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController =
      TextEditingController(text: '100');
  ServingUnit _selectedUnit = ServingUnit.grams;
  List<FoodModel> _results = [];
  FoodModel? _selectedFood;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withAlpha((0.3 * 255).round()),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _selectedFood == null
                    ? 'Buscar ingrediente'
                    : 'Ajustar cantidad',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),

              if (_selectedFood == null) ...[
                // Búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nombre del alimento...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  autofocus: true,
                  onChanged: _onSearch,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_isSearching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Expanded(
                    child: _results.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'Escribe para buscar alimentos'
                                  : 'Sin resultados',
                              style: AppTypography.labelMedium.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final food = _results[index];
                              return ListTile(
                                title: Text(
                                  food.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${food.kcalPer100g} kcal/100g · '
                                  'P:${food.proteinPer100g?.toStringAsFixed(0) ?? '-'} '
                                  'C:${food.carbsPer100g?.toStringAsFixed(0) ?? '-'} '
                                  'G:${food.fatPer100g?.toStringAsFixed(0) ?? '-'}',
                                  style: AppTypography.labelSmall,
                                ),
                                trailing: food.brand != null
                                    ? Text(
                                        food.brand!,
                                        style: AppTypography.labelSmall
                                            .copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      )
                                    : null,
                                onTap: () => _selectFood(food),
                              );
                            },
                          ),
                  ),
              ] else ...[
                // Alimento seleccionado + cantidad
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer
                        .withAlpha((0.3 * 255).round()),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFood!.name,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${_selectedFood!.kcalPer100g} kcal/100g',
                              style: AppTypography.labelSmall.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            setState(() => _selectedFood = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _amountController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<ServingUnit>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unidad',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ServingUnit.grams,
                            child: Text('gramos'),
                          ),
                          DropdownMenuItem(
                            value: ServingUnit.portion,
                            child: Text('porción'),
                          ),
                          DropdownMenuItem(
                            value: ServingUnit.milliliter,
                            child: Text('ml'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedUnit = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Preview de macros
                _IngredientPreview(
                  food: _selectedFood!,
                  amount: double.tryParse(_amountController.text) ?? 100,
                  unit: _selectedUnit,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(_amountController.text) ?? 100;
                    widget.onAdd(_selectedFood!, amount, _selectedUnit);
                  },
                  child: const Text('AÑADIR INGREDIENTE'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final foods = await db.searchFoodsFTS(query, limit: 20);

      // Mapear Drift Food → FoodModel usando la extensión
      final models = foods.map((f) => f.toModel()).toList();

      if (mounted) {
        setState(() {
          _results = models;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectFood(FoodModel food) {
    setState(() {
      _selectedFood = food;
      // Auto-seleccionar gramos si no tiene porción, o porción si sí
      if (food.portionGrams != null && food.portionGrams! > 0) {
        _selectedUnit = ServingUnit.portion;
        _amountController.text = '1';
      } else {
        _selectedUnit = ServingUnit.grams;
        _amountController.text = '100';
      }
    });
  }
}

class _IngredientPreview extends StatelessWidget {
  final FoodModel food;
  final double amount;
  final ServingUnit unit;

  const _IngredientPreview({
    required this.food,
    required this.amount,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    double grams = amount;
    if (unit == ServingUnit.portion) {
      grams = amount * (food.portionGrams ?? 100);
    }
    final macros = food.macrosForGrams(grams);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _PreviewStat('kcal', '${macros.kcal}', colors.primary),
          _PreviewStat('P', '${macros.protein?.toStringAsFixed(1) ?? '-'}g',
              const Color(0xFF4CAF50)),
          _PreviewStat('C', '${macros.carbs?.toStringAsFixed(1) ?? '-'}g',
              const Color(0xFFFF9800)),
          _PreviewStat('G', '${macros.fat?.toStringAsFixed(1) ?? '-'}g',
              const Color(0xFFF44336)),
        ],
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PreviewStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.labelMedium
                .copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: AppTypography.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )),
      ],
    );
  }
}
