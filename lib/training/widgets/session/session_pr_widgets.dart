import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart' as core;

/// Toast dorado que aparece durante la celebración de PR.
class PrToast extends StatelessWidget {
  final String exerciseName;
  final double weight;
  final int reps;

  const PrToast({
    super.key,
    required this.exerciseName,
    required this.weight,
    required this.reps,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(core.AppRadius.xl),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha(60),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 36),
          const SizedBox(height: 8),
          Text(
            '¡NUEVO PR!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFD700),
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$exerciseName — ${weight}kg × $reps',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Bracket visual para agrupar ejercicios en superseries.
/// Dibuja una barra vertical coloreada a la izquierda con
/// esquinas redondeadas arriba (isFirst) y abajo (isLast).
class SupersetBracket extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Widget child;

  const SupersetBracket({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bracketColor = colors.tertiary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra vertical del bracket
        SizedBox(
          width: 6,
          child: Container(
            margin: EdgeInsets.only(
              left: 2,
              top: isFirst ? 8 : 0,
              bottom: isLast ? 8 : 0,
            ),
            decoration: BoxDecoration(
              color: bracketColor.withAlpha((0.6 * 255).round()),
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(3) : Radius.zero,
                bottom: isLast ? const Radius.circular(3) : Radius.zero,
              ),
            ),
          ),
        ),
        // Contenido (exercise card)
        Expanded(child: child),
      ],
    );
  }
}
