import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../providers/voice_input_provider.dart';

/// FAB flotante sutil para control por voz durante entrenamiento
///
/// Diseño UX:
/// - Pequeño y discreto en esquina inferior izquierda
/// - Se expande al pulsar para mostrar comandos
/// - Transcripción en tiempo real en tooltip flotante
/// - Comandos soportados: "Hecho", "Siguiente", "Peso X kilos"
class VoiceTrainingFab extends ConsumerStatefulWidget {
  final Function(VoiceTrainingCommand) onCommand;
  final bool enabled;

  const VoiceTrainingFab({
    super.key,
    required this.onCommand,
    this.enabled = true,
  });

  @override
  ConsumerState<VoiceTrainingFab> createState() => _VoiceTrainingFabState();
}

class _VoiceTrainingFabState extends ConsumerState<VoiceTrainingFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showTranscript = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (!widget.enabled) return;

    final notifier = ref.read(voiceInputProvider.notifier);
    final currentState = ref.read(voiceInputProvider);

    if (currentState.isListening) {
      await notifier.stopListening();
      final updatedState = ref.read(voiceInputProvider);
      final transcript = updatedState.transcript;

      setState(() => _showTranscript = false);
      _pulseController.stop();
      _pulseController.reset();

      if (transcript.isNotEmpty) {
        final command = _parseTrainingCommand(transcript);
        if (command != null) {
          widget.onCommand(command);
        }
      }
      notifier.clearResults();
    } else {
      setState(() => _showTranscript = true);
      _pulseController.repeat(reverse: true);
      await notifier.startListening();
    }
  }

  VoiceTrainingCommand? _parseTrainingCommand(String transcript) {
    var normalized = transcript.toLowerCase().trim();

    // Normalizar números hablados en español
    normalized = _normalizeSpokenNumbers(normalized);

    // Comando: "Hecho" / "Listo" / "Serie completada" / "Ya"
    if (RegExp(r'^(hecho|listo|completado|terminado|ya|vale|ok|serie\s+(?:hecha|completada))').hasMatch(normalized)) {
      try { HapticFeedback.heavyImpact(); } catch (e) { debugPrint('[Voice] Haptic error: $e'); }
      return const VoiceTrainingCommand(type: VoiceCommandType.markDone);
    }

    // Comando: "Siguiente" / "Next" / "Próxima serie"
    if (RegExp(r'^(siguiente|next|proxim|adelante|otra)').hasMatch(normalized)) {
      try { HapticFeedback.mediumImpact(); } catch (e) { debugPrint('[Voice] Haptic error: $e'); }
      return const VoiceTrainingCommand(type: VoiceCommandType.nextSet);
    }

    // Comando: "Descanso" / "Timer" / "Descansar X segundos"
    final restMatch = RegExp(r'(?:descanso|timer|descansar)\s*(?:de\s*)?(\d+)?').firstMatch(normalized);
    if (restMatch != null) {
      final seconds = restMatch.group(1);
      try { HapticFeedback.lightImpact(); } catch (e) { debugPrint('[Voice] Haptic error: $e'); }
      return VoiceTrainingCommand(type: VoiceCommandType.startRest, value: seconds != null ? int.tryParse(seconds)?.toDouble() : null);
    }

    // Comando combinado PRIMERO: "X kilos Y reps" / "80 kilos 12 reps" / "80 12"
    // Este regex debe ir antes de los individuales para capturar ambos valores
    final combinedMatch = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:kilos?|kg|k)?\s+(?:por\s+|x\s+)?(\d+)\s*(?:reps?|repeticiones?|veces)?',
    ).firstMatch(normalized);
    if (combinedMatch != null) {
      final weightStr = combinedMatch.group(1)!.replaceAll(',', '.');
      final weight = double.tryParse(weightStr);
      final reps = int.tryParse(combinedMatch.group(2)!);
      // Si el primer número parece peso (>=15) y el segundo reps (<=100)
      if (weight != null && weight >= 15 && reps != null && reps >= 1 && reps <= 100) {
        // Retornamos peso (el más importante, reps se puede inferir)
        try { HapticFeedback.selectionClick(); } catch (e) { debugPrint('[Voice] Haptic error: $e'); }
        return VoiceTrainingCommand(type: VoiceCommandType.setWeight, value: weight);
      }
    }

    // Comando: "Peso X kilos" / "X kilos" / "X kg" / "a X kilos" / "con X kg"
    // También acepta números grandes sin unidad (>= 20 se asume como peso)
    final weightMatch = RegExp(
      r'(?:peso\s*|a\s*|con\s*)?(\d+(?:[.,]\d+)?)\s*(?:kilos?|kg|k)?',
    ).firstMatch(normalized);
    if (weightMatch != null) {
      final weightStr = weightMatch.group(1)!.replaceAll(',', '.');
      final weight = double.tryParse(weightStr);
      if (weight != null && weight > 0 && weight <= 500) {
        // Si tiene unidad explícita (kilos/kg), aceptar cualquier peso válido
        final hasUnit = RegExp(r'(?:kilos?|kg|k)\b').hasMatch(normalized);
        // Sin unidad: solo aceptar si >= 20 (claramente peso, no reps)
        if (hasUnit || weight >= 20) {
          try { HapticFeedback.selectionClick(); } catch (e) { debugPrint('[Voice] Haptic error: $e'); }
          return VoiceTrainingCommand(type: VoiceCommandType.setWeight, value: weight);
        }
      }
    }

    // Comando: "X repeticiones" / "X reps" / "hice X" / "he hecho X"
    // También acepta números pequeños sin contexto (1-19 se asume como reps)
    final repsMatch = RegExp(
      r'(?:hice\s*|he\s+hecho\s*)?(\d+)\s*(?:reps?|repeticiones?|veces)?',
    ).firstMatch(normalized);
    if (repsMatch != null) {
      final reps = int.tryParse(repsMatch.group(1)!);
      // Aceptar si parece reps (1-99 range)
      if (reps != null && reps >= 1 && reps <= 99) {
        // Evitar conflicto con peso: si ya procesamos peso, no duplicar
        final hasWeightUnit = normalized.contains('kilo') || 
            RegExp(r'\d+\s*kg\b').hasMatch(normalized) ||
            RegExp(r'\d+\s*k\b').hasMatch(normalized);
        // Si tiene unidad de reps explícita, o es número pequeño (1-19), es reps
        final hasRepsUnit = normalized.contains('rep') || normalized.contains('veces');
        if (hasRepsUnit || (!hasWeightUnit && reps <= 19)) {
          try { HapticFeedback.selectionClick(); } catch (e) { debugPrint('[Voice] Haptic error: $e'); }
          return VoiceTrainingCommand(type: VoiceCommandType.setReps, value: reps.toDouble());
        }
      }
    }

    // Comando: "RPE X" / "Esfuerzo X"
    final rpeMatch = RegExp(r'(?:rpe|esfuerzo|dificultad)\s*(\d+(?:[.,]\d+)?)').firstMatch(normalized);
    if (rpeMatch != null) {
      final rpeStr = rpeMatch.group(1)!.replaceAll(',', '.');
      final rpe = double.tryParse(rpeStr);
      if (rpe != null && rpe >= 1 && rpe <= 10) {
        try { HapticFeedback.selectionClick(); } catch (e) { debugPrint('[Voice] Haptic error: $e'); }
        return VoiceTrainingCommand(type: VoiceCommandType.setRpe, value: rpe);
      }
    }

    // Comando: "Nota: texto" / "Anotar: texto" / "Apuntar: texto"
    final noteMatch = RegExp(r'^(?:nota|anotar|apuntar|apunta|anota)[:\s]+(.+)', caseSensitive: false).firstMatch(normalized);
    if (noteMatch != null) {
      final noteText = noteMatch.group(1)!.trim();
      if (noteText.isNotEmpty) {
        try { HapticFeedback.selectionClick(); } catch (e) { debugPrint('[Voice] Haptic error: $e'); }
        return VoiceTrainingCommand(type: VoiceCommandType.addNote, note: noteText);
      }
    }

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
    final voiceState = ref.watch(voiceInputProvider);
    final isListening = voiceState.isListening;
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        if (_showTranscript && (isListening || voiceState.partialTranscript.isNotEmpty))
          Positioned(
            bottom: 80,
            left: 16,
            right: 80,
            child: _buildTranscriptBubble(voiceState, onSurface),
          ),
        Positioned(
          bottom: 16,
          left: 16,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = isListening ? 1.0 + (_pulseController.value * 0.15) : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: FloatingActionButton.small(
              heroTag: 'voice_training_fab',
              onPressed: _onTap,
              backgroundColor: isListening ? Colors.red[600] : AppColors.bgElevated,
              foregroundColor: onSurface,
              elevation: isListening ? 8 : 4,
              child: Icon(isListening ? Icons.mic : Icons.mic_none, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTranscriptBubble(VoiceInputState voiceState, Color onSurface) {
    final text = voiceState.partialTranscript.isNotEmpty
        ? voiceState.partialTranscript
        : 'Di: "Hecho", "50 kilos", "10 reps"...';

    return AnimatedOpacity(
      opacity: voiceState.isListening ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: voiceState.isListening ? AppColors.error.withValues(alpha: 0.5) : AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (voiceState.isListening) ...[
              const _PulsingDot(size: 10),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: voiceState.partialTranscript.isEmpty ? onSurface.withAlpha(97) : onSurface.withAlpha(178),
                  fontStyle: voiceState.partialTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final double size;
  const _PulsingDot({required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
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
      builder: (context, child) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red[500]!.withValues(alpha: 0.5 + _controller.value * 0.5)),
      ),
    );
  }
}

/// Comando de entrenamiento parseado desde voz
class VoiceTrainingCommand {
  final VoiceCommandType type;
  final double? value;
  final String? note;

  const VoiceTrainingCommand({required this.type, this.value, this.note});
}

/// Tipos de comandos de voz para entrenamiento
enum VoiceCommandType {
  markDone,
  nextSet,
  setWeight,
  setReps,
  setRpe,
  startRest,
  addNote,
}
