import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/design_system/design_system.dart';
import '../../core/widgets/widgets.dart';
import '../models/detected_exercise_draft.dart';
import '../models/library_exercise.dart';
import '../providers/exercise_search_providers.dart';
import '../providers/exercise_usage_provider.dart';
import '../providers/smart_import_provider.dart';
import '../utils/exercise_colors.dart';
import '../widgets/exercise_detail_dialog.dart';
import '../widgets/common/create_exercise_dialog.dart';
import '../widgets/smart_import_sheet_v2.dart';

class SearchExerciseScreen extends ConsumerStatefulWidget {
  final bool isPickerMode;

  const SearchExerciseScreen({super.key, this.isPickerMode = false});

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
      ref
          .read(exerciseSearchQueryProvider.notifier)
          .setQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onExerciseSelected(LibraryExercise exercise) {
    if (widget.isPickerMode) {
      ref.read(exerciseUsageProvider.notifier).recordUsage(exercise.id);
      Navigator.of(context).pop(exercise);
      return;
    }

    _showExerciseDetails(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = ref.watch(exerciseSearchQueryProvider);
    final filters = ref.watch(exerciseSearchFiltersProvider);
    final filtersNotifier = ref.read(exerciseSearchFiltersProvider.notifier);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.isPickerMode ? 'Seleccionar ejercicio' : 'Biblioteca',
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colorScheme.surface,
          statusBarIconBrightness: colorScheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              _SearchBar(
                controller: _searchController,
                onClear: () {
                  _searchController.clear();
                  ref.read(exerciseSearchQueryProvider.notifier).setQuery('');
                },
              ),

              // Muscle Group Filters
              _MuscleGroupFilters(
                selected: filters.muscleGroup,
                onSelected: (muscle) => filtersNotifier.setMuscleGroup(
                  muscle == filters.muscleGroup ? null : muscle,
                ),
              ),

              // Equipment Filters
              _EquipmentFilters(
                selected: filters.equipment,
                onSelected: (equip) => filtersNotifier.setEquipment(
                  equip == filters.equipment ? null : equip,
                ),
              ),

              // Main Content
              Expanded(
                child: query.isEmpty
                    ? _SmartSectionsContent(onExerciseTap: _onExerciseSelected)
                    : _SearchResultsContent(onExerciseTap: _onExerciseSelected),
              ),
            ],
          ),

          // FAB Menu Overlay
          if (_isFabMenuOpen)
            GestureDetector(
              onTap: () => setState(() => _isFabMenuOpen = false),
              child: Container(
                color: colorScheme.scrim.withAlpha(140),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

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
      floatingActionButton: FloatingActionButton(
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
    );
  }

  void _showManualAddDialog() {
    setState(() => _isFabMenuOpen = false);
    showDialog(
      context: context,
      builder: (ctx) => const CreateExerciseDialog(),
    ).then((exercise) {
      if (exercise != null && mounted) {
        if (widget.isPickerMode) {
          ref.read(exerciseUsageProvider.notifier).recordUsage(exercise.id);
          Navigator.of(context).pop(exercise);
          return;
        }

        AppSnackbar.show(context, message: 'Ejercicio creado en tu biblioteca');
        _showExerciseDetails(exercise);
      }
    });
  }

  void _showSmartImportDialog() {
    setState(() => _isFabMenuOpen = false);
    _openSmartImportSheet(voiceMode: true);
  }

  void _showOcrImportDialog() {
    setState(() => _isFabMenuOpen = false);
    showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Escanear con cámara'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Importar desde galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    ).then((source) {
      if (source != null && mounted) {
        _openSmartImportSheet(ocrSource: source);
      }
    });
  }

  void _openSmartImportSheet({ImageSource? ocrSource, bool voiceMode = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmartImportSheetV2(
        onConfirm: (drafts) {
          unawaited(_handleImportedDrafts(drafts));
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(smartImportProvider.notifier);
      if (ocrSource != null) {
        unawaited(notifier.startOcrImport(ocrSource));
      } else if (voiceMode) {
        unawaited(_startVoiceImportWhenReady());
      }
    });
  }

  Future<void> _startVoiceImportWhenReady() async {
    final notifier = ref.read(smartImportProvider.notifier);

    // SmartImport inicializa voz async en build(); esperamos brevemente
    // para evitar falsos "no disponible" por carrera de inicialización.
    for (var i = 0; i < 15; i++) {
      if (!mounted) return;
      final state = ref.read(smartImportProvider);
      if (state.isVoiceAvailable) {
        await notifier.startVoiceListening();
        return;
      }
      if (state.hasError) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Último intento para que el provider emita error real si aplica.
    await notifier.startVoiceListening();
  }

  Future<void> _handleImportedDrafts(List<DetectedExerciseDraft> drafts) async {
    final importedExercises = await _resolveImportedExercises(drafts);
    if (!mounted) return;

    if (importedExercises.isEmpty) {
      AppSnackbar.showError(
        context,
        message: 'No se pudo resolver ningún ejercicio importado',
      );
      return;
    }

    if (widget.isPickerMode) {
      final selected = await _pickImportedExercise(importedExercises);
      if (selected != null && mounted) {
        ref.read(exerciseUsageProvider.notifier).recordUsage(selected.id);
        Navigator.of(context).pop(selected);
      }
      return;
    }

    _showImportedExercisesSheet(importedExercises);
  }

  Future<List<LibraryExercise>> _resolveImportedExercises(
    List<DetectedExerciseDraft> drafts,
  ) async {
    final notifier = ref.read(smartImportProvider.notifier);
    final resolved = <LibraryExercise>[];

    for (final draft in drafts) {
      final id = draft.currentMatchedId;
      if (id == null) continue;
      final exercise = await notifier.getExerciseById(id);
      if (exercise != null) {
        resolved.add(exercise);
      }
    }

    return resolved;
  }

  Future<LibraryExercise?> _pickImportedExercise(
    List<LibraryExercise> exercises,
  ) async {
    if (exercises.length == 1) return exercises.first;

    return showModalBottomSheet<LibraryExercise>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Selecciona un ejercicio importado')),
            ...exercises.map(
              (exercise) => ListTile(
                title: Text(exercise.name),
                subtitle: Text(exercise.muscleGroup),
                onTap: () => Navigator.of(ctx).pop(exercise),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportedExercisesSheet(List<LibraryExercise> exercises) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text('${exercises.length} ejercicios importados'),
              subtitle: const Text('Toca uno para ver detalles'),
            ),
            ...exercises.map(
              (exercise) => ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(exercise.name),
                subtitle: Text(exercise.muscleGroup),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showExerciseDetails(exercise);
                },
              ),
            ),
          ],
        ),
      ),
    );
    AppSnackbar.show(
      context,
      message: '${exercises.length} ejercicios importados',
    );
  }

  void _showExerciseDetails(LibraryExercise exercise) {
    ExerciseDetailDialog.show(
      context,
      exercise: exercise,
      onAdd: () {
        AppSnackbar.show(
          context,
          message: 'Abre una rutina para añadir este ejercicio',
        );
      },
    );
  }
}

// ==================== WIDGETS ====================

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controller,
        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Buscar ejercicio...',
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              return value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    )
                  : const SizedBox.shrink();
            },
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _MuscleGroupFilters extends ConsumerWidget {
  final String? selected;
  final Function(String?) onSelected;

  const _MuscleGroupFilters({this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleGroups = ref.watch(availableMuscleGroupsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final priorityMuscles = [
      'Pecho',
      'Espalda',
      'Piernas',
      'Hombros',
      'Biceps',
      'Triceps',
      'Core',
    ];

    // muscleGroups es List<String>, no AsyncValue
    final muscles = muscleGroups;
    final sortedMuscles = muscles.toList()
      ..sort((a, b) {
        final aIndex = priorityMuscles.indexOf(a);
        final bIndex = priorityMuscles.indexOf(b);
        if (aIndex != -1 && bIndex != -1) return aIndex.compareTo(bIndex);
        if (aIndex != -1) return -1;
        if (bIndex != -1) return 1;
        return a.compareTo(b);
      });

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sortedMuscles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final muscle = sortedMuscles[index];
          final isSelected = selected == muscle;
          final color = ExerciseColors.forMuscleGroup(muscle);

          return FilterChip(
            selected: isSelected,
            onSelected: (_) => onSelected(muscle),
            backgroundColor: color.withAlpha(30),
            selectedColor: color.withAlpha(100),
            checkmarkColor: color,
            side: BorderSide(color: isSelected ? color : color.withAlpha(50)),
            label: Text(
              muscle,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? color : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _EquipmentFilters extends StatelessWidget {
  final String? selected;
  final Function(String?) onSelected;

  const _EquipmentFilters({this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final equipment = [
      'Barra',
      'Mancuernas',
      'Máquina',
      'Peso corporal',
      'Cable',
    ];
    final icons = {
      'Barra': Icons.linear_scale,
      'Mancuernas': Icons.fitness_center,
      'Máquina': Icons.precision_manufacturing,
      'Peso corporal': Icons.person,
      'Cable': Icons.architecture,
    };

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: equipment.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final equip = equipment[index];
          final isSelected = selected == equip;

          return ActionChip(
            onPressed: () => onSelected(equip),
            backgroundColor: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withAlpha(50),
            ),
            avatar: Icon(
              icons[equip],
              size: 16,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            label: Text(
              equip,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _SmartSectionsContent extends ConsumerWidget {
  final Function(LibraryExercise) onExerciseTap;

  const _SmartSectionsContent({required this.onExerciseTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(smartExerciseSectionsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return sectionsAsync.when(
      data: (sections) {
        if (!sections.hasRecent && !sections.hasPopular) {
          return const _EmptyLibraryView();
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            if (sections.hasRecent) ...[
              _SectionHeader(
                title: 'Usados recientemente',
                icon: Icons.history,
                color: colorScheme.primary,
              ),
              ...sections.recent.map(
                (e) => _ExerciseListTile(
                  exercise: e,
                  onTap: () => onExerciseTap(e),
                  isRecent: true,
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (sections.hasPopular) ...[
              _SectionHeader(
                title: 'Tus favoritos',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              ...sections.popular.map(
                (e) => _ExerciseListTile(
                  exercise: e,
                  onTap: () => onExerciseTap(e),
                  isPopular: true,
                ),
              ),
              const SizedBox(height: 16),
            ],

            _SectionHeader(
              title: 'Todos los ejercicios',
              icon: Icons.list,
              color: colorScheme.onSurfaceVariant,
            ),
            _AllExercisesList(onExerciseTap: onExerciseTap),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _EmptyLibraryView(),
    );
  }
}

class _SearchResultsContent extends ConsumerWidget {
  final Function(LibraryExercise) onExerciseTap;

  const _SearchResultsContent({required this.onExerciseTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(exerciseSearchResultsProvider);
    final suggestionsAsync = ref.watch(exerciseSearchSuggestionsProvider);
    final query = ref.watch(exerciseSearchQueryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return resultsAsync.when(
      data: (exercises) {
        if (exercises.isEmpty) {
          final suggestions = suggestionsAsync.value ?? [];
          return _EmptySearchView(
            query: query,
            suggestions: suggestions,
            onSuggestionTap: onExerciseTap,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: exercises.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            indent: 72,
            color: colorScheme.outline.withAlpha(30),
          ),
          itemBuilder: (context, index) {
            final exercise = exercises[index];
            return _ExerciseListTile(
              exercise: exercise,
              onTap: () => onExerciseTap(exercise),
              query: query,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error: $error',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: AppTypography.labelLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  final LibraryExercise exercise;
  final VoidCallback onTap;
  final String? query;
  final bool isRecent;
  final bool isPopular;

  const _ExerciseListTile({
    required this.exercise,
    required this.onTap,
    this.query,
    this.isRecent = false,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = ExerciseColors.forMuscleGroup(exercise.muscleGroup);
    final icon = ExerciseColors.iconFor(exercise.muscleGroup);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: query?.isNotEmpty == true
          ? _HighlightedText(
              text: exercise.name.toUpperCase(),
              query: query!,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            )
          : Text(
              exercise.name.toUpperCase(),
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              exercise.muscleGroup.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            exercise.equipment,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (isRecent) ...[
            const SizedBox(width: 8),
            Icon(Icons.history, size: 14, color: colorScheme.primary),
          ],
          if (isPopular) ...[
            const SizedBox(width: 8),
            Icon(Icons.star, size: 14, color: AppColors.warning),
          ],
        ],
      ),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.add, color: colorScheme.primary, size: 20),
      ),
      onTap: onTap,
    );
  }
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
    final colorScheme = Theme.of(context).colorScheme;

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: style);
    }

    return RichText(
      text: TextSpan(
        style: style.copyWith(color: colorScheme.onSurface),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: colorScheme.primaryContainer,
              color: colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

class _EmptyLibraryView extends StatelessWidget {
  const _EmptyLibraryView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: colorScheme.onSurfaceVariant.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(
            'Biblioteca vacía',
            style: AppTypography.titleMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Empieza a crear rutinas para ver\ntus ejercicios favoritos aquí',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchView extends StatelessWidget {
  final String query;
  final List<LibraryExercise> suggestions;
  final Function(LibraryExercise) onSuggestionTap;

  const _EmptySearchView({
    required this.query,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: colorScheme.onSurfaceVariant.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text('No se encontró "$query"', style: AppTypography.titleMedium),
            ],
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('¿Quizás quisiste decir?', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          ...suggestions.map(
            (e) =>
                _ExerciseListTile(exercise: e, onTap: () => onSuggestionTap(e)),
          ),
        ],
      ],
    );
  }
}

class _AllExercisesList extends ConsumerWidget {
  final Function(LibraryExercise) onExerciseTap;

  const _AllExercisesList({required this.onExerciseTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return exercisesAsync.when(
      data: (exercises) {
        return Column(
          children: exercises
              .take(30)
              .map(
                (e) => _ExerciseListTile(
                  exercise: e,
                  onTap: () => onExerciseTap(e),
                ),
              )
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

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
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Crear manualmente'),
              onTap: onManualAdd,
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Importar por voz'),
              onTap: onSmartImport,
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Importar por OCR'),
              onTap: onOcrImport,
            ),
          ],
        ),
      ),
    );
  }
}
