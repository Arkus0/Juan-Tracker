import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/library_exercise.dart';
import '../providers/exercise_search_providers.dart';

class SearchExerciseScreen extends ConsumerStatefulWidget {
  const SearchExerciseScreen({super.key});

  @override
  ConsumerState<SearchExerciseScreen> createState() =>
      _SearchExerciseScreenState();
}

class _SearchExerciseScreenState extends ConsumerState<SearchExerciseScreen> {
  final TextEditingController _searchController = TextEditingController();

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
    final equipment = ref.watch(availableEquipmentProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('BUSCAR EJERCICIO')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Favoritos'),
                  selected: filters.favoritesOnly,
                  onSelected: (value) =>
                      filtersNotifier.setFavoritesOnly(value),
                ),
                const Spacer(),
                if (filters.favoritesOnly ||
                    (filters.muscleGroup != null &&
                        filters.muscleGroup!.isNotEmpty) ||
                    (filters.equipment != null &&
                        filters.equipment!.isNotEmpty))
                  TextButton(
                    onPressed: filtersNotifier.clear,
                    child: const Text('Limpiar filtros'),
                  ),
              ],
            ),
          ),
          if (muscleGroups.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: muscleGroups.take(8).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final muscle = muscleGroups[index];
                  final isSelected = filters.muscleGroup == muscle;
                  return FilterChip(
                    label: Text(muscle),
                    selected: isSelected,
                    onSelected: (_) => filtersNotifier.setMuscleGroup(
                      isSelected ? null : muscle,
                    ),
                  );
                },
              ),
            ),
          if (equipment.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: equipment.take(8).length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = equipment[index];
                  final isSelected = filters.equipment == item;
                  return FilterChip(
                    label: Text(item),
                    selected: isSelected,
                    onSelected: (_) =>
                        filtersNotifier.setEquipment(isSelected ? null : item),
                  );
                },
              ),
            ),
          Expanded(
            child: resultsAsync.when(
              data: (displayedExercises) {
                if (displayedExercises.isEmpty) {
                  final suggestions =
                      suggestionsAsync.value ?? const <LibraryExercise>[];
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
                        const Text(
                          'NO SE ENCONTRÓ EL EJERCICIO',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (suggestions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            '¿Quisiste decir...?',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ...suggestions.map(
                            (exercise) => Text(
                              exercise.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
                  rows.add(const _SearchRow.header('TOP MATCHES'));
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          row.header!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    final exercise = row.exercise!;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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
