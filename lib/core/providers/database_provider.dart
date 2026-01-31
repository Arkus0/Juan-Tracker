import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diet/models/models.dart' as diet;
import '../../diet/repositories/repositories.dart';
import '../../diet/repositories/drift_diet_repositories.dart';
import '../../training/database/database.dart';
import '../models/user_profile_model.dart';
import '../repositories/i_training_repository.dart';
import '../repositories/in_memory_training_repository.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/local_exercise_repository.dart';
import '../repositories/routine_repository.dart';
import '../repositories/in_memory_routine_repository.dart';

// ============================================================================
// DATABASE & REPOSITORIES
// ============================================================================

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final foodRepositoryProvider = Provider<IFoodRepository>((ref) {
  return DriftFoodRepository(ref.watch(appDatabaseProvider));
});

final diaryRepositoryProvider = Provider<IDiaryRepository>((ref) {
  return DriftDiaryRepository(ref.watch(appDatabaseProvider));
});

final weighInRepositoryProvider = Provider<IWeighInRepository>((ref) {
  return DriftWeighInRepository(ref.watch(appDatabaseProvider));
});

final targetsRepositoryProvider = Provider<ITargetsRepository>((ref) {
  return DriftTargetsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(diaryRepositoryProvider),
  );
});

// ============================================================================
// UI STATE - DATE
// ============================================================================

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = DateTime(date.year, date.month, date.day);
  void goToToday() => state = DateTime.now();
  void previousDay() => state = state.subtract(const Duration(days: 1));
  void nextDay() => state = state.add(const Duration(days: 1));
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

// ============================================================================
// UI STATE - STREAMS
// ============================================================================

final dayEntriesStreamProvider = StreamProvider.autoDispose<List<diet.DiaryEntryModel>>((ref) {
  return ref.watch(diaryRepositoryProvider).watchByDate(ref.watch(selectedDateProvider));
});

final dailyTotalsProvider = StreamProvider.autoDispose<diet.DailyTotals>((ref) {
  return ref.watch(diaryRepositoryProvider).watchDailyTotals(ref.watch(selectedDateProvider));
});

final foodSearchResultsProvider = FutureProvider.autoDispose<List<diet.FoodModel>>((ref) async {
  final query = ref.watch(foodSearchQueryProvider);
  if (query.trim().isEmpty) return ref.watch(foodRepositoryProvider).getAll();
  return ref.watch(foodRepositoryProvider).search(query);
});

final latestWeightProvider = FutureProvider<diet.WeighInModel?>((ref) {
  return ref.watch(weighInRepositoryProvider).getLatest();
});

final weightStreamProvider = StreamProvider<List<diet.WeighInModel>>((ref) {
  final from = DateTime.now().subtract(const Duration(days: 90));
  return ref.watch(weighInRepositoryProvider).watchByDateRange(from, DateTime.now());
});

/// 🎯 MED-002: Provider de días con entradas para el calendario
/// Emite un Set de fechas (truncadas a día) que tienen al menos una entrada
///
/// OPTIMIZACIÓN: Usa SELECT DISTINCT solo en la columna date en lugar de
/// cargar todas las filas. Esto reduce significativamente el uso de memoria
/// y CPU para usuarios con muchas entradas de diario.
final calendarEntryDaysProvider = StreamProvider<Set<DateTime>>((ref) {
  final db = ref.watch(appDatabaseProvider);

  // Use selectOnly with distinct to fetch only unique dates
  // This is O(unique_dates) instead of O(total_entries)
  final query = db.selectOnly(db.diaryEntries, distinct: true)
    ..addColumns([db.diaryEntries.date]);

  return query.watch().map((rows) {
    return rows.map((row) {
      final date = row.read(db.diaryEntries.date)!;
      // Truncate to day (dates should already be truncated per schema)
      return DateTime(date.year, date.month, date.day);
    }).toSet();
  });
});

// ============================================================================
// UI STATE - SIMPLE STATE (migrado a Notifier para compatibilidad con Riverpod 3)
// ============================================================================

final foodSearchQueryProvider = NotifierProvider<FoodSearchQueryNotifier, String>(
  FoodSearchQueryNotifier.new,
);

class FoodSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  set query(String q) => state = q;
}

final selectedFoodProvider = NotifierProvider<SelectedFoodNotifier, diet.FoodModel?>(
  SelectedFoodNotifier.new,
);

class SelectedFoodNotifier extends Notifier<diet.FoodModel?> {
  @override
  diet.FoodModel? build() => null;

  set selected(diet.FoodModel? f) => state = f;
}

final editingEntryProvider = NotifierProvider<EditingEntryNotifier, diet.DiaryEntryModel?>(
  EditingEntryNotifier.new,
);

class EditingEntryNotifier extends Notifier<diet.DiaryEntryModel?> {
  @override
  diet.DiaryEntryModel? build() => null;

  set editing(diet.DiaryEntryModel? e) => state = e;
}

final selectedMealTypeProvider = NotifierProvider<SelectedMealTypeNotifier, diet.MealType>(
  SelectedMealTypeNotifier.new,
);

class SelectedMealTypeNotifier extends Notifier<diet.MealType> {
  @override
  diet.MealType build() => diet.MealType.snack;

  set meal(diet.MealType m) => state = m;
}

// ============================================================================
// RECENT FOODS - Para Quick Add (UX optimization)
// ============================================================================

/// Compara dos listas de DiaryEntryModel para evitar emisiones redundantes
bool _areDiaryEntryListsEqual(
  List<diet.DiaryEntryModel> previous,
  List<diet.DiaryEntryModel> next,
) {
  if (identical(previous, next)) return true;
  if (previous.length != next.length) return false;

  for (var i = 0; i < previous.length; i++) {
    if (previous[i] != next[i]) {
      return false;
    }
  }
  return true;
}

/// Provider de comidas recientes para quick-add (UX-002)
/// Retorna las últimas 7 comidas únicas registradas (por foodId)
/// Ordenadas por frecuencia de consumo (más frecuentes primero)
///
/// FIX: StreamProvider para ser reactivo a nuevas entradas en el diario,
/// pero usando `distinct` para evitar emisiones cuando la lista de recientes
/// no ha cambiado realmente.
final recentFoodsProvider = StreamProvider<List<diet.DiaryEntryModel>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  // Capture repo reference outside asyncMap to avoid accessing disposed ref
  // inside stream callback (ref.read inside asyncMap can fail if provider disposed)
  final repo = ref.watch(diaryRepositoryProvider);

  // Escuchar cambios en la tabla diary_entries
  return db
      .select(db.diaryEntries)
      .watch()
      .asyncMap((_) async {
        // UX-002: Aumentado a 7 items, ordenado por frecuencia
        return repo.getRecentUniqueEntries(limit: 7);
      })
      .distinct(_areDiaryEntryListsEqual);
});

// ============================================================================
// 🎯 HIGH-003: SMART FOOD SUGGESTIONS - Sugerencias por hora/historial
// ============================================================================

/// Determina el MealType sugerido basado en la hora actual
diet.MealType _getMealTypeForTime(DateTime time) {
  final hour = time.hour;
  if (hour >= 6 && hour < 11) return diet.MealType.breakfast;
  if (hour >= 11 && hour < 15) return diet.MealType.lunch;
  if (hour >= 15 && hour < 18) return diet.MealType.snack;
  if (hour >= 18 && hour < 22) return diet.MealType.dinner;
  return diet.MealType.snack; // Default para madrugada/noche
}

/// Modelo de sugerencia de comida con contexto
class SmartFoodSuggestion {
  final String foodName;
  final String? foodId;
  final String? brand;
  final int kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double amount;
  final diet.ServingUnit unit;
  final int timesEaten;
  final diet.MealType suggestedMealType;
  final String reason;

  const SmartFoodSuggestion({
    required this.foodName,
    this.foodId,
    this.brand,
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    required this.amount,
    required this.unit,
    required this.timesEaten,
    required this.suggestedMealType,
    required this.reason,
  });

  /// Crea una entrada de diario a partir de la sugerencia
  diet.DiaryEntryModel toEntry({
    required String id,
    required DateTime date,
    diet.MealType? mealType,
  }) {
    return diet.DiaryEntryModel(
      id: id,
      date: date,
      mealType: mealType ?? suggestedMealType,
      foodId: foodId,
      foodName: foodName,
      foodBrand: brand,
      amount: amount,
      unit: unit,
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }
}

/// Notifier para el MealType actual basado en la hora.
///
/// IMPORTANTE: Este provider cachea el valor calculado. Para obtener un valor
/// actualizado con la hora actual, invalide el provider:
///   ref.invalidate(currentMealTypeProvider);
///
/// Se recomienda invalidar:
/// - En initState/didChangeDependencies de pantallas principales
/// - Cuando la app vuelve de segundo plano (AppLifecycleState.resumed)
class CurrentMealTypeNotifier extends Notifier<diet.MealType> {
  @override
  diet.MealType build() {
    return _getMealTypeForTime(DateTime.now());
  }
}

final currentMealTypeProvider = NotifierProvider<CurrentMealTypeNotifier, diet.MealType>(
  CurrentMealTypeNotifier.new,
);

/// Provider de sugerencias inteligentes de comida basadas en:
/// 1. Hora del día (desayuno, almuerzo, cena, snack)
/// 2. Historial del usuario para esa comida (últimos 30 días)
/// 3. Frecuencia de consumo (>40% de días = "habitual")
/// 🎯 HIGH-003: Comida Habitual - Detección de patrones temporales
final smartFoodSuggestionsProvider = FutureProvider<List<SmartFoodSuggestion>>((ref) async {
  final repo = ref.read(diaryRepositoryProvider);
  final suggestedMeal = ref.watch(currentMealTypeProvider);

  // 🎯 HIGH-003: Usar rango de 30 días para detección de patrones
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  final recentEntries = await repo.getByDateRange(thirtyDaysAgo, now);

  // Filtrar solo entradas del tipo de comida actual
  final mealEntries = recentEntries.where((e) => e.mealType == suggestedMeal).toList();

  if (mealEntries.isEmpty) {
    // Sin historial para este tipo de comida
    return [];
  }

  // Contar días únicos con este tipo de comida
  final uniqueDays = mealEntries
      .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
      .toSet();
  final totalDaysWithMealType = uniqueDays.length;

  // Agrupar por alimento y contar frecuencia
  final frequencyMap = <String, _FoodFrequency>{};

  for (final entry in mealEntries) {
    final key = entry.foodId ?? entry.foodName.toLowerCase().trim();
    if (frequencyMap.containsKey(key)) {
      frequencyMap[key]!.addEntry(entry);
    } else {
      frequencyMap[key] = _FoodFrequency(entry: entry)..addEntry(entry);
    }
  }

  // Calcular ratio de frecuencia y filtrar habituales (>40%)
  final habitualFoods = frequencyMap.values.where((freq) {
    final ratio = freq.uniqueDays.length / totalDaysWithMealType;
    return ratio >= 0.4; // 40% threshold = "habitual"
  }).toList();

  if (habitualFoods.isEmpty) {
    // Sin habituales claros, mostrar los más frecuentes (top 3)
    final sorted = frequencyMap.values.toList()
      ..sort((a, b) => b.uniqueDays.length.compareTo(a.uniqueDays.length));
    habitualFoods.addAll(sorted.take(3));
  }

  // Ordenar por frecuencia (descendente) y último uso
  habitualFoods.sort((a, b) {
    final countCompare = b.uniqueDays.length.compareTo(a.uniqueDays.length);
    if (countCompare != 0) return countCompare;
    return b.lastUsed.compareTo(a.lastUsed);
  });

  // Tomar top 3 y convertir a SmartFoodSuggestion
  return habitualFoods.take(3).map((freq) {
    final entry = freq.mostRecentEntry;
    final count = freq.uniqueDays.length;
    final ratio = count / totalDaysWithMealType;

    String reason;
    if (ratio >= 0.7) {
      reason = 'Casi siempre (${count}x)';
    } else if (ratio >= 0.5) {
      reason = 'Muy habitual (${count}x)';
    } else if (ratio >= 0.4) {
      reason = 'Frecuente (${count}x)';
    } else {
      reason = 'Reciente (${count}x)';
    }

    return SmartFoodSuggestion(
      foodName: entry.foodName,
      foodId: entry.foodId,
      brand: entry.foodBrand,
      kcal: entry.kcal,
      protein: entry.protein,
      carbs: entry.carbs,
      fat: entry.fat,
      amount: freq.avgQuantity,
      unit: entry.unit,
      timesEaten: count,
      suggestedMealType: suggestedMeal,
      reason: reason,
    );
  }).toList();
});

/// Helper class para contar frecuencia y calcular estadísticas
/// 🎯 HIGH-003: Mejorado para detección de patrones habituales
class _FoodFrequency {
  final diet.DiaryEntryModel entry;
  final Set<DateTime> uniqueDays = {};
  DateTime lastUsed;
  double totalQuantity = 0;
  int entryCount = 0;

  _FoodFrequency({required this.entry}) : lastUsed = entry.date;

  void addEntry(diet.DiaryEntryModel e) {
    final day = DateTime(e.date.year, e.date.month, e.date.day);
    uniqueDays.add(day);
    totalQuantity += e.amount;
    entryCount++;
    if (e.date.isAfter(lastUsed)) {
      lastUsed = e.date;
    }
  }

  diet.DiaryEntryModel get mostRecentEntry => entry;

  double get avgQuantity => entryCount > 0 ? totalQuantity / entryCount : entry.amount;
}

/// Provider de mensaje contextual para el tipo de comida actual
final mealContextMessageProvider = Provider<String>((ref) {
  final mealType = ref.watch(currentMealTypeProvider);
  final hour = DateTime.now().hour;

  switch (mealType) {
    case diet.MealType.breakfast:
      if (hour < 8) return '¡Buenos días! ¿Qué desayunas?';
      return '¿Ya desayunaste?';
    case diet.MealType.lunch:
      if (hour < 13) return 'Se acerca la hora de comer';
      return '¿Qué hay para el almuerzo?';
    case diet.MealType.snack:
      if (hour >= 15 && hour < 18) return '¿Hora de merendar?';
      return '¿Un snack?';
    case diet.MealType.dinner:
      if (hour < 20) return '¿Planificando la cena?';
      return '¿Qué cenaste?';
  }
});

// ============================================================================
// TRAINING REPOSITORIES (sin cambios)
// ============================================================================

final trainingRepositoryProvider = Provider<ITrainingRepository>(
  (ref) => InMemoryTrainingRepository(),
);
final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => LocalExerciseRepository(),
);
final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => InMemoryRoutineRepository(),
);

// ============================================================================
// USER PROFILE REPOSITORY & PROVIDERS
// ============================================================================

final userProfileRepositoryProvider = Provider<IUserProfileRepository>((ref) {
  return DriftUserProfileRepository(ref.watch(appDatabaseProvider));
});

/// Provider del perfil de usuario actual
final userProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final repo = ref.watch(userProfileRepositoryProvider);
  return repo.get();
});

/// Provider para verificar si el perfil está completo
final isProfileCompleteProvider = Provider<AsyncValue<bool>>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.when(
    data: (profile) => AsyncValue.data(profile?.isComplete ?? false),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
