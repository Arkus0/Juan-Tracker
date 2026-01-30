import 'package:flutter/material.dart';

/// HIGH-002 FIX: Snackbar consistente con duración y estilo unificado
///
/// Uso:
/// ```dart
/// AppSnackbar.show(context, message: 'Guardado');
/// AppSnackbar.showWithUndo(context, message: 'Eliminado', onUndo: () => restore());
/// AppSnackbar.showError(context, message: 'Error al guardar');
/// ```
class AppSnackbar {
  /// Duración estándar para mensajes informativos (3 segundos)
  static const Duration defaultDuration = Duration(seconds: 3);

  /// Duración extendida para acciones con undo (5 segundos)
  static const Duration undoDuration = Duration(seconds: 5);

  /// Duración corta para confirmaciones rápidas (2 segundos)
  static const Duration shortDuration = Duration(seconds: 2);

  /// Muestra un snackbar estándar con icono de éxito
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = defaultDuration,
  }) {
    _showSnackbar(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: Colors.white,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Muestra un snackbar con acción de deshacer
  static void showWithUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) {
    _showSnackbar(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: Colors.white,
      actionLabel: 'DESHACER',
      onAction: onUndo,
      duration: undoDuration,
    );
  }

  /// Muestra un snackbar de error
  static void showError(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colors.onError, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onError),
              ),
            ),
          ],
        ),
        backgroundColor: colors.error,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: colors.onError,
                onPressed: onAction ?? () {},
              )
            : null,
        duration: defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Muestra un snackbar de advertencia
  static void showWarning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.black87, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.black87,
                onPressed: onAction ?? () {},
              )
            : null,
        duration: defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Implementación interna
  static void _showSnackbar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
  }) {
    final colors = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: colors.primaryContainer,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: colors.primary,
                onPressed: onAction ?? () {},
              )
            : null,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
