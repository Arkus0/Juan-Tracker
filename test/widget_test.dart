import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:juan_tracker/app.dart';

void main() {
  testWidgets('App launches with MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: JuanTrackerApp()));
    await tester.pump();

    // Verifica que se crea un MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
