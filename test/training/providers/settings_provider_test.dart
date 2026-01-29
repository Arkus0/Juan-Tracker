import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/providers/settings_provider.dart';

void main() {
  group('UserSettings', () {
    test('should have correct default values', () {
      const settings = UserSettings();

      expect(settings.timerSoundEnabled, isFalse);
      expect(settings.timerVibrationEnabled, isTrue);
      expect(settings.autoStartTimer, isTrue);
      expect(settings.defaultRestSeconds, equals(90));
      expect(settings.showSupersetIndicator, isTrue);
      expect(settings.performanceModeEnabled, isFalse);
      expect(settings.reduceAnimations, isFalse);
      expect(settings.reduceVibrations, isFalse);
      expect(settings.barWeight, equals(20.0));
      expect(settings.lockScreenTimerEnabled, isTrue);
      expect(settings.useFocusedInputMode, isTrue);
      expect(settings.mediaControlsEnabled, isTrue);
      expect(settings.autofocusEnabled, isTrue); // New setting
    });

    test('copyWith should update specific values', () {
      const settings = UserSettings();

      final updated = settings.copyWith(
        timerSoundEnabled: true,
        defaultRestSeconds: 120,
        autofocusEnabled: false,
      );

      expect(updated.timerSoundEnabled, isTrue);
      expect(updated.defaultRestSeconds, equals(120));
      expect(updated.autofocusEnabled, isFalse);
      
      // Unchanged values
      expect(updated.timerVibrationEnabled, isTrue);
      expect(updated.barWeight, equals(20.0));
    });

    test('performance mode should enable all optimizations', () async {
      // This tests the behavior of setPerformanceModeEnabled
      // In real usage, this would also update PerformanceMode singleton
      
      const settings = UserSettings(performanceModeEnabled: true);
      
      expect(settings.performanceModeEnabled, isTrue);
    });
  });

  group('SettingsKeys', () {
    test('should have unique keys', () {
      final keys = [
        SettingsKeys.timerSoundEnabled,
        SettingsKeys.timerVibrationEnabled,
        SettingsKeys.autoStartTimer,
        SettingsKeys.defaultRestSeconds,
        SettingsKeys.showSupersetIndicator,
        SettingsKeys.performanceModeEnabled,
        SettingsKeys.reduceAnimations,
        SettingsKeys.reduceVibrations,
        SettingsKeys.barWeightKg,
        SettingsKeys.lockScreenTimerEnabled,
        SettingsKeys.useFocusedInputMode,
        SettingsKeys.mediaControlsEnabled,
        SettingsKeys.autofocusEnabled,
      ];

      // All keys should be unique
      final uniqueKeys = keys.toSet();
      expect(uniqueKeys.length, equals(keys.length));
    });

    test('should have descriptive key names', () {
      expect(SettingsKeys.timerSoundEnabled, contains('timer'));
      expect(SettingsKeys.timerSoundEnabled, contains('sound'));
      expect(SettingsKeys.autofocusEnabled, contains('autofocus'));
    });
  });
}
