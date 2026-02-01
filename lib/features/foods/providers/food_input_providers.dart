import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../diet/repositories/alimento_repository.dart';
import '../../../../training/database/database.dart';

/// Modos de entrada de alimentos
enum FoodInputMode {
  recent,    // Mostrar alimentos recientes
  search,    // Modo búsqueda activa
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

/// Provider del modo de entrada actual
final foodInputModeProvider = NotifierProvider<FoodInputModeNotifier, FoodInputMode>(
  FoodInputModeNotifier.new,
);

/// Provider para la cantidad detectada por voz
final voiceInputAmountProvider = NotifierProvider<VoiceInputAmountNotifier, double?>(
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
