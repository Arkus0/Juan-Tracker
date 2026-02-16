import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/tdee_calculator.dart';
import '../../../core/services/user_error_message.dart';
import '../../../core/widgets/widgets.dart';
import '../../../diet/providers/body_progress_providers.dart';
import '../../../diet/providers/reminder_providers.dart';
import 'body_progress_screen.dart';

/// Pantalla de Perfil y Ajustes
///
/// Centraliza:
/// - Datos del perfil (edad, sexo, altura, peso)
/// - Cálculo de TDEE
/// - Acceso a objetivos
/// - Biblioteca de alimentos
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Perfil'),
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
                message: 'Error al cargar perfil',
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

        // Sección Progreso Corporal
        const _BodyProgressSection(),

        const SizedBox(height: AppSpacing.lg),

        // Sección Biblioteca
        _LibrarySection(),

        const SizedBox(height: AppSpacing.lg),

        // Sección Recordatorios
        const _RemindersSection(),

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

class _ProfileSection extends StatelessWidget {
  final UserProfileModel? profile;
  final bool isComplete;

  const _ProfileSection({required this.profile, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                      Text('Tus Datos', style: AppTypography.titleMedium),
                      Text(
                        isComplete
                            ? 'Perfil completo'
                            : 'Completa tu perfil para calcular tu TDEE',
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
                label: 'Edad',
                value: profile?.age != null
                    ? '${profile!.age} años'
                    : 'No configurado',
              ),
              _ProfileInfoRow(
                icon: Icons.person,
                label: 'Sexo',
                value: profile?.gender?.displayName ?? 'No configurado',
              ),
              _ProfileInfoRow(
                icon: Icons.height,
                label: 'Altura',
                value: profile?.heightCm != null
                    ? '${profile!.heightCm!.toStringAsFixed(0)} cm'
                    : 'No configurado',
              ),
              _ProfileInfoRow(
                icon: Icons.scale,
                label: 'Peso actual',
                value: profile?.currentWeightKg != null
                    ? '${profile!.currentWeightKg!.toStringAsFixed(1)} kg'
                    : 'No configurado',
              ),
              _ProfileInfoRow(
                icon: Icons.local_fire_department,
                label: 'Nivel de actividad',
                value: profile?.activityLevel.displayName ?? 'Moderado',
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              onPressed: () => _showEditProfileDialog(context, profile),
              label: isComplete ? 'Editar Perfil' : 'Completar Perfil',
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

class _LibrarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Biblioteca de Alimentos', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gestiona tus alimentos guardados',
              style: AppTypography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              variant: AppButtonVariant.secondary,
              onPressed: () => context.pushTo(AppRouter.nutritionFoods),
              icon: Icons.restaurant_menu,
              label: 'Ver Biblioteca',
              isFullWidth: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Mantenimiento',
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
                        'Progreso Corporal',
                        style: AppTypography.titleMedium,
                      ),
                      latestAsync.when(
                        data: (latest) => Text(
                          latest != null
                              ? 'Última medida: ${_formatDate(latest.date)}'
                              : 'Registra tus medidas y fotos',
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
                MaterialPageRoute(builder: (_) => const BodyProgressScreen()),
              ),
              icon: Icons.trending_up,
              label: 'Ver Progreso',
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Hace $diff días';
    if (diff < 30) return 'Hace ${diff ~/ 7} semanas';
    return 'Hace ${diff ~/ 30} meses';
  }
}

/// Botón para limpiar duplicados de alimentos
class _CleanupDuplicatesButton extends ConsumerStatefulWidget {
  const _CleanupDuplicatesButton();

  @override
  ConsumerState<_CleanupDuplicatesButton> createState() =>
      _CleanupDuplicatesButtonState();
}

class _CleanupDuplicatesButtonState
    extends ConsumerState<_CleanupDuplicatesButton> {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar duplicados'),
        content: Text(
          'Se fusionarán $_duplicatesFound alimentos duplicados. '
          'El alimento más usado se mantendrá y las referencias se actualizarán.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('LIMPIAR'),
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
        AppSnackbar.show(context, message: 'Se eliminaron $removed duplicados');
        setState(() => _duplicatesFound = null);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(
          context,
          message: userErrorMessage(
            e,
            fallback: 'No se pudieron limpiar los duplicados.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
        label: const Text('Buscar duplicados'),
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
              'No hay duplicados',
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
              '$_duplicatesFound duplicados encontrados',
              style: AppTypography.bodyMedium.copyWith(color: colors.error),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          variant: AppButtonVariant.secondary,
          onPressed: _cleanupDuplicates,
          icon: Icons.cleaning_services,
          label: 'Limpiar duplicados',
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
    return AlertDialog(
      title: const Text('Editar Perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edad
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Edad *',
                suffixText: 'años',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Sexo
            SegmentedButton<Gender?>(
              selected: {_gender},
              onSelectionChanged: (set) => setState(() => _gender = set.first),
              segments: const [
                ButtonSegment(
                  value: Gender.male,
                  label: Text('Hombre'),
                  icon: Icon(Icons.male),
                ),
                ButtonSegment(
                  value: Gender.female,
                  label: Text('Mujer'),
                  icon: Icon(Icons.female),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Altura
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Altura *',
                suffixText: 'cm',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Peso
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Peso actual *',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Nivel de actividad
            DropdownButtonFormField<ActivityLevel>(
              initialValue: _activityLevel,
              decoration: const InputDecoration(
                labelText: 'Nivel de actividad',
                border: OutlineInputBorder(),
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
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  void _save() async {
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (age == null || height == null || weight == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
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
// REMINDERS SECTION - Recordatorios configurables
// ============================================================================

class _RemindersSection extends ConsumerWidget {
  const _RemindersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final reminders = ref.watch(dietRemindersProvider);
    final notifier = ref.read(dietRemindersProvider.notifier);

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
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recordatorios', style: AppTypography.titleMedium),
                      Text(
                        reminders.hasAnyEnabled
                            ? '${reminders.enabledCount} activo${reminders.enabledCount != 1 ? 's' : ''}'
                            : 'Ninguno activo',
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
            const SizedBox(height: AppSpacing.sm),

            // --- Comidas ---
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                'COMIDAS',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            _ReminderRow(
              icon: Icons.free_breakfast,
              label: 'Desayuno',
              config: reminders.breakfast,
              onToggle: notifier.toggleBreakfast,
              onTimeChanged: notifier.setBreakfastTime,
            ),
            _ReminderRow(
              icon: Icons.lunch_dining,
              label: 'Almuerzo',
              config: reminders.lunch,
              onToggle: notifier.toggleLunch,
              onTimeChanged: notifier.setLunchTime,
            ),
            _ReminderRow(
              icon: Icons.dinner_dining,
              label: 'Cena',
              config: reminders.dinner,
              onToggle: notifier.toggleDinner,
              onTimeChanged: notifier.setDinnerTime,
            ),
            _ReminderRow(
              icon: Icons.apple,
              label: 'Merienda',
              config: reminders.snack,
              onToggle: notifier.toggleSnack,
              onTimeChanged: notifier.setSnackTime,
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // --- Seguimiento ---
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                'SEGUIMIENTO',
                style: AppTypography.labelSmall.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            _ReminderRow(
              icon: Icons.monitor_weight,
              label: 'Pesaje matutino',
              config: reminders.weighIn,
              onToggle: notifier.toggleWeighIn,
              onTimeChanged: notifier.setWeighInTime,
            ),
            _ReminderRow(
              icon: Icons.water_drop,
              label: 'Hidratación',
              config: reminders.water,
              onToggle: notifier.toggleWater,
              onTimeChanged: notifier.setWaterTime,
            ),
            _ReminderRow(
              icon: Icons.auto_graph,
              label: 'Check-in semanal',
              subtitle: 'Cada lunes',
              config: reminders.weeklyCheckIn,
              onToggle: notifier.toggleWeeklyCheckIn,
              onTimeChanged: notifier.setWeeklyCheckInTime,
            ),

            // Botón para desactivar todo
            if (reminders.hasAnyEnabled) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Desactivar recordatorios'),
                        content: const Text(
                          'Se desactivaran todos los recordatorios de dieta. '
                          'Puedes volver a activarlos cuando quieras.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('CANCELAR'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('DESACTIVAR'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    try {
                      await notifier.disableAll();
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.showError(
                          context,
                          message: userErrorMessage(
                            e,
                            fallback:
                                'No se pudieron desactivar los recordatorios.',
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    Icons.notifications_off,
                    size: 18,
                    color: colors.error,
                  ),
                  label: Text(
                    'Desactivar todos',
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fila de un recordatorio con toggle y selector de hora
class _ReminderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final ReminderConfig config;
  final Future<void> Function(bool enabled) onToggle;
  final Future<void> Function(TimeOfDay time) onTimeChanged;

  const _ReminderRow({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.config,
    required this.onToggle,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timeStr = _formatTime(config.time);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: config.enabled ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: config.enabled
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          // Selector de hora (solo visible si está activo)
          if (config.enabled)
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: () => _pickTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  timeStr,
                  style: AppTypography.labelMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            height: 38,
            child: Switch(
              value: config.enabled,
              onChanged: (value) {
                onToggle(value).catchError((error) {
                  if (context.mounted) {
                    AppSnackbar.showError(
                      context,
                      message: userErrorMessage(
                        error,
                        fallback:
                            'No se pudo actualizar el recordatorio. Intenta de nuevo.',
                      ),
                    );
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: config.time,
      helpText: 'Hora del recordatorio',
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
    );
    if (picked != null) {
      try {
        await onTimeChanged(picked);
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.showError(
            context,
            message: userErrorMessage(
              e,
              fallback: 'No se pudo actualizar la hora del recordatorio.',
            ),
          );
        }
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ============================================================================
// TIPS AND TRICKS SECTION - Ayuda para nuevos usuarios
// ============================================================================

class _TipsAndTricksSection extends StatelessWidget {
  const _TipsAndTricksSection();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                  child: Icon(Icons.tips_and_updates, color: AppColors.info),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consejos y Atajos',
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        'Saca el máximo provecho de la app',
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

            // Tips de búsqueda
            _TipItem(
              icon: Icons.search,
              title: 'Búsqueda inteligente',
              description:
                  'Escribe solo las primeras letras. La app busca por palabras clave y sinónimos.',
            ),
            _TipItem(
              icon: Icons.history,
              title: 'Alimentos frecuentes',
              description:
                  'Los chips de acceso rápido muestran lo que más usas. ¡Un tap para añadir!',
            ),
            _TipItem(
              icon: Icons.copy_all,
              title: 'Repetir ayer',
              description:
                  'Usa "Repetir ayer" para copiar todas las comidas del día anterior.',
            ),
            _TipItem(
              icon: Icons.bookmark,
              title: 'Plantillas de comida',
              description:
                  'Guarda comidas como plantillas desde el menú (⋮) de cada sección.',
            ),
            _TipItem(
              icon: Icons.qr_code_scanner,
              title: 'Escanear código de barras',
              description:
                  'Escanea productos para añadirlos automáticamente a tu diario.',
            ),
            _TipItem(
              icon: Icons.auto_graph,
              title: 'Coach adaptativo',
              description:
                  'El check-in semanal ajusta tus objetivos basándose en tu progreso real.',
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
                      'Los valores grises son sugerencias. Edítalos o acéptalos directamente.',
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

class _DebugSection extends StatelessWidget {
  const _DebugSection();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                  'Herramientas de Desarrollo',
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Solo visible en modo debug',
              style: AppTypography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              variant: AppButtonVariant.secondary,
              onPressed: () => context.pushTo(AppRouter.debugSearchBenchmark),
              icon: Icons.speed,
              label: 'Benchmark Búsqueda',
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
