import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

/// Identificadores de tiles del dashboard
enum DashboardTileId {
  nutrition('Nutrición', 'Calorías y macros del día'),
  training('Entrenamiento', 'Sugerencia de entrenamiento'),
  streak('Racha entrenamiento', 'Días consecutivos entrenando'),
  nutritionStreak('Racha nutrición', 'Días consecutivos registrando comidas');

  final String label;
  final String description;
  const DashboardTileId(this.label, this.description);
}

/// Configuración de un tile individual
class DashboardTileConfig {
  final DashboardTileId id;
  final bool visible;

  const DashboardTileConfig({required this.id, this.visible = true});

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'visible': visible,
      };

  factory DashboardTileConfig.fromJson(Map<String, dynamic> json) {
    return DashboardTileConfig(
      id: DashboardTileId.values.byName(json['id'] as String),
      visible: json['visible'] as bool? ?? true,
    );
  }

  DashboardTileConfig copyWith({bool? visible}) =>
      DashboardTileConfig(id: id, visible: visible ?? this.visible);
}

/// Configuración completa del dashboard
class DashboardConfig {
  final List<DashboardTileConfig> tiles;

  const DashboardConfig({required this.tiles});

  /// Configuración por defecto
  static const defaultConfig = DashboardConfig(tiles: [
    DashboardTileConfig(id: DashboardTileId.nutrition),
    DashboardTileConfig(id: DashboardTileId.training),
    DashboardTileConfig(id: DashboardTileId.streak),
    DashboardTileConfig(id: DashboardTileId.nutritionStreak),
  ]);

  /// Tiles visibles en orden
  List<DashboardTileConfig> get visibleTiles =>
      tiles.where((t) => t.visible).toList();

  String toJsonString() =>
      jsonEncode(tiles.map((t) => t.toJson()).toList());

  factory DashboardConfig.fromJsonString(String json) {
    final list = (jsonDecode(json) as List)
        .map((e) => DashboardTileConfig.fromJson(e as Map<String, dynamic>))
        .toList();
    // Asegurar que todos los tiles existen (por si se añaden nuevos)
    final existingIds = list.map((t) => t.id).toSet();
    for (final tile in DashboardTileId.values) {
      if (!existingIds.contains(tile)) {
        list.add(DashboardTileConfig(id: tile));
      }
    }
    return DashboardConfig(tiles: list);
  }

  DashboardConfig reorder(int oldIndex, int newIndex) {
    final newTiles = List<DashboardTileConfig>.from(tiles);
    final item = newTiles.removeAt(oldIndex);
    newTiles.insert(newIndex.clamp(0, newTiles.length), item);
    return DashboardConfig(tiles: newTiles);
  }

  DashboardConfig toggleVisibility(DashboardTileId id) {
    final newTiles = tiles.map((t) {
      if (t.id == id) return t.copyWith(visible: !t.visible);
      return t;
    }).toList();
    return DashboardConfig(tiles: newTiles);
  }
}

/// Provider de configuración del dashboard con persistencia
final dashboardConfigProvider =
    NotifierProvider<DashboardConfigNotifier, DashboardConfig>(
  DashboardConfigNotifier.new,
);

class DashboardConfigNotifier extends Notifier<DashboardConfig> {
  static const _key = 'dashboard_config_v1';

  @override
  DashboardConfig build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = prefs.getString(_key);
    if (json != null) {
      try {
        return DashboardConfig.fromJsonString(json);
      } catch (_) {
        return DashboardConfig.defaultConfig;
      }
    }
    return DashboardConfig.defaultConfig;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    state = state.reorder(oldIndex, newIndex);
    await _persist();
  }

  Future<void> toggleVisibility(DashboardTileId id) async {
    state = state.toggleVisibility(id);
    await _persist();
  }

  Future<void> reset() async {
    state = DashboardConfig.defaultConfig;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, state.toJsonString());
  }
}
