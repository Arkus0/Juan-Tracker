import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/providers/weekly_insights_provider.dart';

void main() {
  group('WeeklyInsight', () {
    test('debe crear instancia correctamente', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 2, 3),
        weekEnd: DateTime(2026, 2, 9),
        daysLogged: 5,
        totalKcal: 10500,
        avgKcalPerDay: 2100,
        targetKcal: 2000,
        adherencePercentage: 0.80,
        avgDeviationKcal: 100,
        avgProtein: 120.0,
        avgCarbs: 250.0,
        avgFat: 70.0,
        kcalChangeVsLastWeek: -150,
      );

      expect(insight.daysLogged, 5);
      expect(insight.totalKcal, 10500);
      expect(insight.avgKcalPerDay, 2100);
      expect(insight.avgProtein, 120.0);
      expect(insight.avgCarbs, 250.0);
      expect(insight.avgFat, 70.0);
      expect(insight.adherencePercentage, 0.80);
      expect(insight.kcalChangeVsLastWeek, -150);
    });

    test('adherenceMessage devuelve "Excelente" para >=80%', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 1, 1),
        weekEnd: DateTime(2026, 1, 7),
        daysLogged: 7,
        totalKcal: 14000,
        avgKcalPerDay: 2000,
        targetKcal: 2000, // Requerido para calcular adherencia
        adherencePercentage: 85,
        avgDeviationKcal: 0,
        avgProtein: 100.0,
        avgCarbs: 200.0,
        avgFat: 60.0,
      );

      expect(insight.adherenceMessage, contains('Excelente'));
    });

    test('adherenceMessage devuelve "Bueno" para 60-79%', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 1, 1),
        weekEnd: DateTime(2026, 1, 7),
        daysLogged: 7,
        totalKcal: 14000,
        avgKcalPerDay: 2000,
        targetKcal: 2000,
        adherencePercentage: 70,
        avgDeviationKcal: 0,
        avgProtein: 100.0,
        avgCarbs: 200.0,
        avgFat: 60.0,
      );

      expect(insight.adherenceMessage, contains('Bueno'));
    });

    test('adherenceMessage devuelve "Mejorable" para 40-59%', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 1, 1),
        weekEnd: DateTime(2026, 1, 7),
        daysLogged: 7,
        totalKcal: 14000,
        avgKcalPerDay: 2000,
        targetKcal: 2000,
        adherencePercentage: 45,
        avgDeviationKcal: 0,
        avgProtein: 100.0,
        avgCarbs: 200.0,
        avgFat: 60.0,
      );

      expect(insight.adherenceMessage, contains('Mejorable'));
    });

    test('adherenceMessage devuelve "A trabajar" para <40%', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 1, 1),
        weekEnd: DateTime(2026, 1, 7),
        daysLogged: 7,
        totalKcal: 14000,
        avgKcalPerDay: 2000,
        targetKcal: 2000,
        adherencePercentage: 30,
        avgDeviationKcal: 0,
        avgProtein: 100.0,
        avgCarbs: 200.0,
        avgFat: 60.0,
      );

      expect(insight.adherenceMessage, contains('A trabajar'));
    });

    test('adherenceMessage devuelve "Sin objetivo" cuando targetKcal es null', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 1, 1),
        weekEnd: DateTime(2026, 1, 7),
        daysLogged: 7,
        totalKcal: 14000,
        avgKcalPerDay: 2000,
        targetKcal: null,
        adherencePercentage: 0.50,
        avgDeviationKcal: 0,
        avgProtein: 100.0,
        avgCarbs: 200.0,
        avgFat: 60.0,
      );

      expect(insight.adherenceMessage, 'Sin objetivo');
    });

    test('kcalChangeVsLastWeek puede ser null', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 1, 1),
        weekEnd: DateTime(2026, 1, 7),
        daysLogged: 7,
        totalKcal: 14000,
        avgKcalPerDay: 2000,
        adherencePercentage: 50,
        avgDeviationKcal: 0,
        avgProtein: 100.0,
        avgCarbs: 200.0,
        avgFat: 60.0,
        kcalChangeVsLastWeek: null,
      );

      expect(insight.kcalChangeVsLastWeek, isNull);
    });

    test('adherenceColorIndex retorna índice correcto', () {
      // >= 80% -> 0 (verde)
      expect(
        WeeklyInsight(
          weekStart: DateTime(2026, 1, 1),
          weekEnd: DateTime(2026, 1, 7),
          daysLogged: 7,
          totalKcal: 14000,
          avgKcalPerDay: 2000,
          adherencePercentage: 85,
          avgDeviationKcal: 0,
          avgProtein: 100.0,
          avgCarbs: 200.0,
          avgFat: 60.0,
        ).adherenceColorIndex,
        0,
      );

      // >= 60% -> 1 (azul)
      expect(
        WeeklyInsight(
          weekStart: DateTime(2026, 1, 1),
          weekEnd: DateTime(2026, 1, 7),
          daysLogged: 7,
          totalKcal: 14000,
          avgKcalPerDay: 2000,
          adherencePercentage: 65,
          avgDeviationKcal: 0,
          avgProtein: 100.0,
          avgCarbs: 200.0,
          avgFat: 60.0,
        ).adherenceColorIndex,
        1,
      );

      // >= 40% -> 2 (naranja)
      expect(
        WeeklyInsight(
          weekStart: DateTime(2026, 1, 1),
          weekEnd: DateTime(2026, 1, 7),
          daysLogged: 7,
          totalKcal: 14000,
          avgKcalPerDay: 2000,
          adherencePercentage: 45,
          avgDeviationKcal: 0,
          avgProtein: 100.0,
          avgCarbs: 200.0,
          avgFat: 60.0,
        ).adherenceColorIndex,
        2,
      );

      // < 40% -> 3 (rojo)
      expect(
        WeeklyInsight(
          weekStart: DateTime(2026, 1, 1),
          weekEnd: DateTime(2026, 1, 7),
          daysLogged: 7,
          totalKcal: 14000,
          avgKcalPerDay: 2000,
          adherencePercentage: 30,
          avgDeviationKcal: 0,
          avgProtein: 100.0,
          avgCarbs: 200.0,
          avgFat: 60.0,
        ).adherenceColorIndex,
        3,
      );
    });
  });

  group('WeeklyInsight edge cases', () {
    test('daysLogged puede ser 0', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 1, 1),
        weekEnd: DateTime(2026, 1, 7),
        daysLogged: 0,
        totalKcal: 0,
        avgKcalPerDay: 0,
        adherencePercentage: 0,
        avgDeviationKcal: 0,
        avgProtein: 0.0,
        avgCarbs: 0.0,
        avgFat: 0.0,
      );

      expect(insight.daysLogged, 0);
    });

    test('kcalChangeVsLastWeek positivo indica aumento', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 1, 8),
        weekEnd: DateTime(2026, 1, 14),
        daysLogged: 7,
        totalKcal: 15400,
        avgKcalPerDay: 2200,
        adherencePercentage: 75,
        avgDeviationKcal: 200,
        avgProtein: 110.0,
        avgCarbs: 220.0,
        avgFat: 65.0,
        kcalChangeVsLastWeek: 200,
      );

      expect(insight.kcalChangeVsLastWeek, isPositive);
    });

    test('kcalChangeVsLastWeek negativo indica reducción', () {
      final insight = WeeklyInsight(
        weekStart: DateTime(2026, 1, 15),
        weekEnd: DateTime(2026, 1, 21),
        daysLogged: 6,
        totalKcal: 11400,
        avgKcalPerDay: 1900,
        adherencePercentage: 65,
        avgDeviationKcal: -100,
        avgProtein: 95.0,
        avgCarbs: 180.0,
        avgFat: 55.0,
        kcalChangeVsLastWeek: -300,
      );

      expect(insight.kcalChangeVsLastWeek, isNegative);
    });

    test('isCurrentWeek detecta semana actual', () {
      final now = DateTime.now();
      // Calcular inicio de semana actual (lunes)
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final insight = WeeklyInsight(
        weekStart: DateTime(weekStart.year, weekStart.month, weekStart.day),
        weekEnd: DateTime(weekEnd.year, weekEnd.month, weekEnd.day),
        daysLogged: now.weekday,
        totalKcal: 2000 * now.weekday,
        avgKcalPerDay: 2000,
        adherencePercentage: 80,
        avgDeviationKcal: 0,
        avgProtein: 100.0,
        avgCarbs: 200.0,
        avgFat: 60.0,
      );

      expect(insight.isCurrentWeek, isTrue);
    });
  });
}
