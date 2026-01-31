import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/rutina.dart';
import '../providers/session_progress_provider.dart';
import '../providers/session_tolerance_provider.dart';
import '../providers/training_provider.dart';
import '../utils/design_system.dart';
import '../widgets/common/app_widgets.dart';
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
    final activeSessionAsync = ref.watch(activeSessionStreamProvider);
    final rutinasAsync = ref.watch(rutinasStreamProvider);
    final suggestionAsync = ref.watch(smartSuggestionProvider);

    return Scaffold(
      // 🎯 REDISEÑO: Fondo del sistema de diseño
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: activeSessionAsync.when(
          loading: () => const _LoadingState(),
          error: (err, stack) => ErrorStateWidget(message: err.toString()),
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
              loading: () => const _LoadingState(),
              error: (err, stack) => ErrorStateWidget(message: err.toString()),
              data: (rutinas) {
                // ═════════════════════════════════════════════════════════════
                // ESTADO 2: SIN RUTINAS - Guiar a crear
                // ═════════════════════════════════════════════════════════════
                if (rutinas.isEmpty) {
                  return const _EmptyState();
                }

                // ═════════════════════════════════════════════════════════════
                // ESTADO 3: NORMAL - Sugerencia prominente + alternativas
                // ═════════════════════════════════════════════════════════════
                return suggestionAsync.when(
                  loading: () => const _LoadingState(),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'TERMINAR SESION',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          'Se perdera el progreso actual.',
          style: GoogleFonts.montserrat(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.montserrat(color: Colors.grey[500]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(trainingSessionProvider.notifier).discardSession();
            },
            child: Text(
              'TERMINAR',
              style: GoogleFonts.montserrat(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
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
/// Diseño centrado con:
/// - Icono grande (reconocimiento visual instantáneo)
/// - Nombre del día (qué puede hacer)
/// - Contexto mínimo (validación rápida)
/// - CTA único gigante (cero decisiones)
/// - Escape claro (no está atrapado)
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

  // 🎯 HIGH-001: Color del icono basado en urgencia
  Color _getUrgencyIconColor() {
    switch (suggestion.urgency) {
      case WorkoutUrgency.rest:
        return AppColors.success; // Verde para descanso
      case WorkoutUrgency.ready:
        return AppColors.textSecondary;
      case WorkoutUrgency.shouldTrain:
        return AppColors.goldAccent; // Oro para "deberías"
      case WorkoutUrgency.urgent:
        return AppColors.bloodRed; // Rojo para urgente
      case WorkoutUrgency.fresh:
        return AppColors.actionPrimary;
    }
  }

  // 🎯 HIGH-001: Icono basado en estado
  IconData _getStateIcon() {
    if (suggestion.isRestDay) {
      return Icons.self_improvement_rounded; // Meditación/descanso
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
    final isRestDay = suggestion.isRestDay;

    return Column(
      children: [
        // ═══════════════════════════════════════════════════════════════════
        // ZONA PRINCIPAL: Centrada, respira, sin ruido
        // ═══════════════════════════════════════════════════════════════════
        Expanded(
          flex: showAlternatives ? 1 : 2,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🎯 HIGH-001: Icono dinámico según urgencia
                    Icon(
                      _getStateIcon(),
                      size: showAlternatives ? 48 : 72,
                      color: _getUrgencyIconColor(),
                    ),

                    SizedBox(height: showAlternatives ? 16 : 32),

                    // Nombre del día: QUÉ PUEDE HACER
                    Text(
                      suggestion.dayName.toUpperCase(),
                      // 🎯 REDISEÑO: Usar tipografía del sistema
                      style: showAlternatives
                          ? AppTypography.heroCompact
                          : AppTypography.hero,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Contexto mínimo: Validación rápida
                    Text(
                      suggestion.reason,
                      style: AppTypography.label,
                      textAlign: TextAlign.center,
                    ),

                    // 🎯 HIGH-001: Subtítulo contextual adicional
                    if (suggestion.contextualSubtitle != null && !showAlternatives) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          suggestion.contextualSubtitle!,
                          style: AppTypography.meta.copyWith(
                            color: isRestDay
                                ? AppColors.success.withValues(alpha: 0.8)
                                : AppColors.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    SizedBox(height: showAlternatives ? 24 : 48),

                    // ═══════════════════════════════════════════════════════
                    // CTA: Diferente para día de descanso vs entrenamiento
                    // ═══════════════════════════════════════════════════════
                    if (isRestDay) ...[
                      // 🎯 HIGH-001: UI de día de descanso
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                              style: AppTypography.button.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Duerme bien, hidrátate, come proteína',
                              style: AppTypography.meta.copyWith(
                                color: AppColors.success.withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Opción de entrenar de todas formas
                      GestureDetector(
                        onTap: onToggleAlternatives,
                        child: Text(
                          'Entrenar de todas formas',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ] else ...[
                      // CTA normal para días de entrenamiento
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: onStart,
                          style: ElevatedButton.styleFrom(
                            // 🎯 HIGH-001: Color basado en urgencia
                            backgroundColor: suggestion.urgency == WorkoutUrgency.urgent
                                ? AppColors.bloodRed
                                : AppColors.actionPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            suggestion.urgency == WorkoutUrgency.urgent
                                ? '¡A ENTRENAR!'
                                : 'ENTRENAR',
                            style: AppTypography.buttonPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Escape claro: No está atrapado
                      GestureDetector(
                        onTap: onToggleAlternatives,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                showAlternatives ? 'Ocultar opciones' : 'Cambiar',
                                style: AppTypography.label,
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                showAlternatives
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textTertiary,
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
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;
    final elapsedMinutes = startTime != null
        ? DateTime.now().difference(startTime!).inMinutes
        : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  child: const Icon(
                    Icons.recommend_rounded,
                    size: 72,
                    // 🎯 NEON IRON: Oro Venice para sesión activa
                    color: AppColors.goldAccent,
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Nombre de la sesión
            Text(
              rutina.nombre.toUpperCase(),
              style: AppTypography.heroCompact,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Progreso visual
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$completedSets',
                  style: AppTypography.dataLarge.copyWith(
                    // 🎯 NEON IRON: Oro Venice para contador de sesión activa
                    color: AppColors.goldAccent,
                  ),
                ),
                Text(' / $totalSets series', style: AppTypography.label),
              ],
            ),

            const SizedBox(height: 8),

            // Barra de progreso - 🎯 REDISEÑO: Verde para progreso
            Container(
              height: 6,
              width: 200,
              decoration: BoxDecoration(
                color: AppColors.bgInteractive,
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

            const SizedBox(height: 8),

            // Tiempo transcurrido
            Text('$elapsedMinutes min', style: AppTypography.meta),

            const SizedBox(height: 48),

            // CTA: CONTINUAR — Rojo Ferrari bold
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  // 🎯 AGGRESSIVE RED: Rojo Ferrari para acción principal
                  backgroundColor: AppColors.bloodRed,
                  foregroundColor: AppColors.textOnAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'CONTINUAR',
                  style: AppTypography.buttonPrimary.copyWith(
                    color: AppColors.textOnAccent,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Separador visual
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('o', style: AppTypography.meta),
                ),
                const Expanded(child: Divider(color: AppColors.divider)),
              ],
            ),

            const SizedBox(height: 16),

            // Opción de descartar — Rojo oscuro para urgencia
            TextButton(
              onPressed: onDiscard,
              child: Text(
                'TERMINAR SESION',
                style: AppTypography.button.copyWith(
                  color: AppColors.darkRed, // #8B0000 urgencia
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 32),
            Text(
              'CREA TU RUTINA',
              style: AppTypography.heroCompact,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Ve a la pestana Rutinas\npara empezar',
              style: AppTypography.label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// ESTADO: LOADING
/// ============================================================================

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              // 🎯 REDISEÑO: Verde para loading
              color: AppColors.success,
            ),
          ),
        ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        // 🎯 REDISEÑO: Fondo del sistema
        color: AppColors.bgElevated.withValues(alpha: 0.8),
        borderRadius: fullScreen
            ? null
            : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(24, fullScreen ? 48 : 20, 24, 12),
            child: Text(
              fullScreen ? 'ELIGE TU ENTRENO' : 'OTRAS OPCIONES',
              style: GoogleFonts.montserrat(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),

          // Lista de rutinas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre de la rutina
            Text(
              rutina.nombre.toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            // Chips de días
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rutina.dias.asMap().entries.map((entry) {
                return InkWell(
                  onTap: () {
                    try {
                      HapticFeedback.selectionClick();
                    } catch (_) {}
                    onDaySelected(entry.key);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgInteractive,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      entry.value.nombre.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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
