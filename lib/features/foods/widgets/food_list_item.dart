import 'package:flutter/material.dart';

import '../../../../training/database/database.dart';

/// Callback para quick-log: recibe (amount, unitLabel) donde unitLabel es 'g', 'ml' o porción
typedef QuickLogCallback = void Function(double amount, String unitKey);

// ============================================================================
// PERF: Emoji lookup optimization - O(1) instead of O(27) per item
// ============================================================================

/// Pre-compiled keyword-to-emoji map for instant lookup.
/// Keys are lowercase keywords that map to emoji.
const _kEmojiKeywords = <String, String>{
  // Lácteos
  'leche': '🥛', 'yogur': '🥛', 'dairy': '🥛', 'milk': '🥛',
  'queso': '🧀', 'cheese': '🧀',
  // Carnes
  'pollo': '🍗', 'chicken': '🍗',
  'carne': '🥩', 'beef': '🥩', 'steak': '🥩', 'ternera': '🥩',
  'jamón': '🥓', 'jamon': '🥓', 'ham': '🥓',
  'pescado': '🐟', 'fish': '🐟', 'salmon': '🐟', 'atún': '🐟', 'atun': '🐟',
  // Frutas
  'manzana': '🍎', 'apple': '🍎',
  'plátano': '🍌', 'platano': '🍌', 'banana': '🍌',
  'naranja': '🍊', 'orange': '🍊',
  'fruit': '🍎', 'fruta': '🍎',
  // Verduras
  'vegetable': '🥬', 'verdura': '🥬', 'vegetal': '🥬',
  // Cereales y pan
  'pan': '🍞', 'bread': '🍞',
  'pasta': '🍝',
  'arroz': '🍚', 'rice': '🍚',
  'cereal': '🥣',
  // Bebidas
  'agua': '💧', 'water': '💧',
  'zumo': '🧃', 'jugo': '🧃', 'juice': '🧃',
  'refresco': '🥤', 'soda': '🥤', 'beverage': '🥤', 'bebida': '🥤',
  'cerveza': '🍺', 'beer': '🍺',
  'vino': '🍷', 'wine': '🍷',
  'café': '☕', 'cafe': '☕', 'coffee': '☕',
  // Snacks y dulces
  'chocolate': '🍫',
  'galleta': '🍪', 'cookie': '🍪', 'cracker': '🍪',
  'helado': '🍦', 'ice cream': '🍦',
  'chips': '🥔', 'patatas': '🥔', 'snack': '🥔',
  // Huevos
  'huevo': '🥚', 'egg': '🥚',
  // Aceites
  'aceite': '🫒', 'oil': '🫒',
};

/// Cached emoji results by food ID to avoid re-scanning.
/// Using a simple LRU-style cache with max 200 entries.
final _emojiCache = <String, String>{};
const _maxCacheSize = 200;

/// Fast emoji lookup using keyword map + caching.
/// O(words_in_name) instead of O(27 comparisons) per call.
String _getEmojiForFoodFast(Food food) {
  // Check cache first
  final cached = _emojiCache[food.id];
  if (cached != null) return cached;

  // Parse name into words for keyword matching
  final nameLower = food.name.toLowerCase();
  final words = nameLower.split(RegExp(r'[\s,.\-_]+'));

  // Check each word against keyword map - O(n) where n = words in name
  for (final word in words) {
    final emoji = _kEmojiKeywords[word];
    if (emoji != null) {
      _cacheEmoji(food.id, emoji);
      return emoji;
    }
  }

  // Check categories from metadata if available
  final metadata = food.sourceMetadata;
  if (metadata != null && metadata['categories'] is List) {
    final categories = (metadata['categories'] as List).join(' ').toLowerCase();
    for (final keyword in _kEmojiKeywords.keys) {
      if (categories.contains(keyword)) {
        final emoji = _kEmojiKeywords[keyword]!;
        _cacheEmoji(food.id, emoji);
        return emoji;
      }
    }
  }

  // Default
  _cacheEmoji(food.id, '🍽️');
  return '🍽️';
}

void _cacheEmoji(String foodId, String emoji) {
  // Simple cache eviction when full
  if (_emojiCache.length >= _maxCacheSize) {
    // Remove oldest 20% of entries
    final keysToRemove = _emojiCache.keys.take(_maxCacheSize ~/ 5).toList();
    for (final key in keysToRemove) {
      _emojiCache.remove(key);
    }
  }
  _emojiCache[foodId] = emoji;
}

// ============================================================================

/// Item de lista de alimentos con información nutricional
///
/// Muestra:
/// - Icono/emoji según categoría
/// - Nombre + marca
/// - Kcal/100g (rojo si es alto)
/// - Macros clave (P/C/G)
/// - Opcionalmente: toggle de favorito y checkbox para batch add
class FoodListItem extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final bool showFavoriteButton;
  final bool showSelectionCheckbox;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  /// Callback para registro rápido (sin abrir diálogo).
  /// Si se pasa, se muestra una fila de chips de cantidad bajo los macros.
  final QuickLogCallback? onQuickLog;

  const FoodListItem({
    super.key,
    required this.food,
    required this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.showFavoriteButton = false,
    this.showSelectionCheckbox = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.onQuickLog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determinar color de calorías
    final kcalColor = _getKcalColor(food.kcalPer100g.toDouble());

    // PERF: Use optimized emoji lookup with caching
    final emoji = _getEmojiForFoodFast(food);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      // Highlight selected items
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: showSelectionCheckbox ? onSelectionToggle : onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox for batch mode OR Emoji icon
              if (showSelectionCheckbox) ...[
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onSelectionToggle?.call(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(
                      (0.3 * 255).round(),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ],
              const SizedBox(width: 16),

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      food.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Marca (si existe) + indicador OFF
                    if (food.brand != null && food.brand!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              food.brand!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Indicador de fuente verificada (OFF)
                          if (food.verifiedSource == 'openfoodfacts') ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified_outlined,
                              size: 14,
                              color: Colors.green[600],
                            ),
                          ],
                        ],
                      ),
                    ] else if (food.verifiedSource == 'openfoodfacts') ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_done_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Open Food Facts',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 4),

                    // Macros
                    _buildMacrosRow(theme),

                    // Quick-log chips (si está habilitado)
                    if (onQuickLog != null)
                      _buildQuickLogRow(theme),
                  ],
                ),
              ),

              // Favorito toggle (si está habilitado)
              if (showFavoriteButton && onFavoriteToggle != null) ...[
                IconButton(
                  icon: Icon(
                    food.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: food.isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: onFavoriteToggle,
                  tooltip: food.isFavorite
                      ? 'Quitar de favoritos'
                      : 'Añadir a favoritos',
                ),
              ],

              // Calorías
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kcalColor.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      food.kcalPer100g.toStringAsFixed(0),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kcalColor,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: kcalColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLogRow(ThemeData theme) {
    final presets = <_QuickPreset>[];

    // Porción del alimento (si existe)
    if (food.portionName != null && food.portionGrams != null) {
      presets.add(_QuickPreset(
        label: '1 ${food.portionName}',
        amount: 1,
        unitKey: 'portion',
      ));
    }

    // Cantidades estándar
    presets.addAll(const [
      _QuickPreset(label: '100g', amount: 100, unitKey: 'g'),
      _QuickPreset(label: '150g', amount: 150, unitKey: 'g'),
      _QuickPreset(label: '200g', amount: 200, unitKey: 'g'),
    ]);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: presets.map((p) => _QuickLogChip(
          label: p.label,
          onTap: () => onQuickLog?.call(p.amount, p.unitKey),
        )).toList(),
      ),
    );
  }

  Widget _buildMacrosRow(ThemeData theme) {
    final protein = food.proteinPer100g;
    final carbs = food.carbsPer100g;
    final fat = food.fatPer100g;

    return Row(
      children: [
        if (protein != null) _buildMacroChip('P', protein, Colors.green),
        if (carbs != null) _buildMacroChip('C', carbs, Colors.orange),
        if (fat != null) _buildMacroChip('G', fat, Colors.blue),
      ],
    );
  }

  Widget _buildMacroChip(String label, double value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label${value.toStringAsFixed(0)}g',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getKcalColor(double kcal) {
    if (kcal >= 500) return Colors.red;
    if (kcal >= 300) return Colors.orange;
    if (kcal >= 150) return Colors.amber;
    return Colors.green;
  }

  // NOTE: _getEmojiForFood moved to top-level _getEmojiForFoodFast() with
  // hash map lookup + caching for O(1) vs O(27) performance improvement
}

/// Dato interno para un preset de quick-log
class _QuickPreset {
  final String label;
  final double amount;
  final String unitKey; // 'g', 'ml', 'portion'

  const _QuickPreset({
    required this.label,
    required this.amount,
    required this.unitKey,
  });
}

/// Chip compacto para loguear una cantidad con un toque
class _QuickLogChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickLogChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.secondaryContainer.withAlpha(100),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 14, color: colors.secondary),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
