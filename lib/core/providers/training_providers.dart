import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/training_sesion.dart';
import 'database_provider.dart';

final trainingSessionsProvider = StreamProvider.autoDispose<List<Sesion>>((
  ref,
) {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.watchSessions();
});
