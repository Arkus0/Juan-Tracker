import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/tdee_calculator.dart';
import '../../../core/widgets/home_button.dart';
import '../../../core/widgets/widgets.dart';

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

        // Sección Biblioteca
        _LibrarySection(),

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
                    Text(
                      'Tus Datos',
                      style: AppTypography.titleMedium,
                    ),
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
              value: profile?.age != null ? '${profile!.age} años' : 'No configurado',
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
            Text(
              'Biblioteca de Alimentos',
              style: AppTypography.titleMedium,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se eliminaron $removed duplicados')),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
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
