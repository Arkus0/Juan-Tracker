import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SummarySection { weeklyTrends, tdeeTrend, breakdown, dayStatus }

class SummarySectionsState {
  final Map<SummarySection, bool> expanded;

  const SummarySectionsState({required this.expanded});

  bool isExpanded(SummarySection section) => expanded[section] ?? false;

  bool get allExpanded => expanded.values.every((value) => value);
  bool get anyExpanded => expanded.values.any((value) => value);

  SummarySectionsState copyWith({Map<SummarySection, bool>? expanded}) {
    return SummarySectionsState(expanded: expanded ?? this.expanded);
  }
}

class SummarySectionsNotifier extends Notifier<SummarySectionsState> {
  static const _keyPrefix = 'summary_section_';

  @override
  SummarySectionsState build() {
    final initial = SummarySectionsState(
      expanded: {
        SummarySection.weeklyTrends: false,
        SummarySection.tdeeTrend: false,
        SummarySection.breakdown: false,
        SummarySection.dayStatus: false,
      },
    );
    Future.microtask(_load);
    return initial;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final updated = Map<SummarySection, bool>.from(state.expanded);
    for (final section in SummarySection.values) {
      final stored = prefs.getBool(_key(section));
      if (stored != null) {
        updated[section] = stored;
      }
    }
    state = state.copyWith(expanded: updated);
  }

  Future<void> toggle(SummarySection section) async {
    final current = state.isExpanded(section);
    await setExpanded(section, !current);
  }

  Future<void> setExpanded(SummarySection section, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(section), value);
    final updated = Map<SummarySection, bool>.from(state.expanded)
      ..[section] = value;
    state = state.copyWith(expanded: updated);
  }

  Future<void> setAll(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = <SummarySection, bool>{};
    for (final section in SummarySection.values) {
      await prefs.setBool(_key(section), value);
      updated[section] = value;
    }
    state = state.copyWith(expanded: updated);
  }

  String _key(SummarySection section) {
    return '$_keyPrefix${section.name}_expanded';
  }
}

final summarySectionsProvider =
    NotifierProvider<SummarySectionsNotifier, SummarySectionsState>(
  SummarySectionsNotifier.new,
);
