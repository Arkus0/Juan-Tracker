import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/step_entry_model.dart';

/// Repositorio de pasos diarios basado en SharedPreferences.
///
/// Almacena un `Map<String, StepEntry>` serializado como JSON.
/// Key de SharedPreferences: `step_entries_v1`
class StepRepository {
  static const _key = 'step_entries_v1';
  final SharedPreferences _prefs;

  StepRepository(this._prefs);

  /// Obtiene todos los registros de pasos.
  Map<String, StepEntry> getAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};

    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) =>
        MapEntry(k, StepEntry.fromJson(v as Map<String, dynamic>)));
  }

  /// Obtiene el registro de pasos para una fecha específica.
  StepEntry? getForDate(DateTime date) {
    final key = _dateKey(date);
    final all = getAll();
    return all[key];
  }

  /// Guarda o actualiza los pasos para una fecha.
  Future<void> save(DateTime date, int steps, {String source = 'manual'}) async {
    final all = getAll();
    final key = _dateKey(date);
    all[key] = StepEntry(dateKey: key, steps: steps, source: source);

    // Limpieza: mantener solo últimos 90 días
    _pruneOldEntries(all);

    await _persist(all);
  }

  /// Suma pasos al conteo existente de la fecha.
  Future<void> addSteps(DateTime date, int additionalSteps) async {
    final current = getForDate(date);
    final newSteps = (current?.steps ?? 0) + additionalSteps;
    await save(date, newSteps);
  }

  /// Elimina el registro de una fecha.
  Future<void> delete(DateTime date) async {
    final all = getAll();
    all.remove(_dateKey(date));
    await _persist(all);
  }

  /// Obtiene los pasos de los últimos N días.
  List<StepEntry> getLastDays(int days) {
    final all = getAll();
    final entries = <StepEntry>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);
      if (all.containsKey(key)) {
        entries.add(all[key]!);
      }
    }

    return entries;
  }

  /// Promedio de pasos en los últimos N días (solo días con registro).
  int averageSteps({int days = 7}) {
    final entries = getLastDays(days);
    if (entries.isEmpty) return 0;
    final total = entries.fold<int>(0, (sum, e) => sum + e.steps);
    return (total / entries.length).round();
  }

  /// Elimina entradas de más de 90 días.
  void _pruneOldEntries(Map<String, StepEntry> all) {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final cutoffKey = _dateKey(cutoff);
    all.removeWhere((key, _) => key.compareTo(cutoffKey) < 0);
  }

  Future<void> _persist(Map<String, StepEntry> all) async {
    final map = all.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString(_key, jsonEncode(map));
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
