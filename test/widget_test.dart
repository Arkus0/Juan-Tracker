import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:juan_tracker/app.dart';

void main() {
  testWidgets('Home shows greeting', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: JuanTrackerApp()));

    expect(find.text('Juan Tracker'), findsOneWidget);
  });
}
