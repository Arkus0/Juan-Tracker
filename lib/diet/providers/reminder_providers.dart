import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/app_providers.dart';
import '../services/diet_reminder_service.dart';

// ============================================================================
// MODELO
// ============================================================================

/// Configuración de un recordatorio individual
class ReminderConfig {
  final bool enabled;
  final TimeOfDay time;

  const ReminderConfig({required this.enabled, required this.time});

  ReminderConfig copyWith({bool? enabled, TimeOfDay? time}) => ReminderConfig(
    enabled: enabled ?? this.enabled,
    time: time ?? this.time,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': time.hour,
    'minute': time.minute,
  };

  factory ReminderConfig.fromJson(Map<String, dynamic> json) => ReminderConfig(
    enabled: json['enabled'] as bool? ?? false,
    time: TimeOfDay(
      hour: json['hour'] as int? ?? 8,
      minute: json['minute'] as int? ?? 0,
    ),
  );

  factory ReminderConfig.disabled({int hour = 8, int minute = 0}) =>
      ReminderConfig(enabled: false, time: TimeOfDay(hour: hour, minute: minute));
}

/// Estado completo de todos los recordatorios de dieta
class DietRemindersState {
  final ReminderConfig breakfast;
  final ReminderConfig lunch;
  final ReminderConfig dinner;
  final ReminderConfig snack;
  final ReminderConfig weighIn;
  final ReminderConfig water;
  final ReminderConfig weeklyCheckIn;

  const DietRemindersState({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.weighIn,
    required this.water,
    required this.weeklyCheckIn,
  });

  /// Valores por defecto sensatos
  factory DietRemindersState.defaults() => DietRemindersState(
    breakfast: ReminderConfig.disabled(hour: 8, minute: 0),
    lunch: ReminderConfig.disabled(hour: 13, minute: 0),
    dinner: ReminderConfig.disabled(hour: 20, minute: 30),
    snack: ReminderConfig.disabled(hour: 17, minute: 0),
    weighIn: ReminderConfig.disabled(hour: 7, minute: 30),
    water: ReminderConfig.disabled(hour: 15, minute: 0),
    weeklyCheckIn: ReminderConfig.disabled(hour: 9, minute: 0),
  );

  DietRemindersState copyWith({
    ReminderConfig? breakfast,
    ReminderConfig? lunch,
    ReminderConfig? dinner,
    ReminderConfig? snack,
    ReminderConfig? weighIn,
    ReminderConfig? water,
    ReminderConfig? weeklyCheckIn,
  }) => DietRemindersState(
    breakfast: breakfast ?? this.breakfast,
    lunch: lunch ?? this.lunch,
    dinner: dinner ?? this.dinner,
    snack: snack ?? this.snack,
    weighIn: weighIn ?? this.weighIn,
    water: water ?? this.water,
    weeklyCheckIn: weeklyCheckIn ?? this.weeklyCheckIn,
  );

  /// ¿Hay al menos un recordatorio activo?
  bool get hasAnyEnabled =>
      breakfast.enabled ||
      lunch.enabled ||
      dinner.enabled ||
      snack.enabled ||
      weighIn.enabled ||
      water.enabled ||
      weeklyCheckIn.enabled;

  /// Cuenta de recordatorios activos
  int get enabledCount => [
    breakfast,
    lunch,
    dinner,
    snack,
    weighIn,
    water,
    weeklyCheckIn,
  ].where((r) => r.enabled).length;

  Map<String, dynamic> toJson() => {
    'breakfast': breakfast.toJson(),
    'lunch': lunch.toJson(),
    'dinner': dinner.toJson(),
    'snack': snack.toJson(),
    'weighIn': weighIn.toJson(),
    'water': water.toJson(),
    'weeklyCheckIn': weeklyCheckIn.toJson(),
  };

  factory DietRemindersState.fromJson(Map<String, dynamic> json) {
    return DietRemindersState(
      breakfast: json['breakfast'] != null
          ? ReminderConfig.fromJson(json['breakfast'] as Map<String, dynamic>)
          : ReminderConfig.disabled(hour: 8),
      lunch: json['lunch'] != null
          ? ReminderConfig.fromJson(json['lunch'] as Map<String, dynamic>)
          : ReminderConfig.disabled(hour: 13),
      dinner: json['dinner'] != null
          ? ReminderConfig.fromJson(json['dinner'] as Map<String, dynamic>)
          : ReminderConfig.disabled(hour: 20, minute: 30),
      snack: json['snack'] != null
          ? ReminderConfig.fromJson(json['snack'] as Map<String, dynamic>)
          : ReminderConfig.disabled(hour: 17),
      weighIn: json['weighIn'] != null
          ? ReminderConfig.fromJson(json['weighIn'] as Map<String, dynamic>)
          : ReminderConfig.disabled(hour: 7, minute: 30),
      water: json['water'] != null
          ? ReminderConfig.fromJson(json['water'] as Map<String, dynamic>)
          : ReminderConfig.disabled(hour: 15),
      weeklyCheckIn: json['weeklyCheckIn'] != null
          ? ReminderConfig.fromJson(json['weeklyCheckIn'] as Map<String, dynamic>)
          : ReminderConfig.disabled(hour: 9),
    );
  }
}

// ============================================================================
// NOTIFIER
// ============================================================================

const _prefsKey = 'diet_reminders_v1';

/// Notifier que gestiona la configuración de recordatorios
/// y sincroniza con DietReminderService.
class DietRemindersNotifier extends Notifier<DietRemindersState> {
  late SharedPreferences _prefs;
  final _service = DietReminderService.instance;

  @override
  DietRemindersState build() {
    _prefs = ref.watch(sharedPreferencesProvider);

    final json = _prefs.getString(_prefsKey);
    if (json != null) {
      try {
        return DietRemindersState.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
      } catch (_) {
        // Config corrupta, usar defaults
      }
    }
    return DietRemindersState.defaults();
  }

  // ─────────────────────────────────────────────────────────────────
  // Toggle individual
  // ─────────────────────────────────────────────────────────────────

  Future<void> toggleBreakfast(bool enabled) async {
    state = state.copyWith(
      breakfast: state.breakfast.copyWith(enabled: enabled),
    );
    await _persist();
    if (enabled) {
      await _service.scheduleBreakfast(
        state.breakfast.time.hour,
        state.breakfast.time.minute,
      );
    } else {
      await _service.cancelBreakfast();
    }
  }

  Future<void> toggleLunch(bool enabled) async {
    state = state.copyWith(
      lunch: state.lunch.copyWith(enabled: enabled),
    );
    await _persist();
    if (enabled) {
      await _service.scheduleLunch(
        state.lunch.time.hour,
        state.lunch.time.minute,
      );
    } else {
      await _service.cancelLunch();
    }
  }

  Future<void> toggleDinner(bool enabled) async {
    state = state.copyWith(
      dinner: state.dinner.copyWith(enabled: enabled),
    );
    await _persist();
    if (enabled) {
      await _service.scheduleDinner(
        state.dinner.time.hour,
        state.dinner.time.minute,
      );
    } else {
      await _service.cancelDinner();
    }
  }

  Future<void> toggleSnack(bool enabled) async {
    state = state.copyWith(
      snack: state.snack.copyWith(enabled: enabled),
    );
    await _persist();
    if (enabled) {
      await _service.scheduleSnack(
        state.snack.time.hour,
        state.snack.time.minute,
      );
    } else {
      await _service.cancelSnack();
    }
  }

  Future<void> toggleWeighIn(bool enabled) async {
    state = state.copyWith(
      weighIn: state.weighIn.copyWith(enabled: enabled),
    );
    await _persist();
    if (enabled) {
      await _service.scheduleWeighIn(
        state.weighIn.time.hour,
        state.weighIn.time.minute,
      );
    } else {
      await _service.cancelWeighIn();
    }
  }

  Future<void> toggleWater(bool enabled) async {
    state = state.copyWith(
      water: state.water.copyWith(enabled: enabled),
    );
    await _persist();
    if (enabled) {
      await _service.scheduleWater(
        state.water.time.hour,
        state.water.time.minute,
      );
    } else {
      await _service.cancelWater();
    }
  }

  Future<void> toggleWeeklyCheckIn(bool enabled) async {
    state = state.copyWith(
      weeklyCheckIn: state.weeklyCheckIn.copyWith(enabled: enabled),
    );
    await _persist();
    if (enabled) {
      await _service.scheduleWeeklyCheckIn(
        state.weeklyCheckIn.time.hour,
        state.weeklyCheckIn.time.minute,
      );
    } else {
      await _service.cancelWeeklyCheckIn();
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Cambio de hora
  // ─────────────────────────────────────────────────────────────────

  Future<void> setBreakfastTime(TimeOfDay time) async {
    state = state.copyWith(
      breakfast: state.breakfast.copyWith(time: time),
    );
    await _persist();
    if (state.breakfast.enabled) {
      await _service.scheduleBreakfast(time.hour, time.minute);
    }
  }

  Future<void> setLunchTime(TimeOfDay time) async {
    state = state.copyWith(
      lunch: state.lunch.copyWith(time: time),
    );
    await _persist();
    if (state.lunch.enabled) {
      await _service.scheduleLunch(time.hour, time.minute);
    }
  }

  Future<void> setDinnerTime(TimeOfDay time) async {
    state = state.copyWith(
      dinner: state.dinner.copyWith(time: time),
    );
    await _persist();
    if (state.dinner.enabled) {
      await _service.scheduleDinner(time.hour, time.minute);
    }
  }

  Future<void> setSnackTime(TimeOfDay time) async {
    state = state.copyWith(
      snack: state.snack.copyWith(time: time),
    );
    await _persist();
    if (state.snack.enabled) {
      await _service.scheduleSnack(time.hour, time.minute);
    }
  }

  Future<void> setWeighInTime(TimeOfDay time) async {
    state = state.copyWith(
      weighIn: state.weighIn.copyWith(time: time),
    );
    await _persist();
    if (state.weighIn.enabled) {
      await _service.scheduleWeighIn(time.hour, time.minute);
    }
  }

  Future<void> setWaterTime(TimeOfDay time) async {
    state = state.copyWith(
      water: state.water.copyWith(time: time),
    );
    await _persist();
    if (state.water.enabled) {
      await _service.scheduleWater(time.hour, time.minute);
    }
  }

  Future<void> setWeeklyCheckInTime(TimeOfDay time) async {
    state = state.copyWith(
      weeklyCheckIn: state.weeklyCheckIn.copyWith(time: time),
    );
    await _persist();
    if (state.weeklyCheckIn.enabled) {
      await _service.scheduleWeeklyCheckIn(time.hour, time.minute);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Bulk
  // ─────────────────────────────────────────────────────────────────

  /// Desactiva todos los recordatorios
  Future<void> disableAll() async {
    state = DietRemindersState.defaults();
    await _persist();
    await _service.cancelAll();
  }

  /// Re-programa todos los recordatorios activos.
  /// Llamar al iniciar la app o tras un reboot.
  Future<void> rescheduleAll() async {
    final s = state;

    if (s.breakfast.enabled) {
      await _service.scheduleBreakfast(s.breakfast.time.hour, s.breakfast.time.minute);
    }
    if (s.lunch.enabled) {
      await _service.scheduleLunch(s.lunch.time.hour, s.lunch.time.minute);
    }
    if (s.dinner.enabled) {
      await _service.scheduleDinner(s.dinner.time.hour, s.dinner.time.minute);
    }
    if (s.snack.enabled) {
      await _service.scheduleSnack(s.snack.time.hour, s.snack.time.minute);
    }
    if (s.weighIn.enabled) {
      await _service.scheduleWeighIn(s.weighIn.time.hour, s.weighIn.time.minute);
    }
    if (s.water.enabled) {
      await _service.scheduleWater(s.water.time.hour, s.water.time.minute);
    }
    if (s.weeklyCheckIn.enabled) {
      await _service.scheduleWeeklyCheckIn(
        s.weeklyCheckIn.time.hour, s.weeklyCheckIn.time.minute,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Persistencia
  // ─────────────────────────────────────────────────────────────────

  Future<void> _persist() async {
    await _prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider principal de recordatorios de dieta
final dietRemindersProvider =
    NotifierProvider<DietRemindersNotifier, DietRemindersState>(
  DietRemindersNotifier.new,
);
