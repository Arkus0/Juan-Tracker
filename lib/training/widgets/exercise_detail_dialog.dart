import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/design_system.dart';
import '../../core/widgets/app_snackbar.dart';
import '../models/analysis_models.dart';
import '../models/library_exercise.dart';
import '../models/serie_log.dart';
import '../models/sesion.dart';
import '../providers/exercise_history_provider.dart';
import '../services/exercise_image_storage_service.dart';
import '../services/exercise_library_service.dart';
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
class ExerciseDetailDialog extends ConsumerStatefulWidget {
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
  ConsumerState<ExerciseDetailDialog> createState() =>
      _ExerciseDetailDialogState();
}

class _ExerciseDetailDialogState extends ConsumerState<ExerciseDetailDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  late LibraryExercise _exercise;
  bool _isUpdatingImage = false;

  @override
  void initState() {
    super.initState();
    _exercise = widget.exercise;
  }

  @override
  void didUpdateWidget(covariant ExerciseDetailDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _exercise = widget.exercise;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(exerciseHistoryProvider(_exercise.name));
    final trendAsync = ref.watch(
      exerciseStrengthTrendProvider(_exercise.name),
    );

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
                      _exercise.name.toUpperCase(),
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // PR Badge
                    if (widget.personalRecord != null)
                      _buildPRBadge(scheme),

                    // Tags (músculo + equipo)
                    _buildTags(scheme),
                    const SizedBox(height: 16),

                    // Descripción
                    if (_exercise.description?.isNotEmpty ?? false) ...[
                      Text(
                        'Descripción',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _exercise.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Progreso rápido
                    _buildQuickProgress(scheme, trendAsync),
                    const SizedBox(height: 16),

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
            child: _buildHeaderImage(scheme),
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
        if (!_exercise.isCurated)
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

        // Botón de foto
        Positioned(
          bottom: 8,
          right: 8,
          child: IconButton(
            onPressed: _isUpdatingImage ? null : () => _showImageOptions(),
            style: IconButton.styleFrom(
              backgroundColor: scheme.surface.withAlpha(210),
            ),
            icon: _isUpdatingImage
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  )
                : Icon(Icons.photo_camera, color: scheme.onSurface),
            tooltip: 'Cambiar foto',
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderImage(ColorScheme scheme) {
    final localPath = _exercise.localImagePath;
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 160,
          errorBuilder: (_, _, _) => _buildPlaceholder(scheme),
        );
      }
    }

    if (_exercise.imageUrls.isNotEmpty) {
      return Image.network(
        _exercise.imageUrls.first,
        fit: BoxFit.cover,
        cacheWidth: 380,
        errorBuilder: (_, _, _) => _buildPlaceholder(scheme),
      );
    }

    return _buildPlaceholder(scheme);
  }

  Future<void> _showImageOptions() async {
    if (_isUpdatingImage) return;

    final action = await showModalBottomSheet<_ImageAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, _ImageAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, _ImageAction.gallery),
            ),
            if (_exercise.localImagePath != null &&
                _exercise.localImagePath!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Quitar foto'),
                onTap: () => Navigator.pop(ctx, _ImageAction.remove),
              ),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;
    switch (action) {
      case _ImageAction.camera:
        await _pickAndSaveImage(ImageSource.camera);
        break;
      case _ImageAction.gallery:
        await _pickAndSaveImage(ImageSource.gallery);
        break;
      case _ImageAction.remove:
        await _removeImage();
        break;
    }
  }

  Future<void> _pickAndSaveImage(ImageSource source) async {
    if (_isUpdatingImage) return;
    setState(() => _isUpdatingImage = true);

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      final imageService = ExerciseImageStorageService.instance;
      final savedPath = await imageService.persistImage(
        sourcePath: picked.path,
        exerciseId: _exercise.id,
      );

      await imageService.deleteImageIfExists(_exercise.localImagePath);
      await ExerciseLibraryService.instance.setExerciseImage(
        exerciseId: _exercise.id,
        localImagePath: savedPath,
      );

      final updated =
          ExerciseLibraryService.instance.getExerciseById(_exercise.id);
      if (updated != null && mounted) {
        setState(() => _exercise = updated);
      }

      if (mounted) {
        AppSnackbar.show(context, message: 'Foto actualizada');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error al guardar la foto');
      }
    } finally {
      if (mounted) setState(() => _isUpdatingImage = false);
    }
  }

  Future<void> _removeImage() async {
    if (_isUpdatingImage) return;
    setState(() => _isUpdatingImage = true);
    try {
      final imageService = ExerciseImageStorageService.instance;
      await imageService.deleteImageIfExists(_exercise.localImagePath);
      await ExerciseLibraryService.instance.setExerciseImage(
        exerciseId: _exercise.id,
        localImagePath: null,
      );

      final updated =
          ExerciseLibraryService.instance.getExerciseById(_exercise.id);
      if (updated != null && mounted) {
        setState(() => _exercise = updated);
      }

      if (mounted) {
        AppSnackbar.show(context, message: 'Foto eliminada');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error al eliminar la foto');
      }
    } finally {
      if (mounted) setState(() => _isUpdatingImage = false);
    }
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
              'RÉCORD: ${widget.personalRecord!.maxWeight.toStringAsFixed(1)}kg × ${widget.personalRecord!.repsAtMax}',
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
            _exercise.muscleGroup.toUpperCase(),
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
                _exercise.equipment,
                style: AppTypography.labelSmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Músculos secundarios
        ..._exercise.muscles.take(3).map((m) => Container(
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

  Widget _buildQuickProgress(
    ColorScheme scheme,
    AsyncValue<List<StrengthDataPoint>> trendAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 18, color: scheme.tertiary),
            const SizedBox(width: 6),
            Text(
              'Progreso rápido',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        trendAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => _buildQuickProgressEmpty(scheme),
          data: (points) {
            if (points.isEmpty) return _buildQuickProgressEmpty(scheme);
            return _buildQuickProgressContent(scheme, points);
          },
        ),
      ],
    );
  }

  Widget _buildQuickProgressContent(
    ColorScheme scheme,
    List<StrengthDataPoint> points,
  ) {
    final last = points.last.estimated1RM;
    final first = points.first.estimated1RM;
    final best = points
        .map((p) => p.estimated1RM)
        .reduce((a, b) => a > b ? a : b);
    final delta = last - first;
    final deltaPct = first > 0 ? (delta / first) * 100 : 0.0;
    final deltaStr =
        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}kg';
    final deltaPctStr =
        '${delta >= 0 ? '+' : ''}${deltaPct.toStringAsFixed(1)}%';
    final deltaColor = delta >= 0 ? AppColors.success : scheme.error;

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: _buildMiniTrendChart(scheme, points),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatPill(
              scheme,
              label: 'Último 1RM',
              value: '${last.toStringAsFixed(1)}kg',
            ),
            const SizedBox(width: 8),
            _buildStatPill(
              scheme,
              label: 'Mejor 1RM',
              value: '${best.toStringAsFixed(1)}kg',
            ),
            const SizedBox(width: 8),
            _buildStatPill(
              scheme,
              label: 'Cambio',
              value: '$deltaStr\n$deltaPctStr',
              valueColor: deltaColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniTrendChart(
    ColorScheme scheme,
    List<StrengthDataPoint> points,
  ) {
    final spots = <FlSpot>[];
    double minY = points.first.estimated1RM;
    double maxY = points.first.estimated1RM;

    for (var i = 0; i < points.length; i++) {
      final value = points[i].estimated1RM;
      spots.add(FlSpot(i.toDouble(), value));
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    var padding = (maxY - minY) * 0.1;
    if (padding == 0) padding = 5;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.length > 1 ? spots.length - 1 : 1,
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: scheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withAlpha(60),
                  scheme.primary.withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    ColorScheme scheme, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickProgressEmpty(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.show_chart, color: scheme.onSurfaceVariant.withAlpha(140)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aún sin datos suficientes para mostrar progreso.',
              style: AppTypography.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
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
      (e) => e.nombre.toLowerCase() == _exercise.name.toLowerCase(),
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
              widget.onFavoriteToggle?.call();
              Navigator.of(context).pop();
            },
            icon: Icon(
              _exercise.isFavorite ? Icons.star : Icons.star_border,
              color: _exercise.isFavorite
                  ? AppColors.warning
                  : scheme.onSurfaceVariant,
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
              widget.onAdd?.call();
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

enum _ImageAction { camera, gallery, remove }
