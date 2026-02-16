/// Repositorio para persistir la configuración de ciclado de macros.
///
/// Usa SharedPreferences (JSON) igual que CoachRepository.
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/macro_cycle_model.dart';

class MacroCycleRepository {
  static const String _configKey = 'macro_cycle_config_v1';

  final SharedPreferences _prefs;

  MacroCycleRepository(this._prefs);

  /// Guarda la configuración de ciclado de macros
  Future<void> save(MacroCycleConfig config) async {
    final json = jsonEncode(_configToJson(config));
    await _prefs.setString(_configKey, json);
  }

  /// Carga la configuración de ciclado (null si no existe o no está habilitada)
  MacroCycleConfig? load() {
    final json = _prefs.getString(_configKey);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return _configFromJson(map);
    } catch (e) {
      return null;
    }
  }

  /// Elimina la configuración de ciclado
  Future<void> clear() async {
    await _prefs.remove(_configKey);
  }

  /// Verifica si hay una configuración activa
  bool hasActiveConfig() {
    final config = load();
    return config != null && config.enabled;
  }

  // ============================================================================
  // SERIALIZACIÓN
  // ============================================================================

  Map<String, dynamic> _configToJson(MacroCycleConfig config) => {
    'id': config.id,
    'enabled': config.enabled,
    'trainingDayMacros': config.trainingDayMacros.toJson(),
    'restDayMacros': config.restDayMacros.toJson(),
    if (config.fastingDayMacros != null)
      'fastingDayMacros': config.fastingDayMacros!.toJson(),
    'weekdayAssignments': config.weekdayAssignments.map(
      (k, v) => MapEntry(k.toString(), v.name),
    ),
    'createdAt': config.createdAt.toIso8601String(),
    'updatedAt': config.updatedAt.toIso8601String(),
  };

  MacroCycleConfig _configFromJson(Map<String, dynamic> json) {
    final assignments = (json['weekdayAssignments'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(
              int.parse(k),
              DayType.values.firstWhere(
                (d) => d.name == v,
                orElse: () => DayType.rest,
              ),
            ));

    DayMacros? fastingMacros;
    if (json['fastingDayMacros'] != null) {
      fastingMacros = DayMacros.fromJson(
        json['fastingDayMacros'] as Map<String, dynamic>,
      );
    }

    return MacroCycleConfig(
      id: json['id'] as String,
      enabled: json['enabled'] as bool? ?? true,
      trainingDayMacros: DayMacros.fromJson(
        json['trainingDayMacros'] as Map<String, dynamic>,
      ),
      restDayMacros: DayMacros.fromJson(
        json['restDayMacros'] as Map<String, dynamic>,
      ),
      fastingDayMacros: fastingMacros,
      weekdayAssignments: assignments,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
