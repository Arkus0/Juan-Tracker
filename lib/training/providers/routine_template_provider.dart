import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/routine_template.dart';
import '../services/routine_template_service.dart';

/// Provider para cargar las plantillas de rutinas
final routineTemplatesProvider = FutureProvider<List<RoutineTemplate>>((ref) async {
  final service = RoutineTemplateService.instance;
  if (!service.isLoaded) {
    await service.init();
  }
  return service.templates;
});

/// Provider para las categorías de plantillas
final templateCategoriesProvider = FutureProvider<List<TemplateCategory>>((ref) async {
  final service = RoutineTemplateService.instance;
  if (!service.isLoaded) {
    await service.init();
  }
  return service.categories;
});

/// Provider para los niveles de plantillas
final templateLevelsProvider = FutureProvider<List<TemplateLevel>>((ref) async {
  final service = RoutineTemplateService.instance;
  if (!service.isLoaded) {
    await service.init();
  }
  return service.levels;
});

/// Notifier para el estado de filtros de plantillas
class TemplateFilterNotifier extends Notifier<TemplateFilterState> {
  @override
  TemplateFilterState build() => const TemplateFilterState();

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId, clearCategory: categoryId == null);
  }

  void setLevel(String? levelId) {
    state = state.copyWith(levelId: levelId, clearLevel: levelId == null);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = const TemplateFilterState();
  }
}

/// Estado de filtros para plantillas
class TemplateFilterState {
  final String? categoryId;
  final String? levelId;
  final String searchQuery;

  const TemplateFilterState({
    this.categoryId,
    this.levelId,
    this.searchQuery = '',
  });

  TemplateFilterState copyWith({
    String? categoryId,
    String? levelId,
    String? searchQuery,
    bool clearCategory = false,
    bool clearLevel = false,
  }) {
    return TemplateFilterState(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      levelId: clearLevel ? null : (levelId ?? this.levelId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasFilters => categoryId != null || levelId != null || searchQuery.isNotEmpty;
}

/// Provider del filtro de plantillas
final templateFilterProvider = NotifierProvider<TemplateFilterNotifier, TemplateFilterState>(
  TemplateFilterNotifier.new,
);

/// Provider de plantillas filtradas
final filteredTemplatesProvider = Provider<AsyncValue<List<RoutineTemplate>>>((ref) {
  final templatesAsync = ref.watch(routineTemplatesProvider);
  final filter = ref.watch(templateFilterProvider);

  return templatesAsync.whenData((templates) {
    var result = templates;

    // Filtrar por búsqueda
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      result = result.where((t) =>
        t.nombre.toLowerCase().contains(query) ||
        t.descripcion.toLowerCase().contains(query)
      ).toList();
    }

    // Filtrar por categoría
    if (filter.categoryId != null) {
      result = result.where((t) => t.categoria == filter.categoryId).toList();
    }

    // Filtrar por nivel
    if (filter.levelId != null) {
      result = result.where((t) => t.nivel == filter.levelId).toList();
    }

    return result;
  });
});

/// Provider para obtener el conteo de plantillas por categoría
final templateCountByCategoryProvider = Provider<Map<String, int>>((ref) {
  final templatesAsync = ref.watch(routineTemplatesProvider);
  return templatesAsync.maybeWhen(
    data: (templates) {
      final counts = <String, int>{};
      for (final template in templates) {
        counts[template.categoria] = (counts[template.categoria] ?? 0) + 1;
      }
      return counts;
    },
    orElse: () => {},
  );
});
