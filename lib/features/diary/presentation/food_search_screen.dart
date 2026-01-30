import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';
import '../../../diet/providers/external_food_search_provider.dart';
import '../../../diet/services/food_label_ocr_service.dart';
import '../../../diet/services/food_label_parser_service.dart';
import 'add_entry_dialog.dart';
import 'barcode_scanner_screen.dart';
import 'external_food_search_screen.dart';

/// Pantalla de búsqueda unificada de alimentos (Local + Open Food Facts)
/// 
/// Funcionalidades:
/// - Búsqueda en biblioteca local con debounce
/// - Búsqueda en Open Food Facts integrada
/// - Smart Import: Voz, Código de barras, OCR
/// - Crear nuevo alimento si no existe
class FoodSearchScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const FoodSearchScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  bool _isExpanded = false;
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodSearchQueryProvider.notifier).query = '';
      ref.read(externalFoodSearchProvider.notifier).clear();
    });
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        setState(() => _isListening = false);
        AppSnackbar.show(context, message: 'Error: ${error.errorMsg}');
      },
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _speech.stop();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;
    final searchQuery = ref.watch(foodSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Entrada' : 'Añadir Alimento'),
        centerTitle: true,
        actions: [
          // Botón de búsqueda por voz
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _startVoiceSearch,
            tooltip: 'Búsqueda por voz',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda mejorada
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar alimento...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(foodSearchQueryProvider.notifier).query = '';
                          ref.read(externalFoodSearchProvider.notifier).clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
              ),
              onChanged: (value) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(_debounceDuration, () {
                  ref.read(foodSearchQueryProvider.notifier).query = value;
                  if (value.trim().isNotEmpty) {
                    ref.read(externalFoodSearchProvider.notifier).search(value);
                  }
                });
              },
            ),
          ),

          // Opciones rápidas (Quick Add + Buscar Externo)
          _QuickActionsRow(
            onQuickAdd: () => _showQuickAddDialog(context),
            onExternalSearch: () => _showExternalSearch(context),
          ),

          const Divider(height: 1),

          // Lista de resultados unificada
          Expanded(
            child: _UnifiedSearchResults(
              searchQuery: searchQuery,
              onSelectFood: (food) => _selectFood(context, food),
              onCreateNew: () => _showCreateNewDialog(context, searchQuery),
            ),
          ),
        ],
      ),
      // FAB Expandible para Smart Import
      floatingActionButton: _ExpandableSmartImportFAB(
        isExpanded: _isExpanded,
        isListening: _isListening,
        onToggle: () => setState(() => _isExpanded = !_isExpanded),
        onBarcodeScan: () => _scanBarcode(context),
        onOcrScan: () => _scanFoodLabel(context),
        onVoiceSearch: () => _startVoiceSearch(),
        onQuickAdd: () => _showQuickAddDialog(context),
      ),
    );
  }

  Future<void> _selectFood(BuildContext context, FoodModel food) async {
    ref.read(selectedFoodProvider.notifier).selected = food;
    
    final navigator = Navigator.of(context);
    final result = await showDialog<DiaryEntryModel>(
      context: context,
      builder: (ctx) => AddEntryDialog(food: food),
    );

    if (result != null && mounted) {
      await _saveEntry(result);
      if (mounted) navigator.pop();
    }
  }

  Future<void> _showQuickAddDialog(BuildContext context) async {
    final navigator = Navigator.of(context);
    final result = await showDialog<DiaryEntryModel>(
      context: context,
      builder: (ctx) => const QuickAddDialog(),
    );

    if (result != null && mounted) {
      await _saveEntry(result);
      if (mounted) navigator.pop();
    }
  }

  Future<void> _showCreateNewDialog(BuildContext context, String initialName) async {
    final food = await showDialog<FoodModel>(
      context: context,
      builder: (ctx) => _CreateFoodDialog(initialName: initialName),
    );

    if (food != null && mounted) {
      // Guardar en biblioteca
      await ref.read(foodRepositoryProvider).insert(food);
      
      if (!context.mounted) return;
      
      // Seleccionar para añadir al diario
      await _selectFood(context, food);
    }
  }

  Future<void> _saveEntry(DiaryEntryModel entry) async {
    final repo = ref.read(diaryRepositoryProvider);
    final existingEntry = ref.read(editingEntryProvider);

    if (existingEntry != null) {
      await repo.update(entry);
    } else {
      await repo.insert(entry);
    }
  }

  Future<void> _showExternalSearch(BuildContext context) async {
    final navigator = Navigator.of(context);
    final result = await navigator.push<DiaryEntryModel>(
      MaterialPageRoute(
        builder: (ctx) => const ExternalFoodSearchScreen(),
      ),
    );

    if (result != null && mounted) {
      await _saveEntry(result);
      if (mounted) navigator.pop();
    }
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode != null && mounted) {
      ref.read(externalFoodSearchProvider.notifier).searchByBarcode(barcode);
    }
  }

  Future<void> _scanFoodLabel(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Escanear etiqueta'),
        content: const Text('¿Desde dónde quieres escanear?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.camera_alt), SizedBox(width: 8), Text('Cámara')],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.photo_library), SizedBox(width: 8), Text('Galería')],
            ),
          ),
        ],
      ),
    );

    if (source == null || !mounted) return;

    try {
      final scanResult = await FoodLabelOcrService.instance.scanLabel(source);
      
      if (!mounted) return;
      
      if (!scanResult.hasText) {
        if (context.mounted) {
          AppSnackbar.show(context, message: 'No se pudo leer texto de la imagen');
        }
        return;
      }

      // Parsear la etiqueta automáticamente
      final parser = FoodLabelParserService.instance;
      final parsed = parser.parse(scanResult.fullText);
      
      // Convertir a por 100g si es necesario
      final per100g = parsed.isPerServing && parsed.servingSize > 0
          ? parser.convertToPer100g(parsed)
          : parsed;

      if (!context.mounted) return;

      // Mostrar diálogo con valores extraídos
      final result = await showDialog<_OcrResult>(
        context: context,
        builder: (ctx) => _OcrResultDialog(
          rawText: scanResult.fullText,
          parsed: per100g,
        ),
      );

      if (result == null || !mounted) return;

      if (result.useForSearch) {
        // Usar texto para búsqueda
        _searchController.text = result.searchText;
        ref.read(foodSearchQueryProvider.notifier).query = result.searchText;
        ref.read(externalFoodSearchProvider.notifier).search(result.searchText);
      } else if (result.createFood && per100g.hasData) {
        // Crear alimento directamente
        final food = FoodModel(
          id: 'food_${DateTime.now().millisecondsSinceEpoch}',
          name: per100g.name.isNotEmpty ? per100g.name : 'Alimento escaneado',
          kcalPer100g: per100g.kcal,
          proteinPer100g: per100g.protein,
          carbsPer100g: per100g.carbs,
          fatPer100g: per100g.fat,
          portionName: per100g.servingSize > 0 ? 'porción' : null,
          portionGrams: per100g.servingSize > 0 ? per100g.servingSize : null,
          userCreated: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await ref.read(foodRepositoryProvider).insert(food);
        
        if (!context.mounted) return;
        
        await _selectFood(context, food);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(context, message: 'Error al escanear: $e');
      }
    }
  }

  Future<void> _startVoiceSearch() async {
    if (!_speechAvailable) {
      AppSnackbar.show(context, message: 'Reconocimiento de voz no disponible');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        _searchController.text = text;
        ref.read(foodSearchQueryProvider.notifier).query = text;
        
        if (text.trim().isNotEmpty) {
          ref.read(externalFoodSearchProvider.notifier).search(text);
        }
        
        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'es_ES',
    );
  }
}

/// Resultados de búsqueda unificada (Local + Open Food Facts)
class _UnifiedSearchResults extends ConsumerWidget {
  final String searchQuery;
  final void Function(FoodModel) onSelectFood;
  final VoidCallback onCreateNew;

  const _UnifiedSearchResults({
    required this.searchQuery,
    required this.onSelectFood,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localResults = ref.watch(foodSearchResultsProvider);
    final externalState = ref.watch(externalFoodSearchProvider);

    // Estado inicial - sin búsqueda
    if (searchQuery.isEmpty && externalState.results.isEmpty) {
      return const _InitialState();
    }

    return ListView(
      children: [
        // Resultados locales
        if (localResults.hasValue && localResults.value!.isNotEmpty) ...[
          _SectionHeader(
            title: 'Tus alimentos',
            count: localResults.value!.length,
          ),
          ...localResults.value!.map((food) => _FoodListTile(
            food: food,
            onTap: () => onSelectFood(food),
          )),
          const Divider(),
        ],

        // Resultados de Open Food Facts
        if (externalState.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (externalState.results.isNotEmpty) ...[
          _SectionHeader(
            title: 'Open Food Facts',
            count: externalState.results.length,
          ),
          ...externalState.results.map((result) => _OpenFoodResultTile(
            result: result,
            onTap: () => _selectOpenFoodResult(context, ref, result),
          )),
          if (externalState.hasMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => ref.read(externalFoodSearchProvider.notifier).loadMore(),
                child: const Text('Cargar más'),
              ),
            ),
          const Divider(),
        ] else if (searchQuery.isNotEmpty && !externalState.isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No se encontraron más resultados en Open Food Facts',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),

        // Opción para crear nuevo
        if (searchQuery.isNotEmpty)
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.green),
            ),
            title: Text('Crear "$searchQuery"'),
            subtitle: const Text('Añadir como nuevo alimento'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onCreateNew,
          ),
      ],
    );
  }

  Future<void> _selectOpenFoodResult(
    BuildContext context,
    WidgetRef ref,
    OpenFoodFactsResult result,
  ) async {
    // Verificar si ya existe en biblioteca local
    final foodRepo = ref.read(foodRepositoryProvider);
    final existing = await foodRepo.findByBarcode(result.code);

    if (existing != null) {
      onSelectFood(existing);
      return;
    }

    // Mostrar diálogo para guardar
    if (!context.mounted) return;
    
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(result.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.brand != null) Text('Marca: ${result.brand}'),
            Text('${result.kcalPer100g.round()} kcal / 100g'),
            const SizedBox(height: 16),
            const Text('¿Guardar este alimento en tu biblioteca?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No guardar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar y usar'),
          ),
        ],
      ),
    );

    if (shouldSave == true && context.mounted) {
      final food = await ref.read(externalFoodSearchProvider.notifier)
          .saveToLocalLibrary(result);
      await foodRepo.insert(food);
      
      if (context.mounted) {
        AppSnackbar.show(context, message: '"${food.name}" guardado');
        onSelectFood(food);
      }
    }
  }
}

/// Header de sección de resultados
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FAB expandible para Smart Import
class _ExpandableSmartImportFAB extends StatelessWidget {
  final bool isExpanded;
  final bool isListening;
  final VoidCallback onToggle;
  final VoidCallback onBarcodeScan;
  final VoidCallback onOcrScan;
  final VoidCallback onVoiceSearch;
  final VoidCallback onQuickAdd;

  const _ExpandableSmartImportFAB({
    required this.isExpanded,
    required this.isListening,
    required this.onToggle,
    required this.onBarcodeScan,
    required this.onOcrScan,
    required this.onVoiceSearch,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isExpanded) ...[
          _FabOption(
            icon: Icons.qr_code_scanner,
            label: 'Código de barras',
            onTap: onBarcodeScan,
          ),
          const SizedBox(height: 8),
          _FabOption(
            icon: Icons.document_scanner,
            label: 'Escanear etiqueta',
            onTap: onOcrScan,
          ),
          const SizedBox(height: 8),
          _FabOption(
            icon: isListening ? Icons.mic_off : Icons.mic,
            label: isListening ? 'Detener' : 'Voz',
            color: isListening ? Colors.red : null,
            onTap: onVoiceSearch,
          ),
          const SizedBox(height: 8),
          _FabOption(
            icon: Icons.bolt,
            label: 'Añadir rápido',
            onTap: onQuickAdd,
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: onToggle,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          child: AnimatedRotation(
            turns: isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Opción individual del FAB expandible
class _FabOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _FabOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withAlpha((0.2 * 255).round()),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: onTap,
          heroTag: label,
          backgroundColor: color?.withAlpha((0.2 * 255).round()) ?? colors.secondaryContainer,
          foregroundColor: color ?? colors.onSecondaryContainer,
          child: Icon(icon),
        ),
      ],
    );
  }
}

/// Fila de acciones rápidas
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onQuickAdd;
  final VoidCallback onExternalSearch;

  const _QuickActionsRow({
    required this.onQuickAdd,
    required this.onExternalSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.bolt,
              label: 'Rápido',
              color: Colors.orange,
              onTap: onQuickAdd,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionChip(
              icon: Icons.public,
              label: 'Online',
              color: Colors.blue,
              onTap: onExternalSearch,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de acción
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha((0.1 * 255).round()),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile de resultado de Open Food Facts
class _OpenFoodResultTile extends StatelessWidget {
  final OpenFoodFactsResult result;
  final VoidCallback onTap;

  const _OpenFoodResultTile({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: result.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                result.imageUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(theme),
              ),
            )
          : _buildPlaceholder(theme),
      title: Text(
        result.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.brand != null)
            Text(
              result.brand!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          Text(
            '${result.kcalPer100g.round()} kcal / 100g',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.fastfood, color: theme.colorScheme.primary),
    );
  }
}

// Widgets existentes (sin cambios)
class _FoodListTile extends StatelessWidget {
  final FoodModel food;
  final VoidCallback onTap;

  const _FoodListTile({
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.restaurant, color: theme.colorScheme.primary),
      ),
      title: Text(
        food.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        food.brand ?? '${food.kcalPer100g} kcal / 100g',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 13,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${food.kcalPer100g}',
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

class _InitialState extends StatelessWidget {
  const _InitialState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.4 * 255).round()),
          ),
          const SizedBox(height: 16),
          Text(
            'Busca alimentos',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus alimentos + Open Food Facts',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para crear nuevo alimento en la biblioteca
class _CreateFoodDialog extends StatefulWidget {
  final String initialName;

  const _CreateFoodDialog({required this.initialName});

  @override
  State<_CreateFoodDialog> createState() => _CreateFoodDialogState();
}

class _CreateFoodDialogState extends State<_CreateFoodDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _portionNameController;
  late final TextEditingController _portionGramsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _brandController = TextEditingController();
    _kcalController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _portionNameController = TextEditingController(text: 'porción');
    _portionGramsController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _portionNameController.dispose();
    _portionGramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Alimento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre (obligatorio)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej: Pollo a la plancha',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Marca (opcional)
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marca (opcional)',
                hintText: 'Ej: Hacendado',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Kcal por 100g (obligatorio)
            TextField(
              controller: _kcalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kcal / 100g *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Macros
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Proteína (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Grasa (g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Porción
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _portionNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre porción',
                      hintText: 'Ej: unidad, taza',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _portionGramsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Gramos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _createFood,
          child: const Text('Crear y Usar'),
        ),
      ],
    );
  }

  void _createFood() {
    final name = _nameController.text.trim();
    final kcal = int.tryParse(_kcalController.text) ?? 0;

    if (name.isEmpty || kcal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y kcal son obligatorios')),
      );
      return;
    }

    final food = FoodModel(
      id: 'food_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      brand: _brandController.text.trim().isEmpty 
          ? null 
          : _brandController.text.trim(),
      kcalPer100g: kcal,
      proteinPer100g: double.tryParse(_proteinController.text) ?? 0,
      carbsPer100g: double.tryParse(_carbsController.text) ?? 0,
      fatPer100g: double.tryParse(_fatController.text) ?? 0,
      portionName: _portionNameController.text.trim().isEmpty
          ? 'porción'
          : _portionNameController.text.trim(),
      portionGrams: double.tryParse(_portionGramsController.text) ?? 100.0,
      userCreated: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(food);
  }
}


/// Resultado del diálogo OCR
class _OcrResult {
  final bool useForSearch;
  final bool createFood;
  final String searchText;

  const _OcrResult({
    required this.useForSearch,
    required this.createFood,
    required this.searchText,
  });
}

/// Diálogo para mostrar resultados del OCR con valores parseados
class _OcrResultDialog extends StatefulWidget {
  final String rawText;
  final ParsedLabelResult parsed;

  const _OcrResultDialog({
    required this.rawText,
    required this.parsed,
  });

  @override
  State<_OcrResultDialog> createState() => _OcrResultDialogState();
}

class _OcrResultDialogState extends State<_OcrResultDialog> {
  late final TextEditingController _searchController;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.parsed.name);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = widget.parsed;
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Valores detectados'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parsed.hasData) ...[
              // Valores extraídos
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${parsed.kcal} kcal / 100g',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MacroItem(label: 'Proteína', value: '${parsed.protein.toStringAsFixed(1)}g'),
                        _MacroItem(label: 'Carbs', value: '${parsed.carbs.toStringAsFixed(1)}g'),
                        _MacroItem(label: 'Grasa', value: '${parsed.fat.toStringAsFixed(1)}g'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botón crear alimento
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_OcrResult(
                  useForSearch: false,
                  createFood: true,
                  searchText: '',
                )),
                icon: const Icon(Icons.add),
                label: const Text('Crear alimento con estos valores'),
              ),
              const SizedBox(height: 24),
            ],

            // Búsqueda manual
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(_OcrResult(
                useForSearch: true,
                createFood: false,
                searchText: _searchController.text,
              )),
              icon: const Icon(Icons.search),
              label: const Text('Buscar en biblioteca'),
            ),

            // Ver texto raw
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _showRawText = !_showRawText),
              icon: Icon(_showRawText ? Icons.visibility_off : Icons.visibility),
              label: Text(_showRawText ? 'Ocultar texto' : 'Ver texto detectado'),
            ),
            if (_showRawText) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.rawText,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final String value;

  const _MacroItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
