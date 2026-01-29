/// Barrel file para exportar todo el módulo de Diet
///
/// Uso:
/// ```dart
/// import 'package:juan_tracker/diet/diet.dart';
/// ```

// Modelos
export 'models/models.dart';

// Repositorios - Interfaces
export 'repositories/repositories.dart';

// Repositorios - Implementación Drift
export 'repositories/drift_diet_repositories.dart';

// Providers (opcional, solo si usas Riverpod)
export 'providers/diet_providers.dart';
