import 'dart:async';

import '../models/food.dart';

abstract class FoodRepository {
  Future<List<Food>> getAll();
  Stream<List<Food>> watchAll();
  Future<Food?> getById(String id);
  Future<void> add(Food food);
  Future<void> update(Food food);
  Future<void> delete(String id);
  Future<List<Food>> searchByNameOrBrand(String q);
  Future<Food?> lookupByBarcode(String barcode);
}

class InMemoryFoodRepository implements FoodRepository {
  final Map<String, Food> _store = {};
  final StreamController<List<Food>> _controller = StreamController.broadcast();

  InMemoryFoodRepository([List<Food>? seeds]) {
    if (seeds != null) {
      for (var f in seeds) {
        _store[f.id] = f;
      }
    }
    _notify();
  }

  void _notify() => _controller.add(_store.values.toList());

  @override
  Future<void> add(Food food) async {
    _store[food.id] = food;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _notify();
  }

  @override
  Future<List<Food>> getAll() async => _store.values.toList();

  @override
  Future<Food?> getById(String id) async => _store[id];

  @override
  Future<void> update(Food food) async {
    _store[food.id] = food;
    _notify();
  }

  @override
  Stream<List<Food>> watchAll() => _controller.stream;

  @override
  Future<List<Food>> searchByNameOrBrand(String q) async {
    final ql = q.toLowerCase();
    return _store.values.where((f) => f.name.toLowerCase().contains(ql) || (f.brand?.toLowerCase().contains(ql) ?? false)).toList();
  }

  @override
  Future<Food?> lookupByBarcode(String barcode) async {
    for (var f in _store.values) {
      if (f.barcode != null && f.barcode == barcode) return f;
    }
    return null;
  }
}
