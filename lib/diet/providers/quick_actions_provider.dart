/// Providers para Quick Actions (Recents + Repetir ayer)
///
/// Proporciona acceso rápido a alimentos recientes y funcionalidad
/// para repetir las comidas del día anterior.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../models/models.dart';

// ============================================================================
// YESTERDAY MEALS PROVIDER
// ============================================================================

/// Modelo para las comidas de ayer agrupadas por tipo
class YesterdayMeals {
  final List<DiaryEntryModel> breakfast;
  final List<DiaryEntryModel> lunch;
  final List<DiaryEntryModel> dinner;
  final List<DiaryEntryModel> snack;
  final int totalKcal;
  final int entryCount;

  const YesterdayMeals({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.totalKcal,
    required this.entryCount,
  });

  bool get isEmpty => entryCount == 0;
  bool get hasBreakfast => breakfast.isNotEmpty;
  bool get hasLunch => lunch.isNotEmpty;
  bool get hasDinner => dinner.isNotEmpty;
  bool get hasSnack => snack.isNotEmpty;

  List<DiaryEntryModel> get all => [...breakfast, ...lunch, ...dinner, ...snack];

  List<DiaryEntryModel> byMealType(MealType type) {
    return switch (type) {
      MealType.breakfast => breakfast,
      MealType.lunch => lunch,
      MealType.dinner => dinner,
      MealType.snack => snack,
    };
  }
}

/// Provider que obtiene las comidas del día anterior al día seleccionado.
/// 
/// Si el usuario está viendo el día 5 en el calendario, "ayer" es el día 4,
/// no el día anterior a "hoy".
final yesterdayMealsProvider = FutureProvider<YesterdayMeals>((ref) async {
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  // Usar la fecha seleccionada, no DateTime.now()
  final selectedDate = ref.watch(selectedDateProvider);
  // "Ayer" es el día anterior a la fecha seleccionada
  final yesterday = DateTime(selectedDate.year, selectedDate.month, selectedDate.day - 1);
  final yesterdayEnd = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

  final entries = await diaryRepo.getByDateRange(yesterday, yesterdayEnd);

  final breakfast = entries.where((e) => e.mealType == MealType.breakfast).toList();
  final lunch = entries.where((e) => e.mealType == MealType.lunch).toList();
  final dinner = entries.where((e) => e.mealType == MealType.dinner).toList();
  final snack = entries.where((e) => e.mealType == MealType.snack).toList();

  final totalKcal = entries.fold<int>(0, (sum, e) => sum + e.kcal);

  return YesterdayMeals(
    breakfast: breakfast,
    lunch: lunch,
    dinner: dinner,
    snack: snack,
    totalKcal: totalKcal,
    entryCount: entries.length,
  );
});

// ============================================================================
// REPEAT YESTERDAY PROVIDER
// ============================================================================

/// Helper para generar una clave única que identifica un alimento + comida
String _entryKey(DiaryEntryModel entry) {
  // Usamos foodId si existe, o foodName + brand como fallback
  final foodKey = entry.foodId ?? '${entry.foodName}|${entry.foodBrand ?? ''}';
  return '${entry.mealType.name}|$foodKey|${entry.amount}|${entry.unit.name}';
}

/// Acción para repetir todas las comidas de ayer en el día actual.
/// 
/// IMPORTANTE: Evita duplicados verificando si ya existen entradas
/// con el mismo alimento, comida, cantidad y unidad en el día destino.
final repeatYesterdayProvider = Provider<Future<int> Function()>((ref) {
  return () async {
    final diaryRepo = ref.read(diaryRepositoryProvider);
    final selectedDate = ref.read(selectedDateProvider);
    final yesterdayMeals = await ref.read(yesterdayMealsProvider.future);

    if (yesterdayMeals.isEmpty) return 0;

    // Obtener las entradas del día destino para evitar duplicados
    final dayStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final existingEntries = await diaryRepo.getByDateRange(dayStart, dayEnd);
    
    // Crear un Set de claves de las entradas existentes
    final existingKeys = existingEntries.map(_entryKey).toSet();

    int count = 0;
    for (final entry in yesterdayMeals.all) {
      // Solo insertar si no existe ya una entrada idéntica
      final key = _entryKey(entry);
      if (!existingKeys.contains(key)) {
        final newEntry = entry.copyWith(
          id: '${DateTime.now().millisecondsSinceEpoch}_$count',
          date: selectedDate,
          createdAt: DateTime.now(),
        );
        await diaryRepo.insert(newEntry);
        existingKeys.add(key); // Prevenir duplicados dentro del mismo batch
        count++;
      }
    }

    return count;
  };
});

/// Acción para repetir solo una comida de ayer.
/// 
/// IMPORTANTE: Evita duplicados verificando si ya existen entradas
/// con el mismo alimento, cantidad y unidad en el día destino.
final repeatMealFromYesterdayProvider = Provider.family<Future<int> Function(), MealType>(
  (ref, mealType) {
    return () async {
      final diaryRepo = ref.read(diaryRepositoryProvider);
      final selectedDate = ref.read(selectedDateProvider);
      final yesterdayMeals = await ref.read(yesterdayMealsProvider.future);

      final entries = yesterdayMeals.byMealType(mealType);
      if (entries.isEmpty) return 0;

      // Obtener las entradas del día destino para evitar duplicados
      final dayStart = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final existingEntries = await diaryRepo.getByDateRange(dayStart, dayEnd);
      
      // Crear un Set de claves de las entradas existentes
      final existingKeys = existingEntries.map(_entryKey).toSet();

      int count = 0;
      for (final entry in entries) {
        // Solo insertar si no existe ya una entrada idéntica
        final key = _entryKey(entry);
        if (!existingKeys.contains(key)) {
          final newEntry = entry.copyWith(
            id: '${DateTime.now().millisecondsSinceEpoch}_$count',
            date: selectedDate,
            createdAt: DateTime.now(),
          );
          await diaryRepo.insert(newEntry);
          existingKeys.add(key); // Prevenir duplicados dentro del mismo batch
          count++;
        }
      }

      return count;
    };
  },
);

// ============================================================================
// QUICK RECENT FOODS PROVIDER (alimentos recientes únicos)
// ============================================================================

/// Alimento reciente con metadata
class QuickRecentFood {
  final String id;
  final String name;
  final String? brand;
  final int kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final DateTime lastUsed;
  final int useCount;
  final double lastAmount;
  final ServingUnit lastUnit;

  const QuickRecentFood({
    required this.id,
    required this.name,
    this.brand,
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    required this.lastUsed,
    required this.useCount,
    required this.lastAmount,
    required this.lastUnit,
  });

  String get displayName => brand != null ? '$name ($brand)' : name;
}

/// Provider que obtiene los últimos 10 alimentos usados (únicos)
final quickRecentFoodsProvider = FutureProvider<List<QuickRecentFood>>((ref) async {
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final now = DateTime.now();
  final twoWeeksAgo = now.subtract(const Duration(days: 14));

  final entries = await diaryRepo.getByDateRange(twoWeeksAgo, now);

  // Agrupar por foodId o foodName
  final Map<String, List<DiaryEntryModel>> grouped = {};
  for (final entry in entries) {
    final key = entry.foodId ?? entry.foodName.toLowerCase().trim();
    grouped.putIfAbsent(key, () => []).add(entry);
  }

  // Convertir a QuickRecentFood
  final recentFoods = grouped.entries.map((entry) {
    final key = entry.key;
    final entryList = entry.value;

    // Ordenar por fecha (más reciente primero)
    entryList.sort((a, b) => b.date.compareTo(a.date));
    final mostRecent = entryList.first;

    return QuickRecentFood(
      id: key,
      name: mostRecent.foodName,
      brand: mostRecent.foodBrand,
      kcal: mostRecent.kcal,
      protein: mostRecent.protein,
      carbs: mostRecent.carbs,
      fat: mostRecent.fat,
      lastUsed: mostRecent.date,
      useCount: entryList.length,
      lastAmount: mostRecent.amount,
      lastUnit: mostRecent.unit,
    );
  }).toList();

  // Ordenar por recencia
  recentFoods.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

  // Limitar a 10
  return recentFoods.take(10).toList();
});
