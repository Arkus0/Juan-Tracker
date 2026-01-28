import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/weight_repository.dart';
import '../models/weight_entry.dart';
import 'database_provider.dart';

final weightListStreamProvider = StreamProvider<List<WeightEntry>>((ref) {
  final repo = ref.watch(weightRepositoryProvider);
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 30));
  final to = now.add(const Duration(days: 1));
  return repo.watchRange(from, to);
});

final latestWeightProvider = FutureProvider<WeightEntry?>((ref) {
  final repo = ref.watch(weightRepositoryProvider);
  return repo.latest();
});
