import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_exercise.dart';
import 'exercise_repository.dart';

class LocalExerciseRepository implements ExerciseRepository {
  static const _customKey = 'custom_exercises_v1';

  final StreamController<List<TrainingExercise>> _controller =
      StreamController<List<TrainingExercise>>.broadcast();
  bool _loaded = false;
  List<TrainingExercise> _seed = [];
  List<TrainingExercise> _custom = [];

  @override
  Stream<List<TrainingExercise>> watchAll() {
    _ensureLoaded();
    return _controller.stream;
  }

  @override
  Future<List<TrainingExercise>> getAll() async {
    await _ensureLoaded();
    return List.unmodifiable([..._seed, ..._custom]);
  }

  @override
  Future<void> addExercise(TrainingExercise exercise) async {
    await _ensureLoaded();
    _custom.removeWhere((e) => e.id == exercise.id);
    _custom.add(exercise);
    await _persistCustom();
    _emit();
  }

  @override
  Future<void> deleteExercise(String id) async {
    await _ensureLoaded();
    _custom.removeWhere((e) => e.id == id);
    await _persistCustom();
    _emit();
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    _seed = await _loadSeed();
    _custom = await _loadCustom();
    _emit();
  }

  Future<List<TrainingExercise>> _loadSeed() async {
    final raw = await rootBundle.loadString('assets/data/exercises_local.json');
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .map(
          (e) => TrainingExercise.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<List<TrainingExercise>> _loadCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .map(
          (e) => TrainingExercise.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> _persistCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(_custom.map((e) => e.toMap()).toList());
    await prefs.setString(_customKey, raw);
  }

  void _emit() {
    final snapshot = List<TrainingExercise>.unmodifiable([
      ..._seed,
      ..._custom,
    ]);
    _controller.add(snapshot);
  }

  void dispose() {
    _controller.close();
  }
}
