// ============================================================================
// APP STATES - Estados de UI (loading, empty, error)
// ============================================================================

import 'package:flutter/material.dart';
import '../design_system/app_theme.dart';
import 'app_button.dart';

/// Estado de carga
class AppLoading extends StatelessWidget {
  final String? message;
  final double size;

  const AppLoading({
    super.key,
    this.message,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Estado vacío
class AppEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: colors.onSurfaceVariant.withAlpha((0.5 * 255).round()),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de error
class AppError extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const AppError({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.headlineSmall.copyWith(
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                details!,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: 'Reintentar',
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader animado para estados de carga de contenido
/// MD-004: Efecto shimmer para mejor feedback visual
class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
  });

  const AppSkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 9999;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutSine,
    ));
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                colors.surfaceContainerHighest,
                colors.surfaceContainerHighest.withAlpha((0.7 * 255).round()),
                colors.surfaceContainerHighest,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Lista de skeletons
class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const AppSkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 64,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppSkeleton(
            width: double.infinity,
            height: itemHeight,
          ),
        );
      },
    );
  }
}

/// Skeleton específico para la pantalla de Diario
/// Muestra la estructura completa: calendario, resumen y secciones de comidas
class DiarySkeleton extends StatelessWidget {
  const DiarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendario semanal
          const AppSkeleton(
            width: double.infinity,
            height: 90,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Card de resumen diario
          const AppSkeleton(
            width: double.infinity,
            height: 200,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Quick add chips
          Row(
            children: [
              const AppSkeleton(width: 120, height: 44),
              const SizedBox(width: AppSpacing.md),
              const AppSkeleton(width: 100, height: 44),
              const SizedBox(width: AppSpacing.md),
              const AppSkeleton(width: 110, height: 44),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Secciones de comidas
          ...List.generate(4, (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: const AppSkeleton(
              width: double.infinity,
              height: 120,
            ),
          )),
        ],
      ),
    );
  }
}

/// Skeleton específico para la pantalla de Resumen
class SummarySkeleton extends StatelessWidget {
  const SummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de stats
          Row(
            children: [
              const Expanded(
                child: AppSkeleton(width: double.infinity, height: 100),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: AppSkeleton(width: double.infinity, height: 100),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: AppSkeleton(width: double.infinity, height: 100),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Gráfico
          const AppSkeleton(
            width: double.infinity,
            height: 250,
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Lista de datos
          ...List.generate(5, (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: const AppSkeleton(
              width: double.infinity,
              height: 64,
            ),
          )),
        ],
      ),
    );
  }
}
