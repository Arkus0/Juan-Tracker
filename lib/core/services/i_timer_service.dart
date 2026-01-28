abstract class ITimerService {
  void start(int seconds);
  void stop();
  Stream<int> get remaining$;
}
