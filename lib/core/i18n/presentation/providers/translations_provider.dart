import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/translations_model.dart';
import '../../domain/entities/app_language.dart';
import 'language_provider.dart';

/// Provider de traducciones que carga el JSON según el idioma actual
///
/// Se invalida automáticamente cuando cambia el languageProvider.
/// Uso: ref.watch(translationsProvider) → AsyncValue<TranslationsModel>
final translationsProvider = FutureProvider<TranslationsModel>((ref) async {
  final language = ref.watch(languageProvider);
  return TranslationsModel.load(language);
});

/// Extensión en WidgetRef para acceso rápido a traducciones
extension TranslationRefExtension on WidgetRef {
  /// Traduce una clave. Devuelve la clave si las traducciones no están listas.
  ///
  /// Uso: ref.tr('settings.title')
  /// Con interpolación: ref.tr('greeting.hello', args: {'name': 'Juan'})
  /// Con pluralización: ref.tr('common.daysAgo', count: 3)
  String tr(
    String key, {
    Map<String, String>? args,
    int? count,
  }) {
    final translations = watch(translationsProvider);
    return translations.when(
      data: (t) => t.translate(key, args: args, count: count),
      loading: () => key,
      error: (_, __) => key,
    );
  }
}

/// Extensión en BuildContext para acceso via InheritedWidget-like pattern
/// (requiere un ConsumerWidget o ConsumerStatefulWidget padre)
extension TranslationContextExtension on BuildContext {
  /// Obtiene el locale code actual para DateFormat y similares
  String get localeCode {
    // Este método necesita acceso al WidgetRef, se usa en ConsumerWidgets
    // Para widgets estáticos, usar el default 'es'
    return 'es';
  }
}

/// Helper class estática para acceder a traducciones sin ref
/// Se inicializa una vez que las traducciones están disponibles
class AppTranslations {
  static TranslationsModel? _current;

  /// Actualiza la instancia actual de traducciones
  static void update(TranslationsModel translations) {
    _current = translations;
  }

  /// Obtiene la instancia actual, o null si no se ha inicializado
  static TranslationsModel? get current => _current;

  /// Traduce una clave usando la instancia actual
  /// Devuelve la clave si no hay traducciones cargadas
  static String tr(
    String key, {
    Map<String, String>? args,
    int? count,
  }) {
    return _current?.translate(key, args: args, count: count) ?? key;
  }
}

/// Provider que mantiene sincronizado AppTranslations.current
/// Debe ser watched en el widget raíz (app.dart)
final translationsSyncProvider = Provider<void>((ref) {
  final translations = ref.watch(translationsProvider);
  translations.whenData((t) => AppTranslations.update(t));
});

/// Provider helper para obtener el locale code actual
final localeCodeProvider = Provider<String>((ref) {
  return ref.watch(languageProvider).code;
});
