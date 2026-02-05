import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../providers/session_timer_provider.dart';

/// Widget que muestra el tiempo transcurrido de la sesión.
///
/// Diseño compacto para mostrar en el AppBar de la pantalla de entrenamiento.
/// Cambia de color si la sesión es muy larga (>1h amarillo, >2h rojo).
class SessionTimerDisplay extends ConsumerWidget {
  final bool showIcon;
  final bool compact;

  const SessionTimerDisplay({
    super.key,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerAsync = ref.watch(sessionTimerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return timerAsync.when(
      data: (duration) => _buildContent(context, duration, colorScheme),
      loading: () => _buildPlaceholder(colorScheme),
      error: (_, _) => _buildPlaceholder(colorScheme),
    );
  }

  Widget _buildContent(BuildContext context, Duration duration, ColorScheme colorScheme) {
    final isLong = duration.isLongSession;
    final isVeryLong = duration.isVeryLongSession;
    
    // Color según duración
    final color = isVeryLong 
        ? AppColors.error 
        : isLong 
            ? AppColors.warning 
            : colorScheme.primary;

    final timeText = compact 
        ? duration.formattedShort 
        : duration.formatted;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withAlpha(50),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.timer_outlined,
              size: compact ? 14 : 16,
              color: color,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            timeText,
            style: (compact ? AppTypography.labelMedium : AppTypography.bodyMedium).copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()], // Números monoespaciados
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.timer_outlined,
              size: compact ? 14 : 16,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            compact ? '0m' : '00:00',
            style: (compact ? AppTypography.labelMedium : AppTypography.bodyMedium).copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Versión expandida del cronómetro para mostrar en un panel o bottom sheet.
///
/// Muestra información adicional como tiempo estimado restante o alertas.
class SessionTimerExpanded extends ConsumerWidget {
  const SessionTimerExpanded({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerAsync = ref.watch(sessionTimerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return timerAsync.when(
      data: (duration) => _buildExpanded(context, duration, colorScheme),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildExpanded(BuildContext context, Duration duration, ColorScheme colorScheme) {
    final isLong = duration.isLongSession;
    final isVeryLong = duration.isVeryLongSession;
    
    String? alertMessage;
    if (isVeryLong) {
      alertMessage = '⚠️ Sesión muy larga. Considera finalizar para evitar sobreentrenamiento.';
    } else if (isLong) {
      alertMessage = '⏱️ Llevas más de 1 hora. Mantén la hidratación.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isVeryLong 
              ? AppColors.error 
              : isLong 
                  ? AppColors.warning 
                  : colorScheme.outline,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: isVeryLong 
                    ? AppColors.error 
                    : isLong 
                        ? AppColors.warning 
                        : colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tiempo de Sesión',
                style: AppTypography.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            duration.formatted,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isVeryLong 
                  ? AppColors.error 
                  : isLong 
                      ? AppColors.warning 
                      : colorScheme.primary,
            ),
          ),
          if (alertMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (isVeryLong ? AppColors.error : AppColors.warning).withAlpha(20),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    isVeryLong ? Icons.warning_amber : Icons.info,
                    color: isVeryLong ? AppColors.error : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      alertMessage,
                      style: AppTypography.bodySmall.copyWith(
                        color: isVeryLong ? AppColors.error : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
