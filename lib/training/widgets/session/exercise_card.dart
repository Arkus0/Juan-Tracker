import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snackbar.dart';

import '../../models/ejercicio.dart';
import '../../services/warmup_generator_service.dart';
import '../../models/library_exercise.dart';
import '../../models/progression_engine_models.dart';
import '../../models/serie_log.dart';
import '../../../core/providers/information_density_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/focus_manager_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/training_provider.dart';
import '../../providers/timer_focus_provider.dart';
import '../../services/alternativas_service.dart';
import '../../services/exercise_library_service.dart';
import '../../../core/design_system/design_system.dart';
import '../../widgets/common/alternativas_dialog.dart';
import 'advanced_options_modal.dart';
import 'exercise_swap_bottom_sheet.dart'; // 🆕 Quick Swap
import 'focused_set_row.dart';
import 'progression_suggestion_chip.dart'; // Nuevo chip de sugerencias de progresión
import 'quick_actions_menu.dart'; // QuickActionsMenu for the FAB-style actions
import 'session_modifiers.dart'; // AddSetButton
import 'session_set_row.dart';
import 'series_indicator.dart';
import 'exercise_history_sheet.dart';

typedef IndexedCompletionChanged =
    void Function(int setIndex, {required bool? value});

enum _ExerciseHistoryFillAction { fillEmpty, overwriteAll }

class ExerciseCardContainer extends ConsumerStatefulWidget {
  final int exerciseIndex;

  const ExerciseCardContainer({super.key, required this.exerciseIndex});

  @override
  ConsumerState<ExerciseCardContainer> createState() =>
      _ExerciseCardContainerState();
}

class _ExerciseCardContainerState extends ConsumerState<ExerciseCardContainer> {
  // 🆕 Estado de colapso local - null significa auto (colapsa al completar)
  bool? _manualCollapsedState;

  /// Determina si el ejercicio está colapsado
  bool _isCollapsed(bool allSetsCompleted) {
    // Si el usuario ha tocado manualmente, usar ese estado
    if (_manualCollapsedState != null) {
      return _manualCollapsedState!;
    }
    // Auto-colapsar cuando todas las series están completadas
    return allSetsCompleted;
  }

  void _toggleCollapse() {
    final exercises = ref.read(trainingSessionProvider).exercises;
    if (widget.exerciseIndex < 0 || widget.exerciseIndex >= exercises.length) {
      return;
    }
    final exercise = exercises[widget.exerciseIndex];
    final allCompleted = exercise.logs.every((log) => log.completed);

    setState(() {
      // Toggle basado en el estado actual
      final currentCollapsed = _isCollapsed(allCompleted);
      _manualCollapsedState = !currentCollapsed;
    });
  }

  SerieLog? _getLog(int setIndex) {
    final exercises = ref.read(trainingSessionProvider).exercises;
    if (widget.exerciseIndex < 0 || widget.exerciseIndex >= exercises.length) {
      return null;
    }
    final logs = exercises[widget.exerciseIndex].logs;
    if (setIndex < 0 || setIndex >= logs.length) return null;
    return logs[setIndex];
  }

  void _toggleWarmup(int setIndex) {
    final log = _getLog(setIndex);
    if (log == null) return;
    ref
        .read(trainingSessionProvider.notifier)
        .updateLog(widget.exerciseIndex, setIndex, isWarmup: !log.isWarmup);
  }

  void _toggleFailure(int setIndex) {
    final log = _getLog(setIndex);
    if (log == null) return;
    ref
        .read(trainingSessionProvider.notifier)
        .updateLog(widget.exerciseIndex, setIndex, isFailure: !log.isFailure);
  }

  void _toggleDropset(int setIndex) {
    final log = _getLog(setIndex);
    if (log == null) return;
    ref
        .read(trainingSessionProvider.notifier)
        .updateLog(widget.exerciseIndex, setIndex, isDropset: !log.isDropset);
  }

  void _toggleRestPause(int setIndex) {
    final log = _getLog(setIndex);
    if (log == null) return;
    ref
        .read(trainingSessionProvider.notifier)
        .updateLog(widget.exerciseIndex, setIndex, isRestPause: !log.isRestPause);
  }

  void _toggleMyoReps(int setIndex) {
    final log = _getLog(setIndex);
    if (log == null) return;
    ref
        .read(trainingSessionProvider.notifier)
        .updateLog(widget.exerciseIndex, setIndex, isMyoReps: !log.isMyoReps);
  }

  void _toggleAmrap(int setIndex) {
    final log = _getLog(setIndex);
    if (log == null) return;
    ref
        .read(trainingSessionProvider.notifier)
        .updateLog(widget.exerciseIndex, setIndex, isAmrap: !log.isAmrap);
  }

  void _maybeAutoWarmup(int setIndex, double? weight) {
    if (setIndex != 0) return;
    if (weight == null || weight <= 0) return;

    final settings = ref.read(settingsProvider);
    if (!settings.autoWarmupEnabled) return;
    if (weight <= settings.barWeight) return;

    final exercises = ref.read(trainingSessionProvider).exercises;
    if (widget.exerciseIndex < 0 || widget.exerciseIndex >= exercises.length) {
      return;
    }
    final exercise = exercises[widget.exerciseIndex];
    final primaryMuscle = exercise.musculosPrincipales.isNotEmpty
        ? exercise.musculosPrincipales.first
        : '';
    final isCompound = exercise.musculosPrincipales.length > 1 ||
        exercise.musculosSecundarios.isNotEmpty;
    if (primaryMuscle.isNotEmpty &&
        !WarmupGeneratorService().shouldHaveWarmup(
          primaryMuscle,
          isCompound: isCompound,
        )) {
      return;
    }
    final hasWarmup = exercise.logs.any((log) => log.isWarmup);
    if (hasWarmup) return;

    final warmupSets = WarmupGeneratorService().generateWarmupSets(
      targetWeight: weight,
      barWeight: settings.barWeight,
    );
    if (warmupSets.isEmpty) return;

    final notifier = ref.read(trainingSessionProvider.notifier);
    for (var i = 0; i < warmupSets.length; i++) {
      notifier.insertSetAt(
        exerciseIndex: widget.exerciseIndex,
        setIndex: i,
        weight: warmupSets[i].weight,
        reps: warmupSets[i].reps,
        isWarmup: true,
      );
    }

    if (!mounted) return;
    AppSnackbar.showWithUndo(
      context,
      message: 'Calentamiento automatico: +${warmupSets.length} sets',
      onUndo: () {
        for (var i = 0; i < warmupSets.length; i++) {
          notifier.removeSetFromExercise(widget.exerciseIndex, 0);
        }
      },
    );
  }

  void _showNotesDialog(BuildContext context, String exerciseName) async {
    final repo = ref.read(trainingRepositoryProvider);
    final currentNote = await repo.getNote(exerciseName);

    if (!context.mounted) return;

    final controller = TextEditingController(text: currentNote);
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'COMENTARIOS: ${exerciseName.toUpperCase()}',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText:
                'Ajustes personales del ejercicio (ej. altura del asiento, agarre...)',
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () async {
              await repo.saveNote(exerciseName, controller.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _generateWarmupSets(BuildContext context, Ejercicio exercise) {
    // Obtener el peso de la primera serie como referencia
    final targetWeight = exercise.logs.isNotEmpty
        ? (exercise.logs.first.peso > 0 ? exercise.logs.first.peso : 0.0)
        : 0.0;

    if (targetWeight <= 20) {
      AppSnackbar.show(
        context,
        message: 'Añade primero el peso de trabajo para generar calentamiento',
      );
      return;
    }

    final warmupSets = WarmupGeneratorService().generateWarmupSets(
      targetWeight: targetWeight,
    );

    if (warmupSets.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'No se pueden generar sets de calentamiento',
      );
      return;
    }

    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SETS DE CALENTAMIENTO',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peso objetivo: ${targetWeight.toStringAsFixed(1)}kg',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Se añadirán ${warmupSets.length} sets:',
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: 8),
              ...warmupSets.map((set) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center, size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${set.weight.toStringAsFixed(1)}kg × ${set.reps} reps',
                      style: AppTypography.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      'CALENTAMIENTO',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los sets de calentamiento se insertarán antes del primer set de trabajo y se marcarán como tal.',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            FilledButton.icon(
              onPressed: () {
                final notifier = ref.read(trainingSessionProvider.notifier);
                
                // Insertar sets de calentamiento antes del primer set
                for (var i = 0; i < warmupSets.length; i++) {
                  notifier.insertSetAt(
                    exerciseIndex: widget.exerciseIndex,
                    setIndex: i,
                    weight: warmupSets[i].weight,
                    reps: warmupSets[i].reps,
                    isWarmup: true,
                  );
                }
                
                Navigator.pop(ctx);
                AppSnackbar.show(
                  context,
                  message: '✅ ${warmupSets.length} sets de calentamiento añadidos',
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('AÑADIR'),
            ),
          ],
        );
      },
    );
  }

  void _showExerciseOptions(BuildContext context, Ejercicio exercise) {
    // Convert string ID to int safely
    final libId = int.tryParse(exercise.libraryId);
    final allCompleted =
        exercise.logs.isNotEmpty && exercise.logs.every((log) => log.completed);

    final hasAlternativas =
        libId != null && AlternativasService.instance.hasAlternativas(libId);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final historyLogs = ref
            .read(trainingSessionProvider)
            .history[exercise.historyKey];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  exercise.nombre.toUpperCase(),
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    'Ver Historial',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showHistoryDialog(context, exercise.nombre, historyLogs);
                  },
                ),
                ListTile(
                  leading: Icon(
                    allCompleted ? Icons.undo_rounded : Icons.check_circle,
                    color: allCompleted
                        ? AppColors.textSecondary
                        : AppColors.completedGreen,
                  ),
                  title: Text(
                    allCompleted
                        ? 'Reabrir ejercicio'
                        : 'Marcar ejercicio como completado',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    allCompleted
                        ? 'Vuelve a editar sus series'
                        : 'Marca todas las series como hechas',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref
                        .read(trainingSessionProvider.notifier)
                        .setExerciseCompletion(
                          widget.exerciseIndex,
                          completed: !allCompleted,
                        );
                    AppSnackbar.show(
                      context,
                      message: allCompleted
                          ? 'Ejercicio reabierto'
                          : 'Ejercicio completado',
                      duration: AppSnackbar.shortDuration,
                    );
                  },
                ),
                // 🆕 QUICK SWAP: Sustituir ejercicio en sesión activa
                ListTile(
                  leading: Icon(
                    Icons.swap_horiz,
                    color: libId != null
                        ? AppColors.techCyan
                        : AppColors.textDisabled,
                  ),
                  title: Text(
                    'Sustituir Ejercicio',
                    style: TextStyle(
                      color: libId != null
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    libId != null
                        ? 'Cambiar por alternativa (solo esta sesión)'
                        : 'Ejercicio personalizado - no se puede sustituir',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    if (libId == null) return;

                    Navigator.pop(sheetContext);
                    _showSwapBottomSheet(context, exercise);
                  },
                ),
                // LEGACY: Ver alternativas (información solo)
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: hasAlternativas
                        ? AppColors.textSecondary
                        : AppColors.textDisabled,
                  ),
                  title: Text(
                    'Ver Alternativas (info)',
                    style: TextStyle(
                      color: hasAlternativas
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
                  ),
                  subtitle: Text(
                    hasAlternativas
                        ? 'Ver ejercicios similares'
                        : 'Sin alternativas registradas',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    if (!hasAlternativas) return;

                    Navigator.pop(sheetContext);

                    final libraryExercise = ExerciseLibraryService.instance
                        .getExerciseById(libId);

                    if (libraryExercise == null) {
                      AppSnackbar.showError(
                        context,
                        message: 'No se encontró información del ejercicio',
                      );
                      return;
                    }

                    final allExercises = ExerciseLibraryService
                        .instance
                        .exercises
                        .cast<LibraryExercise>();

                    showAlternativasDialog(
                      context: context,
                      ejercicioOriginal: libraryExercise,
                      allExercises: allExercises,
                      onReplace: (alternativa) {
                        HapticFeedback.selectionClick();
                        AppSnackbar.show(
                          context,
                          message: 'Alternativa: ${alternativa.name}',
                        );
                      },
                    );
                  },
                ),
                // 🆕 WARMUP: Generar sets de calentamiento
                ListTile(
                  leading: Icon(
                    Icons.local_fire_department_outlined,
                    color: libId != null
                        ? Colors.orange
                        : AppColors.textDisabled,
                  ),
                  title: Text(
                    'Generar Calentamiento',
                    style: TextStyle(
                      color: libId != null
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    libId != null
                        ? 'Auto-generar 2-3 sets de calentamiento'
                        : 'Solo para ejercicios de la biblioteca',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    if (libId == null) return;

                    Navigator.pop(sheetContext);
                    _generateWarmupSets(context, exercise);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.note_alt_outlined,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    'Comentarios del ejercicio',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showNotesDialog(context, exercise.nombre);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHistoryDialog(
    BuildContext context,
    String name,
    List<SerieLog>? logs,
  ) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'HISTORIAL: $name',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: logs == null || logs.isEmpty
            ? const Text('No hay datos previos.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ÚLTIMA SESIÓN:',
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...logs.map(
                    (l) => Text(
                      '• ${l.peso}kg x ${l.reps}',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedOptions(BuildContext context, int setIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AdvancedOptionsModal(
            exerciseIndex: widget.exerciseIndex,
            setIndex: setIndex,
          ),
        );
      },
    );
  }

  void _triggerCompletionFeedback(SerieLog current, SerieLog? previous) async {
    // Check for "PR" or better performance
    if (previous != null) {
      var improved = false;
      if (current.peso > previous.peso) improved = true;
      if (current.peso == previous.peso && current.reps > previous.reps) {
        improved = true;
      }

      if (improved) {
        if (mounted) {
          AppSnackbar.show(
            context,
            message: '¡HAS SUPERADO LA SESIÓN ANTERIOR! 🔥',
            duration: AppSnackbar.shortDuration,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt Optimization: Only rebuild this specific card when this exercise changes
    final exercise = ref.watch(
      trainingSessionProvider.select(
        (s) => s.exercises.length > widget.exerciseIndex
            ? s.exercises[widget.exerciseIndex]
            : null,
      ),
    );
    if (exercise == null) return const SizedBox.shrink();

    final historyLogs = ref.watch(
      trainingSessionProvider.select((s) => s.history[exercise.historyKey]),
    );
    final showAdvanced = ref.watch(
      trainingSessionProvider.select((s) => s.showAdvancedOptions),
    );

    // Settings
    final showSupersetIndicator = ref.watch(
      settingsProvider.select((s) => s.showSupersetIndicator),
    );
    final useFocusedInputMode = ref.watch(
      settingsProvider.select((s) => s.useFocusedInputMode),
    );

    // Progression v2: Obtener decisión de progresión para este ejercicio
    final progressionDecision = ref.watch(
      exerciseProgressionProvider(widget.exerciseIndex),
    );

    // Empathetic feedback: mensajes de apoyo para días difíciles
    final empatheticBannerMessage = ref.watch(
      exerciseEmpatheticBannerProvider(widget.exerciseIndex),
    );

    // Auto-focus: detectar si este ejercicio/set debe recibir focus
    // Usa el provider legacy y el nuevo FocusManager
    final focusTarget = ref.watch(timerFinishedFocusProvider);
    final focusManagerTarget = ref.watch(focusManagerProvider).currentTarget;

    // Determinar si este ejercicio debe recibir focus (de cualquiera de los dos sistemas)
    int? focusSetIndexFromManager;
    if (focusManagerTarget != null &&
        focusManagerTarget.exerciseIndex == widget.exerciseIndex) {
      focusSetIndexFromManager = focusManagerTarget.setIndex;
    }

    final notifier = ref.read(trainingSessionProvider.notifier);

    // 🆕 Calcular estado de colapso
    final allSetsCompleted = exercise.logs.every((log) => log.completed);
    final isCollapsed = _isCollapsed(allSetsCompleted);

    return ExerciseCard(
      exerciseIndex: widget.exerciseIndex,
      exercise: exercise,
      historyLogs: historyLogs,
      showAdvanced: showAdvanced,
      showSupersetBadge: showSupersetIndicator && exercise.isInSuperset,
      progressionDecision: progressionDecision,
      empatheticBannerMessage: empatheticBannerMessage,
      focusSetIndex:
          focusSetIndexFromManager ??
          (focusTarget?.exerciseIndex == widget.exerciseIndex
              ? focusTarget?.setIndex
              : null),
      useFocusedInputMode: useFocusedInputMode,
      isCollapsed: isCollapsed,
      onToggleCollapse: _toggleCollapse,
      onShowOptions: () => _showExerciseOptions(context, exercise),
      onUpdateWeight: (setIndex, val) {
        final parsed = double.tryParse(val);
        notifier.updateLog(widget.exerciseIndex, setIndex, peso: parsed);
        _maybeAutoWarmup(setIndex, parsed);
      },
      onUpdateReps: (setIndex, val) => notifier.updateLog(
        widget.exerciseIndex,
        setIndex,
        reps: int.tryParse(val),
      ),
      onUpdateCompleted: (setIndex, {required bool? value}) {
        notifier.updateLog(widget.exerciseIndex, setIndex, completed: value);
        if (value == true) {
          if (setIndex < 0 || setIndex >= exercise.logs.length) {
            return;
          }
          final log = exercise.logs[setIndex];
          final prevLog = (historyLogs != null && setIndex < historyLogs.length)
              ? historyLogs[setIndex]
              : null;
          _triggerCompletionFeedback(log, prevLog);
        }
      },
      onPlateCalc: (setIndex, val) {
        notifier.updateLog(widget.exerciseIndex, setIndex, peso: val);
        _maybeAutoWarmup(setIndex, val);
      },
      onSetLongPress: (setIndex) => _showAdvancedOptions(context, setIndex),
      onRestTimeChange: (seconds) => _updateExerciseRestTime(seconds),
      onUpdateWeightDirect: (setIndex, val) {
        notifier.updateLog(widget.exerciseIndex, setIndex, peso: val);
        _maybeAutoWarmup(setIndex, val);
      },
      onUpdateRepsDirect: (setIndex, val) =>
          notifier.updateLog(widget.exerciseIndex, setIndex, reps: val),
      // 🆕 Quick Actions
      onRepeat: () => _repeatCurrentSet(exercise, historyLogs),
      onHistory: () => _showExpandedHistorySheet(context, exercise),
      onQuickNote: (note) => _addQuickNote(exercise.nombre, note),
      onFillFromHistory:
          (historyLogs == null || historyLogs.isEmpty)
              ? null
              : () => _fillFromHistory(exercise, historyLogs),
      onDuplicateSet: () => _duplicateCurrentSet(exercise),
      onDuplicateSetAt: (setIndex) => _duplicateSetAt(exercise, setIndex),
      dragHandle: _buildDragHandle(),
      // 🆕 ELIMINAR SERIE: Solo afecta sesión activa, no la rutina
      onDeleteSet: (setIndex) => _deleteSet(setIndex),
      onShowWarmup: () => _generateWarmupSets(context, exercise),
      onToggleWarmup: (setIndex) => _toggleWarmup(setIndex),
      onToggleFailure: (setIndex) => _toggleFailure(setIndex),
      onToggleDropset: (setIndex) => _toggleDropset(setIndex),
      onToggleRestPause: (setIndex) => _toggleRestPause(setIndex),
      onToggleMyoReps: (setIndex) => _toggleMyoReps(setIndex),
      onToggleAmrap: (setIndex) => _toggleAmrap(setIndex),
    );
  }

  void _updateExerciseRestTime(int seconds) {
    final notifier = ref.read(trainingSessionProvider.notifier);
    notifier.updateExerciseRestTime(widget.exerciseIndex, seconds);
  }

  /// 🆕 QUICK ACTION: Repetir la serie actual (copiar peso/reps de la anterior)
  void _repeatCurrentSet(Ejercicio exercise, List<SerieLog>? historyLogs) {
    final notifier = ref.read(trainingSessionProvider.notifier);

    // Encontrar la primera serie incompleta
    final firstIncompleteIndex = exercise.logs.indexWhere(
      (log) => !log.completed,
    );
    if (firstIncompleteIndex == -1) return; // Todas completadas

    // Buscar la serie anterior completada para copiar datos
    SerieLog? prevLog;
    if (firstIncompleteIndex > 0) {
      prevLog = exercise.logs[firstIncompleteIndex - 1];
    } else if (historyLogs != null && historyLogs.isNotEmpty) {
      // Usar historial si es la primera serie
      prevLog = historyLogs.first;
    }

    if (prevLog != null) {
      notifier.updateLog(
        widget.exerciseIndex,
        firstIncompleteIndex,
        peso: prevLog.peso,
        reps: prevLog.reps,
      );

      HapticFeedback.mediumImpact();
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'REPITE: ${prevLog.peso}kg × ${prevLog.reps}',
          duration: AppSnackbar.shortDuration,
        );
      }
    }
  }

  /// 🆕 QUICK ACTION: Rellenar ejercicio con la última sesión
  Future<void> _fillFromHistory(Ejercicio exercise, List<SerieLog>? historyLogs) async {
    if (historyLogs == null || historyLogs.isEmpty) {
      if (mounted) {
        AppSnackbar.showWarning(
          context,
          message: 'No hay historial para este ejercicio',
        );
      }
      return;
    }

    final hasInput = exercise.logs.any(
      (log) => log.peso > 0 || log.reps > 0 || log.completed,
    );

    var overwriteExisting = true;
    if (hasInput) {
      final action = await _showFillFromHistoryDialog();
      if (!mounted) return;
      if (action == null) return;
      overwriteExisting = action == _ExerciseHistoryFillAction.overwriteAll;
    }

    final notifier = ref.read(trainingSessionProvider.notifier);
    final setsApplied = notifier.applyHistoryToExercise(
      widget.exerciseIndex,
      overwriteExisting: overwriteExisting,
    );

    if (!mounted) return;

    if (setsApplied == 0) {
      AppSnackbar.showWarning(
        context,
        message: 'No se aplicaron series',
      );
      return;
    }

    AppSnackbar.show(
      context,
      message: 'Rellenado: $setsApplied series',
      duration: AppSnackbar.shortDuration,
    );
  }

  Future<_ExerciseHistoryFillAction?> _showFillFromHistoryDialog() {
    final colors = Theme.of(context).colorScheme;

    return showDialog<_ExerciseHistoryFillAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Rellenar ejercicio',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Ya hay datos en este ejercicio. ¿Cómo quieres aplicar el historial?',
          style: AppTypography.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ExerciseHistoryFillAction.fillEmpty),
            child: const Text('RELLENAR HUECOS'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_ExerciseHistoryFillAction.overwriteAll),
            child: const Text('REEMPLAZAR TODO'),
          ),
        ],
      ),
    );
  }

  /// 🆕 QUICK ACTION: Duplicar la serie actual
  void _duplicateCurrentSet(Ejercicio exercise) {
    final currentSetIndex = exercise.logs.indexWhere((log) => !log.completed);
    final targetIndex = currentSetIndex == -1
        ? (exercise.logs.isEmpty ? 0 : exercise.logs.length - 1)
        : currentSetIndex;

    _duplicateSetAt(exercise, targetIndex);
  }

  void _duplicateSetAt(Ejercicio exercise, int setIndex) {
    final notifier = ref.read(trainingSessionProvider.notifier);
    notifier.duplicateSet(widget.exerciseIndex, setIndex);

    if (mounted) {
      AppSnackbar.showWithUndo(
        context,
        message: 'Serie duplicada',
        onUndo: () {
          notifier.removeSetFromExercise(widget.exerciseIndex, setIndex + 1);
        },
      );
    }
  }

  Widget _buildDragHandle() {
    return ReorderableDragStartListener(
      index: widget.exerciseIndex,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.bgInteractive,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.drag_handle,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showExpandedHistorySheet(BuildContext context, Ejercicio exercise) {
    showExpandedHistorySheet(context, exercise);
  }

  /// 🆕 QUICK ACTION: Añadir nota rápida al ejercicio
  void _addQuickNote(String exerciseName, String note) async {
    final repo = ref.read(trainingRepositoryProvider);

    // Obtener nota existente y añadir la nueva
    final currentNote = await repo.getNote(exerciseName);
    final newNote = currentNote.isNotEmpty ? '$currentNote\n$note' : note;

    await repo.saveNote(exerciseName, newNote);

    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: AppColors.textOnAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nota guardada: $note',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnAccent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  /// 🆕 ELIMINAR SERIE: Solo afecta la sesión activa
  ///
  /// MODELO MENTAL:
  /// - Rutina ≠ Sesión
  /// - La sesión es editable y flexible
  /// - La rutina base (targets) permanece intacta
  /// - Futuros entrenamientos no se ven afectados
  void _deleteSet(int setIndex) {
    final notifier = ref.read(trainingSessionProvider.notifier);
    
    // Guardar datos de la serie antes de eliminar para poder restaurar
    final exercises = ref.read(trainingSessionProvider).exercises;
    SerieLog? deletedLog;
    if (widget.exerciseIndex < exercises.length) {
      final exercise = exercises[widget.exerciseIndex];
      if (setIndex < exercise.logs.length) {
        deletedLog = exercise.logs[setIndex];
      }
    }
    
    notifier.removeSetFromExercise(widget.exerciseIndex, setIndex);

    HapticFeedback.mediumImpact();
    if (mounted) {
      // Duración fija de 1.5s para evitar bugs con snackbars que no desaparecen
      AppSnackbar.show(
        context,
        message: 'Serie ${setIndex + 1} eliminada',
        actionLabel: 'DESHACER',
        onAction: () {
          // Restaurar la serie con sus datos originales
          notifier.insertSetAt(
            exerciseIndex: widget.exerciseIndex,
            setIndex: setIndex,
            weight: deletedLog?.peso ?? 0,
            reps: deletedLog?.reps ?? 0,
          );
        },
        duration: const Duration(milliseconds: 1500),
      );
    }
  }

  /// 🆕 QUICK SWAP: Muestra bottom sheet para sustituir el ejercicio
  void _showSwapBottomSheet(BuildContext context, Ejercicio exercise) {
    final notifier = ref.read(trainingSessionProvider.notifier);

    ExerciseSwapBottomSheet.show(
      context,
      currentExercise: exercise,
      exerciseIndex: widget.exerciseIndex,
      onSwapSelected: (selectedExercise) {
        // Realizar el swap
        notifier.swapExerciseInSession(
          exerciseIndex: widget.exerciseIndex,
          newExercise: selectedExercise,
          preserveCompletedSets: true,
        );

        HapticFeedback.mediumImpact();
        if (mounted) {
          AppSnackbar.show(
            context,
            message: 'Sustituido por: ${selectedExercise.name}',
            duration: AppSnackbar.shortDuration,
          );
        }
      },
    );
  }
}

class ExerciseCard extends ConsumerWidget {
  final int exerciseIndex;
  final Ejercicio exercise;
  final List<SerieLog>? historyLogs;
  final bool showAdvanced;
  final bool showSupersetBadge;
  final ProgressionDecision? progressionDecision; // Decisión de progresión v2
  final String? empatheticBannerMessage; // Mensaje empático para días difíciles
  final int? focusSetIndex; // Set que debe recibir focus (auto-focus del timer)
  final bool useFocusedInputMode; // Usar el nuevo modo de entrada con modal
  final bool isCollapsed; // 🆕 Estado colapsado
  final VoidCallback? onToggleCollapse; // 🆕 Callback para toggle
  final VoidCallback onShowOptions;
  final Function(int, String) onUpdateWeight;
  final Function(int, String) onUpdateReps;
  final IndexedCompletionChanged onUpdateCompleted;
  final Function(int, double) onPlateCalc;
  final Function(int) onSetLongPress;
  final Function(int)? onRestTimeChange;
  final Function(int, double)? onUpdateWeightDirect; // Para FocusedSetRow
  final Function(int, int)? onUpdateRepsDirect; // Para FocusedSetRow
  // 🆕 Quick Actions callbacks
  final VoidCallback? onRepeat; // Copiar peso/reps de serie anterior
  final VoidCallback? onHistory; // Ver historial de 3 últimas sesiones
  final Function(String)? onQuickNote; // Añadir nota rápida
  final VoidCallback? onFillFromHistory; // Rellenar con última sesión
  final VoidCallback? onDuplicateSet; // Duplicar serie actual
  final Function(int)? onDuplicateSetAt; // Duplicar serie específica
  final Widget? dragHandle; // Drag handle para reordenar
  // 🆕 Callback para eliminar serie (solo sesión activa)
  final Function(int)? onDeleteSet;
  // 🆕 Callback para mostrar warm-up (doble-tap en header)
  final VoidCallback? onShowWarmup;
  // 🆕 Quick toggles de tipo de set
  final Function(int)? onToggleWarmup;
  final Function(int)? onToggleFailure;
  final Function(int)? onToggleDropset;
  final Function(int)? onToggleRestPause;
  final Function(int)? onToggleMyoReps;
  final Function(int)? onToggleAmrap;

  const ExerciseCard({
    super.key,
    required this.exerciseIndex,
    required this.exercise,
    required this.historyLogs,
    required this.showAdvanced,
    this.showSupersetBadge = false,
    this.progressionDecision,
    this.empatheticBannerMessage,
    this.focusSetIndex,
    this.useFocusedInputMode = true,
    this.isCollapsed = false,
    this.onToggleCollapse,
    required this.onShowOptions,
    required this.onUpdateWeight,
    required this.onUpdateReps,
    required this.onUpdateCompleted,
    required this.onPlateCalc,
    required this.onSetLongPress,
    this.onRestTimeChange,
    this.onUpdateWeightDirect,
    this.onUpdateRepsDirect,
    this.onRepeat,
    this.onHistory,
    this.onQuickNote,
    this.onFillFromHistory,
    this.onDuplicateSet,
    this.onDuplicateSetAt,
    this.dragHandle,
    this.onDeleteSet,
    this.onShowWarmup,
    this.onToggleWarmup,
    this.onToggleFailure,
    this.onToggleDropset,
    this.onToggleRestPause,
    this.onToggleMyoReps,
    this.onToggleAmrap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(informationDensityProvider);
    final densityValues = DensityValues.forMode(density);
    final restSeconds = exercise.descansoSugeridoSeconds ?? 90;
    final autofocusEnabled = ref.watch(
      settingsProvider.select((s) => s.autofocusEnabled),
    );

    // 🆕 Calcular si todas las series están completadas
    final allSetsCompleted = exercise.logs.every((log) => log.completed);
    final completedSets = exercise.logs.where((log) => log.completed).length;
    final totalSets = exercise.logs.length;
    final historySummary = _formatHistorySummary(historyLogs);
    final prAsync = ref.watch(
      personalRecordForExerciseProvider(exercise.nombre),
    );
    final prRecord = prAsync.asData?.value;

    bool isPrLog(SerieLog log) {
      if (prRecord == null) return false;
      if (!log.completed || log.isWarmup) return false;
      if (log.peso > prRecord.maxWeight) return true;
      if (log.peso == prRecord.maxWeight && log.reps > prRecord.repsAtMax) {
        return true;
      }
      return false;
    }

    // 🎯 NUEVO: Índice de la serie actual (primera incompleta)
    final currentSetIndex = exercise.logs.indexWhere((log) => !log.completed);
    final currentSetNumber = currentSetIndex == -1
        ? totalSets
        : currentSetIndex + 1;
    final isLastSet = currentSetNumber == totalSets && !allSetsCompleted;

    return Card(
      margin: EdgeInsets.only(
        bottom: densityValues.cardMargin,
      ), // Ajustado según densidad
      // Color diferente si está colapsado/completado
      color: isCollapsed && allSetsCompleted
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      child: Semantics(
        button: isCollapsed,
        label: isCollapsed 
            ? 'Ejercicio ${exercise.nombre} completado, tocar para expandir'
            : 'Ejercicio ${exercise.nombre}',
        child: InkWell(
          // Tap en header para colapsar/expandir
          onTap: isCollapsed ? onToggleCollapse : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            // Padding ajustado según densidad
            padding: EdgeInsets.all(
              isCollapsed 
                ? densityValues.cardPadding * 0.875 
                : densityValues.cardPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header siempre visible - diseño en 2 líneas para mejor legibilidad
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: Nombre del ejercicio (nunca cortado)
                    // Doble-tap para warm-up
                    GestureDetector(
                      onTap: onToggleCollapse,
                      onDoubleTap: onShowWarmup,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.neonPrimary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Icono de expansión/colapso
                          AnimatedRotation(
                            turns: isCollapsed ? -0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            size: 22,
                            color: allSetsCompleted
                                ? AppColors.completedGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Nombre con wrap permitido (2 líneas max)
                        Expanded(
                          child: Text(
                            exercise.nombre.toUpperCase(),
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: (isCollapsed ? 16 : 17) + densityValues.fontSizeOffset,
                              fontWeight: FontWeight.w700,
                              color: allSetsCompleted
                                  ? AppColors.completedGreen
                                  : AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2, // 🆕 Permitir 2 líneas
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Check si completado
                        if (allSetsCompleted) ...[
                          SizedBox(width: 8 + densityValues.fontSizeOffset),
                          Icon(
                            Icons.check_circle,
                            size: densityValues.iconSize - 4,
                            color: AppColors.completedGreen,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Fila 2: Indicador de serie + botón acciones (solo si expandido)
                  if (!isCollapsed) ...[
                    if (historySummary != null) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Text(
                          historySummary,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 32), // Alineado con el nombre
                        // Indicador de serie prominente
                        if (!allSetsCompleted)
                          SeriesIndicator(
                            currentSet: currentSetNumber,
                            totalSets: totalSets,
                            completedSets: completedSets,
                            isCollapsed: false,
                            isLastSet: isLastSet,
                          ),
                        const Spacer(),
                        if (dragHandle != null) ...[
                          dragHandle!,
                          const SizedBox(width: 8),
                        ],
                        // Botón acciones rápidas - touch target grande
                        Material(
                          color: AppColors.bgInteractive,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: AppColors.bgElevated,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (sheetContext) {
                                  return SafeArea(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                        top: 16,
                                        bottom:
                                            MediaQuery.of(
                                              sheetContext,
                                            ).viewInsets.bottom +
                                            16,
                                      ),
                                      child: QuickActionsMenu(
                                        currentRestSeconds: restSeconds,
                                        startExpanded: true,
                                        showToggle: false,
                                        onRepeat: () {
                                          Navigator.pop(sheetContext);
                                          onRepeat?.call();
                                        },
                                        onHistory: () {
                                          Navigator.pop(sheetContext);
                                          onHistory?.call();
                                        },
                                        onFillFromHistory: () {
                                          Navigator.pop(sheetContext);
                                          onFillFromHistory?.call();
                                        },
                                        onDuplicateSet: () {
                                          Navigator.pop(sheetContext);
                                          onDuplicateSet?.call();
                                        },
                                        onRestTimeSelected: (s) {
                                          Navigator.pop(sheetContext);
                                          onRestTimeChange?.call(s);
                                        },
                                        onQuickNote: (note) {
                                          Navigator.pop(sheetContext);
                                          onQuickNote?.call(note);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    color: AppColors.bloodRed,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'ACCIONES',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Indicador compacto cuando colapsado
                  if (isCollapsed && !allSetsCompleted) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const SizedBox(width: 32),
                        SeriesIndicator(
                          currentSet: currentSetNumber,
                          totalSets: totalSets,
                          completedSets: completedSets,
                          isCollapsed: true,
                          isLastSet: isLastSet,
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // 🆕 Contenido colapsable con animación
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildExpandedContent(
                  context,
                  restSeconds,
                  autofocusEnabled,
                  isPrLog,
                ),
                crossFadeState: isCollapsed
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _formatHistorySummary(List<SerieLog>? logs) {
    if (logs == null || logs.isEmpty) return null;

    String formatWeight(double value) {
      if (value % 1 == 0) return value.toStringAsFixed(0);
      return value.toStringAsFixed(1);
    }

    final preview = logs.take(3).map((log) {
      return '${formatWeight(log.peso)}×${log.reps}';
    }).join(' · ');
    final suffix = logs.length > 3 ? ' +${logs.length - 3}' : '';

    return 'Última: $preview$suffix';
  }

  /// Contenido expandido del ejercicio (series, etc.)
  Widget _buildExpandedContent(
    BuildContext context,
    int restSeconds,
    bool autofocusEnabled,
    bool Function(SerieLog) isPrLog,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge superset si aplica
        if (showSupersetBadge) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.tertiary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SUPERSET',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onTertiary,
              ),
            ),
          ),
        ],

        // Mensaje empático para días difíciles (si aplica)
        if (empatheticBannerMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              empatheticBannerMessage!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // 🎯 Chip de progresión prominente y accionable (reemplaza el card anterior)
        if (progressionDecision != null) ...[
          const SizedBox(height: 12),
          ProgressionSuggestionChip(
            exerciseIndex: exerciseIndex,
          ),
        ],

        const SizedBox(height: 12),

        // Header Row - solo mostrar si NO es modo focalizado
        if (!useFocusedInputMode)
          const Row(
            children: [
              SizedBox(
                width: 30,
                child: Center(
                  child: Text(
                    '#',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    'PREV',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'KG',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'REPS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Center(
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        if (!useFocusedInputMode) const SizedBox(height: 8),

        // 🎯 REDISEÑO: Usar FocusedSetRow en modo focalizado
        ...List.generate(exercise.logs.length, (setIndex) {
          final log = exercise.logs[setIndex];
          final prevLog =
              (historyLogs != null && setIndex < historyLogs!.length)
              ? historyLogs![setIndex]
              : null;
          final prBadge = isPrLog(log);

          // Determinar si esta serie es la activa (primera incompleta)
          final isFirstIncomplete = exercise.logs
              .take(setIndex)
              .every((l) => l.completed);
          final isActive = !log.completed && isFirstIncomplete;
          final isFuture = !log.completed && !isActive;

          if (useFocusedInputMode) {
            return FocusedSetRow(
              key: ValueKey('ex${exercise.id}_focused_set$setIndex'),
              index: setIndex,
              log: log,
              prevLog: prevLog,
              isActive: isActive,
              isFuture: isFuture,
              exerciseName: exercise.nombre,
              totalSets: exercise.logs.length,
              onWeightChanged: (val) =>
                  onUpdateWeightDirect?.call(setIndex, val),
              onRepsChanged: (val) => onUpdateRepsDirect?.call(setIndex, val),
              onCompleted: (value) => onUpdateCompleted(setIndex, value: value),
              showAdvanced: showAdvanced,
              onLongPress: () => onSetLongPress(setIndex),
              // 🎯 FIX #2: Siempre permite eliminar - si el ejercicio se queda sin series,
              // se elimina de la sesión (pero NO de la rutina base)
              canDelete: true,
              onDelete: () => onDeleteSet?.call(setIndex),
              onToggleWarmup: () => onToggleWarmup?.call(setIndex),
              onToggleFailure: () => onToggleFailure?.call(setIndex),
              onToggleDropset: () => onToggleDropset?.call(setIndex),
              onToggleRestPause: () => onToggleRestPause?.call(setIndex),
              onToggleMyoReps: () => onToggleMyoReps?.call(setIndex),
              onToggleAmrap: () => onToggleAmrap?.call(setIndex),
              showPrBadge: prBadge,
            );
          }

          // 🆕 Fast Logging Parity: Swipe-to-delete en modo tradicional
          return SessionSetRow(
            key: ValueKey('ex${exercise.id}_set$setIndex'),
            index: setIndex,
            log: log,
            prevLog: prevLog,
            onWeightChanged: (val) => onUpdateWeight(setIndex, val),
            onRepsChanged: (val) => onUpdateReps(setIndex, val),
            onCompleted: ({required bool? value}) =>
                onUpdateCompleted(setIndex, value: value),
            onPlateCalc: (val) => onPlateCalc(setIndex, val),
            onLongPress: () => onSetLongPress(setIndex),
            showAdvanced: showAdvanced,
            shouldFocus: autofocusEnabled && focusSetIndex == setIndex,
            canDelete: true,
            onDelete: () => onDeleteSet?.call(setIndex),
            onDuplicate: () => onDuplicateSetAt?.call(setIndex),
            onToggleWarmup: () => onToggleWarmup?.call(setIndex),
            onToggleFailure: () => onToggleFailure?.call(setIndex),
            onToggleDropset: () => onToggleDropset?.call(setIndex),
            onToggleRestPause: () => onToggleRestPause?.call(setIndex),
            onToggleMyoReps: () => onToggleMyoReps?.call(setIndex),
            onToggleAmrap: () => onToggleAmrap?.call(setIndex),
            showPrBadge: prBadge,
          );
        }),

        // 🆕 Botón para añadir series adicionales
        AddSetButton(exerciseIndex: exerciseIndex),
      ],
    );
  }
}
