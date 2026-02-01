import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/training/models/library_exercise.dart';
import 'package:juan_tracker/training/models/rutina.dart';
import 'package:juan_tracker/training/models/sesion.dart';
import 'package:juan_tracker/training/models/training_block.dart';
import 'package:juan_tracker/training/providers/create_routine_provider.dart';
import 'package:juan_tracker/training/providers/training_provider.dart';
import 'package:juan_tracker/training/screens/block_edit_screen.dart';
import 'package:juan_tracker/training/screens/create_routine/widgets/biblioteca_bottom_sheet.dart';
import 'package:juan_tracker/training/screens/create_routine/widgets/dia_expansion_tile.dart';
import 'package:juan_tracker/training/services/haptics_controller.dart';
import 'package:juan_tracker/training/services/routine_ocr_service.dart';
import 'package:juan_tracker/training/services/routine_sharing_service.dart';
import 'package:juan_tracker/training/services/voice_input_service.dart';
import 'package:juan_tracker/training/utils/design_system.dart';
import 'package:juan_tracker/training/widgets/routine/block_timeline_widget.dart';
import 'package:juan_tracker/training/widgets/routine/scheduling_config_widget.dart';
import 'package:juan_tracker/training/widgets/routine_import_dialog.dart';
import 'package:juan_tracker/training/widgets/smart_import_sheet.dart';
import 'package:juan_tracker/training/widgets/voice/voice_input_sheet.dart';
import 'package:logger/logger.dart';
import '../../core/design_system/design_system.dart' as core show AppTypography;

class CreateEditRoutineScreen extends ConsumerStatefulWidget {
  final Rutina? rutina; // Null for Create, existing for Edit

  const CreateEditRoutineScreen({super.key, this.rutina});

  @override
  ConsumerState<CreateEditRoutineScreen> createState() =>
      _CreateEditRoutineScreenState();
}

class _CreateEditRoutineScreenState
    extends ConsumerState<CreateEditRoutineScreen> {
  late TextEditingController _nameController;

  /// Flag para saber si ya se guardó la rutina (evitar diálogo al salir después de guardar)
  bool _savedSuccessfully = false;

  /// Estado local del modo Pro para UI (se sincroniza con el provider)
  late bool _isProMode;

  // Stored references for safe disposal without accessing `ref` in dispose
  late final providerContainer = ref.container;
  late final _createRoutineProvider = createRoutineProvider(widget.rutina);

  @override
  void initState() {
    super.initState();
    // 🎯 P2: Nombre por defecto para nuevas rutinas
    final defaultName = widget.rutina?.nombre ?? _generateDefaultName();
    _nameController = TextEditingController(text: defaultName);
    // Inicializar modo Pro desde la rutina existente o false por defecto
    _isProMode = widget.rutina?.isProMode ?? false;
  }

  /// Verifica si hay cambios sin guardar
  /// 🎯 FIX #4: Comparación PROFUNDA para detectar cambios en ejercicios individuales
  bool _hasUnsavedChanges() {
    if (_savedSuccessfully) return false;

    final currentState = ref.read(createRoutineProvider(widget.rutina));

    // Si es nueva rutina, verificar si tiene contenido
    if (widget.rutina == null) {
      // Tiene cambios si: nombre no está vacío Y no es el default, O tiene ejercicios
      final hasExercises = currentState.dias.any(
        (d) => d.ejercicios.isNotEmpty,
      );
      final nameChanged =
          currentState.nombre.isNotEmpty &&
          currentState.nombre != _generateDefaultName();
      return hasExercises || nameChanged;
    }

    // Si es edición, comparar con el original usando comparación PROFUNDA
    final original = widget.rutina!;

    // Comparar nombre de rutina
    if (currentState.nombre != original.nombre) return true;

    // Comparar número de días
    if (currentState.dias.length != original.dias.length) return true;

    // Comparar cada día en detalle
    for (var i = 0; i < currentState.dias.length; i++) {
      final currentDay = currentState.dias[i];
      final originalDay = original.dias[i];

      // Comparar nombre del día
      if (currentDay.nombre != originalDay.nombre) return true;

      // Comparar tipo de progresión del día
      if (currentDay.progressionType != originalDay.progressionType) {
        return true;
      }

      // Comparar número de ejercicios
      if (currentDay.ejercicios.length != originalDay.ejercicios.length) {
        return true;
      }

      // 🎯 FIX #4: Comparación PROFUNDA de cada ejercicio
      for (var j = 0; j < currentDay.ejercicios.length; j++) {
        final currentEx = currentDay.ejercicios[j];
        final originalEx = originalDay.ejercicios[j];

        // Comparar propiedades del ejercicio
        if (currentEx.id != originalEx.id) return true;
        if (currentEx.nombre != originalEx.nombre) return true;
        if (currentEx.series != originalEx.series) return true;
        if (currentEx.repsRange != originalEx.repsRange) return true;
        if (currentEx.notas != originalEx.notas) return true;
        if (currentEx.descansoSugerido != originalEx.descansoSugerido) {
          return true;
        }
        if (currentEx.supersetId != originalEx.supersetId) {
          return true;
        }
        if (currentEx.progressionType != originalEx.progressionType) {
          return true;
        }
        if (currentEx.weightIncrement != originalEx.weightIncrement) {
          return true;
        }
        if (currentEx.targetRpe != originalEx.targetRpe) return true;
      }
    }

    return false;
  }

  /// Muestra diálogo de confirmación antes de salir
  Future<bool> _confirmExit() async {
    if (!_hasUnsavedChanges()) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surfaceContainerHighest,
        title: Text(
          '¿Salir sin guardar?',
          style: core.AppTypography.titleLarge.copyWith(
            color: Theme.of(ctx).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Tienes cambios sin guardar. Si sales ahora, se perderán.',
          style: core.AppTypography.bodyMedium.copyWith(
            color: Theme.of(ctx).colorScheme.onSurface.withAlpha(178),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'SEGUIR EDITANDO',
              style: core.AppTypography.labelLarge.copyWith(
                color: AppColors.neonPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red[400]),
            child: Text(
              'SALIR',
              style: core.AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Genera un nombre por defecto basado en la fecha
  String _generateDefaultName() {
    final now = DateTime.now();
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return 'Rutina ${months[now.month - 1]} ${now.year}';
  }

  @override
  void dispose() {
    // Ensure edit state doesn't leak across future edits. Use stored container
    // and provider to avoid using `ref` while the widget is being unmounted.
    try {
      providerContainer.invalidate(_createRoutineProvider);
    } catch (_) {
      // If invalidation fails (unlikely), ignore — we don't want to crash
    }

    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveRoutine() async {
    final notifier = ref.read(createRoutineProvider(widget.rutina).notifier);

    // Attempt Save
    try {
      final error = await notifier.saveRoutine();

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            backgroundColor: AppColors.neonPrimary,
          ),
        );
        HapticsController.instance.trigger(
          HapticEvent.voiceError,
        ); // Error feedback
        return;
      }

      // Success Feedback
      if (!mounted) return;

      // Marcar como guardado para evitar diálogo de confirmación al salir
      _savedSuccessfully = true;

      // Flash
      final overlay = Overlay.of(context);
      final entry = OverlayEntry(
        builder: (context) {
          return Container(
            color: AppColors.neonPrimaryPressed.withValues(alpha: 0.4),
          );
        },
      );
      overlay.insert(entry);

      // 🎯 RUTINA FORJADA: Vibración fuerte de celebración
      HapticsController.instance.onRoutineForged();

      // SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡RUTINA FORJADA!',
            style: core.AppTypography.headlineMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: AppColors.neonPrimaryPressed,
        ),
      );

      // Wait 300ms for flash then remove and pop
      final navigator = Navigator.of(context);
      await Future.delayed(const Duration(milliseconds: 300));
      entry.remove();

      if (mounted) navigator.pop();
    } catch (e, s) {
      // Unexpected error: show friendly message and log
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error inesperado al guardar: ${e.toString()}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: AppColors.neonPrimary,
        ),
      );
      HapticsController.instance.trigger(
        HapticEvent.voiceError,
      ); // Error feedback
      final logger = Logger();
      logger.e('Unexpected error in _saveRoutine', error: e, stackTrace: s);
      return;
    }
  }

  void _addExercise(int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => BibliotecaBottomSheet(
        onAdd: (LibraryExercise ex) async {
          // 🆕 SmartDefaults: buscar historial antes de añadir
          SmartDefaults? defaults;
          try {
            final repo = ref.read(trainingRepositoryProvider);
            final sessions = await repo.getExpandedHistoryForExercise(
              ex.name,
              limit: 3,
            );
            if (sessions.isNotEmpty) {
              // Calcular series y reps más comunes del historial
              defaults = _calculateSmartDefaults(sessions, ex.name);
            }
          } catch (_) {
            // Si falla, usar defaults normales
          }

          ref
              .read(createRoutineProvider(widget.rutina).notifier)
              .addExerciseToDay(
                dayIndex,
                ex,
                defaultSeries: defaults?.series,
                defaultRepsRange: defaults?.repsRange,
              );
          // 🎯 Vibración suave al añadir ejercicio
          HapticsController.instance.trigger(HapticEvent.buttonTap);
          // Snackbar is now shown inside BibliotecaBottomSheet
        },
        // 🆕 Callback para obtener PR personal
        getPersonalRecord: (exerciseName) async {
          try {
            final repo = ref.read(trainingRepositoryProvider);
            final prs = await repo.getPersonalRecords(
              exerciseNames: [exerciseName],
            );
            return prs.isNotEmpty ? prs.first : null;
          } catch (_) {
            return null;
          }
        },
        // 🆕 Callback para SmartDefaults (usado en preview)
        getSmartDefaults: (exerciseName) async {
          try {
            final repo = ref.read(trainingRepositoryProvider);
            final sessions = await repo.getExpandedHistoryForExercise(
              exerciseName,
              limit: 3,
            );
            if (sessions.isNotEmpty) {
              return _calculateSmartDefaults(sessions, exerciseName);
            }
          } catch (_) {}
          return null;
        },
      ),
    );
  }

  /// 🆕 Calcula SmartDefaults basado en historial del usuario
  SmartDefaults? _calculateSmartDefaults(
    List<Sesion> sessions,
    String exerciseName,
  ) {
    // Recopilar datos de sets del ejercicio
    var totalSeries = 0;
    var sessionCount = 0;
    final repsList = <int>[];

    for (final session in sessions) {
      for (final ejercicio in session.ejerciciosCompletados) {
        if (ejercicio.nombre.toLowerCase() == exerciseName.toLowerCase()) {
          totalSeries += ejercicio.logs.length;
          sessionCount++;
          for (final serie in ejercicio.logs) {
            if (serie.reps > 0) {
              repsList.add(serie.reps);
            }
          }
        }
      }
    }

    if (sessionCount == 0) return null;

    // Series: promedio redondeado
    final avgSeries = (totalSeries / sessionCount).round();

    // Reps: rango min-max o valor único
    if (repsList.isEmpty) {
      return SmartDefaults(series: avgSeries, repsRange: '8-12');
    }

    repsList.sort();
    final minReps = repsList.first;
    final maxReps = repsList.last;

    final repsRange = minReps == maxReps ? '$minReps' : '$minReps-$maxReps';

    return SmartDefaults(series: avgSeries.clamp(1, 10), repsRange: repsRange);
  }

  void _exportRoutine(Rutina rutina) {
    // Validate that routine has content worth exporting
    if (rutina.nombre.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ponle nombre a tu rutina antes de compartir',
            style: core.AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: AppColors.neonPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (rutina.dias.isEmpty ||
        !rutina.dias.any((d) => d.ejercicios.isNotEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Añade ejercicios antes de compartir',
            style: core.AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: AppColors.neonPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticsController.instance.trigger(HapticEvent.buttonTap);
    RoutineSharingService.instance.shareRoutine(rutina);
  }

  /// Importa ejercicios desde imagen usando OCR
  // ignore: unused_element
  void _importFromOcr() {
    final routineState = ref.read(createRoutineProvider(widget.rutina));

    // Verificar que hay al menos un día
    if (routineState.dias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Primero añade un día a tu rutina',
            style: core.AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: AppColors.neonPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Mostrar selector de día si hay más de uno
    final targetDayIndex = routineState.dias.length == 1
        ? 0
        : ref
              .read(createRoutineProvider(widget.rutina).notifier)
              .expandedDayIndex;

    // Si no hay día expandido y hay múltiples días, preguntar
    if (targetDayIndex < 0 && routineState.dias.length > 1) {
      _showDaySelectorForImport();
      return;
    }

    final dayIndex = targetDayIndex < 0 ? 0 : targetDayIndex;

    RoutineImportDialog.show(
      context,
      onConfirm: (candidates) async {
        await _processOcrCandidates(dayIndex, candidates);
      },
    );
  }

  /// Muestra selector de día para importar
  void _showDaySelectorForImport() {
    final routineState = ref.read(createRoutineProvider(widget.rutina));

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿A qué día importar?',
              style: core.AppTypography.titleLarge.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...routineState.dias.asMap().entries.map((entry) {
              final index = entry.key;
              final dia = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.neonPrimary,
                  child: Text(
                    '${index + 1}',
                    style: core.AppTypography.titleLarge.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                ),
                title: Text(
                  dia.nombre,
                  style: core.AppTypography.bodyMedium.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${dia.ejercicios.length} ejercicio${dia.ejercicios.length == 1 ? '' : 's'}',
                  style: core.AppTypography.bodySmall.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface.withAlpha(138),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  RoutineImportDialog.show(
                    context,
                    onConfirm: (candidates) async {
                      await _processOcrCandidates(index, candidates);
                    },
                  );
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Procesa los candidatos de OCR y los añade al día
  Future<void> _processOcrCandidates(
    int dayIndex,
    List<ParsedExerciseCandidate> candidates,
  ) async {
    final ocrService = RoutineOcrService.instance;
    final notifier = ref.read(createRoutineProvider(widget.rutina).notifier);

    final exercises = <LibraryExercise>[];
    final seriesList = <int>[];
    final repsRangeList = <String>[];

    for (final candidate in candidates) {
      if (candidate.matchedExerciseId == null) continue;

      final exercise = await ocrService.getExerciseById(
        candidate.matchedExerciseId!,
      );
      if (exercise != null) {
        exercises.add(exercise);
        seriesList.add(candidate.series);
        repsRangeList.add(candidate.reps.toString());
      }
    }

    if (exercises.isNotEmpty) {
      notifier.addExercisesFromOcr(
        dayIndex,
        exercises,
        seriesList,
        repsRangeList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡${exercises.length} ejercicio${exercises.length == 1 ? '' : 's'} importado${exercises.length == 1 ? '' : 's'}!',
              style: core.AppTypography.labelLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        HapticsController.instance.trigger(
          HapticEvent.inputSubmit,
        ); // Import success
      }
    }
  }

  /// Importa ejercicios usando dictado por voz
  /// Se mantiene para compatibilidad aunque el flujo principal usa _showUnifiedImportSheet
  // ignore: unused_element
  void _importFromVoice() {
    final routineState = ref.read(createRoutineProvider(widget.rutina));

    // Verificar que hay al menos un día
    if (routineState.dias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Primero añade un día a tu rutina',
            style: core.AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: AppColors.neonPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Determinar día objetivo
    final targetDayIndex = routineState.dias.length == 1
        ? 0
        : ref
              .read(createRoutineProvider(widget.rutina).notifier)
              .expandedDayIndex;

    // Si no hay día expandido y hay múltiples días, preguntar
    if (targetDayIndex < 0 && routineState.dias.length > 1) {
      _showDaySelectorForVoice();
      return;
    }

    final dayIndex = targetDayIndex < 0 ? 0 : targetDayIndex;
    _showVoiceInputSheet(dayIndex);
  }

  /// Muestra selector de día para importar por voz
  void _showDaySelectorForVoice() {
    final routineState = ref.read(createRoutineProvider(widget.rutina));

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mic, color: AppColors.neonPrimaryHover),
                const SizedBox(width: 8),
                Text(
                  '¿A qué día añadir?',
                  style: core.AppTypography.titleLarge.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...routineState.dias.asMap().entries.map((entry) {
              final index = entry.key;
              final dia = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.neonPrimary,
                  child: Text(
                    '${index + 1}',
                    style: core.AppTypography.titleLarge.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                ),
                title: Text(
                  dia.nombre,
                  style: core.AppTypography.bodyMedium.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${dia.ejercicios.length} ejercicio${dia.ejercicios.length == 1 ? '' : 's'}',
                  style: core.AppTypography.bodySmall.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurface.withAlpha(138),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showVoiceInputSheet(index);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Muestra el sheet de input por voz
  void _showVoiceInputSheet(int dayIndex) {
    VoiceInputSheet.show(
      context,
      onConfirm: (parsedExercises) async {
        await _processVoiceExercises(dayIndex, parsedExercises);
      },
    );
  }

  /// Procesa los ejercicios del dictado por voz y los añade al día
  Future<void> _processVoiceExercises(
    int dayIndex,
    List<VoiceParsedExercise> parsedExercises,
  ) async {
    final voiceService = VoiceInputService.instance;
    final notifier = ref.read(createRoutineProvider(widget.rutina).notifier);

    final exercises = <LibraryExercise>[];
    final seriesList = <int>[];
    final repsRangeList = <String>[];

    for (final parsed in parsedExercises) {
      if (parsed.matchedId == null) continue;

      final exercise = await voiceService.getExerciseById(parsed.matchedId!);
      if (exercise != null) {
        exercises.add(exercise);
        seriesList.add(parsed.series);
        repsRangeList.add(parsed.repsRange);
      }
    }

    if (exercises.isNotEmpty) {
      // Reutilizamos el método existente de OCR ya que tienen la misma estructura
      notifier.addExercisesFromOcr(
        dayIndex,
        exercises,
        seriesList,
        repsRangeList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '¡${exercises.length} ejercicio${exercises.length == 1 ? '' : 's'} añadido${exercises.length == 1 ? '' : 's'}!',
                  style: core.AppTypography.labelLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        HapticsController.instance.trigger(
          HapticEvent.inputSubmit,
        ); // Import success
      }
    }
  }

  /// 🎯 UX ALTO: Sheet unificado para todas las formas de añadir ejercicios
  void _showUnifiedImportSheet() {
    final routineState = ref.read(createRoutineProvider(widget.rutina));

    // Verificar que hay al menos un día
    if (routineState.dias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Primero añade un día a tu rutina',
            style: core.AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: AppColors.neonPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticsController.instance.trigger(HapticEvent.buttonTap);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurface.withAlpha(138),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'AÑADIR EJERCICIOS',
                style: core.AppTypography.headlineMedium.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              // Opción 1: Biblioteca (principal y más usada)
              _ImportOptionTile(
                icon: Icons.search,
                iconColor: AppColors.neonPrimaryHover,
                title: 'Buscar en Biblioteca',
                subtitle: 'Busca ejercicios por nombre o músculo',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleAddFromLibrary();
                },
              ),
              const SizedBox(height: 12),
              // Opción 2: Smart Import (detecta automático - voz, OCR, texto)
              _ImportOptionTile(
                icon: Icons.auto_awesome,
                iconColor: Colors.amber[400]!,
                title: 'Import Inteligente',
                subtitle: 'Voz, texto, cámara o galería',
                onTap: () {
                  Navigator.pop(ctx);
                  _showSmartImport();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Añade ejercicio desde biblioteca (determina día automáticamente)
  void _handleAddFromLibrary() {
    final routineState = ref.read(createRoutineProvider(widget.rutina));
    final targetDayIndex = routineState.dias.length == 1
        ? 0
        : ref
              .read(createRoutineProvider(widget.rutina).notifier)
              .expandedDayIndex;

    if (targetDayIndex < 0 && routineState.dias.length > 1) {
      // Mostrar selector de día y luego biblioteca
      _showDaySelectorThenLibrary();
    } else {
      _addExercise(targetDayIndex < 0 ? 0 : targetDayIndex);
    }
  }

  /// Selector de día antes de mostrar biblioteca
  void _showDaySelectorThenLibrary() {
    final routineState = ref.read(createRoutineProvider(widget.rutina));

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            '¿A qué día añadir?',
            style: core.AppTypography.titleLarge.copyWith(
              color: Theme.of(ctx).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(routineState.dias.length, (index) {
            final dia = routineState.dias[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.neonPrimary,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                ),
              ),
              title: Text(
                dia.nombre,
                style: core.AppTypography.bodyMedium.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _addExercise(index);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Muestra el sheet de Smart Import (Voz + OCR unificado)
  void _showSmartImport() {
    final routineState = ref.read(createRoutineProvider(widget.rutina));

    // Verificar que hay al menos un día
    if (routineState.dias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Primero añade un día a tu rutina',
            style: core.AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: AppColors.neonPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Determinar día objetivo
    final targetDayIndex = routineState.dias.length == 1
        ? 0
        : ref
              .read(createRoutineProvider(widget.rutina).notifier)
              .expandedDayIndex;

    // Si no hay día expandido y hay múltiples días, preguntar
    if (targetDayIndex < 0 && routineState.dias.length > 1) {
      _showDaySelectorForSmartImport();
      return;
    }

    final dayIndex = targetDayIndex < 0 ? 0 : targetDayIndex;
    _showSmartImportSheet(dayIndex);
  }

  /// Muestra selector de día para smart import
  void _showDaySelectorForSmartImport() {
    final routineState = ref.read(createRoutineProvider(widget.rutina));

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            '¿A qué día añadir ejercicios?',
            style: core.AppTypography.titleLarge.copyWith(
              color: Theme.of(ctx).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(routineState.dias.length, (index) {
            final dia = routineState.dias[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.neonPrimary,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                ),
              ),
              title: Text(
                dia.nombre,
                style: core.AppTypography.bodyMedium.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                '${dia.ejercicios.length} ejercicios',
                style: core.AppTypography.bodySmall.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurface.withAlpha(138),
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showSmartImportSheet(index);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Muestra el sheet de smart import para un día específico
  void _showSmartImportSheet(int dayIndex) {
    SmartImportSheet.show(
      context,
      onConfirm: (importedExercises) async {
        await _processSmartImportExercises(dayIndex, importedExercises);
      },
    );
  }

  /// Procesa los ejercicios del smart import y los añade al día
  Future<void> _processSmartImportExercises(
    int dayIndex,
    List<SmartImportedExercise> importedExercises,
  ) async {
    final voiceService = VoiceInputService.instance;
    final notifier = ref.read(createRoutineProvider(widget.rutina).notifier);

    final exercises = <LibraryExercise>[];
    final seriesList = <int>[];
    final repsRangeList = <String>[];

    for (final imported in importedExercises) {
      if (imported.matchedId == null) continue;

      final exercise = await voiceService.getExerciseById(imported.matchedId!);
      if (exercise != null) {
        exercises.add(exercise);
        seriesList.add(imported.series);
        repsRangeList.add(imported.repsRange);
      }
    }

    if (exercises.isNotEmpty) {
      notifier.addExercisesFromOcr(
        dayIndex,
        exercises,
        seriesList,
        repsRangeList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${exercises.length} ejercicio${exercises.length == 1 ? '' : 's'} importado${exercises.length == 1 ? '' : 's'}',
                  style: core.AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        HapticsController.instance.trigger(
          HapticEvent.inputSubmit,
        ); // Import success
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS MODO PRO (BLOQUES)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Activa/desactiva el modo Pro
  void _toggleProMode() {
    final notifier = ref.read(createRoutineProvider(widget.rutina).notifier);
    notifier.toggleProMode();
    setState(() {
      _isProMode = !_isProMode;
    });
    HapticsController.instance.trigger(HapticEvent.buttonTap);
  }

  /// Navega a la pantalla de creación de bloque
  Future<void> _addBlock() async {
    final routineState = ref.read(createRoutineProvider(widget.rutina));
    final notifier = ref.read(createRoutineProvider(widget.rutina).notifier);

    // Calcular fecha de inicio por defecto (después del último bloque o hoy)
    final defaultStartDate = routineState.blocks.isEmpty
        ? DateTime.now()
        : routineState.blocks
            .map((b) => b.endDate)
            .reduce((a, b) => a.isAfter(b) ? a : b)
            .add(const Duration(days: 1));

    final result = await Navigator.push<TrainingBlock>(
      context,
      MaterialPageRoute(
        builder: (context) => BlockEditScreen(
          defaultStartDate: defaultStartDate,
          existingBlocks: routineState.blocks,
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        notifier.addBlock(result);
        HapticsController.instance.trigger(HapticEvent.inputSubmit);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.toString()}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              backgroundColor: AppColors.neonPrimary,
            ),
          );
        }
      }
    }
  }

  /// Navega a la pantalla de edición de bloque
  Future<void> _editBlock(TrainingBlock block) async {
    final routineState = ref.read(createRoutineProvider(widget.rutina));
    final notifier = ref.read(createRoutineProvider(widget.rutina).notifier);

    final result = await Navigator.push<TrainingBlock>(
      context,
      MaterialPageRoute(
        builder: (context) => BlockEditScreen(
          block: block,
          existingBlocks: routineState.blocks,
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        notifier.updateBlock(result);
        HapticsController.instance.trigger(HapticEvent.inputSubmit);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.toString()}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              backgroundColor: AppColors.neonPrimary,
            ),
          );
        }
      }
    }
  }

  /// Elimina un bloque
  void _deleteBlock(TrainingBlock block) {
    final notifier = ref.read(createRoutineProvider(widget.rutina).notifier);
    notifier.removeBlock(block.id);
    HapticsController.instance.trigger(HapticEvent.buttonTap);
  }

  @override
  Widget build(BuildContext context) {
    final routineState = ref.watch(createRoutineProvider(widget.rutina));
    final notifier = ref.read(createRoutineProvider(widget.rutina).notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmExit();
        if (shouldPop && context.mounted) {
          // Ensure we discard unsaved changes explicitly to avoid accidental saves
          ref
              .read(createRoutineProvider(widget.rutina).notifier)
              .discardChanges();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.rutina == null
                ? 'CREA TU RUTINA'
                : 'EDITAR: ${routineState.nombre.toUpperCase()}',
            style: core.AppTypography.headlineSmall,
          ),
          actions: [
            // 🎯 UX ALTO: Un solo botón Smart Import (consolida voz + OCR + smart)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              tooltip: 'Añadir ejercicios',
              onPressed: _showUnifiedImportSheet,
            ),
            // Export button - only show when editing an existing routine with content
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'export':
                    _exportRoutine(routineState);
                  case 'toggle_pro_mode':
                    _toggleProMode();
                }
              },
              itemBuilder: (ctx) => [
                // Modo Pro toggle
                PopupMenuItem(
                  value: 'toggle_pro_mode',
                  child: Row(
                    children: [
                      Icon(
                        _isProMode ? Icons.science : Icons.science_outlined,
                        size: 20,
                        color: _isProMode ? AppColors.neonPrimary : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isProMode ? 'Desactivar Modo Pro' : 'Activar Modo Pro',
                        style: TextStyle(
                          color: _isProMode ? AppColors.neonPrimary : null,
                          fontWeight: _isProMode ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
                // Exportar rutina (solo si hay contenido)
                if (widget.rutina != null || routineState.dias.isNotEmpty)
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 20),
                        SizedBox(width: 8),
                        Text('Compartir Rutina'),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100), // Space for FAB/Button
          child: Column(
            children: [
              // Routine Name Input
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _nameController,
                  style: core.AppTypography.headlineMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nombre que motive miedo',
                    hintStyle: core.AppTypography.bodyMedium.copyWith(
                      color: AppColors.neonPrimaryPressed.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.neonPrimaryPressed,
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.neonPrimary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (val) => notifier.updateName(val),
                ),
              ),

              // ═════════════════════════════════════════════════════════════════
              // MODO PRO: TIMELINE DE BLOQUES
              // ═════════════════════════════════════════════════════════════════
              if (_isProMode)
                BlockTimelineWidget(
                  blocks: routineState.blocks,
                  activeBlock: routineState.activeBlock,
                  onAddBlock: _addBlock,
                  onEditBlock: _editBlock,
                  onDeleteBlock: _deleteBlock,
                  isEditing: true,
                ),

              // ═════════════════════════════════════════════════════════════════
              // MODO PRO: CONFIGURACIÓN DE SCHEDULING
              // ═════════════════════════════════════════════════════════════════
              if (_isProMode && routineState.dias.isNotEmpty)
                SchedulingConfigWidget(
                  rutina: routineState,
                  onSchedulingChanged: (mode, config) {
                    final notifier = ref.read(_createRoutineProvider.notifier);
                    notifier.updateScheduling(mode, config);
                  },
                  onDayConfigChanged: (dayIndex, weekdays, minRestHours) {
                    final notifier = ref.read(_createRoutineProvider.notifier);
                    notifier.updateDayScheduling(dayIndex, weekdays, minRestHours);
                  },
                ),

              // Days List (Reorderable)
              // Using ReorderableColumn to handle list of Days
              if (routineState.dias.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      'AÑADE TU PRIMER DÍA',
                      style: core.AppTypography.titleLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(61),
                      ),
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  key: ValueKey(routineState.dias.length),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, index, animation) {
                    // Detectamos el inicio del arrastre y colapsamos cualquier día abierto para evitar glitches visuales
                    Future.microtask(() {
                      final notifier = ref.read(
                        createRoutineProvider(widget.rutina).notifier,
                      );
                      if (notifier.expandedDayIndex != -1) {
                        notifier.collapseAllDays();
                      }
                    });

                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Material(
                          elevation: animation.value * 8,
                          color: Colors.transparent,
                          shadowColor: AppColors.neonPrimaryPressed,
                          child: child,
                        );
                      },
                      child: child,
                    );
                  },
                  onReorder: notifier.reorderDays,
                  itemCount: routineState.dias.length,
                  itemBuilder: (context, index) {
                    final dia = routineState.dias[index];
                    return Container(
                      key: Key(dia.id),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: DiaExpansionTile(
                        dayIndex: index,
                        dia: dia,
                        // Ensure this item rebuilds when routine state changes (watch),
                        // but read the notifier to get the UI-only expanded index.
                        initiallyExpanded:
                            ref
                                .read(
                                  createRoutineProvider(widget.rutina).notifier,
                                )
                                .expandedDayIndex ==
                            index,
                        onExpansionChanged: (val) {
                          if (val) {
                            ref
                                .read(
                                  createRoutineProvider(widget.rutina).notifier,
                                )
                                .setExpandedDay(index);
                          } else {
                            ref
                                .read(
                                  createRoutineProvider(widget.rutina).notifier,
                                )
                                .collapseAllDays();
                          }
                        },
                        onUpdateName: (val) =>
                            notifier.updateDayName(index, val),
                        onUpdateProgression: (val) =>
                            notifier.updateDayProgression(index, val),
                        onAddExercise: () => _addExercise(index),
                        onReorderExercises: (oldIdx, newIdx) => notifier
                            .reorderVisualExercises(index, oldIdx, newIdx),
                        onRemoveExercise: (exIdx) =>
                            notifier.removeExercise(index, exIdx),
                        onUndoRemove: (exIdx, ex) =>
                            notifier.insertExercise(index, exIdx, ex),
                        onUpdateExercise: (exIdx, updated) =>
                            notifier.updateExercise(index, exIdx, updated),
                        onReplaceExercise: (exIdx, alternativaNombre) =>
                            notifier.replaceExercise(
                              index,
                              exIdx,
                              alternativaNombre,
                            ),
                        onRemoveDay: () => notifier.removeDay(index),
                        onDuplicateDay: () => notifier.duplicateDay(index),
                        onDuplicateExercise:
                            (exIdx) => // 🆕 Duplicar ejercicio
                                notifier.duplicateExercise(index, exIdx),
                        onCreateSuperset: (idxA, idxB) =>
                            notifier.createSuperset(index, idxA, idxB),
                        onMoveSuperset: (supersetId, toFlat) =>
                            notifier.moveSuperset(index, supersetId, toFlat),
                        onMoveExercise: (fromFlat, toFlat) =>
                            notifier.reorderExercises(index, fromFlat, toFlat),
                        onRemoveFromSuperset: (exIdx) =>
                            notifier.removeFromSuperset(index, exIdx),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // FAB Add Day (Inline or actual FAB? Requirements: "Floating big red FAB... Below list: big red FAB")
              // "Below list: big red FAB 'AÑADIR DÍA'"
              Center(
                child: FloatingActionButton.extended(
                  heroTag: 'add_day_fab',
                  onPressed: () async {
                    HapticsController.instance.trigger(HapticEvent.buttonTap);
                    final selectedName = await _showDayNameSuggestionsDialog(context);
                    if (selectedName != null) {
                      notifier.addDay(suggestedName: selectedName);
                    }
                  },
                  icon: const Icon(Icons.add, size: 32),
                  label: Text(
                    'AÑADIR DÍA',
                    style: core.AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 3,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _saveRoutine,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shadowColor: Theme.of(context).colorScheme.primary,
              elevation: 10,
            ),
            child: Text(
              'GUARDAR RUTINA',
              style: core.AppTypography.headlineSmall.copyWith(
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ), // Close PopScope
    );
  }

  /// 🎯 QW-06: Muestra diálogo con sugerencias de nombres semánticos para días
  Future<String?> _showDayNameSuggestionsDialog(BuildContext context) async {
    final suggestedNames = [
      'Pecho',
      'Espalda',
      'Pierna',
      'Hombros',
      'Brazos',
      'Full Body',
      'Upper',
      'Lower',
      'Push',
      'Pull',
      'Pecho & Tríceps',
      'Espalda & Bíceps',
      'Cuádriceps & Glúteos',
      'Isquios & Pantorrillas',
    ];

    final TextEditingController customController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre del día'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: customController,
              decoration: const InputDecoration(
                labelText: 'Nombre personalizado',
                hintText: 'Ej: Pecho & Tríceps',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Sugerencias:',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestedNames.map((name) => ActionChip(
                label: Text(name),
                onPressed: () {
                  Navigator.of(context).pop(name);
                },
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              final custom = customController.text.trim();
              if (custom.isNotEmpty) {
                Navigator.of(context).pop(custom);
              }
            },
            child: const Text('AÑADIR'),
          ),
        ],
      ),
    );
  }
}

/// Widget reutilizable para opciones de importación
class _ImportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImportOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: core.AppTypography.labelLarge.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: core.AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withAlpha(153)),
            ],
          ),
        ),
      ),
    );
  }
}
