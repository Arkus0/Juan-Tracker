class WeightEntry {
  final String id;
  final DateTime date; // truncated to date
  final double weightKg;
  final DateTime createdAt;

  WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
