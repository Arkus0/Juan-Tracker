import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  // TODO: Implementar método getRecentFoods en el repositorio o database
  // Por ahora retornamos lista vacía
  return [];
});

/// Provider de alimentos favoritos del usuario
final favoriteFoodsProvider = FutureProvider<List<Food>>((ref) async {
  // TODO: Implementar favoritos en la base de datos
  return [];
});

/// Provider para guardar un alimento como reciente
final saveRecentFoodProvider = Provider<Future<void> Function(Food)>((ref) {
  return (Food food) async {
    // TODO: Actualizar timestamp de último uso
    // await db.updateFoodUsage(food.id);
  };
});
