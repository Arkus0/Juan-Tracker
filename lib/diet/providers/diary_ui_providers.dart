/// Providers de UI para el Diario de Diet
/// Manejan el estado de la pantalla día y navegación
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/repositories/repositories.dart';
import 'diet_providers.dart';

// ============================================================================
// ESTADO DE FECHA SELECCIONADA
// ============================================================================

/// Notifier para la fecha seleccionada en el diario
class SelectedDateNotifier extends StateNotifier<DateTime> {
  SelectedDateNotifier() : super(DateTime.now());

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void goToToday() {
    state = DateTime.now();
  }

  void previousDay() {
    state = state.subtract(const Duration(days: 1));
  }

  void nextDay() {
    state = state.add(const Duration(days: 1));
  }
}

/// Provider de la fecha seleccionada
final selectedDateProvider = StateNotifierProvider<SelectedDateNotifier, DateTime>(
  (ref) => SelectedDateNotifier(),
);

// ============================================================================
// ENTRADAS Y TOTALES DEL DÍA
// ============================================================================

/// Stream de entradas del día seleccionado
final dayEntriesStreamProvider = StreamProvider.autoDispose<List<DiaryEntryModel>>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.watchByDate(date);
});

/// Future de entradas del día (para operaciones one-shot)
final dayEntriesFutureProvider = FutureProvider.autoDispose<List<DiaryEntryModel>>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.getByDate(date);
});

/// Totales diarios calculados
final dailyTotalsProvider = StreamProvider.autoDispose<DailyTotals>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  return repo.watchDailyTotals(date);
});

/// Entradas filtradas por tipo de comida
final entriesByMealProvider = Provider.autoDispose.family<List<DiaryEntryModel>, MealType>((ref, mealType) {
  final entriesAsync = ref.watch(dayEntriesStreamProvider);
  return entriesAsync.when(
    data: (entries) => entries.where((e) => e.mealType == mealType).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Totales por tipo de comida
final mealTotalsProvider = Provider.autoDispose.family<MealTotals, MealType>((ref, mealType) {
  final totalsAsync = ref.watch(dailyTotalsProvider);
  return totalsAsync.when(
    data: (totals) => totals.byMeal[mealType] ?? MealTotals.empty,
    loading: () => MealTotals.empty,
    error: (_, __) => MealTotals.empty,
  );
});

// ============================================================================
// BÚSQUEDA DE ALIMENTOS
// ============================================================================

/// Query de búsqueda actual
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

/// Resultados de búsqueda de alimentos
final foodSearchResultsProvider = FutureProvider.autoDispose<List<FoodModel>>((ref) async {
  final repo = ref.watch(foodRepositoryProvider);
  final query = ref.watch(foodSearchQueryProvider);
  
  if (query.trim().isEmpty) {
    return repo.getAll();
  }
  return repo.search(query);
});

/// Alimento seleccionado para añadir
final selectedFoodProvider = StateProvider<FoodModel?>((ref) => null);

// ============================================================================
// ESTADO DE EDICIÓN
// ============================================================================

/// Entrada actualmente en edición (null si se está creando nueva)
final editingEntryProvider = StateProvider<DiaryEntryModel?>((ref) => null);

/// Tipo de comida seleccionado para nueva entrada
final selectedMealTypeProvider = StateProvider<MealType>((ref) => MealType.snack);
