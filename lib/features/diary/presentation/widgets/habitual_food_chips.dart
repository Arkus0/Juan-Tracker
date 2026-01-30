import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/diet/models/diary_entry_model.dart';
import 'package:juan_tracker/diet/providers/habitual_food_provider.dart';
import 'package:juan_tracker/core/design_system/design_system.dart';

/// Chips horizontales que muestran comidas habituales para el tipo de comida actual
/// Permite añadir con un solo tap
class HabitualFoodChips extends ConsumerWidget {
  final MealType? overrideMealType;
  final void Function(String foodName, String? foodId, double avgQuantity)?
      onFoodSelected;

  const HabitualFoodChips({
    super.key,
    this.overrideMealType,
    this.onFoodSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentMealType = ref.watch(currentMealTypeProvider);
    final mealType = overrideMealType ?? currentMealType;

    final patternsAsync = ref.watch(habitualFoodByMealProvider(mealType));

    return patternsAsync.when(
      data: (patterns) {
        if (patterns.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tus habituales',
                  style: AppTypography.labelMedium.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: patterns.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final pattern = patterns[index];
                  return _HabitualFoodChip(
                    pattern: pattern,
                    onTap: () {
                      if (onFoodSelected != null) {
                        onFoodSelected!(
                          pattern.foodName,
                          pattern.foodId,
                          pattern.avgQuantity,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _HabitualFoodChip extends StatelessWidget {
  final HabitualFoodPattern pattern;
  final VoidCallback onTap;

  const _HabitualFoodChip({
    required this.pattern,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: ActionChip(
        avatar: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${pattern.frequency}x',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        label: Text(pattern.foodName),
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onPressed: onTap,
      ),
    );
  }
}

/// Widget combinado que muestra el mensaje de contexto + chips habituales
class HabitualFoodSection extends ConsumerWidget {
  final void Function(String foodName, String? foodId, double avgQuantity)?
      onFoodSelected;

  const HabitualFoodSection({
    super.key,
    this.onFoodSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = ref.watch(mealContextMessageProvider);
    final currentMealType = ref.watch(currentMealTypeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mensaje de contexto
          Row(
            children: [
              _MealTypeIcon(mealType: currentMealType),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chips de comidas habituales
          HabitualFoodChips(
            onFoodSelected: onFoodSelected,
          ),
        ],
      ),
    );
  }
}

class _MealTypeIcon extends StatelessWidget {
  final MealType mealType;

  const _MealTypeIcon({required this.mealType});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final colorScheme = Theme.of(context).colorScheme;

    late final IconData icon;
    late final Color color;

    switch (mealType) {
      case MealType.breakfast:
        icon = Icons.wb_sunny_outlined;
        color = Colors.orange;
      case MealType.lunch:
        icon = Icons.lunch_dining_outlined;
        color = Colors.green;
      case MealType.snack:
        icon = Icons.coffee_outlined;
        color = Colors.brown;
      case MealType.dinner:
        icon = Icons.nightlight_outlined;
        color = Colors.indigo;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}
