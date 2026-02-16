import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design_system/design_system.dart';
import '../services/routine_ocr_service.dart';

/// Widget para importar rutinas desde imagen (OCR)
///
/// Flujo:
/// 1. Muestra BottomSheet para elegir Cámara o Galería
/// 2. Escanea la imagen con OCR
/// 3. Muestra preview con ejercicios detectados
/// 4. Permite editar antes de confirmar
class RoutineImportDialog extends StatefulWidget {
  final Function(List<ParsedExerciseCandidate>) onConfirm;
  final ImageSource source;

  const RoutineImportDialog({
    super.key,
    required this.onConfirm,
    required this.source,
  });

  @override
  State<RoutineImportDialog> createState() => _RoutineImportDialogState();

  /// Muestra el flujo completo de importación
  static Future<void> show(
    BuildContext context, {
    required Function(List<ParsedExerciseCandidate>) onConfirm,
  }) async {
    // Primero mostrar selector de fuente (Cámara/Galería)
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _SourceSelectorSheet(),
    );

    if (source == null) return;

    // Mostrar el diálogo de procesamiento y preview
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) =>
          RoutineImportDialog(onConfirm: onConfirm, source: source),
    );
  }
}

class _RoutineImportDialogState extends State<RoutineImportDialog> {
  final _ocrService = RoutineOcrService.instance;

  bool _isLoading = true;
  String? _error;
  List<ParsedExerciseCandidate> _candidates = [];

  // Controllers para edición
  final Map<int, TextEditingController> _seriesControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};

  @override
  void initState() {
    super.initState();
    // Usar post-frame callback para iniciar el escaneo después del build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  void dispose() {
    for (final c in _seriesControllers.values) {
      c.dispose();
    }
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Escanear imagen
      final lines = await _ocrService.scanImage(widget.source);

      if (lines.isEmpty) {
        setState(() {
          _isLoading = false;
          _error =
              'No se detectó texto en la imagen.\nIntenta con mejor iluminación o una imagen más nítida.';
        });
        return;
      }

      // 2. Parsear líneas
      final candidates = await _ocrService.parseLines(lines);

      // Filtrar solo los válidos (con ejercicio detectado)
      final validCandidates = candidates.where((c) => c.isValid).toList();

      if (validCandidates.isEmpty) {
        setState(() {
          _isLoading = false;
          _error =
              'No se detectaron ejercicios válidos.\n\nTexto encontrado:\n${lines.take(5).join('\n')}${lines.length > 5 ? '\n...' : ''}';
        });
        return;
      }

      // 3. Crear controllers para edición
      for (var i = 0; i < validCandidates.length; i++) {
        _seriesControllers[i] = TextEditingController(
          text: validCandidates[i].series.toString(),
        );
        _repsControllers[i] = TextEditingController(
          text: validCandidates[i].reps.toString(),
        );
      }

      setState(() {
        _candidates = validCandidates;
        _isLoading = false;
      });

      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error al procesar la imagen:\n${e.toString()}';
      });
    }
  }

  void _removeCandidate(int index) {
    setState(() {
      _candidates.removeAt(index);
      // Reorganizar controllers
      _seriesControllers.remove(index);
      _repsControllers.remove(index);
    });
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void _confirmImport() {
    // Actualizar los valores editados
    final updatedCandidates = <ParsedExerciseCandidate>[];

    for (var i = 0; i < _candidates.length; i++) {
      final candidate = _candidates[i];
      final series =
          int.tryParse(_seriesControllers[i]?.text ?? '') ?? candidate.series;
      final reps =
          int.tryParse(_repsControllers[i]?.text ?? '') ?? candidate.reps;

      updatedCandidates.add(candidate.copyWith(series: series, reps: reps));
    }

    widget.onConfirm(updatedCandidates);
    Navigator.pop(context);
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.document_scanner,
                  color: AppColors.neonPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'IMPORTAR RUTINA',
                    style: AppTypography.headlineSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
            height: 1,
          ),

          // Content
          Flexible(child: _buildContent()),

          // Bottom padding for keyboard
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.neonPrimary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Analizando imagen...',
              style: AppTypography.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detectando ejercicios con IA',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(97),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.neonPrimary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCELAR',
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Cerrar este diálogo y reiniciar el flujo completo
                    Navigator.pop(context);
                    if (mounted) {
                      // Re-trigger the full import flow
                      RoutineImportDialog.show(
                        context,
                        onConfirm: widget.onConfirm,
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(
                    'REINTENTAR',
                    style: AppTypography.labelLarge,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Preview de ejercicios detectados
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.neonCyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${_candidates.length} ejercicio${_candidates.length == 1 ? '' : 's'} detectado${_candidates.length == 1 ? '' : 's'}',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                ),
              ),
            ],
          ),
        ),

        // Lista de ejercicios
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _candidates.length,
            itemBuilder: (context, index) {
              return _buildCandidateRow(index);
            },
          ),
        ),

        // Botones de acción
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.neonPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'CANCELAR',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.neonPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _candidates.isEmpty ? null : _confirmImport,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    'AÑADIR ${_candidates.length}',
                    style: AppTypography.titleMedium,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateRow(int index) {
    final candidate = _candidates[index];
    final confidence = (candidate.confidence * 100).toInt();

    return Card(
      color: AppColors.bgElevated,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: nombre y delete
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.matchedExerciseName ?? 'Desconocido',
                        style: AppTypography.titleMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 12,
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(97),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${candidate.rawText}${candidate.cleanedText.isNotEmpty ? ' → "${candidate.cleanedText}"' : ''}',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withAlpha(97),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: confidence >= 70
                                  ? Colors.green.withAlpha((0.2 * 255).round())
                                  : confidence >= 50
                                  ? Colors.orange.withAlpha((0.2 * 255).round())
                                  : Colors.red.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$confidence%',
                              style: AppTypography.labelSmall.copyWith(
                                color: confidence >= 70
                                    ? AppColors.neonCyan
                                    : confidence >= 50
                                    ? AppColors.warning
                                    : AppColors.neonPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.error.withAlpha(200),
                    size: 20,
                  ),
                  onPressed: () => _removeCandidate(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Fila inferior: Series x Reps editables
            Row(
              children: [
                // Series
                _buildEditableField(
                  controller: _seriesControllers[index]!,
                  label: 'SERIES',
                  width: 60,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '×',
                    style: AppTypography.headlineSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
                    ),
                  ),
                ),
                // Reps
                _buildEditableField(
                  controller: _repsControllers[index]!,
                  label: 'REPS',
                  width: 60,
                ),
                const Spacer(),
                // Peso (si existe)
                if (candidate.weight != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${candidate.weight!.toStringAsFixed(candidate.weight! % 1 == 0 ? 0 : 1)} kg',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error.withAlpha(200),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required double width,
  }) {
    return Column(
      children: [
        SizedBox(
          width: width,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.bgDeep,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(97),
          ),
        ),
      ],
    );
  }
}

/// Sheet para seleccionar fuente de imagen (Cámara o Galería)
class _SourceSelectorSheet extends StatelessWidget {
  const _SourceSelectorSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'IMPORTAR RUTINA',
            style: AppTypography.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escanea una rutina escrita a mano o una captura de pantalla',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt,
                  label: 'CÁMARA',
                  subtitle: 'Foto a papel',
                  onTap: () {
                    try {
                      HapticFeedback.selectionClick();
                    } catch (_) {}
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library,
                  label: 'GALERÍA',
                  subtitle: 'Captura guardada',
                  onTap: () {
                    try {
                      HapticFeedback.selectionClick();
                    } catch (_) {}
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgElevated,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.neonPrimary, size: 40),
              const SizedBox(height: 12),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(138),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
