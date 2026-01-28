import 'dart:async';

import '../models/weight_entry.dart';

abstract class WeightRepository {
  Future<void> add(WeightEntry e);
  Future<void> update(WeightEntry e);
  Future<void> delete(String id);
  Stream<List<WeightEntry>> watchRange(DateTime from, DateTime to);
  Future<WeightEntry?> latest();
}

class InMemoryWeightRepository implements WeightRepository {
  final Map<String, WeightEntry> _store = {};
  final StreamController<List<WeightEntry>> _controller =
      StreamController.broadcast();

  void _notify() => _controller.add(_store.values.toList());

  @override
  Future<void> add(WeightEntry e) async {
    _store[e.id] = e;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _notify();
  }

  @override
  Future<WeightEntry?> latest() async {
    if (_store.isEmpty) return null;
    final list = _store.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list.first;
  }

  @override
  Stream<List<WeightEntry>> watchRange(DateTime from, DateTime to) {
    return _controller.stream.map(
      (list) => list
          .where((e) => e.date.isAfter(from) && e.date.isBefore(to))
          .toList(),
    );
  }

  @override
  Future<void> update(WeightEntry e) async {
    _store[e.id] = e;
    _notify();
  }
}
