import 'package:flutter/material.dart';

import '../../../../training/database/database.dart';

/// Item de lista de alimentos con información nutricional
/// 
/// Muestra:
/// - Icono/emoji según categoría
/// - Nombre + marca
/// - Kcal/100g (rojo si es alto)
/// - Macros clave (P/C/G)
class FoodListItem extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;

  const FoodListItem({
    super.key,
    required this.food,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determinar color de calorías
    final kcalColor = _getKcalColor(food.kcalPer100g.toDouble());
    
    // Emoji/icono según categoría
    final emoji = _getEmojiForFood(food);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono/Emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
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
                    
                    // Marca (si existe)
                    if (food.brand != null && food.brand!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        food.brand!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 4),
                    
                    // Macros
                    _buildMacrosRow(theme),
                  ],
                ),
              ),
              
              // Calorías
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kcalColor.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${food.kcalPer100g.toStringAsFixed(0)}',
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

  String _getEmojiForFood(Food food) {
    final name = food.name.toLowerCase();
    // Usar sourceMetadata para obtener categorías si existen
    final metadata = food.sourceMetadata;
    final categories = metadata != null && metadata['categories'] is List
        ? (metadata['categories'] as List).join(' ').toLowerCase()
        : '';
    
    // Lácteos
    if (name.contains('leche') || name.contains('yogur') || 
        categories.contains('dairy') || categories.contains('milk')) {
      return '🥛';
    }
    if (name.contains('queso') || categories.contains('cheese')) {
      return '🧀';
    }
    
    // Carnes
    if (name.contains('pollo') || name.contains('chicken')) {
      return '🍗';
    }
    if (name.contains('carne') || name.contains('beef') || name.contains('steak')) {
      return '🥩';
    }
    if (name.contains('jamón') || name.contains('jamon') || name.contains('ham')) {
      return '🥓';
    }
    if (name.contains('pescado') || name.contains('fish') || name.contains('salmon')) {
      return '🐟';
    }
    
    // Frutas y verduras
    if (name.contains('manzana') || name.contains('apple')) {
      return '🍎';
    }
    if (name.contains('plátano') || name.contains('platano') || name.contains('banana')) {
      return '🍌';
    }
    if (name.contains('naranja') || name.contains('orange')) {
      return '🍊';
    }
    if (categories.contains('fruit') || categories.contains('fruta')) {
      return '🍎';
    }
    if (categories.contains('vegetable') || categories.contains('verdura')) {
      return '🥬';
    }
    
    // Cereales y pan
    if (name.contains('pan') || name.contains('bread')) {
      return '🍞';
    }
    if (name.contains('pasta') || categories.contains('pasta')) {
      return '🍝';
    }
    if (name.contains('arroz') || name.contains('rice')) {
      return '🍚';
    }
    if (categories.contains('cereal')) {
      return '🥣';
    }
    
    // Bebidas
    if (name.contains('agua') || name.contains('water')) {
      return '💧';
    }
    if (name.contains('zumo') || name.contains('jugo') || name.contains('juice')) {
      return '🧃';
    }
    if (name.contains('refresco') || name.contains('soda') || categories.contains('beverage')) {
      return '🥤';
    }
    if (name.contains('cerveza') || name.contains('beer')) {
      return '🍺';
    }
    if (name.contains('vino') || name.contains('wine')) {
      return '🍷';
    }
    if (name.contains('café') || name.contains('cafe') || name.contains('coffee')) {
      return '☕';
    }
    
    // Snacks y dulces
    if (name.contains('chocolate')) {
      return '🍫';
    }
    if (name.contains('galleta') || name.contains('cookie') || name.contains('cracker')) {
      return '🍪';
    }
    if (name.contains('helado') || name.contains('ice cream')) {
      return '🍦';
    }
    if (name.contains('chips') || name.contains('patatas') || categories.contains('snack')) {
      return '🥔';
    }
    
    // Huevos
    if (name.contains('huevo') || name.contains('egg')) {
      return '🥚';
    }
    
    // Aceites
    if (name.contains('aceite') || name.contains('oil')) {
      return '🫒';
    }
    
    // Default
    return '🍽️';
  }
}
