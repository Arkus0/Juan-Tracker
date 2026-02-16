/// Providers para el sistema de tracking de agua.
///
/// Persistencia diaria via SharedPreferences con clave
/// `water_{yyyy-MM-dd}`. Meta diaria configurable.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';

/// Meta diaria de agua en ml (por defecto 2500 ml)
const int kDefaultWaterGoalMl = 2500;

/// Incrementos rápidos disponibles
const List<int> kWaterQuickAmounts = [150, 250, 330, 500];

// ============================================================================
// ESTADO
// ============================================================================

/// Provider del consumo de agua del día seleccionado.
final waterIntakeProvider =
    NotifierProvider<WaterIntakeNotifier, WaterState>(WaterIntakeNotifier.new);

/// Estado del tracking de agua
class WaterState {
  /// Cantidad consumida hoy (ml)
  final int consumedMl;

  /// Meta diaria (ml)
  final int goalMl;

  /// Hora de la fecha activa (para detectar cambio de día)
  final String dateKey;

  const WaterState({
    required this.consumedMl,
    required this.goalMl,
    required this.dateKey,
  });

  double get progress => goalMl > 0 ? (consumedMl / goalMl).clamp(0.0, 2.0) : 0;
  bool get goalReached => consumedMl >= goalMl;
  int get remainingMl => (goalMl - consumedMl).clamp(0, goalMl);
  double get consumedLiters => consumedMl / 1000;
  double get goalLiters => goalMl / 1000;
}

class WaterIntakeNotifier extends Notifier<WaterState> {
  @override
  WaterState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final dateKey = _todayKey();
    final consumed = prefs.getInt('water_$dateKey') ?? 0;
    final goal = prefs.getInt('water_goal') ?? kDefaultWaterGoalMl;

    return WaterState(
      consumedMl: consumed,
      goalMl: goal,
      dateKey: dateKey,
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Añadir agua
  void addWater(int ml) {
    final prefs = ref.read(sharedPreferencesProvider);
    final dateKey = _todayKey();
    final newTotal = state.consumedMl + ml;
    prefs.setInt('water_$dateKey', newTotal);
    state = WaterState(
      consumedMl: newTotal,
      goalMl: state.goalMl,
      dateKey: dateKey,
    );
  }

  /// Quitar agua (undo)
  void removeWater(int ml) {
    final prefs = ref.read(sharedPreferencesProvider);
    final dateKey = _todayKey();
    final newTotal = (state.consumedMl - ml).clamp(0, 99999);
    prefs.setInt('water_$dateKey', newTotal);
    state = WaterState(
      consumedMl: newTotal,
      goalMl: state.goalMl,
      dateKey: dateKey,
    );
  }

  /// Cambiar la meta diaria
  void setGoal(int goalMl) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt('water_goal', goalMl);
    state = WaterState(
      consumedMl: state.consumedMl,
      goalMl: goalMl,
      dateKey: state.dateKey,
    );
  }

  /// Resetear el consumo del día
  void reset() {
    final prefs = ref.read(sharedPreferencesProvider);
    final dateKey = _todayKey();
    prefs.setInt('water_$dateKey', 0);
    state = WaterState(
      consumedMl: 0,
      goalMl: state.goalMl,
      dateKey: dateKey,
    );
  }
}
