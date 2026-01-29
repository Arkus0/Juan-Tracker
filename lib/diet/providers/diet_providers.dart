/// Providers de Riverpod para la capa de datos y UI de Diet
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/training/database/database.dart';
import 'package:juan_tracker/diet/repositories/repositories.dart';
import 'package:juan_tracker/diet/repositories/drift_diet_repositories.dart';

// ============================================================================
// DATABASE
// ============================================================================

/// Provider de la base de datos Drift
/// Nota: En app real, esto debería ser un singleton proporcionado desde main
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// ============================================================================
// REPOSITORIOS
// ============================================================================

/// Provider del repositorio de alimentos
final foodRepositoryProvider = Provider<IFoodRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftFoodRepository(db);
});

/// Provider del repositorio de diario
final diaryRepositoryProvider = Provider<IDiaryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftDiaryRepository(db);
});

/// Provider del repositorio de pesos
final weighInRepositoryProvider = Provider<IWeighInRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftWeighInRepository(db);
});

/// Provider del repositorio de objetivos
final targetsRepositoryProvider = Provider<ITargetsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  return DriftTargetsRepository(db, diaryRepo);
});

// ============================================================================
// UI PROVIDERS
// ============================================================================

export 'diary_ui_providers.dart';
