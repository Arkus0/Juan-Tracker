import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para comunicar el auto-focus cuando el timer termina
/// (Mantenido para compatibilidad, ahora usa FocusManagerProvider internamente)
final timerFinishedFocusProvider =
    NotifierProvider<
      TimerFinishedFocusNotifier,
      ({int exerciseIndex, int setIndex})?
    >(TimerFinishedFocusNotifier.new);

class TimerFinishedFocusNotifier
    extends Notifier<({int exerciseIndex, int setIndex})?> {
  @override
  ({int exerciseIndex, int setIndex})? build() => null;

  void setFocus(({int exerciseIndex, int setIndex})? focus) {
    state = focus;
  }

  void clear() {
    state = null;
  }
}
