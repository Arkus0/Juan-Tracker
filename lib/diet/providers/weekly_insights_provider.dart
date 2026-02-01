/// Providers para Weekly History Insights (resumen histórico semanal)
///
/// Proporciona datos agregados por semana para análisis de adherencia,
/// tendencias y comparación semana vs semana.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/database_provider.dart';
import 'coach_providers.dart';
import 'summary_providers.dart';

// ============================================================================
// MODELO
// ============================================================================

/// Resumen de una semana completa
class WeeklyInsight {
  /// Fecha de inicio de la semana (lunes)
  final DateTime weekStart;

  /// Fecha de fin de la semana (domingo)
  final DateTime weekEnd;

  /// Número de días con registros
  final int daysLogged;

  /// Total de calorías consumidas en la semana
  final int totalKcal;

  /// Promedio diario de calorías (solo días con registro)
  final int avgKcalPerDay;

  /// Objetivo de calorías diarias (de CoachPlan)
  final int? targetKcal;

  /// Porcentaje de adherencia (días dentro del ±10% del objetivo)
  final double adherencePercentage;

  /// Desviación promedio del objetivo en kcal
  final int avgDeviationKcal;

  /// Macros promedio
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;

  /// Diferencia con la semana anterior
  final int? kcalChangeVsLastWeek;

  const WeeklyInsight({
    required this.weekStart,
    required this.weekEnd,
    required this.daysLogged,
    required this.totalKcal,
    required this.avgKcalPerDay,
    this.targetKcal,
    required this.adherencePercentage,
    required this.avgDeviationKcal,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    this.kcalChangeVsLastWeek,
  });

  /// Etiqueta de la semana (ej: "27 Ene - 2 Feb")
  String get weekLabel {
    final startStr = DateFormat('d MMM', 'es').format(weekStart);
    final endStr = DateFormat('d MMM', 'es').format(weekEnd);
    return '$startStr - $endStr';
  }

  /// ¿Es la semana actual?
  bool get isCurrentWeek {
    final now = DateTime.now();
    return now.isAfter(weekStart) && now.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  /// Mensaje de adherencia
  String get adherenceMessage {
    if (targetKcal == null) return 'Sin objetivo';
    if (adherencePercentage >= 80) return 'Excelente 🎯';
    if (adherencePercentage >= 60) return 'Bueno 👍';
    if (adherencePercentage >= 40) return 'Mejorable 📈';
    return 'A trabajar 💪';
  }

  /// Color de adherencia (índice para UI)
  int get adherenceColorIndex {
    if (adherencePercentage >= 80) return 0; // Verde
    if (adherencePercentage >= 60) return 1; // Azul
    if (adherencePercentage >= 40) return 2; // Naranja
    return 3; // Rojo
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider que calcula insights semanales
/// Retorna las últimas 4 semanas
final weeklyInsightsProvider = FutureProvider<List<WeeklyInsight>>((ref) async {
  final diaryRepo = ref.watch(diaryRepositoryProvider);
  final coachPlan = ref.read(coachPlanProvider);
  final calculator = ref.read(daySummaryCalculatorProvider);

  final now = DateTime.now();
  final results = <WeeklyInsight>[];

  // Calcular target desde CoachPlan
  int? targetKcal;
  if (coachPlan != null) {
    targetKcal = calculator.calculateTDEEFromCoachPlan(coachPlan).round();
  }

  // Obtener inicio de la semana actual (lunes)
  final todayWeekday = now.weekday; // 1 = lunes, 7 = domingo
  final currentWeekStart = DateTime(
    now.year,
    now.month,
    now.day - (todayWeekday - 1),
  );

  // Procesar últimas 4 semanas
  for (var weekOffset = 0; weekOffset < 4; weekOffset++) {
    final weekStart = currentWeekStart.subtract(Duration(days: 7 * weekOffset));
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Obtener entradas de la semana
    final entries = await diaryRepo.getByDateRange(
      weekStart,
      weekEnd.add(const Duration(days: 1)), // Incluir el último día completo
    );

    // Agrupar por día
    final dayTotals = <DateTime, _DayTotal>{};
    for (final entry in entries) {
      final dayKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
      dayTotals.putIfAbsent(
        dayKey,
        () => _DayTotal(kcal: 0, protein: 0, carbs: 0, fat: 0),
      );
      dayTotals[dayKey]!.kcal += entry.kcal;
      dayTotals[dayKey]!.protein += entry.protein ?? 0;
      dayTotals[dayKey]!.carbs += entry.carbs ?? 0;
      dayTotals[dayKey]!.fat += entry.fat ?? 0;
    }

    final daysLogged = dayTotals.length;
    if (daysLogged == 0) {
      // Semana sin datos
      results.add(WeeklyInsight(
        weekStart: weekStart,
        weekEnd: weekEnd,
        daysLogged: 0,
        totalKcal: 0,
        avgKcalPerDay: 0,
        targetKcal: targetKcal,
        adherencePercentage: 0,
        avgDeviationKcal: 0,
        avgProtein: 0,
        avgCarbs: 0,
        avgFat: 0,
        kcalChangeVsLastWeek: null,
      ));
      continue;
    }

    // Calcular totales
    final totalKcal = dayTotals.values.fold<int>(0, (sum, d) => sum + d.kcal);
    final avgKcal = totalKcal ~/ daysLogged;

    final totalProtein = dayTotals.values.fold<double>(0, (sum, d) => sum + d.protein);
    final totalCarbs = dayTotals.values.fold<double>(0, (sum, d) => sum + d.carbs);
    final totalFat = dayTotals.values.fold<double>(0, (sum, d) => sum + d.fat);

    // Calcular adherencia (días dentro del ±10% del objetivo)
    double adherence = 0;
    int totalDeviation = 0;

    if (targetKcal != null && targetKcal > 0) {
      int daysOnTarget = 0;
      for (final dayTotal in dayTotals.values) {
        final deviation = (dayTotal.kcal - targetKcal).abs();
        totalDeviation += deviation;

        // ±10% del objetivo es "on target"
        if (deviation <= targetKcal * 0.1) {
          daysOnTarget++;
        }
      }
      adherence = (daysOnTarget / daysLogged) * 100;
    }

    results.add(WeeklyInsight(
      weekStart: weekStart,
      weekEnd: weekEnd,
      daysLogged: daysLogged,
      totalKcal: totalKcal,
      avgKcalPerDay: avgKcal,
      targetKcal: targetKcal,
      adherencePercentage: adherence,
      avgDeviationKcal: daysLogged > 0 ? totalDeviation ~/ daysLogged : 0,
      avgProtein: totalProtein / daysLogged,
      avgCarbs: totalCarbs / daysLogged,
      avgFat: totalFat / daysLogged,
      kcalChangeVsLastWeek: null, // Se calcula después
    ));
  }

  // Calcular diferencias semana vs semana
  for (var i = 0; i < results.length - 1; i++) {
    final current = results[i];
    final previous = results[i + 1];

    if (current.daysLogged > 0 && previous.daysLogged > 0) {
      results[i] = WeeklyInsight(
        weekStart: current.weekStart,
        weekEnd: current.weekEnd,
        daysLogged: current.daysLogged,
        totalKcal: current.totalKcal,
        avgKcalPerDay: current.avgKcalPerDay,
        targetKcal: current.targetKcal,
        adherencePercentage: current.adherencePercentage,
        avgDeviationKcal: current.avgDeviationKcal,
        avgProtein: current.avgProtein,
        avgCarbs: current.avgCarbs,
        avgFat: current.avgFat,
        kcalChangeVsLastWeek: current.avgKcalPerDay - previous.avgKcalPerDay,
      );
    }
  }

  return results;
});

/// Provider de insight de la semana actual
final currentWeekInsightProvider = Provider<AsyncValue<WeeklyInsight?>>((ref) {
  final insightsAsync = ref.watch(weeklyInsightsProvider);

  return insightsAsync.when(
    data: (insights) {
      if (insights.isEmpty) return const AsyncValue.data(null);
      return AsyncValue.data(insights.first);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// ============================================================================
// HELPER CLASSES
// ============================================================================

class _DayTotal {
  int kcal;
  double protein;
  double carbs;
  double fat;

  _DayTotal({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}
