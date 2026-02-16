import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';

/// Datos de racha de nutrición
class NutritionStreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLogDate;
  final Set<DateTime> recentDays; // últimos 7 días con registros

  const NutritionStreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastLogDate,
    this.recentDays = const {},
  });
}

/// Provider que calcula la racha de registro de comidas
final nutritionStreakProvider = FutureProvider<NutritionStreakData>((ref) async {
  // Usar calendarEntryDaysProvider que ya emite Set<DateTime> de días con registros
  final daysAsync = ref.watch(calendarEntryDaysProvider);

  return daysAsync.when(
    data: (loggedDays) => _calculateStreak(loggedDays),
    loading: () => const NutritionStreakData(
      currentStreak: 0,
      longestStreak: 0,
    ),
    error: (_, _) => const NutritionStreakData(
      currentStreak: 0,
      longestStreak: 0,
    ),
  );
});

/// Calcula rachas de nutrición a partir de un set de fechas con registros
NutritionStreakData _calculateStreak(Set<DateTime> loggedDays) {
  if (loggedDays.isEmpty) {
    return const NutritionStreakData(currentStreak: 0, longestStreak: 0);
  }

  // Normalizar todas las fechas a medianoche local
  final normalized = loggedDays.map((d) => DateTime(d.year, d.month, d.day)).toSet();
  final sortedDates = normalized.toList()..sort();

  // Fecha más reciente con registro
  final lastLogDate = sortedDates.last;

  // Racha actual: caminar hacia atrás desde hoy (o ayer si hoy no tiene registros)
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  int currentStreak = 0;

  // Empezar desde hoy; si no hay registro hoy, probar ayer
  DateTime checkDate = today;
  if (!normalized.contains(checkDate)) {
    checkDate = today.subtract(const Duration(days: 1));
    if (!normalized.contains(checkDate)) {
      // No hay racha activa (ni hoy ni ayer)
      currentStreak = 0;
    }
  }

  if (currentStreak == 0 && normalized.contains(checkDate)) {
    while (normalized.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
  }

  // Racha más larga: recorrer todas las fechas cronológicamente
  int longestStreak = 0;
  int tempStreak = 1;
  for (int i = 1; i < sortedDates.length; i++) {
    final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
    if (diff == 1) {
      tempStreak++;
    } else if (diff > 1) {
      if (tempStreak > longestStreak) longestStreak = tempStreak;
      tempStreak = 1;
    }
    // diff == 0: mismo día duplicado, ignorar
  }
  if (tempStreak > longestStreak) longestStreak = tempStreak;

  // Días recientes (últimos 7 días)
  final recentDays = <DateTime>{};
  for (int i = 0; i < 7; i++) {
    final day = today.subtract(Duration(days: i));
    if (normalized.contains(day)) recentDays.add(day);
  }

  return NutritionStreakData(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastLogDate: lastLogDate,
    recentDays: recentDays,
  );
}
