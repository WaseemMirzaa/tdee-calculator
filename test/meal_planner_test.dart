import 'package:flutter_test/flutter_test.dart';
import 'package:vita_tdee/core/models/meal.dart';
import 'package:vita_tdee/core/meal_planner.dart';

Meal _meal(String id, String type, double kcal, List<String> foods,
    {List<String> diets = const ['anything']}) {
  return Meal(
    id: id,
    title: id,
    type: type,
    diets: diets,
    timeMinutes: 10,
    calories: kcal,
    protein: 10,
    carbs: 10,
    fat: 10,
    ingredients: [for (final f in foods) Ingredient(foodId: f, name: f, amount: '', kcal: 1)],
    steps: const ['step'],
  );
}

void main() {
  final meals = <Meal>[
    _meal('b1', 'breakfast', 300, ['egg']),
    _meal('b2', 'breakfast', 500, ['oats']),
    _meal('b3', 'breakfast', 400, ['yogurt']),
    _meal('l1', 'lunch', 500, ['chicken']),
    _meal('l2', 'lunch', 700, ['beef']),
    _meal('l3', 'lunch', 600, ['tuna']),
    _meal('d1', 'dinner', 500, ['salmon']),
    _meal('d2', 'dinner', 650, ['tofu']),
    _meal('d3', 'dinner', 450, ['pasta']),
    _meal('k1', 'breakfast', 480, ['egg'], diets: ['keto', 'anything']),
    _meal('k2', 'lunch', 470, ['chicken'], diets: ['keto', 'anything']),
    _meal('k3', 'dinner', 535, ['salmon'], diets: ['keto', 'anything']),
  ];

  test('generates the requested number of days with 3 core meals each', () {
    final days = MealPlanner.generate(
      allMeals: meals,
      dietId: 'anything',
      likedFoodIds: const {},
      targetCalories: 1500,
      days: 7,
    );
    expect(days.length, 7);
    for (final d in days) {
      expect(d.meals.length, 3);
      expect(d.meals.map((m) => m.type).toSet(), {'breakfast', 'lunch', 'dinner'});
    }
  });

  test('respects the diet membership filter', () {
    final days = MealPlanner.generate(
      allMeals: meals,
      dietId: 'keto',
      likedFoodIds: const {},
      targetCalories: 1500,
      days: 3,
    );
    for (final d in days) {
      for (final m in d.meals) {
        expect(m.allowedFor('keto'), isTrue);
      }
    }
  });

  test('is deterministic for a fixed seed', () {
    List<String> ids(int seed) => MealPlanner.generate(
          allMeals: meals,
          dietId: 'anything',
          likedFoodIds: const {},
          targetCalories: 1600,
          days: 5,
          seed: seed,
        ).expand((d) => d.meals.map((m) => m.id)).toList();
    expect(ids(42), ids(42));
  });

  test('liked-food filter prefers meals with liked ingredients', () {
    final days = MealPlanner.generate(
      allMeals: meals,
      dietId: 'anything',
      likedFoodIds: const {'egg', 'chicken', 'salmon'},
      targetCalories: 1500,
      days: 2,
    );
    // With enough liked-food meals the breakfast slot should favour 'egg' ones.
    expect(days.first.meals.any((m) => m.foodIds.contains('egg')), isTrue);
  });

  test('day calories land in a sane band around the target', () {
    final days = MealPlanner.generate(
      allMeals: meals,
      dietId: 'anything',
      likedFoodIds: const {},
      targetCalories: 1500,
      days: 4,
    );
    for (final d in days) {
      expect(d.calories, greaterThan(900));
      expect(d.calories, lessThan(2400));
    }
  });
}
