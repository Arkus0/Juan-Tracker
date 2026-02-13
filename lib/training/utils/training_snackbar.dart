import 'package:flutter/material.dart';
import 'design_system.dart';

/// Centralized SnackBar helper for the Training module.
///
/// Replaces 7+ duplicated SnackBar constructors scattered across
/// TrainingSessionScreen and ExerciseCard. Uses training design tokens
/// for consistent styling.
///
/// Usage:
/// ```dart
/// TrainingSnackbar.success(context, '¡Sesión guardada!');
/// TrainingSnackbar.info(context, 'Peso: 80.0 kg');
/// TrainingSnackbar.note(context, 'Nota guardada: ...');
/// ```
class TrainingSnackbar {
  TrainingSnackbar._();

  /// Green success snackbar with check icon (e.g. session saved, set complete)
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      iconColor: AppColors.textOnAccent,
      backgroundColor: AppColors.completedGreen,
      textColor: AppColors.textOnAccent,
    );
  }

  /// Neutral info snackbar (e.g. weight/reps set via voice)
  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.bgElevated,
    );
  }

  /// Note confirmation snackbar with edit icon
  static void note(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.edit_note_rounded,
      iconColor: AppColors.textOnAccent,
    );
  }

  /// Info-colored snackbar with note icon (voice note added)
  static void voiceNote(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.note_add,
      iconColor: AppColors.textPrimary,
      backgroundColor: AppColors.info,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                message,
                style: AppTypography.labelEmphasis.copyWith(
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? AppColors.bgElevated,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
