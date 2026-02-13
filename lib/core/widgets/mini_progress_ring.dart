import 'package:flutter/material.dart';

/// Compact circular progress indicator with percentage label.
///
/// Used on mode cards (Entry, Today) to show kcal progress at a glance.
/// Turns red when [progress] > 1.0 (over limit).
class MiniProgressRing extends StatelessWidget {
  final double progress;
  final double size;

  const MiniProgressRing({
    super.key,
    required this.progress,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isOverLimit = progress > 1.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 4,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withAlpha((0.2 * 255).round()),
            ),
          ),
          // Progress arc
          CircularProgressIndicator(
            value: clampedProgress,
            strokeWidth: 4,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              isOverLimit ? Colors.red.shade300 : Colors.white,
            ),
          ),
          // Percentage text
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
