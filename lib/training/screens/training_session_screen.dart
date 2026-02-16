import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_system.dart';
import '../../core/widgets/widgets.dart' show AppCard, AppSnackbar;
import '../providers/focus_manager_provider.dart';
import '../providers/session_progress_provider.dart';
import '../providers/session_tolerance_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/training_provider.dart';
import '../providers/voice_input_provider.dart';
import '../providers/session_template_provider.dart';
import '../providers/timer_focus_provider.dart';
import '../providers/pr_celebration_provider.dart';
import '../services/haptics_controller.dart';
import '../services/media_control_service.dart';
import '../services/media_session_service.dart';
import '../models/ejercicio.dart';
import '../models/serie_log.dart';
import '../models/session_template.dart';
import '../widgets/session/exercise_card.dart';
import '../widgets/session/exercise_nav_rail.dart';
import '../widgets/common/confetti_overlay.dart';
import '../widgets/session/haptics_observer.dart';
import '../widgets/session/progression_preview.dart';
import '../widgets/session/session_modifiers.dart';
import '../widgets/session/session_progress_bar.dart';
import '../widgets/session/session_summary_widgets.dart';
import '../widgets/session/session_finish_flow.dart';
import '../widgets/session/session_pr_widgets.dart';
import '../widgets/session/session_timer_section.dart';
import '../widgets/session/tolerance_feedback_widgets.dart';
import '../widgets/voice/voice_training_button.dart';

enum _RepeatLastSessionAction { fillEmpty, overwriteAll }
enum _OverlayPriority { none, resume, welcome, pr, completion }

class TrainingSessionScreen extends ConsumerStatefulWidget {
  const TrainingSessionScreen({super.key});

  @override
  ConsumerState<TrainingSessionScreen> createState() =>
      _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends ConsumerState<TrainingSessionScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isHudCollapsed = false;
  bool _showSessionDetails = false;
  _ResumeBannerInfo? _resumeBanner;
  DateTime? _lastCompactPrShown;

  // Per-card keys used for precise scrolling via Scrollable.ensureVisible (stable per exercise id)
  final Map<String, GlobalKey> _exerciseKeys = {};

  // Track last known incomplete set for auto-scroll detection
  ({int exerciseIndex, int setIndex})? _lastKnownIncompleteSet;

  @override
  void initState() {
    super.initState();

    // 🎯 HAPTICS: Inicializar controlador de haptics
    HapticsController.instance.initialize();
    _scrollController.addListener(_handleScroll);

    // Discovery Tooltip Check (First 3 sessions)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDiscoveryTooltip();
      // Inicializar el progreso de sesión
      ref.read(sessionProgressProvider.notifier).recalculate();
      // Initialize tracking
      _lastKnownIncompleteSet = ref
          .read(trainingSessionProvider)
          .nextIncompleteSet;
      // 🎯 ERROR TOLERANCE: Evaluar gap desde última sesión
      ref.read(sessionToleranceProvider.notifier).evaluateSessionGap();

      // 🎯 MEDIA SESSION: Iniciar MediaSession para mostrar controles del sistema
      _initializeMediaSession();

      // 🎯 HIGH-004: Welcome back banner si la sesión lleva tiempo activa
      _showWelcomeBackIfNeeded();
    });
  }

  /// Inicializa el monitoreo de MediaSession.
  /// Solo mostrará controles si hay música real (Spotify, etc), no con beeps.
  Future<void> _initializeMediaSession() async {
    // Obtener configuración
    final settings = ref.read(settingsProvider);
    final rutinaName = ref.read(trainingSessionProvider).activeRutina?.nombre;

    // Inicializar el servicio
    MediaSessionManagerService.instance.initialize();

    // Iniciar monitoreo (solo mostrará controles si hay música real)
    MediaSessionManagerService.instance.startMonitoring(
      trainingName: rutinaName ?? 'Entrenamiento',
      enabled: settings.mediaControlsEnabled,
    );

    // Configurar callbacks para los botones de media
    MediaSessionManagerService.instance.onPlayPause = () {
      MediaControlService.instance.playPause();
    };
    MediaSessionManagerService.instance.onNext = () {
      MediaControlService.instance.next();
    };
    MediaSessionManagerService.instance.onPrevious = () {
      MediaControlService.instance.previous();
    };
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    // 🎯 MEDIA SESSION: Detener monitoreo al salir del entrenamiento
    MediaSessionManagerService.instance.stopMonitoring();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    if (!_isHudCollapsed && offset > 120) {
      setState(() => _isHudCollapsed = true);
      return;
    }
    if (_isHudCollapsed && offset < 40) {
      setState(() => _isHudCollapsed = false);
    }
  }

  void _toggleHud() {
    setState(() => _isHudCollapsed = !_isHudCollapsed);
  }

  void _showSessionActionsSheet({
    required BuildContext context,
    required bool voiceAvailable,
    required bool hasHistoryData,
    required bool hasAnyInput,
    required bool focusModeEnabled,
    required dynamic notifier,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acciones de sesión',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (voiceAvailable)
                  Row(
                    children: [
                      const Icon(Icons.mic_none, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Voz (toca para dictar)'),
                      ),
                      VoiceTrainingButton(
                        onCommand: (command) =>
                            _handleVoiceCommand(command, notifier),
                        context: _buildVoiceContext(),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.mic_off, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Voz no disponible',
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Modo enfoque'),
                  subtitle: Text(
                    'Oculta overlays y navegación mientras entrenas',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: focusModeEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setSessionFocusModeEnabled(value: value);
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                ListTile(
                  leading: const Icon(Icons.undo_rounded),
                  title: const Text('Deshacer última serie'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final undone = ref
                        .read(trainingSessionProvider.notifier)
                        .undoLastCompletedSet();
                    if (!undone) {
                      AppSnackbar.showWarning(
                        context,
                        message: 'Nada que deshacer',
                      );
                    } else {
                      AppSnackbar.show(
                        context,
                        message: 'Última serie restaurada',
                        duration: AppSnackbar.shortDuration,
                      );
                    }
                  },
                ),
                if (hasHistoryData)
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('Repetir última sesión'),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _handleRepeatLastSession(hasAnyInput: hasAnyInput);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Mostrar/ocultar timer'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    final showTimerBar = ref.read(
                      trainingSessionProvider.select((s) => s.showTimerBar),
                    );
                    ref
                        .read(trainingSessionProvider.notifier)
                        .toggleTimerBar(!showTimerBar);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_add_outlined),
                  title: const Text('Guardar plantilla'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _saveSessionTemplate();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleCompactPrDismiss(PrEvent prEvent) {
    if (_lastCompactPrShown == prEvent.timestamp) return;
    _lastCompactPrShown = prEvent.timestamp;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        final current = ref.read(prCelebrationProvider);
        if (current?.timestamp == prEvent.timestamp) {
          ref.read(prCelebrationProvider.notifier).dismiss();
        }
      });
    });
  }

  void _onFinishSession() async {
    final progress = ref.read(sessionProgressProvider);
    final sessionState = ref.read(trainingSessionProvider);

    // 🎯 P1: Skip dialog si sesión 100% completada - flujo sin fricción
    if (progress.isComplete) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Stop any active rest timer
      ref.read(trainingSessionProvider.notifier).stopRest();
      ref.read(sessionProgressProvider.notifier).reset();

      final summary = await buildFinishSummary(sessionState, ref);
      await ref.read(trainingSessionProvider.notifier).finishSession();

      // 🎯 FIX: Mostrar feedback de sesión guardada ANTES de pop
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.textOnAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '¡Sesión guardada!',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textOnAccent,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.completedGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (mounted) {
        await showFinishSummarySheet(context, summary);
      }

      navigator.pop();
      return;
    }

    // Mensaje de confirmación según el progreso
    var confirmMessage =
        '¿Estás seguro de que quieres terminar el entrenamiento?';
    if (progress.percentage < 0.5) {
      confirmMessage +=
          '\n\nSolo has completado ${progress.formattedPercentage} de la sesión.';
    } else if (progress.percentage < 1.0) {
      confirmMessage +=
          '\n\nHas completado ${progress.formattedPercentage}. ¡Casi lo tienes!';
    }

    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        title: Text('¿TERMINAR SESIÓN?', style: AppTypography.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              confirmMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCELAR',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'TERMINAR',
              style: AppTypography.labelLarge.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldFinish == true) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Stop any active rest timer so UI and state are consistent
      // Prevents floating timer overlay from still being active after finishing
      ref.read(trainingSessionProvider.notifier).stopRest();

      // Reset progreso
      ref.read(sessionProgressProvider.notifier).reset();

      final summary = await buildFinishSummary(sessionState, ref);
      await ref.read(trainingSessionProvider.notifier).finishSession();

      // 🎯 FIX: Mostrar feedback de sesión guardada
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.textOnAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '¡Sesión guardada!',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textOnAccent,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.completedGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (mounted) {
        await showFinishSummarySheet(context, summary);
      }

      navigator.pop();
    }
  }

  Future<void> _saveSessionTemplate() async {
    final state = ref.read(trainingSessionProvider);
    if (state.exercises.isEmpty) {
      AppSnackbar.showWarning(
        context,
        message: 'No hay ejercicios para guardar',
      );
      return;
    }

    final controller = TextEditingController(
      text: state.dayName ?? 'Plantilla',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: Theme.of(ctx).colorScheme.outline),
        ),
        title: Text('GUARDAR PLANTILLA', style: AppTypography.titleLarge),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nombre de la plantilla',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCELAR',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(
              'GUARDAR',
              style: AppTypography.labelLarge.copyWith(
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    final exercises = state.exercises.map((exercise) {
      final sets = exercise.logs.map((log) {
        return SessionTemplateSet(
          weight: log.peso,
          reps: log.reps,
          isWarmup: log.isWarmup,
          isFailure: log.isFailure,
          isDropset: log.isDropset,
          isRestPause: log.isRestPause,
          isMyoReps: log.isMyoReps,
          isAmrap: log.isAmrap,
        );
      }).toList();

      return SessionTemplateExercise(
        libraryId: exercise.libraryId,
        name: exercise.nombre,
        musclesPrimary: exercise.musculosPrincipales,
        musclesSecondary: exercise.musculosSecundarios,
        suggestedRestSeconds: exercise.descansoSugeridoSeconds,
        sets: sets,
      );
    }).toList();

    final template = SessionTemplate(
      name: result,
      createdAt: DateTime.now(),
      exercises: exercises,
    );

    final service = ref.read(sessionTemplateServiceProvider);
    await service.saveTemplate(template);
    ref.invalidate(sessionTemplatesProvider);

    if (!mounted) return;
    AppSnackbar.show(
      context,
      message: 'Plantilla guardada',
      duration: AppSnackbar.shortDuration,
    );
  }

  void _checkDiscoveryTooltip() async {
    // Discovery tooltip removed by request - it was showing a swipe hint which is considered noisy.
    // Left intentionally empty so the callsite remains but it does nothing.
    return;
  }

  /// 🎯 HIGH-004: Muestra banner de bienvenida si la sesión lleva tiempo activa
  /// Ayuda al usuario a recuperar contexto cuando regresa a la app
  void _showWelcomeBackIfNeeded() {
    final session = ref.read(trainingSessionProvider);

    // Solo mostrar si la sesión empezó hace más de 5 minutos
    if (session.startTime == null) return;
    final elapsed = DateTime.now().difference(session.startTime!);
    if (elapsed.inMinutes < 5) return;

    // Calcular progreso
    int completedSets = 0;
    int totalSets = 0;
    for (final ex in session.exercises) {
      for (final log in ex.logs) {
        totalSets++;
        if (log.completed) completedSets++;
      }
    }

    // Encontrar siguiente ejercicio
    final nextSet = session.nextIncompleteSet;
    final currentExercise = (nextSet != null &&
            nextSet.exerciseIndex < session.exercises.length)
        ? session.exercises[nextSet.exerciseIndex].nombre
        : null;

    final bannerInfo = _ResumeBannerInfo(
      elapsedMinutes: elapsed.inMinutes,
      completedSets: completedSets,
      totalSets: totalSets,
      currentExercise: currentExercise,
      nextSetIndex: nextSet?.setIndex,
      nextSetTotal: nextSet != null && nextSet.exerciseIndex < session.exercises.length
          ? session.exercises[nextSet.exerciseIndex].logs.length
          : null,
      createdAt: DateTime.now(),
    );

    setState(() => _resumeBanner = bannerInfo);

    // Auto-dismiss después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_resumeBanner?.createdAt == bannerInfo.createdAt) {
        setState(() => _resumeBanner = null);
      }
    });

    // 🎯 HIGH-004: Scroll automático al ejercicio activo para recuperar contexto
    if (nextSet != null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _scrollToExercise(nextSet.exerciseIndex);
        }
      });
    }
  }

  /// Callback cuando el timer de descanso termina
  /// Vibra y notifica para auto-focus al siguiente input
  // ignore: unused_element
  void _onTimerFinished() async {
    // La vibración ya se maneja en el TimerBar
    // Notificar para auto-focus usando el nuevo FocusManager
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      // Usar el nuevo FocusManager para solicitar focus
      ref
          .read(focusManagerProvider.notifier)
          .requestFocus(
            exerciseIndex: nextSet.exerciseIndex,
            setIndex: nextSet.setIndex,
          );

      // También actualizar el provider legacy para compatibilidad
      ref.read(timerFinishedFocusProvider.notifier).setFocus(nextSet);

      // Scroll hacia el ejercicio si es necesario
      _scrollToExercise(nextSet.exerciseIndex);

      // Limpiar después de un frame para que el widget pueda reaccionar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            ref.read(timerFinishedFocusProvider.notifier).clear();
            ref.read(focusManagerProvider.notifier).clearFocus();
          }
        });
      });
    }
  }

  /// Scroll suave hacia un ejercicio específico
  void _scrollToExercise(int exerciseIndex) async {
    // Try precise scroll using the exercise's GlobalKey and ensureVisible.
    final exercises = ref.read(trainingSessionProvider).exercises;
    final id = exercises.length > exerciseIndex
        ? exercises[exerciseIndex].id
        : null;
    if (id != null) {
      final key = _exerciseKeys[id];
      if (key != null && key.currentContext != null) {
        await Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        );
        return;
      }
    }

    // Fallback: estimate position (legacy behavior) to keep previous UX for edge cases
    if (!_scrollController.hasClients) return;
    final estimatedOffset = (exerciseIndex * 220.0) + 40;
    final maxOffset = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      estimatedOffset.clamp(0.0, maxOffset),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpToExercise(int exerciseIndex, List<Ejercicio> exercises) {
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;

    _scrollToExercise(exerciseIndex);

    final exercise = exercises[exerciseIndex];
    final nextSetIndex = exercise.logs.indexWhere((log) => !log.completed);
    final targetSetIndex = nextSetIndex == -1
        ? (exercise.logs.isEmpty ? 0 : exercise.logs.length - 1)
        : nextSetIndex;

    ref.read(focusManagerProvider.notifier).requestFocus(
      exerciseIndex: exerciseIndex,
      setIndex: targetSetIndex,
    );
  }

  Widget _buildActiveSetBanner({
    required ({int exerciseIndex, int setIndex}) nextSet,
    required List<Ejercicio> exercises,
  }) {
    if (nextSet.exerciseIndex < 0 ||
        nextSet.exerciseIndex >= exercises.length) {
      return const SizedBox.shrink();
    }

    final exercise = exercises[nextSet.exerciseIndex];
    final currentLog = nextSet.setIndex < exercise.logs.length
        ? exercise.logs[nextSet.setIndex]
        : null;
    final historyLogs =
        ref.read(trainingSessionProvider).history[exercise.historyKey] ??
            const <SerieLog>[];
    final historyLog = nextSet.setIndex < historyLogs.length
        ? historyLogs[nextSet.setIndex]
        : null;
    final notifier = ref.read(trainingSessionProvider.notifier);
    final canApplyHistory = currentLog != null &&
        currentLog.peso <= 0 &&
        currentLog.reps <= 0 &&
        historyLog != null &&
        (historyLog.peso > 0 || historyLog.reps > 0);

    // Hint: muestra valores actuales o de la última sesión
    String? hint;
    if (currentLog != null &&
        (currentLog.peso > 0 || currentLog.reps > 0)) {
      hint = '${currentLog.peso}kg × ${currentLog.reps}';
    } else if (historyLog != null &&
        (historyLog.peso > 0 || historyLog.reps > 0)) {
      hint = 'Ant: ${historyLog.peso}kg × ${historyLog.reps}';
    }

    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Material(
        color: colors.primaryContainer.withAlpha((0.35 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => _jumpToExercise(nextSet.exerciseIndex, exercises),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            child: Row(
              children: [
                // Icono compacto
                Icon(
                  Icons.play_arrow_rounded,
                  color: colors.primary,
                  size: 22,
                ),
                const SizedBox(width: 6),
                // Info (flexible)
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: exercise.nombre,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        TextSpan(
                          text: '  ${nextSet.setIndex + 1}/${exercise.logs.length}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (hint != null)
                          TextSpan(
                            text: '  $hint',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                // ÚLTIMA (compacto, solo si aplica)
                if (canApplyHistory)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SizedBox(
                      height: 32,
                      child: TextButton(
                        onPressed: () {
                          notifier.updateLog(
                            nextSet.exerciseIndex,
                            nextSet.setIndex,
                            peso: historyLog.peso,
                            reps: historyLog.reps,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '${historyLog.peso}kg×${historyLog.reps}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                // HECHO (compacto)
                SizedBox(
                  height: 32,
                  child: FilledButton(
                    onPressed: () {
                      final eiForPr = nextSet.exerciseIndex;
                      final siForPr = nextSet.setIndex;
                      notifier.updateLog(
                        eiForPr,
                        siForPr,
                        completed: true,
                      );
                      ref.read(prCelebrationProvider.notifier).checkForPr(
                        exerciseIndex: eiForPr,
                        setIndex: siForPr,
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Icon(Icons.check, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionHud({
    required bool collapsed,
    required SessionProgress progress,
    required ({int exerciseIndex, int setIndex})? nextSet,
    required List<Ejercicio> exercises,
    required VoidCallback onToggle,
    required bool focusModeEnabled,
    required VoidCallback onToggleFocusMode,
  }) {
    final colors = Theme.of(context).colorScheme;
    final hasProgress = progress.totalSets > 0;
    final hasNext = nextSet != null &&
        nextSet.exerciseIndex >= 0 &&
        nextSet.exerciseIndex < exercises.length;
    final next = hasNext ? nextSet : null;
    if (!hasProgress && !hasNext) return const SizedBox.shrink();

    final collapsedContent = Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withAlpha((0.6 * 255).round()),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    hasProgress ? progress.formattedPercentage : '0%',
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        next != null
                            ? 'Siguiente: ${exercises[next.exerciseIndex].nombre}'
                            : 'Sin series pendientes',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasNext || hasProgress)
                        Text(
                          next != null
                              ? 'Serie ${next.setIndex + 1}/${exercises[next.exerciseIndex].logs.length} · ${progress.setsText}'
                              : progress.setsText,
                          style: AppTypography.labelSmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onToggleFocusMode,
                  icon: Icon(
                    focusModeEnabled
                        ? Icons.center_focus_strong
                        : Icons.center_focus_weak,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  tooltip: focusModeEnabled
                      ? 'Desactivar modo enfoque'
                      : 'Activar modo enfoque',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final expandedContent = Column(
      children: [
        if (next != null)
          _buildActiveSetBanner(
            nextSet: next,
            exercises: exercises,
          ),
        if (hasProgress) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => _showSessionDetails = !_showSessionDetails);
              },
              icon: Icon(
                _showSessionDetails ? Icons.expand_less : Icons.expand_more,
                size: 18,
              ),
              label: Text(
                _showSessionDetails
                    ? 'Ocultar detalles'
                    : 'Ver detalles de sesion',
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: const SessionSummaryBar(),
            crossFadeState: _showSessionDetails
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDurations.fast,
            sizeCurve: AppCurves.easeOut,
          ),
        ],
      ],
    );

    return AnimatedCrossFade(
      firstChild: expandedContent,
      secondChild: collapsedContent,
      crossFadeState:
          collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: AppDurations.fast,
      sizeCurve: AppCurves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt Optimization: Use select to only rebuild on specific changes
    final activeRutinaName = ref.watch(
      trainingSessionProvider.select((s) => s.activeRutina?.nombre),
    );
    final exercisesLength = ref.watch(
      trainingSessionProvider.select((s) => s.exercises.length),
    );
    final exercises = ref.watch(
      trainingSessionProvider.select((s) => s.exercises),
    );

    // MD-001: Timer state movido a _TimerSection para aislar rebuilds
    // El timer ya no causa rebuilds de toda la pantalla

    // Progress state
    final progress = ref.watch(sessionProgressProvider);

    // Voice available
    final voiceAvailable = ref.watch(voiceAvailableProvider);
    final isVoiceAvailable = voiceAvailable.asData?.value ?? false;

    final isKeyboardVisible = ref.watch(
      focusManagerProvider.select((s) => s.isKeyboardVisible),
    );
    final manualFocusMode = ref.watch(
      settingsProvider.select((s) => s.sessionFocusModeEnabled),
    );
    final isFocusMode = manualFocusMode ||
        isKeyboardVisible ||
        MediaQuery.of(context).viewInsets.bottom > 0;

    // 🎯 FEEDBACK: Ejercicio recién completado
    final completionInfo = ref.watch(exerciseCompletionProvider);

    // 🎯 ERROR TOLERANCE: Estado de tolerancia para mostrar bienvenida
    final toleranceState = ref.watch(sessionToleranceProvider);

    // 🎉 PR CELEBRATION: Evento de PR detectado
    final prEvent = ref.watch(prCelebrationProvider);

    // 🎯 ERROR TOLERANCE: Datos sospechosos pendientes de confirmación
    final suspiciousData = ref.watch(suspiciousDataProvider);

    final showResumeOverlay = _resumeBanner != null && !isFocusMode;
    final showWelcomeOverlay = !isFocusMode &&
        toleranceState.shouldShowWelcome &&
        toleranceState.sessionGapResult != null;
    final showPrOverlay = prEvent != null;
    final showCompletionOverlay = !isFocusMode && completionInfo != null;
    final overlayPriority = showPrOverlay
        ? _OverlayPriority.pr
        : showResumeOverlay
            ? _OverlayPriority.resume
            : showWelcomeOverlay
                ? _OverlayPriority.welcome
                : showCompletionOverlay
                    ? _OverlayPriority.completion
                    : _OverlayPriority.none;
    final useCompactPr = isFocusMode || exercisesLength > 8;
    if (overlayPriority == _OverlayPriority.pr &&
        prEvent != null &&
        useCompactPr) {
      _scheduleCompactPrDismiss(prEvent);
    }

    final hasHistoryData = ref.watch(
      trainingSessionProvider.select(
        (s) => s.history.values.any(
          (logs) => logs.any((log) => log.peso > 0 || log.reps > 0),
        ),
      ),
    );
    final hasAnyInput = ref.watch(
      trainingSessionProvider.select(
        (s) => s.exercises.any(
          (e) => e.logs.any(
            (log) => log.peso > 0 || log.reps > 0 || log.completed,
          ),
        ),
      ),
    );

    final notifier = ref.read(trainingSessionProvider.notifier);

    // 🎯 ERROR TOLERANCE: Mostrar diálogo de datos sospechosos
    // FIX: Marcar inmediatamente como "mostrando" para evitar múltiples diálogos
    if (suspiciousData.hasSuspiciousData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Marcar como mostrando y abrir diálogo después del build para cumplir con Riverpod
          ref.read(suspiciousDataProvider.notifier).markDialogShowing();
          _showSuspiciousDataDialog(suspiciousData);
        }
      });
    }

    // 🎯 UX CRÍTICO: Auto-scroll al siguiente ejercicio cuando se completa una serie
    final currentIncompleteSet = ref.watch(
      trainingSessionProvider.select((s) => s.nextIncompleteSet),
    );
    final activeExerciseIndex =
        currentIncompleteSet?.exerciseIndex ?? 0;
    final safeActiveExerciseIndex = exercises.isEmpty
        ? 0
        : (activeExerciseIndex < 0
              ? 0
              : (activeExerciseIndex >= exercises.length
                    ? exercises.length - 1
                    : activeExerciseIndex));
    if (_lastKnownIncompleteSet != null &&
        currentIncompleteSet != null &&
        currentIncompleteSet.exerciseIndex !=
            _lastKnownIncompleteSet!.exerciseIndex) {
      // El ejercicio cambió - scroll suave al nuevo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToExercise(currentIncompleteSet.exerciseIndex);
        }
      });
    }
    _lastKnownIncompleteSet = currentIncompleteSet;

    // 🎯 HAPTICS: Observer que escucha eventos de providers y dispara haptics
    return HapticsObserver(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  (activeRutinaName ?? 'Entrenando').toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded, size: 22),
              tooltip: 'Acciones de sesión',
              onPressed: () => _showSessionActionsSheet(
                context: context,
                voiceAvailable: isVoiceAvailable,
                hasHistoryData: hasHistoryData,
                hasAnyInput: hasAnyInput,
                focusModeEnabled: manualFocusMode,
                notifier: notifier,
              ),
            ),
            // TERMINAR/GUARDAR
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.tonal(
                onPressed: _onFinishSession,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(
                  progress.isComplete ? 'GUARDAR' : 'TERMINAR',
                  style: AppTypography.labelLarge,
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // 🎯 NEON IRON: Barra de progreso ultra-mínima (4px)
                const SessionProgressBar(),

                _buildSessionHud(
                  collapsed: _isHudCollapsed || isFocusMode,
                  progress: progress,
                  nextSet: currentIncompleteSet,
                  exercises: exercises,
                  onToggle: _toggleHud,
                  focusModeEnabled: manualFocusMode,
                  onToggleFocusMode: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setSessionFocusModeEnabled(
                          value: !manualFocusMode,
                        );
                  },
                ),

                // Lista de ejercicios
                Expanded(
                  child: SessionTimerSection(
                    child: ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    scrollController: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      8,
                      4,
                      8,
                      MediaQuery.of(context).viewPadding.bottom + 100,
                    ),
                    itemCount:
                        exercisesLength +
                        1, // +1 para el botón de añadir ejercicio
                    cacheExtent: 300,
                    physics: const BouncingScrollPhysics(
                      decelerationRate: ScrollDecelerationRate.fast,
                    ),
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex >= exercisesLength) return;
                      if (newIndex > exercisesLength) newIndex = exercisesLength;
                      ref
                          .read(trainingSessionProvider.notifier)
                          .reorderExercises(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      // Último item: botón para añadir ejercicio
                      if (index == exercisesLength) {
                        return const KeyedSubtree(
                          key: ValueKey('add_exercise_button'),
                          child: AddExerciseButton(),
                        );
                      }

                      // Guardia: si el índice excede la lista actual, mostrar vacío
                      if (index >= exercises.length) {
                        return KeyedSubtree(
                          key: ValueKey('exercise_placeholder_$index'),
                          child: const SizedBox.shrink(),
                        );
                      }
                
                      final exercise = exercises[index];
                      final id = exercise.id;
                      final key = _exerciseKeys.putIfAbsent(
                        id,
                        () => GlobalKey(),
                      );

                      // 🔗 SUPERSET BRACKET: Detectar si este ejercicio
                      // comparte supersetId con el anterior/siguiente
                      final ssId = exercise.supersetId;
                      final isInSuperset = ssId != null && ssId.isNotEmpty;
                      final prevSame = isInSuperset &&
                          index > 0 &&
                          exercises[index - 1].supersetId == ssId;
                      final nextSame = isInSuperset &&
                          index < exercises.length - 1 &&
                          exercises[index + 1].supersetId == ssId;

                      Widget card = RepaintBoundary(
                        child: Container(
                          key: key,
                          child: ExerciseCardContainer(exerciseIndex: index),
                        ),
                      );

                      // Envolver con bracket visual si está en superset
                      if (isInSuperset && (prevSame || nextSame)) {
                        card = SupersetBracket(
                          isFirst: !prevSame,
                          isLast: !nextSame,
                          child: card,
                        );
                      }

                      return KeyedSubtree(
                        key: ValueKey('exercise_$id'),
                        child: card,
                      );
                    },
                  ),
                  ),
                ),
              ],
            ),


            if (overlayPriority == _OverlayPriority.none &&
                !isFocusMode &&
                exercises.length > 3)
              (exercises.length > 8
                  ? Positioned(
                      right: 4,
                      top: 80,
                      bottom: 140,
                      child: ExerciseNavRailCompact(
                        exercises: exercises,
                        currentExerciseIndex: safeActiveExerciseIndex,
                        onExerciseTap: (index) =>
                            _jumpToExercise(index, exercises),
                      ),
                    )
                  : ExerciseNavRail(
                      exercises: exercises,
                      currentExerciseIndex: safeActiveExerciseIndex,
                      onExerciseTap: (index) =>
                          _jumpToExercise(index, exercises),
                    )),
            // 🎯 FEEDBACK: Overlay de ejercicio completado
            if (overlayPriority == _OverlayPriority.completion &&
                completionInfo != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 100, // Encima del timer bar
                child: GestureDetector(
                  onTap: () =>
                      ref.read(exerciseCompletionProvider.notifier).dismiss(),
                  child: AnimatedSlide(
                    offset: Offset.zero,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: ExerciseSummaryFeedback(
                      completedSets: completionInfo.completedSets,
                      targetSets: completionInfo.targetSets,
                      totalReps: completionInfo.totalReps,
                      metTarget: completionInfo.metTarget,
                      nextSessionHint: completionInfo.nextSessionHint,
                    ),
                  ),
                ),
              ),

            if (overlayPriority == _OverlayPriority.resume &&
                _resumeBanner != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: _SessionResumeBanner(
                  info: _resumeBanner!,
                  onDismiss: () => setState(() => _resumeBanner = null),
                  onContinue: () => setState(() => _resumeBanner = null),
                ),
              ),

            // 🎯 ERROR TOLERANCE: Banner de bienvenida tras días sin entrenar
            if (overlayPriority == _OverlayPriority.welcome &&
                toleranceState.sessionGapResult != null)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: WelcomeBackBanner(
                  result: toleranceState.sessionGapResult!,
                  onDismiss: () => ref
                      .read(sessionToleranceProvider.notifier)
                      .markWelcomeShown(),
                ),
              ),

            // 🎉 PR CELEBRATION: Confetti + toast dorado (compacto si la sesión está cargada)
            if (overlayPriority == _OverlayPriority.pr && prEvent != null)
              useCompactPr
                  ? Positioned(
                      left: 16,
                      right: 16,
                      bottom: 100,
                      child: PrToast(
                        exerciseName: prEvent.exerciseName,
                        weight: prEvent.weight,
                        reps: prEvent.reps,
                      ),
                    )
                  : Positioned.fill(
                      child: ConfettiOverlay(
                        trigger: true,
                        onComplete: () =>
                            ref.read(prCelebrationProvider.notifier).dismiss(),
                        child: PrToast(
                          exerciseName: prEvent.exerciseName,
                          weight: prEvent.weight,
                          reps: prEvent.reps,
                        ),
                      ),
                    ),
          ],
        ),
      ), // End of HapticsObserver
    );
  }


  Future<void> _handleRepeatLastSession({required bool hasAnyInput}) async {
    _RepeatLastSessionAction? action;

    if (hasAnyInput) {
      action = await _showRepeatLastSessionDialog();
      if (!mounted) return;
      if (action == null) return;
    } else {
      action = _RepeatLastSessionAction.overwriteAll;
    }

    final notifier = ref.read(trainingSessionProvider.notifier);
    final result = notifier.applyHistoryToCurrentSession(
      overwriteExisting: action == _RepeatLastSessionAction.overwriteAll,
    );

    if (!mounted) return;

    if (result.setsApplied == 0) {
      AppSnackbar.showWarning(
        context,
        message: 'No hay datos previos para aplicar',
      );
      return;
    }

    AppSnackbar.show(
      context,
      message:
          'Listo: ${result.setsApplied} series en ${result.exercisesUpdated} ejercicios',
      duration: AppSnackbar.shortDuration,
    );
  }

  Future<_RepeatLastSessionAction?> _showRepeatLastSessionDialog() {
    final colors = Theme.of(context).colorScheme;

    return showDialog<_RepeatLastSessionAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Repetir última sesión',
          style: AppTypography.titleMedium,
        ),
        content: Text(
          'Ya hay datos en la sesión. ¿Cómo quieres aplicar los valores anteriores?',
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
                Navigator.of(ctx).pop(_RepeatLastSessionAction.fillEmpty),
            child: const Text('RELLENAR HUECOS'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_RepeatLastSessionAction.overwriteAll),
            child: const Text('REEMPLAZAR TODO'),
          ),
        ],
      ),
    );
  }

  /// Construye el contexto de voz para mostrar qué serie se modificará
  VoiceTrainingContext? _buildVoiceContext() {
    final sessionState = ref.read(trainingSessionProvider);
    final nextSet = sessionState.nextIncompleteSet;

    if (nextSet == null ||
        nextSet.exerciseIndex >= sessionState.exercises.length) {
      return null;
    }

    final exercise = sessionState.exercises[nextSet.exerciseIndex];
    final log = exercise.logs.length > nextSet.setIndex
        ? exercise.logs[nextSet.setIndex]
        : null;

    return VoiceTrainingContext(
      exerciseName: exercise.nombre,
      currentSet: nextSet.setIndex + 1,
      totalSets: exercise.logs.length,
      currentWeight: log?.peso,
      currentReps: log?.reps,
      currentRpe: log?.rpe?.toDouble(),
    );
  }

  /// Maneja comandos de voz durante el entrenamiento
  void _handleVoiceCommand(VoiceTrainingCommand command, dynamic notifier) {
    switch (command.type) {
      case VoiceCommandType.markDone:
        // Marcar la serie actual como completada
        _markCurrentSetDone(notifier);
        break;

      case VoiceCommandType.nextSet:
        // Navegar a la siguiente serie
        _navigateToNextSet();
        break;

      case VoiceCommandType.setWeight:
        if (command.value != null) {
          _setCurrentWeight(command.value!, notifier);
        }
        break;

      case VoiceCommandType.setReps:
        if (command.value != null) {
          _setCurrentReps(command.value!.toInt(), notifier);
        }
        break;

      case VoiceCommandType.setRpe:
        if (command.value != null) {
          _setCurrentRpe(command.value!, notifier);
        }
        break;

      case VoiceCommandType.startRest:
        final duration = command.value?.toInt() ?? 90;
        notifier.setRestDuration(duration);
        notifier.startRest();
        break;

      case VoiceCommandType.addNote:
        if (command.note != null && command.note!.isNotEmpty) {
          _addNoteToCurrentSet(command.note!, notifier);
        }
        break;
    }
  }

  /// Muestra diálogo para datos sospechosos (ERROR TOLERANCE)
  void _showSuspiciousDataDialog(SuspiciousDataState data) {
    // Limpiar inmediatamente para evitar múltiples diálogos
    ref.read(suspiciousDataProvider.notifier).clear();

    // Guardia: verificar que todos los campos necesarios existen
    final exerciseName = data.exerciseName;
    final enteredWeight = data.enteredWeight;
    final suggestedWeight = data.suggestedWeight;
    final exerciseIndex = data.exerciseIndex;
    final setIndex = data.setIndex;
    if (exerciseName == null || enteredWeight == null || suggestedWeight == null ||
        exerciseIndex == null || setIndex == null) {
      return;
    }

    showSuspiciousDataDialog(
      context,
      exerciseName: exerciseName,
      enteredWeight: enteredWeight,
      suggestedWeight: suggestedWeight,
      onConfirmOriginal: () {
        // El usuario confirma que el peso es correcto - no hacer nada
      },
      onUseSuggested: () {
        // El usuario acepta la sugerencia - actualizar el peso
        ref
            .read(trainingSessionProvider.notifier)
            .updateLog(
              exerciseIndex,
              setIndex,
              peso: suggestedWeight,
              skipToleranceCheck: true,
            );
      },
    );
  }

  void _addNoteToCurrentSet(String note, dynamic notifier) {
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      notifier.updateLog(nextSet.exerciseIndex, nextSet.setIndex, notas: note);
      AppSnackbar.show(context, message: 'Nota: $note', duration: AppSnackbar.shortDuration);
    }
  }

  void _markCurrentSetDone(dynamic notifier) {
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      notifier.updateLog(
        nextSet.exerciseIndex,
        nextSet.setIndex,
        completed: true,
      );
      AppSnackbar.show(context, message: '¡Serie completada!', duration: AppSnackbar.shortDuration);
    }
  }

  void _navigateToNextSet() {
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      _scrollToExercise(nextSet.exerciseIndex);
      ref
          .read(focusManagerProvider.notifier)
          .requestFocus(
            exerciseIndex: nextSet.exerciseIndex,
            setIndex: nextSet.setIndex,
          );
    }
  }

  void _setCurrentWeight(double weight, dynamic notifier) {
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      notifier.updateLog(nextSet.exerciseIndex, nextSet.setIndex, peso: weight);
      AppSnackbar.show(context, message: 'Peso: ${weight.toStringAsFixed(1)} kg', duration: AppSnackbar.shortDuration);
    }
  }

  void _setCurrentReps(int reps, dynamic notifier) {
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      notifier.updateLog(nextSet.exerciseIndex, nextSet.setIndex, reps: reps);
      AppSnackbar.show(context, message: 'Reps: $reps', duration: AppSnackbar.shortDuration);
    }
  }

  void _setCurrentRpe(double rpe, dynamic notifier) {
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      notifier.updateLog(
        nextSet.exerciseIndex,
        nextSet.setIndex,
        rpe: rpe.toInt(),
      );
      AppSnackbar.show(context, message: 'RPE: ${rpe.toStringAsFixed(1)}', duration: AppSnackbar.shortDuration);
    }
  }
}

class _ResumeBannerInfo {
  final int elapsedMinutes;
  final int completedSets;
  final int totalSets;
  final String? currentExercise;
  final int? nextSetIndex;
  final int? nextSetTotal;
  final DateTime createdAt;

  const _ResumeBannerInfo({
    required this.elapsedMinutes,
    required this.completedSets,
    required this.totalSets,
    required this.createdAt,
    this.currentExercise,
    this.nextSetIndex,
    this.nextSetTotal,
  });
}

class _SessionResumeBanner extends StatelessWidget {
  final _ResumeBannerInfo info;
  final VoidCallback onDismiss;
  final VoidCallback? onContinue;

  const _SessionResumeBanner({
    required this.info,
    required this.onDismiss,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final nextLabel = (info.currentExercise != null && info.nextSetIndex != null)
        ? 'Siguiente: ${info.currentExercise} (Serie ${info.nextSetIndex! + 1}${info.nextSetTotal != null ? '/${info.nextSetTotal}' : ''})'
        : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withAlpha((0.2 * 255).round())),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withAlpha((0.08 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Bienvenido de vuelta!',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
                color: colors.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Llevas ${info.elapsedMinutes} min · ${info.completedSets}/${info.totalSets} series',
            style: AppTypography.bodySmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (nextLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              nextLabel,
              style: AppTypography.bodySmall.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                onContinue?.call();
                onDismiss();
              },
              child: const Text('CONTINUAR'),
            ),
          ),
        ],
      ),
    );
  }
}
