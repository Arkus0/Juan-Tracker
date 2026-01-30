import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../training/database/database.dart';
import '../providers/food_search_provider.dart';

/// Widget que muestra los resultados de búsqueda de alimentos
///
/// Maneja todos los estados:
/// - idle: Estado inicial con sugerencias
/// - loading: Cargando resultados
/// - success: Mostrar lista de resultados
/// - empty: Sin resultados con sugerencias inteligentes
/// - error: Error con opción de reintentar
/// - offline: Resultados locales sin conexión
class FoodSearchResults extends ConsumerWidget {
  final Function(Food)? onFoodSelected;
  final VoidCallback? onCreateCustom;

  const FoodSearchResults({
    super.key,
    this.onFoodSelected,
    this.onCreateCustom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodSearchProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _buildContent(context, ref, state),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, FoodSearchState state) {
    switch (state.status) {
      case SearchStatus.idle:
        return _buildIdleState(context, ref);
      case SearchStatus.loading:
        return _buildLoadingState(context);
      case SearchStatus.loadingMore:
        return _buildResultsList(context, ref, state, isLoadingMore: true);
      case SearchStatus.success:
        return _buildResultsList(context, ref, state);
      case SearchStatus.empty:
        return _buildEmptyState(context, ref, state);
      case SearchStatus.error:
        return _buildErrorState(context, ref, state);
      case SearchStatus.offline:
        return _buildOfflineState(context, ref, state);
    }
  }

  // ============================================================================
  // ESTADOS
  // ============================================================================

  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.4 * 255).round()),
          ),
          const SizedBox(height: 16),
          Text(
            'Busca alimentos por nombre o código de barras',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Sugerencias predictivas
          _buildPredictiveSuggestions(context, ref),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Buscando alimentos...'),
        ],
      ),
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    WidgetRef ref,
    FoodSearchState state, {
    bool isLoadingMore = false,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.results.length + (isLoadingMore || state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Botón de "cargar más" o indicador de carga
        if (index == state.results.length) {
          if (isLoadingMore) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () => ref.read(foodSearchProvider.notifier).loadMore(),
              child: const Text('Cargar más'),
            ),
          );
        }

        final scoredFood = state.results[index];
        return _FoodListTile(
          food: scoredFood.food,
          onTap: () {
            // Registrar selección
            ref.read(foodSearchProvider.notifier).selectFood(scoredFood.food.id);
            onFoodSelected?.call(scoredFood.food);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, FoodSearchState state) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados para "${state.query}"',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Sugerencias de queries similares
            if (state.suggestions.isNotEmpty) ...[
              Text(
                '¿Quisiste decir?',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: state.suggestions.map((s) => ActionChip(
                  avatar: const Icon(Icons.search, size: 16),
                  label: Text(s),
                  onPressed: () {
                    ref.read(foodSearchProvider.notifier).search(s);
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Alternativas populares
            if (state.popularAlternatives.isNotEmpty) ...[
              Text(
                'Alternativas populares',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...state.popularAlternatives.take(3).map((food) => _FoodListTile(
                food: food,
                isCompact: true,
                onTap: () => onFoodSelected?.call(food),
              )),
              const SizedBox(height: 24),
            ],

            // Botón para crear alimento personalizado
            if (state.showCreateCustom)
              ElevatedButton.icon(
                onPressed: onCreateCustom,
                icon: const Icon(Icons.add),
                label: const Text('Crear alimento personalizado'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, FoodSearchState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Error de búsqueda',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(foodSearchProvider.notifier)
                        .search(state.query, forceOffline: true);
                  },
                  icon: const Icon(Icons.wifi_off),
                  label: const Text('Modo offline'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(foodSearchProvider.notifier).search(state.query);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineState(BuildContext context, WidgetRef ref, FoodSearchState state) {
    return Column(
      children: [
        // Banner de offline
        Container(
          color: Colors.orange.shade100,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.errorMessage ?? 'Sin conexión a internet',
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ),
            ],
          ),
        ),
        // Resultados offline
        Expanded(child: _buildResultsList(context, ref, state)),
      ],
    );
  }

  // ============================================================================
  // SUGERENCIAS PREDICTIVAS
  // ============================================================================

  Widget _buildPredictiveSuggestions(BuildContext context, WidgetRef ref) {
    final futureFoods = ref.watch(predictiveFoodsProvider);

    return FutureBuilder<List<Food>>(
      future: futureFoods,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final foods = snapshot.data!;

        return Column(
          children: [
            Text(
              'Sugerencias para ti',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: foods.take(5).map((food) => ActionChip(
                avatar: const Icon(Icons.restaurant, size: 16),
                label: Text(food.name),
                onPressed: () => onFoodSelected?.call(food),
              )).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// TILE DE ALIMENTO
// ============================================================================

class _FoodListTile extends StatelessWidget {
  final Food food;
  final VoidCallback? onTap;
  final bool isCompact;

  const _FoodListTile({
    required this.food,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompact) {
      return ListTile(
        dense: true,
        leading: Icon(Icons.fastfood, color: theme.colorScheme.primary),
        title: Text(
          food.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: food.brand != null
            ? Text(food.brand!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Text(
          '${food.kcalPer100g} kcal',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        onTap: onTap,
      );
    }

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.restaurant, color: theme.colorScheme.primary),
      ),
      title: Text(
        food.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (food.portionName != null)
            Text(
              'Porción: ${food.portionName}',
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
