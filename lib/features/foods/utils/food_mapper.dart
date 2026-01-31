import '../../../diet/models/food_model.dart';
import '../../../diet/repositories/alimento_repository.dart';
import '../../../training/database/database.dart';

/// Extensiones para convertir entre modelos de datos (Drift) y modelos de dominio
extension FoodMapper on Food {
  /// Convierte un Food (Drift) a FoodModel (dominio)
  FoodModel toModel() {
    return FoodModel(
      id: id,
      name: name,
      brand: brand,
      barcode: barcode,
      kcalPer100g: kcalPer100g,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      portionName: portionName,
      portionGrams: portionGrams,
      userCreated: userCreated,
      verifiedSource: verifiedSource,
      sourceMetadata: sourceMetadata,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Extensión para ScoredFood (del provider de diet)
extension ScoredFoodMapper on ScoredFood {
  /// Convierte un ScoredFood a FoodModel
  /// 
  /// ScoredFood tiene una propiedad 'food' que es de tipo Food (Drift)
  FoodModel toModel() {
    return food.toModel();
  }
}
