import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/widgets/widgets.dart';
import '../models/rutina.dart';
import '../providers/main_provider.dart';
import '../providers/session_progress_provider.dart';
import '../providers/session_tolerance_provider.dart';
import '../providers/training_provider.dart';
import '../widgets/routine_template_sheet.dart';
import 'training_session_screen.dart';

/// ============================================================================
/// PRINCIPIO DE LOS 3 SEGUNDOS
/// ============================================================================
/// En 3 segundos debe quedar claro:
/// 1. Qué puede hacer ahora
/// 2. Qué pasará si toca el botón principal
/// 3. Cómo deshacerlo/cambiarlo
/// ============================================================================

class TrainSelectionScreen extends ConsumerStatefulWidget {
  const TrainSelectionScreen({super.key});

  @override
  ConsumerState<TrainSelectionScreen> createState() =>
      _TrainSelectionScreenState();
}

class _TrainSelectionScreenState extends ConsumerState<TrainSelectionScreen> {
  bool _showAlternatives = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activeSessionAsync = ref.watch(activeSessionStreamProvider);
    final rutinasAsync = ref.watch(rutinasStreamProvider);
    final suggestionAsync = ref.watch(smartSuggestionProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: activeSessionAsync.when(
          loading: () => const AppLoading(),
          error: (err, stack) => AppError(
            message: 'Error al cargar sesión',
            details: err.toString(),
            onRetry: () => ref.invalidate(activeSessionStreamProvider),
          ),
          data: (activeSessionData) {
            // ═══════════════════════════════════════════════════════════════
            // ESTADO 1: SESIÓN ACTIVA - "CONTINUAR" es la acción obvia
            // ═══════════════════════════════════════════════════════════════
            if (activeSessionData != null &&
                activeSessionData.activeRutina != null) {
              return _ActiveSessionState(
                rutina: activeSessionData.activeRutina!,
                startTime: activeSessionData.startTime,
                completedSets: activeSessionData.completedSets,
                totalSets: activeSessionData.totalSets,
                onContinue: () => _continueSession(context, ref),
                onDiscard: () => _showDiscardDialog(context, ref),
              );
            }

            return rutinasAsync.when(
              loading: () => const AppLoading(),
              error: (err, stack) => AppError(
                message: 'Error al cargar rutinas',
                details: err.toString(),
                onRetry: () => ref.invalidate(rutinasStreamProvider),
              ),
              data: (rutinas) {
                // ═════════════════════════════════════════════════════════════
                // ESTADO 2: SIN RUTINAS - Guiar a crear
                // ═════════════════════════════════════════════════════════════
                if (rutinas.isEmpty) {
                  return _EmptyState(onCreate: () => _goToRoutines(context));
                }

                // ═════════════════════════════════════════════════════════════
                // ESTADO 3: NORMAL - Sugerencia prominente + alternativas
                // ═════════════════════════════════════════════════════════════
                return suggestionAsync.when(
                  loading: () => const AppLoading(),
                  error: (_, _) => _FallbackState(
                    rutinas: rutinas,
                    onDaySelected: (rutina, dayIndex) =>
                        _startSession(context, ref, rutina, dayIndex),
                  ),
                  data: (suggestion) {
                    if (suggestion == null) {
                      return _FallbackState(
                        rutinas: rutinas,
                        onDaySelected: (rutina, dayIndex) =>
                            _startSession(context, ref, rutina, dayIndex),
                      );
                    }

                    return _ZeroThoughtHome(
                      suggestion: suggestion,
                      rutinas: rutinas,
                      showAlternatives: _showAlternatives,
                      onStart: () => _startSession(
                        context,
                        ref,
                        suggestion.rutina,
                        suggestion.dayIndex,
                      ),
                      onToggleAlternatives: () => setState(
                        () => _showAlternatives = !_showAlternatives,
                      ),
                      onAlternativeSelected: (rutina, dayIndex) {
                        setState(() => _showAlternatives = false);
                        _startSession(context, ref, rutina, dayIndex);
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _goToRoutines(BuildContext context) {
    // Navigate to routines tab
    final mainProvider = ref.read(bottomNavIndexProvider.notifier);
    mainProvider.setIndex(0);
  }

  void _continueSession(BuildContext context, WidgetRef ref) {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    final theme = Theme.of(context);
    ref.read(trainingSessionProvider.notifier).restoreFromStorage();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Theme(
          data: theme,
          child: const TrainingSessionScreen(),
        ),
      ),
    );
  }

  void _startSession(
    BuildContext context,
    WidgetRef ref,
    Rutina rutina,
    int dayIndex,
  ) {
    if (rutina.dias.isEmpty || dayIndex >= rutina.dias.length) return;

    final day = rutina.dias[dayIndex];
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    // Reset state providers antes de iniciar nueva sesión
    // para evitar que el estado de sesiones anteriores afecte la nueva
    ref.read(sessionProgressProvider.notifier).reset();
    ref.read(exerciseCompletionProvider.notifier).reset();
    ref.read(sessionToleranceProvider.notifier).reset();

    ref
        .read(trainingSessionProvider.notifier)
        .startSession(
          rutina,
          day.ejercicios,
          dayName: day.nombre,
          dayIndex: dayIndex,
        );

    final theme = Theme.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Theme(
          data: theme,
          child: const TrainingSessionScreen(),
        ),
      ),
    );
  }

  void _showDiscardDialog(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          '¿Terminar sesión?',
          style: AppTypography.headlineSmall.copyWith(
            color: colors.onSurface,
          ),
        ),
        content: Text(
          'Se perderá el progreso actual.',
          style: AppTypography.bodyMedium.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: AppTypography.labelLarge.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(trainingSessionProvider.notifier).discardSession();
            },
            child: Text(
              'Terminar',
              style: AppTypography.labelLarge.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// ESTADO PRINCIPAL: ZERO-THOUGHT HOME
/// ============================================================================

class _ZeroThoughtHome extends StatelessWidget {
  final SmartWorkoutSuggestion suggestion;
  final List<Rutina> rutinas;
  final bool showAlternatives;
  final VoidCallback onStart;
  final VoidCallback onToggleAlternatives;
  final void Function(Rutina, int) onAlternativeSelected;

  const _ZeroThoughtHome({
    required this.suggestion,
    required this.rutinas,
    required this.showAlternatives,
    required this.onStart,
    required this.onToggleAlternatives,
    required this.onAlternativeSelected,
  });

  Color _getUrgencyIconColor(ColorScheme colors) {
    switch (suggestion.urgency) {
      case WorkoutUrgency.rest:
        return AppColors.success;
      case WorkoutUrgency.ready:
        return colors.onSurfaceVariant;
      case WorkoutUrgency.shouldTrain:
        return AppColors.warning;
      case WorkoutUrgency.urgent:
        return colors.error;
      case WorkoutUrgency.fresh:
        return colors.primary;
    }
  }

  IconData _getStateIcon() {
    if (suggestion.isRestDay) {
      return Icons.self_improvement_rounded;
    }
    switch (suggestion.urgency) {
      case WorkoutUrgency.urgent:
        return Icons.priority_high_rounded;
      case WorkoutUrgency.fresh:
        return Icons.rocket_launch_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRestDay = suggestion.isRestDay;

    return Column(
      children: [
        // ═══════════════════════════════════════════════════════════════════
        // ZONA PRINCIPAL: Centrada, respira, sin ruido
        // ═══════════════════════════════════════════════════════════════════
        Expanded(
          flex: showAlternatives ? 1 : 2,
          child: AnimatedContainer(
            duration: AppDurations.normal,
            curve: Curves.easeOutCubic,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono dinámico según urgencia
                    Icon(
                      _getStateIcon(),
                      size: showAlternatives ? 48 : 72,
                      color: _getUrgencyIconColor(colors),
                    ),

                    SizedBox(height: showAlternatives ? AppSpacing.lg : AppSpacing.xxl),

                    // Nombre del día: QUÉ PUEDE HACER
                    Text(
                      suggestion.dayName.toUpperCase(),
                      style: showAlternatives
                          ? AppTypography.headlineMedium
                          : AppTypography.headlineLarge,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Contexto mínimo: Validación rápida
                    Text(
                      suggestion.reason,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Subtítulo contextual adicional
                    if (suggestion.contextualSubtitle != null && !showAlternatives) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text(
                          suggestion.contextualSubtitle!,
                          style: AppTypography.bodySmall.copyWith(
                            color: isRestDay
                                ? AppColors.success.withValues(alpha: 0.8)
                                : colors.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    SizedBox(height: showAlternatives ? AppSpacing.md : AppSpacing.xl),

                    // ═══════════════════════════════════════════════════════
                    // CTA: Diferente para día de descanso vs entrenamiento
                    // ═══════════════════════════════════════════════════════
                    if (isRestDay) ...[
                      // UI de día de descanso
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'RECUPERACIÓN ACTIVA',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Duerme bien, hidrátate, come proteína',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.success.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Opción de entrenar de todas formas
                      GestureDetector(
                        onTap: onToggleAlternatives,
                        child: Text(
                          'Entrenar de todas formas',
                          style: AppTypography.labelMedium.copyWith(
                            color: colors.onSurfaceVariant,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ] else ...[
                      // CTA normal para días de entrenamiento
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: onStart,
                          style: FilledButton.styleFrom(
                            backgroundColor: suggestion.urgency == WorkoutUrgency.urgent
                                ? colors.error
                                : colors.primary,
                            foregroundColor: colors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: Text(
                            suggestion.urgency == WorkoutUrgency.urgent
                                ? '¡A ENTRENAR!'
                                : 'ENTRENAR',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Escape claro: No está atrapado
                      GestureDetector(
                        onTap: onToggleAlternatives,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                showAlternatives ? 'Ocultar opciones' : 'Cambiar',
                                style: AppTypography.labelMedium.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Icon(
                                showAlternatives
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: colors.onSurfaceVariant,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // ═══════════════════════════════════════════════════════════════════
        // ZONA ALTERNATIVAS: Solo visible si el usuario lo pide
        // ═══════════════════════════════════════════════════════════════════
        if (showAlternatives)
          Expanded(
            flex: 2,
            child: _AlternativesPanel(
              rutinas: rutinas,
              currentSuggestion: suggestion,
              onDaySelected: onAlternativeSelected,
            ),
          ),
      ],
    );
  }
}

/// ============================================================================
/// ESTADO: SESIÓN ACTIVA
/// ============================================================================

class _ActiveSessionState extends StatelessWidget {
  final Rutina rutina;
  final DateTime? startTime;
  final int completedSets;
  final int totalSets;
  final VoidCallback onContinue;
  final VoidCallback onDiscard;

  const _ActiveSessionState({
    required this.rutina,
    required this.startTime,
    required this.completedSets,
    required this.totalSets,
    required this.onContinue,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;
    final elapsedMinutes = startTime != null
        ? DateTime.now().difference(startTime!).inMinutes
        : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de sesión activa (pulso visual)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.recommend_rounded,
                    size: 72,
                    color: colors.primary,
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Nombre de la sesión
            Text(
              rutina.nombre.toUpperCase(),
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Progreso visual
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$completedSets',
                  style: AppTypography.dataMedium.copyWith(
                    color: colors.primary,
                  ),
                ),
                Text(
                  ' / $totalSets series',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Barra de progreso
            Container(
              height: 6,
              width: 200,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Tiempo transcurrido
            Text(
              '$elapsedMinutes min',
              style: AppTypography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // CTA: CONTINUAR
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(
                  'CONTINUAR',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Separador visual
            Row(
              children: [
                Expanded(
                  child: Divider(color: colors.outline.withValues(alpha: 0.5)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'o',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: colors.outline.withValues(alpha: 0.5)),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Opción de descartar
            TextButton(
              onPressed: onDiscard,
              child: Text(
                'Terminar sesión',
                style: AppTypography.labelLarge.copyWith(
                  color: colors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// ESTADO: SIN RUTINAS
/// ============================================================================

class _EmptyState extends ConsumerWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sin rutinas',
              style: AppTypography.headlineSmall.copyWith(
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Crea una rutina estructurada o entrena libremente',
              style: AppTypography.bodyMedium.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            // CTA Principal: Entrenar Libre (reduce TTV de 14 clics a 2)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startFreeWorkout(context, ref),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('ENTRENAR LIBRE'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // CTA Secundario: Usar plantilla
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => _showTemplates(context, ref),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.library_books_outlined),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('USAR PLANTILLA'),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        '+68',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // CTA Terciario: Crear rutina personalizada
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('CREAR RUTINA'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showTemplates(BuildContext context, WidgetRef ref) async {
    final rutina = await RoutineTemplateSheet.show(context);
    if (rutina != null && context.mounted) {
      // Guardar la rutina convertida
      await ref.read(trainingRepositoryProvider).saveRutina(rutina);
      // Invalidar para refrescar lista
      ref.invalidate(rutinasStreamProvider);
      // Feedback
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: '✓ Rutina "${rutina.nombre}" añadida',
        );
      }
    }
  }
  
  void _startFreeWorkout(BuildContext context, WidgetRef ref) {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    
    // Iniciar sesión libre sin rutina
    ref.read(trainingSessionProvider.notifier).startFreeSession();
    
    final theme = Theme.of(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Theme(
          data: theme,
          child: const TrainingSessionScreen(),
        ),
      ),
    );
  }
}

/// ============================================================================
/// ESTADO: FALLBACK (sin sugerencia)
/// ============================================================================

class _FallbackState extends StatelessWidget {
  final List<Rutina> rutinas;
  final void Function(Rutina, int) onDaySelected;

  const _FallbackState({required this.rutinas, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return _AlternativesPanel(
      rutinas: rutinas,
      currentSuggestion: null,
      onDaySelected: onDaySelected,
      fullScreen: true,
    );
  }
}

/// ============================================================================
/// PANEL DE ALTERNATIVAS
/// ============================================================================

class _AlternativesPanel extends StatelessWidget {
  final List<Rutina> rutinas;
  final SmartWorkoutSuggestion? currentSuggestion;
  final void Function(Rutina, int) onDaySelected;
  final bool fullScreen;

  const _AlternativesPanel({
    required this.rutinas,
    required this.currentSuggestion,
    required this.onDaySelected,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: fullScreen
            ? null
            : const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              fullScreen ? AppSpacing.xxxl : AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Text(
              fullScreen ? 'ELIGE TU ENTRENO' : 'OTRAS OPCIONES',
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
          ),

          // Lista de rutinas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: rutinas.length,
              itemBuilder: (context, index) {
                final rutina = rutinas[index];
                return _CompactRutinaCard(
                  rutina: rutina,
                  onDaySelected: (dayIndex) => onDaySelected(rutina, dayIndex),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// CARD DE RUTINA COMPACTA
/// ============================================================================

class _CompactRutinaCard extends StatelessWidget {
  final Rutina rutina;
  final void Function(int) onDaySelected;

  const _CompactRutinaCard({required this.rutina, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre de la rutina
            Text(
              rutina.nombre.toUpperCase(),
              style: AppTypography.titleLarge,
            ),

            const SizedBox(height: AppSpacing.md),

            // Chips de días
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: rutina.dias.asMap().entries.map((entry) {
                return InkWell(
                  onTap: () {
                    try {
                      HapticFeedback.selectionClick();
                    } catch (_) {}
                    onDaySelected(entry.key);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.outline.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      entry.value.nombre.toUpperCase(),
                      style: AppTypography.labelMedium,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
