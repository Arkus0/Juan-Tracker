import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/app_providers.dart';
import '../services/diet_reminder_service.dart';

// ============================================================================
// MODELOS
// ============================================================================

/// Configuracion de un recordatorio individual.
class ReminderConfig {
  final bool enabled;
  final TimeOfDay time;

  const ReminderConfig({required this.enabled, required this.time});

  ReminderConfig copyWith({bool? enabled, TimeOfDay? time}) =>
      ReminderConfig(enabled: enabled ?? this.enabled, time: time ?? this.time);

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

  factory ReminderConfig.disabled({int hour = 8, int minute = 0}) {
    return ReminderConfig(
      enabled: false,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }
}

/// Estado completo de todos los recordatorios de dieta.
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
  }) {
    return DietRemindersState(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snack: snack ?? this.snack,
      weighIn: weighIn ?? this.weighIn,
      water: water ?? this.water,
      weeklyCheckIn: weeklyCheckIn ?? this.weeklyCheckIn,
    );
  }

  bool get hasAnyEnabled {
    return breakfast.enabled ||
        lunch.enabled ||
        dinner.enabled ||
        snack.enabled ||
        weighIn.enabled ||
        water.enabled ||
        weeklyCheckIn.enabled;
  }

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
          ? ReminderConfig.fromJson(
              json['weeklyCheckIn'] as Map<String, dynamic>,
            )
          : ReminderConfig.disabled(hour: 9),
    );
  }
}

// ============================================================================
// NOTIFIER
// ============================================================================

const _prefsKey = 'diet_reminders_v1';

/// Notifier que gestiona configuracion de recordatorios y sincroniza servicio.
class DietRemindersNotifier extends Notifier<DietRemindersState> {
  late SharedPreferences _prefs;
  final _service = DietReminderService.instance;
  bool _serviceReady = false;

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
        // Config corrupta, usar defaults.
      }
    }
    return DietRemindersState.defaults();
  }

  // ---------------- Toggle ----------------

  Future<void> toggleBreakfast(bool enabled) => _toggleReminder(
    enabled: enabled,
    current: state.breakfast,
    setConfig: (config) => state.copyWith(breakfast: config),
    schedule: _service.scheduleBreakfast,
    cancel: _service.cancelBreakfast,
  );

  Future<void> toggleLunch(bool enabled) => _toggleReminder(
    enabled: enabled,
    current: state.lunch,
    setConfig: (config) => state.copyWith(lunch: config),
    schedule: _service.scheduleLunch,
    cancel: _service.cancelLunch,
  );

  Future<void> toggleDinner(bool enabled) => _toggleReminder(
    enabled: enabled,
    current: state.dinner,
    setConfig: (config) => state.copyWith(dinner: config),
    schedule: _service.scheduleDinner,
    cancel: _service.cancelDinner,
  );

  Future<void> toggleSnack(bool enabled) => _toggleReminder(
    enabled: enabled,
    current: state.snack,
    setConfig: (config) => state.copyWith(snack: config),
    schedule: _service.scheduleSnack,
    cancel: _service.cancelSnack,
  );

  Future<void> toggleWeighIn(bool enabled) => _toggleReminder(
    enabled: enabled,
    current: state.weighIn,
    setConfig: (config) => state.copyWith(weighIn: config),
    schedule: _service.scheduleWeighIn,
    cancel: _service.cancelWeighIn,
  );

  Future<void> toggleWater(bool enabled) => _toggleReminder(
    enabled: enabled,
    current: state.water,
    setConfig: (config) => state.copyWith(water: config),
    schedule: _service.scheduleWater,
    cancel: _service.cancelWater,
  );

  Future<void> toggleWeeklyCheckIn(bool enabled) => _toggleReminder(
    enabled: enabled,
    current: state.weeklyCheckIn,
    setConfig: (config) => state.copyWith(weeklyCheckIn: config),
    schedule: _service.scheduleWeeklyCheckIn,
    cancel: _service.cancelWeeklyCheckIn,
  );

  // ---------------- Cambio de hora ----------------

  Future<void> setBreakfastTime(TimeOfDay time) => _setReminderTime(
    time: time,
    current: state.breakfast,
    setConfig: (config) => state.copyWith(breakfast: config),
    schedule: _service.scheduleBreakfast,
  );

  Future<void> setLunchTime(TimeOfDay time) => _setReminderTime(
    time: time,
    current: state.lunch,
    setConfig: (config) => state.copyWith(lunch: config),
    schedule: _service.scheduleLunch,
  );

  Future<void> setDinnerTime(TimeOfDay time) => _setReminderTime(
    time: time,
    current: state.dinner,
    setConfig: (config) => state.copyWith(dinner: config),
    schedule: _service.scheduleDinner,
  );

  Future<void> setSnackTime(TimeOfDay time) => _setReminderTime(
    time: time,
    current: state.snack,
    setConfig: (config) => state.copyWith(snack: config),
    schedule: _service.scheduleSnack,
  );

  Future<void> setWeighInTime(TimeOfDay time) => _setReminderTime(
    time: time,
    current: state.weighIn,
    setConfig: (config) => state.copyWith(weighIn: config),
    schedule: _service.scheduleWeighIn,
  );

  Future<void> setWaterTime(TimeOfDay time) => _setReminderTime(
    time: time,
    current: state.water,
    setConfig: (config) => state.copyWith(water: config),
    schedule: _service.scheduleWater,
  );

  Future<void> setWeeklyCheckInTime(TimeOfDay time) => _setReminderTime(
    time: time,
    current: state.weeklyCheckIn,
    setConfig: (config) => state.copyWith(weeklyCheckIn: config),
    schedule: _service.scheduleWeeklyCheckIn,
  );

  // ---------------- Bulk ----------------

  Future<void> disableAll() async {
    final previousState = state;
    state = DietRemindersState.defaults();
    await _persist();

    try {
      await _ensureServiceReady();
      await _service.cancelAll();
    } catch (_) {
      state = previousState;
      await _persist();
      rethrow;
    }
  }

  Future<void> rescheduleAll() async {
    await _ensureServiceReady();
    final s = state;

    if (s.breakfast.enabled) {
      await _service.scheduleBreakfast(
        s.breakfast.time.hour,
        s.breakfast.time.minute,
      );
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
      await _service.scheduleWeighIn(
        s.weighIn.time.hour,
        s.weighIn.time.minute,
      );
    }
    if (s.water.enabled) {
      await _service.scheduleWater(s.water.time.hour, s.water.time.minute);
    }
    if (s.weeklyCheckIn.enabled) {
      await _service.scheduleWeeklyCheckIn(
        s.weeklyCheckIn.time.hour,
        s.weeklyCheckIn.time.minute,
      );
    }
  }

  // ---------------- Helpers ----------------

  Future<void> _toggleReminder({
    required bool enabled,
    required ReminderConfig current,
    required DietRemindersState Function(ReminderConfig config) setConfig,
    required Future<void> Function(int hour, int minute) schedule,
    required Future<void> Function() cancel,
  }) async {
    final previousState = state;
    final updatedConfig = current.copyWith(enabled: enabled);
    state = setConfig(updatedConfig);
    await _persist();

    try {
      if (enabled) {
        await _ensurePermission();
        await schedule(updatedConfig.time.hour, updatedConfig.time.minute);
      } else {
        await _ensureServiceReady();
        await cancel();
      }
    } catch (_) {
      state = previousState;
      await _persist();
      rethrow;
    }
  }

  Future<void> _setReminderTime({
    required TimeOfDay time,
    required ReminderConfig current,
    required DietRemindersState Function(ReminderConfig config) setConfig,
    required Future<void> Function(int hour, int minute) schedule,
  }) async {
    final previousState = state;
    final updatedConfig = current.copyWith(time: time);
    state = setConfig(updatedConfig);
    await _persist();

    try {
      if (updatedConfig.enabled) {
        await _ensurePermission();
        await schedule(time.hour, time.minute);
      }
    } catch (_) {
      state = previousState;
      await _persist();
      rethrow;
    }
  }

  Future<void> _ensureServiceReady() async {
    if (_serviceReady) return;
    await _service.initialize();
    _serviceReady = true;
  }

  Future<void> _ensurePermission() async {
    await _ensureServiceReady();
    final granted = await _service.requestPermission();
    if (!granted) {
      throw StateError(
        'Permiso de notificaciones denegado. Actívalo en ajustes del sistema.',
      );
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

final dietRemindersProvider =
    NotifierProvider<DietRemindersNotifier, DietRemindersState>(
      DietRemindersNotifier.new,
    );
