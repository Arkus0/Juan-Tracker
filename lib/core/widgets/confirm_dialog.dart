import 'package:flutter/material.dart';
import '../design_system/app_theme.dart';

/// Standard confirmation dialog used throughout the app.
///
/// Provides a consistent pattern for destructive confirmations
/// (delete entry, cancel session, discard changes) so users
/// always see the same UI pattern before irreversible actions.
///
/// Usage:
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context: context,
///   title: 'Eliminar entrada',
///   message: '¿Eliminar "Pollo a la plancha"?',
///   confirmLabel: 'Eliminar',
///   isDestructive: true,
/// );
/// if (confirmed) { ... }
/// ```
class ConfirmDialog {
  ConfirmDialog._();

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
  }) async {
    final colors = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: colors.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
