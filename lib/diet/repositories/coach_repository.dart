/// Repositorio para persistir el plan del Coach Adaptativo
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/adaptive_coach_service.dart';

/// Repositorio para guardar/cargar el plan del Coach
class CoachRepository {
  static const String _planKey = 'coach_plan_v1';
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
    return CoachPlan(
      id: json['id'] as String,
      goal: WeightGoal.values.byName(json['goal'] as String),
      weeklyRatePercent: (json['weeklyRatePercent'] as num).toDouble(),
      initialTdeeEstimate: json['initialTdeeEstimate'] as int,
      startingWeight: (json['startingWeight'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      lastCheckInDate: json['lastCheckInDate'] != null
          ? DateTime.parse(json['lastCheckInDate'] as String)
          : null,
      currentTargetId: json['currentTargetId'] as String?,
      currentKcalTarget: json['currentKcalTarget'] as int?,
      notes: json['notes'] as String?,
    );
  }
}

/// Extensión para serializar CoachPlan
extension CoachPlanJson on CoachPlan {
  Map<String, dynamic> toJson() => {
    'id': id,
    'goal': goal.name,
    'weeklyRatePercent': weeklyRatePercent,
    'initialTdeeEstimate': initialTdeeEstimate,
    'startingWeight': startingWeight,
    'startDate': startDate.toIso8601String(),
    'lastCheckInDate': lastCheckInDate?.toIso8601String(),
    'currentTargetId': currentTargetId,
    'currentKcalTarget': currentKcalTarget,
    'notes': notes,
  };
}
