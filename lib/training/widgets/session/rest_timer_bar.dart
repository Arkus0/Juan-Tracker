import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart' show AppTypography;
import '../../providers/settings_provider.dart';
import '../../services/haptics_controller.dart' show HapticEvent, HapticsController;
import '../../services/rest_timer_controller.dart';
import '../../services/timer_audio_service.dart';
import '../../services/timer_notification_service.dart';
import '../../services/timer_platform_service.dart';
import '../../utils/design_system.dart' show AppColors;
import '../../utils/performance_utils.dart' show PerformanceMode, Throttler;

/// Callback cuando el timer termina, incluye info para auto-focus
typedef TimerFinishedCallback =
    void Function({int? lastExerciseIndex, int? lastSetIndex});

/// Barra de timer de descanso no invasiva (estilo Hevy/Strong)
///
/// Optimizaciones:
/// - RepaintBoundary para aislar repaints del timer
/// - Ticker adaptativo (reduce frecuencia en modo performance)
/// - Widgets const donde posible
/// - Estilos pre-computados (no GoogleFonts en build)
/// - Mínimo uso de setState
class RestTimerBar extends ConsumerStatefulWidget {
  final RestTimerState timerState;
  final bool
  showInactiveBar; // Mostrar barra inactiva (configurable desde AppBar)
  final VoidCallback onStartRest;
  final VoidCallback onStopRest;
  final VoidCallback onPauseRest;
  final VoidCallback onResumeRest;
  final ValueChanged<int> onDurationChange;
  final ValueChanged<int> onAddTime;
  final TimerFinishedCallback onTimerFinished;
  final VoidCallback? onDiscardSession; // Nuevo: borrar sesión
  final VoidCallback?
  onRestartRest; // Nuevo: reiniciar descanso dentro de la sesión

  const RestTimerBar({
    super.key,
    required this.timerState,
    this.showInactiveBar = false,
    required this.onStartRest,
    required this.onStopRest,
    required this.onPauseRest,
    required this.onResumeRest,
    required this.onDurationChange,
    required this.onAddTime,
    required this.onTimerFinished,
    this.onDiscardSession,
    this.onRestartRest,
  });

  @override
  ConsumerState<RestTimerBar> createState() => _RestTimerBarState();
}

class _RestTimerBarState extends ConsumerState<RestTimerBar>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Timer? _ticker;
  double _displaySeconds = 0;
  int _lastVibratedSecond = -1;

  // Animación para show/hide (optimizada)
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Throttler para limitar vibraciones
  final Throttler _vibrationThrottler = Throttler(
    interval: const Duration(milliseconds: 800),
  );

  // Lock screen notification service
  final TimerNotificationService _notificationService =
      TimerNotificationService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Duración de animación adaptativa según modo performance
    final animDuration = Duration(
      milliseconds: (250 * PerformanceMode.instance.animationScale).round(),
    );

    _animController = AnimationController(vsync: this, duration: animDuration);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Setup notification callbacks
    _setupNotificationCallbacks();

    if (widget.timerState.isActive) {
      _startTicker();
      _animController.forward();
      _startLockScreenNotification();
    }

    _displaySeconds = widget.timerState.remainingSeconds;
  }

  /// Setup callbacks for notification button actions
  void _setupNotificationCallbacks() {
    _notificationService.onPausePressed = () {
      if (mounted &&
          widget.timerState.isActive &&
          !widget.timerState.isPaused) {
        widget.onPauseRest();
      }
    };
    _notificationService.onResumePressed = () {
      if (mounted && widget.timerState.isActive && widget.timerState.isPaused) {
        widget.onResumeRest();
      }
    };
    _notificationService.onSkipPressed = () {
      if (mounted && widget.timerState.isActive) {
        widget.onStopRest();
      }
    };
    _notificationService.onAddTimePressed = () {
      if (mounted && widget.timerState.isActive) {
        widget.onAddTime(30);
      }
    };
  }

  /// Start the lock screen notification
  Future<void> _startLockScreenNotification() async {
    final settings = ref.read(settingsProvider);
    // Only show if lock screen timer is enabled in settings
    if (!settings.lockScreenTimerEnabled) return;

    if (widget.timerState.endTime != null) {
      await _notificationService.startTimerNotification(
        totalSeconds: widget.timerState.totalSeconds,
        endTime: widget.timerState.endTime!,
        isPaused: widget.timerState.isPaused,
      );
    }
  }

  /// Update the lock screen notification
  Future<void> _updateLockScreenNotification() async {
    final settings = ref.read(settingsProvider);
    if (!settings.lockScreenTimerEnabled) return;

    await _notificationService.updateTimerNotification(
      totalSeconds: widget.timerState.totalSeconds,
      endTime: widget.timerState.endTime,
      isPaused: widget.timerState.isPaused,
    );
  }

  /// Stop the lock screen notification
  Future<void> _stopLockScreenNotification() async {
    await _notificationService.stopTimerNotification();
  }

  @override
  void didUpdateWidget(RestTimerBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Timer se activó
    if (widget.timerState.isActive && !oldWidget.timerState.isActive) {
      _startTicker();
      _animController.forward();
      _lastVibratedSecond = -1;
      _startLockScreenNotification();
    }

    // Timer se desactivó
    if (!widget.timerState.isActive && oldWidget.timerState.isActive) {
      _stopTicker();
      _animController.reverse();
      _stopLockScreenNotification();
    }

    // Timer se pausó
    if (widget.timerState.isPaused && !oldWidget.timerState.isPaused) {
      _stopTicker();
      _updateLockScreenNotification();
    }

    // Timer se reanudó
    if (!widget.timerState.isPaused &&
        oldWidget.timerState.isPaused &&
        widget.timerState.isActive) {
      _startTicker();
      _updateLockScreenNotification();
    }

    // Timer duration changed (e.g., +30s)
    if (widget.timerState.totalSeconds != oldWidget.timerState.totalSeconds ||
        widget.timerState.endTime != oldWidget.timerState.endTime) {
      _updateLockScreenNotification();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.timerState.isActive &&
        !widget.timerState.isPaused) {
      // Sincronizar con timer nativo de Android
      _syncWithPlatformTimer();
      _updateDisplay();
    }
  }

  /// Sincroniza el estado del timer Dart con el timer nativo de Android
  void _syncWithPlatformTimer() {
    final platformState = TimerPlatformService.instance.state;
    // Si el timer nativo ya terminó pero Dart aún lo cree activo, forzar actualización
    if (platformState.isFinished && widget.timerState.isActive) {
      // El timer terminó mientras la app estaba en background
      _stopTicker();
      _triggerFinalFeedback();
      widget.onTimerFinished(
        lastExerciseIndex: widget.timerState.lastCompletedExerciseIndex,
        lastSetIndex: widget.timerState.lastCompletedSetIndex,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    _animController.dispose();
    _vibrationThrottler.dispose();
    // Clear notification callbacks
    _notificationService.onPausePressed = null;
    _notificationService.onResumePressed = null;
    _notificationService.onSkipPressed = null;
    _notificationService.onAddTimePressed = null;
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    // Usar intervalo adaptativo según modo performance
    final interval = PerformanceMode.instance.timerTickInterval;
    _ticker = Timer.periodic(interval, (_) {
      if (!mounted) return;
      _updateDisplay();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _updateDisplay() {
    final remaining = widget.timerState.remainingSeconds;

    if (remaining <= 0 &&
        widget.timerState.isActive &&
        !widget.timerState.isPaused) {
      _stopTicker();
      _triggerFinalFeedback();
      widget.onTimerFinished(
        lastExerciseIndex: widget.timerState.lastCompletedExerciseIndex,
        lastSetIndex: widget.timerState.lastCompletedSetIndex,
      );
      widget.onStopRest();
      return;
    }

    // Solo hacer setState si el valor cambió significativamente
    // (para reducir rebuilds innecesarios)
    final newSeconds = remaining.ceil();
    if (newSeconds != _displaySeconds.ceil()) {
      setState(() {
        _displaySeconds = remaining;
      });

      // Vibración y sonido progresivo últimos 10 segundos
      _handleProgressiveFeedback(remaining);
    } else {
      // Actualizar internamente sin rebuild completo
      _displaySeconds = remaining;
    }
  }

  /// Vibración y sonido progresivo: suave en 10-6s, media en 5-3s, fuerte en 2-1s
  void _handleProgressiveFeedback(double remaining) {
    final secondInt = remaining.ceil();

    // Solo feedback una vez por segundo
    if (secondInt == _lastVibratedSecond || secondInt > 10 || secondInt <= 0) {
      return;
    }
    _lastVibratedSecond = secondInt;

    // Usar throttler para evitar vibraciones excesivas
    _vibrationThrottler.run(() async {
      // Leer settings
      final settings = ref.read(settingsProvider);
      final vibrationEnabled =
          settings.timerVibrationEnabled &&
          !PerformanceMode.instance.reduceVibrations;
      final soundEnabled = settings.timerSoundEnabled;

      // Vibración via HapticsController (lifecycle-aware)
      if (vibrationEnabled) {
        if (secondInt <= 3) {
          HapticsController.instance.trigger(HapticEvent.restWarning3s);
        } else if (secondInt <= 5) {
          HapticsController.instance.trigger(HapticEvent.restWarning5s);
        }
        // No vibramos 6-10 para reducir spam
      }

      // Sonido (solo últimos 3 segundos para no ser molesto)
      if (soundEnabled && secondInt <= 3) {
        final audio = TimerAudioService.instance;
        if (secondInt == 3) {
          audio.playMediumBeep();
        } else if (secondInt == 2) {
          audio.playHighBeep();
        } else if (secondInt == 1) {
          audio.playHighBeep();
        }
      }
    });
  }

  void _triggerFinalFeedback() async {
    final settings = ref.read(settingsProvider);

    // Vibración final via HapticsController (lifecycle-aware)
    if (settings.timerVibrationEnabled &&
        !PerformanceMode.instance.reduceVibrations) {
      HapticsController.instance.onRestFinished();
    }

    // Sonido final
    if (settings.timerSoundEnabled) {
      TimerAudioService.instance.playFinalBeep();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no está activo, mostrar barra de inicio compacta solo si showInactiveBar es true
    if (!widget.timerState.isActive) {
      if (!widget.showInactiveBar) {
        return const SizedBox.shrink(); // Ocultar barra inactiva
      }
      return _InactiveTimerBar(
        seconds: widget.timerState.totalSeconds,
        onDurationChange: widget.onDurationChange,
        onStartRest: widget.onStartRest,
        onDiscardSession: widget.onDiscardSession,
        onRestartRest: widget.onRestartRest,
      );
    }

    // Timer activo: barra compacta con progreso
    // Usar RepaintBoundary para aislar los repaints del timer
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          alignment: Alignment.bottomCenter,
          child: _ActiveTimerBar(
            displaySeconds: _displaySeconds,
            timerState: widget.timerState,
            onStopRest: widget.onStopRest,
            onPauseRest: widget.onPauseRest,
            onResumeRest: widget.onResumeRest,
            onAddTime: () => widget.onAddTime(30),
            onDiscardSession: widget.onDiscardSession,
            onRestartRest: widget.onRestartRest,
          ),
        ),
      ),
    );
  }
}

/// Barra inactiva: botón para iniciar descanso + ajuste de tiempo
/// 🎯 REDISEÑO: Grid horizontal consistente con barra activa
///
/// Estructura (izq → der):
/// [16px] [Duration selector] [flex] [Delete 40px] [12px] [Start 52px] [16px]
class _InactiveTimerBar extends StatelessWidget {
  final int seconds;
  final ValueChanged<int> onDurationChange;
  final VoidCallback onStartRest;
  final VoidCallback? onDiscardSession;
  final VoidCallback? onRestartRest;

  // UX-003: Constantes consistentes con barra activa (touch targets aumentados)
  static const double _horizontalPadding = 16.0;
  static const double _deleteButtonSize = 40.0;

  const _InactiveTimerBar({
    required this.seconds,
    required this.onDurationChange,
    required this.onStartRest,
    this.onDiscardSession,
    this.onRestartRest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        border: Border(top: BorderSide(color: AppColors.bgDeep)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Row(
            children: [
              // ═══════════════════════════════════════════════════════
              // IZQUIERDA: Selector de duración (flexible para evitar overflow)
              // ═══════════════════════════════════════════════════════
              Flexible(
                child: _TimeDurationSelector(
                  seconds: seconds,
                  onChanged: onDurationChange,
                ),
              ),

              const SizedBox(width: 8),

              // ═══════════════════════════════════════════════════════
              // DERECHA: Controles
              // ═══════════════════════════════════════════════════════
              // Delete/Restart - terciario
              if (onDiscardSession != null)
                _CircleButton(
                  icon: Icons.delete_outline,
                  size: _deleteButtonSize,
                  color: AppColors.bgDeep,
                  onTap: () => _showDiscardDialog(context),
                )
              else if (onRestartRest != null)
                _CircleButton(
                  icon: Icons.refresh,
                  size: _deleteButtonSize,
                  color: AppColors.bgDeep,
                  onTap: () {
                    HapticsController.instance.trigger(HapticEvent.buttonTap);
                    onRestartRest!();
                  },
                ),

              const SizedBox(width: 16),

              // Start - PRIMARIO (más grande, destacado)
              _StartRestButton(onTap: onStartRest),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDiscardDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Descartar sesión?'),
        content: const Text('Se perderán los datos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('NO'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('SÍ'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      HapticsController.instance.trigger(HapticEvent.inputSubmit);
      onDiscardSession!();
    }
  }
}

/// Barra activa: timer compacto con controles
/// 🎯 REDISEÑO UX: Grid horizontal explícita con jerarquía visual clara
///
/// Estructura (izq → der):
/// [16px] [Timer 52px] [12px] [Estado flex] [12px] [Controles] [16px]
///
/// Jerarquía de tamaños:
/// - Timer circular: 52px (DOMINANTE - info principal)
/// - Skip button: 44px (acción primaria de controles)
/// - +30s button: 36px (secundario)
/// - Delete button: 32px (terciario, discreto)
class _ActiveTimerBar extends StatelessWidget {
  final double displaySeconds;
  final RestTimerState timerState;
  final VoidCallback onStopRest;
  final VoidCallback onPauseRest;
  final VoidCallback onResumeRest;
  final VoidCallback onAddTime;
  final VoidCallback? onDiscardSession;
  final VoidCallback? onRestartRest;

  // 🎯 CONSTANTES: Espaciado y tamaños consistentes (UX-003)
  static const double _barHeight = 80.0; // Aumentado para touch targets más grandes
  static const double _horizontalPadding = 16.0;
  static const double _elementGap = 16.0;
  static const double _skipButtonSize = 52.0; // Aumentado de 44
  static const double _addTimeButtonSize = 44.0; // Aumentado de 36
  static const double _deleteButtonSize = 40.0; // Aumentado de 32

  const _ActiveTimerBar({
    required this.displaySeconds,
    required this.timerState,
    required this.onStopRest,
    required this.onPauseRest,
    required this.onResumeRest,
    required this.onAddTime,
    this.onDiscardSession,
    this.onRestartRest,
  });

  @override
  Widget build(BuildContext context) {
    final seconds = displaySeconds.ceil();
    final progress = timerState.totalSeconds > 0
        ? 1.0 - (displaySeconds / timerState.totalSeconds)
        : 1.0;
    final isCritical = seconds <= 10;
    final isPaused = timerState.isPaused;

    // Colores según estado
    final borderColor = isPaused
        ? AppColors.warning
        : isCritical
        ? AppColors.fireRed
        : const Color(0xFF00CED1);

    return Semantics(
      label:
          'Timer de descanso: $seconds segundos restantes${isPaused ? ", pausado" : ""}. Desliza arriba para añadir 30 segundos, abajo para saltar.',
      child: GestureDetector(
        onLongPress: () {
          HapticsController.instance.trigger(HapticEvent.inputSubmit);
          onStopRest();
        },
        onTap: () {
          HapticsController.instance.trigger(HapticEvent.buttonTap);
          if (isPaused) {
            onResumeRest();
          } else {
            onPauseRest();
          }
        },
        // UX-003: Gestos swipe para acciones rápidas con manos sudadas
        onVerticalDragEnd: (details) {
          // Swipe up: +30s
          if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
            HapticsController.instance.trigger(HapticEvent.buttonTap);
            onAddTime();
          }
          // Swipe down: skip
          else if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
            HapticsController.instance.trigger(HapticEvent.inputSubmit);
            onStopRest();
          }
        },
        child: Container(
          height: _barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isCritical
                    ? AppColors.fireRed.withValues(alpha: 0.1)
                    : AppColors.bgElevated,
                AppColors.bgDeep,
              ],
            ),
            border: Border(
              top: BorderSide(color: borderColor, width: isCritical ? 3 : 2),
            ),
            boxShadow: PerformanceMode.instance.showShadows
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.4),
                      blurRadius: isCritical ? 16 : 8,
                      offset: const Offset(0, -4),
                    ),
                  ]
                : null,
          ),
          child: SafeArea(
            top: false,
            // 🎯 GRID HORIZONTAL: Padding simétrico + Row con alineación central
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
              ),
              child: Row(
                children: [
                  // ═══════════════════════════════════════════════════════
                  // IZQUIERDA: Timer circular (DOMINANTE)
                  // ═══════════════════════════════════════════════════════
                  RepaintBoundary(
                    child: _CircularTimerProgress(
                      progress: progress,
                      seconds: seconds,
                      isCritical: isCritical,
                      isPaused: isPaused,
                    ),
                  ),

                  const SizedBox(width: _elementGap),

                  // ═══════════════════════════════════════════════════════
                  // CENTRO: Estado + hint (flexible, ocupa espacio restante)
                  // ═══════════════════════════════════════════════════════
                  Expanded(child: _TimerStateLabel(isPaused: isPaused)),

                  const SizedBox(width: _elementGap),

                  // ═══════════════════════════════════════════════════════
                  // DERECHA: Controles con jerarquía clara
                  // ═══════════════════════════════════════════════════════
                  _buildControlsGroup(context, isPaused),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Grupo de controles con jerarquía visual clara
  /// Orden: [Delete 32px] [+30s 36px] [Skip 44px]
  Widget _buildControlsGroup(BuildContext context, bool isPaused) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Delete/Restart - TERCIARIO (más pequeño, discreto)
        if (onDiscardSession != null)
          _CircleButton(
            icon: Icons.delete_outline,
            size: _deleteButtonSize,
            color: AppColors.bgDeep,
            onTap: () => _showDiscardDialog(context),
          )
        else if (onRestartRest != null)
          _CircleButton(
            icon: Icons.refresh,
            size: _deleteButtonSize,
            color: AppColors.bgDeep,
            onTap: () {
              HapticsController.instance.trigger(HapticEvent.buttonTap);
              onRestartRest!();
            },
          )
        else
          const SizedBox(
            width: _deleteButtonSize,
          ), // Mantener espacio para alineación

        const SizedBox(width: 16),

        // +30s - SECUNDARIO (UX-003: Separado de acciones destructivas)
        _CircleButton(
          icon: Icons.more_time,
          size: _addTimeButtonSize,
          color: AppColors.bgPressed,
          onTap: () {
            HapticsController.instance.trigger(HapticEvent.buttonTap);
            onAddTime();
          },
        ),

        const SizedBox(width: 16),

        // Skip - PRIMARIO (más grande, destacado)
        _CircleButton(
          icon: Icons.skip_next_rounded,
          size: _skipButtonSize,
          color: AppColors.techCyan,
          onTap: () {
            HapticsController.instance.trigger(HapticEvent.buttonTap);
            onStopRest();
          },
        ),
      ],
    );
  }

  Future<void> _showDiscardDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Descartar sesión?'),
        content: const Text('Se perderán los datos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('NO'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('SÍ'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      HapticsController.instance.trigger(HapticEvent.inputSubmit);
      onDiscardSession!();
    }
  }
}

/// Label de estado del timer - extraído para evitar rebuilds
/// 🎯 MEJORA UX: Labels más grandes y con color activo
class _TimerStateLabel extends StatelessWidget {
  final bool isPaused;

  const _TimerStateLabel({required this.isPaused});

  @override
  Widget build(BuildContext context) {
    // 🎯 NUEVO: Usar teal brillante para estado activo
    const activeColor = Color(0xFF00CED1);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPaused ? 'PAUSADO' : 'DESCANSANDO',
          style: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: isPaused ? AppColors.warning : activeColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isPaused ? 'Toca para reanudar' : 'Toca para pausar',
          style: AppTypography.bodySmall.copyWith(
            color: isPaused
                ? AppColors.warning.withAlpha((0.7 * 255).round())
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Selector de duración de descanso (modo inactivo)
/// 🎯 REDISEÑO: Espaciado consistente y jerarquía clara
class _TimeDurationSelector extends StatelessWidget {
  final int seconds;
  final ValueChanged<int> onChanged;

  // Tamaños consistentes
  static const double _buttonSize = 28.0;
  static const double _gap = 8.0;

  const _TimeDurationSelector({required this.seconds, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DESCANSO',
          style: AppTypography.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 12),
        _CircleButton(
          icon: Icons.remove,
          size: _buttonSize,
          color: AppColors.bgDeep,
          onTap: seconds > 10 ? () => onChanged(seconds - 10) : null,
        ),
        const SizedBox(width: _gap),
        SizedBox(
          width: 48, // Ancho fijo para evitar saltos
          child: Center(
            child: Text(
              '${seconds}s',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(width: _gap),
        _CircleButton(
          icon: Icons.add,
          size: _buttonSize,
          color: AppColors.bloodRed,
          onTap: () => onChanged(seconds + 10),
        ),
      ],
    );
  }
}

/// Botón para iniciar descanso - Rojo Ferrari, circular
/// 🎯 REDISEÑO: Tamaño configurable para consistencia
class _StartRestButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartRestButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // UX-003: Aumentado a 52dp para consistencia
    const size = 52.0;
    return Tooltip(
      message: 'Iniciar descanso',
      child: Material(
        color: AppColors.bloodRed,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            HapticsController.instance.trigger(HapticEvent.buttonTap);
            onTap();
          },
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.play_arrow_rounded,
              size: size * 0.58,
              color: AppColors.textOnAccent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicador de progreso circular con countdown
/// 🎯 MEJORA UX: Timer GRANDE y VISIBLE para gimnasio
/// - Tamaño configurable (default 52px)
/// - Color TEAL brillante para máximo contraste (#00CED1)
/// - Glow animado que "respira" para atraer atención
/// - Texto proporcional al tamaño
class _CircularTimerProgress extends StatefulWidget {
  final double progress;
  final int seconds;
  final bool isCritical;
  final bool isPaused;

  const _CircularTimerProgress({
    required this.progress,
    required this.seconds,
    required this.isCritical,
    required this.isPaused,
  });

  @override
  State<_CircularTimerProgress> createState() => _CircularTimerProgressState();
}

class _CircularTimerProgressState extends State<_CircularTimerProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Solo animar si está activo y no pausado
    if (!widget.isPaused) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_CircularTimerProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Controlar animación según estado
    if (widget.isPaused && !oldWidget.isPaused) {
      _pulseController.stop();
    } else if (!widget.isPaused && oldWidget.isPaused) {
      _pulseController.repeat(reverse: true);
    }
    // Acelerar pulso en estado crítico
    if (widget.isCritical && !oldWidget.isCritical) {
      _pulseController.duration = const Duration(milliseconds: 600);
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCritical && oldWidget.isCritical) {
      _pulseController.duration = const Duration(milliseconds: 1200);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 NUEVO: Colores de ALTO CONTRASTE para visibilidad en gimnasio
    // - Pausado: Amarillo warning (visible, indica estado)
    // - Crítico (<10s): Blanco brillante con glow rojo (MÁXIMA URGENCIA)
    // - Normal: Cyan/Teal brillante (#00CED1) - contraste 8:1 sobre fondo oscuro
    final Color timerColor;
    final Color glowColor;

    if (widget.isPaused) {
      timerColor = AppColors.warning;
      glowColor = AppColors.warning.withValues(alpha: 0.5);
    } else if (widget.isCritical) {
      timerColor = Colors.white; // Máxima visibilidad en crítico
      glowColor = AppColors.fireRed.withValues(alpha: 0.8);
    } else {
      timerColor = const Color(0xFF00CED1); // Dark Turquoise - alto contraste
      glowColor = const Color(0xFF00CED1).withValues(alpha: 0.5);
    }

    const size = 52.0;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = widget.isPaused ? 1.0 : _pulseAnimation.value;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // 🎯 NUEVO: Glow que "respira"
              boxShadow: PerformanceMode.instance.showShadows
                  ? [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: widget.isCritical ? 20 : 12,
                        spreadRadius: widget.isCritical ? 4 : 2,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fondo del círculo - más visible
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 4,
                  backgroundColor: AppColors.bgDeep,
                  valueColor: AlwaysStoppedAnimation(
                    timerColor.withValues(alpha: 0.2),
                  ),
                ),
                // Progreso activo
                CircularProgressIndicator(
                  value: widget.progress.clamp(0.0, 1.0),
                  strokeWidth: 4,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(timerColor),
                ),
                // Texto proporcional al tamaño del widget
                Text(
                  '${widget.seconds}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: size * 0.4, // Proporcional al tamaño
                    fontWeight: FontWeight.w900,
                    color: timerColor,
                    shadows: widget.isCritical
                        ? [Shadow(color: glowColor, blurRadius: 8)]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Botón circular reutilizable
///
/// MEJORA UX: El área táctil (hitbox) es siempre >= 48dp para cumplir
/// con las guías de accesibilidad, independiente del tamaño visual del icono.
/// Esto es crítico para uso en gimnasio (manos sudadas, guantes, prisa).
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final VoidCallback? onTap;

  /// Tamaño mínimo del área táctil (UX-003: 64dp para manos sudadas/guantes)
  static const double _minHitArea = 64.0;

  const _CircleButton({
    required this.icon,
    required this.size,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final buttonColor = color ?? AppColors.border;
    // El área táctil es el máximo entre el tamaño visual y el mínimo de 48dp
    final hitAreaSize = size < _minHitArea ? _minHitArea : size;

    return SizedBox(
      // Hitbox expandida para accesibilidad
      width: hitAreaSize,
      height: hitAreaSize,
      child: Center(
        child: Material(
          color: isEnabled ? buttonColor : Colors.grey[850],
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            // El visual mantiene el tamaño original
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                size: size * 0.5,
                color: isEnabled ? AppColors.textPrimary : AppColors.border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
