import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/features/foods/widgets/input_method_fab.dart';

void main() {
  group('InputMethodFab', () {
    testWidgets('does not expand while busy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: InputMethodFab(
              isBusy: true,
              onManualAdd: () {},
              onVoiceInput: () {},
              onOcrScan: () {},
              onBarcodeScan: () {},
            ),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.onPressed, isNull);
    });

    testWidgets('invokes barcode callback when expanded and tapped', (
      tester,
    ) async {
      var barcodeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: InputMethodFab(
              onManualAdd: () {},
              onVoiceInput: () {},
              onOcrScan: () {},
              onBarcodeScan: () => barcodeTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Escanear barcode'));
      await tester.pumpAndSettle();

      expect(barcodeTapped, isTrue);
    });
  });
}
