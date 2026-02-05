/// Idiomas soportados por la aplicación
enum AppLanguage {
  spanish('es', 'Español', '🇪🇸'),
  english('en', 'English', '🇬🇧');

  const AppLanguage(this.code, this.displayName, this.flag);

  /// Código ISO 639-1
  final String code;

  /// Nombre para mostrar en UI
  final String displayName;

  /// Bandera emoji
  final String flag;

  /// Idioma por defecto (español)
  static const defaultLanguage = AppLanguage.spanish;

  /// Obtiene un AppLanguage por código, o devuelve el default
  static AppLanguage fromCode(String? code) {
    if (code == null) return defaultLanguage;
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => defaultLanguage,
    );
  }
}
