import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:juan_tracker/app.dart';

void main() {
  testWidgets('App launches with MaterialApp.router', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: JuanTrackerApp()));
    
    // Dejar que el SplashWrapper complete su animación inicial
    // Usamos pump con duración en lugar de pumpAndSettle para evitar
    // timeouts con timers del SplashWrapper
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 800)); // Duración del timer del splash
    
    // Verifica que se crea un MaterialApp (con router)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
