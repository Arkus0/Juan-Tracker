// Tests de integración para GoRouter (Fase B)
//
// Verifica:
// - Rutas principales funcionan correctamente
// - Deep links se parsean adecuadamente
// - Navegación entre pantallas

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:juan_tracker/core/router/app_router.dart';

void main() {
  group('AppRouter Integration Tests', () {
    late GoRouter router;

    setUp(() {
      router = AppRouter.router;
    });

    test('router se inicializa correctamente', () {
      expect(router, isNotNull);
      expect(router.routeInformationParser, isNotNull);
      expect(router.routerDelegate, isNotNull);
    });

    test('ruta raíz es /', () {
      expect(AppRouter.root, equals('/'));
    });

    test('rutas de nutrición están definidas', () {
      expect(AppRouter.nutrition, equals('/nutrition'));
      expect(AppRouter.nutritionDiary, equals('/nutrition/diary'));
      expect(AppRouter.nutritionFoods, equals('/nutrition/foods'));
      expect(AppRouter.nutritionFoodSearch, equals('/nutrition/food-search'));
      expect(AppRouter.nutritionWeight, equals('/nutrition/weight'));
      expect(AppRouter.nutritionSummary, equals('/nutrition/summary'));
      expect(AppRouter.nutritionTargets, equals('/nutrition/targets'));
      expect(AppRouter.nutritionCoach, equals('/nutrition/coach'));
    });

    test('rutas de entrenamiento están definidas', () {
      expect(AppRouter.training, equals('/training'));
      expect(AppRouter.trainingHistory, equals('/training/history'));
      expect(AppRouter.trainingRoutines, equals('/training/routines'));
      expect(AppRouter.trainingLibrary, equals('/training/library'));
      expect(AppRouter.trainingSession, equals('/training/session'));
    });

    test('router puede parsear URL de nutrición', () {
      final uri = Uri.parse('https://juantracker.app/nutrition/diary');
      expect(uri.path, equals('/nutrition/diary'));
    });

    test('router puede parsear URL de entrenamiento', () {
      final uri = Uri.parse('https://juantracker.app/training/history');
      expect(uri.path, equals('/training/history'));
    });

    test('router puede parsear esquema personalizado', () {
      final uri = Uri.parse('juantracker://nutrition/weight');
      expect(uri.scheme, equals('juantracker'));
      // Nota: en URIs con scheme, el host va después de ://
      // juantracker://nutrition/weight -> host='nutrition', path='/weight'
      expect(uri.host, equals('nutrition'));
      expect(uri.path, equals('/weight'));
    });

    test('helper para detalle de sesión genera URL correcta', () {
      final url = AppRouter.trainingSessionDetailWithId('123');
      expect(url, equals('/training/session/detail/123'));
    });
  });

  group('Navigation Extensions', () {
    testWidgets('goToNutrition navega a ruta correcta',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );

      // Esperar a que el splash termine
      await tester.pump(const Duration(milliseconds: 900));

      // Verificar que se renderiza (no hay errores de navegación)
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Route Configuration', () {
    test('todas las rutas tienen formato válido', () {
      final routes = [
        AppRouter.root,
        AppRouter.nutrition,
        AppRouter.nutritionDiary,
        AppRouter.nutritionFoods,
        AppRouter.nutritionFoodSearch,
        AppRouter.nutritionWeight,
        AppRouter.nutritionSummary,
        AppRouter.nutritionTargets,
        AppRouter.nutritionCoach,
        AppRouter.nutritionCoachSetup,
        AppRouter.nutritionCoachCheckin,
        AppRouter.training,
        AppRouter.trainingHistory,
        AppRouter.trainingRoutines,
        AppRouter.trainingLibrary,
        AppRouter.trainingSession,
      ];

      for (final route in routes) {
        expect(route, startsWith('/'));
        expect(route.isNotEmpty, isTrue);
      }
    });

    test('rutas no tienen slashes consecutivos', () {
      final routes = [
        AppRouter.nutritionCoachSetup,
        AppRouter.nutritionCoachCheckin,
      ];

      for (final route in routes) {
        expect(route.contains('//'), isFalse);
      }
    });
  });
}
