/// Providers para el sistema de tracking de pasos.
///
/// Integra pasos diarios con el cálculo de TDEE y nivel de actividad.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/tdee_calculator.dart';
import '../../core/models/user_profile_model.dart';
import '../models/step_entry_model.dart';
import '../repositories/step_repository.dart';

// ============================================================================
// REPOSITORIO
// ============================================================================

final stepRepositoryProvider = Provider<StepRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StepRepository(prefs);
});

// ============================================================================
// ESTADO
// ============================================================================

/// Notifier global para gestionar pasos. Almacena un mapa de dateKey → steps.
///
/// Los providers derivados usan este estado para leer pasos por fecha.
final stepDataProvider =
    NotifierProvider<StepDataNotifier, Map<String, int>>(
  StepDataNotifier.new,
);

class StepDataNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    final repo = ref.watch(stepRepositoryProvider);
    final all = repo.getAll();
    return all.map((k, v) => MapEntry(k, v.steps));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Establece los pasos del día.
  Future<void> setSteps(DateTime date, int steps) async {
    final repo = ref.read(stepRepositoryProvider);
    await repo.save(date, steps);
    state = {...state, _dateKey(date): steps};
  }

  /// Suma pasos al conteo actual del día.
  Future<void> addSteps(DateTime date, int additionalSteps) async {
    final key = _dateKey(date);
    final current = state[key] ?? 0;
    final newSteps = current + additionalSteps;
    final repo = ref.read(stepRepositoryProvider);
    await repo.save(date, newSteps);
    state = {...state, key: newSteps};
  }
}

/// Provider de pasos para una fecha específica.
final dailyStepsProvider = Provider.family<int, DateTime>((ref, date) {
  final data = ref.watch(stepDataProvider);
  final key =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  return data[key] ?? 0;
});

// ============================================================================
// PROVIDERS DERIVADOS
// ============================================================================

/// Promedio de pasos de los últimos 7 días.
final weeklyStepAvgProvider = Provider<int>((ref) {
  final repo = ref.watch(stepRepositoryProvider);
  return repo.averageSteps(days: 7);
});

/// Nivel de actividad inferido de los pasos de los últimos 7 días.
final stepBasedActivityProvider = Provider<StepActivityLevel>((ref) {
  final avg = ref.watch(weeklyStepAvgProvider);
  return StepActivityLevel.fromSteps(avg);
});

/// Historial de pasos de los últimos 7 días (para mini gráfico).
final weeklyStepHistoryProvider = Provider<List<StepEntry>>((ref) {
  final repo = ref.watch(stepRepositoryProvider);
  return repo.getLastDays(7);
});

/// TDEE ajustado por pasos.
///
/// Si hay datos de pasos suficientes (≥3 días en última semana),
/// usa el multiplier derivado de pasos en vez del nivel de actividad
/// estático del perfil.
final stepAdjustedTdeeProvider = Provider<double?>((ref) {
  final repo = ref.watch(stepRepositoryProvider);
  final entries = repo.getLastDays(7);

  // Necesitamos al menos 3 días de datos para ser confiable
  if (entries.length < 3) return null;

  // Obtener perfil del usuario
  final profileAsync = ref.watch(userProfileProvider);
  UserProfileModel? profile;
  profileAsync.whenData((p) => profile = p);
  if (profile == null || !profile!.isComplete) return null;

  // Calcular BMR
  final bmr = TdeeCalculator.calculateBMR(
    weightKg: profile!.currentWeightKg!,
    heightCm: profile!.heightCm!,
    age: profile!.age!,
    gender: profile!.gender!,
  );

  // Usar multiplier basado en pasos
  final stepActivity = ref.watch(stepBasedActivityProvider);
  return bmr * stepActivity.tdeeMultiplier;
});

/// Kcal estimadas quemadas por pasos hoy.
final todayStepKcalProvider = Provider.family<double, DateTime>((ref, date) {
  final steps = ref.watch(dailyStepsProvider(date));
  final profileAsync = ref.watch(userProfileProvider);
  double weight = 70;
  profileAsync.whenData((p) {
    if (p?.currentWeightKg != null) weight = p!.currentWeightKg!;
  });
  return StepEntry(dateKey: '', steps: steps).estimateKcal(weightKg: weight);
});
