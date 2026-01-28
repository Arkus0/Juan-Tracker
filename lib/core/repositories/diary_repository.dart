import 'dart:async';

import '../models/diary_entry.dart';

abstract class DiaryRepository {
  Future<void> add(DiaryEntry e);
  Future<void> update(DiaryEntry e);
  Future<void> delete(String id);
  Future<List<DiaryEntry>> getDay(DateTime date);
  Stream<List<DiaryEntry>> watchDay(DateTime date);
  Future<DailyTotals> totalsForDay(DateTime date);
}

class DailyTotals {
  final int kcal;
  final double? protein;
  final double? carbs;
  final double? fat;

  DailyTotals({required this.kcal, this.protein, this.carbs, this.fat});
}

class InMemoryDiaryRepository implements DiaryRepository {
  final Map<String, DiaryEntry> _store = {};
  final StreamController<List<DiaryEntry>> _controller =
      StreamController.broadcast();

  void _notify() => _controller.add(_store.values.toList());

  @override
  Future<void> add(DiaryEntry e) async {
    _store[e.id] = e;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
    _notify();
  }

  @override
  Future<List<DiaryEntry>> getDay(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    return _store.values
        .where((e) => DateTime(e.date.year, e.date.month, e.date.day) == d)
        .toList();
  }

  @override
  Stream<List<DiaryEntry>> watchDay(DateTime date) {
    // naive implementation: stream of all entries; consumer can filter
    return _controller.stream.map((list) {
      final d = DateTime(date.year, date.month, date.day);
      return list
          .where((e) => DateTime(e.date.year, e.date.month, e.date.day) == d)
          .toList();
    });
  }

  @override
  Future<void> update(DiaryEntry e) async {
    _store[e.id] = e;
    _notify();
  }

  @override
  Future<DailyTotals> totalsForDay(DateTime date) async {
    final entries = await getDay(date);
    final kcal = entries.fold<int>(0, (p, e) => p + e.kcal);
    double prot = 0, carbs = 0, fat = 0;
    for (var e in entries) {
      prot += e.protein ?? 0;
      carbs += e.carbs ?? 0;
      fat += e.fat ?? 0;
    }
    return DailyTotals(
      kcal: kcal,
      protein: prot == 0 ? null : prot,
      carbs: carbs == 0 ? null : carbs,
      fat: fat == 0 ? null : fat,
    );
  }
}
