// ============================================================================
// APP BUTTON - Componentes de botón reutilizables
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_theme.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  danger,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  });

  factory AppButton.primary({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      size: size,
      icon: icon,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  factory AppButton.secondary({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
    bool isLoading = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      size: size,
      icon: icon,
      isLoading: isLoading,
    );
  }

  factory AppButton.outlined({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.outlined,
      size: size,
      icon: icon,
    );
  }

  factory AppButton.ghost({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.small,
    IconData? icon,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.ghost,
      size: size,
      icon: icon,
    );
  }

  factory AppButton.danger({
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    IconData? icon,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.danger,
      size: size,
      icon: icon,
    );
  }

  EdgeInsets get _padding {
    if (padding != null) return padding!;
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  TextStyle get _textStyle {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.labelMedium;
      case AppButtonSize.medium:
        return AppTypography.labelLarge;
      case AppButtonSize.large:
        return AppTypography.titleMedium;
    }
  }

  void _handleTap() {
    if (onPressed != null && !isLoading) {
      HapticFeedback.lightImpact();
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.primary 
                  ? colors.onPrimary 
                  : colors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: _iconSize),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(label, style: _textStyle),
      ],
    );

    if (isFullWidth) {
      buttonChild = SizedBox(
        width: double.infinity,
        child: Center(child: buttonChild),
      );
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return FilledButton(
          onPressed: isLoading ? null : _handleTap,
          style: FilledButton.styleFrom(
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: buttonChild,
        );

      case AppButtonVariant.secondary:
        return FilledButton.tonal(
          onPressed: isLoading ? null : _handleTap,
          style: FilledButton.styleFrom(
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: buttonChild,
        );

      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isLoading ? null : _handleTap,
          style: OutlinedButton.styleFrom(
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: buttonChild,
        );

      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : _handleTap,
          style: TextButton.styleFrom(
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: buttonChild,
        );

      case AppButtonVariant.danger:
        return FilledButton(
          onPressed: isLoading ? null : _handleTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: buttonChild,
        );
    }
  }
}

/// Botón de icono circular
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
  });

  double get _size {
    switch (size) {
      case AppButtonSize.small:
        return 32;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 56;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }

  void _handleTap() {
    if (onPressed != null) {
      HapticFeedback.lightImpact();
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget button = InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(_size / 2),
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: variant == AppButtonVariant.primary
              ? colors.primary
              : variant == AppButtonVariant.secondary
                  ? colors.secondaryContainer
                  : Colors.transparent,
          border: variant == AppButtonVariant.outlined
              ? Border.all(color: colors.outline)
              : null,
          borderRadius: BorderRadius.circular(_size / 2),
        ),
        child: Icon(
          icon,
          size: _iconSize,
          color: variant == AppButtonVariant.primary
              ? colors.onPrimary
              : variant == AppButtonVariant.secondary
                  ? colors.onSecondaryContainer
                  : colors.primary,
        ),
      ),
    );

    return button;
  }
}

/// Botón flotante de acción principal (FAB)
class AppFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  const AppFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      icon: Icon(icon),
      label: Text(label ?? ''),
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}
