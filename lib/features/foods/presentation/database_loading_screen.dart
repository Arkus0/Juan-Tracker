import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/food_database_loader.dart';

/// Pantalla de carga inicial de la base de datos de alimentos
/// 
/// Se muestra en el primer lanzamiento de la app mientras se cargan
/// los ~600,000 productos de Open Food Facts desde el asset comprimido.
class DatabaseLoadingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const DatabaseLoadingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<DatabaseLoadingScreen> createState() => _DatabaseLoadingScreenState();
}

class _DatabaseLoadingScreenState extends ConsumerState<DatabaseLoadingScreen> {
  double _progress = 0.0;
  String _status = 'Preparando base de datos...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAndLoadDatabase();
  }

  Future<void> _checkAndLoadDatabase() async {
    try {
      final loader = ref.read(foodDatabaseLoaderProvider);
      
      // Verificar si ya está cargada
      final isLoaded = await loader.isDatabaseLoaded();
      
      if (isLoaded) {
        // Ya está cargada, ir directamente a la app
        widget.onComplete();
        return;
      }

      // Necesita carga - mostrar progreso
      setState(() {
        _status = 'Descargando base de datos de alimentos...';
        _progress = 0.0;
      });

      // Cargar la base de datos con progreso
      final loadedCount = await loader.loadDatabase(
        onProgress: (progress, loaded) {
          setState(() {
            _progress = progress;
            _status = 'Cargando alimentos... ${(progress * 100).toStringAsFixed(0)}% ($loaded)';
          });
        },
      );

      setState(() {
        _status = '¡Base de datos lista! ($loadedCount alimentos)';
        _progress = 1.0;
      });

      // Pequeña pausa para mostrar el mensaje de completado
      await Future.delayed(const Duration(milliseconds: 500));
      
      widget.onComplete();
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icono
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),
              
              // Título
              Text(
                'Configuración inicial',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Subtítulo explicativo
              Text(
                'Estamos preparando la base de datos de alimentos.\nSolo es necesario una vez.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Barra de progreso
              if (_error == null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 12,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Texto de estado
                Text(
                  _status,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                // Estimación de tiempo
                if (_progress > 0 && _progress < 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Esto puede tardar unos minutos...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
              
              // Error
              if (_error != null) ...[
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _checkAndLoadDatabase,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onComplete,
                  child: const Text('Continuar sin base de datos'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
