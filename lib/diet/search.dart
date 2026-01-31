// Exporta todo el sistema de búsqueda refactorizado
// 
// Uso:
// ```dart
// import 'package:juan_tracker/diet/search.dart';
// ```

// Domain
export 'domain/repositories/food_search_repository.dart';
export 'domain/services/food_scoring_service.dart';

// Data - Models
export 'data/models/cached_search_result.dart';

// Data - Datasources (interfaces e implementaciones)
export 'data/datasources/food_search_local_datasource.dart';
export 'data/datasources/food_search_remote_datasource.dart';

// Data - Repositories
export 'data/repositories/food_search_repository_impl.dart';

// Data - Services
export 'data/services/food_scoring_service_impl.dart';

// Presentation - Providers
export 'presentation/providers/food_search_provider.dart';
