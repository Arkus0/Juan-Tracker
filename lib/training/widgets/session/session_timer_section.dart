import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/focus_manager_provider.dart';
import '../../providers/timer_focus_provider.dart';
import '../../providers/training_provider.dart';
import '../common/floating_timer_overlay.dart';

/// MD-001: Sección de Timer aislada para evitar rebuilds de la pantalla completa
///
/// Este widget ConsumerWidget aísla todo el estado del timer del resto de la
/// pantalla de entrenamiento. Cuando el timer actualiza (cada 100ms), solo
/// este widget se reconstruye, no toda la TrainingSessionScreen.
///
/// Ahora envuelve el contenido como overlay flotante en lugar de ser
/// parte del Column (evita empujar el contenido).
class SessionTimerSection extends ConsumerWidget {
  final Widget child;
  const SessionTimerSection({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restTimerState = ref.watch(
      trainingSessionProvider.select((s) => s.restTimer),
    );
    final showTimerBar = ref.watch(
      trainingSessionProvider.select((s) => s.showTimerBar),
    );

    final notifier = ref.read(trainingSessionProvider.notifier);

    void onTimerFinished({int? lastExerciseIndex, int? lastSetIndex}) {
      final state = ref.read(trainingSessionProvider);
      final nextSet = state.nextIncompleteSet;

      if (nextSet != null) {
        ref
            .read(focusManagerProvider.notifier)
            .requestFocus(
              exerciseIndex: nextSet.exerciseIndex,
              setIndex: nextSet.setIndex,
            );

        ref.read(timerFinishedFocusProvider.notifier).setFocus(nextSet);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 150), () {
            ref.read(timerFinishedFocusProvider.notifier).clear();
            ref.read(focusManagerProvider.notifier).clearFocus();
          });
        });
      }
    }

    return RepaintBoundary(
      child: FloatingTimerOverlay(
        timerState: restTimerState,
        showInactiveBar: showTimerBar,
        onStartRest: (seconds) {
          notifier.setRestDuration(seconds);
          notifier.startRest();
        },
        onStopRest: notifier.stopRest,
        onPauseRest: notifier.pauseRest,
        onResumeRest: notifier.resumeRest,
        onDurationChange: notifier.setRestDuration,
        onAddTime: notifier.addRestTime,
        onTimerFinished: onTimerFinished,
        onRestartRest: notifier.restartRest,
        child: child,
      ),
    );
  }
}
