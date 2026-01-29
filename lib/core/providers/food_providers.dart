import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diet/models/models.dart';
import 'database_provider.dart';

// Provider de lista de alimentos (adaptador)
final foodListStreamProvider = StreamProvider<List<FoodModel>>((ref) {
  return ref.watch(foodRepositoryProvider).watchAll();
});

// Provider de busqueda de alimentos (adaptador)
final searchFoodsProvider = FutureProvider.family<List<FoodModel>, String>((ref, q) async {
  if (q.trim().isEmpty) return ref.watch(foodRepositoryProvider).getAll();
  return ref.watch(foodRepositoryProvider).search(q);
});
