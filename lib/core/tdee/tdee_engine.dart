import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/weight_repository.dart';
import '../repositories/diary_repository.dart';
import '../providers/database_provider.dart';

/// Baseline TDEE estimator provider.
final tdeeEstimateProvider = FutureProvider.family<double, DateTime>((ref, day) async {
  // Simple baseline: intake_day - (delta_weight_kg * 7700 / days)
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final weightRepo = ref.watch(weightRepositoryProvider);

  final totals = await diaryRepo.totalsForDay(day);
  final intake = totals.kcal.toDouble();

  final latest = await weightRepo.latest();
  if (latest == null) return intake; // fallback

  // naive: assume delta from previous day if exists
  // for baseline, return intake as estimate (placeholder)
  return intake;
});
