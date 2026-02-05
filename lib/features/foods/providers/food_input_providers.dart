import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../diet/repositories/alimento_repository.dart';
import '../../../../training/database/database.dart';

/// Modos de entrada de alimentos
enum FoodInputMode {
  recent, // Mostrar alimentos recientes
  search, // Modo búsqueda activa
  favorites, // Mostrar favoritos
}

/// Notifier simple para FoodInputMode
class FoodInputModeNotifier extends Notifier<FoodInputMode> {
  @override
  FoodInputMode build() => FoodInputMode.recent;
  void setMode(FoodInputMode mode) => state = mode;
}

/// Notifier simple para double? (cantidad por voz)
class VoiceInputAmountNotifier extends Notifier<double?> {
  @override
  double? build() => null;
  void setAmount(double? amount) => state = amount;
}

// ============================================================================
// BATCH SELECTION - Multi-add mode
// ============================================================================

/// Estado de selección batch para añadir múltiples alimentos
class BatchSelectionState {
  final bool isActive;
  final Set<String> selectedFoodIds;

  const BatchSelectionState({
    this.isActive = false,
    this.selectedFoodIds = const {},
  });

  BatchSelectionState copyWith({bool? isActive, Set<String>? selectedFoodIds}) {
    return BatchSelectionState(
      isActive: isActive ?? this.isActive,
      selectedFoodIds: selectedFoodIds ?? this.selectedFoodIds,
    );
  }

  int get count => selectedFoodIds.length;
  bool isSelected(String foodId) => selectedFoodIds.contains(foodId);
}

/// Notifier para gestionar la selección batch
class BatchSelectionNotifier extends Notifier<BatchSelectionState> {
  @override
  BatchSelectionState build() => const BatchSelectionState();

  /// Activa el modo batch sin selección inicial.
  void enableBatchMode() {
    state = const BatchSelectionState(isActive: true, selectedFoodIds: {});
  }

  /// Activa el modo batch con un primer alimento seleccionado
  void startBatch(String foodId) {
    state = BatchSelectionState(isActive: true, selectedFoodIds: {foodId});
  }

  /// Toggle selección de un alimento
  void toggleSelection(String foodId) {
    if (!state.isActive) {
      startBatch(foodId);
      return;
    }

    final newSet = Set<String>.from(state.selectedFoodIds);
    if (newSet.contains(foodId)) {
      newSet.remove(foodId);
      // Si no quedan seleccionados, salir de batch mode
      if (newSet.isEmpty) {
        state = const BatchSelectionState();
        return;
      }
    } else {
      newSet.add(foodId);
    }
    state = state.copyWith(selectedFoodIds: newSet);
  }

  /// Cancelar modo batch
  void cancelBatch() {
    state = const BatchSelectionState();
  }

  /// Obtener los IDs seleccionados y limpiar
  Set<String> consumeSelection() {
    final ids = state.selectedFoodIds;
    state = const BatchSelectionState();
    return ids;
  }
}

/// Provider de batch selection
final batchSelectionProvider =
    NotifierProvider<BatchSelectionNotifier, BatchSelectionState>(
      BatchSelectionNotifier.new,
    );

/// Provider del modo de entrada actual
final foodInputModeProvider =
    NotifierProvider<FoodInputModeNotifier, FoodInputMode>(
      FoodInputModeNotifier.new,
    );

/// Provider para la cantidad detectada por voz
final voiceInputAmountProvider =
    NotifierProvider<VoiceInputAmountNotifier, double?>(
      VoiceInputAmountNotifier.new,
    );

/// Provider de alimentos recientes (usados por el usuario)
final recentFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.getRecentlyUsed(limit: 20);
});

/// Provider de alimentos favoritos del usuario
final favoriteFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final repository = ref.read(alimentoRepositoryProvider);
  return repository.getFavorites(limit: 50);
});

/// Provider para alternar favorito
final toggleFavoriteProvider = Provider<Future<bool> Function(String)>((ref) {
  return (String foodId) async {
    final repository = ref.read(alimentoRepositoryProvider);
    return repository.toggleFavorite(foodId);
  };
});

/// Provider para guardar un alimento como reciente
final saveRecentFoodProvider = Provider<Future<void> Function(Food)>((ref) {
  return (Food food) async {
    final repository = ref.read(alimentoRepositoryProvider);
    await repository.recordSelection(food.id);
  };
});
