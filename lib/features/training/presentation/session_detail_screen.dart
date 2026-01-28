import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/training_sesion.dart';

class SessionDetailScreen extends StatelessWidget {
  final Sesion session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de sesion'),
        actions: [
          IconButton(
            onPressed: () => _export(context, asJson: false),
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Exportar texto',
          ),
          IconButton(
            onPressed: () => _export(context, asJson: true),
            icon: const Icon(Icons.data_object),
            tooltip: 'Exportar JSON',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _formatSessionTitle(session),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('Duracion: ${session.formattedDuration}'),
          Text('Series: ${session.completedSetsCount}'),
          Text('Volumen: ${session.totalVolume.toStringAsFixed(1)}'),
          const SizedBox(height: 16),
          for (final ejercicio in session.ejerciciosCompletados) ...[
            Text(
              ejercicio.nombre,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final log in ejercicio.logs)
              Text(
                '  ${log.peso} x ${log.reps}${log.rpe != null ? ' rpe ${log.rpe}' : ''}',
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, {required bool asJson}) async {
    final content = asJson
        ? const JsonEncoder.withIndent('  ').convert(session.toMap())
        : _exportSessionText(session);
    await _showExportDialog(
      context,
      title: asJson ? 'Exportar sesion (JSON)' : 'Exportar sesion (Texto)',
      content: content,
    );
  }
}

String _formatSessionTitle(Sesion sesion) {
  final date = sesion.fecha;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return 'Sesion $day/$month/${date.year}';
}

String _exportSessionText(Sesion sesion) {
  final buffer = StringBuffer();
  buffer.writeln(_formatSessionTitle(sesion));
  buffer.writeln('Duracion: ${sesion.formattedDuration}');
  buffer.writeln('Volumen total: ${sesion.totalVolume.toStringAsFixed(1)}');
  for (final ejercicio in sesion.ejerciciosCompletados) {
    buffer.writeln('- ${ejercicio.nombre}:');
    for (final log in ejercicio.logs) {
      final rpe = log.rpe != null ? ' rpe ${log.rpe}' : '';
      buffer.writeln('  ${log.peso} x ${log.reps}$rpe');
    }
  }
  return buffer.toString().trim();
}

Future<void> _showExportDialog(
  BuildContext context, {
  required String title,
  required String content,
}) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: SelectableText(content)),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: content));
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          child: const Text('Copiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
