/// Providers globales de la aplicación
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../diet/repositories/coach_repository.dart';
import '../../diet/providers/coach_providers.dart';

/// Provider de SharedPreferences (inicializado en main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Debe ser inicializado en main.dart');
});

/// Provider del CoachRepository inicializado
final initializedCoachRepositoryProvider = Provider<CoachRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CoachRepository(prefs);
});

/// Crea los overrides necesarios para ProviderScope
/// Uso: ProviderScope(overrides: getProviderOverrides(prefs), child: ...)
dynamic getProviderOverrides(SharedPreferences prefs) {
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    coachRepositoryProvider.overrideWith((ref) {
      return ref.watch(initializedCoachRepositoryProvider);
    }),
  ];
}
