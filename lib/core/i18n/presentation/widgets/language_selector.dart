import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/design_system.dart';
import '../../domain/entities/app_language.dart';
import '../providers/language_provider.dart';
import '../providers/translations_provider.dart';

/// Selector de idioma como cards verticales para onboarding
class LanguageSelector extends ConsumerWidget {
  /// Callback opcional cuando se selecciona un idioma
  final ValueChanged<AppLanguage>? onSelected;

  const LanguageSelector({super.key, this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: AppLanguage.values.map((language) {
        final isSelected = language == currentLanguage;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Material(
            color: isSelected
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(languageProvider.notifier).setLanguage(language);
                onSelected?.call(language);
              },
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isSelected
                        ? colors.primary
                        : colors.outline.withAlpha((0.3 * 255).round()),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      language.flag,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Text(
                        language.displayName,
                        style: AppTypography.titleMedium.copyWith(
                          color: isSelected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: colors.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Toggle compacto de idioma para usar en settings/profile
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final colors = Theme.of(context).colorScheme;

    return SegmentedButton<AppLanguage>(
      selected: {currentLanguage},
      onSelectionChanged: (set) {
        HapticFeedback.selectionClick();
        ref.read(languageProvider.notifier).setLanguage(set.first);
      },
      segments: AppLanguage.values.map((language) {
        return ButtonSegment<AppLanguage>(
          value: language,
          label: Text(language.displayName),
          icon: Text(
            language.flag,
            style: const TextStyle(fontSize: 18),
          ),
        );
      }).toList(),
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(colors.onSurface),
      ),
    );
  }
}

/// Chip compacto que muestra el idioma actual y abre un bottom sheet
class LanguageChip extends ConsumerWidget {
  const LanguageChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final colors = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Text(language.flag),
      label: Text(
        language.displayName,
        style: AppTypography.labelMedium.copyWith(
          color: colors.onSurface,
        ),
      ),
      onPressed: () => _showLanguageSheet(context, ref),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final t = ref.read(translationsProvider).valueOrNull;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t?.translate('common.changeLanguage') ?? 'Cambiar idioma',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              LanguageSelector(
                onSelected: (_) => Navigator.of(ctx).pop(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
