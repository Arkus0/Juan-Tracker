import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_language.dart';

/// Datasource local para persistencia del idioma vía SharedPreferences
class LanguageLocalDatasource {
  final SharedPreferences _prefs;

  static const _key = 'app_language';

  LanguageLocalDatasource(this._prefs);

  /// Lee el código de idioma guardado
  AppLanguage? getSavedLanguage() {
    final code = _prefs.getString(_key);
    if (code == null) return null;
    return AppLanguage.fromCode(code);
  }

  /// Persiste el código de idioma
  Future<void> saveLanguage(AppLanguage language) async {
    await _prefs.setString(_key, language.code);
  }
}
