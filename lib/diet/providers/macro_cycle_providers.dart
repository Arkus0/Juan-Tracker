/// Providers para el sistema de ciclado de macros.
///
/// Permite configurar macros diferentes por día de la semana
/// (días de entrenamiento vs descanso).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/macro_cycle_model.dart';
import '../repositories/macro_cycle_repository.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/training_day_provider.dart';

// ============================================================================
// REPOSITORIO
// ============================================================================

final macroCycleRepositoryProvider = Provider<MacroCycleRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MacroCycleRepository(prefs);
});

// ============================================================================
// ESTADO
// ============================================================================

/// Provider de la configuración de ciclado de macros actual
final macroCycleConfigProvider =
    NotifierProvider<MacroCycleConfigNotifier, MacroCycleConfig?>(
  MacroCycleConfigNotifier.new,
);

class MacroCycleConfigNotifier extends Notifier<MacroCycleConfig?> {
  @override
  MacroCycleConfig? build() {
    final repo = ref.watch(macroCycleRepositoryProvider);
    return repo.load();
  }

  /// Guarda una nueva configuración de ciclado
  Future<void> save(MacroCycleConfig config) async {
    final repo = ref.read(macroCycleRepositoryProvider);
    await repo.save(config);
    state = config;
  }

  /// Activa o desactiva el ciclado de macros
  Future<void> toggle(bool enabled) async {
    if (state == null) return;
    final updated = state!.copyWith(
      enabled: enabled,
      updatedAt: DateTime.now(),
    );
    await save(updated);
  }

  /// Actualiza la asignación de un día de la semana
  Future<void> updateDayType(int weekday, DayType type) async {
    if (state == null) return;
    final assignments = Map<int, DayType>.from(state!.weekdayAssignments);
    assignments[weekday] = type;
    final updated = state!.copyWith(
      weekdayAssignments: assignments,
      updatedAt: DateTime.now(),
    );
    await save(updated);
  }

  /// Actualiza los macros de un tipo de día
  Future<void> updateDayMacros({
    DayMacros? trainingMacros,
    DayMacros? restMacros,
    DayMacros? fastingMacros,
  }) async {
    if (state == null) return;
    final updated = state!.copyWith(
      trainingDayMacros: trainingMacros ?? state!.trainingDayMacros,
      restDayMacros: restMacros ?? state!.restDayMacros,
      fastingDayMacros: fastingMacros ?? state!.fastingDayMacros,
      updatedAt: DateTime.now(),
    );
    await save(updated);
  }

  /// Elimina la configuración de ciclado
  Future<void> clear() async {
    final repo = ref.read(macroCycleRepositoryProvider);
    await repo.clear();
    state = null;
  }
}

// ============================================================================
// PROVIDERS DERIVADOS
// ============================================================================

/// Provider que indica si el ciclado de macros está activo
final isMacroCyclingActiveProvider = Provider<bool>((ref) {
  final config = ref.watch(macroCycleConfigProvider);
  return config != null && config.enabled;
});

/// Provider que obtiene el tipo de día (training/rest) para la fecha seleccionada
final selectedDayTypeProvider = Provider.family<DayType, DateTime>((ref, date) {
  final config = ref.watch(macroCycleConfigProvider);
  if (config == null || !config.enabled) return DayType.rest;
  return config.getDayType(date);
});

/// Provider inteligente que usa datos reales de entrenamiento.
///
/// Si el usuario entrenó ese día (sesión completada en la DB), se considera
/// día de entrenamiento aunque la configuración estática diga lo contrario.
/// Útil para ajustes automáticos cuando el usuario cambia un entreno de día.
final smartDayTypeProvider =
    Provider.family<AsyncValue<DayType>, DateTime>((ref, date) {
  final config = ref.watch(macroCycleConfigProvider);
  if (config == null || !config.enabled) {
    return const AsyncValue.data(DayType.rest);
  }

  final trainingInfo = ref.watch(trainingDayInfoProvider(date));
  return trainingInfo.whenData((info) {
    if (info.didTrain) return DayType.training;
    // Caer al valor estático si no hay datos reales
    return config.getDayType(date);
  });
});

/// Provider de macros específicos que usa detección real de entrenamiento.
///
/// Si el ciclado está activo, usa smartDayType para decidir si aplicar
/// macros de entrenamiento o descanso.
final smartDayMacrosProvider =
    Provider.family<AsyncValue<DayMacros?>, DateTime>((ref, date) {
  final config = ref.watch(macroCycleConfigProvider);
  if (config == null || !config.enabled) {
    return const AsyncValue.data(null);
  }

  final dayType = ref.watch(smartDayTypeProvider(date));
  return dayType.whenData((type) {
    return config.getMacrosForDate(date);
  });
});

/// Provider que obtiene los macros específicos del día para una fecha
final daySpecificMacrosProvider = Provider.family<DayMacros?, DateTime>((ref, date) {
  final config = ref.watch(macroCycleConfigProvider);
  if (config == null || !config.enabled) return null;
  return config.getMacrosForDate(date);
});

/// Promedio semanal de kcal con ciclado activo
final weeklyAvgKcalProvider = Provider<int?>((ref) {
  final config = ref.watch(macroCycleConfigProvider);
  if (config == null || !config.enabled) return null;
  return config.weeklyAvgKcal;
});
