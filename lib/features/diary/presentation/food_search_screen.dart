import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/providers/database_provider.dart';
import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';
import 'add_entry_dialog.dart';

/// Pantalla de búsqueda de alimentos (solo local)
/// 
/// Nota: Para búsqueda en Open Food Facts, usar ExternalFoodSearchScreen
class FoodSearchScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const FoodSearchScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  
  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodSearchQueryProvider.notifier).query = '';
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
    final searchQuery = ref.watch(foodSearchQueryProvider);
    final searchResults = ref.watch(foodSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Entrada' : 'Añadir Alimento'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar alimentos...',
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
              ),
              onChanged: (value) {
                _debounceTimer?.cancel();
                _debounceTimer = Timer(_debounceDuration, () {
                  ref.read(foodSearchQueryProvider.notifier).query = value;
                });
              },
            ),
          ),
          
          // Resultados
          Expanded(
            child: searchResults.when(
              data: (foods) {
                if (foods.isEmpty && searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron resultados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Para buscar en Open Food Facts,\nusa la búsqueda externa',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (foods.isEmpty) {
                  return const Center(
                    child: Text('Escribe para buscar alimentos'),
                  );
                }
                
                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return ListTile(
                      title: Text(food.name),
                      subtitle: food.brand != null ? Text(food.brand!) : null,
                      trailing: Text('${food.kcalPer100g} kcal/100g'),
                      onTap: () => _selectFood(food),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('Error al buscar')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFood(FoodModel food) async {
    final result = await showDialog<DiaryEntryModel>(
      context: context,
      builder: (ctx) => AddEntryDialog(food: food),
    );

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }
}
