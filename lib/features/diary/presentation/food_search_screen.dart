import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';
import 'add_entry_dialog.dart';

/// Pantalla de búsqueda de alimentos para añadir al diario
/// Paso 1: Buscar/Seleccionar alimento o Quick Add
class FoodSearchScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const FoodSearchScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Limpiar búsqueda al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodSearchQueryProvider.notifier).query = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(foodSearchResultsProvider);
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Entrada' : 'Añadir Alimento'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
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
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              onChanged: (value) {
                ref.read(foodSearchQueryProvider.notifier).query = value;
              },
            ),
          ),

          // Opción Quick Add
          _QuickAddButton(
            onTap: () => _showQuickAddDialog(context),
          ),

          const Divider(height: 1),

          // Lista de resultados
          Expanded(
            child: searchResults.when(
              data: (foods) {
                if (foods.isEmpty && _searchController.text.isNotEmpty) {
                  return const _EmptySearchState();
                }
                if (foods.isEmpty) {
                  return const _InitialState();
                }
                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return _FoodListTile(
                      food: food,
                      onTap: () => _selectFood(context, food),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFood(BuildContext context, FoodModel food) async {
    ref.read(selectedFoodProvider.notifier).selected = food;
    
    final result = await showDialog<DiaryEntryModel>(
      context: context,
      builder: (ctx) => AddEntryDialog(food: food),
    );

    if (result != null && mounted) {
      await _saveEntry(result);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _showQuickAddDialog(BuildContext context) async {
    final result = await showDialog<DiaryEntryModel>(
      context: context,
      builder: (ctx) => const QuickAddDialog(),
    );

    if (result != null && mounted) {
      await _saveEntry(result);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _saveEntry(DiaryEntryModel entry) async {
    final repo = ref.read(diaryRepositoryProvider);
    final existingEntry = ref.read(editingEntryProvider);

    if (existingEntry != null) {
      // Actualizar entrada existente
      await repo.update(entry);
    } else {
      // Crear nueva entrada
      await repo.insert(entry);
    }
  }
}

/// Botón de Quick Add
class _QuickAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.bolt, color: Colors.orange.shade700),
      ),
      title: const Text(
        'Añadir Rápido',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('Introduce kcal y macros directamente'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Tile de alimento en la lista
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

/// Estado vacío cuando no hay resultados
class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
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
            'Prueba con otra búsqueda o usa "Añadir Rápido"',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado inicial (sin búsqueda)
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
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Busca alimentos de tu biblioteca',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
