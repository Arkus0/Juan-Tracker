import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/rest_timer_controller.dart';

/// Timer flotante que se superpone al contenido sin empujarlo.
///
/// Muestra un panel compacto Material 3 en la parte inferior con:
/// - Progreso circular + countdown
/// - Botones: +30s, Pausa/Play, Skip
/// - Pulso y glow en los últimos 10 segundos
class FloatingTimerOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final RestTimerState timerState;
  final bool showInactiveBar;
  final void Function(int) onStartRest;
  final VoidCallback onStopRest;
  final VoidCallback onPauseRest;
  final VoidCallback onResumeRest;
  final void Function(int) onDurationChange;
  final void Function(int) onAddTime;
  final void Function({int? lastExerciseIndex, int? lastSetIndex})
      onTimerFinished;
  final VoidCallback onRestartRest;

  const FloatingTimerOverlay({
    super.key,
    required this.child,
    required this.timerState,
    required this.showInactiveBar,
    required this.onStartRest,
    required this.onStopRest,
    required this.onPauseRest,
    required this.onResumeRest,
    required this.onDurationChange,
    required this.onAddTime,
    required this.onTimerFinished,
    required this.onRestartRest,
  });

  @override
  ConsumerState<FloatingTimerOverlay> createState() =>
      _FloatingTimerOverlayState();
}

class _FloatingTimerOverlayState extends ConsumerState<FloatingTimerOverlay>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  double _displaySeconds = 0;
  bool _wasActive = false;
  bool _showAdvancedControls = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _displaySeconds = widget.timerState.remainingSeconds;
    _wasActive = widget.timerState.isActive;
    if (widget.timerState.isActive && !widget.timerState.isPaused) {
      _startTicker();
    }
  }

  @override
  void didUpdateWidget(FloatingTimerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Timer started
    if (widget.timerState.isActive && !oldWidget.timerState.isActive) {
      _displaySeconds = widget.timerState.remainingSeconds;
      _startTicker();
    }

    // Timer stopped
    if (!widget.timerState.isActive && oldWidget.timerState.isActive) {
      _stopTicker();
    }

    // Resumed
    if (widget.timerState.isActive &&
        !widget.timerState.isPaused &&
        oldWidget.timerState.isPaused) {
      _startTicker();
    }

    // Paused
    if (widget.timerState.isActive &&
        widget.timerState.isPaused &&
        !oldWidget.timerState.isPaused) {
      _stopTicker();
      setState(() {
        _displaySeconds = widget.timerState.totalSeconds.toDouble();
      });
    }

    // Check if timer just finished
    if (_wasActive && !widget.timerState.isActive) {
      widget.onTimerFinished(
        lastExerciseIndex: oldWidget.timerState.lastCompletedExerciseIndex,
        lastSetIndex: oldWidget.timerState.lastCompletedSetIndex,
      );
    }
    _wasActive = widget.timerState.isActive;
  }

  @override
  void dispose() {
    _stopTicker();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      final remaining = widget.timerState.remainingSeconds;
      setState(() => _displaySeconds = remaining);

      if (remaining <= 10 && remaining > 0) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }

      if (remaining <= 0 && widget.timerState.isActive) {
        _stopTicker();
        widget.onStopRest();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (_pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  String _formatTime(int s) {
    final min = s ~/ 60;
    final sec = s % 60;
    if (min > 0) return '$min:${sec.toString().padLeft(2, '0')}';
    return '$s';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.timerState.isActive;
    final isPaused = widget.timerState.isPaused;
    final seconds = _displaySeconds.ceil();
    final progress = widget.timerState.totalSeconds > 0
        ? 1.0 - (_displaySeconds / widget.timerState.totalSeconds)
        : 1.0;
    final isCritical = seconds <= 10 && seconds > 0;

    final colors = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Stack(
      children: [
        widget.child,

        // Timer activo flotante
        if (isActive)
          Positioned(
            left: 12,
            right: 12,
            bottom: bottomPadding + 8,
            child: RepaintBoundary(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    final accentColor = isCritical
                        ? colors.error
                        : (isPaused ? colors.tertiary : colors.primary);
                    final accentForeground = isCritical
                        ? colors.onError
                        : (isPaused ? colors.onTertiary : colors.onPrimary);
                    return Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCritical
                              ? colors.error.withAlpha((0.6 * 255).round())
                              : colors.outlineVariant,
                        ),
                        boxShadow: isCritical
                            ? [
                                BoxShadow(
                                  color: colors.error.withAlpha(
                                    (0.3 * _glowAnimation.value * 255).round(),
                                  ),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.2 * 255).round()),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPaused ? 'PAUSADO' : 'DESCANSO',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color:
                                                  colors.onSurfaceVariant,
                                              letterSpacing: 1.2,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(seconds),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: accentColor,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _showAdvancedControls
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: colors.onSurfaceVariant,
                                  ),
                                  tooltip: _showAdvancedControls
                                      ? 'Ocultar controles'
                                      : 'Mostrar controles',
                                  onPressed: () {
                                    setState(() {
                                      _showAdvancedControls =
                                          !_showAdvancedControls;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor:
                                  colors.surfaceContainerHighest,
                              valueColor:
                                  AlwaysStoppedAnimation(accentColor),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      isPaused
                                          ? widget.onResumeRest()
                                          : widget.onPauseRest();
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: accentForeground,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      isPaused ? 'REANUDAR' : 'PAUSAR',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      HapticFeedback.heavyImpact();
                                      widget.onStopRest();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      'SALTAR',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    _TimerMiniAction(
                                      icon: Icons.add_rounded,
                                      label: '+30s',
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        widget.onAddTime(30);
                                      },
                                      colors: colors,
                                    ),
                                    const SizedBox(width: 8),
                                    _TimerMiniAction(
                                      icon: Icons.refresh_rounded,
                                      label: 'Reiniciar',
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        widget.onRestartRest();
                                      },
                                      colors: colors,
                                    ),
                                  ],
                                ),
                              ),
                              crossFadeState: _showAdvancedControls
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

        // Chip compacto inactivo para iniciar timer manualmente
        if (!isActive && widget.showInactiveBar)
          Positioned(
            left: 12,
            right: 12,
            bottom: bottomPadding + 8,
            child: _InactiveTimerChip(
              totalSeconds: widget.timerState.totalSeconds,
              colors: colors,
              onStart: () {
                HapticFeedback.mediumImpact();
                widget.onStartRest(widget.timerState.totalSeconds);
              },
              onDurationChange: widget.onDurationChange,
            ),
          ),
      ],
    );
  }
}

/// Botón de acción compacto para el timer
class _TimerMiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _TimerMiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: colors.onSurfaceVariant),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        side: BorderSide(color: colors.outlineVariant),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Chip compacto para iniciar timer cuando está inactivo
class _InactiveTimerChip extends StatelessWidget {
  final int totalSeconds;
  final ColorScheme colors;
  final VoidCallback onStart;
  final void Function(int) onDurationChange;

  const _InactiveTimerChip({
    required this.totalSeconds,
    required this.colors,
    required this.onStart,
    required this.onDurationChange,
  });

  @override
  Widget build(BuildContext context) {
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    final label = min > 0
        ? '$min:${sec.toString().padLeft(2, '0')}'
        : '${totalSeconds}s';

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                onDurationChange(totalSeconds > 30 ? totalSeconds - 30 : totalSeconds),
            child: Icon(Icons.remove_rounded, size: 18, color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onDurationChange(totalSeconds + 30),
            child: Icon(Icons.add_rounded, size: 18, color: colors.onSurfaceVariant),
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('INICIAR'),
          ),
        ],
      ),
    );
  }
}
