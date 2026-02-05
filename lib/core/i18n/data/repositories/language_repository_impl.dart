import '../../domain/entities/app_language.dart';
import '../../domain/repositories/language_repository.dart';
import '../datasources/language_local_datasource.dart';

/// Implementación del repositorio de idioma usando SharedPreferences
class LanguageRepositoryImpl implements LanguageRepository {
  final LanguageLocalDatasource _datasource;

  LanguageRepositoryImpl(this._datasource);

  @override
  AppLanguage? getSavedLanguage() => _datasource.getSavedLanguage();

  @override
  Future<void> saveLanguage(AppLanguage language) =>
      _datasource.saveLanguage(language);
}
