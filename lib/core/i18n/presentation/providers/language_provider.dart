import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../providers/app_providers.dart';
import '../../data/datasources/language_local_datasource.dart';
import '../../data/repositories/language_repository_impl.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/repositories/language_repository.dart';
import 'translations_provider.dart';

/// Provider del datasource local
final languageLocalDatasourceProvider = Provider<LanguageLocalDatasource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageLocalDatasource(prefs);
});

/// Provider del repositorio de idioma
final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return LanguageRepositoryImpl(ref.watch(languageLocalDatasourceProvider));
});

/// Provider principal del idioma actual
///
/// Gestiona el estado del idioma con persistencia en SharedPreferences.
/// Al cambiar de idioma, invalida automáticamente el translationsProvider
/// para recargar las traducciones.
final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    final repo = ref.watch(languageRepositoryProvider);
    return repo.getSavedLanguage() ?? AppLanguage.defaultLanguage;
  }

  /// Cambia el idioma y persiste la elección
  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;

    final repo = ref.read(languageRepositoryProvider);
    await repo.saveLanguage(language);

    // Inicializar formato de fechas para el nuevo locale
    await initializeDateFormatting(language.code);

    // Invalidar traducciones para recargar JSON
    ref.invalidate(translationsProvider);
  }

  /// Alterna entre español e inglés
  void toggle() {
    final next = state == AppLanguage.spanish
        ? AppLanguage.english
        : AppLanguage.spanish;
    setLanguage(next);
  }
}
