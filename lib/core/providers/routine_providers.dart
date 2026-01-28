import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/training_rutina.dart';
import 'database_provider.dart';

final routinesProvider = StreamProvider<List<Rutina>>((ref) {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.watchAll();
});

class RoutineNameFilter extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;

  void clear() => state = '';
}

final routineNameFilterProvider = NotifierProvider<RoutineNameFilter, String>(
  RoutineNameFilter.new,
);

final filteredRoutinesProvider = Provider<List<Rutina>>((ref) {
  final query = ref.watch(routineNameFilterProvider).trim().toLowerCase();
  final async = ref.watch(routinesProvider);
  return async.maybeWhen(
    data: (items) {
      if (query.isEmpty) return items;
      return items
          .where((r) => r.nombre.toLowerCase().contains(query))
          .toList();
    },
    orElse: () => [],
  );
});
