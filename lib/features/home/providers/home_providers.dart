import 'package:flutter_riverpod/flutter_riverpod.dart';

final greetingProvider = Provider<String>((ref) {
  return 'Hello';
});

enum HomeTab { diary, weight, summary, coach, profile }

class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.diary;

  void setTab(HomeTab tab) => state = tab;
  void goToCoach() => state = HomeTab.coach;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, HomeTab>(
  HomeTabNotifier.new,
);
