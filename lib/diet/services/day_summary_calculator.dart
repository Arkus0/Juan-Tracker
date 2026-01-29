import '../models/models.dart';

/// {@template day_summary_calculator}
/// Servicio puro de cálculo para resúmenes diarios.
/// 
/// Combina totales consumidos con objetivos para calcular progreso.
/// Es 100% puro Dart (sin dependencias de Flutter ni DB) para facilitar testing.
/// {@endtemplate}
class DaySummaryCalculator {
  /// {@macro day_summary_calculator}
  const DaySummaryCalculator();

  /// Calcula el resumen completo de un día dados los objetivos activos y las entradas.
  /// 
  /// Si no hay objetivos configurados para la fecha, [targets] será null
  /// y el progreso se reportará como 0%.
  DaySummary calculate({
    required DateTime date,
    required DailyTotals consumed,
    TargetsModel? targets,
  }) {
    final progress = TargetsProgress(
      targets: targets,
      kcalConsumed: consumed.kcal,
      proteinConsumed: consumed.protein,
      carbsConsumed: consumed.carbs,
      fatConsumed: consumed.fat,
    );

    return DaySummary(
      date: DateTime(date.year, date.month, date.day),
      consumed: consumed,
      targets: targets,
      progress: progress,
    );
  }

  /// Calcula el target activo para una fecha dada desde una lista ordenada.
  /// 
  /// Busca el target con [validFrom] más reciente que sea <= [date].
  /// Si no encuentra ninguno, retorna null.
  TargetsModel? findActiveTargetForDate(
    List<TargetsModel> allTargets,
    DateTime date,
  ) {
    if (allTargets.isEmpty) return null;

    // Ordenar por validFrom descendente (más reciente primero)
    final sorted = List<TargetsModel>.from(allTargets)
      ..sort((a, b) => b.validFrom.compareTo(a.validFrom));

    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Encontrar el primero cuya validFrom sea <= date
    for (final target in sorted) {
      final targetDate = DateTime(
        target.validFrom.year,
        target.validFrom.month,
        target.validFrom.day,
      );
      if (targetDate.isBefore(normalizedDate) ||
          targetDate.isAtSameMomentAs(normalizedDate)) {
        return target;
      }
    }

    return null;
  }
}

/// {@template day_summary}
/// Resumen completo de un día incluyendo consumo, objetivos y progreso.
/// {@endtemplate}
class DaySummary {
  final DateTime date;
  final DailyTotals consumed;
  final TargetsModel? targets;
  final TargetsProgress progress;

  const DaySummary({
    required this.date,
    required this.consumed,
    required this.targets,
    required this.progress,
  });

  /// Indica si hay objetivos configurados para este día.
  bool get hasTargets => targets != null;

  /// Indica si el día tiene consumo (no está vacío).
  bool get hasConsumption => consumed.kcal > 0;

  /// Resumen formateado para debugging.
  Map<String, dynamic> toDebugMap() => {
        'date': date.toIso8601String(),
        'consumed': consumed.toDebugMap(),
        'targets': targets?.toDebugMap(),
        'progress': progress.toDebugMap(),
      };

  @override
  String toString() => 'DaySummary(${toDebugMap()})';
}
