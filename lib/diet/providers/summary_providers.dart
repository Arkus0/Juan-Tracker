import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../models/models.dart';
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
// TARGETS
// ============================================================================

/// Provider de todos los objetivos (ordenados por fecha descendente).
/// 
/// Se auto-refresca cuando cambia la base de datos.
final allTargetsProvider = StreamProvider<List<TargetsModel>>((ref) {
  return ref.watch(targetsRepositoryProvider).watchAll();
});

/// Provider de objetivos activos para una fecha específica.
/// 
/// Usa el calculador puro para determinar cuál target aplica para la fecha.
/// Si no hay target configurado, retorna null.
final dayTargetsProvider = FutureProvider<TargetsModel?>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final targets = await ref.watch(allTargetsProvider.future);
  final calculator = ref.watch(daySummaryCalculatorProvider);

  return calculator.findActiveTargetForDate(targets, date);
});

/// Provider de objetivos actuales (para hoy).
/// 
/// Alias conveniente para [dayTargetsProvider] con fecha actual.
final currentTargetsProvider = FutureProvider<TargetsModel?>((ref) async {
  final repo = ref.watch(targetsRepositoryProvider);
  return repo.getCurrent();
});

// ============================================================================
// DAY SUMMARY
// ============================================================================

/// Provider del resumen completo del día (consumo + targets + progreso).
/// 
/// Este es el provider principal para la UI de "budget".
/// Combina:
/// - Totales consumidos del día
/// - Target activo para la fecha
/// - Progreso calculado
final daySummaryProvider = Provider<AsyncValue<DaySummary>>((ref) {
  final date = ref.watch(selectedDateProvider);
  final totalsAsync = ref.watch(dailyTotalsProvider);
  final targetsAsync = ref.watch(dayTargetsProvider);
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
    date: date,
    consumed: totals,
    targets: targets,
  );

  return AsyncValue.data(summary);
});

/// Provider del resumen del día como Future (para widgets que necesitan Future).
/// 
/// Combina el totales del día con el cálculo de targets.
final daySummaryFutureProvider = FutureProvider<DaySummary>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final totals = await ref.watch(dailyTotalsProvider.future);
  final targets = await ref.watch(dayTargetsProvider.future);
  final calculator = ref.watch(daySummaryCalculatorProvider);

  return calculator.calculate(
    date: date,
    consumed: totals,
    targets: targets,
  );
});

// ============================================================================
// UI STATE - TARGETS MANAGEMENT
// ============================================================================

/// Notifier para gestionar el formulario de creación/edición de targets.
class TargetsFormNotifier extends Notifier<TargetsFormState> {
  @override
  TargetsFormState build() => TargetsFormState.empty();

  void setKcal(int kcal) => state = state.copyWith(kcalTarget: kcal);
  void setProtein(double? protein) => state = state.copyWith(proteinTarget: protein);
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
final targetsFormProvider = NotifierProvider<TargetsFormNotifier, TargetsFormState>(
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

  factory TargetsFormState.empty() => TargetsFormState(
        kcalTarget: 2000,
        validFrom: DateTime.now(),
      );

  TargetsFormState copyWith({
    String? id,
    int? kcalTarget,
    double? proteinTarget,
    double? carbsTarget,
    double? fatTarget,
    DateTime? validFrom,
    String? notes,
    bool? isEditing,
  }) =>
      TargetsFormState(
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
