import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';
import '../../../diet/providers/external_food_search_provider.dart';
import '../../../diet/services/food_label_ocr_service.dart';
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
  
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodSearchQueryProvider.notifier).query = '';
      ref.read(externalFoodSearchProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
    // TODO: Implementar diálogo de creación rápida
    AppSnackbar.show(context, message: 'Crear "$initialName" - Próximamente');
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
        AppSnackbar.show(context, message: 'No se pudo leer texto de la imagen');
        return;
      }

      if (!mounted) return;
      
      final searchText = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Texto detectado'),
          content: TextField(
            controller: TextEditingController(text: scanResult.fullText),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Edita el texto para buscar',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(scanResult.fullText),
              child: const Text('Buscar'),
            ),
          ],
        ),
      );

      if (searchText != null && searchText.isNotEmpty && mounted) {
        _searchController.text = searchText;
        ref.read(foodSearchQueryProvider.notifier).query = searchText;
        ref.read(externalFoodSearchProvider.notifier).search(searchText);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: 'Error al escanear: $e');
      }
    }
  }

  Future<void> _startVoiceSearch() async {
    // TODO: Implementar búsqueda por voz
    AppSnackbar.show(context, message: 'Búsqueda por voz - Próximamente');
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
  final VoidCallback onToggle;
  final VoidCallback onBarcodeScan;
  final VoidCallback onOcrScan;
  final VoidCallback onVoiceSearch;
  final VoidCallback onQuickAdd;

  const _ExpandableSmartImportFAB({
    required this.isExpanded,
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
            icon: Icons.mic,
            label: 'Voz',
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

  const _FabOption({
    required this.icon,
    required this.label,
    required this.onTap,
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
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
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
                errorBuilder: (_, _, __) => _buildPlaceholder(theme),
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
