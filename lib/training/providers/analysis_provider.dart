import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis_models.dart';
import '../models/sesion.dart';
import '../widgets/analysis/muscle_imbalance_dashboard.dart';
import 'training_provider.dart';

// =============================================================================
// TAB & VIEW STATE
// =============================================================================

/// Current tab index (0 = BITÁCORA, 1 = LABORATORIO)
final analysisTabIndexProvider =
    NotifierProvider<AnalysisTabIndexNotifier, int>(
      AnalysisTabIndexNotifier.new,
    );

/// View mode for BITÁCORA tab
enum BitacoraViewMode { calendar, list }

final bitacoraViewModeProvider =
    NotifierProvider<BitacoraViewModeNotifier, BitacoraViewMode>(
      BitacoraViewModeNotifier.new,
    );

/// Selected year for heatmap
final selectedYearProvider = NotifierProvider<SelectedYearNotifier, int>(
  SelectedYearNotifier.new,
);

/// Selected date for calendar detail view
final selectedCalendarDateProvider =
    NotifierProvider<SelectedCalendarDateNotifier, DateTime?>(
      SelectedCalendarDateNotifier.new,
    );

/// Selected exercise for strength trend
final selectedTrendExerciseProvider =
    NotifierProvider<SelectedTrendExerciseNotifier, String?>(
      SelectedTrendExerciseNotifier.new,
    );

class AnalysisTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

class BitacoraViewModeNotifier extends Notifier<BitacoraViewMode> {
  @override
  BitacoraViewMode build() => BitacoraViewMode.calendar;

  void setMode(BitacoraViewMode mode) {
    state = mode;
  }
}

class SelectedYearNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;

  void setYear(int year) {
    state = year;
  }
}

class SelectedCalendarDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void setDate(DateTime? date) {
    state = date;
  }
}

class SelectedTrendExerciseNotifier extends Notifier<String?> {
  @override
  String? build() => 'Press de Banca';

  void setExercise(String? exercise) {
    state = exercise;
  }
}

// =============================================================================
// DATA PROVIDERS
// =============================================================================

/// Yearly activity data for heatmap - cached per year
final yearlyActivityProvider =
    FutureProvider.family<Map<DateTime, DailyActivity>, int>((ref, year) async {
      // Recompute when history changes so calendar stays in sync
      ref.watch(sesionesHistoryStreamProvider);
      final repo = ref.watch(trainingRepositoryProvider);
      return repo.getYearlyActivityMap(year);
    });

/// Current streak data
final streakDataProvider = FutureProvider<StreakData>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getStreakData();
});

/// Muscle recovery data - sorted by days since training
final muscleRecoveryProvider = FutureProvider<List<MuscleRecovery>>((
  ref,
) async {
  final repo = ref.watch(trainingRepositoryProvider);
  final lastTrained = await repo.getLastTrainedDateByMuscle();

  // Create recovery entries for all main muscle groups
  final recoveries = <MuscleRecovery>[];

  for (final group in kMuscleGroups) {
    final date = lastTrained[group];
    recoveries.add(
      MuscleRecovery.fromLastTrained(
        muscleName: group,
        displayName: group,
        lastTrained: date,
      ),
    );
  }

  // Sort by days since training (ascending - needs attention first)
  recoveries.sort((a, b) => a.daysSinceTraining.compareTo(b.daysSinceTraining));

  return recoveries;
});

/// Muscle volume for symmetry radar (last 30 days)
final muscleVolumeProvider = FutureProvider<Map<String, MuscleVolume>>((
  ref,
) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getMuscleVolumePeriod();
});

/// Muscle volume for last 7 days
final muscleVolumeWeekProvider =
    FutureProvider<Map<String, MuscleVolume>>((ref) async {
      final repo = ref.watch(trainingRepositoryProvider);
      return repo.getMuscleVolumePeriod(days: 7);
    });

/// Symmetry data with imbalance detection
final symmetryDataProvider = FutureProvider<SymmetryData>((ref) async {
  final volumes = await ref.watch(muscleVolumeProvider.future);

  if (volumes.isEmpty) {
    return const SymmetryData(
      volumes: {},
      maxVolume: 0,
      hasImbalance: false,
      imbalanceWarnings: [],
    );
  }

  // Calculate max volume for normalization
  double maxVolume = 0;
  for (final v in volumes.values) {
    if (v.totalVolume > maxVolume) maxVolume = v.totalVolume;
  }

  // Detect imbalances (if one muscle is <50% of max)
  final warnings = <String>[];
  if (maxVolume > 0) {
    for (final entry in volumes.entries) {
      final ratio = entry.value.totalVolume / maxVolume;
      if (ratio < 0.5 && entry.value.totalVolume > 0) {
        warnings.add('${entry.key} necesita más atención');
      }
    }
  }

  return SymmetryData(
    volumes: volumes,
    maxVolume: maxVolume,
    hasImbalance: warnings.isNotEmpty,
    imbalanceWarnings: warnings,
  );
});

/// Personal records for Hall of Fame
final personalRecordsProvider = FutureProvider<List<PersonalRecord>>((
  ref,
) async {
  final repo = ref.watch(trainingRepositoryProvider);
  // Get PRs for big lifts only
  return repo.getPersonalRecords(
    exerciseNames: [
      'Press de Banca',
      'Sentadilla',
      'Peso Muerto',
      'Press Militar',
      'Dominadas',
      'Remo con Barra',
    ],
  );
});

/// All personal records (not limited to big lifts)
final allPersonalRecordsProvider = FutureProvider<List<PersonalRecord>>((
  ref,
) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getPersonalRecords();
});

/// Personal record para un ejercicio específico
final personalRecordForExerciseProvider =
    FutureProvider.family<PersonalRecord?, String>((ref, exerciseName) async {
      if (exerciseName.trim().isEmpty) return null;
      final repo = ref.watch(trainingRepositoryProvider);
      final records = await repo.getPersonalRecords(
        exerciseNames: [exerciseName],
      );
      if (records.isEmpty) return null;
      return records.first;
    });

/// Strength trend for selected exercise
final strengthTrendProvider = FutureProvider<List<StrengthDataPoint>>((
  ref,
) async {
  final exerciseName = ref.watch(selectedTrendExerciseProvider);
  if (exerciseName == null || exerciseName.isEmpty) return [];

  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getStrengthTrend(exerciseName);
});

/// Daily snapshot for selected date
final dailySnapshotProvider = FutureProvider<DailySnapshot?>((ref) async {
  final date = ref.watch(selectedCalendarDateProvider);
  if (date == null) return null;

  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getDailySnapshot(date);
});

/// Sessions for selected date
final sessionsForDateProvider = FutureProvider<List<Sesion>>((ref) async {
  final date = ref.watch(selectedCalendarDateProvider);
  if (date == null) return [];

  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getSessionsForDate(date);
});

/// Available exercise names for dropdown
final exerciseNamesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.getExerciseNames();
});

/// Training dates set for calendar markers
final trainingDatesProvider = FutureProvider<Set<DateTime>>((ref) async {
  final year = ref.watch(selectedYearProvider);
  final activity = await ref.watch(yearlyActivityProvider(year).future);
  return activity.keys.toSet();
});

// =============================================================================
// COMPUTED VALUES
// =============================================================================

/// Check if user has any training data
final hasTrainingDataProvider = FutureProvider<bool>((ref) async {
  final streak = await ref.watch(streakDataProvider.future);
  return streak.lastTrainingDate != null;
});

/// Today's training status
final trainedTodayProvider = FutureProvider<bool>((ref) async {
  final streak = await ref.watch(streakDataProvider.future);
  return streak.trainedToday;
});

// =============================================================================
// HELPER CLASSES
// =============================================================================

/// Symmetry analysis result
class SymmetryData {
  final Map<String, MuscleVolume> volumes;
  final double maxVolume;
  final bool hasImbalance;
  final List<String> imbalanceWarnings;

  const SymmetryData({
    required this.volumes,
    required this.maxVolume,
    required this.hasImbalance,
    required this.imbalanceWarnings,
  });

  /// Get normalized value (0-1) for a muscle group
  double getNormalized(String muscle) {
    final volume = volumes[muscle];
    if (volume == null || maxVolume <= 0) return 0;
    return (volume.totalVolume / maxVolume).clamp(0.0, 1.0);
  }
}

// =============================================================================
// MUSCLE IMBALANCE DASHBOARD PROVIDER
// =============================================================================

/// Provider para datos de desbalance muscular (empuje/jalón, quad/ham)
final muscleImbalanceProvider = FutureProvider<MuscleImbalanceData>((ref) async {
  final volumes = await ref.watch(muscleVolumeProvider.future);

  if (volumes.isEmpty) {
    return const MuscleImbalanceData();
  }

  // Calcular volúmenes agregados
  double pushVolume = 0;
  double pullVolume = 0;
  double quadVolume = 0;
  double hamstringVolume = 0;

  // Agrupar por categorías
  for (final entry in volumes.entries) {
    final muscle = entry.key.toLowerCase();
    final volume = entry.value.totalVolume;

    // Empuje (push)
    if (muscle.contains('pecho') || 
        muscle.contains('hombro') || 
        muscle.contains('triceps') ||
        muscle.contains('frontal')) {
      pushVolume += volume;
    }

    // Jalón (pull)
    if (muscle.contains('espalda') || 
        muscle.contains('dorsal') || 
        muscle.contains('biceps') ||
        muscle.contains('trapecio')) {
      pullVolume += volume;
    }

    // Cuádriceps
    if (muscle.contains('cuadriceps') || 
        muscle.contains('frontal') ||
        muscle.contains('muslo')) {
      quadVolume += volume;
    }

    // Femoral
    if (muscle.contains('femoral') || 
        muscle.contains('isquio') || 
        muscle.contains('posterior')) {
      hamstringVolume += volume;
    }
  }

  // Calcular ratios
  double? pushPullRatio;
  double? quadHamstringRatio;
  final warnings = <MuscleImbalanceWarning>[];

  // Ratio empuje/jalón (ideal 1:1, aceptable 0.8-1.3)
  if (pushVolume > 0 && pullVolume > 0) {
    pushPullRatio = pushVolume / pullVolume;
    
    if (pushPullRatio > 1.3) {
      warnings.add(MuscleImbalanceWarning(
        type: 'push_pull',
        message: 'Demasiado empuje (${(pushPullRatio - 1).abs().toStringAsFixed(0)}% más). Añade más dominadas y remos.',
        severity: (pushPullRatio - 1.3).clamp(0.0, 1.0),
      ));
    } else if (pushPullRatio < 0.8) {
      warnings.add(MuscleImbalanceWarning(
        type: 'push_pull',
        message: 'Demasiado jalón (${(pushPullRatio - 1).abs().toStringAsFixed(0)}% más). Equilibra con press y fondos.',
        severity: (0.8 - pushPullRatio).clamp(0.0, 1.0),
      ));
    }
  }

  // Ratio cuádriceps/femoral (ideal 1.5:1, alerta si > 2.5 o < 1.0)
  if (quadVolume > 0 && hamstringVolume > 0) {
    quadHamstringRatio = quadVolume / hamstringVolume;
    
    if (quadHamstringRatio > 2.5) {
      warnings.add(MuscleImbalanceWarning(
        type: 'quad_hamstring',
        message: 'Desbalance pierna severo (${quadHamstringRatio.toStringAsFixed(1)}:1). Prioriza peso muerto y curl femoral.',
        severity: ((quadHamstringRatio - 2.5) / 2).clamp(0.0, 1.0),
      ));
    } else if (quadHamstringRatio < 1.0) {
      warnings.add(MuscleImbalanceWarning(
        type: 'quad_hamstring',
        message: 'Femorales dominantes. Añade sentadillas o prensa.',
        severity: (1.0 - quadHamstringRatio).clamp(0.0, 1.0),
      ));
    }
  } else if (quadVolume > 0 && hamstringVolume == 0) {
    warnings.add(MuscleImbalanceWarning(
      type: 'quad_hamstring',
      message: 'Sin trabajo de femoral detectado. Incluye curl femoral o peso muerto.',
      severity: 0.8,
    ));
  }

  return MuscleImbalanceData(
    pushPullRatio: pushPullRatio,
    quadHamstringRatio: quadHamstringRatio,
    pushVolume: pushVolume,
    pullVolume: pullVolume,
    quadVolume: quadVolume,
    hamstringVolume: hamstringVolume,
    warnings: warnings,
  );
});
