import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_template.dart';

class SessionTemplateService {
  static const String _prefsKey = 'session_templates_v1';

  Future<List<SessionTemplate>> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final templates = decoded
          .map((e) => SessionTemplate.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return templates;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTemplate(SessionTemplate template) async {
    final templates = await loadTemplates();
    final existingIndex = templates.indexWhere((t) => t.id == template.id);
    if (existingIndex >= 0) {
      templates[existingIndex] = template;
    } else {
      templates.add(template);
    }
    await _persist(templates);
  }

  Future<void> deleteTemplate(String id) async {
    final templates = await loadTemplates();
    templates.removeWhere((t) => t.id == id);
    await _persist(templates);
  }

  Future<void> renameTemplate(String id, String newName) async {
    final templates = await loadTemplates();
    final index = templates.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final current = templates[index];
    templates[index] = SessionTemplate(
      id: current.id,
      name: newName,
      createdAt: current.createdAt,
      exercises: current.exercises,
    );
    await _persist(templates);
  }

  Future<void> _persist(List<SessionTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(templates.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }
}
