/// Tests para sistema de celebraciones UX-004
///
/// Cubre:
/// - Confetti animation
/// - Scale animation para completar series
/// - Controller de celebraciones
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/core/widgets/celebration_overlay.dart';

void main() {
  group('CelebrationController Tests', () {
    late CelebrationController controller;

    setUp(() {
      controller = CelebrationController();
    });

    test('controller es singleton', () {
      final controller2 = CelebrationController();
      expect(identical(controller, controller2), isTrue);
    });
  });

  group('AnimatedCompleteCheckbox Tests', () {
    testWidgets('checkbox muestra estado completado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCompleteCheckbox(
              isCompleted: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCompleteCheckbox), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('checkbox muestra estado no completado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCompleteCheckbox(
              isCompleted: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCompleteCheckbox), findsOneWidget);
      
      // Verificar que el checkbox tiene valor false
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });

    testWidgets('onChanged se ejecuta al tocar', (tester) async {
      var changed = false;
      bool? newValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedCompleteCheckbox(
              isCompleted: false,
              onChanged: (value) {
                changed = true;
                newValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(changed, isTrue);
      expect(newValue, isTrue);
    });
  });
}
