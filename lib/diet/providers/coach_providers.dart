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

  /// Activa/desactiva el modo de auto-aplicar check-in
  Future<void> toggleAutoApply(bool enabled) async {
    if (state == null) return;
    final repository = ref.read(coachRepositoryProvider);

    final updatedPlan = state!.copyWith(autoApplyCheckIn: enabled);
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
// CHECK-IN REMINDER
// ============================================================================

/// Provider que indica si es momento de hacer el check-in semanal
/// Devuelve true si han pasado 7+ días desde el último check-in
final isCheckInDueProvider = Provider<bool>((ref) {
  final plan = ref.watch(coachPlanProvider);
  if (plan == null) return false;
  
  final lastCheckIn = plan.lastCheckInDate;
  if (lastCheckIn == null) {
    // Si nunca se hizo check-in y han pasado 7+ días desde el inicio del plan
    final daysSinceStart = DateTime.now().difference(plan.startDate).inDays;
    return daysSinceStart >= 7;
  }
  
  final daysSinceCheckIn = DateTime.now().difference(lastCheckIn).inDays;
  return daysSinceCheckIn >= 7;
});

// ============================================================================
// SERVICIO
// ============================================================================

final adaptiveCoachServiceProvider = Provider<AdaptiveCoachService>((ref) {
  return const AdaptiveCoachService();
});

// ============================================================================
// AUTO-APPLY CHECK-IN
// ============================================================================

/// Resultado de un auto-apply ejecutado
class AutoApplyResult {
  final int previousKcal;
  final int newKcal;
  final String summary;

  const AutoApplyResult({
    required this.previousKcal,
    required this.newKcal,
    required this.summary,
  });
}

/// Provider que ejecuta auto-apply si:
/// 1. El plan tiene autoApplyCheckIn = true
/// 2. El check-in está pendiente (7+ días)
/// 3. Hay datos suficientes para calcular
///
/// Devuelve el resultado para mostrar snackbar. null = no se aplicó.
final autoApplyCheckInProvider =
    FutureProvider.autoDispose<AutoApplyResult?>((ref) async {
  final plan = ref.watch(coachPlanProvider);
  if (plan == null || !plan.autoApplyCheckIn) return null;

  final isCheckInDue = ref.watch(isCheckInDueProvider);
  if (!isCheckInDue) return null;

  // Calcular check-in
  final checkIn = await ref.watch(weeklyCheckInProvider.future);
  if (checkIn == null || checkIn.status != CheckInStatus.ready) return null;

  // Guardar target anterior para mostrar en snackbar
  final previousKcal = plan.currentKcalTarget ?? plan.initialTdeeEstimate;

  // Aplicar automáticamente
  final targetsRepo = ref.read(targetsRepositoryProvider);
  await targetsRepo.insert(checkIn.proposedTargets);
  await ref.read(coachPlanProvider.notifier).applyCheckIn(checkIn);

  return AutoApplyResult(
    previousKcal: previousKcal,
    newKcal: checkIn.proposedTargets.kcalTarget,
    summary: checkIn.explanation.line5,
  );
});

// ============================================================================
// HISTORIAL DE CHECK-INS
// ============================================================================

final checkInHistoryProvider = Provider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(coachRepositoryProvider);
  return repository.loadCheckInHistory();
});

// ============================================================================
// PLAN EN EDICIÓN (para pasar entre pantallas)
// ============================================================================

/// Notifier para almacenar temporalmente el plan en edición
/// Se usa al navegar a PlanSetupScreen para editar un plan existente
class EditingPlanNotifier extends Notifier<CoachPlan?> {
  @override
  CoachPlan? build() => null;

  void setPlan(CoachPlan? plan) => state = plan;
  void clear() => state = null;
}

/// Provider para el plan en edición
final editingPlanProvider = NotifierProvider<EditingPlanNotifier, CoachPlan?>(
  EditingPlanNotifier.new,
);

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
