enum MealType { breakfast, lunch, dinner, snack }

class DiaryEntry {
  final String id;
  final DateTime date; // truncated to date
  final MealType mealType;
  final String? foodId;
  final String? customName;
  final double grams;
  final int kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final DateTime createdAt;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.mealType,
    this.foodId,
    this.customName,
    required this.grams,
    required this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
