import 'dart:math';
import 'package:flutter/material.dart';

/// Partícula de confetti con física simple.
class _ConfettiParticle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double rotation;
  double rotationSpeed;
  double size;
  Color color;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
  });
}

/// Overlay de confetti que se lanza desde el centro-superior y cae con gravedad.
///
/// Uso:
/// ```dart
/// ConfettiOverlay(
///   trigger: showConfetti,       // true para disparar
///   onComplete: () => setState(() => showConfetti = false),
///   child: Text('¡NUEVO PR!'),   // widget central opcional
/// )
/// ```
class ConfettiOverlay extends StatefulWidget {
  /// Cuando cambia de false→true, dispara la animación.
  final bool trigger;

  /// Se llama cuando la animación termina para que el padre resetee el trigger.
  final VoidCallback? onComplete;

  /// Widget superpuesto al centro (ej: texto "¡NUEVO PR!").
  final Widget? child;

  /// Duración total de la animación de confetti.
  final Duration duration;

  /// Cantidad de partículas.
  final int particleCount;

  const ConfettiOverlay({
    super.key,
    required this.trigger,
    this.onComplete,
    this.child,
    this.duration = const Duration(milliseconds: 2200),
    this.particleCount = 80,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();
  bool _isActive = false;

  // Colores festivos dorados/amarillos con toques de color
  static const _colors = [
    Color(0xFFFFD700), // gold
    Color(0xFFFFA500), // orange
    Color(0xFFFF6347), // tomato
    Color(0xFF00BFFF), // deep sky blue
    Color(0xFF7CFC00), // lawn green
    Color(0xFFFF69B4), // hot pink
    Color(0xFFFFFFFF), // white
    Color(0xFFE6BE8A), // gold muted
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _isActive = false;
          _particles.clear();
          widget.onComplete?.call();
        }
      });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _fire();
    }
  }

  void _fire() {
    _particles.clear();
    for (var i = 0; i < widget.particleCount; i++) {
      _particles.add(_ConfettiParticle(
        x: 0.5 + (_random.nextDouble() - 0.5) * 0.3,
        y: 0.15,
        velocityX: (_random.nextDouble() - 0.5) * 0.8,
        velocityY: -0.5 - _random.nextDouble() * 0.8,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        size: 4 + _random.nextDouble() * 6,
        color: _colors[_random.nextInt(_colors.length)],
      ));
    }
    _isActive = true;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(
          particles: _particles,
          progress: _controller.value,
        ),
        size: Size.infinite,
        child: widget.child != null
            ? Center(
                child: AnimatedOpacity(
                  opacity: _controller.value < 0.7 ? 1.0 : 1.0 - ((_controller.value - 0.7) / 0.3),
                  duration: const Duration(milliseconds: 100),
                  child: widget.child,
                ),
              )
            : null,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gravity = 1.8;

    for (final p in particles) {
      final t = progress;

      // Posición con gravedad
      final x = (p.x + p.velocityX * t) * size.width;
      final y = (p.y + p.velocityY * t + 0.5 * gravity * t * t) * size.height;

      // Fade out en el último 30%
      final opacity = t > 0.7 ? (1.0 - (t - 0.7) / 0.3) : 1.0;
      if (opacity <= 0) continue;

      // Fuera de pantalla = skip
      if (y > size.height || y < -50 || x < -50 || x > size.width + 50) {
        continue;
      }

      final rotation = p.rotation + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = p.color.withAlpha((opacity * 255).round())
        ..style = PaintingStyle.fill;

      // Rectángulo pequeño (confetti)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
