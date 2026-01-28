import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/diary_entry.dart';
import '../repositories/diary_repository.dart';
import 'database_provider.dart';

final selectedDayProvider = Provider<DateTime>((ref) => DateTime.now());

final dayEntriesProvider = StreamProvider.autoDispose<List<DiaryEntry>>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  final day = ref.watch(selectedDayProvider);
  return repo.watchDay(day);
});

final dayTotalsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(diaryRepositoryProvider);
  final day = ref.watch(selectedDayProvider);
  return repo.totalsForDay(day);
});
