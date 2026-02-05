import '../entities/app_language.dart';

/// Interfaz para la persistencia del idioma seleccionado
abstract class LanguageRepository {
  /// Obtiene el idioma guardado, o null si no hay ninguno
  AppLanguage? getSavedLanguage();

  /// Guarda el idioma seleccionado
  Future<void> saveLanguage(AppLanguage language);
}
