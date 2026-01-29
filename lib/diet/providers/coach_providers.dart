/// Providers del Coach Adaptativo
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../services/adaptive_coach_service.dart';
import '../repositories/coach_repository.dart';
// import '../models/weighin_model.dart';

// ============================================================================
// REPOSITORIO
// ============================================================================

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  throw UnimplementedError('Debe ser sobreescrito con el valor real');
});

// ============================================================================
// ESTADO DEL PLAN
// ============================================================================

/// Provider del plan actual del Coach
final coachPlanProvider = NotifierProvider<CoachPlanNotifier, CoachPlan?>(
  CoachPlanNotifier.new,
);

class CoachPlanNotifier extends Notifier<CoachPlan?> {
  @override
  CoachPlan? build() {
    final repository = ref.watch(coachRepositoryProvider);
    return repository.loadPlan();
  }

  /// Crea un nuevo plan de Coach
  Future<void> createPlan({
    required WeightGoal goal,
    double? weeklyRatePercent, // Legacy, preferir weeklyRateKg
    double? weeklyRateKg,
    required int initialTdeeEstimate,
    required double startingWeight,
    String? notes,
    MacroPreset macroPreset = MacroPreset.balanced,
  }) async {
    final repository = ref.read(coachRepositoryProvider);
    
    // Usar weeklyRateKg si se proporciona, si no calcular de weeklyRatePercent (legacy)
    final rateKg = weeklyRateKg ?? (weeklyRatePercent != null 
        ? startingWeight * weeklyRatePercent 
        : (goal == WeightGoal.maintain ? 0.0 : 0.5));
    
    final plan = CoachPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      goal: goal,
      weeklyRateKg: rateKg,
      initialTdeeEstimate: initialTdeeEstimate,
      startingWeight: startingWeight,
      startDate: DateTime.now(),
      currentKcalTarget: initialTdeeEstimate,
      notes: notes,
      macroPreset: macroPreset,
    );

    await repository.savePlan(plan);
    state = plan;
  }

  /// Actualiza el plan con un nuevo check-in aplicado
  Future<void> applyCheckIn(CheckInResult checkIn) async {
    if (state == null) return;
    final repository = ref.read(coachRepositoryProvider);

    final updatedPlan = state!.copyWith(
      lastCheckInDate: DateTime.now(),
      currentTargetId: checkIn.proposedTargets.id,
      currentKcalTarget: checkIn.proposedTargets.kcalTarget,
    );

    await repository.savePlan(updatedPlan);
    await repository.saveCheckIn(checkIn, DateTime.now());
    state = updatedPlan;
  }

  /// Elimina el plan actual
  Future<void> deletePlan() async {
    final repository = ref.read(coachRepositoryProvider);
    await repository.clearPlan();
    state = null;
  }

  /// Actualiza el target actual (cuando se aplica manualmente)
  Future<void> updateCurrentTarget(String targetId, int kcalTarget) async {
    if (state == null) return;
    final repository = ref.read(coachRepositoryProvider);

    final updatedPlan = state!.copyWith(
      currentTargetId: targetId,
      currentKcalTarget: kcalTarget,
    );

    await repository.savePlan(updatedPlan);
    state = updatedPlan;
  }
}

// ============================================================================
// CHECK-IN SEMANAL
// ============================================================================

/// Provider para calcular el check-in semanal
final weeklyCheckInProvider = FutureProvider.autoDispose<CheckInResult?>((ref) async {
  final plan = ref.watch(coachPlanProvider);
  if (plan == null) return null;

  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final weighInRepo = ref.watch(weighInRepositoryProvider);
  final service = ref.watch(adaptiveCoachServiceProvider);

  // Calcular rango de la última semana
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  // Obtener datos del diario (últimos 7 días)
  final dailyKcalList = <int>[];
  for (int i = 0; i < 7; i++) {
    final date = now.subtract(Duration(days: i));
    final entries = await diaryRepo.getByDate(date);
    final totalKcal = entries.fold<int>(0, (sum, e) => sum + e.kcal);
    dailyKcalList.add(totalKcal);
  }
  dailyKcalList.reverse(); // Ordenar cronológicamente

  // Obtener pesajes (últimos 30 días para trend)
  final weighIns = await weighInRepo.getByDateRange(
    weekAgo.subtract(const Duration(days: 21)),
    now,
  );

  // Obtener peso actual
  final latestWeighIn = await weighInRepo.getLatest();
  if (latestWeighIn == null) {
    return CheckInResult.insufficientData(
      WeeklyData(
        startDate: weekAgo,
        endDate: now,
        avgDailyKcal: 0,
        trendWeightStart: 0,
        trendWeightEnd: 0,
        daysWithDiaryEntries: 0,
        daysWithWeighIns: 0,
      ),
      reason: 'No hay pesajes registrados',
    );
  }

  // Calcular weekly data
  final weeklyData = service.calculateWeeklyData(
    startDate: weekAgo,
    endDate: now,
    dailyKcalList: dailyKcalList,
    weighIns: weighIns,
  );

  // Calcular check-in
  return service.calculateCheckIn(
    plan: plan,
    weeklyData: weeklyData,
    currentWeight: latestWeighIn.weightKg,
    checkInDate: now,
  );
});

// ============================================================================
// SERVICIO
// ============================================================================

final adaptiveCoachServiceProvider = Provider<AdaptiveCoachService>((ref) {
  return const AdaptiveCoachService();
});

// ============================================================================
// HISTORIAL DE CHECK-INS
// ============================================================================

final checkInHistoryProvider = Provider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(coachRepositoryProvider);
  return repository.loadCheckInHistory();
});

// ============================================================================
// UTILIDADES
// ============================================================================

extension ListReverse<T> on List<T> {
  void reverse() {
    if (length < 2) return;
    for (int i = 0; i < length ~/ 2; i++) {
      final temp = this[i];
      this[i] = this[length - 1 - i];
      this[length - 1 - i] = temp;
    }
  }
}
