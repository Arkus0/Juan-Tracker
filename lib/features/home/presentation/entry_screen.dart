import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/feedback/haptics.dart';
import 'package:juan_tracker/core/router/app_router.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/diet/models/weighin_model.dart';
import 'package:juan_tracker/training/widgets/analysis/streak_counter.dart';
import 'package:juan_tracker/training/providers/training_provider.dart';

/// Pantalla de entrada principal con selección de modo
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return '¡Buenos días!';
    if (hour < 18) return '¡Buenas tardes!';
    return '¡Buenas noches!';
  }

  String get _currentDate {
    return DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      // UX-005: Edge-to-edge support
      extendBodyBehindAppBar: true,
      body: SafeArea(
        // UX-005: Mantener padding bottom para navegación
        minimum: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 16,
        ),
        child: CustomScrollView(
          slivers: [
            // Header con saludo
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo/Icono animado
                    _AnimatedLogo(),
                    const SizedBox(height: 24),
                    Text(
                      _greeting,
                      style: AppTypography.displaySmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentDate.toUpperCase(),
                      style: AppTypography.labelLarge.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Selector de modo
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _NutritionModeCard(onTap: () => _navigateToNutrition(context)),
                  const SizedBox(height: 16),
                  _TrainingModeCard(onTap: () => _navigateToTraining(context)),
                ]),
              ),
            ),

            // Accesos rápidos
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _QuickActionsRow(),
              ),
            ),

            // Spacer
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),

            // Indicador de racha
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const StreakCounter(),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNutrition(BuildContext context) {
    AppHaptics.buttonPressed();
    context.goToNutrition();
  }

  void _navigateToTraining(BuildContext context) {
    AppHaptics.buttonPressed();
    context.goToTraining();
  }
}

/// Fila de acciones rápidas
class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCESOS RÁPIDOS',
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickActionButton(
              icon: Icons.add_rounded,
              label: 'Peso',
              onTap: () => _showAddWeightDialog(context, ref),
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Entrenar',
              onTap: () => _navigateToTraining(context),
            ),
            const SizedBox(width: 12),
            _QuickActionButton(
              icon: Icons.restaurant_rounded,
              label: 'Comida',
              onTap: () => _showAddFoodDialog(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToTraining(BuildContext context) {
    AppHaptics.buttonPressed();
    context.goToTraining();
  }

  Future<void> _showAddWeightDialog(BuildContext context, WidgetRef ref) async {
    AppHaptics.buttonPressed();
    final weightController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Registrar peso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  hintText: 'Ej: 75.5',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Fecha: '),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Text(DateFormat('d MMM yyyy', 'es').format(selectedDate)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () {
                final text = weightController.text.trim();
                final value = double.tryParse(text.replaceAll(',', '.'));
                if (value != null && value > 0 && value < 500) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final text = weightController.text.trim();
      final value = double.tryParse(text.replaceAll(',', '.'));
      if (value != null) {
        final repo = ref.read(weighInRepositoryProvider);
        final id = 'wi_${DateTime.now().millisecondsSinceEpoch}';
        await repo.insert(WeighInModel(
          id: id, 
          dateTime: selectedDate, 
          weightKg: value,
        ));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Peso registrado')),
          );
        }
      }
    }
    
    weightController.dispose();
  }

  void _showAddFoodDialog(BuildContext context, WidgetRef ref) {
    AppHaptics.buttonPressed();
    context.pushTo(AppRouter.nutritionFoods);
  }
}

/// Logo animado
class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary,
              colors.primary.withAlpha((0.7 * 255).round()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withAlpha((0.3 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.track_changes_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

/// Modelo de estadística
class _Stat {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
  });
}

/// Card de modo (Nutrición o Entrenamiento)
class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final List<_Stat> stats;
  final VoidCallback onTap;
  final bool isDark;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.stats,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title: $subtitle',
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withAlpha((0.7 * 255).round()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Título
              Text(
                title,
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withAlpha((0.8 * 255).round()),
                ),
              ),
              const SizedBox(height: 16),
              // Stats
              Row(
                children: stats.map((stat) {
                  return Expanded(
                    child: Row(
                      children: [
                        Icon(
                          stat.icon,
                          color: Colors.white.withAlpha((0.6 * 255).round()),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.value,
                              style: AppTypography.dataSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              stat.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withAlpha((0.6 * 255).round()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Botón de acción rápida
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: colors.surfaceContainerHighest,
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
                    color: colors.primary,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: colors.onSurface,
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

/// Nutrition card that uses providers to show today's kcal and latest weight
class _NutritionModeCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _NutritionModeCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(daySummaryProvider);
    final latestAsync = ref.watch(latestWeighInProvider);

    final kcalText = summaryAsync.when(
      data: (s) => s.consumed.kcal.toString(),
      loading: () => '--',
      error: (e, _) => '--',
    );

    final weightText = latestAsync.when(
      data: (w) => w == null ? '--' : w.weightKg.toStringAsFixed(1),
      loading: () => '--',
      error: (e, _) => '--',
    );

    return _ModeCard(
      title: 'Nutrición',
      subtitle: 'Diario, alimentos, peso y resumen',
      icon: Icons.restaurant_menu_rounded,
      gradientColors: [AppColors.primary, AppColors.primaryLight],
      stats: [
        _Stat(icon: Icons.local_fire_department, value: kcalText, label: 'kcal'),
        _Stat(icon: Icons.scale, value: weightText, label: 'kg'),
      ],
      onTap: onTap,
    );
  }
}

class _TrainingModeCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _TrainingModeCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinasAsync = ref.watch(rutinasStreamProvider);

    final stats = rutinasAsync.when(
      data: (rutinas) {
        if (rutinas.isEmpty) {
          return [
            const _Stat(icon: Icons.calendar_today, value: '—', label: 'Hoy'),
            const _Stat(icon: Icons.timer, value: '--', label: 'min'),
          ];
        }
        return [
          const _Stat(icon: Icons.calendar_today, value: '—', label: 'Hoy'),
          const _Stat(icon: Icons.timer, value: '--', label: 'min'),
        ];
      },
      loading: () => [
        const _Stat(icon: Icons.calendar_today, value: '—', label: 'Hoy'),
        const _Stat(icon: Icons.timer, value: '--', label: 'min'),
      ],
      error: (e, _) => [
        const _Stat(icon: Icons.calendar_today, value: '—', label: 'Hoy'),
        const _Stat(icon: Icons.timer, value: '--', label: 'min'),
      ],
    );

    return _ModeCard(
      title: 'Entrenamiento',
      subtitle: 'Sesiones, rutinas, análisis y progreso',
      icon: Icons.fitness_center_rounded,
      gradientColors: [AppColors.ironRed, AppColors.ironRedLight],
      isDark: true,
      stats: stats,
      onTap: onTap,
    );
  }
}
