import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/diet/providers/water_providers.dart';

/// Card de tracking de agua para hábitos.
///
/// Muestra un anillo de progreso, el consumo actual, botones rápidos
/// para añadir agua y la meta diaria configurable.
class WaterTrackingCard extends ConsumerWidget {
  const WaterTrackingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final water = ref.watch(waterIntakeProvider);
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Agua',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Configurar meta
              GestureDetector(
                onTap: () => _showGoalDialog(context, ref, water.goalMl),
                child: Text(
                  'Meta: ${water.goalLiters.toStringAsFixed(1)}L',
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onSurfaceVariant,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Anillo + Consumo
          Row(
            children: [
              // Anillo de progreso
              SizedBox(
                width: 64,
                height: 64,
                child: CustomPaint(
                  painter: _WaterRingPainter(
                    progress: water.progress.clamp(0.0, 1.0),
                    ringColor: Colors.blue.shade400,
                    bgColor: colors.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Icon(
                      water.goalReached
                          ? Icons.check_circle
                          : Icons.water_drop_outlined,
                      color: water.goalReached
                          ? Colors.green
                          : Colors.blue.shade400,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),

              // Texto consumo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${water.consumedMl}',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          TextSpan(
                            text: ' / ${water.goalMl} ml',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      water.goalReached
                          ? '¡Meta alcanzada! 💧'
                          : 'Faltan ${water.remainingMl} ml',
                      style: AppTypography.labelSmall.copyWith(
                        color: water.goalReached
                            ? Colors.green
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Botones rápidos
          Row(
            children: kWaterQuickAmounts.map((ml) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: ml != kWaterQuickAmounts.last ? 6 : 0,
                  ),
                  child: _WaterQuickButton(
                    ml: ml,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(waterIntakeProvider.notifier).addWater(ml);
                      AppSnackbar.showWithUndo(
                        context,
                        message: '+${ml}ml de agua',
                        onUndo: () {
                          ref
                              .read(waterIntakeProvider.notifier)
                              .removeWater(ml);
                        },
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context, WidgetRef ref, int currentGoal) {
    final controller = TextEditingController(text: currentGoal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Meta diaria de agua', style: AppTypography.titleMedium),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Meta (ml)',
            suffixText: 'ml',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                ref.read(waterIntakeProvider.notifier).setGoal(goal);
              }
              Navigator.pop(ctx);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}

/// Botón rápido para añadir agua.
class _WaterQuickButton extends StatelessWidget {
  final int ml;
  final VoidCallback onTap;

  const _WaterQuickButton({required this.ml, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.blue.shade400.withAlpha((0.1 * 255).round()),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(Icons.add, size: 14, color: Colors.blue.shade400),
              Text(
                '${ml}ml',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter para el anillo de progreso de agua.
class _WaterRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color bgColor;

  _WaterRingPainter({
    required this.progress,
    required this.ringColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 6.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        2 * math.pi * progress,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_WaterRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
