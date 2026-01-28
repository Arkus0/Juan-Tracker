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

  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _ejercicioCtl.dispose();
    _pesoCtl.dispose();
    _repsCtl.dispose();
    _rpeCtl.dispose();
    _duracionCtl.dispose();
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

  void _save() {
    final ejercicioNombre = _ejercicioCtl.text.trim();
    final peso = double.tryParse(_pesoCtl.text) ?? 0.0;
    final reps = int.tryParse(_repsCtl.text) ?? 0;
    final rpe = int.tryParse(_rpeCtl.text);
    final minutos = int.tryParse(_duracionCtl.text) ?? 0;

    if (peso < 0 || reps < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Peso y reps deben ser positivos')),
      );
      return;
    }

    final logs = <SerieLog>[];
    if (ejercicioNombre.isNotEmpty && reps > 0) {
      logs.add(SerieLog(peso: peso, reps: reps, rpe: rpe));
    }

    final ejercicios = <Ejercicio>[];
    if (logs.isNotEmpty) {
      ejercicios.add(
        Ejercicio(id: ejercicioNombre, nombre: ejercicioNombre, logs: logs),
      );
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
          TextField(
            controller: _duracionCtl,
            decoration: const InputDecoration(labelText: 'Duracion (min)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
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
              Expanded(
                child: TextField(
                  controller: _rpeCtl,
                  decoration: const InputDecoration(labelText: 'RPE'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
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
                  onPressed: _save,
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
