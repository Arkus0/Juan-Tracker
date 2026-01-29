import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/feedback/haptics.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/training/training_shell.dart';
import 'home_screen.dart';

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
      body: SafeArea(
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
                  _ModeCard(
                    title: 'Nutrición',
                    subtitle: 'Diario, alimentos, peso y resumen',
                    icon: Icons.restaurant_menu_rounded,
                    gradientColors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                    stats: const [
                      _Stat(icon: Icons.local_fire_department, value: '1,850', label: 'kcal'),
                      _Stat(icon: Icons.scale, value: '78.5', label: 'kg'),
                    ],
                    onTap: () => _navigateToNutrition(context),
                  ),
                  const SizedBox(height: 16),
                  _ModeCard(
                    title: 'Entrenamiento',
                    subtitle: 'Sesiones, rutinas, análisis y progreso',
                    icon: Icons.fitness_center_rounded,
                    gradientColors: [
                      AppColors.ironRed,
                      AppColors.ironRedLight,
                    ],
                    isDark: true,
                    stats: const [
                      _Stat(icon: Icons.calendar_today, value: 'Push', label: 'Hoy'),
                      _Stat(icon: Icons.timer, value: '45', label: 'min'),
                    ],
                    onTap: () => _navigateToTraining(context),
                  ),
                ]),
              ),
            ),

            // Accesos rápidos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
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
                          onTap: () {},
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
                          onTap: () => _navigateToNutrition(context),
                        ),
                      ],
                    ),
                  ],
                ),
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
                child: _StreakIndicator(days: 12),
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
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToTraining(BuildContext context) {
    AppHaptics.buttonPressed();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const TrainingShell(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
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
    return AppCard(
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
    );
  }
}

/// Indicador de racha
class _StreakIndicator extends StatelessWidget {
  final int days;

  const _StreakIndicator({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.warning.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Racha de $days días! 🔥',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  'Sigues tu plan de nutrición y entrenamiento',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warning.withAlpha((0.8 * 255).round()),
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
