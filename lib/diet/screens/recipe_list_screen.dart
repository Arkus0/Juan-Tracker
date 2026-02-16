import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../core/services/user_error_message.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/router/app_router.dart';
import '../models/recipe_model.dart';
import '../providers/recipe_providers.dart';
import '../repositories/recipe_repository.dart';
import '../services/recipe_url_importer.dart';

/// Pantalla de lista de recetas
///
/// Muestra todas las recetas guardadas con búsqueda y acciones rápidas.
/// Desde aquí se puede crear, editar o eliminar recetas.
class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isImportingRecipe = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesStreamProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Recetas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: _isImportingRecipe
                ? 'Importando receta...'
                : 'Importar desde URL',
            onPressed: _isImportingRecipe
                ? null
                : () => _showImportUrlDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(recipeEditorProvider.notifier).initNew();
          context.pushTo(AppRouter.nutritionRecipeNew);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_isImportingRecipe) const LinearProgressIndicator(minHeight: 2),
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar recetas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withAlpha(
                  (0.3 * 255).round(),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Lista de recetas
          Expanded(
            child: recipesAsync.when(
              loading: () => const AppLoading(message: 'Cargando recetas...'),
              error: (e, _) => Center(
                child: Text(
                  userErrorMessage(
                    e,
                    fallback: 'No se pudieron cargar las recetas.',
                  ),
                ),
              ),
              data: (recipes) {
                // Filtrar por búsqueda
                final filtered = _searchQuery.isEmpty
                    ? recipes
                    : recipes
                          .where(
                            (r) => r.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return AppEmpty(
                    icon: Icons.restaurant_menu,
                    title: recipes.isEmpty ? 'Sin recetas' : 'Sin resultados',
                    subtitle: recipes.isEmpty
                        ? 'Crea tu primera receta con el botón +'
                        : 'No se encontraron recetas con "$_searchQuery"',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _RecipeCard(
                      recipe: filtered[index],
                      onTap: () => _openRecipe(filtered[index]),
                      onDelete: () => _deleteRecipe(filtered[index]),
                      onAddToDiary: () => _addToDiary(filtered[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openRecipe(RecipeModel recipe) {
    ref.read(recipeEditorProvider.notifier).initFromRecipe(recipe);
    context.pushTo('${AppRouter.nutritionRecipes}/${recipe.id}');
  }

  Future<void> _deleteRecipe(RecipeModel recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar receta', style: AppTypography.titleMedium),
        content: Text(
          '¿Eliminar "${recipe.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(recipeRepositoryProvider);
      await repo.delete(recipe.id);
      ref.invalidate(recipesStreamProvider);
      if (mounted) {
        AppSnackbar.show(context, message: '${recipe.name} eliminada');
      }
    }
  }

  Future<void> _addToDiary(RecipeModel recipe) async {
    // Guardar como food y notificar
    final repo = ref.read(recipeRepositoryProvider);
    final food = await repo.saveAsFood(recipe);
    if (mounted) {
      AppSnackbar.show(
        context,
        message: '"${food.name}" guardada como alimento. Búscala en el diario.',
      );
    }
  }

  // ---- Importar desde URL ----

  Future<void> _showImportUrlDialog(BuildContext ctx) async {
    final urlController = TextEditingController();

    final url = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Importar receta desde URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pega la URL de una receta web. Se extraerán nombre, ingredientes y nutrición si están disponibles.',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(dialogCtx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: urlController,
              autofocus: true,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'https://ejemplo.com/receta...',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  tooltip: 'Pegar URL',
                  onPressed: () async {
                    final clipboard = await Clipboard.getData('text/plain');
                    final pasted = clipboard?.text?.trim();
                    if (pasted == null || pasted.isEmpty) return;
                    urlController
                      ..text = pasted
                      ..selection = TextSelection.collapsed(
                        offset: pasted.length,
                      );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onSubmitted: (_) {
                final normalized = _normalizeHttpUrl(urlController.text);
                if (normalized != null) {
                  Navigator.pop(dialogCtx, normalized);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCELAR'),
          ),
          FilledButton.icon(
            onPressed: () {
              final normalized = _normalizeHttpUrl(urlController.text);
              if (normalized != null) {
                Navigator.pop(dialogCtx, normalized);
              } else {
                AppSnackbar.showError(
                  dialogCtx,
                  message: 'Introduce una URL válida (http/https)',
                );
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('IMPORTAR'),
          ),
        ],
      ),
    );

    urlController.dispose();

    if (url == null || !ctx.mounted) return;

    setState(() => _isImportingRecipe = true);

    try {
      final importer = RecipeUrlImporter();
      final parsed = await importer.importFromUrl(url);

      if (!ctx.mounted) return;

      if (parsed.ingredients.isEmpty) {
        AppSnackbar.showError(
          ctx,
          message: 'No se encontraron ingredientes en la URL',
        );
        return;
      }

      // Iniciar editor con datos importados
      ref.read(recipeEditorProvider.notifier).initNew();
      ref.read(recipeEditorProvider.notifier).setName(parsed.name);
      if (parsed.description != null) {
        ref
            .read(recipeEditorProvider.notifier)
            .setDescription(parsed.description!);
      }
      if (parsed.servings != null && parsed.servings! > 0) {
        ref.read(recipeEditorProvider.notifier).setServings(parsed.servings!);
      }

      if (ctx.mounted) {
        ctx.pushTo(AppRouter.nutritionRecipeNew);

        // Mostrar ingredientes parseados como guía
        Future.delayed(const Duration(milliseconds: 500), () {
          if (ctx.mounted) {
            _showParsedIngredientsSheet(ctx, parsed);
          }
        });
      }
    } on RecipeImportException catch (e) {
      if (ctx.mounted) {
        AppSnackbar.showError(ctx, message: e.message);
      }
    } catch (_) {
      if (ctx.mounted) {
        AppSnackbar.showError(
          ctx,
          message: 'No se pudo importar la receta en este momento.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingRecipe = false);
      }
    }
  }

  String? _normalizeHttpUrl(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    return null;
  }

  void _showParsedIngredientsSheet(BuildContext ctx, ParsedRecipe parsed) {
    final colors = Theme.of(ctx).colorScheme;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withAlpha((0.4 * 255).round()),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.checklist, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ingredientes de "${parsed.name}"',
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Usa esta lista como guía para añadir ingredientes manualmente con la búsqueda.',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            if (parsed.totalKcal != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Total estimado: ${parsed.totalKcal} kcal'
                      '${parsed.totalProtein != null ? ', ${parsed.totalProtein!.round()}g prot' : ''}',
                      style: AppTypography.labelMedium.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: parsed.ingredients.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          parsed.ingredients[index],
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de receta en la lista
class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onAddToDiary;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onDelete,
    required this.onAddToDiary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera: nombre + acciones
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 20,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            style: AppTypography.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${recipe.items.length} ingredientes · ${recipe.servings} ${recipe.servingName ?? 'porción'}${recipe.servings > 1 ? 'es' : ''}',
                            style: AppTypography.labelSmall.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'diary':
                            onAddToDiary();
                          case 'delete':
                            onDelete();
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'diary',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline, size: 18),
                              SizedBox(width: 8),
                              Text('Guardar como alimento'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: colors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Eliminar',
                                style: TextStyle(color: colors.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Macros por porción
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withAlpha(
                      (0.5 * 255).round(),
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MacroChip(
                        label: 'kcal',
                        value: '${recipe.kcalPerServing}',
                        color: colors.primary,
                      ),
                      _MacroChip(
                        label: 'P',
                        value:
                            '${recipe.proteinPerServing?.toStringAsFixed(0) ?? '-'}g',
                        color: const Color(0xFF4CAF50),
                      ),
                      _MacroChip(
                        label: 'C',
                        value:
                            '${recipe.carbsPerServing?.toStringAsFixed(0) ?? '-'}g',
                        color: const Color(0xFFFF9800),
                      ),
                      _MacroChip(
                        label: 'G',
                        value:
                            '${recipe.fatPerServing?.toStringAsFixed(0) ?? '-'}g',
                        color: const Color(0xFFF44336),
                      ),
                    ],
                  ),
                ),
                if (recipe.description != null &&
                    recipe.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    recipe.description!,
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
