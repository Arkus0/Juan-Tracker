import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/i18n/i18n.dart';

/// Toggle de idioma específico para la sección de entrenamiento
///
/// Muestra una card con el idioma actual y un SegmentedButton para cambiar.
/// Pensado para incluirse en pantallas de configuración de entrenamiento.
class WorkoutLanguageToggle extends ConsumerWidget {
  const WorkoutLanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final t = ref.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.translate, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('training.language'),
                    style: AppTypography.labelLarge.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t('training.languageDescription'),
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const LanguageToggle(),
      ],
    );
  }
}
