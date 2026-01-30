import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';
import '../../../diet/services/food_label_ocr_service.dart';
import '../../../diet/services/food_label_parser_service.dart';
import '../../diary/presentation/barcode_scanner_screen.dart';
import '../../diary/presentation/external_food_search_screen.dart';
import '../providers/foods_search_provider.dart';

/// Pantalla de biblioteca de alimentos
/// Permite ver, buscar y añadir alimentos a la base de datos
class FoodsScreen extends ConsumerStatefulWidget {
  const FoodsScreen({super.key});

  @override
  ConsumerState<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends ConsumerState<FoodsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Estado del FAB expandible
  bool _isFabExpanded = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Debounce de 300ms para evitar queries excesivas
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(foodsSearchProvider.notifier).search(value);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    ref.read(foodsSearchProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    // Usar el provider reactivo para la búsqueda
    final searchState = ref.watch(foodsSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alimentos'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar alimentos...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _onSearchChanged,
                );
              },
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (searchState.isLoading) {
            return const _FoodsLoadingSkeleton();
          }

          if (searchState.error != null) {
            return Center(child: Text('Error: ${searchState.error}'));
          }

          if (searchState.foods.isEmpty) {
            return _EmptyState(isSearch: searchState.query.isNotEmpty);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: searchState.foods.length,
            itemBuilder: (context, index) {
              final food = searchState.foods[index];
              return _FoodTile(
                food: food,
                onTap: () => _showFoodDetail(food),
              );
            },
          );
        },
      ),
      floatingActionButton: _SmartImportFAB(
        isExpanded: _isFabExpanded,
        onToggle: () => setState(() => _isFabExpanded = !_isFabExpanded),
        onManualAdd: () => _showAddFoodDialog(context),
        onBarcodeScan: () => _scanBarcode(context),
        onOcrScan: () => _scanFoodLabel(context),
      ),
    );
  }

  void _showFoodDetail(FoodModel food) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FoodDetailSheet(food: food),
    );
  }

  Future<void> _showAddFoodDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _AddFoodDialog(),
    );

    // Refrescar lista si se añadió un alimento exitosamente
    if (result == true && mounted) {
      ref.read(foodsSearchProvider.notifier).refresh();
    }
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode != null && mounted) {
      // Navegar a búsqueda externa con el código de barras
      if (context.mounted) {
        final food = await Navigator.of(context).push<FoodModel>(
          MaterialPageRoute(
            builder: (_) => ExternalFoodSearchScreen(
              returnFoodOnSelect: true,
              initialBarcode: barcode,
            ),
          ),
        );

        // Si se añadió un alimento, refrescar la lista
        if (food != null && mounted) {
          ref.read(foodsSearchProvider.notifier).refresh();
        }
      }
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

      // Mostrar diálogo para crear alimento con valores extraídos
      final foodName = per100g.name.isNotEmpty ? per100g.name : 'Alimento escaneado';
      
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => _AddFoodDialog(
          initialName: foodName,
          initialKcal: per100g.hasData ? per100g.kcal : null,
          initialProtein: per100g.hasData ? per100g.protein : null,
          initialCarbs: per100g.hasData ? per100g.carbs : null,
          initialFat: per100g.hasData ? per100g.fat : null,
        ),
      );

      if (saved == true && mounted) {
        ref.read(foodsSearchProvider.notifier).refresh();
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(context, message: 'Error al escanear: $e');
      }
    }
  }
}

/// Tile de alimento en la lista
class _FoodTile extends StatelessWidget {
  final FoodModel food;
  final VoidCallback onTap;

  const _FoodTile({
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.restaurant, color: theme.colorScheme.primary),
      ),
      title: Text(
        food.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (food.brand != null)
            Text(
              food.brand!,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          Text(
            '${food.kcalPer100g} kcal / 100g',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Estado vacío
class _EmptyState extends StatelessWidget {
  final bool isSearch;

  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.restaurant_menu,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.4 * 255).round()),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No se encontraron alimentos' : 'Sin alimentos',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 8),
            Text(
              'Añade tu primer alimento con el botón +',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.7 * 255).round()),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet con detalle del alimento
class _FoodDetailSheet extends StatelessWidget {
  final FoodModel food;

  const _FoodDetailSheet({required this.food});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Nombre
                    Text(
                      food.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (food.brand != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        food.brand!,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Macros
                    _MacroGrid(food: food),
                    const SizedBox(height: 24),

                    // Info adicional
                    if (food.portionName != null && food.portionGrams != null)
                      _InfoRow(
                        icon: Icons.scale,
                        label: 'Porción',
                        value: '1 ${food.portionName} = ${food.portionGrams}g',
                      ),
                    if (food.barcode != null)
                      _InfoRow(
                        icon: Icons.qr_code,
                        label: 'Código de barras',
                        value: food.barcode!,
                      ),
                    _InfoRow(
                      icon: food.userCreated ? Icons.person : Icons.verified,
                      label: 'Origen',
                      value: food.userCreated ? 'Creado por usuario' : 'Verificado',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MacroGrid extends StatelessWidget {
  final FoodModel food;

  const _MacroGrid({required this.food});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Kcal principal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${food.kcalPer100g}',
                style: GoogleFonts.montserrat(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'kcal\n/100g',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          // Macros
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MacroBox(
                label: 'Proteína',
                value: '${food.proteinPer100g?.toStringAsFixed(1) ?? 0}g',
                color: Colors.red.shade400,
              ),
              _MacroBox(
                label: 'Carbs',
                value: '${food.carbsPer100g?.toStringAsFixed(1) ?? 0}g',
                color: Colors.amber.shade600,
              ),
              _MacroBox(
                label: 'Grasa',
                value: '${food.fatPer100g?.toStringAsFixed(1) ?? 0}g',
                color: Colors.blue.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

/// Diálogo para añadir nuevo alimento
class _AddFoodDialog extends ConsumerStatefulWidget {
  final String? initialName;
  final int? initialKcal;
  final double? initialProtein;
  final double? initialCarbs;
  final double? initialFat;

  const _AddFoodDialog({
    this.initialName,
    this.initialKcal,
    this.initialProtein,
    this.initialCarbs,
    this.initialFat,
  });

  @override
  ConsumerState<_AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends ConsumerState<_AddFoodDialog> {
  final _formKey = GlobalKey<FormState>();
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
    _kcalController = TextEditingController(
      text: widget.initialKcal?.toString() ?? '',
    );
    _proteinController = TextEditingController(
      text: widget.initialProtein?.toStringAsFixed(1) ?? '',
    );
    _carbsController = TextEditingController(
      text: widget.initialCarbs?.toStringAsFixed(1) ?? '',
    );
    _fatController = TextEditingController(
      text: widget.initialFat?.toStringAsFixed(1) ?? '',
    );
    _portionNameController = TextEditingController();
    _portionGramsController = TextEditingController();
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
      title: const Text('Añadir Alimento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Marca (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kcalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kcal / 100g *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
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
                    child: TextFormField(
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
                    child: TextFormField(
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
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Porción personalizada (opcional)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _portionNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre (ej: taza)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _portionGramsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saveFood,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;

    final food = FoodModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      kcalPer100g: int.tryParse(_kcalController.text) ?? 0,
      proteinPer100g: double.tryParse(_proteinController.text),
      carbsPer100g: double.tryParse(_carbsController.text),
      fatPer100g: double.tryParse(_fatController.text),
      portionName: _portionNameController.text.trim().isEmpty
          ? null
          : _portionNameController.text.trim(),
      portionGrams: double.tryParse(_portionGramsController.text),
      userCreated: true,
    );

    final repo = ref.read(foodRepositoryProvider);
    try {
      await repo.insert(food);
      if (!mounted) return;
      Navigator.of(context).pop(true); // Devolver true para indicar éxito
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el alimento. Inténtalo de nuevo.'),
        ),
      );
    }
  }
}

/// FAB expandible con opciones de importación inteligente
class _SmartImportFAB extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onManualAdd;
  final VoidCallback onBarcodeScan;
  final VoidCallback onOcrScan;

  const _SmartImportFAB({
    required this.isExpanded,
    required this.onToggle,
    required this.onManualAdd,
    required this.onBarcodeScan,
    required this.onOcrScan,
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
            icon: Icons.edit,
            label: 'Manual',
            onTap: () {
              onToggle();
              onManualAdd();
            },
          ),
          const SizedBox(height: 8),
          _FabOption(
            icon: Icons.qr_code_scanner,
            label: 'Código de barras',
            onTap: () {
              onToggle();
              onBarcodeScan();
            },
          ),
          const SizedBox(height: 8),
          _FabOption(
            icon: Icons.document_scanner,
            label: 'Escanear etiqueta',
            onTap: () {
              onToggle();
              onOcrScan();
            },
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
  }); // ignore: unused_element_parameter

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 20,
              color: color ?? theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de carga para la lista de alimentos
class _FoodsLoadingSkeleton extends StatelessWidget {
  const _FoodsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, index) {
        return _SkeletonFoodTile(colors: colors);
      },
    );
  }
}

/// Tile de alimento en estado skeleton
class _SkeletonFoodTile extends StatefulWidget {
  final ColorScheme colors;

  const _SkeletonFoodTile({required this.colors});

  @override
  State<_SkeletonFoodTile> createState() => _SkeletonFoodTileState();
}

class _SkeletonFoodTileState extends State<_SkeletonFoodTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _shimmerGradient(),
            ),
          ),
          title: Container(
            height: 16,
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: _shimmerGradient(),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: _shimmerGradient(),
                ),
              ),
            ],
          ),
          trailing: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: _shimmerGradient(),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _shimmerGradient() {
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        widget.colors.surfaceContainerHighest,
        widget.colors.surfaceContainerHighest.withAlpha((0.7 * 255).round()),
        widget.colors.surfaceContainerHighest,
      ],
      stops: [
        (_animation.value - 0.3).clamp(0.0, 1.0),
        _animation.value.clamp(0.0, 1.0),
        (_animation.value + 0.3).clamp(0.0, 1.0),
      ],
    );
  }
}
