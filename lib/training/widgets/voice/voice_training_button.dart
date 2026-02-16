import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../providers/voice_input_provider.dart' as vip;
import 'voice_training_fab.dart' show VoiceTrainingCommand, VoiceCommandType;

// Re-exportar los tipos del FAB para compatibilidad
export 'voice_training_fab.dart' show VoiceTrainingCommand, VoiceCommandType;

/// Contexto de la serie activa para mostrar en el overlay
class VoiceTrainingContext {
  final String exerciseName;
  final int currentSet;
  final int totalSets;
  final double? currentWeight;
  final int? currentReps;
  final double? currentRpe;

  const VoiceTrainingContext({
    required this.exerciseName,
    required this.currentSet,
    required this.totalSets,
    this.currentWeight,
    this.currentReps,
    this.currentRpe,
  });
}

/// Botón de voz compacto para usar en AppBar durante entrenamiento
///
/// Diseño UX - PUSH TO TALK:
/// - IconButton que cabe en el AppBar junto a otros botones
/// - Muestra overlay modal con transcripción y CONTEXTO al escuchar
/// - Indica claramente qué serie/campo se va a modificar
class VoiceTrainingButton extends ConsumerStatefulWidget {
  final Function(VoiceTrainingCommand) onCommand;
  final bool enabled;
  final VoiceTrainingContext? context; // Contexto de la serie activa

  const VoiceTrainingButton({
    super.key,
    required this.onCommand,
    this.enabled = true,
    this.context,
  });

  @override
  ConsumerState<VoiceTrainingButton> createState() =>
      _VoiceTrainingButtonState();
}

class _VoiceTrainingButtonState extends ConsumerState<VoiceTrainingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showListeningOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => _ListeningOverlay(
        onDismiss: _onStopListening,
        context: widget.context, // Pasar contexto de la serie activa
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _onTap() async {
    if (!widget.enabled) return;

    final notifier = ref.read(vip.voiceInputProvider.notifier);
    final currentState = ref.read(vip.voiceInputProvider);

    if (currentState.isListening) {
      await _onStopListening();
    } else {
      // Empezar a escuchar
      _pulseController.repeat(reverse: true);
      _showListeningOverlay();
      await notifier.startListening();
    }
  }

  Future<void> _onStopListening() async {
    final notifier = ref.read(vip.voiceInputProvider.notifier);

    _removeOverlay();
    _pulseController.stop();
    _pulseController.reset();

    await notifier.stopListening();

    // Obtener el transcript del estado actualizado
    final updatedState = ref.read(vip.voiceInputProvider);
    final transcript = updatedState.transcript;

    // Parsear comando de entrenamiento
    if (transcript.isNotEmpty) {
      final command = _parseTrainingCommand(transcript);
      if (command != null) {
        // Registrar acción para undo
        notifier.recordAction(
          vip.VoiceAction(description: _getActionDescription(command)),
        );
        widget.onCommand(command);
      } else {
        // No se entendió el comando - mostrar feedback
        _showNotUnderstoodSnackbar(transcript);
      }
    } else if (updatedState.notUnderstood) {
      // No se captó nada
      _showNotUnderstoodSnackbar(null);
    }
    // Limpiar después de procesar
    notifier.clearResults();
  }

  String _getActionDescription(VoiceTrainingCommand command) {
    switch (command.type) {
      case VoiceCommandType.setWeight:
        return 'Peso: ${command.value?.toStringAsFixed(1)} kg';
      case VoiceCommandType.setReps:
        return 'Reps: ${command.value?.toInt()}';
      case VoiceCommandType.setRpe:
        return 'RPE: ${command.value?.toStringAsFixed(1)}';
      case VoiceCommandType.addNote:
        return 'Nota añadida';
      case VoiceCommandType.markDone:
        return 'Serie completada';
      case VoiceCommandType.nextSet:
        return 'Siguiente serie';
      case VoiceCommandType.startRest:
        return 'Descanso iniciado';
    }
  }

  void _showNotUnderstoodSnackbar(String? transcript) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                transcript != null
                    ? 'No entendido: "$transcript"'
                    : 'No se detectó voz',
                style: AppTypography.bodyMedium,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.bgElevated,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'REINTENTAR',
          textColor: colorScheme.error,
          onPressed: _onTap,
        ),
      ),
    );
  }

  VoiceTrainingCommand? _parseTrainingCommand(String transcript) {
    var normalized = transcript.toLowerCase().trim();

    // Normalizar números hablados en español
    normalized = _normalizeSpokenNumbers(normalized);

    // Comando: "Hecho" / "Listo" / "Serie completada" / "Ya"
    if (RegExp(
      r'^(hecho|listo|completado|terminado|ya|vale|ok|serie\s+(?:hecha|completada))',
    ).hasMatch(normalized)) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
      return const VoiceTrainingCommand(type: VoiceCommandType.markDone);
    }

    // Comando: "Siguiente" / "Next" / "Próxima serie"
    if (RegExp(r'^(siguiente|next|proxim|adelante|otra)').hasMatch(normalized)) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
      return const VoiceTrainingCommand(type: VoiceCommandType.nextSet);
    }

    // Comando: "Descanso" / "Timer" / "Descansar X segundos"
    final restMatch = RegExp(
      r'(?:descanso|timer|descansar)\s*(?:de\s*)?(\d+)?',
    ).firstMatch(normalized);
    if (restMatch != null) {
      final seconds = restMatch.group(1);
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
      return VoiceTrainingCommand(
        type: VoiceCommandType.startRest,
        value: seconds != null ? int.tryParse(seconds)?.toDouble() : null,
      );
    }

    // Comando: "Peso X kilos" / "X kilos" / "X kg" / "a X kilos" / "con X kg"
    final weightMatch = RegExp(
      r'(?:peso\s*|a\s*|con\s*)?(\d+(?:[.,]\d+)?)\s*(?:kilos?|kg|k)',
    ).firstMatch(normalized);
    if (weightMatch != null) {
      final weightStr = weightMatch.group(1)!.replaceAll(',', '.');
      final weight = double.tryParse(weightStr);
      if (weight != null && weight > 0 && weight <= 500) {
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
        return VoiceTrainingCommand(
          type: VoiceCommandType.setWeight,
          value: weight,
        );
      }
    }

    // Comando: "X repeticiones" / "X reps" / "hice X" / "he hecho X"
    final repsMatch = RegExp(
      r'(?:hice\s*|he\s+hecho\s*)?(\d+)\s*(?:reps?|repeticiones?|veces)?',
    ).firstMatch(normalized);
    if (repsMatch != null) {
      final reps = int.tryParse(repsMatch.group(1)!);
      // Solo aceptar si parece realmente reps (1-50 range típico)
      if (reps != null && reps >= 1 && reps <= 50) {
        // Evitar conflicto con peso: si el texto contiene "kg/kilos" no es reps
        if (!normalized.contains('kilo') &&
            !normalized.contains(' kg') &&
            !normalized.contains(' k ')) {
          try {
            HapticFeedback.selectionClick();
          } catch (_) {}
          return VoiceTrainingCommand(
            type: VoiceCommandType.setReps,
            value: reps.toDouble(),
          );
        }
      }
    }

    // Comando combinado: "X kilos Y reps" / "80 12" (peso primero, luego reps)
    final combinedMatch = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:kilos?|kg|k)?\s+(\d+)\s*(?:reps?|repeticiones?)?',
    ).firstMatch(normalized);
    if (combinedMatch != null) {
      final weightStr = combinedMatch.group(1)!.replaceAll(',', '.');
      final weight = double.tryParse(weightStr);
      final reps = int.tryParse(combinedMatch.group(2)!);
      // Si el primer número parece peso (>20) y el segundo reps (<50)
      if (weight != null && weight >= 20 && reps != null && reps <= 50) {
        // Retornamos peso primero (el más importante de capturar)
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
        return VoiceTrainingCommand(
          type: VoiceCommandType.setWeight,
          value: weight,
        );
      }
    }

    // Comando: "RPE X" / "Esfuerzo X"
    final rpeMatch = RegExp(
      r'(?:rpe|esfuerzo|dificultad)\s*(\d+(?:[.,]\d+)?)',
    ).firstMatch(normalized);
    if (rpeMatch != null) {
      final rpeStr = rpeMatch.group(1)!.replaceAll(',', '.');
      final rpe = double.tryParse(rpeStr);
      if (rpe != null && rpe >= 1 && rpe <= 10) {
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
        return VoiceTrainingCommand(type: VoiceCommandType.setRpe, value: rpe);
      }
    }

    // Comando: "Nota: texto" / "Anotar: texto" / "Apuntar: texto"
    final noteMatch = RegExp(
      r'^(?:nota|anotar|apuntar|apunta|anota)[:\s]+(.+)',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (noteMatch != null) {
      final noteText = noteMatch.group(1)!.trim();
      if (noteText.isNotEmpty) {
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
        return VoiceTrainingCommand(
          type: VoiceCommandType.addNote,
          note: noteText,
        );
      }
    }

    // No reconocido
    return null;
  }

  /// Normaliza números hablados en español a dígitos
  String _normalizeSpokenNumbers(String text) {
    const numberWords = {
      'cero': '0', 'uno': '1', 'una': '1', 'dos': '2', 'tres': '3',
      'cuatro': '4', 'cinco': '5', 'seis': '6', 'siete': '7', 'ocho': '8',
      'nueve': '9', 'diez': '10', 'once': '11', 'doce': '12', 'trece': '13',
      'catorce': '14', 'quince': '15', 'dieciséis': '16', 'dieciseis': '16',
      'diecisiete': '17', 'dieciocho': '18', 'diecinueve': '19',
      'veinte': '20', 'veintiuno': '21', 'veintidós': '22', 'veintidos': '22',
      'veintitrés': '23', 'veintitres': '23', 'veinticuatro': '24',
      'veinticinco': '25', 'treinta': '30', 'cuarenta': '40', 'cincuenta': '50',
      'sesenta': '60', 'setenta': '70', 'ochenta': '80', 'noventa': '90',
      'cien': '100', 'ciento': '100',
    };

    var result = text;
    for (final entry in numberWords.entries) {
      result = result.replaceAll(RegExp('\\b${entry.key}\\b'), entry.value);
    }

    // Manejar "treinta y cinco" → "35", etc.
    result = result.replaceAllMapped(
      RegExp(r'(\d0)\s+y\s+(\d)'),
      (m) => (int.parse(m.group(1)!) + int.parse(m.group(2)!)).toString(),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final voiceState = ref.watch(vip.voiceInputProvider);
    final isListening = voiceState.isListening;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: isListening
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(
                        alpha: 0.3 + _pulseController.value * 0.3,
                      ),
                      blurRadius: 8 + _pulseController.value * 4,
                      spreadRadius: _pulseController.value * 2,
                    ),
                  ],
                )
              : null,
          child: IconButton(
            onPressed: _onTap,
            icon: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: isListening ? AppColors.neonPrimary : colorScheme.onSurface.withAlpha(178),
            ),
            tooltip: isListening
                ? 'Escuchando...'
                : 'Dictar series (ej: 80kg, 10 reps)',
            style: IconButton.styleFrom(
              backgroundColor: isListening
                  ? AppColors.live.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
        );
      },
    );
  }
}

/// Overlay modal que muestra la transcripción y CONTEXTO mientras escucha
/// Diseño UX: Muestra claramente qué serie/campo se va a modificar
class _ListeningOverlay extends ConsumerWidget {
  final VoidCallback onDismiss;
  final VoiceTrainingContext? context;

  const _ListeningOverlay({required this.onDismiss, this.context});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final voiceState = ref.watch(vip.voiceInputProvider);
    final text = voiceState.partialTranscript.isNotEmpty
        ? voiceState.partialTranscript
        : 'Di: "80 kilos", "10 reps", "RPE 8", "hecho"...';

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onDismiss,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              left: 16,
              right: 16,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.live.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de escucha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _PulsingMicIcon(),
                      const SizedBox(width: 12),
                      Text(
                        'ESCUCHANDO...',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.neonPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // CONTEXTO: Qué serie se va a modificar
                  if (this.context != null) ...[
                    _buildContextIndicator(this.context!, colorScheme),
                    const SizedBox(height: 16),
                  ],

                  // Transcripción en tiempo real
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgDeep,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          text,
                          style: AppTypography.titleMedium.copyWith(
                            color: voiceState.partialTranscript.isEmpty
                                ? colorScheme.onSurface.withAlpha(97)
                                : colorScheme.onSurface,
                            fontStyle: voiceState.partialTranscript.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (voiceState.partialTranscript.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildLivePreview(voiceState.partialTranscript, colorScheme),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comandos disponibles
                  _buildAvailableCommands(colorScheme),

                  const SizedBox(height: 12),
                  // Hint para cerrar
                  Text(
                    'Toca en cualquier lugar para detener',
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.onSurface.withAlpha(97),
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

  /// Indicador de contexto: muestra qué serie se va a modificar
  Widget _buildContextIndicator(VoiceTrainingContext ctx, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neonCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                size: 16,
                color: AppColors.neonCyan.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                'MODIFICANDO:',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ctx.exerciseName,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Serie ${ctx.currentSet} de ${ctx.totalSets}',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface.withAlpha(178),
            ),
          ),
          const SizedBox(height: 8),
          // Campos actuales
          Row(
            children: [
              _FieldChip(
                label: 'Peso',
                value: ctx.currentWeight != null
                    ? '${ctx.currentWeight!.toStringAsFixed(1)} kg'
                    : '--',
                isSet: ctx.currentWeight != null,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _FieldChip(
                label: 'Reps',
                value: ctx.currentReps?.toString() ?? '--',
                isSet: ctx.currentReps != null,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),
              _FieldChip(
                label: 'RPE',
                value: ctx.currentRpe?.toStringAsFixed(1) ?? '--',
                isSet: ctx.currentRpe != null,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Preview en tiempo real de lo que se va a cambiar
  Widget _buildLivePreview(String transcript, ColorScheme colorScheme) {
    // Detectar qué tipo de comando se está diciendo
    final normalized = transcript.toLowerCase().trim();
    String? detectedType;
    String? detectedValue;
    IconData? detectedIcon;
    Color? detectedColor;

    // Detectar peso
    final weightMatch = RegExp(
      r'(?:peso\s*|a\s*|con\s*)?(\d+(?:[.,]\d+)?)\s*(?:kilos?|kg|k)',
    ).firstMatch(normalized);
    if (weightMatch != null) {
      detectedType = 'PESO';
      detectedValue = '${weightMatch.group(1)} kg';
      detectedIcon = Icons.scale;
      detectedColor = Colors.orange;
    }

    // Detectar reps
    if (detectedType == null) {
      final repsMatch = RegExp(
        r'(\d+)\s*(?:reps?|repeticiones?|veces)',
      ).firstMatch(normalized);
      if (repsMatch != null) {
        detectedType = 'REPS';
        detectedValue = repsMatch.group(1);
        detectedIcon = Icons.tag;
        detectedColor = Colors.blue;
      }
    }

    // Detectar RPE
    if (detectedType == null) {
      final rpeMatch = RegExp(
        r'(?:rpe|esfuerzo|dificultad)\s*(\d+(?:[.,]\d+)?)',
      ).firstMatch(normalized);
      if (rpeMatch != null) {
        detectedType = 'RPE';
        detectedValue = rpeMatch.group(1);
        detectedIcon = Icons.speed;
        detectedColor = Colors.purple;
      }
    }

    // Detectar comandos
    if (detectedType == null) {
      if (RegExp(r'^(hecho|listo|completado|terminado|ya|vale|ok)').hasMatch(normalized)) {
        detectedType = 'MARCAR';
        detectedValue = 'Serie completada';
        detectedIcon = Icons.check_circle;
        detectedColor = Colors.green;
      } else if (RegExp(r'^(siguiente|next|proxim|adelante|otra)').hasMatch(normalized)) {
        detectedType = 'IR A';
        detectedValue = 'Siguiente serie';
        detectedIcon = Icons.arrow_forward;
        detectedColor = AppColors.neonCyan;
      } else if (RegExp(r'(?:descanso|timer|descansar)').hasMatch(normalized)) {
        detectedType = 'INICIAR';
        detectedValue = 'Descanso';
        detectedIcon = Icons.timer;
        detectedColor = Colors.teal;
      }
    }

    if (detectedType == null) {
      // Nada detectado aún, mostrar indicador de escucha
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PulsingDot(color: Colors.green, size: 6),
          SizedBox(width: 8),
          _PulsingDot(color: Colors.green, size: 6),
          SizedBox(width: 8),
          _PulsingDot(color: Colors.green, size: 6),
        ],
      );
    }

    // Mostrar preview de lo que se detectó
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: detectedColor!.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: detectedColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(detectedIcon, size: 16, color: detectedColor),
          const SizedBox(width: 8),
          Text(
            '$detectedType: $detectedValue',
            style: AppTypography.labelLarge.copyWith(
              color: detectedColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.check, size: 14, color: detectedColor.withValues(alpha: 0.7)),
        ],
      ),
    );
  }

  /// Lista de comandos disponibles
  Widget _buildAvailableCommands(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        _CommandHint(label: '80 kilos', icon: Icons.scale, colorScheme: colorScheme),
        _CommandHint(label: '10 reps', icon: Icons.tag, colorScheme: colorScheme),
        _CommandHint(label: 'RPE 8', icon: Icons.speed, colorScheme: colorScheme),
        _CommandHint(label: 'Hecho', icon: Icons.check, colorScheme: colorScheme),
        _CommandHint(label: 'Nota: ...', icon: Icons.note, colorScheme: colorScheme),
      ],
    );
  }
}

/// Chip para mostrar el estado de un campo
class _FieldChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSet;
  final ColorScheme colorScheme;

  const _FieldChip({
    required this.label,
    required this.value,
    required this.isSet,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSet
            ? AppColors.success.withValues(alpha: 0.2)
            : AppColors.bgDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSet
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurface.withAlpha(138),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isSet ? AppColors.success : colorScheme.onSurface.withAlpha(97),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hint de comando disponible
class _CommandHint extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;

  const _CommandHint({
    required this.label,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgDeep,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurface.withAlpha(97)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurface.withAlpha(138),
            ),
          ),
        ],
      ),
    );
  }
}

/// Punto pulsante para indicadores
class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingDot({required this.color, this.size = 8});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withValues(
              alpha: 0.5 + _controller.value * 0.5,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _PulsingMicIcon extends StatefulWidget {
  const _PulsingMicIcon();

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Icon(
          Icons.mic,
          size: 28,
          color: AppColors.neonPrimary.withValues(
            alpha: 0.6 + _controller.value * 0.4,
          ),
        );
      },
    );
  }
}
