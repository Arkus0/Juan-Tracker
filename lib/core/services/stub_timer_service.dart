import 'dart:async';

import 'i_timer_service.dart';

class StubTimerService implements ITimerService {
  final StreamController<int> _controller = StreamController<int>.broadcast();

  @override
  Stream<int> get remaining$ => _controller.stream;

  @override
  void start(int seconds) {
    _controller.add(seconds);
  }

  @override
  void stop() {
    _controller.add(0);
  }

  void dispose() {
    _controller.close();
  }
}
