import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/focus_manager_provider.dart';
import '../providers/session_progress_provider.dart';
import '../providers/session_tolerance_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/training_provider.dart';
import '../providers/voice_input_provider.dart';
import '../services/haptics_controller.dart';
import '../services/media_control_service.dart';
import '../services/media_session_service.dart';
import '../utils/design_system.dart';
import '../utils/training_snackbar.dart';
import '../widgets/session/exercise_card.dart';
import '../widgets/session/haptics_observer.dart';
import '../widgets/session/music_launcher_bar.dart';
import '../widgets/session/progression_preview.dart';
import '../widgets/session/rest_timer_bar.dart';
import '../widgets/session/session_modifiers.dart';
import '../widgets/session/session_progress_bar.dart';
import '../widgets/session/session_timer_display.dart';
import '../widgets/session/tolerance_feedback_widgets.dart';
import '../widgets/voice/voice_training_button.dart';

/// Provider para comunicar el auto-focus cuando el timer termina
/// (Mantenido para compatibilidad, ahora usa FocusManagerProvider internamente)
final timerFinishedFocusProvider =
    NotifierProvider<
      TimerFinishedFocusNotifier,
      ({int exerciseIndex, int setIndex})?
    >(TimerFinishedFocusNotifier.new);

class TimerFinishedFocusNotifier
    extends Notifier<({int exerciseIndex, int setIndex})?> {
  @override
  ({int exerciseIndex, int setIndex})? build() => null;

  void setFocus(({int exerciseIndex, int setIndex})? focus) {
    state = focus;
  }

  void clear() {
    state = null;
  }
}

class TrainingSessionScreen extends ConsumerStatefulWidget {
  const TrainingSessionScreen({super.key});

  @override
  ConsumerState<TrainingSessionScreen> createState() =>
      _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends ConsumerState<TrainingSessionScreen> {
  final ScrollController _scrollController = ScrollController();

  // Per-card keys used for precise scrolling via Scrollable.ensureVisible (stable per exercise id)
  final Map<String, GlobalKey> _exerciseKeys = {};

  // Track last known incomplete set for auto-scroll detection
  ({int exerciseIndex, int setIndex})? _lastKnownIncompleteSet;

  @override
  void initState() {
    super.initState();

    // 🎯 HAPTICS: Inicializar controlador de haptics
    HapticsController.instance.initialize();

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
    _scrollController.dispose();
    // 🎯 MEDIA SESSION: Detener monitoreo al salir del entrenamiento
    MediaSessionManagerService.instance.stopMonitoring();
    super.dispose();
  }

  void _onFinishSession() async {
    final progress = ref.read(sessionProgressProvider);

    // 🎯 P1: Skip dialog si sesión 100% completada - flujo sin fricción
    if (progress.isComplete) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Stop any active rest timer
      ref.read(trainingSessionProvider.notifier).stopRest();
      ref.read(sessionProgressProvider.notifier).reset();

      await ref.read(trainingSessionProvider.notifier).finishSession();

      TrainingSnackbar.success(context, '¡Sesión guardada!');

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
        title: Text('¿TERMINAR SESIÓN?', style: AppTypography.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              confirmMessage,
              style: AppTypography.body.copyWith(
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
              style: AppTypography.button.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'TERMINAR',
              style: AppTypography.button.copyWith(
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

      await ref.read(trainingSessionProvider.notifier).finishSession();

      TrainingSnackbar.success(context, '¡Sesión guardada!');

      navigator.pop();
    }
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
    final currentExercise = nextSet != null
        ? session.exercises[nextSet.exerciseIndex].nombre
        : null;

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.all(16),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¡Bienvenido de vuelta!',
              style: AppTypography.labelEmphasis.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Llevas ${elapsed.inMinutes} min | $completedSets/$totalSets series',
              style: AppTypography.meta,
            ),
            if (currentExercise != null && nextSet != null) ...[
              const SizedBox(height: 2),
              Text(
                'Siguiente: $currentExercise (Serie ${nextSet.setIndex + 1})',
                style: AppTypography.meta.copyWith(color: AppColors.success),
              ),
            ],
          ],
        ),
        leading: const Icon(Icons.fitness_center, color: AppColors.success),
        backgroundColor: AppColors.bgElevated,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text(
              'CONTINUAR',
              style: AppTypography.button.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );

    // Auto-dismiss después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
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
    final estimatedOffset = (exerciseIndex * 220.0) + 40;
    final maxOffset = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      estimatedOffset.clamp(0.0, maxOffset),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
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

    // MD-001: Timer state movido a _TimerSection para aislar rebuilds
    // El timer ya no causa rebuilds de toda la pantalla

    // Progress state
    final progress = ref.watch(sessionProgressProvider);

    // Voice available
    final voiceAvailable = ref.watch(voiceAvailableProvider);

    // 🎯 FEEDBACK: Ejercicio recién completado
    final completionInfo = ref.watch(exerciseCompletionProvider);

    // 🎯 ERROR TOLERANCE: Estado de tolerancia para mostrar bienvenida
    final toleranceState = ref.watch(sessionToleranceProvider);

    // 🎯 ERROR TOLERANCE: Datos sospechosos pendientes de confirmación
    final suspiciousData = ref.watch(suspiciousDataProvider);

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
          title: Text(
            (activeRutinaName ?? 'Entrenando').toUpperCase(),
            style: AppTypography.sectionTitle,
          ),
          actions: [
            // ⏱️ CRONÓMETRO TOTAL DE SESIÓN
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Center(
                child: SessionTimerDisplay(showIcon: true, compact: true),
              ),
            ),
            // 🎯 NEON IRON: Control de música compacto (antes era barra completa)
            const MusicAppBarAction(),
            // Botón de voz en AppBar (al lado de terminar)
            // Incluye contexto de la serie activa para feedback claro
            voiceAvailable.when(
              data: (available) => available
                  ? VoiceTrainingButton(
                      onCommand: (command) =>
                          _handleVoiceCommand(command, notifier),
                      context: _buildVoiceContext(),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            // MD-001: Usar Consumer para aislar el rebuild del botón de timer
            Consumer(
              builder: (context, ref, child) {
                final showTimerBar = ref.watch(
                  trainingSessionProvider.select((s) => s.showTimerBar),
                );
                return IconButton(
                  icon: Icon(showTimerBar ? Icons.timer : Icons.timer_outlined),
                  onPressed: () => ref
                      .read(trainingSessionProvider.notifier)
                      .toggleTimerBar(!showTimerBar),
                  tooltip: 'Mostrar/ocultar timer',
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _onFinishSession,
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    side: BorderSide.none,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.save_outlined, size: 16),
                    ),
                    Text(
                      progress.isComplete ? 'GUARDAR' : 'TERMINAR',
                      style: AppTypography.button.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
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

                // Lista de ejercicios (MusicLauncherBar movido a AppBar)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      8,
                      8,
                      8,
                      MediaQuery.of(context).viewPadding.bottom + 100,
                    ), // Dynamic bottom padding to account for RestTimerBar and SafeArea
                    itemCount:
                        exercisesLength +
                        1, // +1 para el botón de añadir ejercicio
                    // ⚡ OPTIMIZACIÓN: Pre-renderizar items cercanos para scroll más suave
                    cacheExtent: 300,
                    // ⚡ OPTIMIZACIÓN: Física optimizada para listas cortas (4-8 ejercicios típicos)
                    physics: const BouncingScrollPhysics(
                      decelerationRate: ScrollDecelerationRate.fast,
                    ),
                    itemBuilder: (context, index) {
                      // 🆕 Último item: botón para añadir ejercicio
                      if (index == exercisesLength) {
                        return const AddExerciseButton();
                      }

                      // ⚡ Bolt Optimization: Extracted to smart widget
                      final exercises = ref
                          .read(trainingSessionProvider)
                          .exercises;
                      final id = exercises.length > index
                          ? exercises[index].id
                          : index.toString();
                      final key = _exerciseKeys.putIfAbsent(
                        id,
                        () => GlobalKey(),
                      );
                      // ⚡ OPTIMIZACIÓN: RepaintBoundary para aislar repintura de cada card
                      return RepaintBoundary(
                        child: Container(
                          key: key,
                          child: ExerciseCardContainer(exerciseIndex: index),
                        ),
                      );
                    },
                  ),
                ),

                // MD-001: Timer aislado en widget const para evitar rebuilds
                const _TimerSection(),
              ],
            ),

            // 🎯 FEEDBACK: Overlay de ejercicio completado
            if (completionInfo != null)
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

            // 🎯 ERROR TOLERANCE: Banner de bienvenida tras días sin entrenar
            if (toleranceState.shouldShowWelcome &&
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
          ],
        ),
      ), // End of HapticsObserver
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

    showSuspiciousDataDialog(
      context,
      exerciseName: data.exerciseName!,
      enteredWeight: data.enteredWeight!,
      suggestedWeight: data.suggestedWeight!,
      onConfirmOriginal: () {
        // El usuario confirma que el peso es correcto - no hacer nada
        // El peso ya fue guardado
      },
      onUseSuggested: () {
        // El usuario acepta la sugerencia - actualizar el peso
        // 🎯 FIX: Skip tolerance check to prevent infinite validation loop
        ref
            .read(trainingSessionProvider.notifier)
            .updateLog(
              data.exerciseIndex!,
              data.setIndex!,
              peso: data.suggestedWeight,
              skipToleranceCheck: true,
            );
      },
    );
  }

  void _addNoteToCurrentSet(String note, dynamic notifier) {
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      // Añadir nota a la serie actual
      notifier.updateLog(nextSet.exerciseIndex, nextSet.setIndex, notas: note);

      TrainingSnackbar.voiceNote(context, 'Nota: $note');
    }
  }

  void _markCurrentSetDone(dynamic notifier) {
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      // Marcar la serie como completada (toggle done)
      notifier.updateLog(
        nextSet.exerciseIndex,
        nextSet.setIndex,
        completed: true,
      );

      TrainingSnackbar.success(context, '¡Serie completada!');
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

      TrainingSnackbar.info(context, 'Peso: ${weight.toStringAsFixed(1)} kg');
    }
  }

  void _setCurrentReps(int reps, dynamic notifier) {
    final state = ref.read(trainingSessionProvider);
    final nextSet = state.nextIncompleteSet;

    if (nextSet != null) {
      notifier.updateLog(nextSet.exerciseIndex, nextSet.setIndex, reps: reps);

      TrainingSnackbar.info(context, 'Reps: $reps');
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

      TrainingSnackbar.info(context, 'RPE: ${rpe.toStringAsFixed(1)}');
    }
  }
}

/// MD-001: Sección de Timer aislada para evitar rebuilds de la pantalla completa
///
/// Este widget ConsumerWidget aísla todo el estado del timer del resto de la
/// pantalla de entrenamiento. Cuando el timer actualiza (cada 100ms), solo
/// este widget se reconstruye, no toda la TrainingSessionScreen.
///
/// Optimizaciones:
/// - Usa select() para escuchar solo cambios específicos del timer
/// - Envuelto en RepaintBoundary para aislar repaints
/// - Callbacks delegados al notifier sin reconstruir el padre
class _TimerSection extends ConsumerWidget {
  const _TimerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar solo el estado del timer - cambios aquí solo reconstruyen este widget
    final restTimerState = ref.watch(
      trainingSessionProvider.select((s) => s.restTimer),
    );
    final showTimerBar = ref.watch(
      trainingSessionProvider.select((s) => s.showTimerBar),
    );

    final notifier = ref.read(trainingSessionProvider.notifier);

    // Callback que necesita acceso al context para scroll
    void onTimerFinished({int? lastExerciseIndex, int? lastSetIndex}) {
      // La vibración ya se maneja en el TimerBar
      final state = ref.read(trainingSessionProvider);
      final nextSet = state.nextIncompleteSet;

      if (nextSet != null) {
        // Usar el FocusManager para solicitar focus
        ref
            .read(focusManagerProvider.notifier)
            .requestFocus(
              exerciseIndex: nextSet.exerciseIndex,
              setIndex: nextSet.setIndex,
            );

        // Actualizar provider legacy para compatibilidad
        ref.read(timerFinishedFocusProvider.notifier).setFocus(nextSet);

        // Limpiar después de un frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 150), () {
            ref.read(timerFinishedFocusProvider.notifier).clear();
            ref.read(focusManagerProvider.notifier).clearFocus();
          });
        });
      }
    }

    return RepaintBoundary(
      child: RestTimerBar(
        timerState: restTimerState,
        showInactiveBar: showTimerBar,
        onStartRest: notifier.startRest,
        onStopRest: notifier.stopRest,
        onPauseRest: notifier.pauseRest,
        onResumeRest: notifier.resumeRest,
        onDurationChange: notifier.setRestDuration,
        onAddTime: notifier.addRestTime,
        onTimerFinished: onTimerFinished,
        onRestartRest: notifier.restartRest,
      ),
    );
  }
}
