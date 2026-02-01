import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';

import '../../training/database/database.dart';
import '../models/food_model.dart';



/// Filtros avanzados para búsqueda de alimentos
class SearchFilters {
  final bool soloGenericos;
  final bool soloVerificados;
  final bool soloConImagen;
  final String? categoria;
  final String? minNutriScore; // 'a', 'b', 'c', 'd', 'e'
  final int? maxNovaGroup; // 1, 2, 3, 4
  final double? minProteinas;
  final double? maxCalorias;
  final List<String>? alergenosExcluir;
  final List<String>? preferenciasDieteticas; // 'vegano', 'keto', etc.

  const SearchFilters({
    this.soloGenericos = false,
    this.soloVerificados = false,
    this.soloConImagen = false,
    this.categoria,
    this.minNutriScore,
    this.maxNovaGroup,
    this.minProteinas,
    this.maxCalorias,
    this.alergenosExcluir,
    this.preferenciasDieteticas,
  });

  SearchFilters copyWith({
    bool? soloGenericos,
    bool? soloVerificados,
    bool? soloConImagen,
    String? categoria,
    String? minNutriScore,
    int? maxNovaGroup,
    double? minProteinas,
    double? maxCalorias,
    List<String>? alergenosExcluir,
    List<String>? preferenciasDieteticas,
  }) {
    return SearchFilters(
      soloGenericos: soloGenericos ?? this.soloGenericos,
      soloVerificados: soloVerificados ?? this.soloVerificados,
      soloConImagen: soloConImagen ?? this.soloConImagen,
      categoria: categoria ?? this.categoria,
      minNutriScore: minNutriScore ?? this.minNutriScore,
      maxNovaGroup: maxNovaGroup ?? this.maxNovaGroup,
      minProteinas: minProteinas ?? this.minProteinas,
      maxCalorias: maxCalorias ?? this.maxCalorias,
      alergenosExcluir: alergenosExcluir ?? this.alergenosExcluir,
      preferenciasDieteticas: preferenciasDieteticas ?? this.preferenciasDieteticas,
    );
  }
}

/// Modelo de resultado de búsqueda con score de relevancia
class ScoredFood {
  final Food food;
  final double score;
  final bool isFromCache;
  final bool isFromRemote;

  const ScoredFood({
    required this.food,
    required this.score,
    this.isFromCache = false,
    this.isFromRemote = false,
  });
}

/// Repository para operaciones de alimentos con Drift
/// 
/// Características:
/// - Búsqueda FTS5 nativa de SQLite
/// - Ranking inteligente con múltiples señales
/// 
/// Nota: Para búsquedas externas (Open Food Facts), usar FoodSearchRepository
class AlimentoRepository {
  final AppDatabase _db;

  AlimentoRepository(this._db);

  // ============================================================================
  // BÚSQUEDA PRINCIPAL
  // ============================================================================

  /// Búsqueda inteligente: local primero, API después
  /// 
  /// Estrategia:
  /// 1. Busca localmente con FTS5 (instantáneo)
  /// 2. Aplica filtros adicionales
  /// 3. Si hay pocos resultados (<10), busca en API
  /// 4. Guarda resultados remotos en caché local
  /// 5. Aplica ranking personalizado combinando múltiples señales
  Future<List<ScoredFood>> search(
    String query, {
    SearchFilters? filters,
    int limit = 50,
    bool includeRemote = true,
  }) async {
    if (query.trim().isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase().trim();
    
    // 1. Búsqueda FTS local (instantánea)
    var localResults = await _db.searchFoodsFTS(normalizedQuery, limit: limit);
    
    // 2. Aplicar filtros adicionales
    if (filters != null) {
      localResults = _applyFilters(localResults, filters);
    }
    
    // Convertir a ScoredFood con score base
    var scoredResults = localResults.map((f) => ScoredFood(
      food: f,
      score: _calculateBaseScore(f, normalizedQuery),
      isFromCache: true,
    )).toList();
    
    // 3. Aplicar ranking final
    return _applyRanking(scoredResults, normalizedQuery).take(limit).toList();
  }

  /// Búsqueda rápida offline (solo local)
  Future<List<Food>> searchOffline(String query, {int limit = 50}) async {
    return _db.searchFoodsOffline(query, limit: limit);
  }

  /// Búsqueda por código de barras (solo local)
  /// 
  /// Nota: Para búsqueda externa por barcode, usar FoodSearchRepository
  Future<Food?> searchByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;
    
    final cleanBarcode = barcode.trim();
    
    // Buscar localmente
    final local = await (_db.select(_db.foods)
      ..where((f) => f.barcode.equals(cleanBarcode)))
      .getSingleOrNull();
    
    if (local != null) {
      await _db.recordFoodUsage(local.id);
      return local;
    }
    
    return null;
  }

  // ============================================================================
  // SUGERENCIAS Y PREDICCIONES
  // ============================================================================

  /// Sugerencias de autocompletado
  Future<List<String>> getSuggestions(String prefix, {int limit = 10}) async {
    if (prefix.length < 2) return [];
    return _db.getSearchSuggestions(prefix, limit: limit);
  }

  /// Alimentos habituales del usuario basados en contexto temporal
  Future<List<Food>> getHabitualFoods({
    DateTime? dateTime,
    int limit = 20,
  }) async {
    final dt = dateTime ?? DateTime.now();
    return _db.getHabitualFoods(
      hourOfDay: dt.hour,
      dayOfWeek: dt.weekday,
      limit: limit,
    );
  }

  /// Alimentos más usados recientemente
  Future<List<Food>> getRecentlyUsed({int limit = 20}) async {
    return (_db.select(_db.foods)
      ..where((f) => f.lastUsedAt.isNotNull())
      ..orderBy([(f) => OrderingTerm.desc(f.lastUsedAt)])
      ..limit(limit))
      .get();
  }

  /// Alimentos más populares (por useCount)
  Future<List<Food>> getMostPopular({int limit = 20}) async {
    return (_db.select(_db.foods)
      ..orderBy([(f) => OrderingTerm.desc(f.useCount)])
      ..limit(limit))
      .get();
  }

  /// Alimentos favoritos del usuario
  Future<List<Food>> getFavorites({int limit = 50}) async {
    return (_db.select(_db.foods)
      ..where((f) => f.isFavorite.equals(true))
      ..orderBy([(f) => OrderingTerm.desc(f.lastUsedAt)])
      ..limit(limit))
      .get();
  }

  /// Marcar/desmarcar alimento como favorito
  Future<void> setFavorite(String foodId, bool isFavorite) async {
    await (_db.update(_db.foods)
      ..where((f) => f.id.equals(foodId)))
      .write(FoodsCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ));
  }

  /// Alternar estado de favorito
  Future<bool> toggleFavorite(String foodId) async {
    final food = await getById(foodId);
    if (food == null) return false;
    
    final newState = !food.isFavorite;
    await setFavorite(foodId, newState);
    return newState;
  }

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  /// Insertar o actualizar un alimento
  Future<void> saveFood(FoodModel model) async {
    final companion = FoodsCompanion(
      id: Value(model.id),
      name: Value(model.name),
      normalizedName: Value(model.name.toLowerCase()),
      brand: Value(model.brand),
      barcode: Value(model.barcode),
      kcalPer100g: Value(model.kcalPer100g),
      proteinPer100g: Value(model.proteinPer100g ?? 0),
      carbsPer100g: Value(model.carbsPer100g ?? 0),
      fatPer100g: Value(model.fatPer100g ?? 0),
      portionName: Value(model.portionName),
      portionGrams: Value(model.portionGrams),
      userCreated: Value(model.userCreated),
      verifiedSource: Value(model.verifiedSource),
      sourceMetadata: Value(model.sourceMetadata),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
    
    await _db.into(_db.foods).insertOnConflictUpdate(companion);
    
    // Sincronizar con índice FTS5
    await _db.insertFoodFts(
      model.id,
      model.name,
      model.brand,
    );
  }

  /// Obtener un alimento por ID
  Future<Food?> getById(String id) async {
    return (_db.select(_db.foods)
      ..where((f) => f.id.equals(id)))
      .getSingleOrNull();
  }

  /// Eliminar un alimento
  Future<void> delete(String id) async {
    await (_db.delete(_db.foods)
      ..where((f) => f.id.equals(id)))
      .go();
  }

  /// Registrar selección de alimento (actualiza estadísticas)
  Future<void> recordSelection(String foodId, {MealType? mealType}) async {
    await _db.recordFoodUsage(foodId, mealType: mealType);
  }

  /// Guardar búsqueda en historial
  Future<void> recordSearch(String query, {String? selectedFoodId, bool hasResults = true}) async {
    await _db.saveSearchHistory(query, selectedFoodId: selectedFoodId, hasResults: hasResults);
  }

  // ============================================================================
  // MÉTODOS PRIVADOS
  // ============================================================================



  List<Food> _applyFilters(List<Food> foods, SearchFilters filters) {
    return foods.where((f) {
      if (filters.soloGenericos && !f.userCreated) return false;
      if (filters.soloVerificados && f.verifiedSource == null) return false;
      if (filters.minNutriScore != null && f.nutriScore != null) {
        // Nutri-Score: 'a' es mejor que 'e'
        final order = {'a': 5, 'b': 4, 'c': 3, 'd': 2, 'e': 1};
        final foodScore = order[f.nutriScore?.toLowerCase()] ?? 0;
        final minScore = order[filters.minNutriScore!.toLowerCase()] ?? 0;
        if (foodScore < minScore) return false;
      }
      if (filters.maxNovaGroup != null && f.novaGroup != null) {
        if (f.novaGroup! > filters.maxNovaGroup!) return false;
      }
      if (filters.minProteinas != null && (f.proteinPer100g ?? 0) < filters.minProteinas!) {
        return false;
      }
      if (filters.maxCalorias != null && f.kcalPer100g > filters.maxCalorias!) {
        return false;
      }
      return true;
    }).toList();
  }

  double _calculateBaseScore(Food food, String query) {
    var score = 0.0;
    final nameLower = food.name.toLowerCase();
    final queryLower = query.toLowerCase();
    
    // 1. Coincidencia exacta al inicio (máxima prioridad)
    if (nameLower.startsWith(queryLower)) {
      score += 100;
    } 
    // 2. Coincidencia exacta en cualquier parte
    else if (nameLower.contains(queryLower)) {
      score += 50;
    }
    // 3. Coincidencia en palabras individuales
    else if (nameLower.split(' ').any((word) => word.startsWith(queryLower))) {
      score += 30;
    }
    
    // 4. Popularidad (escala logarítmica para no favorecer demasiado)
    score += math.log(food.useCount + 1) * 5;
    
    // 5. Recencia de uso
    if (food.lastUsedAt != null) {
      final diasDesdeUso = DateTime.now().difference(food.lastUsedAt!).inDays;
      score += math.max(0, 20 - diasDesdeUso);
    }
    
    // 6. Verificación (alimentos verificados tienen boost)
    if (food.verifiedSource != null) score += 10;
    
    // 7. Preferir alimentos con datos completos
    final hasCompleteData = food.proteinPer100g != null && 
                           food.carbsPer100g != null && 
                           food.fatPer100g != null;
    if (hasCompleteData) score += 5;
    
    return score;
  }

  List<ScoredFood> _applyRanking(List<ScoredFood> foods, String query) {
    // Ordenar por score descendente
    foods.sort((a, b) => b.score.compareTo(a.score));
    return foods;
  }

}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider del AlimentoRepository (solo búsqueda local)
/// 
/// Nota: Para búsquedas externas (Open Food Facts), usar foodSearchRepositoryProvider
final alimentoRepositoryProvider = Provider<AlimentoRepository>((ref) {
  return AlimentoRepository(ref.watch(appDatabaseProvider));
});
