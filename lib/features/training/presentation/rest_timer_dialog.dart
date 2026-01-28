import 'dart:async';

import 'package:flutter/material.dart';

class RestTimerDialog extends StatefulWidget {
  final int seconds;

  const RestTimerDialog({super.key, required this.seconds});

  @override
  State<RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<RestTimerDialog> {
  Timer? _timer;
  late int _remaining;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 0) {
        timer.cancel();
        setState(() => _running = false);
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _resume() {
    setState(() => _running = true);
    _start();
  }

  void _reset() {
    setState(() {
      _remaining = widget.seconds;
      _running = true;
    });
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');

    return AlertDialog(
      title: const Text('Timer de descanso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$minutes:$seconds',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _running ? _pause : _resume,
                  child: Text(_running ? 'Pausar' : 'Reanudar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
