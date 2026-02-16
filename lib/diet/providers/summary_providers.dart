import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../diet/providers/coach_providers.dart';
import '../models/models.dart';
import '../providers/macro_cycle_providers.dart';
import '../services/day_summary_calculator.dart';

/// {@template summary_providers}
/// Providers Riverpod segmentados para el resumen diario y objetivos.
///
/// Estos providers están diseñados para:
/// - Evitar duplicación de lógica
/// - Facilitar testing
/// - Cachear resultados automáticamente
/// {@endtemplate}

// ============================================================================
// CALCULATOR (singleton puro)
// ============================================================================

/// Provider del calculador de resúmenes (singleton, sin estado).
final daySummaryCalculatorProvider = Provider<DaySummaryCalculator>(
  (_) => const DaySummaryCalculator(),
);

// ============================================================================
// TARGETS (DEPRECATED - usar CoachPlan)
// ============================================================================

/// @deprecated Usar [activeTargetsProvider] que obtiene datos del CoachPlan.
/// Este provider existe solo por compatibilidad con código legacy.
///
/// Provider de todos los objetivos (ordenados por fecha descendente).
/// Se auto-refresca cuando cambia la base de datos.
@Deprecated(
  'Usar activeTargetsProvider - el sistema manual de Targets está deprecado',
)
final allTargetsProvider = StreamProvider<List<TargetsModel>>((ref) {
  return ref.watch(targetsRepositoryProvider).watchAll();
});

/// @deprecated Usar [activeTargetsProvider] que obtiene datos del CoachPlan.
/// Este provider existe solo por compatibilidad con código legacy.
///
/// Provider de objetivos activos para una fecha específica.
@Deprecated(
  'Usar activeTargetsProvider - el sistema manual de Targets está deprecado',
)
final dayTargetsProvider = FutureProvider<TargetsModel?>((ref) async {
  final date = ref.watch(selectedDateProvider);
  // ignore: deprecated_member_use_from_same_package
  final targets = await ref.watch(allTargetsProvider.future);
  final calculator = ref.watch(daySummaryCalculatorProvider);

  return calculator.findActiveTargetForDate(targets, date);
});

/// Provider que obtiene targets SOLO desde CoachPlan.
///
/// El sistema de Targets manuales está deprecado - el Coach es la única
/// fuente de objetivos calóricos y de macros.
///
/// Convierte CoachPlan a TargetsModel para mantener compatibilidad con UI existente.
final activeTargetsProvider = FutureProvider<TargetsModel?>((ref) async {
  // Usar watch para que se re-ejecute cuando cambie el plan
  final coachPlan = ref.watch(coachPlanProvider);
  if (coachPlan == null) {
    return null;
  }

  // Convertir CoachPlan a TargetsModel
  final calculator = ref.watch(daySummaryCalculatorProvider);
  final tdee = calculator.calculateTDEEFromCoachPlan(coachPlan);

  return TargetsModel.fromCoachPlan(
    coachPlan: coachPlan,
    calculatedCalories: tdee.round(),
  );
});

/// @deprecated Usar [activeTargetsProvider] que obtiene datos del CoachPlan.
/// Este provider existe solo por compatibilidad con código legacy.
///
/// Provider de objetivos actuales (para hoy).
@Deprecated(
  'Usar activeTargetsProvider - el sistema manual de Targets está deprecado',
)
final currentTargetsProvider = FutureProvider<TargetsModel?>((ref) async {
  final repo = ref.watch(targetsRepositoryProvider);
  return repo.getCurrent();
});

// ============================================================================
// DAY SUMMARY
// ============================================================================

/// Provider de targets con ciclado de macros aplicado para una fecha.
///
/// Si el ciclado está activo, ajusta kcal/protein/carbs/fat según el tipo de día.
/// Si no, devuelve los targets base del CoachPlan.
final cycleAwareTargetsForDateProvider =
    Provider.family<AsyncValue<TargetsModel?>, DateTime>((ref, date) {
      final baseTargetsAsync = ref.watch(activeTargetsProvider);
      final cycleConfig = ref.watch(macroCycleConfigProvider);

      if (baseTargetsAsync.isLoading) return const AsyncValue.loading();
      if (baseTargetsAsync.hasError) {
        return AsyncValue.error(
          baseTargetsAsync.error!, baseTargetsAsync.stackTrace!);
      }

      final baseTargets = baseTargetsAsync.value;
      if (baseTargets == null) return const AsyncValue.data(null);

      // Si no hay ciclado activo, devolver targets base
      if (cycleConfig == null || !cycleConfig.enabled) {
        return AsyncValue.data(baseTargets);
      }

      // Aplicar macros del día específico
      final dayMacros = cycleConfig.getMacrosForDate(date);
      final adjusted = baseTargets.copyWith(
        kcalTarget: dayMacros.kcal,
        proteinTarget: dayMacros.protein,
        carbsTarget: dayMacros.carbs,
        fatTarget: dayMacros.fat,
      );

      return AsyncValue.data(adjusted);
    });

/// Provider del resumen completo del día (consumo + targets + progreso).
///
/// Este es el provider principal para la UI de "budget".
/// Combina:
/// - Totales consumidos del día
/// - Target activo para la fecha (con ciclado de macros si está activo)
/// - Progreso calculado
final daySummaryForDateProvider =
    Provider.family<AsyncValue<DaySummary>, DateTime>((ref, date) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final totalsAsync = ref.watch(dailyTotalsForDateProvider(normalizedDate));
      final targetsAsync = ref.watch(
        cycleAwareTargetsForDateProvider(normalizedDate));
      final calculator = ref.watch(daySummaryCalculatorProvider);

      // Combinar ambos streams
      if (totalsAsync.isLoading || targetsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      if (totalsAsync.hasError) {
        return AsyncValue.error(totalsAsync.error!, totalsAsync.stackTrace!);
      }

      if (targetsAsync.hasError) {
        return AsyncValue.error(targetsAsync.error!, targetsAsync.stackTrace!);
      }

      final totals = totalsAsync.value!;
      final targets = targetsAsync.value;

      final summary = calculator.calculate(
        date: normalizedDate,
        consumed: totals,
        targets: targets,
      );

      return AsyncValue.data(summary);
    });

/// Provider del resumen completo del día seleccionado por UI.
final daySummaryProvider = Provider<AsyncValue<DaySummary>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  return ref.watch(daySummaryForDateProvider(selectedDate));
});

/// Provider del resumen del día como Future (para widgets que necesitan Future).
///
/// Combina el totales del día con el cálculo de targets desde CoachPlan.
final daySummaryFutureProvider = FutureProvider<DaySummary>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final totals = await ref.watch(dailyTotalsProvider.future);
  final targets = await ref.watch(
    activeTargetsProvider.future,
  ); // Usa CoachPlan
  final calculator = ref.watch(daySummaryCalculatorProvider);

  return calculator.calculate(date: date, consumed: totals, targets: targets);
});

// ============================================================================
// WEEKLY TRENDS (para gráficas)
// ============================================================================

/// Datos de un día para las gráficas semanales.
class DayTrendData {
  final DateTime date;
  final int kcalConsumed;
  final int? kcalTarget;

  const DayTrendData({
    required this.date,
    required this.kcalConsumed,
    this.kcalTarget,
  });

  double get kcalPercent => kcalTarget != null && kcalTarget! > 0
      ? (kcalConsumed / kcalTarget!).clamp(0.0, 2.0)
      : 0.0;
}

/// Provider de tendencia semanal de calorías (últimos 7 días).
///
/// Retorna datos de calorías consumidas por día para mostrar en gráficos.
final weeklyCalorieTrendProvider = FutureProvider<List<DayTrendData>>((
  ref,
) async {
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  // Usar watch para reaccionar a cambios en el plan
  final coachPlan = ref.watch(coachPlanProvider);

  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  final weekAgo = startOfToday.subtract(const Duration(days: 6));

  final result = <DayTrendData>[];
  int? targetKcal;

  // Calcular target desde CoachPlan si existe
  if (coachPlan != null) {
    final calculator = ref.watch(daySummaryCalculatorProvider);
    targetKcal = calculator.calculateTDEEFromCoachPlan(coachPlan).round();
  }

  // Obtener datos de cada día
  for (var i = 0; i < 7; i++) {
    final date = weekAgo.add(Duration(days: i));
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final entries = await diaryRepo.getByDateRange(dayStart, dayEnd);

    final kcalSum = entries.fold<double>(0.0, (sum, e) => sum + e.kcal).round();

    result.add(
      DayTrendData(
        date: dayStart,
        kcalConsumed: kcalSum,
        kcalTarget: targetKcal,
      ),
    );
  }

  return result;
});

// ============================================================================
// UI STATE - TARGETS MANAGEMENT (DEPRECATED)
// ============================================================================

/// @deprecated El sistema manual de Targets está deprecado.
/// Usar el Coach (CoachPlan) para configurar objetivos.
///
/// Notifier para gestionar el formulario de creación/edición de targets.
@Deprecated(
  'Usar CoachPlan via coach_providers - el sistema manual de Targets está deprecado',
)
class TargetsFormNotifier extends Notifier<TargetsFormState> {
  @override
  TargetsFormState build() => TargetsFormState.empty();

  void setKcal(int kcal) => state = state.copyWith(kcalTarget: kcal);
  void setProtein(double? protein) =>
      state = state.copyWith(proteinTarget: protein);
  void setCarbs(double? carbs) => state = state.copyWith(carbsTarget: carbs);
  void setFat(double? fat) => state = state.copyWith(fatTarget: fat);
  void setValidFrom(DateTime date) => state = state.copyWith(validFrom: date);
  void setNotes(String? notes) => state = state.copyWith(notes: notes);

  /// Carga datos de un target existente para edición.
  void loadFromModel(TargetsModel model) {
    state = TargetsFormState(
      id: model.id,
      kcalTarget: model.kcalTarget,
      proteinTarget: model.proteinTarget,
      carbsTarget: model.carbsTarget,
      fatTarget: model.fatTarget,
      validFrom: model.validFrom,
      notes: model.notes,
      isEditing: true,
    );
  }

  /// Resetea el formulario a valores por defecto.
  void reset() => state = TargetsFormState.empty();

  /// Valida si el formulario tiene datos mínimos válidos.
  bool get isValid => state.kcalTarget > 0;

  /// Convierte el estado actual a modelo para guardar.
  TargetsModel toModel() => TargetsModel(
    id: state.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    validFrom: DateTime(
      state.validFrom.year,
      state.validFrom.month,
      state.validFrom.day,
    ),
    kcalTarget: state.kcalTarget,
    proteinTarget: state.proteinTarget,
    carbsTarget: state.carbsTarget,
    fatTarget: state.fatTarget,
    notes: state.notes,
  );
}

/// Provider del estado del formulario de targets.
final targetsFormProvider =
    NotifierProvider<TargetsFormNotifier, TargetsFormState>(
      TargetsFormNotifier.new,
    );

/// Estado del formulario de targets.
class TargetsFormState {
  final String? id;
  final int kcalTarget;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatTarget;
  final DateTime validFrom;
  final String? notes;
  final bool isEditing;

  const TargetsFormState({
    this.id,
    required this.kcalTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatTarget,
    required this.validFrom,
    this.notes,
    this.isEditing = false,
  });

  factory TargetsFormState.empty() =>
      TargetsFormState(kcalTarget: 2000, validFrom: DateTime.now());

  TargetsFormState copyWith({
    String? id,
    int? kcalTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
    DateTime? validFrom,
    String? notes,
    bool? isEditing,
  }) => TargetsFormState(
    id: id ?? this.id,
    kcalTarget: kcalTarget ?? this.kcalTarget,
    proteinTarget: proteinTarget ?? this.proteinTarget,
    carbsTarget: carbsTarget ?? this.carbsTarget,
    fatTarget: fatTarget ?? this.fatTarget,
    validFrom: validFrom ?? this.validFrom,
    notes: notes ?? this.notes,
    isEditing: isEditing ?? this.isEditing,
  );

  /// Calorías calculadas desde macros (para validación).
  int? get kcalFromMacros {
    final p = proteinTarget ?? 0;
    final c = carbsTarget ?? 0;
    final f = fatTarget ?? 0;
    if (p == 0 && c == 0 && f == 0) return null;
    return ((p * 4) + (c * 4) + (f * 9)).round();
  }

  /// Diferencia entre kcal objetivo y kcal calculadas de macros.
  int? get kcalDifference {
    final fromMacros = kcalFromMacros;
    if (fromMacros == null) return null;
    return kcalTarget - fromMacros;
  }
}
