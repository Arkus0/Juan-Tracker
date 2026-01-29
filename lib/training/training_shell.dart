import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/main_screen.dart';
import 'services/alternativas_service.dart';
import 'services/exercise_library_service.dart';
import 'services/image_precache_service.dart';
import 'utils/design_system.dart';

class TrainingShell extends ConsumerStatefulWidget {
  const TrainingShell({super.key});

  @override
  ConsumerState<TrainingShell> createState() => _TrainingShellState();
}

class _TrainingShellState extends ConsumerState<TrainingShell> {
  bool _ready = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await ExerciseLibraryService.instance.init();
      await AlternativasService.instance.initialize();
      
      // MD-003: Precache de imágenes de ejercicios en segundo plano
      // Se ejecuta después de cargar la biblioteca para mejorar UX
      if (mounted) {
        // No esperamos el precache para mostrar la UI rápidamente
        context.precacheTopExerciseImages().then((_) {
          debugPrint('TrainingShell: Exercise images precached');
        }).catchError((e) {
          debugPrint('TrainingShell: Precache error (non-critical): $e');
        });
      }
      
      if (mounted) {
        setState(() {
          _ready = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          if (_initError != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('ENTRENAMIENTO')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      const Text('Error al cargar biblioteca de ejercicios'),
                      const SizedBox(height: 8),
                      Text(_initError.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _initError = null;
                            _ready = false;
                          });
                          _boot();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (!_ready) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return const MainScreen();
        },
      ),
    );
  }
}
