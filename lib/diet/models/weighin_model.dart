/// Modelo de dominio para registros de peso corporal
class WeighInModel {
  final String id;
  final DateTime dateTime; // Fecha y hora exacta del pesaje
  final double weightKg;
  final String? note;
  final DateTime createdAt;

  WeighInModel({
    required this.id,
    required this.dateTime,
    required this.weightKg,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Peso en libras (conversión)
  double get weightLbs => weightKg * 2.20462;

  /// Crea una copia con valores modificados
  WeighInModel copyWith({
    String? id,
    DateTime? dateTime,
    double? weightKg,
    String? note,
    DateTime? createdAt,
  }) =>
      WeighInModel(
        id: id ?? this.id,
        dateTime: dateTime ?? this.dateTime,
        weightKg: weightKg ?? this.weightKg,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Formatea el peso para display
  String formatted({bool useLbs = false}) {
    final weight = useLbs ? weightLbs : weightKg;
    final unit = useLbs ? 'lb' : 'kg';
    return '${weight.toStringAsFixed(1)} $unit';
  }

  Map<String, dynamic> toDebugMap() => {
        'id': id,
        'dateTime': dateTime.toIso8601String(),
        'weightKg': weightKg,
        'note': note,
      };

  @override
  String toString() => 'WeighInModel(${toDebugMap()})';
}

/// Trend de peso calculado a partir de múltiples registros
class WeightTrend {
  final double currentWeight;
  final double? previousWeight;
  final double? change7Days;
  final double? change30Days;
  final List<WeighInModel> entries;

  const WeightTrend({
    required this.currentWeight,
    this.previousWeight,
    this.change7Days,
    this.change30Days,
    required this.entries,
  });

  /// Calcula el trend desde una lista de entradas ordenadas por fecha (más reciente primero)
  factory WeightTrend.fromEntries(List<WeighInModel> entries) {
    if (entries.isEmpty) {
      throw ArgumentError('Cannot calculate trend from empty entries');
    }

    final sorted = List<WeighInModel>.from(entries)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    final current = sorted.first.weightKg;
    final previous = sorted.length > 1 ? sorted[1].weightKg : null;

    // Calcular cambio en 7 días
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekEntries = sorted.where((e) => e.dateTime.isAfter(weekAgo)).toList();
    final change7Days = weekEntries.length >= 2
        ? weekEntries.first.weightKg - weekEntries.last.weightKg
        : null;

    // Calcular cambio en 30 días
    final monthAgo = now.subtract(const Duration(days: 30));
    final monthEntries =
        sorted.where((e) => e.dateTime.isAfter(monthAgo)).toList();
    final change30Days = monthEntries.length >= 2
        ? monthEntries.first.weightKg - monthEntries.last.weightKg
        : null;

    return WeightTrend(
      currentWeight: current,
      previousWeight: previous,
      change7Days: change7Days,
      change30Days: change30Days,
      entries: sorted,
    );
  }

  Map<String, dynamic> toDebugMap() => {
        'currentWeight': currentWeight,
        'previousWeight': previousWeight,
        'change7Days': change7Days,
        'change30Days': change30Days,
        'entryCount': entries.length,
      };

  @override
  String toString() => 'WeightTrend(${toDebugMap()})';
}
