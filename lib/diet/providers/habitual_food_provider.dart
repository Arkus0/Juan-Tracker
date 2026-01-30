import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/diet/models/diary_entry_model.dart';
import 'package:juan_tracker/core/providers/database_provider.dart';

/// Patrón de comida habitual detectado
class HabitualFoodPattern {
  final String foodName;
  final MealType mealType;
  final int frequency; // Número de veces consumido
  final DateTime lastUsed;
  final double avgQuantity;
  final String? foodId;

  const HabitualFoodPattern({
    required this.foodName,
    required this.mealType,
    required this.frequency,
    required this.lastUsed,
    required this.avgQuantity,
    this.foodId,
  });

  HabitualFoodPattern copyWith({
    String? foodName,
    MealType? mealType,
    int? frequency,
    DateTime? lastUsed,
    double? avgQuantity,
    String? foodId,
  }) {
    return HabitualFoodPattern(
      foodName: foodName ?? this.foodName,
      mealType: mealType ?? this.mealType,
      frequency: frequency ?? this.frequency,
      lastUsed: lastUsed ?? this.lastUsed,
      avgQuantity: avgQuantity ?? this.avgQuantity,
      foodId: foodId ?? this.foodId,
    );
  }
}

/// Provider que detecta patrones de comida habitual basados en el historial
final habitualFoodProvider = FutureProvider<List<HabitualFoodPattern>>((ref) async {
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  // Obtener entradas de los últimos 30 días
  final entries = await diaryRepo.getByDateRange(thirtyDaysAgo, now);

  if (entries.isEmpty) {
    return [];
  }

  // Agrupar por tipo de comida y nombre de alimento
  final Map<MealType, Map<String, List<DiaryEntryModel>>> grouped = {};

  for (final entry in entries) {
    final mealType = entry.mealType;
    final foodName = entry.foodName.toLowerCase().trim();

    grouped.putIfAbsent(mealType, () => {});
    grouped[mealType]!.putIfAbsent(foodName, () => []);
    grouped[mealType]![foodName]!.add(entry);
  }

  // Calcular patrones habituales (>40% de frecuencia)
  final List<HabitualFoodPattern> patterns = [];

  // Contar días únicos por tipo de comida
  final Map<MealType, Set<DateTime>> daysByMeal = {};
  for (final entry in entries) {
    daysByMeal.putIfAbsent(entry.mealType, () => {});
    daysByMeal[entry.mealType]!.add(
      DateTime(entry.date.year, entry.date.month, entry.date.day),
    );
  }

  grouped.forEach((mealType, foods) {
    final totalDays = daysByMeal[mealType]?.length ?? 1;

    foods.forEach((foodName, foodEntries) {
      // Contar días únicos en los que se comió este alimento
      final uniqueDays = foodEntries
          .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
          .toSet();
      final frequency = uniqueDays.length;
      final frequencyRatio = frequency / totalDays;

      // Solo incluir si >40% de frecuencia
      if (frequencyRatio >= 0.4) {
        // Calcular cantidad promedio (en gramos si está disponible)
        final avgQuantity = foodEntries.isNotEmpty
            ? foodEntries.map((e) => e.amount).reduce((a, b) => a + b) /
                foodEntries.length
            : 0.0;

        // Último uso
        final lastUsed = foodEntries
            .map((e) => e.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        // Obtener foodId del entry más reciente si existe
        final mostRecent = foodEntries
            .where((e) => e.foodId != null)
            .fold<DiaryEntryModel?>(
                null,
                (prev, curr) =>
                    prev == null || curr.date.isAfter(prev.date) ? curr : prev);

        patterns.add(HabitualFoodPattern(
          foodName: foodEntries.first.foodName, // Usar nombre original (con case)
          mealType: mealType,
          frequency: frequency,
          lastUsed: lastUsed,
          avgQuantity: avgQuantity,
          foodId: mostRecent?.foodId,
        ));
      }
    });
  });

  // Ordenar por frecuencia (descendente) y recencia
  patterns.sort((a, b) {
    final freqCompare = b.frequency.compareTo(a.frequency);
    if (freqCompare != 0) {
      return freqCompare;
    }
    return b.lastUsed.compareTo(a.lastUsed);
  });

  return patterns;
});

/// Provider que filtra patrones por tipo de comida actual
final habitualFoodByMealProvider = FutureProvider.family<List<HabitualFoodPattern>, MealType>(
  (ref, mealType) async {
    final allPatterns = await ref.watch(habitualFoodProvider.future);
    return allPatterns.where((p) => p.mealType == mealType).take(3).toList();
  },
);

/// Provider que determina el tipo de comida actual basado en la hora del día
final currentMealTypeProvider = Provider<MealType>((ref) {
  final hour = DateTime.now().hour;

  if (hour >= 6 && hour < 11) {
    return MealType.breakfast;
  } else if (hour >= 11 && hour < 15) {
    return MealType.lunch;
  } else if (hour >= 15 && hour < 19) {
    return MealType.snack;
  } else {
    return MealType.dinner;
  }
});

/// Provider para obtener el mensaje de contexto de comida
final mealContextMessageProvider = Provider<String>((ref) {
  final mealType = ref.watch(currentMealTypeProvider);
  final hour = DateTime.now().hour;

  switch (mealType) {
    case MealType.breakfast:
      return hour < 9 ? '¡Buenos días! ¿Qué desayunas hoy?' : '¿Algo más para desayunar?';
    case MealType.lunch:
      return hour < 13 ? 'Hora de almorzar' : '¿Qué almorzaste?';
    case MealType.snack:
      return 'Merienda time ☕';
    case MealType.dinner:
      return hour >= 21 ? 'Cena de campeones' : '¿Qué cenamos hoy?';
  }
});

/// Provider para añadir una comida habitual al diario
final addHabitualFoodProvider = Provider.autoDispose
    .family<Future<void> Function(), HabitualFoodPattern>(
  (ref, pattern) {
    return () async {
      final diaryRepo = ref.read(diaryRepositoryProvider);
      final selectedDate = ref.read(selectedDateProvider);

      // Crear entrada basada en el patrón
      final entry = DiaryEntryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: selectedDate,
        mealType: pattern.mealType,
        foodId: pattern.foodId,
        foodName: pattern.foodName,
        amount: pattern.avgQuantity,
        unit: ServingUnit.grams,
        kcal: 0, // Se calculará si hay foodId
        createdAt: DateTime.now(),
      );

      await diaryRepo.insert(entry);
    };
  },
);
