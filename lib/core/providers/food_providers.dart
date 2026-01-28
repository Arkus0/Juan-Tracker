import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food.dart';
import 'database_provider.dart';

final foodListStreamProvider = StreamProvider<List<Food>>((ref) {
  final repo = ref.watch(foodRepositoryProvider);
  return repo.watchAll();
});

final searchFoodsProvider = FutureProvider.family<List<Food>, String>((ref, q) {
  final repo = ref.watch(foodRepositoryProvider);
  if (q.trim().isEmpty) return repo.getAll();
  return repo.searchByNameOrBrand(q);
});
