import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/app_language.dart';

/// Modelo que carga y resuelve traducciones desde JSON
///
/// Soporta:
/// - Claves anidadas por dot-notation: "diet.meals.breakfast"
/// - Interpolación de variables: "Hola {{name}}"
/// - Pluralización: "{{count}} día" / "{{count}} días" via claves .one/.other
/// - Fallback automático: si falta key en inglés, usa español
class TranslationsModel {
  final Map<String, dynamic> _translations;
  final Map<String, dynamic>? _fallback;

  TranslationsModel._(this._translations, [this._fallback]);

  /// Carga las traducciones para un idioma desde assets/i18n/{code}.json
  /// Si el idioma no es español, también carga español como fallback
  static Future<TranslationsModel> load(AppLanguage language) async {
    final translations = await _loadJson(language.code);

    Map<String, dynamic>? fallback;
    if (language != AppLanguage.spanish) {
      fallback = await _loadJson(AppLanguage.spanish.code);
    }

    return TranslationsModel._(translations, fallback);
  }

  static Future<Map<String, dynamic>> _loadJson(String code) async {
    final jsonString = await rootBundle.loadString('assets/i18n/$code.json');
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// Obtiene una traducción por clave dot-notation
  ///
  /// [key] - Clave como "diet.meals.breakfast"
  /// [args] - Mapa de variables para interpolación: {"name": "Juan"}
  /// [count] - Para pluralización automática (busca .one/.other)
  String translate(
    String key, {
    Map<String, String>? args,
    int? count,
  }) {
    String? value;

    // Si hay count, intentar pluralización
    if (count != null) {
      final pluralKey = count == 1 ? '$key.one' : '$key.other';
      value = _resolve(pluralKey, _translations);
      value ??= _resolve(pluralKey, _fallback);
    }

    // Intentar clave directa
    value ??= _resolve(key, _translations);

    // Fallback al español
    value ??= _resolve(key, _fallback);

    // Si no se encuentra, devolver la clave
    if (value == null) return key;

    // Interpolación de variables
    if (args != null) {
      for (final entry in args.entries) {
        value = value!.replaceAll('{{${entry.key}}}', entry.value);
      }
    }

    // Interpolar count si está presente
    if (count != null) {
      value = value!.replaceAll('{{count}}', count.toString());
    }

    return value!;
  }

  /// Resuelve una clave dot-notation en un mapa anidado
  String? _resolve(String key, Map<String, dynamic>? map) {
    if (map == null) return null;

    final parts = key.split('.');
    dynamic current = map;

    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current is String ? current : null;
  }
}
