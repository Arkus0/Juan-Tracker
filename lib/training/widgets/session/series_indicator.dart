import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';

/// Indicador de series prominente y visible.
/// Responde a: "¿Cuántas llevo? ¿Cuántas quedan?"
/// - Cuando expandido: Muestra "Serie X / Y" con barra de progreso visual
/// - Cuando colapsado: Muestra "X/Y" compacto
/// - Última serie: Destaca con color especial y mensaje "¡ÚLTIMA!"
class SeriesIndicator extends StatelessWidget {
  final int currentSet;
  final int totalSets;
  final int completedSets;
  final bool isCollapsed;
  final bool isLastSet;

  const SeriesIndicator({
    super.key,
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
