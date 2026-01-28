import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/external_session.dart';
import '../providers/training_provider.dart';
import '../providers/voice_input_provider.dart';
import '../services/voice_input_service.dart';
import '../utils/design_system.dart';
import '../widgets/voice/voice_mic_button.dart';

/// Pantalla para agregar sesiones de entrenamiento realizadas fuera de la app
///
/// Soporta tres modos de entrada:
/// 1. VOZ: Dictar la sesión completa (fecha, ejercicios, series, reps, peso)
/// 2. MANUAL: Formularios tap-by-tap para máxima precisión
/// 3. HÍBRIDO: Voz + edición manual
///
/// Las sesiones externas se marcan visualmente en el historial y
/// NO afectan métricas de progresión automática por defecto.
class ExternalSessionScreen extends ConsumerStatefulWidget {
  const ExternalSessionScreen({super.key});

  @override
  ConsumerState<ExternalSessionScreen> createState() =>
      _ExternalSessionScreenState();
}

class _ExternalSessionScreenState extends ConsumerState<ExternalSessionScreen> {
  DateTime _selectedDate = DateTime.now();
  final List<_ExternalExercise> _exercises = [];
  String? _sessionNotes;
  bool _includeInStats = false; // Opt-in para incluir en estadísticas

  // Estado de entrada
  _InputMode _inputMode = _InputMode.voice;

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceInputProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AGREGAR SESIÓN EXTERNA',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        actions: [
          if (_exercises.isNotEmpty)
            TextButton(
              onPressed: _onSaveSession,
              child: Text(
                'GUARDAR',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner informativo
            _buildInfoBanner(),
            const SizedBox(height: 20),

            // Selector de fecha
            _buildDateSelector(),
            const SizedBox(height: 20),

            // Selector de modo de entrada
            _buildModeSelector(),
            const SizedBox(height: 20),

            // Área de entrada según modo
            if (_inputMode == _InputMode.voice) ...[
              _buildVoiceInput(voiceState),
            ] else ...[
              _buildManualInput(),
            ],

            // Lista de ejercicios añadidos
            if (_exercises.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildExercisesList(),
            ],

            // Notas de sesión
            const SizedBox(height: 20),
            _buildSessionNotes(),

            // Toggle para incluir en estadísticas
            const SizedBox(height: 16),
            _buildStatsToggle(),

            const SizedBox(height: 100), // Espacio para scroll
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neonCyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.neonCyan.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesión Externa',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonCyan,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registra entrenamientos hechos fuera de la app. '
                  'Se marcarán como "externos" en tu historial.',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white54, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha de la sesión',
                    style: GoogleFonts.montserrat(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(_selectedDate),
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            icon: Icons.mic,
            label: 'Voz',
            isSelected: _inputMode == _InputMode.voice,
            onTap: () => setState(() => _inputMode = _InputMode.voice),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeButton(
            icon: Icons.edit,
            label: 'Manual',
            isSelected: _inputMode == _InputMode.manual,
            onTap: () => setState(() => _inputMode = _InputMode.manual),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceInput(VoiceInputState voiceState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Instrucciones de voz
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDeep,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dicta los ejercicios de tu sesión:',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _buildExampleText('"Press banca 4 series de 8 con 80 kilos"'),
                _buildExampleText('"Sentadillas 5x5 a 100 kilos"'),
                _buildExampleText('"Remo 3x12, nota: agarre supino"'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botón de micrófono
          VoiceMicButton(onTap: _onVoiceTap, size: 72),
          const SizedBox(height: 12),

          // Estado de voz
          _buildVoiceStatus(voiceState),

          // Preview de ejercicios parseados
          if (voiceState.hasResults) ...[
            const SizedBox(height: 16),
            _buildParsedExercisesPreview(voiceState.parsedExercises),
          ],

          // Estado no entendido
          if (voiceState.notUnderstood) ...[
            const SizedBox(height: 16),
            _buildNotUnderstoodState(voiceState.notUnderstoodMessage),
          ],
        ],
      ),
    );
  }

  Widget _buildExampleText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: Colors.white38,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildVoiceStatus(VoiceInputState state) {
    if (state.isListening) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ESCUCHANDO...',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: AppColors.neonPrimary,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    if (state.isProcessing) {
      return Text(
        'Procesando...',
        style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 14),
      );
    }

    return Text(
      'Mantén pulsado para hablar',
      style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 13),
    );
  }

  Widget _buildParsedExercisesPreview(List<VoiceParsedExercise> exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ejercicios detectados:',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ...exercises.map(
          (e) => _ParsedExerciseTile(
            exercise: e,
            onAdd: () => _addExerciseFromVoice(e),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _addAllExercisesFromVoice(exercises),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'AÑADIR ${exercises.length} EJERCICIO${exercises.length == 1 ? '' : 'S'}',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotUnderstoodState(String? message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? 'No entendido. Intenta de nuevo.',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'Añade ejercicios manualmente',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddExerciseDialog,
              icon: const Icon(Icons.add),
              label: const Text('AÑADIR EJERCICIO'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neonCyan,
                side: const BorderSide(color: AppColors.neonCyan),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fitness_center, color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(
              'EJERCICIOS (${_exercises.length})',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._exercises.asMap().entries.map(
          (entry) => _ExerciseTile(
            exercise: entry.value,
            onEdit: () => _editExercise(entry.key),
            onDelete: () => _deleteExercise(entry.key),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionNotes() {
    return TextField(
      maxLines: 3,
      onChanged: (value) => _sessionNotes = value,
      style: GoogleFonts.montserrat(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Notas de la sesión (opcional)',
        labelStyle: GoogleFonts.montserrat(color: Colors.white54),
        hintText: 'Cómo te sentiste, condiciones, etc.',
        hintStyle: GoogleFonts.montserrat(color: Colors.white30),
        filled: true,
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonCyan),
        ),
      ),
    );
  }

  Widget _buildStatsToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incluir en estadísticas',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Si activas esto, los pesos contarán para tu progresión',
                  style: GoogleFonts.montserrat(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _includeInStats,
            onChanged: (value) => setState(() => _includeInStats = value),
            activeThumbColor: AppColors.neonCyan,
          ),
        ],
      ),
    );
  }

  // --- Actions ---

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonCyan,
              surface: AppColors.bgElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _onVoiceTap() async {
    final notifier = ref.read(voiceInputProvider.notifier);
    final state = ref.read(voiceInputProvider);

    if (state.notUnderstood) {
      notifier.clearNotUnderstood();
    }

    if (state.isListening) {
      await notifier.stopListening();
    } else {
      await notifier.startListening();
    }
  }

  void _addExerciseFromVoice(VoiceParsedExercise parsed) {
    if (!parsed.isValid) return;

    setState(() {
      _exercises.add(
        _ExternalExercise(
          name: parsed.matchedName!,
          sets: parsed.series,
          reps: parsed.repsRange,
          weight: parsed.weight,
          notes: parsed.notes,
        ),
      );
    });

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${parsed.matchedName} añadido'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addAllExercisesFromVoice(List<VoiceParsedExercise> exercises) {
    final valid = exercises.where((e) => e.isValid).toList();
    if (valid.isEmpty) return;

    setState(() {
      for (final e in valid) {
        _exercises.add(
          _ExternalExercise(
            name: e.matchedName!,
            sets: e.series,
            reps: e.repsRange,
            weight: e.weight,
            notes: e.notes,
          ),
        );
      }
    });

    ref.read(voiceInputProvider.notifier).clearResults();

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${valid.length} ejercicios añadidos'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddExerciseDialog({int? editIndex}) {
    final nameController = TextEditingController();
    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final weightController = TextEditingController();
    final notesController = TextEditingController();

    if (editIndex != null) {
      final ex = _exercises[editIndex];
      nameController.text = ex.name;
      setsController.text = ex.sets.toString();
      repsController.text = ex.reps;
      weightController.text = ex.weight?.toString() ?? '';
      notesController.text = ex.notes ?? '';
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bgElevated,
          title: Text(
            editIndex == null ? 'Añadir ejercicio' : 'Editar ejercicio',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del ejercicio',
                    labelStyle: GoogleFonts.montserrat(color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.bgDeep,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: setsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Series',
                          labelStyle: GoogleFonts.montserrat(
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: AppColors.bgDeep,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        decoration: InputDecoration(
                          labelText: 'Reps (ej. 8 o 6-8)',
                          labelStyle: GoogleFonts.montserrat(
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: AppColors.bgDeep,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Peso (kg) - opcional',
                    labelStyle: GoogleFonts.montserrat(color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.bgDeep,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notas - opcional',
                    labelStyle: GoogleFonts.montserrat(color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.bgDeep,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.montserrat(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final sets = int.tryParse(setsController.text.trim()) ?? 0;
                final reps = repsController.text.trim();
                final weight = double.tryParse(weightController.text.trim());
                final notes = notesController.text.trim();

                if (name.isEmpty || sets <= 0 || reps.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rellena nombre, series y reps'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                setState(() {
                  final newExercise = _ExternalExercise(
                    name: name,
                    sets: sets,
                    reps: reps,
                    weight: weight,
                    notes: notes.isEmpty ? null : notes,
                  );

                  if (editIndex == null) {
                    _exercises.add(newExercise);
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name añadido'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  } else {
                    _exercises[editIndex] = newExercise;
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name actualizado'),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                });

                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: Text(
                editIndex == null ? 'AÑADIR' : 'GUARDAR',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editExercise(int index) {
    _showAddExerciseDialog(editIndex: index);
  }

  void _deleteExercise(int index) {
    setState(() => _exercises.removeAt(index));
    HapticFeedback.lightImpact();
  }

  /// 🎯 FIX #5: Implementación completa del guardado de sesiones externas
  Future<void> _onSaveSession() async {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos un ejercicio'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Convertir ejercicios locales a ExternalExercise
    final externalExercises = _exercises
        .map(
          (e) => ExternalExercise(
            name: e.name,
            series: e.sets,
            repsRange: e.reps,
            weight: e.weight,
            notes: e.notes,
            confidence: 1.0, // Usuario lo añadió manualmente
            rawInput:
                '${e.name} ${e.sets}x${e.reps}${e.weight != null ? ' ${e.weight}kg' : ''}',
          ),
        )
        .toList();

    // Crear la sesión externa
    final externalSession = ExternalSession.create(
      sessionDate: _selectedDate,
      exercises: externalExercises,
      notes: _sessionNotes,
      includeInProgression: _includeInStats,
      source: _inputMode == _InputMode.voice
          ? ExternalSessionSource.voice
          : ExternalSessionSource.manual,
    );

    // Convertir a Sesion y guardar en el repositorio
    final sesion = externalSession.toSesion();

    try {
      final repository = ref.read(trainingRepositoryProvider);
      await repository.saveSesion(sesion);

      HapticFeedback.heavyImpact();

      if (!mounted) return;

      // Mostrar confirmación de éxito
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgElevated,
          title: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Sesión guardada!',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha: ${_formatDate(_selectedDate)}',
                style: GoogleFonts.montserrat(color: Colors.white70),
              ),
              Text(
                'Ejercicios: ${_exercises.length}',
                style: GoogleFonts.montserrat(color: Colors.white70),
              ),
              Text(
                'En estadísticas: ${_includeInStats ? "Sí" : "No"}',
                style: GoogleFonts.montserrat(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.upload_file,
                      color: AppColors.neonCyan,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Guardada en tu historial como sesión externa',
                        style: GoogleFonts.montserrat(
                          color: AppColors.neonCyan,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                'ACEPTAR',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hoy';
    if (dateOnly == yesterday) return 'Ayer';

    return DateFormat('EEEE, d MMMM yyyy', 'es').format(date);
  }
}

// --- Private Models ---

enum _InputMode { voice, manual }

class _ExternalExercise {
  final String name;
  final int sets;
  final String reps;
  final double? weight;
  final String? notes;

  _ExternalExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    this.notes,
  });
}

// --- Private Widgets ---

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonCyan.withValues(alpha: 0.15)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.neonCyan.withValues(alpha: 0.5)
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.neonCyan : Colors.white54,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.neonCyan : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParsedExerciseTile extends StatelessWidget {
  final VoiceParsedExercise exercise;
  final VoidCallback onAdd;

  const _ParsedExerciseTile({required this.exercise, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isValid = exercise.isValid;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.bgDeep
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid
              ? AppColors.border
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? exercise.matchedName! : 'No encontrado',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: isValid ? Colors.white : Colors.orange,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.series}x${exercise.repsRange}${exercise.weight != null ? ' • ${exercise.weight}kg' : ''}',
                  style: GoogleFonts.montserrat(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isValid)
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle, color: AppColors.success),
              tooltip: 'Añadir',
            ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final _ExternalExercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseTile({
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.sets} series × ${exercise.reps} reps${exercise.weight != null ? ' • ${exercise.weight!.toStringAsFixed(1)} kg' : ''}',
                  style: GoogleFonts.montserrat(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Nota: ${exercise.notes}',
                    style: GoogleFonts.montserrat(
                      color: Colors.white38,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Colors.white38, size: 20),
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}
