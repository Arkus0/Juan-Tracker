import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snackbar.dart';

import '../../models/ejercicio.dart';
import '../../models/library_exercise.dart';
import '../../models/progression_engine_models.dart';
import '../../models/serie_log.dart';
import '../../../core/providers/information_density_provider.dart';
import '../../providers/exercise_history_provider.dart';
import '../../providers/focus_manager_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/training_provider.dart';
import '../../screens/training_session_screen.dart';
import '../../services/alternativas_service.dart';
import '../../services/exercise_library_service.dart';
import '../../../core/design_system/design_system.dart' show AppTypography;
import '../../utils/design_system.dart' show AppColors;
import '../../widgets/common/alternativas_dialog.dart';
import 'advanced_options_modal.dart';
import 'focused_set_row.dart';
import 'progression_suggestion_chip.dart'; // Nuevo chip de sugerencias de progresión
import 'quick_actions_menu.dart'; // QuickActionsMenu for the FAB-style actions
import 'session_modifiers.dart'; // AddSetButton
import 'session_set_row.dart';

typedef IndexedCompletionChanged =
    void Function(int setIndex, {required bool? value});

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
          'NOTAS: ${exerciseName.toUpperCase()}',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText:
                'Escribe notas importantes para este ejercicio (ej. altura del asiento, agarre...)',
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

  void _showExerciseOptions(BuildContext context, Ejercicio exercise) {
    // Convert string ID to int safely
    final libId = int.tryParse(exercise.libraryId);

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
                    Icons.swap_horiz,
                    color: hasAlternativas
                        ? AppColors.techCyan
                        : AppColors.textDisabled,
                  ),
                  title: Text(
                    'Ver Alternativas',
                    style: TextStyle(
                      color: hasAlternativas
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
                  ),
                  subtitle: Text(
                    hasAlternativas
                        ? 'Ejercicios similares disponibles'
                        : 'Sin alternativas registradas',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    if (!hasAlternativas) return;

                    Navigator.pop(sheetContext);

                    // Resolve LibraryExercise object
                    final libraryExercise = ExerciseLibraryService.instance
                        .getExerciseById(libId);

                    if (libraryExercise == null) {
                      AppSnackbar.showError(
                        context,
                        message: 'No se encontró información del ejercicio en la biblioteca',
                      );
                      return;
                    }

                    // Get full list for service
                    final allExercises = ExerciseLibraryService
                        .instance
                        .exercises
                        .cast<LibraryExercise>();

                    showAlternativasDialog(
                      context: context,
                      ejercicioOriginal: libraryExercise,
                      allExercises: allExercises,
                      onReplace: (alternativa) {
                        try {
                          HapticFeedback.selectionClick();
                        } catch (_) {}

                        AppSnackbar.show(
                          context,
                          message: 'Alternativa: ${alternativa.name} (edita la rutina para cambiar)',
                        );
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.note_alt_outlined,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text(
                    'Notas del Ejercicio',
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
    final isRestActive = ref.watch(
      trainingSessionProvider.select((s) => s.restTimer.isActive),
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
      onUpdateWeight: (setIndex, val) => notifier.updateLog(
        widget.exerciseIndex,
        setIndex,
        peso: double.tryParse(val),
      ),
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
          // 🎯 P1: Timer SIEMPRE auto-inicia al completar serie
          if (!isRestActive) {
            notifier.startRestForExercise(
              widget.exerciseIndex,
              setIndex: setIndex,
            );
          }
        }
      },
      onPlateCalc: (setIndex, val) =>
          notifier.updateLog(widget.exerciseIndex, setIndex, peso: val),
      onSetLongPress: (setIndex) => _showAdvancedOptions(context, setIndex),
      onRestTimeChange: (seconds) => _updateExerciseRestTime(seconds),
      onUpdateWeightDirect: (setIndex, val) =>
          notifier.updateLog(widget.exerciseIndex, setIndex, peso: val),
      onUpdateRepsDirect: (setIndex, val) =>
          notifier.updateLog(widget.exerciseIndex, setIndex, reps: val),
      // 🆕 Quick Actions
      onRepeat: () => _repeatCurrentSet(exercise, historyLogs),
      onHistory: () => _showExpandedHistorySheet(context, exercise),
      onQuickNote: (note) => _addQuickNote(exercise.nombre, note),
      // 🆕 ELIMINAR SERIE: Solo afecta sesión activa, no la rutina
      onDeleteSet: (setIndex) => _deleteSet(setIndex),
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

  void _showExpandedHistorySheet(BuildContext context, Ejercicio exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            // Performance: ProviderScope aísla el consumer del historial
            child: _HistorySheetContent(exerciseName: exercise.nombre),
          ),
        );
      },
    );
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
    notifier.removeSetFromExercise(widget.exerciseIndex, setIndex);

    HapticFeedback.mediumImpact();
    if (mounted) {
      AppSnackbar.showWithUndo(
        context,
        message: 'Serie ${setIndex + 1} eliminada (solo esta sesión)',
        onUndo: () => notifier.addSetToExercise(widget.exerciseIndex),
      );
    }
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
  // 🆕 Callback para eliminar serie (solo sesión activa)
  final Function(int)? onDeleteSet;

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
    this.onDeleteSet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(informationDensityProvider);
    final densityValues = DensityValues.forMode(density);
    final restSeconds = exercise.descansoSugeridoSeconds ?? 90;

    // 🆕 Calcular si todas las series están completadas
    final allSetsCompleted = exercise.logs.every((log) => log.completed);
    final completedSets = exercise.logs.where((log) => log.completed).length;
    final totalSets = exercise.logs.length;

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
      color: isCollapsed
          ? (allSetsCompleted ? const Color(0xFF1A2A1A) : AppColors.bgElevated)
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
                    GestureDetector(
                      onTap: onToggleCollapse,
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const SizedBox(width: 32), // Alineado con el nombre
                        // Indicador de serie prominente
                        if (!allSetsCompleted)
                          _SeriesIndicator(
                            currentSet: currentSetNumber,
                            totalSets: totalSets,
                            completedSets: completedSets,
                            isCollapsed: false,
                            isLastSet: isLastSet,
                          ),
                        const Spacer(),
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
                        _SeriesIndicator(
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
                secondChild: _buildExpandedContent(restSeconds),
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

  /// Contenido expandido del ejercicio (series, etc.)
  Widget _buildExpandedContent(int restSeconds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge superset si aplica
        if (showSupersetBadge) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange[800],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'SUPERSET',
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
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
              onLongPress: () => onSetLongPress(setIndex),
              // 🎯 FIX #2: Siempre permite eliminar - si el ejercicio se queda sin series,
              // se elimina de la sesión (pero NO de la rutina base)
              canDelete: true,
              onDelete: () => onDeleteSet?.call(setIndex),
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
            shouldFocus: focusSetIndex == setIndex,
            canDelete: true,
            onDelete: () => onDeleteSet?.call(setIndex),
          );
        }),

        // 🆕 Botón para añadir series adicionales
        AddSetButton(exerciseIndex: exerciseIndex),
      ],
    );
  }
}

/// 🎯 NUEVO: Indicador de series prominente y visible
/// Responde a: "¿Cuántas llevo? ¿Cuántas quedan?"
/// - Cuando expandido: Muestra "Serie X / Y" con barra de progreso visual
/// - Cuando colapsado: Muestra "X/Y" compacto
/// - Última serie: Destaca con color especial y mensaje "¡ÚLTIMA!"
class _SeriesIndicator extends StatelessWidget {
  final int currentSet;
  final int totalSets;
  final int completedSets;
  final bool isCollapsed;
  final bool isLastSet;

  const _SeriesIndicator({
    required this.currentSet,
    required this.totalSets,
    required this.completedSets,
    required this.isCollapsed,
    required this.isLastSet,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular progreso
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;

    // Colores según estado
    final Color bgColor;
    final Color textColor;
    final Color progressColor;

    if (isLastSet) {
      // Última serie: color de urgencia/celebración
      bgColor = AppColors.fireRed.withValues(alpha: 0.2);
      textColor = AppColors.fireRed;
      progressColor = AppColors.fireRed;
    } else if (progress >= 0.5) {
      // Más de la mitad: color de progreso
      bgColor = AppColors.completedGreen.withValues(alpha: 0.15);
      textColor = AppColors.completedGreen;
      progressColor = AppColors.completedGreen;
    } else {
      // Menos de la mitad: color neutro/activo
      bgColor = AppColors.bloodRed.withValues(alpha: 0.15);
      textColor = AppColors.bloodRed;
      progressColor = AppColors.bloodRed;
    }

    if (isCollapsed) {
      // Versión compacta para estado colapsado
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: textColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          '$completedSets/$totalSets',
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      );
    }

    // Versión expandida con más información
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de serie/repetición
          Icon(Icons.fitness_center, size: 12, color: textColor),
          const SizedBox(width: 4),
          // Texto principal
          Text(
            isLastSet ? '¡ÚLTIMA!' : 'Serie $currentSet',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          // Separador
          Text(
            '/',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: textColor.withAlpha((0.6 * 255).round()),
            ),
          ),
          const SizedBox(width: 4),
          // Total de series
          Text(
            '$totalSets',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor.withAlpha((0.8 * 255).round()),
            ),
          ),
          const SizedBox(width: 6),
          // Mini barra de progreso visual
          SizedBox(
            width: 24,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: textColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PERFORMANCE OPTIMIZATION: Historial Cacheado
// ============================================================================
/// Widget que muestra el historial de un ejercicio usando provider cacheado.
/// 
/// Usa [exerciseHistoryProvider] que implementa TTL de 5 minutos,
/// evitando N+1 queries cuando el usuario navega entre ejercicios.
class _HistorySheetContent extends ConsumerWidget {
  final String exerciseName;

  const _HistorySheetContent({required this.exerciseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseName));

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('HISTORIAL', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            'Error al cargar: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('HISTORIAL', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'No hay datos previos.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName.toUpperCase(),
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'ÚLTIMAS 3 SESIONES',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final sessionExercise = session.ejerciciosCompletados
                      .firstWhere(
                        (e) => e.nombre == exerciseName,
                        orElse: () => Ejercicio(
                          id: '',
                          libraryId: 'unknown',
                          nombre: exerciseName,
                          series: 0,
                          reps: 0,
                          logs: const [],
                        ),
                      );

                  final dateLabel =
                      '${session.fecha.day.toString().padLeft(2, '0')}/'
                      '${session.fecha.month.toString().padLeft(2, '0')}/'
                      '${session.fecha.year}';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...sessionExercise.logs.map((log) {
                          final weight =
                              log.peso.truncateToDouble() == log.peso
                                  ? log.peso.toInt().toString()
                                  : log.peso.toStringAsFixed(1);
                          return Text(
                            '• $weight kg × ${log.reps}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
