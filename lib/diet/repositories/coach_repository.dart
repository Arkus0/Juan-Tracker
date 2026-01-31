/// Repositorio para persistir el plan del Coach Adaptativo
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/adaptive_coach_service.dart';

/// Repositorio para guardar/cargar el plan del Coach
class CoachRepository {
  static const String _planKey = 'coach_plan_v2';
  static const String _checkInHistoryKey = 'coach_checkin_history_v1';

  final SharedPreferences _prefs;

  CoachRepository(this._prefs);

  /// Guarda el plan actual
  Future<void> savePlan(CoachPlan plan) async {
    final json = jsonEncode(plan.toJson());
    await _prefs.setString(_planKey, json);
  }

  /// Carga el plan guardado (null si no existe)
  CoachPlan? loadPlan() {
    final json = _prefs.getString(_planKey);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return _planFromJson(map);
    } catch (e) {
      return null;
    }
  }

  /// Elimina el plan guardado
  Future<void> clearPlan() async {
    await _prefs.remove(_planKey);
  }

  /// Verifica si existe un plan activo
  bool hasActivePlan() {
    return loadPlan() != null;
  }

  /// Guarda una entrada de check-in en el historial
  Future<void> saveCheckIn(CheckInResult checkIn, DateTime date) async {
    final history = _loadCheckInHistory();
    history[date.toIso8601String()] = {
      'tdee': checkIn.estimatedTdee,
      'targetKcal': checkIn.proposedTargets.kcalTarget,
      'weightChange': checkIn.weeklyData.trendChangeKg,
      'avgIntake': checkIn.weeklyData.avgDailyKcal,
    };
    await _prefs.setString(_checkInHistoryKey, jsonEncode(history));
  }

  /// Carga el historial de check-ins
  Map<String, dynamic> loadCheckInHistory() {
    return _loadCheckInHistory();
  }

  Map<String, dynamic> _loadCheckInHistory() {
    final json = _prefs.getString(_checkInHistoryKey);
    if (json == null) return {};

    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Serialización manual de CoachPlan
  CoachPlan _planFromJson(Map<String, dynamic> json) {
    // Migración de datos antiguos (weeklyRatePercent -> weeklyRateKg)
    double weeklyRateKg;
    if (json.containsKey('weeklyRateKg')) {
      weeklyRateKg = (json['weeklyRateKg'] as num).toDouble();
    } else if (json.containsKey('weeklyRatePercent')) {
      // Legacy: convertir % a kg usando startingWeight
      // Asume que percent está en formato decimal (0.02 = 2%)
      final percent = (json['weeklyRatePercent'] as num).toDouble();
      final weight = (json['startingWeight'] as num).toDouble();
      // Si percent > 1, probablemente está en formato entero (2 = 2%)
      final normalizedPercent = percent > 1 ? percent / 100 : percent;
      weeklyRateKg = weight * normalizedPercent;
    } else {
      weeklyRateKg = 0.5; // Default
    }

    // Parseo seguro de enums con fallback
    WeightGoal goal;
    try {
      goal = WeightGoal.values.byName(json['goal'] as String);
    } catch (e) {
      goal = WeightGoal.maintain; // Fallback seguro
    }

    MacroPreset macroPreset;
    try {
      macroPreset = json.containsKey('macroPreset')
          ? MacroPreset.values.byName(json['macroPreset'] as String)
          : MacroPreset.balanced;
    } catch (e) {
      macroPreset = MacroPreset.balanced; // Fallback seguro
    }

    // Parseo seguro de fechas con fallback
    DateTime startDate;
    try {
      startDate = DateTime.parse(json['startDate'] as String);
    } catch (e) {
      startDate = DateTime.now(); // Fallback a fecha actual
    }

    DateTime? lastCheckInDate;
    try {
      lastCheckInDate = json['lastCheckInDate'] != null
          ? DateTime.parse(json['lastCheckInDate'] as String)
          : null;
    } catch (e) {
      lastCheckInDate = null;
    }

    return CoachPlan(
      id: json['id'] as String,
      goal: goal,
      weeklyRateKg: weeklyRateKg,
      initialTdeeEstimate: json['initialTdeeEstimate'] as int,
      startingWeight: (json['startingWeight'] as num).toDouble(),
      startDate: startDate,
      lastCheckInDate: lastCheckInDate,
      currentTargetId: json['currentTargetId'] as String?,
      currentKcalTarget: json['currentKcalTarget'] as int?,
      notes: json['notes'] as String?,
      macroPreset: macroPreset,
    );
  }
}

/// Extensión para serializar CoachPlan
extension CoachPlanJson on CoachPlan {
  Map<String, dynamic> toJson() => {
    'id': id,
    'goal': goal.name,
    'weeklyRateKg': weeklyRateKg,
    'initialTdeeEstimate': initialTdeeEstimate,
    'startingWeight': startingWeight,
    'startDate': startDate.toIso8601String(),
    'lastCheckInDate': lastCheckInDate?.toIso8601String(),
    'currentTargetId': currentTargetId,
    'currentKcalTarget': currentKcalTarget,
    'notes': notes,
    'macroPreset': macroPreset.name,
  };
}
