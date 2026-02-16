import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/market_providers.dart';
import '../services/food_database_loader.dart';

/// Pantalla de carga inicial de la base de datos de alimentos
/// 
/// Se muestra en el primer lanzamiento de la app mientras se cargan
/// los productos desde el asset comprimido según el mercado seleccionado.
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
  int _loadedCount = 0;
  String _status = 'Preparando base de datos...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAndLoadDatabase();
  }

  Future<void> _checkAndLoadDatabase() async {
    final market = ref.read(selectedMarketProvider);
    
    if (market == null) {
      setState(() {
        _error = 'No se ha seleccionado un mercado';
      });
      return;
    }

    try {
      final loader = ref.read(foodDatabaseLoaderProvider);
      
      // Verificar si ya está cargada
      final isLoaded = await loader.isDatabaseLoaded(market);
      
      if (isLoaded) {
        widget.onComplete();
        return;
      }

      setState(() {
        _status = 'Cargando productos de ${market.displayName}...';
        _progress = 0.0;
      });

      // Cargar la base de datos
      final loadedCount = await loader.loadDatabase(
        market: market,
        onProgress: (progress, loaded) {
          setState(() {
            _progress = progress;
            _loadedCount = loaded;
            _status = 'Cargando ${market.displayName}... ${(progress * 100).toStringAsFixed(0)}%';
          });
        },
      );

      setState(() {
        _status = '¡Listo! $loadedCount productos cargados';
        _progress = 1.0;
      });

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
    final market = ref.watch(selectedMarketProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Flag del mercado
              Text(
                market?.flag ?? '🌍',
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 32),
              
              Text(
                'Configurando tu biblioteca',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                'Estamos preparando los productos de ${market?.displayName ?? "tu región"}.\nSolo es necesario una vez.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
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
                
                Text(
                  _status,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                
                if (_loadedCount > 0 && _progress < 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '$_loadedCount productos importados',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
              
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
