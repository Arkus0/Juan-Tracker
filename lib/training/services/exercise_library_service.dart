import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_exercise.dart';
import 'exercise_library_storage.dart';

class ExerciseLibraryService {
  static final ExerciseLibraryService instance = ExerciseLibraryService._();
  ExerciseLibraryService._();

  static const _favoritesKey = 'training_favorite_exercises';
  static const _legacyCustomExercisesKey = 'training_custom_exercises';
  static const _imageOverridesKey = 'training_exercise_image_overrides';
  static const _bundlePath = 'assets/data/exercises_local.json';

  final _logger = Logger();
  final ExerciseLibraryStorage _storage = createExerciseLibraryStorage();

  final ValueNotifier<List<LibraryExercise>> exercisesNotifier =
      ValueNotifier<List<LibraryExercise>>([]);

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  List<LibraryExercise> _baseExercises = [];
  List<LibraryExercise> _customExercises = [];
  Set<int> _favoriteIds = <int>{};
  Map<int, String> _imageOverrides = <int, String>{};

  List<LibraryExercise> get exercises => List<LibraryExercise>.from(_all);
  List<LibraryExercise> getExercises() => exercises;

  List<LibraryExercise> get favorites =>
      _all.where((e) => e.isFavorite).toList(growable: false);

  List<LibraryExercise> get customExercises =>
      List<LibraryExercise>.from(_customExercises);

  List<LibraryExercise> get _all => [..._baseExercises, ..._customExercises];

  Future<void> init() async {
    await loadLibrary();
  }

  Future<void> loadLibrary() async {
    try {
      await _loadFavorites();
      _baseExercises = await _loadBundledExercises();
      _customExercises = await _loadCustomExercises();
      await _loadImageOverrides();
      _applyFavorites();
      _applyImageOverrides();
      _isLoaded = true;
      _updateNotifier();
    } catch (e, s) {
      _logger.e('Error loading exercise library', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<LibraryExercise>> _loadBundledExercises() async {
    try {
      final jsonStr = await rootBundle.loadString(_bundlePath);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((entry) {
        final map = Map<String, dynamic>.from(entry as Map);

        // 🆕 IDs numéricos estables desde JSON (schema v2)
        // Si el JSON tiene ID numérico, lo usamos. Si no, fallback al índice.
        final jsonId = map['id'];
        final stableId = jsonId is int ? jsonId : (list.indexOf(entry) + 1);

        // Prefer native keys if present (nuevo formato)
        if (map.containsKey('name') || map.containsKey('muscleGroup')) {
          return LibraryExercise.fromJson(map).copyWith(
            id: stableId,
            isCurated: true,
          );
        }

        // Formato legacy (nombre, grupoMuscular, etc.)
        final name = (map['nombre'] as String?) ?? '';
        final muscleGroup = (map['grupoMuscular'] as String?) ?? '';
        final equipment = (map['equipo'] as String?) ?? '';
        final description = map['descripcion'] as String?;
        final secondary =
            (map['musculosSecundarios'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
        // 🆕 Usar campo muscles si existe, sino fallback a grupoMuscular
        final primary =
            (map['muscles'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            (map['musculosPrincipales'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            (muscleGroup.isNotEmpty ? <String>[muscleGroup] : const <String>[]);

        return LibraryExercise(
          id: stableId,
          name: name,
          muscleGroup: muscleGroup,
          equipment: equipment,
          description: description,
          muscles: primary,
          secondaryMuscles: secondary,
          isCurated: true,
        );
      }).toList();
    } catch (e, s) {
      _logger.w(
        'Failed to load bundled exercises, using fallback',
        error: e,
        stackTrace: s,
      );
      return const <LibraryExercise>[];
    }
  }

  Future<List<LibraryExercise>> _loadCustomExercises() async {
    final raw = await _storage.readCustomJson();
    if (raw == null || raw.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_legacyCustomExercisesKey);
      if (legacy == null || legacy.isEmpty) {
        return const <LibraryExercise>[];
      }
      await _storage.writeCustomJson(legacy);
      return _parseCustomExercises(legacy);
    }

    return _parseCustomExercises(raw);
  }

  List<LibraryExercise> _parseCustomExercises(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => LibraryExercise.fromJson(
              Map<String, dynamic>.from(e as Map),
            ).copyWith(isCurated: false),
          )
          .toList();
    } catch (e, s) {
      _logger.w('Failed to parse custom exercises', error: e, stackTrace: s);
      return const <LibraryExercise>[];
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_favoritesKey) ?? const <String>[];
    _favoriteIds = raw.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  Future<void> _loadImageOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_imageOverridesKey);
    if (raw == null || raw.trim().isEmpty) {
      _imageOverrides = <int, String>{};
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _imageOverrides = <int, String>{};
        return;
      }
      final overrides = <int, String>{};
      for (final entry in decoded.entries) {
        final id = int.tryParse(entry.key);
        final path = entry.value?.toString();
        if (id != null && path != null && path.isNotEmpty) {
          overrides[id] = path;
        }
      }
      _imageOverrides = overrides;
    } catch (_) {
      _imageOverrides = <int, String>{};
    }
  }

  void _applyFavorites() {
    _baseExercises = _baseExercises
        .map((e) => e.copyWith(isFavorite: _favoriteIds.contains(e.id)))
        .toList();
    _customExercises = _customExercises
        .map((e) => e.copyWith(isFavorite: _favoriteIds.contains(e.id)))
        .toList();
  }

  void _applyImageOverrides() {
    if (_imageOverrides.isEmpty) return;

    _baseExercises = _baseExercises.map((e) {
      final override = _imageOverrides[e.id];
      if (override == null || override.isEmpty) return e;
      return e.copyWith(localImagePath: override);
    }).toList();

    _customExercises = _customExercises.map((e) {
      final override = _imageOverrides[e.id];
      if (override == null || override.isEmpty) return e;
      return e.copyWith(localImagePath: override);
    }).toList();
  }

  void _updateNotifier() {
    exercisesNotifier.value = List<LibraryExercise>.from(_all);
  }

  LibraryExercise? getExerciseById(int id) {
    try {
      return _all.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleFavorite(int exerciseId) async {
    if (_favoriteIds.contains(exerciseId)) {
      _favoriteIds.remove(exerciseId);
    } else {
      _favoriteIds.add(exerciseId);
    }
    _applyFavorites();
    _updateNotifier();

    await _persistFavorites();
  }

  Future<void> setExerciseImage({
    required int exerciseId,
    String? localImagePath,
  }) async {
    final customIndex = _customExercises.indexWhere((e) => e.id == exerciseId);
    if (customIndex != -1) {
      final existing = _customExercises[customIndex];
      _customExercises[customIndex] = existing.copyWith(
        localImagePath: localImagePath,
      );
      await _persistCustomExercises();
    } else {
      if (localImagePath == null || localImagePath.isEmpty) {
        _imageOverrides.remove(exerciseId);
        final baseIndex = _baseExercises.indexWhere(
          (e) => e.id == exerciseId,
        );
        if (baseIndex != -1) {
          _baseExercises[baseIndex] = _baseExercises[baseIndex].copyWith(
            localImagePath: null,
          );
        }
      } else {
        _imageOverrides[exerciseId] = localImagePath;
      }
      await _persistImageOverrides();
    }

    _applyFavorites();
    _applyImageOverrides();
    _updateNotifier();
  }

  int _nextCustomId() {
    final allIds = _all.map((e) => e.id).toList()..sort();
    if (allIds.isEmpty) return 1;
    return allIds.last + 1;
  }

  Future<LibraryExercise> addCustomExercise({
    required String name,
    required String muscleGroup,
    required String equipment,
    String? description,
    List<String> muscles = const [],
    List<String> secondaryMuscles = const [],
  }) async {
    final newId = _nextCustomId();
    final newExercise = LibraryExercise(
      id: newId,
      name: name,
      muscleGroup: muscleGroup,
      equipment: equipment,
      description: description,
      muscles: muscles,
      secondaryMuscles: secondaryMuscles,
      isCurated: false,
      isFavorite: _favoriteIds.contains(newId),
    );

    _customExercises = [..._customExercises, newExercise];
    _updateNotifier();
    await _persistCustomExercises();
    return newExercise;
  }

  Future<bool> updateCustomExercise({
    required int exerciseId,
    required String name,
    required String muscleGroup,
    required String equipment,
    String? description,
    List<String> muscles = const [],
    List<String> secondaryMuscles = const [],
  }) async {
    final idx = _customExercises.indexWhere((e) => e.id == exerciseId);
    if (idx == -1) return false;

    final existing = _customExercises[idx];
    _customExercises[idx] = existing.copyWith(
      name: name,
      muscleGroup: muscleGroup,
      equipment: equipment,
      description: description,
      muscles: muscles,
      secondaryMuscles: secondaryMuscles,
    );

    _updateNotifier();
    await _persistCustomExercises();
    return true;
  }

  Future<bool> deleteCustomExercise(int exerciseId) async {
    final idx = _customExercises.indexWhere((e) => e.id == exerciseId);
    if (idx == -1) return false;

    _customExercises.removeAt(idx);
    _favoriteIds.remove(exerciseId);
    _applyFavorites();
    _updateNotifier();
    await _persistCustomExercises();
    await _persistFavorites();
    return true;
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      _favoriteIds.map((e) => e.toString()).toList(),
    );
  }

  Future<void> _persistImageOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, String>{
      for (final entry in _imageOverrides.entries)
        entry.key.toString(): entry.value,
    };
    await prefs.setString(_imageOverridesKey, jsonEncode(map));
  }

  Future<void> _persistCustomExercises() async {
    final encoded = jsonEncode(
      _customExercises.map((e) => e.toJson()).toList(),
    );
    await _storage.writeCustomJson(encoded);
  }

  void dispose() {
    exercisesNotifier.dispose();
  }
}
