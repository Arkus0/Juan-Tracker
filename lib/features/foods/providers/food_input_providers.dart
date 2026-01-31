import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../training/database/database.dart';

/// Modos de entrada de alimentos
enum FoodInputMode {
  recent,    // Mostrar alimentos recientes
  search,    // Modo búsqueda activa
  favorites, // Mostrar favoritos
}

/// Provider del modo de entrada actual
final foodInputModeProvider = StateProvider<FoodInputMode>((ref) => FoodInputMode.recent);

/// Provider para la cantidad detectada por voz
final voiceInputAmountProvider = StateProvider<double?>((ref) => null);

/// Provider de alimentos recientes (usados por el usuario)
final recentFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  // TODO: Implementar método getRecentFoods en el repositorio o database
  // Por ahora retornamos lista vacía
  return [];
});

/// Provider de alimentos favoritos del usuario
final favoriteFoodsProvider = FutureProvider<List<Food>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  // TODO: Implementar favoritos en la base de datos
  return [];
});

/// Provider para guardar un alimento como reciente
final saveRecentFoodProvider = Provider<Future<void> Function(Food)>((ref) {
  return (Food food) async {
    final db = ref.read(appDatabaseProvider);
    // Actualizar timestamp de último uso
    await db.updateFoodUsage(food.id);
  };
});
