// Providers para rangos flexibles de macros

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../models/macro_flexibility_model.dart';

const String _kFlexibilityKey = 'macro_flexibility_config_v1';

/// Provider de la configuración de rangos flexibles de macros.
///
/// Persiste en SharedPreferences via [sharedPreferencesProvider].
/// Permite al usuario configurar la tolerancia (±%) para cada macro.
/// Habilitado por defecto con tolerancias MacroFactor-like.
final macroFlexibilityProvider =
    NotifierProvider<MacroFlexibilityNotifier, MacroFlexibilityConfig>(
  MacroFlexibilityNotifier.new,
);

class MacroFlexibilityNotifier extends Notifier<MacroFlexibilityConfig> {
  @override
  MacroFlexibilityConfig build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final json = prefs.getString(_kFlexibilityKey);
    if (json == null) return MacroFlexibilityConfig.defaults;
    try {
      return MacroFlexibilityConfig.fromJsonString(json);
    } catch (_) {
      return MacroFlexibilityConfig.defaults;
    }
  }

  Future<void> save(MacroFlexibilityConfig config) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kFlexibilityKey, config.toJsonString());
    state = config;
  }

  Future<void> toggle() async {
    await save(state.copyWith(enabled: !state.enabled));
  }

  Future<void> setPreset(MacroFlexibilityConfig preset) async {
    await save(preset.copyWith(enabled: state.enabled));
  }

  Future<void> updateKcalTolerance(double value) async {
    await save(state.copyWith(kcalTolerance: value.clamp(0.01, 0.30)));
  }

  Future<void> updateProteinTolerance(double value) async {
    await save(state.copyWith(proteinTolerance: value.clamp(0.01, 0.30)));
  }

  Future<void> updateCarbsTolerance(double value) async {
    await save(state.copyWith(carbsTolerance: value.clamp(0.01, 0.30)));
  }

  Future<void> updateFatTolerance(double value) async {
    await save(state.copyWith(fatTolerance: value.clamp(0.01, 0.30)));
  }
}

/// Provider derivado: ¿están habilitados los rangos flexibles?
final isMacroFlexibilityActiveProvider = Provider<bool>((ref) {
  return ref.watch(macroFlexibilityProvider).enabled;
});
