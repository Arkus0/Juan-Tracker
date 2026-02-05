import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/tdee_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../../../diet/providers/body_progress_providers.dart';
import 'body_progress_screen.dart';

/// Pantalla de Perfil y Ajustes
///
/// Centraliza:
/// - Datos del perfil (edad, sexo, altura, peso)
/// - Cálculo de TDEE
/// - Acceso a objetivos
/// - Biblioteca de alimentos
/// - Selección de idioma
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final t = ref.tr;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Text(t('settings.title')),
            centerTitle: true,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: HomeButton(),
            ),
          ),
          SliverToBoxAdapter(
            child: profileAsync.when(
              data: (profile) => _SettingsContent(profile: profile),
              loading: () => const AppLoading(),
              error: (e, _) => AppError(
                message: t('settings.errorLoadProfile'),
                onRetry: () => ref.invalidate(userProfileProvider),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  final UserProfileModel? profile;

  const _SettingsContent({this.profile});

  @override
  Widget build(BuildContext context) {
    final isComplete = profile?.isComplete ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección Perfil
        _ProfileSection(profile: profile, isComplete: isComplete),

        const SizedBox(height: AppSpacing.lg),

        // Sección Idioma
        const _LanguageSection(),

        const SizedBox(height: AppSpacing.lg),

        // Sección Progreso Corporal
        const _BodyProgressSection(),

        const SizedBox(height: AppSpacing.lg),

        // Sección Biblioteca
        const _LibrarySection(),

        const SizedBox(height: AppSpacing.lg),

        // Sección Consejos y Atajos
        const _TipsAndTricksSection(),

        // Debug section (only in debug mode)
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.lg),
          const _DebugSection(),
        ],
      ],
    );
  }
}

// ============================================================================
// LANGUAGE SECTION
// ============================================================================

class _LanguageSection extends ConsumerWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final t = ref.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.translate,
                    color: colors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('settings.languageSection'),
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        t('settings.languageSectionDesc'),
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const LanguageToggle(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE SECTION
// ============================================================================

class _ProfileSection extends ConsumerWidget {
  final UserProfileModel? profile;
  final bool isComplete;

  const _ProfileSection({required this.profile, required this.isComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final t = ref.tr;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AppCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isComplete ? AppColors.success : colors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isComplete ? Icons.check_circle : Icons.person,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('settings.yourData'),
                      style: AppTypography.titleMedium,
                    ),
                    Text(
                      isComplete
                          ? t('settings.profileComplete')
                          : t('settings.completeProfile'),
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            _ProfileInfoRow(
              icon: Icons.cake,
              label: t('settings.age'),
              value: profile?.age != null
                  ? '${profile!.age} ${t('units.years')}'
                  : t('common.notConfigured'),
            ),
            _ProfileInfoRow(
              icon: Icons.person,
              label: t('settings.sex'),
              value: profile?.gender?.displayName ?? t('common.notConfigured'),
            ),
            _ProfileInfoRow(
              icon: Icons.height,
              label: t('settings.height'),
              value: profile?.heightCm != null
                  ? '${profile!.heightCm!.toStringAsFixed(0)} ${t('units.cm')}'
                  : t('common.notConfigured'),
            ),
            _ProfileInfoRow(
              icon: Icons.scale,
              label: t('settings.currentWeight'),
              value: profile?.currentWeightKg != null
                  ? '${profile!.currentWeightKg!.toStringAsFixed(1)} ${t('units.kg')}'
                  : t('common.notConfigured'),
            ),
            _ProfileInfoRow(
              icon: Icons.local_fire_department,
              label: t('settings.activityLevel'),
              value: profile?.activityLevel.displayName ?? t('settings.moderate'),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            onPressed: () => _showEditProfileDialog(context, profile),
            label: isComplete
                ? t('settings.editProfile')
                : t('settings.completeProfileBtn'),
            isFullWidth: true,
          ),
        ],
      ),
    ),
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfileModel? profile) {
    showDialog(
      context: context,
      builder: (ctx) => _EditProfileDialog(profile: profile),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibrarySection extends ConsumerWidget {
  const _LibrarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final t = ref.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t('settings.foodLibrary'),
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t('settings.manageFoods'),
              style: AppTypography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              variant: AppButtonVariant.secondary,
              onPressed: () => context.pushTo(AppRouter.nutritionFoods),
              icon: Icons.restaurant_menu,
              label: t('settings.viewLibrary'),
              isFullWidth: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Text(
              t('settings.maintenance'),
              style: AppTypography.labelLarge.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _CleanupDuplicatesButton(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BODY PROGRESS SECTION
// ============================================================================

class _BodyProgressSection extends ConsumerWidget {
  const _BodyProgressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final latestAsync = ref.watch(latestMeasurementProvider);
    final t = ref.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.straighten,
                    color: colors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('settings.bodyProgress'),
                        style: AppTypography.titleMedium,
                      ),
                      latestAsync.when(
                        data: (latest) => Text(
                          latest != null
                              ? t('settings.lastMeasure', args: {
                                  'date': _formatDate(latest.date, t),
                                })
                              : t('settings.recordMeasures'),
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BodyProgressScreen(),
                ),
              ),
              icon: Icons.trending_up,
              label: t('settings.viewProgress'),
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(
    DateTime date,
    String Function(String, {Map<String, String>? args, int? count}) t,
  ) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return t('common.today');
    if (diff == 1) return t('common.yesterday');
    if (diff < 7) return t('common.daysAgo', count: diff);
    if (diff < 30) return t('common.weeksAgo', count: diff ~/ 7);
    return t('common.monthsAgo', count: diff ~/ 30);
  }
}

/// Botón para limpiar duplicados de alimentos
class _CleanupDuplicatesButton extends ConsumerStatefulWidget {
  const _CleanupDuplicatesButton();

  @override
  ConsumerState<_CleanupDuplicatesButton> createState() => _CleanupDuplicatesButtonState();
}

class _CleanupDuplicatesButtonState extends ConsumerState<_CleanupDuplicatesButton> {
  bool _isLoading = false;
  int? _duplicatesFound;

  Future<void> _checkDuplicates() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final groups = await db.findDuplicateFoods();
      setState(() {
        _duplicatesFound = groups.fold<int>(0, (sum, g) => sum + g.count - 1);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanupDuplicates() async {
    final t = ref.read(translationsProvider).valueOrNull;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t?.translate('settings.cleanDuplicatesTitle') ?? 'Limpiar duplicados'),
        content: Text(
          t?.translate('settings.cleanDuplicatesMessage',
                  args: {'count': '$_duplicatesFound'}) ??
              'Se fusionarán $_duplicatesFound alimentos duplicados. '
                  'El alimento más usado se mantendrá y las referencias se actualizarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t?.translate('common.cancel') ?? 'CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t?.translate('settings.cleanDuplicates') ?? 'LIMPIAR'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final removed = await db.cleanupAllDuplicates();
      if (mounted) {
        final msg = t?.translate('settings.duplicatesRemoved',
                args: {'count': '$removed'}) ??
            'Se eliminaron $removed duplicados';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        setState(() => _duplicatesFound = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final t = ref.tr;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_duplicatesFound == null) {
      return TextButton.icon(
        onPressed: _checkDuplicates,
        icon: const Icon(Icons.find_replace),
        label: Text(t('settings.findDuplicates')),
      );
    }

    if (_duplicatesFound == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              t('settings.noDuplicates'),
              style: AppTypography.bodyMedium.copyWith(color: colors.primary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, color: colors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              t('settings.duplicatesFound', args: {'count': '$_duplicatesFound'}),
              style: AppTypography.bodyMedium.copyWith(color: colors.error),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          variant: AppButtonVariant.secondary,
          onPressed: _cleanupDuplicates,
          icon: Icons.cleaning_services,
          label: t('settings.cleanDuplicates'),
          isFullWidth: true,
        ),
      ],
    );
  }
}

// ============================================================================
// EDIT PROFILE DIALOG
// ============================================================================

class _EditProfileDialog extends ConsumerStatefulWidget {
  final UserProfileModel? profile;

  const _EditProfileDialog({this.profile});

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  Gender? _gender;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _ageController = TextEditingController(text: p?.age?.toString() ?? '');
    _heightController = TextEditingController(
      text: p?.heightCm?.toStringAsFixed(0) ?? '',
    );
    _weightController = TextEditingController(
      text: p?.currentWeightKg?.toStringAsFixed(1) ?? '',
    );
    _gender = p?.gender;
    _activityLevel = p?.activityLevel ?? ActivityLevel.moderatelyActive;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.tr;

    return AlertDialog(
      title: Text(t('settings.editProfileTitle')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edad
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t('settings.ageLabel'),
                suffixText: t('units.years'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Sexo
            SegmentedButton<Gender?>(
              selected: {_gender},
              onSelectionChanged: (set) => setState(() => _gender = set.first),
              segments: [
                ButtonSegment(
                  value: Gender.male,
                  label: Text(t('settings.male')),
                  icon: const Icon(Icons.male),
                ),
                ButtonSegment(
                  value: Gender.female,
                  label: Text(t('settings.female')),
                  icon: const Icon(Icons.female),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Altura
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t('settings.heightLabel'),
                suffixText: t('units.cm'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Peso
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t('settings.weightLabel'),
                suffixText: t('units.kg'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Nivel de actividad
            DropdownButtonFormField<ActivityLevel>(
              initialValue: _activityLevel,
              decoration: InputDecoration(
                labelText: t('settings.activityLevel'),
                border: const OutlineInputBorder(),
              ),
              items: ActivityLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.displayName),
                );
              }).toList(),
              onChanged: (v) => setState(() => _activityLevel = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t('common.cancel')),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(t('common.save')),
        ),
      ],
    );
  }

  void _save() async {
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    final t = ref.read(translationsProvider).valueOrNull;

    if (age == null || height == null || weight == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t?.translate('settings.completeAllFields') ??
                'Completa todos los campos',
          ),
        ),
      );
      return;
    }

    // Validar
    final error = TdeeCalculator.validateProfile(
      age: age,
      heightCm: height,
      weightKg: weight,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final profile = UserProfileModel(
      id: 'user_profile',
      age: age,
      gender: _gender,
      heightCm: height,
      currentWeightKg: weight,
      activityLevel: _activityLevel,
      createdAt: widget.profile?.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(userProfileRepositoryProvider).save(profile);

    if (mounted) {
      ref.invalidate(userProfileProvider);
      Navigator.of(context).pop();
    }
  }
}

// ============================================================================
// TIPS AND TRICKS SECTION - Ayuda para nuevos usuarios
// ============================================================================

class _TipsAndTricksSection extends ConsumerWidget {
  const _TipsAndTricksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final t = ref.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.tips_and_updates,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('settings.tipsTitle'),
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        t('settings.tipsSubtitle'),
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Tips
            _TipItem(
              icon: Icons.search,
              title: t('settings.tipSearch'),
              description: t('settings.tipSearchDesc'),
            ),
            _TipItem(
              icon: Icons.history,
              title: t('settings.tipFrequent'),
              description: t('settings.tipFrequentDesc'),
            ),
            _TipItem(
              icon: Icons.copy_all,
              title: t('settings.tipRepeat'),
              description: t('settings.tipRepeatDesc'),
            ),
            _TipItem(
              icon: Icons.bookmark,
              title: t('settings.tipTemplates'),
              description: t('settings.tipTemplatesDesc'),
            ),
            _TipItem(
              icon: Icons.qr_code_scanner,
              title: t('settings.tipBarcode'),
              description: t('settings.tipBarcodeDesc'),
            ),
            _TipItem(
              icon: Icons.auto_graph,
              title: t('settings.tipCoach'),
              description: t('settings.tipCoachDesc'),
            ),

            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: colors.primary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: colors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      t('settings.tipGrayValues'),
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DEBUG SECTION (only visible in debug mode)
// ============================================================================

class _DebugSection extends ConsumerWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final t = ref.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.bug_report,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  t('settings.debugTitle'),
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t('settings.debugOnly'),
              style: AppTypography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              variant: AppButtonVariant.secondary,
              onPressed: () => context.pushTo(AppRouter.debugSearchBenchmark),
              icon: Icons.speed,
              label: t('settings.benchmark'),
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
