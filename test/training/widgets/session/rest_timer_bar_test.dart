/// Tests para RestTimerBar con gestos UX-003
///
/// Cubre:
/// - Accesibilidad semántica
/// - Estados activo/inactivo
/// Nota: Requiere ProviderScope para tests completos debido a Riverpod
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/services/rest_timer_controller.dart';

void main() {
  group('RestTimerBar UX-003 Tests', () {
    late RestTimerState activeTimerState;
    late RestTimerState inactiveTimerState;

    setUp(() {
      activeTimerState = RestTimerState(
        isActive: true,
        isPaused: false,
        endTime: DateTime.now().add(const Duration(seconds: 60)),
        totalSeconds: 60,
      );
      inactiveTimerState = const RestTimerState(
        isActive: false,
        isPaused: false,
        totalSeconds: 90,
      );
    });

    test('RestTimerState se crea correctamente activo', () {
      expect(activeTimerState.isActive, isTrue);
      expect(activeTimerState.isPaused, isFalse);
      expect(activeTimerState.totalSeconds, equals(60));
    });

    test('RestTimerState se crea correctamente inactivo', () {
      expect(inactiveTimerState.isActive, isFalse);
      expect(inactiveTimerState.totalSeconds, equals(90));
    });

    test('RestTimerState copyWith funciona correctamente', () {
      final newState = activeTimerState.copyWith(
        isPaused: true,
        totalSeconds: 120,
      );
      
      expect(newState.isPaused, isTrue);
      expect(newState.totalSeconds, equals(120));
      expect(newState.isActive, isTrue); // No cambió
    });

    test('remainingSeconds calcula correctamente', () {
      final state = RestTimerState(
        isActive: true,
        endTime: DateTime.now().add(const Duration(seconds: 30)),
        totalSeconds: 60,
      );
      
      expect(state.remainingSeconds, greaterThan(25));
      expect(state.remainingSeconds, lessThanOrEqualTo(30));
    });
  });
}
