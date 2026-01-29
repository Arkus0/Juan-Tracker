import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/providers/database_provider.dart';
import '../../../diet/models/models.dart';
import '../../../diet/providers/external_food_search_provider.dart';
import 'add_entry_dialog.dart';

/// Pantalla de búsqueda de alimentos externos (Open Food Facts)
/// 
/// Funcionalidades:
/// - Búsqueda por texto con debounce
/// - Escaneo de código de barras
/// - Búsqueda por voz
/// - Modo offline con cache local
/// - Guardar alimentos a biblioteca local
class ExternalFoodSearchScreen extends ConsumerStatefulWidget {
  final bool returnFoodOnSelect; // Si true, retorna el FoodModel en vez de ir al diario

  const ExternalFoodSearchScreen({
    super.key,
    this.returnFoodOnSelect = false,
  });

  @override
  ConsumerState<ExternalFoodSearchScreen> createState() => _ExternalFoodSearchScreenState();
}

class _ExternalFoodSearchScreenState extends ConsumerState<ExternalFoodSearchScreen> {
  late final TextEditingController _searchController;
  final _speech = SpeechToText();
  bool _isListening = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initSpeech();
    
    // Cargar sugerencias offline al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(externalFoodSearchProvider.notifier).loadOfflineSuggestions();
    });
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Debounce para no spamear la API
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        ref.read(externalFoodSearchProvider.notifier).search(value);
      }
    });
  }

  /// Inicia escucha de voz
  Future<void> _startVoiceSearch() async {
    if (!_speech.isAvailable) {
      _showError('Reconocimiento de voz no disponible');
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        _searchController.text = text;
        _onSearchChanged(text);
        
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'es_ES',
    );
  }

  /// Detiene escucha de voz
  void _stopVoiceSearch() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  /// Escanea código de barras
  Future<void> _scanBarcode() async {
    // Mostrar un dialog para entrada manual de barcode
    final barcode = await showDialog<String>(
      context: context,
      builder: (ctx) => const _BarcodeInputDialog(),
    );

    if (barcode != null && barcode.isNotEmpty && mounted) {
      final notifier = ref.read(externalFoodSearchProvider.notifier);
      
      // Mostrar loading
      notifier.setLoading(barcode);

      final result = await notifier.searchByBarcode(barcode);
      
      if (result != null && mounted) {
        _selectProduct(result);
      } else if (mounted) {
        _showError('Producto no encontrado');
        notifier.clear();
      }
    }
  }

  /// Selecciona un producto para guardar/usar
  Future<void> _selectProduct(OpenFoodFactsResult result) async {
    // Verificar si ya existe en biblioteca local
    final foodRepo = ref.read(foodRepositoryProvider);
    final existing = await foodRepo.findByBarcode(result.code);

    if (existing != null) {
      // Ya existe, usar directamente
      if (mounted) {
        await _useFood(existing);
      }
      return;
    }

    // Mostrar dialog de confirmación para guardar
    if (!mounted) return;
    
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SaveFoodDialog(result: result),
    );

    if (shouldSave == true && mounted) {
      // Guardar en biblioteca
      final food = await ref.read(externalFoodSearchProvider.notifier)
          .saveToLocalLibrary(result);
      
      // Insertar en repositorio
      await foodRepo.insert(food);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${food.name}" guardado en tu biblioteca'),
            duration: const Duration(seconds: 2),
          ),
        );
        await _useFood(food);
      }
    }
  }

  /// Usa el alimento (navegar a diario o retornar)
  Future<void> _useFood(FoodModel food) async {
    if (widget.returnFoodOnSelect) {
      if (mounted) {
        Navigator.of(context).pop(food);
      }
      return;
    }

    // Navegar al dialog de añadir entrada
    if (!mounted) return;
    
    final result = await showDialog<DiaryEntryModel>(
      context: context,
      builder: (ctx) => AddEntryDialog(food: food),
    );

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(externalFoodSearchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Alimentos'),
        centerTitle: true,
        actions: [
          // Indicador de modo offline
          if (!searchState.isOnline)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.offline_bolt,
                color: theme.colorScheme.tertiary,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda con acciones
          _SearchBar(
            controller: _searchController,
            isListening: _isListening,
            onChanged: _onSearchChanged,
            onVoicePressed: _isListening ? _stopVoiceSearch : _startVoiceSearch,
            onBarcodePressed: _scanBarcode,
            onClear: () {
              _searchController.clear();
              ref.read(externalFoodSearchProvider.notifier).clear();
            },
          ),

          // Indicador de estado
          _StatusBar(state: searchState),

          const Divider(height: 1),

          // Contenido principal
          Expanded(
            child: _buildContent(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ExternalSearchState state) {
    switch (state.status) {
      case ExternalSearchStatus.idle:
        return _IdleState(
          recentSearches: state.recentSearches,
          offlineSuggestions: state.offlineSuggestions,
          onRecentTap: (q) {
            _searchController.text = q;
            ref.read(externalFoodSearchProvider.notifier).selectRecentSearch(q);
          },
          onSuggestionTap: _selectProduct,
        );

      case ExternalSearchStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case ExternalSearchStatus.loadingMore:
        return _ResultsList(
          results: state.results,
          isLoadingMore: true,
          onProductTap: _selectProduct,
          onLoadMore: () {},
        );

      case ExternalSearchStatus.success:
        return _ResultsList(
          results: state.results,
          hasMore: state.hasMore,
          onProductTap: _selectProduct,
          onLoadMore: () => ref.read(externalFoodSearchProvider.notifier).loadMore(),
        );

      case ExternalSearchStatus.offline:
        return _OfflineResults(
          results: state.results,
          errorMessage: state.errorMessage,
          onProductTap: _selectProduct,
        );

      case ExternalSearchStatus.empty:
        return const _EmptyState();

      case ExternalSearchStatus.error:
        return _ErrorState(
          message: state.errorMessage ?? 'Error desconocido',
          onRetry: () => ref.read(externalFoodSearchProvider.notifier)
              .search(_searchController.text),
        );
    }
  }
}

// ============================================================================
// WIDGETS AUXILIARES
// ============================================================================

/// Barra de búsqueda con acciones
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final ValueChanged<String> onChanged;
  final VoidCallback onVoicePressed;
  final VoidCallback onBarcodePressed;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.isListening,
    required this.onChanged,
    required this.onVoicePressed,
    required this.onBarcodePressed,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Buscar en Open Food Facts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Micrófono
                  IconButton(
                    icon: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      color: isListening ? theme.colorScheme.primary : null,
                    ),
                    onPressed: onVoicePressed,
                  ),
                  // Barcode
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: onBarcodePressed,
                  ),
                  // Clear
                  if (value.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withAlpha((0.3 * 255).round()),
            ),
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}

/// Indicador de estado de búsqueda
class _StatusBar extends StatelessWidget {
  final ExternalSearchState state;

  const _StatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Buscando "${state.query}"...',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (state.isOfflineMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: theme.colorScheme.tertiaryContainer.withAlpha((0.3 * 255).round()),
        child: Row(
          children: [
            Icon(
              Icons.offline_bolt,
              size: 16,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.errorMessage ?? 'Modo offline - Resultados guardados',
                style: TextStyle(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.isSuccess && state.results.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          '${state.results.length} resultados',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Estado inicial con búsquedas recientes y sugerencias
class _IdleState extends StatelessWidget {
  final List<String> recentSearches;
  final List<OpenFoodFactsResult> offlineSuggestions;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<OpenFoodFactsResult> onSuggestionTap;

  const _IdleState({
    required this.recentSearches,
    required this.offlineSuggestions,
    required this.onRecentTap,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Búsquedas recientes
        if (recentSearches.isNotEmpty) ...[
          _SectionTitle(
            title: 'Búsquedas recientes',
            onClear: () {
              // Llamar a limpiar historial
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: recentSearches.map((q) => ActionChip(
              label: Text(q),
              onPressed: () => onRecentTap(q),
              avatar: const Icon(Icons.history, size: 18),
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Sugerencias offline
        if (offlineSuggestions.isNotEmpty) ...[
          const _SectionTitle(title: 'Disponibles offline'),
          const SizedBox(height: 8),
          ...offlineSuggestions.take(10).map((r) => _ProductListTile(
            result: r,
            onTap: () => onSuggestionTap(r),
          )),
        ],

        // Estado vacío
        if (recentSearches.isEmpty && offlineSuggestions.isEmpty)
          const _EmptyInitialState(),
      ],
    );
  }
}

/// Título de sección
class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onClear;

  const _SectionTitle({required this.title, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: const Text('Limpiar'),
          ),
      ],
    );
  }
}

/// Lista de resultados
class _ResultsList extends StatelessWidget {
  final List<OpenFoodFactsResult> results;
  final bool hasMore;
  final bool isLoadingMore;
  final ValueChanged<OpenFoodFactsResult> onProductTap;
  final VoidCallback onLoadMore;

  const _ResultsList({
    required this.results,
    required this.onProductTap,
    required this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: results.length + (hasMore || isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == results.length) {
          if (isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: onLoadMore,
              child: const Text('Cargar más'),
            ),
          );
        }

        return _ProductListTile(
          result: results[index],
          onTap: () => onProductTap(results[index]),
        );
      },
    );
  }
}

/// Tile de producto
class _ProductListTile extends StatelessWidget {
  final OpenFoodFactsResult result;
  final VoidCallback onTap;

  const _ProductListTile({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: result.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  result.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Icon(
                    Icons.fastfood,
                    color: theme.colorScheme.primary,
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
              )
            : Icon(Icons.fastfood, color: theme.colorScheme.primary),
      ),
      title: Text(
        result.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.brand != null)
            Text(
              result.brand!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          if (result.portionName != null)
            Text(
              'Porción: ${result.portionName}',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${result.kcalPer100g.round()}',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            'kcal/100g',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Resultados en modo offline
class _OfflineResults extends StatelessWidget {
  final List<OpenFoodFactsResult> results;
  final String? errorMessage;
  final ValueChanged<OpenFoodFactsResult> onProductTap;

  const _OfflineResults({
    required this.results,
    this.errorMessage,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return _ErrorState(
        message: errorMessage ?? 'Sin conexión y no hay datos guardados',
        icon: Icons.offline_bolt,
      );
    }

    return _ResultsList(
      results: results,
      onProductTap: onProductTap,
      onLoadMore: () {},
    );
  }
}

/// Estado vacío
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.4 * 255).round()),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron alimentos',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prueba con otros términos o escanea el código de barras',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Estado inicial vacío
class _EmptyInitialState extends StatelessWidget {
  const _EmptyInitialState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.4 * 255).round()),
          ),
          const SizedBox(height: 16),
          Text(
            'Busca alimentos en Open Food Facts',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Más de 3 millones de productos de todo el mundo',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Estado de error
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const _ErrorState({
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.error.withAlpha((0.5 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DIÁLOGOS
// ============================================================================

/// Dialog para guardar alimento en biblioteca
class _SaveFoodDialog extends StatelessWidget {
  final OpenFoodFactsResult result;

  const _SaveFoodDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Guardar alimento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"${result.name}"'),
          if (result.brand != null)
            Text(
              result.brand!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            '${result.kcalPer100g.round()} kcal / 100g',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Se guardará en tu biblioteca local para uso offline.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Guardar y usar'),
        ),
      ],
    );
  }
}

/// Dialog para entrada manual de código de barras
class _BarcodeInputDialog extends StatefulWidget {
  const _BarcodeInputDialog();

  @override
  State<_BarcodeInputDialog> createState() => _BarcodeInputDialogState();
}

class _BarcodeInputDialogState extends State<_BarcodeInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Código de barras'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'Ej: 8410000000000',
          labelText: 'EAN-13',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final code = _controller.text.trim();
            if (code.isNotEmpty) {
              Navigator.of(context).pop(code);
            }
          },
          child: const Text('Buscar'),
        ),
      ],
    );
  }
}
