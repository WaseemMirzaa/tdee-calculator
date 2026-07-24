import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_tdee/core/seed_loader.dart';

void main() {
  final seed = SeedLoader.parse(File('assets/tdee_seed.json').readAsStringSync());

  test('parses the expected counts (99 foods · 18 meals · 6 diets)', () {
    expect(seed.foods.length, 99);
    expect(seed.meals.length, 18);
    expect(seed.diets.length, 6);
  });

  test('every meal ingredient with a foodId resolves to a food', () {
    for (final m in seed.meals) {
      for (final id in m.foodIds) {
        expect(seed.foodById(id), isNotNull, reason: 'missing food $id in ${m.id}');
      }
    }
  });

  test('diet filtering is a membership test', () {
    final keto = seed.foods.where((f) => f.allowedFor('keto')).toList();
    expect(keto, isNotEmpty);
    expect(keto.every((f) => f.diets.contains('keto')), isTrue);
  });

  test('corrected exclusions: vegetarian keeps dairy & eggs available', () {
    // The competitor wrongly excluded these; our seed corrects it.
    final vegFoods = seed.foods.where((f) => f.allowedFor('vegetarian'));
    expect(vegFoods.any((f) => f.category == 'dairy'), isTrue);
    expect(vegFoods.any((f) => f.id.contains('egg')), isTrue);
  });

  test('sample plan references real meals', () {
    for (final day in seed.samplePlan) {
      for (final id in day) {
        expect(seed.mealById(id), isNotNull);
      }
    }
  });
}
