import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kcal and macros from grams and per_100g', () {
    double grams = 150; // 150g
    int kcalPer100g = 200; // 200 kcal per 100g

    final kcal = (grams / 100 * kcalPer100g).round();
    expect(kcal, 300);

    double proteinPer100g = 10.0; // g
    final protein = grams / 100 * proteinPer100g;
    expect(protein, closeTo(15.0, 1e-6));
  });
}
