import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_exercise.dart';
import '../providers/exercise_search_providers.dart';
import '../widgets/common/create_exercise_dialog.dart';

class SearchExerciseScreen extends ConsumerStatefulWidget {
  const SearchExerciseScreen({super.key});

  @override
  ConsumerState<SearchExerciseScreen> createState() =>
      _SearchExerciseScreenState();
}

class _SearchExerciseScreenState extends ConsumerState<SearchExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isFabMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    ref
        .read(exerciseSearchQueryProvider.notifier)
        .setQuery(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(exerciseSearchResultsProvider);
    final suggestionsAsync = ref.watch(exerciseSearchSuggestionsProvider);
    final query = ref.watch(exerciseSearchQueryProvider);
    final filters = ref.watch(exerciseSearchFiltersProvider);
    final filtersNotifier = ref.read(exerciseSearchFiltersProvider.notifier);
    final muscleGroups = ref.watch(availableMuscleGroupsProvider);
    // final equipment = ref.watch(availableEquipmentProvider);

    return Scaffold(
      // AppBar flotante para reducir espacio arriba
      appBar: AppBar(
        title: const Text('BIBLIOTECA'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Barra de búsqueda con menos padding superior
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  onChanged: (value) {
                    ref.read(exerciseSearchQueryProvider.notifier).setQuery(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar ejercicio...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(exerciseSearchQueryProvider.notifier)
                                  .setQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              
              // Filtros compactos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Favoritos'),
                      selected: filters.favoritesOnly,
                      onSelected: (value) =>
                          filtersNotifier.setFavoritesOnly(value),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    if (filters.favoritesOnly ||
                        (filters.muscleGroup != null &&
                            filters.muscleGroup!.isNotEmpty) ||
                        (filters.equipment != null &&
                            filters.equipment!.isNotEmpty))
                      TextButton(
                        onPressed: filtersNotifier.clear,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Limpiar'),
                      ),
                  ],
                ),
              ),
              
              // Chips de grupos musculares
              if (muscleGroups.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: muscleGroups.take(8).length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final muscle = muscleGroups[index];
                      final isSelected = filters.muscleGroup == muscle;
                      return FilterChip(
                        label: Text(muscle),
                        selected: isSelected,
                        onSelected: (_) => filtersNotifier.setMuscleGroup(
                          isSelected ? null : muscle,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    },
                  ),
                ),
              
              // Lista de resultados
              Expanded(
                child: resultsAsync.when(
                  data: (displayedExercises) {
                    if (displayedExercises.isEmpty) {
                      final suggestions =
                          suggestionsAsync.value ?? const <LibraryExercise>[];
                      return _EmptyState(
                        query: query,
                        suggestions: suggestions,
                        onSuggestionTap: (exercise) {
                          Navigator.of(context).pop(exercise);
                        },
                      );
                    }

                    final topMatches = query.trim().isEmpty
                        ? const <LibraryExercise>[]
                        : displayedExercises.take(5).toList();
                    final remaining = query.trim().isEmpty
                        ? displayedExercises
                        : displayedExercises.skip(5).toList();

                    final rows = <_SearchRow>[];
                    if (topMatches.isNotEmpty) {
                      rows.add(const _SearchRow.header('MEJORES COINCIDENCIAS'));
                      rows.addAll(topMatches.map(_SearchRow.exercise));
                    }
                    if (remaining.isNotEmpty) {
                      if (query.trim().isNotEmpty) {
                        rows.add(const _SearchRow.header('RESULTADOS'));
                      }
                      rows.addAll(remaining.map(_SearchRow.exercise));
                    }

                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey[800]),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        if (row.isHeader) {
                          return _SectionHeader(title: row.header!);
                        }

                        final exercise = row.exercise!;
                        return _ExerciseListTile(
                          exercise: exercise,
                          query: query,
                          onTap: () {
                            Navigator.of(context).pop(exercise);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Error al buscar ejercicios: $error',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Menú flotante del FAB
          if (_isFabMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isFabMenuOpen = false),
              child: Container(
                color: Colors.black54,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // FAB menu
          if (_isFabMenuOpen)
            Positioned(
              right: 16,
              bottom: 88,
              child: _FabMenu(
                onManualAdd: _showManualAddDialog,
                onSmartImport: _showSmartImportDialog,
                onOcrImport: _showOcrImportDialog,
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _isFabMenuOpen = !_isFabMenuOpen);
            },
            child: AnimatedRotation(
              turns: _isFabMenuOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualAddDialog() async {
    setState(() => _isFabMenuOpen = false);
    final result = await showDialog<LibraryExercise>(
      context: context,
      builder: (ctx) => const CreateExerciseDialog(),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _showSmartImportDialog() {
    setState(() => _isFabMenuOpen = false);
    // TODO: Implementar smart import desde rutinas/plantillas
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Smart Import: selecciona una rutina para importar ejercicios'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showOcrImportDialog() {
    setState(() => _isFabMenuOpen = false);
    // TODO: Implementar OCR para importar desde imagen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OCR: escanea una imagen de rutina para importar'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Menú flotante del FAB
class _FabMenu extends StatelessWidget {
  final VoidCallback onManualAdd;
  final VoidCallback onSmartImport;
  final VoidCallback onOcrImport;

  const _FabMenu({
    required this.onManualAdd,
    required this.onSmartImport,
    required this.onOcrImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _FabMenuItem(
          icon: Icons.edit,
          label: 'Crear manual',
          onTap: onManualAdd,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _FabMenuItem(
          icon: Icons.auto_fix_high,
          label: 'Smart Import',
          onTap: onSmartImport,
          color: colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        _FabMenuItem(
          icon: Icons.document_scanner,
          label: 'OCR (imagen)',
          onTap: onOcrImport,
          color: colorScheme.tertiary,
        ),
      ],
    );
  }
}

/// Item del menú FAB
class _FabMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _FabMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.3 * 255).round()),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          onPressed: onTap,
          backgroundColor: color,
          heroTag: label,
          child: Icon(icon, color: Colors.white),
        ),
      ],
    );
  }
}

/// Estado vacío con sugerencias
class _EmptyState extends StatelessWidget {
  final String query;
  final List<LibraryExercise> suggestions;
  final ValueChanged<LibraryExercise> onSuggestionTap;

  const _EmptyState({
    required this.query,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.grey[800],
          ),
          const SizedBox(height: 16),
          Text(
            'NO SE ENCONTRÓ EL EJERCICIO',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '¿Quisiste decir...?',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            ...suggestions.map(
              (exercise) => InkWell(
                onTap: () => onSuggestionTap(exercise),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    exercise.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Header de sección
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Tile de ejercicio
class _ExerciseListTile extends StatelessWidget {
  final LibraryExercise exercise;
  final String query;
  final VoidCallback onTap;

  const _ExerciseListTile({
    required this.exercise,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      title: _HighlightedText(
        text: exercise.name.toUpperCase(),
        query: query,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              exercise.muscleGroup.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            exercise.equipment,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.add_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: onTap,
    );
  }
}

class _SearchRow {
  final String? header;
  final LibraryExercise? exercise;

  const _SearchRow._({this.header, this.exercise});

  const _SearchRow.header(String header) : this._(header: header);

  const _SearchRow.exercise(LibraryExercise exercise)
    : this._(exercise: exercise);

  bool get isHeader => header != null;
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final tokens = normalizedQuery
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toList();

    if (tokens.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final pattern = RegExp(
      tokens.map(RegExp.escape).join('|'),
      caseSensitive: false,
    );
    final matches = pattern.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final highlightStyle = style.copyWith(
      color: Theme.of(context).colorScheme.primary,
    );

    final spans = <TextSpan>[];
    var lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(text: text.substring(lastIndex, match.start), style: style),
        );
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: highlightStyle,
        ),
      );
      lastIndex = match.end;
    }
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: style));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
