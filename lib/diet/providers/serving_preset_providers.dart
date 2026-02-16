import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../models/models.dart';

// ============================================================================
// MODELO DE PRESET
// ============================================================================

/// Un preset de porción mostrado como chip en el diálogo
class ServingPreset {
  final String label;
  final double amount;
  final ServingUnit unit;
  final bool isLastUsed;

  const ServingPreset({
    required this.label,
    required this.amount,
    required this.unit,
    this.isLastUsed = false,
  });
}

/// Resultado de búsqueda de la última porción usada para un alimento
class LastUsedServing {
  final double amount;
  final ServingUnit unit;

  const LastUsedServing({required this.amount, required this.unit});
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Obtiene la última porción usada para un foodId (últimos 90 días)
final lastUsedServingProvider =
    FutureProvider.family<LastUsedServing?, String>((ref, foodId) async {
  final repo = ref.read(diaryRepositoryProvider);

  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 90));

  final entries = await repo.getByDateRange(from, now);

  // Buscar la entrada más reciente con este foodId
  DiaryEntryModel? latest;
  for (final entry in entries) {
    if (entry.foodId == foodId) {
      if (latest == null || entry.date.isAfter(latest.date)) {
        latest = entry;
      }
    }
  }

  if (latest == null) return null;

  return LastUsedServing(
    amount: latest.amount,
    unit: latest.unit,
  );
});

/// Genera una lista de presets de porción para un alimento
final servingPresetsProvider =
    FutureProvider.family<List<ServingPreset>, FoodModel>((ref, food) async {
  final presets = <ServingPreset>[];

  // 1. Último usado (si existe)
  if (food.id.isNotEmpty) {
    final lastUsed = await ref.watch(lastUsedServingProvider(food.id).future);
    if (lastUsed != null) {
      final label = _formatPresetLabel(lastUsed.amount, lastUsed.unit, food);
      presets.add(ServingPreset(
        label: '↺ $label',
        amount: lastUsed.amount,
        unit: lastUsed.unit,
        isLastUsed: true,
      ));
    }
  }

  // 2. Porción del alimento (si existe y no es duplicado del último usado)
  if (food.portionName != null && food.portionGrams != null) {
    final isDuplicate = presets.any(
      (p) => p.unit == ServingUnit.portion && p.amount == 1,
    );
    if (!isDuplicate) {
      presets.add(ServingPreset(
        label: '1 ${food.portionName}',
        amount: 1,
        unit: ServingUnit.portion,
      ));
    }

    // Media porción
    presets.add(ServingPreset(
      label: '½ ${food.portionName}',
      amount: 0.5,
      unit: ServingUnit.portion,
    ));
  }

  // 3. Cantidades estándar en gramos
  final standardGrams = [50, 100, 150, 200];
  for (final g in standardGrams) {
    final isDuplicate = presets.any(
      (p) => p.unit == ServingUnit.grams && p.amount == g.toDouble(),
    );
    if (!isDuplicate) {
      presets.add(ServingPreset(
        label: '${g}g',
        amount: g.toDouble(),
        unit: ServingUnit.grams,
      ));
    }
  }

  return presets;
});

// ============================================================================
// HELPERS
// ============================================================================

String _formatPresetLabel(double amount, ServingUnit unit, FoodModel food) {
  switch (unit) {
    case ServingUnit.grams:
      return amount == amount.roundToDouble()
          ? '${amount.toInt()}g'
          : '${amount.toStringAsFixed(1)}g';
    case ServingUnit.portion:
      final name = food.portionName ?? 'porción';
      if (amount == 1) return '1 $name';
      if (amount == 0.5) return '½ $name';
      return '${amount.toStringAsFixed(1)} $name';
    case ServingUnit.milliliter:
      return amount == amount.roundToDouble()
          ? '${amount.toInt()}ml'
          : '${amount.toStringAsFixed(1)}ml';
  }
}
