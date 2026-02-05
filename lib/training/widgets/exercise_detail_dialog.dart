import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/design_system.dart';
import '../models/analysis_models.dart';
import '../models/library_exercise.dart';
import '../models/serie_log.dart';
import '../models/sesion.dart';
import '../providers/exercise_history_provider.dart';
import '../services/one_rm_calculator.dart';

/// Dialog que muestra los detalles completos de un ejercicio.
/// 
/// Incluye:
/// - Imagen y nombre del ejercicio
/// - Grupo muscular y equipamiento
/// - Descripción (si existe)
/// - Historial de las últimas sesiones (con fechas y series)
/// - 1RM estimado
/// - Botón para añadir a la rutina
class ExerciseDetailDialog extends ConsumerWidget {
  final LibraryExercise exercise;
  final PersonalRecord? personalRecord;
  final VoidCallback? onAdd;
  final VoidCallback? onFavoriteToggle;

  const ExerciseDetailDialog({
    super.key,
    required this.exercise,
    this.personalRecord,
    this.onAdd,
    this.onFavoriteToggle,
  });

  /// Muestra el dialog y devuelve true si se añadió el ejercicio
  static Future<bool?> show(
    BuildContext context, {
    required LibraryExercise exercise,
    PersonalRecord? personalRecord,
    VoidCallback? onAdd,
    VoidCallback? onFavoriteToggle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ExerciseDetailDialog(
        exercise: exercise,
        personalRecord: personalRecord,
        onAdd: onAdd,
        onFavoriteToggle: onFavoriteToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(exerciseHistoryProvider(exercise.name));

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 650),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen + Badge
            _buildHeader(context, scheme),

            // Contenido scrolleable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      exercise.name.toUpperCase(),
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // PR Badge
                    if (personalRecord != null) _buildPRBadge(scheme),

                    // Tags (músculo + equipo)
                    _buildTags(scheme),
                    const SizedBox(height: 16),

                    // Descripción
                    if (exercise.description?.isNotEmpty ?? false) ...[
                      Text(
                        'Descripción',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Historial de sesiones
                    _buildHistorySection(context, scheme, historyAsync),
                  ],
                ),
              ),
            ),

            // Botones de acción
            _buildActionButtons(context, scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: exercise.imageUrls.isNotEmpty
                ? Image.network(
                    exercise.imageUrls.first,
                    fit: BoxFit.cover,
                    cacheWidth: 380,
                    errorBuilder: (_, _, _) => _buildPlaceholder(scheme),
                  )
                : _buildPlaceholder(scheme),
          ),
        ),
        // Gradient overlay para legibilidad
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  scheme.surface.withAlpha(200),
                ],
              ),
            ),
          ),
        ),
        // Botón cerrar
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surface.withAlpha(200),
            ),
            icon: Icon(Icons.close, color: scheme.onSurface),
          ),
        ),
        // Badge custom si aplica
        if (!exercise.isCurated)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.tertiary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'PERSONALIZADO',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onTertiary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: 64,
          color: scheme.onSurfaceVariant.withAlpha(60),
        ),
      ),
    );
  }

  Widget _buildPRBadge(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'RÉCORD: ${personalRecord!.maxWeight.toStringAsFixed(1)}kg × ${personalRecord!.repsAtMax}',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTags(ColorScheme scheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Grupo muscular principal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            exercise.muscleGroup.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ),
        // Equipamiento
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                exercise.equipment,
                style: AppTypography.labelSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Músculos secundarios
        ...exercise.muscles.take(3).map((m) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            m,
            style: AppTypography.labelSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    ColorScheme scheme,
    AsyncValue<List<Sesion>> historyAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Tu historial',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        historyAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No se pudo cargar el historial',
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          data: (sessions) {
            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.outlineVariant.withAlpha(100),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, 
                      size: 32, 
                      color: scheme.primary.withAlpha(150),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¡Aún no has hecho este ejercicio!\nAñádelo para empezar a registrar tu progreso.',
                        style: AppTypography.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: sessions.take(5).map((session) {
                return _buildSessionCard(context, scheme, session);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    ColorScheme scheme,
    Sesion session,
  ) {
    // Encontrar el ejercicio específico en la sesión
    final ejercicio = session.ejerciciosCompletados.firstWhere(
      (e) => e.nombre.toLowerCase() == exercise.name.toLowerCase(),
      orElse: () => session.ejerciciosCompletados.first,
    );

    // Calcular 1RM estimado del mejor set
    double? estimated1RM;
    SerieLog? bestSet;
    for (final serie in ejercicio.logs) {
      if (serie.peso > 0 && serie.reps > 0 && serie.completed) {
        final rm = OneRMCalculator.calculate(
          weight: serie.peso,
          reps: serie.reps,
        );
        if (estimated1RM == null || rm > estimated1RM) {
          estimated1RM = rm;
          bestSet = serie;
        }
      }
    }

    final dateFormat = DateFormat('d MMM', 'es');
    final timeAgo = _formatTimeAgo(session.fecha);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fecha y tiempo relativo
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(session.fecha),
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($timeAgo)',
                style: AppTypography.labelSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // 1RM estimado
              if (estimated1RM != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '1RM: ${estimated1RM.toStringAsFixed(0)}kg',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Series realizadas
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: ejercicio.logs.where((s) => s.completed).map((serie) {
              final isBest = serie == bestSet;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBest 
                      ? AppColors.success.withAlpha(40)
                      : scheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isBest 
                        ? AppColors.success 
                        : scheme.outlineVariant,
                    width: isBest ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  '${serie.peso.toStringAsFixed(1)}kg × ${serie.reps}',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: isBest ? FontWeight.w700 : FontWeight.w500,
                    color: isBest ? AppColors.success : scheme.onSurface,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'hoy';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    if (diff.inDays < 14) return 'hace 1 semana';
    if (diff.inDays < 30) return 'hace ${(diff.inDays / 7).floor()} semanas';
    if (diff.inDays < 60) return 'hace 1 mes';
    return 'hace ${(diff.inDays / 30).floor()} meses';
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Favorito toggle
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onFavoriteToggle?.call();
              Navigator.of(context).pop();
            },
            icon: Icon(
              exercise.isFavorite ? Icons.star : Icons.star_border,
              color: exercise.isFavorite ? AppColors.warning : scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          // Cerrar
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CERRAR',
              style: AppTypography.labelLarge.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Añadir
          ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onAdd?.call();
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'AÑADIR',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
