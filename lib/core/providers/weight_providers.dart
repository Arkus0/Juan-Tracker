import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../diet/models/models.dart';
import 'database_provider.dart';

// Provider de lista de pesos (adaptador)
final weightListStreamProvider = StreamProvider<List<WeighInModel>>((ref) {
  final from = DateTime.now().subtract(const Duration(days: 90));
  return ref.watch(weighInRepositoryProvider).watchByDateRange(from, DateTime.now());
});

// Provider del ultimo peso (re-export)
// latestWeightProvider ya está definido en database_provider.dart
