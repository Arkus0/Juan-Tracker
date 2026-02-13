import 'package:flutter_riverpod/flutter_riverpod.dart';

final greetingProvider = Provider<String>((ref) {
  return 'Hello';
});

/// Navigation tabs for the Nutrition HomeScreen.
///
/// Reduced from 5 tabs (diary, weight, summary, coach, profile) to 3.
/// Weight + Summary + Coach are consolidated into "progress" tab
/// with internal SegmentedButton (see ProgressScreen).
enum HomeTab {
  diary,
  progress,
  profile;
}

class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.diary;

  void setTab(HomeTab tab) => state = tab;
  void goToCoach() => state = HomeTab.progress;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, HomeTab>(
  HomeTabNotifier.new,
);
