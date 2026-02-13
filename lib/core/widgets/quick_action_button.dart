import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_theme.dart';

/// Reusable quick action button used on Home/Entry and Today screens.
///
/// Displays an icon + label in a tappable column. Optionally styled
/// as "primary" (filled with primary color) or "default" (surface container).
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: isPrimary ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: isPrimary ? colors.onPrimary : colors.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: isPrimary ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
