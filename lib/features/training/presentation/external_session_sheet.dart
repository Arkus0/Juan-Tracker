import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/training_ejercicio.dart';
import '../../../core/models/training_serie_log.dart';
import '../../../core/models/training_sesion.dart';

Future<Sesion?> showExternalSessionSheet(BuildContext context) {
  return showModalBottomSheet<Sesion>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _ExternalSessionSheet(),
  );
}

class _ExternalSessionSheet extends StatefulWidget {
  const _ExternalSessionSheet();

  @override
  State<_ExternalSessionSheet> createState() => _ExternalSessionSheetState();
}

class _ExternalSessionSheetState extends State<_ExternalSessionSheet> {
  final _ejercicioCtl = TextEditingController();
  final _pesoCtl = TextEditingController();
  final _repsCtl = TextEditingController();
  final _rpeCtl = TextEditingController();
  final _duracionCtl = TextEditingController();
  final _textPasteCtl = TextEditingController();

  DateTime _fecha = DateTime.now();
  bool _showTextInput = false;
  final List<_ParsedExercise> _exercises = [];

  @override
  void dispose() {
    _ejercicioCtl.dispose();
    _pesoCtl.dispose();
    _repsCtl.dispose();
    _rpeCtl.dispose();
    _duracionCtl.dispose();
    _textPasteCtl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _fecha = DateTime(picked.year, picked.month, picked.day, _fecha.hour);
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      setState(() {
        _textPasteCtl.text = data!.text!;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _parseTextInput() {
    final text = _textPasteCtl.text.trim();
    if (text.isEmpty) return;

    final lines = text.split('\n');
    final parsedExercises = <_ParsedExercise>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Patrones comunes:
      // "Press banca 4x8 80kg"
      // "Sentadillas 3 series de 10 a 100 kg"
      // "Curl biceps 3x12-15 20kg"
      
      final result = _parseExerciseLine(trimmed);
      if (result != null) {
        parsedExercises.add(result);
      }
    }

    if (parsedExercises.isNotEmpty) {
      setState(() {
        _exercises.addAll(parsedExercises);
        _textPasteCtl.clear();
        _showTextInput = false;
      });
      HapticFeedback.mediumImpact();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron parsear ejercicios. Formato: Ejercicio 3x10 80kg')),
      );
    }
  }

  _ParsedExercise? _parseExerciseLine(String line) {
    // Patrón: nombre series x reps peso
    // Ejemplos:
    // Press banca 4x8 80kg
    // Sentadilla 3x10-12 100kg
    // Curl 3 x 8 20 kg
    
    try {
      // Remover caracteres comunes
      final cleanLine = line
          .replaceAll('kg', '')
          .replaceAll('KG', '')
          .replaceAll(' x ', 'x')
          .replaceAll(' X ', 'x')
          .replaceAll('×', 'x')
          .trim();

      // Buscar patrón: número x número (series x reps)
      final regex = RegExp(r'(\d+)\s*x\s*(\d+(?:-\d+)?)');
      final match = regex.firstMatch(cleanLine);
      
      if (match != null) {
        final series = int.parse(match.group(1)!);
        final reps = match.group(2)!;
        
        // Buscar peso (número al final o después de las reps)
        final afterMatch = cleanLine.substring(match.end).trim();
        double? weight;
        
        // Intentar encontrar un número después del patrón de series x reps
        final weightMatch = RegExp(r'\b(\d+(?:\.\d+)?)\b').firstMatch(afterMatch);
        if (weightMatch != null) {
          weight = double.tryParse(weightMatch.group(1)!);
        }

        // El nombre es todo antes del patrón de series x reps
        var name = cleanLine.substring(0, match.start).trim();
        // Limpiar caracteres sobrantes al final del nombre
        name = name.replaceAll(RegExp(r'[\s:]+$'), '');
        
        if (name.isNotEmpty) {
          return _ParsedExercise(
            name: name,
            series: series,
            reps: reps,
            weight: weight,
          );
        }
      }
    } catch (e) {
      // Ignorar errores de parsing
    }
    return null;
  }

  void _addManualExercise() {
    final name = _ejercicioCtl.text.trim();
    final peso = double.tryParse(_pesoCtl.text) ?? 0.0;
    final reps = int.tryParse(_repsCtl.text) ?? 0;

    if (name.isEmpty || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa nombre y reps')),
      );
      return;
    }

    setState(() {
      _exercises.add(_ParsedExercise(
        name: name,
        series: 1,
        reps: reps.toString(),
        weight: peso > 0 ? peso : null,
      ));
    });

    _ejercicioCtl.clear();
    _pesoCtl.clear();
    _repsCtl.clear();
    HapticFeedback.lightImpact();
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
    HapticFeedback.lightImpact();
  }

  void _save() {
    final minutos = int.tryParse(_duracionCtl.text) ?? 0;

    final ejercicios = <Ejercicio>[];
    final logs = <SerieLog>[];

    for (final ex in _exercises) {
      final exLogs = <SerieLog>[];
      final weight = ex.weight ?? 0.0;
      
      // Parsear reps (puede ser "8" o "8-12")
      int repsValue;
      if (ex.reps.contains('-')) {
        final parts = ex.reps.split('-');
        final min = int.tryParse(parts[0]) ?? 8;
        final max = int.tryParse(parts[1]) ?? 12;
        repsValue = ((min + max) / 2).round();
      } else {
        repsValue = int.tryParse(ex.reps) ?? 10;
      }

      for (int i = 0; i < ex.series; i++) {
        final log = SerieLog(peso: weight, reps: repsValue, completed: true);
        exLogs.add(log);
        logs.add(log);
      }

      ejercicios.add(Ejercicio(
        id: '${ex.name}_${DateTime.now().millisecondsSinceEpoch}',
        nombre: ex.name,
        logs: exLogs,
      ));
    }

    if (ejercicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un ejercicio')),
      );
      return;
    }

    final totalVolume = logs.fold<double>(0, (sum, l) => sum + l.volume);
    final sesion = Sesion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fecha: _fecha,
      durationSeconds: minutos > 0 ? minutos * 60 : null,
      totalVolume: totalVolume,
      ejerciciosCompletados: ejercicios,
    );

    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(sesion);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sesion externa', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          
          // Selector de fecha
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fecha: ${_fecha.day}/${_fecha.month}/${_fecha.year}',
                ),
              ),
              TextButton(onPressed: _pickDate, child: const Text('Cambiar')),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Duración
          TextField(
            controller: _duracionCtl,
            decoration: const InputDecoration(labelText: 'Duracion (min)'),
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 16),
          
          // Toggle entre entrada manual y pegar texto
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Manual'),
                  selected: !_showTextInput,
                  onSelected: (selected) {
                    if (selected) setState(() => _showTextInput = false);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Pegar texto'),
                  selected: _showTextInput,
                  onSelected: (selected) {
                    if (selected) setState(() => _showTextInput = true);
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contenido según modo seleccionado
          if (_showTextInput) ...[
            // Modo pegar texto
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste),
                    label: const Text('PEGAR DEL PORTAPAPELES'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textPasteCtl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ej:\nPress banca 4x8 80kg\nSentadilla 3x10 100kg\nCurl 3x12 20kg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _textPasteCtl.text.isEmpty ? null : _parseTextInput,
                icon: const Icon(Icons.playlist_add),
                label: const Text('PROCESAR TEXTO'),
              ),
            ),
          ] else ...[
            // Modo manual
            TextField(
              controller: _ejercicioCtl,
              decoration: const InputDecoration(labelText: 'Ejercicio'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pesoCtl,
                    decoration: const InputDecoration(labelText: 'Peso'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _repsCtl,
                    decoration: const InputDecoration(labelText: 'Reps'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addManualExercise,
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
          
          // Lista de ejercicios agregados
          if (_exercises.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Ejercicios (${_exercises.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _exercises.length,
                itemBuilder: (ctx, index) {
                  final ex = _exercises[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(ex.name),
                    subtitle: Text('${ex.series}x${ex.reps}${ex.weight != null ? ' @ ${ex.weight}kg' : ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _removeExercise(index),
                    ),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _exercises.isEmpty ? null : _save,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParsedExercise {
  final String name;
  final int series;
  final String reps;
  final double? weight;

  _ParsedExercise({
    required this.name,
    required this.series,
    required this.reps,
    this.weight,
  });
}
