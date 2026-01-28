import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_db/seeds/seed_data.dart';
import '../repositories/food_repository.dart';
import '../repositories/diary_repository.dart';
import '../repositories/weight_repository.dart';
import '../repositories/i_training_repository.dart';
import '../repositories/in_memory_training_repository.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/local_exercise_repository.dart';
import '../repositories/routine_repository.dart';
import '../repositories/in_memory_routine_repository.dart';

/// For now: provide in-memory repositories. Later replace with Drift-backed DB for native.
final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => InMemoryFoodRepository(seedFoods),
);
final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => InMemoryDiaryRepository(),
);
final weightRepositoryProvider = Provider<WeightRepository>(
  (ref) => InMemoryWeightRepository(),
);
final trainingRepositoryProvider = Provider<ITrainingRepository>(
  (ref) => InMemoryTrainingRepository(),
);
final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => LocalExerciseRepository(),
);
final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => InMemoryRoutineRepository(),
);
