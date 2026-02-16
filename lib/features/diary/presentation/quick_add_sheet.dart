import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/core/providers/database_provider.dart';

/// Bottom sheet para entrada rápida de calorías y macros.
///
/// Permite registrar kcal/macros en 2 taps sin buscar un alimento.
/// Usa [DiaryEntryModel.quickAdd] con `isQuickAdd: true`.
class QuickAddSheet extends ConsumerStatefulWidget {
  /// Comida pre-seleccionada (null = auto-detectar por hora)
  final MealType? preselectedMeal;

  const QuickAddSheet({super.key, this.preselectedMeal});

  /// Muestra el bottom sheet y retorna true si se guardó una entrada.
  static Future<bool?> show(BuildContext context, {MealType? mealType}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => QuickAddSheet(preselectedMeal: mealType),
    );
  }

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  late MealType _mealType;
  final _nameController = TextEditingController(text: 'Entrada rápida');
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _kcalFocus = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mealType = widget.preselectedMeal ?? _suggestMealType();
    // Auto-focus el campo de kcal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kcalFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _kcalFocus.dispose();
    super.dispose();
  }

  MealType _suggestMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return MealType.breakfast;
    if (hour < 15) return MealType.lunch;
    if (hour < 20) return MealType.dinner;
    return MealType.snack;
  }

  Future<void> _save() async {
    final kcalText = _kcalController.text.trim();
    if (kcalText.isEmpty) return;

    final kcal = int.tryParse(kcalText);
    if (kcal == null || kcal <= 0) return;

    setState(() => _isSaving = true);

    try {
      final date = ref.read(selectedDateProvider);
      final name = _nameController.text.trim().isEmpty
          ? 'Entrada rápida'
          : _nameController.text.trim();

      final entry = DiaryEntryModel.quickAdd(
        id: '${DateTime.now().millisecondsSinceEpoch}_quick',
        date: date,
        mealType: _mealType,
        name: name,
        kcal: kcal,
        protein: double.tryParse(_proteinController.text.trim()),
        carbs: double.tryParse(_carbsController.text.trim()),
        fat: double.tryParse(_fatController.text.trim()),
      );

      await ref.read(diaryRepositoryProvider).insert(entry);

      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: '$name · $kcal kcal añadido',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, message: 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withAlpha((0.4 * 255).round()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Título
          Row(
            children: [
              Icon(Icons.bolt, color: colors.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Entrada rápida',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Selector de comida
          _MealTypeSelector(
            selected: _mealType,
            onChanged: (type) => setState(() => _mealType = type),
          ),
          const SizedBox(height: AppSpacing.md),

          // Nombre (opcional)
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre (opcional)',
              hintText: 'Ej: Café con leche',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              isDense: true,
              prefixIcon: const Icon(Icons.label_outline, size: 20),
            ),
            style: AppTypography.bodyMedium,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),

          // Kcal (campo principal, grande)
          TextField(
            controller: _kcalController,
            focusNode: _kcalFocus,
            decoration: InputDecoration(
              labelText: 'Calorías (kcal) *',
              hintText: '0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              prefixIcon: const Icon(Icons.local_fire_department, size: 20),
              suffixText: 'kcal',
            ),
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Macros (opcionales, fila de 3)
          Text(
            'Macros (opcional)',
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _MacroField(
                  controller: _proteinController,
                  label: 'Prot',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MacroField(
                  controller: _carbsController,
                  label: 'Carbs',
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MacroField(
                  controller: _fatController,
                  label: 'Grasa',
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Botón guardar
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('AÑADIR'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Selector de tipo de comida con chips.
class _MealTypeSelector extends StatelessWidget {
  final MealType selected;
  final ValueChanged<MealType> onChanged;

  const _MealTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MealType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type != MealType.snack ? 6 : 0,
            ),
            child: ChoiceChip(
              label: Text(
                _shortName(type),
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                onChanged(type);
              },
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              showCheckmark: false,
              avatar: Icon(_mealIcon(type), size: 16),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _shortName(MealType type) {
    return switch (type) {
      MealType.breakfast => 'Desay.',
      MealType.lunch => 'Almuer.',
      MealType.dinner => 'Cena',
      MealType.snack => 'Snack',
    };
  }

  IconData _mealIcon(MealType type) {
    return switch (type) {
      MealType.breakfast => Icons.wb_sunny_outlined,
      MealType.lunch => Icons.restaurant,
      MealType.dinner => Icons.nightlight_outlined,
      MealType.snack => Icons.cookie_outlined,
    };
  }
}

/// Campo de macro individual (Prot/Carbs/Grasa).
class _MacroField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;

  const _MacroField({
    required this.controller,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.labelSmall.copyWith(color: color),
        hintText: '0',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        isDense: true,
        suffixText: 'g',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
      ),
      style: AppTypography.bodyMedium,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
      ],
    );
  }
}
