/// ============================================================================
/// SISTEMA DE CELEBRACIONES MEJORADO — UX-004
/// ============================================================================
///
/// Implementa:
/// - Confetti animation para PRs personales
/// - Scale animation para completar series
/// - Feedback háptico mejorado
///
/// PRINCIPIOS:
/// - Celebraciones breves (máx 2s)
/// - No interrumpir el flujo de entrenamiento
/// - Feedback inmediato y satisfactorio
/// ============================================================================

library;

import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/design_system.dart';

/// Controller para gestionar celebraciones
class CelebrationController {
  static final CelebrationController _instance = CelebrationController._internal();
  factory CelebrationController() => _instance;
  CelebrationController._internal();

  OverlayEntry? _currentOverlay;

  /// Muestra celebración de confetti para PR
  void showConfettiCelebration(
    BuildContext context, {
    required String title,
    String? subtitle,
    Color? primaryColor,
  }) {
    // Haptic fuerte para PR
    HapticFeedback.heavyImpact();
    
    _currentOverlay?.remove();
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _ConfettiCelebrationOverlay(
        title: title,
        subtitle: subtitle,
        primaryColor: primaryColor ?? AppColors.goldAccent,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );
    
    Overlay.of(context).insert(_currentOverlay!);
    
    // Auto-remover después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }

  /// Muestra micro-celebración para serie completada
  void showSetCompleteCelebration(BuildContext context, {int setNumber = 1}) {
    // Haptic medio para serie
    HapticFeedback.mediumImpact();
    
    _currentOverlay?.remove();
    
    _currentOverlay = OverlayEntry(
      builder: (context) => _SetCompleteOverlay(
        setNumber: setNumber,
        onComplete: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );
    
    Overlay.of(context).insert(_currentOverlay!);
    
    // Auto-remover rápidamente (1s)
    Future.delayed(const Duration(seconds: 1), () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }
}

/// Overlay de confetti para celebraciones de PR
class _ConfettiCelebrationOverlay extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Color primaryColor;
  final VoidCallback onComplete;

  const _ConfettiCelebrationOverlay({
    required this.title,
    this.subtitle,
    required this.primaryColor,
    required this.onComplete,
  });

  @override
  State<_ConfettiCelebrationOverlay> createState() => _ConfettiCelebrationOverlayState();
}

class _ConfettiCelebrationOverlayState extends State<_ConfettiCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Generar partículas de confetti
    _particles = List.generate(50, (index) => _ConfettiParticle(
      color: _getRandomColor(),
      x: _random.nextDouble(),
      y: -0.1 - _random.nextDouble() * 0.5,
      size: 5 + _random.nextDouble() * 10,
      rotation: _random.nextDouble() * 360,
      velocity: 0.3 + _random.nextDouble() * 0.4,
      rotationSpeed: (_random.nextDouble() - 0.5) * 10,
    ));

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  Color _getRandomColor() {
    final colors = [
      AppColors.goldAccent,
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      Colors.white,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Fondo semitransparente
            FadeTransition(
              opacity: Tween<double>(begin: 0, end: 0.3).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0, 0.3, curve: Curves.easeOut),
                ),
              ),
              child: Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Partículas de confetti
            ..._particles.map((particle) {
              final progress = _controller.value;
              final y = particle.y + progress * particle.velocity;
              final x = particle.x + mathSin(progress * 4 + particle.rotation) * 0.1;
              final rotation = particle.rotation + progress * particle.rotationSpeed * 360;
              final opacity = progress < 0.8 ? 1.0 : 1.0 - (progress - 0.8) * 5;

              return Positioned(
                left: x * MediaQuery.of(context).size.width,
                top: y * MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: rotation * 3.14159 / 180,
                    child: Container(
                      width: particle.size,
                      height: particle.size * 0.6,
                      decoration: BoxDecoration(
                        color: particle.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Contenido central
            Center(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
                  ),
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.5, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: const Interval(0.1, 0.5, curve: Curves.elasticOut),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: widget.primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 64,
                          color: widget.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.title,
                          style: AppTypography.headlineMedium.copyWith(
                            color: widget.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.subtitle!,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Overlay rápido para completar serie
class _SetCompleteOverlay extends StatefulWidget {
  final int setNumber;
  final VoidCallback onComplete;

  const _SetCompleteOverlay({
    required this.setNumber,
    required this.onComplete,
  });

  @override
  State<_SetCompleteOverlay> createState() => _SetCompleteOverlayState();
}

class _SetCompleteOverlayState extends State<_SetCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 100,
      left: 0,
      right: 0,
      child: Center(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _controller,
              curve: const Interval(0, 0.3, curve: Curves.easeOut),
            ),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.5, end: 1).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0, 0.5, curve: Curves.elasticOut),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppRadius.round),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Serie ${widget.setNumber} completada',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modelo de partícula de confetti
class _ConfettiParticle {
  final Color color;
  final double x;
  double y;
  final double size;
  double rotation;
  final double velocity;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.velocity,
    required this.rotationSpeed,
  });
}

/// Helper para función seno
double mathSin(double x) {
  // Aproximación simple de seno
  return (x % 6.28318) > 3.14159 ? -1 : 1;
}

/// Widget de checkbox animado para completar series
class AnimatedCompleteCheckbox extends StatefulWidget {
  final bool isCompleted;
  final ValueChanged<bool?> onChanged;

  const AnimatedCompleteCheckbox({
    super.key,
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  State<AnimatedCompleteCheckbox> createState() => _AnimatedCompleteCheckboxState();
}

class _AnimatedCompleteCheckboxState extends State<AnimatedCompleteCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(AnimatedCompleteCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: SizedBox(
        width: 40,
        height: 40,
        child: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: widget.isCompleted,
            activeColor: AppColors.success,
            checkColor: Colors.white,
            onChanged: widget.onChanged,
            side: BorderSide(
              color: widget.isCompleted ? AppColors.success : Colors.grey[600]!,
              width: 2,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
    );
  }
}
