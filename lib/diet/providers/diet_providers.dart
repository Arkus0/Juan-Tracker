// Re-exports para compatibilidad entre providers antiguos y nuevos
// Este archivo centraliza las importaciones que antes vivían en
// lib/diet/providers/diet_providers.dart y evita errores de URI.

// Exportar proveedores nuevos (database_provider contiene la mayoría)
export 'package:juan_tracker/core/providers/database_provider.dart';

// Exportar adaptadores/compatibilidad con el modelo antiguo (solo providers, no tipos)
// MD-002: Añadido mealTotalsProvider para totales memoizados por tipo de comida
export 'package:juan_tracker/core/providers/diary_providers.dart' show 
    selectedDayProvider, 
    dayEntriesProvider, 
    dayTotalsProvider,
    mealTotalsProvider;

// Exportar providers de summary (targets y day summary)
export 'summary_providers.dart';

// Exportar providers de tendencia de peso
export 'weight_trend_providers.dart';
