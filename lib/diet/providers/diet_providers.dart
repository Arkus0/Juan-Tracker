// Re-exports para compatibilidad entre providers antiguos y nuevos
// Este archivo centraliza las importaciones que antes vivían en
// lib/diet/providers/diet_providers.dart y evita errores de URI.

// Exportar proveedores nuevos (database_provider contiene la mayoría)
export 'package:juan_tracker/core/providers/database_provider.dart';

// Exportar adaptadores/compatibilidad con el modelo antiguo (solo providers, no tipos)
export 'package:juan_tracker/core/providers/diary_providers.dart' show selectedDayProvider, dayEntriesProvider, dayTotalsProvider;
