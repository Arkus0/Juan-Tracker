import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juan_tracker/training/models/analysis_models.dart';
import 'package:juan_tracker/training/models/library_exercise.dart';
import 'package:juan_tracker/training/services/exercise_library_service.dart';
import 'package:juan_tracker/training/widgets/common/create_exercise_dialog.dart';

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

  /// Normaliza texto para búsqueda (sin acentos, minúsculas)
  String _normalize(String input) {
    if (input.trim().isEmpty) return '';
    final lower = input.toLowerCase();
    const accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'ü': 'u', 'ñ': 'n',
    };
    var result = lower;
    accents.forEach((accent, normal) {
      result = result.replaceAll(accent, normal);
    });
    return result.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').trim();
  }

  /// Tokeniza una query en palabras individuales
  List<String> _tokenize(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return [];
    return normalized.split(RegExp(r'\s+')).where((t) => t.length >= 2).toList();
  }

  /// Calcula el score de relevancia de un ejercicio para una query
  /// Retorna 0 si no hay coincidencia, mayor es mejor
  int _calculateScore(LibraryExercise ex, String query, List<String> tokens) {
    final nameNorm = _normalize(ex.name);
    final queryNorm = _normalize(query);
    final muscleNorm = _normalize(ex.muscleGroup);
    final equipmentNorm = _normalize(ex.equipment);
    
    // 1. Coincidencia exacta del nombre completo (100 pts)
    if (nameNorm == queryNorm) return 100;
    
    // 2. El nombre empieza exactamente con la query (95 pts)
    if (nameNorm.startsWith('$queryNorm ')) return 95;
    if (nameNorm.startsWith(queryNorm)) return 90;
    
    // 3. Query está contenida en el nombre como palabra completa (85 pts)
    if (nameNorm.contains(' $queryNorm ')) return 85;
    if (nameNorm.contains(' $queryNorm') || nameNorm.contains('$queryNorm ')) return 80;
    
    // 4. Query contenida en cualquier parte del nombre (70 pts)
    if (nameNorm.contains(queryNorm)) return 70;
    
    // 5. Scoring por tokens (palabras individuales)
    if (tokens.isNotEmpty) {
      final nameTokens = nameNorm.split(RegExp(r'\s+'));
      var matchedTokens = 0;
      var prefixMatches = 0;
      
      for (final token in tokens) {
        // Token exacto en nombre
        if (nameTokens.contains(token)) {
          matchedTokens++;
        } else if (nameNorm.contains(token)) {
          // Token contenido
          matchedTokens++;
        } else {
          // Verificar si alguna palabra del nombre empieza con el token
          for (final nameToken in nameTokens) {
            if (nameToken.startsWith(token) || token.startsWith(nameToken)) {
              prefixMatches++;
              break;
            }
          }
        }
      }
      
      // Todas las palabras coinciden exactamente (75 pts base + bonus)
      if (matchedTokens == tokens.length && tokens.length > 1) {
        return 75 + (tokens.length * 2);
      }
      
      // Todas las palabras coinciden (incluyendo parciales)
      if (matchedTokens + prefixMatches >= tokens.length && tokens.length > 1) {
        return 60 + matchedTokens * 5;
      }
      
      // Algunas palabras coinciden
      if (matchedTokens > 0) {
        return 40 + (matchedTokens * 10);
      }
      
      if (prefixMatches > 0) {
        return 30 + (prefixMatches * 5);
      }
    }
    
    // 6. Coincidencia en grupo muscular (20-40 pts)
    if (muscleNorm.contains(queryNorm)) return 35;
    if (tokens.any((t) => muscleNorm.contains(t))) return 25;
    
    // 7. Coincidencia en equipo (10-30 pts)
    if (equipmentNorm.contains(queryNorm)) return 30;
    if (tokens.any((t) => equipmentNorm.contains(t))) return 20;
    
    // 8. Búsqueda en músculos secundarios
    for (final muscle in ex.muscles) {
      final muscleToken = _normalize(muscle);
      if (muscleToken.contains(queryNorm)) return 25;
      if (tokens.any((t) => muscleToken.contains(t))) return 15;
    }
    
    return 0; // Sin coincidencia
  }

  /// Filtra y ordena ejercicios por relevancia
  List<LibraryExercise> _searchExercises(
    List<LibraryExercise> exercises,
    String query,
  ) {
    if (query.trim().isEmpty) {
      // Sin query: ordenar alfabéticamente
      final result = List<LibraryExercise>.from(exercises);
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return result;
    }
    
    final tokens = _tokenize(query);
    final scored = <_ScoredExercise>[];
    
    for (final ex in exercises) {
      final score = _calculateScore(ex, query, tokens);
      if (score > 0) {
        scored.add(_ScoredExercise(ex, score));
      }
    }
    
    // Ordenar por score descendente, luego por nombre
    scored.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      return a.exercise.name.toLowerCase().compareTo(
        b.exercise.name.toLowerCase(),
      );
    });
    
    return scored.map((s) => s.exercise).toList();
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
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: scheme.surface,
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      ),
    );
  }

  void _showCustomExerciseOptions(BuildContext context, LibraryExercise ex) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
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
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              ex.name,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'EJERCICIO PERSONALIZADO',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue[400]),
              title: const Text(
                'Editar ejercicio',
                style: TextStyle(color: Colors.white),
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
              leading: Icon(Icons.delete, color: Colors.red[400]),
              title: const Text(
                'Eliminar ejercicio',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text(
                      '¿ELIMINAR EJERCICIO?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      'Se eliminará "${ex.name}" de tu biblioteca. Esta acción no se puede deshacer.',
                      style: const TextStyle(color: Colors.white70),
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
                          style: TextStyle(color: Colors.red[400]),
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
                        backgroundColor: Colors.red[700],
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

  /// 🆕 Muestra preview del ejercicio con historial personal
  void _showExercisePreview(BuildContext context, LibraryExercise ex) async {
    final scheme = Theme.of(context).colorScheme;
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

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340, maxHeight: 550),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen grande
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: SizedBox(height: 180, child: _buildImage(ex)),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      ex.name.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // 🆕 Historial personal (PR)
                    if (personalRecord != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber[800]!, Colors.orange[700]!],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: scheme.onSurface,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TU MEJOR: ${personalRecord.maxWeight.toStringAsFixed(1)}kg × ${personalRecord.repsAtMax}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Grupo muscular + equipo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ex.muscleGroup.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ex.equipment,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Músculos detallados
                    if (ex.muscles.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: ex.muscles
                            .map(
                              (m) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  m,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Descripción
                    if (ex.description?.isNotEmpty ?? false)
                      Text(
                        ex.description!,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Botones de acción
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // Favorito toggle
                    IconButton(
                      onPressed: () async {
                        await ExerciseLibraryService.instance.toggleFavorite(
                          ex.id,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                      icon: Icon(
                        ex.isFavorite ? Icons.star : Icons.star_border,
                        color: ex.isFavorite ? Colors.amber : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    // Cerrar
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'CERRAR',
                        style: GoogleFonts.montserrat(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Añadir
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.onAdd(ex);
                        _addToRecent(ex);
                        _generateSuggestions(ex);
                        _showAddedSnackbar(context, ex.name);
                        setState(() {});
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        'AÑADIR',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.library_books, color: scheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    'EJERCICIOS',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  // Toggle favoritos
                  IconButton(
                    icon: Icon(
                      _searchMode == SearchMode.favorites 
                        ? Icons.star 
                        : Icons.star_border,
                      color: _searchMode == SearchMode.favorites 
                        ? Colors.amber 
                        : scheme.onSurface,
                    ),
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
                  // 🆕 Toggle vista compacta/grid
                  IconButton(
                    icon: Icon(
                      _compactView ? Icons.grid_view : Icons.view_list,
                      color: scheme.onSurface,
                    ),
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
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.white),
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search & Filters
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo de búsqueda principal
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                      hintText: 'Buscar ejercicio (ej: press banca)...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
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
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.grey[600],
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
                        Icon(Icons.history, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          'RECIENTES',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
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
                              color: Colors.redAccent[200],
                            ),
                            label: Text(
                              ex.name.length > 20
                                  ? '${ex.name.substring(0, 17)}...'
                                  : ex.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            backgroundColor: Colors.grey[850],
                            side: BorderSide(color: Colors.grey[700]!),
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
                    Divider(color: Colors.grey[800], height: 1),
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
                  color: Colors.green.withValues(alpha: 0.1),
                  border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.green[400],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'COMPLEMENTA TU ${_lastAddedExercise!.muscleGroup.toUpperCase()}',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green[400],
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
                            color: Colors.grey[600],
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
                              color: Colors.green[300],
                            ),
                            label: Text(
                              ex.name.length > 18
                                  ? '${ex.name.substring(0, 15)}...'
                                  : ex.name,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            backgroundColor: Colors.green.withValues(
                              alpha: 0.2,
                            ),
                            side: BorderSide(color: Colors.green[700]!),
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
                        style: TextStyle(color: Colors.grey[600]),
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
                          color: Colors.grey[900],
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
                                        ? Colors.amber
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                ),
                                if (isCustom) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.purple[400],
                                  ),
                                ],
                              ],
                            ),
                            title: Text(
                              ex.name,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${ex.muscleGroup} • ${ex.equipment}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
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
                            onTap: () {
                              try {
                                HapticFeedback.selectionClick();
                              } catch (_) {}
                              widget.onAdd(ex);
                              _addToRecent(ex);
                              _generateSuggestions(ex);
                              _showAddedSnackbar(context, ex.name);
                              setState(() {});
                            },
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              if (isCustom) {
                                _showCustomExerciseOptions(context, ex);
                              } else {
                                _showExercisePreview(context, ex);
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
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          if (isCustom) {
                            _showCustomExerciseOptions(context, ex);
                          } else {
                            _showExercisePreview(
                              context,
                              ex,
                            ); // 🆕 Preview con historial
                          }
                        },
                        child: Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isCustom
                                  ? Colors.purple[400]!
                                  : (ex.isFavorite
                                        ? Colors.amber
                                        : Colors.grey[800]!),
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
                                            color: Colors.purple[700],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'CUSTOM',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: scheme.onSurface,
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
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            ex.isFavorite
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: ex.isFavorite
                                                ? Colors.amber
                                                : Colors.white70,
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
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        color: scheme.onSurface,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ex.muscleGroup,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 12,
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
            color: isSelected ? Colors.redAccent[700] : Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
            border: isSelected 
              ? Border.all(color: Colors.redAccent[400]!) 
              : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(LibraryExercise ex) {
    if (ex.imageUrls.isNotEmpty) {
      return Image.network(
        ex.imageUrls.first,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: Colors.grey[800],
          child: const Icon(Icons.broken_image, color: Colors.white24),
        ),
      );
    }

    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.fitness_center, color: Colors.white24),
    );
  }
}

/// Helper class para scoring
class _ScoredExercise {
  final LibraryExercise exercise;
  final int score;
  
  _ScoredExercise(this.exercise, this.score);
}
