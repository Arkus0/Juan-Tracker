import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/features/foods/widgets/search_empty_state.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('SearchEmptyState', () {
    testWidgets('disables actions while busy', (tester) async {
      var barcodeTapped = false;

      await tester.pumpWidget(
        _wrap(
          SearchEmptyState(
            query: 'arroz',
            isBusy: true,
            onManualAdd: () {},
            onVoiceInput: () {},
            onOcrScan: () {},
            onBarcodeScan: () => barcodeTapped = true,
            onSearchOnline: () {},
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byTooltip('Barcode'));
      await tester.pumpAndSettle();

      expect(barcodeTapped, isFalse);
    });

    testWidgets('triggers barcode action when enabled', (tester) async {
      var barcodeTapped = false;

      await tester.pumpWidget(
        _wrap(
          SearchEmptyState(
            onManualAdd: () {},
            onVoiceInput: () {},
            onOcrScan: () {},
            onBarcodeScan: () => barcodeTapped = true,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Barcode'));
      await tester.pumpAndSettle();

      expect(barcodeTapped, isTrue);
    });
  });
}
