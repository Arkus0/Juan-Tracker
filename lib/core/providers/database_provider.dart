import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_db/seeds/seed_data.dart';
import '../repositories/food_repository.dart';
import '../repositories/diary_repository.dart';
import '../repositories/weight_repository.dart';

/// For now: provide in-memory repositories. Later replace with Drift-backed DB for native.
final foodRepositoryProvider = Provider<FoodRepository>((ref) => InMemoryFoodRepository(seedFoods));
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) => InMemoryDiaryRepository());
final weightRepositoryProvider = Provider<WeightRepository>((ref) => InMemoryWeightRepository());
