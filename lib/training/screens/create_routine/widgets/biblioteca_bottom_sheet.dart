import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/training/models/analysis_models.dart';
import 'package:juan_tracker/training/models/library_exercise.dart';
import 'package:juan_tracker/training/services/exercise_library_service.dart';
import 'package:juan_tracker/training/services/smart_exercise_search_service.dart';
import 'package:juan_tracker/training/widgets/common/create_exercise_dialog.dart';
import 'package:juan_tracker/training/widgets/exercise_detail_dialog.dart';

/// Modo de búsqueda
enum SearchMode {
  smart, // Búsqueda inteligente por relevancia
  favorites, // Solo favoritos
}

/// 🆕 SmartDefaults: valores sugeridos basados en historial
class SmartDefaults {
  final int series;
  final String repsRange;

  const SmartDefaults({required this.series, required this.repsRange});
}

class BibliotecaBottomSheet extends StatefulWidget {
  final Function(LibraryExercise) onAdd;

  /// Callback opcional para obtener el PR personal de un ejercicio
  final Future<PersonalRecord?> Function(String exerciseName)?
  getPersonalRecord;

  /// 🆕 Callback para obtener SmartDefaults del historial del usuario
  final Future<SmartDefaults?> Function(String exerciseName)? getSmartDefaults;

  const BibliotecaBottomSheet({
    super.key,
    required this.onAdd,
    this.getPersonalRecord,
    this.getSmartDefaults,
  });

  @override
  State<BibliotecaBottomSheet> createState() => _BibliotecaBottomSheetState();
}

class _BibliotecaBottomSheetState extends State<BibliotecaBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  SearchMode _searchMode = SearchMode.smart;
  
  /// Filtros opcionales (se ignoran cuando hay búsqueda de texto)
  String? _filterMuscle;
  String? _filterEquipment;

  /// 🆕 Vista compacta (solo lista) vs grid con imágenes
  bool _compactView = false;

  /// 🆕 Último ejercicio añadido (para sugerencias)
  LibraryExercise? _lastAddedExercise;

  /// 🆕 Sugerencias basadas en el último ejercicio
  List<LibraryExercise> _suggestions = [];

  /// 🆕 Historial de ejercicios añadidos recientemente (máximo 5)
  /// Static para persistir entre aperturas del bottom sheet
  static final List<LibraryExercise> _recentlyAdded = [];

  /// Añade un ejercicio al historial de recientes
  void _addToRecent(LibraryExercise ex) {
    _recentlyAdded.removeWhere((e) => e.id == ex.id);
    _recentlyAdded.insert(0, ex);
    if (_recentlyAdded.length > 5) _recentlyAdded.removeLast();
  }

  /// 🆕 Genera sugerencias de ejercicios complementarios
  void _generateSuggestions(LibraryExercise addedEx) {
    final allExercises =
        ExerciseLibraryService.instance.exercisesNotifier.value;
    final sameMuscle = allExercises
        .where(
          (e) =>
              e.id != addedEx.id &&
              e.muscleGroup.toLowerCase() ==
                  addedEx.muscleGroup.toLowerCase() &&
              !_recentlyAdded.any((r) => r.id == e.id),
        )
        .toList();

    // Mezclar y tomar 3 sugerencias
    sameMuscle.shuffle();
    _suggestions = sameMuscle.take(3).toList();
    _lastAddedExercise = addedEx;
  }





  final List<String> _muscles = [
    'Pecho', 'Espalda', 'Piernas', 'Brazos', 
    'Hombros', 'Abdominales', 'Gemelos', 'Cardio',
  ];
  final List<String> _equipment = [
    'Barra', 'Mancuerna', 'Máquina', 
    'Polea', 'Peso corporal', 'Banco',
  ];

  /// SmartExerciseSearchService para búsqueda inteligente
  final SmartExerciseSearchService _searchService = SmartExerciseSearchService();

  /// Filtra y ordena ejercicios usando el motor de búsqueda inteligente
  List<LibraryExercise> _searchExercises(
    List<LibraryExercise> exercises,
    String query,
  ) {
    // Usar el SmartExerciseSearchService con soporte para sinónimos y fuzzy matching
    final results = _searchService.search(query, exercises, limit: 200);
    return results.map((r) => r.exercise).toList();
  }

  /// Aplica filtros opcionales (solo cuando no hay búsqueda de texto)
  List<LibraryExercise> _applyOptionalFilters(List<LibraryExercise> exercises) {
    // Si hay búsqueda de texto, ignorar filtros para no perder resultados
    if (_query.trim().isNotEmpty) return exercises;
    
    var filtered = exercises;
    
    // Modo favoritos
    if (_searchMode == SearchMode.favorites) {
      filtered = filtered.where((e) => e.isFavorite).toList();
    }
    
    // Filtro de músculo
    if (_filterMuscle != null) {
      final muscleLower = _filterMuscle!.toLowerCase();
      filtered = filtered.where((e) {
        return e.muscleGroup.toLowerCase().contains(muscleLower);
      }).toList();
    }
    
    // Filtro de equipo
    if (_filterEquipment != null) {
      final equipLower = _filterEquipment!.toLowerCase();
      filtered = filtered.where((e) {
        return e.equipment.toLowerCase().contains(equipLower);
      }).toList();
    }
    
    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddedSnackbar(BuildContext context, String exerciseName) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$exerciseName añadido',
          style: AppTypography.labelLarge.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: scheme.surfaceContainerHighest,
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      ),
    );
  }

  void _showCustomExerciseOptions(BuildContext context, LibraryExercise ex) {
    final scheme = Theme.of(context).colorScheme;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              ex.name,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.tertiary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'EJERCICIO PERSONALIZADO',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onTertiary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit, color: scheme.primary),
              title: Text(
                'Editar ejercicio',
                style: TextStyle(color: scheme.onSurface),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await CreateExerciseDialog.show(
                  context,
                  exerciseToEdit: ex,
                );
                if (!context.mounted) return;
                if (result != null && mounted) {
                  setState(() {});
                  _showAddedSnackbar(context, '${result.name} actualizado');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: scheme.error),
              title: Text(
                'Eliminar ejercicio',
                style: TextStyle(color: scheme.onSurface),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('¿ELIMINAR EJERCICIO?'),
                    content: Text(
                      'Se eliminará "${ex.name}" de tu biblioteca. Esta acción no se puede deshacer.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('CANCELAR'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: Text(
                          'ELIMINAR',
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (!context.mounted) return;
                if (confirm == true) {
                  await ExerciseLibraryService.instance.deleteCustomExercise(
                    ex.id,
                  );
                  if (context.mounted && mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${ex.name} eliminado'),
                        backgroundColor: scheme.error,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Abre el dialog de detalles del ejercicio con historial completo.
  /// Usa el nuevo ExerciseDetailDialog que es ConsumerWidget y puede
  /// acceder al historial via Riverpod.
  void _openExerciseDetails(
    BuildContext context,
    LibraryExercise ex,
    bool isCustom,
  ) async {
    HapticFeedback.selectionClick();

    // Obtener PR personal si hay callback
    PersonalRecord? personalRecord;
    if (widget.getPersonalRecord != null) {
      try {
        personalRecord = await widget.getPersonalRecord!(ex.name);
      } catch (_) {
        // Ignorar errores
      }
    }

    if (!context.mounted || !mounted) return;

    final added = await ExerciseDetailDialog.show(
      context,
      exercise: ex,
      personalRecord: personalRecord,
      onAdd: () {
        widget.onAdd(ex);
        _addToRecent(ex);
        _generateSuggestions(ex);
        _showAddedSnackbar(context, ex.name);
      },
      onFavoriteToggle: () async {
        await ExerciseLibraryService.instance.toggleFavorite(ex.id);
        setState(() {});
      },
    );

    // Si se añadió, actualizar UI
    if (added == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Wrap in Scaffold to have its own ScaffoldMessenger for snackbars
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Handle bar con espacio superior generoso
            Container(
              color: scheme.surfaceContainerHighest,
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header con más espacio vertical
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: scheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(Icons.fitness_center, color: scheme.onSurface, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'EJERCICIOS',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Toggle favoritos
                  _HeaderIconButton(
                    icon: _searchMode == SearchMode.favorites 
                      ? Icons.star 
                      : Icons.star_border,
                    color: _searchMode == SearchMode.favorites 
                      ? AppColors.warning 
                      : scheme.onSurfaceVariant,
                    tooltip: 'Solo favoritos',
                    onPressed: () {
                      setState(() {
                        _searchMode = _searchMode == SearchMode.favorites
                          ? SearchMode.smart
                          : SearchMode.favorites;
                      });
                      HapticFeedback.selectionClick();
                    },
                  ),
                  // Toggle vista compacta/grid
                  _HeaderIconButton(
                    icon: _compactView ? Icons.grid_view : Icons.view_list,
                    color: scheme.onSurfaceVariant,
                    tooltip: _compactView ? 'Vista grid' : 'Vista compacta',
                    onPressed: () {
                      setState(() {
                        _compactView = !_compactView;
                      });
                      try {
                        HapticFeedback.selectionClick();
                      } catch (_) {}
                    },
                  ),
                  // Botón crear ejercicio custom
                  _HeaderIconButton(
                    icon: Icons.add_circle,
                    color: scheme.primary,
                    tooltip: 'Crear ejercicio',
                    onPressed: () async {
                      final result = await CreateExerciseDialog.show(context);
                      if (!context.mounted) return;
                      if (result != null && mounted) {
                        HapticFeedback.mediumImpact();
                        _showAddedSnackbar(context, '${result.name} creado');
                      }
                    },
                  ),
                  _HeaderIconButton(
                    icon: Icons.close,
                    color: scheme.onSurfaceVariant,
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search & Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo de búsqueda principal
                  TextField(
                    controller: _searchController,
                    style: AppTypography.bodyLarge.copyWith(color: scheme.onSurface),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
                      suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: scheme.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                      hintText: 'Buscar ejercicio (ej: press banca)...',
                      hintStyle: AppTypography.bodyLarge.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    onChanged: (val) {
                      setState(() => _query = val);
                    },
                  ),
                  
                  // Solo mostrar filtros cuando NO hay búsqueda de texto
                  if (_query.isEmpty) ...[
                    const SizedBox(height: 12),
                    // Filtro por grupo muscular
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Todos',
                            isSelected: _filterMuscle == null,
                            onTap: () => setState(() => _filterMuscle = null),
                          ),
                          ..._muscles.map((m) => _buildFilterChip(
                            label: m,
                            isSelected: _filterMuscle == m,
                            onTap: () => setState(() => 
                              _filterMuscle = _filterMuscle == m ? null : m),
                          )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Filtro por equipo
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _equipment.map((e) => _buildFilterChip(
                          label: e,
                          isSelected: _filterEquipment == e,
                          onTap: () => setState(() => 
                            _filterEquipment = _filterEquipment == e ? null : e),
                        )).toList(),
                      ),
                    ),
                  ] else ...[
                    // Indicador de búsqueda activa
                    const SizedBox(height: 8),
                    Text(
                      'Búsqueda inteligente activa - Los filtros se ignoran',
                      style: AppTypography.labelSmall.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 🆕 Sección: Añadidos recientemente (si no hay búsqueda activa)
            if (_query.isEmpty &&
                _recentlyAdded.isNotEmpty &&
                _searchMode != SearchMode.favorites)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          'RECIENTES',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _recentlyAdded.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final ex = _recentlyAdded[idx];
                          return ActionChip(
                            avatar: Icon(
                              Icons.add,
                              size: 16,
                              color: scheme.primary,
                            ),
                            label: Text(
                              ex.name.length > 20
                                  ? '${ex.name.substring(0, 17)}...'
                                  : ex.name,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            backgroundColor: scheme.surfaceContainerHighest,
                            side: BorderSide(color: scheme.outlineVariant),
                            onPressed: () {
                              try {
                                HapticFeedback.selectionClick();
                              } catch (_) {}
                              widget.onAdd(ex);
                              _showAddedSnackbar(context, ex.name);
                              // Mover al frente del historial
                              _addToRecent(ex);
                              _generateSuggestions(ex);
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Divider(color: scheme.outlineVariant, height: 1),
                  ],
                ),
              ),

            // 🆕 Sección: Sugerencias basadas en último ejercicio añadido
            if (_suggestions.isNotEmpty &&
                _lastAddedExercise != null &&
                _query.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'COMPLEMENTA TU ${_lastAddedExercise!.muscleGroup.toUpperCase()}',
                          style: AppTypography.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _suggestions = [];
                              _lastAddedExercise = null;
                            });
                          },
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final ex = _suggestions[idx];
                          return ActionChip(
                            avatar: Icon(
                              Icons.add,
                              size: 14,
                              color: AppColors.success,
                            ),
                            label: Text(
                              ex.name.length > 18
                                  ? '${ex.name.substring(0, 15)}...'
                                  : ex.name,
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            backgroundColor: AppColors.success.withAlpha(51),
                            side: BorderSide(color: AppColors.success),
                            onPressed: () {
                              try {
                                HapticFeedback.selectionClick();
                              } catch (_) {}
                              widget.onAdd(ex);
                              _addToRecent(ex);
                              _showAddedSnackbar(context, ex.name);
                              _generateSuggestions(ex);
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // List
            Expanded(
              child: ValueListenableBuilder<List<LibraryExercise>>(
                valueListenable:
                    ExerciseLibraryService.instance.exercisesNotifier,
                builder: (context, exercises, _) {
                  // 1. Aplicar filtros opcionales (solo cuando no hay búsqueda)
                  var filtered = _applyOptionalFilters(exercises);
                  
                  // 2. Aplicar búsqueda inteligente con scoring
                  filtered = _searchExercises(filtered, _query);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No se encontraron ejercicios.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    );
                  }

                  // 🆕 Vista compacta (lista) o grid con imágenes
                  if (_compactView) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ex = filtered[index];
                        final isCustom = !ex.isCurated;
                        return Card(
                          color: scheme.surfaceContainerHighest,
                          margin: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    try {
                                      HapticFeedback.selectionClick();
                                    } catch (_) {}
                                    await ExerciseLibraryService.instance
                                        .toggleFavorite(ex.id);
                                    setState(() {});
                                  },
                                  child: Icon(
                                    ex.isFavorite
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: ex.isFavorite
                                        ? AppColors.warning
                                        : scheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                                if (isCustom) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: scheme.tertiary,
                                  ),
                                ],
                              ],
                            ),
                            title: Text(
                              ex.name,
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${ex.muscleGroup} • ${ex.equipment}',
                              style: AppTypography.bodySmall.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: scheme.primary,
                              ),
                              onPressed: () {
                                try {
                                  HapticFeedback.selectionClick();
                                } catch (_) {}
                                widget.onAdd(ex);
                                _addToRecent(ex);
                                _generateSuggestions(ex);
                                _showAddedSnackbar(context, ex.name);
                                setState(() {});
                              },
                            ),
                            onTap: () => _openExerciseDetails(context, ex, isCustom),
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              if (isCustom) {
                                _showCustomExerciseOptions(context, ex);
                              }
                            },
                          ),
                        );
                      },
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ex = filtered[index];
                      final isCustom = !ex.isCurated;
                      return GestureDetector(
                        onTap: () => _openExerciseDetails(context, ex, isCustom),
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          if (isCustom) {
                            _showCustomExerciseOptions(context, ex);
                          }
                        },
                        child: Card(
                          color: scheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCustom
                                  ? scheme.tertiary
                                  : (ex.isFavorite
                                        ? AppColors.warning
                                        : scheme.outlineVariant),
                              width: (ex.isFavorite || isCustom) ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: SizedBox.expand(
                                        child: _buildImage(ex),
                                      ),
                                    ),
                                    // Badge CUSTOM para ejercicios personalizados
                                    if (isCustom)
                                      Positioned(
                                        top: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: scheme.tertiary,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'CUSTOM',
                                            style: AppTypography.labelSmall.copyWith(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: scheme.onTertiary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Favorite star button
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () async {
                                          try {
                                            HapticFeedback.selectionClick();
                                          } catch (_) {}
                                          await ExerciseLibraryService.instance
                                              .toggleFavorite(ex.id);
                                          setState(() {}); // Refresh UI
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: scheme.scrim.withAlpha(140),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            ex.isFavorite
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: ex.isFavorite
                                                ? AppColors.warning
                                                : scheme.onSurface.withAlpha(180),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.name,
                                      style: AppTypography.labelLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: scheme.onSurface,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ex.muscleGroup,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: scheme.primary,
                                    foregroundColor: scheme.onPrimary,
                                    minimumSize: const Size(
                                      double.infinity,
                                      36,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () {
                                    try {
                                      HapticFeedback.selectionClick();
                                    } catch (_) {}
                                    widget.onAdd(ex);
                                    _addToRecent(
                                      ex,
                                    ); // 🆕 Registrar en historial
                                    _generateSuggestions(
                                      ex,
                                    ); // 🆕 Generar sugerencias
                                    _showAddedSnackbar(context, ex.name);
                                    setState(() {});
                                  },
                                  child: const Text('AÑADIR'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: isSelected 
              ? Border.all(color: scheme.primary) 
              : null,
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? scheme.onPrimary : scheme.onSurface.withAlpha(180),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(LibraryExercise ex) {
    final scheme = Theme.of(context).colorScheme;
    if (ex.localImagePath != null && ex.localImagePath!.isNotEmpty) {
      final file = File(ex.localImagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: 120,
          cacheHeight: 120,
          errorBuilder: (ctx, err, stack) => Container(
            color: scheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image,
              color: scheme.onSurfaceVariant.withAlpha(60),
            ),
          ),
        );
      }
    }
    if (ex.imageUrls.isNotEmpty) {
      return Image.network(
        ex.imageUrls.first,
        fit: BoxFit.cover,
        // Cache en memoria para evitar re-descargas
        cacheWidth: 120,
        cacheHeight: 120,
        errorBuilder: (ctx, err, stack) => Container(
          color: scheme.surfaceContainerHighest,
          child: Icon(Icons.broken_image, color: scheme.onSurfaceVariant.withAlpha(60)),
        ),
      );
    }

    return Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.fitness_center, color: scheme.onSurfaceVariant.withAlpha(60)),
    );
  }
}

/// IconButton para el header de la biblioteca - tamaño táctil adecuado
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: color,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onPressed,
      ),
    );
  }
}
