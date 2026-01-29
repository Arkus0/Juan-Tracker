import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider del modo de tema
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  () => ThemeModeNotifier(),
);

/// Notifier que gestiona el modo de tema
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _loadSavedMode();
    return ThemeMode.system;
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      final mode = ThemeMode.values.firstWhere(
        (e) => e.name == saved,
        orElse: () => ThemeMode.system,
      );
      state = mode;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  void toggle() {
    switch (state) {
      case ThemeMode.system:
        setMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        setMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setMode(ThemeMode.system);
        break;
    }
  }
}
