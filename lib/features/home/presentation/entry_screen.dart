import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/feedback/haptics.dart';
import 'package:juan_tracker/core/router/app_router.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/diet/models/models.dart';
import 'package:juan_tracker/diet/services/weight_input_validator.dart';
import 'package:juan_tracker/training/utils/design_system.dart' as training;
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
      extendBodyBehindAppBar: true,
      body: SafeArea(
        minimum: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 16,
        ),
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Header con saludo
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      _NutritionModeCard(
                        onTap: () => _navigateToNutrition(context),
                      ),
                      const SizedBox(height: 16),
                      _TrainingModeCard(
                        onTap: () => _navigateToTraining(context),
                      ),
                    ]),
                  ),
                ),

                // Indicador de racha
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const StreakCounter(),
                  ),
                ),

                // Spacer para que el contenido no quede detrás del bottom bar
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),

            // Accesos rápidos fijos en thumb zone
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withAlpha((0.1 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: const SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 12, 24, 12),
                    child: _QuickActionsRow(),
                  ),
                ),
              ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Text(
                      DateFormat('d MMM yyyy', 'es').format(selectedDate),
                    ),
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
                final validationError = WeightInputValidator.validate(
                  weightController.text,
                );
                if (validationError == null) {
                  Navigator.of(context).pop(true);
                } else {
                  AppSnackbar.showError(context, message: validationError);
                }
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final value = WeightInputValidator.parse(weightController.text);
      if (value != null) {
        final repo = ref.read(weighInRepositoryProvider);
        final id = 'wi_${DateTime.now().millisecondsSinceEpoch}';
        await repo.insert(
          WeighInModel(id: id, dateTime: selectedDate, weightKg: value),
        );
        if (context.mounted) {
          AppSnackbar.show(context, message: 'Peso registrado');
        }
      }
    }

    weightController.dispose();
  }

  void _showAddFoodDialog(BuildContext context, WidgetRef ref) {
    AppHaptics.buttonPressed();
    // Mostrar diálogo para elegir en qué comida añadir
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿En qué comida quieres añadir?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ...MealType.values.map(
                (meal) => ListTile(
                  leading: Icon(_getMealIcon(meal)),
                  title: Text(meal.displayName),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(selectedMealTypeProvider.notifier).meal = meal;
                    context.pushTo(AppRouter.nutritionFoodSearch);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMealIcon(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return Icons.free_breakfast;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
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

  const _Stat({required this.icon, required this.value, required this.label});
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
  final Widget? trailing; // 🎯 QW-05: Widget opcional (progress ring)

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.stats,
    required this.onTap,
    this.isDark = false,
    this.trailing,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                    // 🎯 QW-05: Mostrar progress ring o flecha
                    if (trailing != null)
                      trailing!
                    else
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white.withAlpha((0.7 * 255).round()),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
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
                                  color: Colors.white.withAlpha(
                                    (0.6 * 255).round(),
                                  ),
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
                  Icon(icon, color: colors.primary, size: 24),
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

/// Nutrition card that uses providers to show remaining kcal and protein
class _NutritionModeCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _NutritionModeCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(daySummaryProvider);

    final result = summaryAsync.when(
      data: (s) {
        final hasTargets = s.hasTargets;

        if (!hasTargets) {
          return (
            [
              _Stat(
                icon: Icons.local_fire_department,
                value: '${s.consumed.kcal}',
                label: 'kcal',
              ),
              _Stat(
                icon: Icons.fitness_center,
                value: '${s.consumed.protein.round()}g',
                label: 'proteína',
              ),
            ],
            'Seguimiento de nutrición',
            0.0,
          );
        }

        final remainingKcal = s.targets!.kcalTarget - s.consumed.kcal;
        final remainingProtein = s.targets!.proteinTarget != null
            ? (s.targets!.proteinTarget! - s.consumed.protein).round()
            : 0;

        final progress = s.progress.kcalPercent ?? 0;

        return (
          [
            _Stat(
              icon: Icons.local_fire_department,
              value: '$remainingKcal',
              label: 'kcal rest',
            ),
            _Stat(
              icon: Icons.fitness_center,
              value: '${remainingProtein}g',
              label: 'prot rest',
            ),
          ],
          '${s.consumed.kcal}/${s.targets!.kcalTarget} kcal consumidas',
          progress, // QW-05: Progress para ring
        );
      },
      loading: () => (
        [
          const _Stat(
            icon: Icons.local_fire_department,
            value: '--',
            label: 'kcal',
          ),
          const _Stat(
            icon: Icons.fitness_center,
            value: '--',
            label: 'proteína',
          ),
        ],
        'Cargando...',
        0.0,
      ),
      error: (err, stack) => (
        [
          const _Stat(icon: Icons.error, value: '--', label: 'error'),
          const _Stat(icon: Icons.error, value: '--', label: 'error'),
        ],
        'Error al cargar datos',
        0.0,
      ),
    );

    final stats = result.$1;
    final subtitle = result.$2;
    final progress = result.$3;

    return _ModeCard(
      title: 'Nutrición',
      subtitle: subtitle,
      icon: Icons.restaurant_rounded,
      gradientColors: [
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.primary.withAlpha((0.7 * 255).round()),
      ],
      stats: stats,
      onTap: onTap,
      // 🎯 QW-05: Progress ring mostrando % de calorías consumidas
      trailing: progress > 0
          ? _MiniProgressRing(
              progress: progress.clamp(0.0, 1.0),
              remaining: int.tryParse(stats[0].value) ?? 0,
            )
          : null,
    );
  }
}

/// Training card that uses smartSuggestionProvider to show what to train today
class _TrainingModeCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _TrainingModeCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(smartSuggestionProvider);

    return suggestionAsync.when(
      data: (suggestion) {
        if (suggestion == null) {
          // No hay rutinas configuradas
          return _ModeCard(
            title: 'Entrenamiento',
            subtitle: 'Configura tu primera rutina',
            icon: Icons.fitness_center_rounded,
            gradientColors: [
              training.AppColors.darkRed,
              training.AppColors.bloodRed,
            ],
            stats: const [
              _Stat(
                icon: Icons.fitness_center,
                value: '--',
                label: 'sin rutina',
              ),
              _Stat(icon: Icons.calendar_today, value: '--', label: 'hoy'),
            ],
            onTap: onTap,
            isDark: true,
          );
        }

        // Tenemos sugerencia - mostrar qué toca hoy
        final dayName = suggestion.dayName;
        // 🎯 QW-04: Usar formateo compacto para stat, contextual para subtítulo
        final timeSinceCompact = suggestion.timeSinceCompact;
        final timeSinceContextual = suggestion.timeSinceFormattedContextual;

        // Subtítulo dinámico basado en contexto con mensaje motivacional
        String subtitle;
        if (suggestion.isRestDay) {
          subtitle = suggestion.contextualSubtitle ?? suggestion.reason;
        } else if (suggestion.timeSinceLastSession == null) {
          subtitle = 'Primera vez: $dayName';
        } else {
          // QW-04: Subtítulo más rico con contexto temporal
          subtitle = suggestion.motivationalMessage;
        }

        return _ModeCard(
          title: suggestion.isRestDay ? 'Descanso' : 'Entrenamiento',
          subtitle: subtitle,
          icon: suggestion.isRestDay
              ? Icons.bedtime_rounded
              : Icons.fitness_center_rounded,
          gradientColors: suggestion.isRestDay
              ? [Colors.blueGrey, Colors.blueGrey.shade700]
              : [training.AppColors.darkRed, training.AppColors.bloodRed],
          stats: [
            // Stat 1: Qué toca hoy (lo más importante)
            _Stat(
              icon: suggestion.isRestDay ? Icons.bedtime : Icons.fitness_center,
              value: dayName.length > 8
                  ? '${dayName.substring(0, 8)}...'
                  : dayName,
              label: suggestion.isRestDay ? 'hoy' : 'toca',
            ),
            // Stat 2: Tiempo desde última sesión (formato compacto)
            _Stat(
              icon: Icons.history,
              value: timeSinceCompact,
              label: timeSinceContextual.contains('semana')
                  ? 'sin gym'
                  : 'última',
            ),
          ],
          onTap: onTap,
          isDark: true,
        );
      },
      loading: () => _ModeCard(
        title: 'Entrenamiento',
        subtitle: 'Cargando sugerencia...',
        icon: Icons.fitness_center_rounded,
        gradientColors: [
          training.AppColors.darkRed,
          training.AppColors.bloodRed,
        ],
        stats: const [
          _Stat(icon: Icons.fitness_center, value: '...', label: 'cargando'),
          _Stat(icon: Icons.history, value: '--', label: 'última'),
        ],
        onTap: onTap,
        isDark: true,
      ),
      error: (err, stack) => _ModeCard(
        title: 'Entrenamiento',
        subtitle: 'Error al cargar',
        icon: Icons.fitness_center_rounded,
        gradientColors: [
          training.AppColors.darkRed,
          training.AppColors.bloodRed,
        ],
        stats: const [
          _Stat(icon: Icons.error, value: '--', label: 'error'),
          _Stat(icon: Icons.history, value: '--', label: 'última'),
        ],
        onTap: onTap,
        isDark: true,
      ),
    );
  }
}

/// 🎯 QW-05: Mini progress ring para cards
class _MiniProgressRing extends StatelessWidget {
  final double progress;
  final int remaining;

  const _MiniProgressRing({required this.progress, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final isOverLimit = progress > 1.0;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 4,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withAlpha((0.2 * 255).round()),
            ),
          ),
          // Progress arc
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              isOverLimit ? Colors.red.shade300 : Colors.white,
            ),
          ),
          // Percentage text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
