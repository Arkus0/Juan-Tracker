import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/feedback/haptics.dart';
import 'package:juan_tracker/core/providers/today_providers.dart';
import 'package:juan_tracker/core/router/app_router.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';

/// 🎯 FASE 6: Pantalla "HOY" unificada
/// 
/// Muestra en una sola vista:
/// - Estado de entrenamiento (qué toca hoy)
/// - Macros restantes
/// - Accesos rápidos contextuales
/// - Sesión en progreso (si aplica)
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 10) return '¡Buenos días!';
    if (hour < 14) return '¡Buenas tardes!';
    return '¡Buenas noches!';
  }

  String get _currentDate {
    return DateFormat('EEEE, d MMMM', 'es').format(DateTime.now());
  }

  /// Obtiene mensaje contextual según hora del día
  String _getContextualMessage(TodaySummary summary, int hour) {
    if (summary.isLoading) return 'Cargando tu día...';
    
    if (hour < 10) {
      // Mañana
      if (!summary.hasTrainingData) {
        return 'Configura tu rutina para empezar';
      }
      if (summary.isRestDaySuggested) {
        return 'Día de descanso. ¡A recuperar!';
      }
      return 'Hoy toca ${summary.suggestedWorkout}';
    } else if (hour < 14) {
      // Mediodía
      if (summary.hasNutritionData) {
        return 'Te quedan ${summary.kcalRemaining} kcal para hoy';
      }
      return '¿Ya registraste tu almuerzo?';
    } else if (hour < 18) {
      // Tarde
      if (summary.hasTrainingData && !summary.isRestDaySuggested) {
        return '¿Listo para ${summary.suggestedWorkout}?';
      }
      return '¿Qué tal va tu día?';
    } else {
      // Noche
      if (summary.hasNutritionData) {
        return '¿Qué cenar con ${summary.kcalRemaining} kcal?';
      }
      return 'Revisa tu progreso de hoy';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todaySummaryProvider);
    final hour = DateTime.now().hour;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: todayAsync.when(
          data: (summary) => CustomScrollView(
            slivers: [
              // Header con saludo y fecha
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 8),
                      Text(
                        _getContextualMessage(summary, hour),
                        style: AppTypography.bodyLarge.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Card de Entrenamiento (siempre visible)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _TrainingTodayCard(
                    summary: summary,
                    onTap: () => _navigateToTraining(context),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Card de Nutrición
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _NutritionTodayCard(
                    summary: summary,
                    onTap: () => _navigateToNutrition(context),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Accesos rápidos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _QuickActionsSection(
                    summary: summary,
                  ),
                ),
              ),

              // Espacio al final
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Center(
            child: AppError(
              message: 'Error al cargar tu día',
              details: e.toString(),
              onRetry: () => ref.invalidate(todaySummaryProvider),
            ),
          ),
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

/// Card de entrenamiento para Today Screen
class _TrainingTodayCard extends StatelessWidget {
  final TodaySummary summary;
  final VoidCallback onTap;

  const _TrainingTodayCard({
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    // Determinar estado visual
    final bool isRestDay = summary.isRestDaySuggested;
    final bool hasWorkout = summary.hasTrainingData;
    
    final gradientColors = isRestDay
        ? [Colors.blueGrey, Colors.blueGrey.shade700]
        : hasWorkout
            ? [Colors.red.shade800, Colors.red.shade600]
            : [Colors.grey.shade700, Colors.grey.shade600];

    final icon = isRestDay
        ? Icons.bedtime_rounded
        : Icons.fitness_center_rounded;

    final title = isRestDay
        ? 'Día de Descanso'
        : hasWorkout
            ? summary.suggestedWorkout ?? 'Entrenamiento'
            : 'Sin Rutina';

    final subtitle = summary.workoutMotivationalMessage ?? 
        (hasWorkout 
            ? summary.daysSinceLastSession != null
                ? 'Última: hace ${summary.daysSinceLastSession} días'
                : 'Configura tu primera rutina'
            : 'Crea tu rutina para empezar');

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
                  if (hasWorkout && !isRestDay)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        'HOY',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de nutrición para Today Screen
class _NutritionTodayCard extends StatelessWidget {
  final TodaySummary summary;
  final VoidCallback onTap;

  const _NutritionTodayCard({
    required this.summary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!summary.hasNutritionTargets) {
      // Estado sin objetivos configurados
      return AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                Icons.restaurant_rounded,
                color: colors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrición',
                    style: AppTypography.headlineSmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    'Configura tus objetivos',
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      );
    }

    // Con objetivos configurados - mostrar progreso
    final progress = summary.kcalProgress.clamp(0.0, 1.0);
    final isOverLimit = summary.kcalProgress > 1.0;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
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
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  // Mini progress ring
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 4,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withAlpha((0.2 * 255).round()),
                          ),
                        ),
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOverLimit ? Colors.red.shade300 : Colors.white,
                          ),
                        ),
                        Text(
                          summary.kcalProgressText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Te quedan ${summary.kcalRemaining} kcal',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.kcalConsumed}/${summary.kcalTarget} consumidas',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withAlpha((0.8 * 255).round()),
                ),
              ),
              const SizedBox(height: 12),
              // Macros restantes
              Row(
                children: [
                  _MacroChip(
                    label: 'Proteína',
                    value: '${summary.proteinRemaining.toInt()}g',
                  ),
                  const SizedBox(width: 8),
                  _MacroChip(
                    label: 'Carbs',
                    value: '${summary.carbsRemaining.toInt()}g',
                  ),
                  const SizedBox(width: 8),
                  _MacroChip(
                    label: 'Grasa',
                    value: '${summary.fatRemaining.toInt()}g',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip pequeño para macro
class _MacroChip extends StatelessWidget {
  final String label;
  final String value;

  const _MacroChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha((0.7 * 255).round()),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de accesos rápidos contextuales
class _QuickActionsSection extends StatelessWidget {
  final TodaySummary summary;

  const _QuickActionsSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;

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
            // Acción principal según hora
            if (hour < 11) ...[
              _QuickActionButton(
                icon: Icons.add_rounded,
                label: 'Desayuno',
                onTap: () {
                  // Navegar a diario con desayuno seleccionado
                  context.goToDiary();
                },
              ),
            ] else if (hour < 15) ...[
              _QuickActionButton(
                icon: Icons.add_rounded,
                label: 'Almuerzo',
                onTap: () {
                  context.goToDiary();
                },
              ),
            ] else if (hour < 19) ...[
              _QuickActionButton(
                icon: Icons.add_rounded,
                label: 'Merienda',
                onTap: () {
                  context.goToDiary();
                },
              ),
            ] else ...[
              _QuickActionButton(
                icon: Icons.add_rounded,
                label: 'Cena',
                onTap: () {
                  context.goToDiary();
                },
              ),
            ],
            const SizedBox(width: 12),
            // Acción secundaria: Entrenar si toca
            if (summary.hasTrainingData && !summary.isRestDaySuggested)
              _QuickActionButton(
                icon: Icons.fitness_center_rounded,
                label: 'Entrenar',
                isPrimary: true,
                onTap: () {
                  context.goToTraining();
                },
              )
            else
              _QuickActionButton(
                icon: Icons.add_chart_rounded,
                label: 'Peso',
                onTap: () {
                  context.goToWeight();
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Botón de acción rápida
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Material(
        color: isPrimary ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isPrimary ? colors.onPrimary : colors.onSurface,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isPrimary ? colors.onPrimary : colors.onSurface,
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
