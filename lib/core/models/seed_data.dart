import 'food.dart';
import 'meal.dart';
import 'diet.dart';

/// The fully-parsed seed database (foods, meals, diets, sample plan).
class SeedData {
  const SeedData({
    required this.version,
    required this.foods,
    required this.meals,
    required this.diets,
    required this.samplePlan,
  });

  final int version;
  final List<Food> foods;
  final List<Meal> meals;
  final List<Diet> diets;
  final List<List<String>> samplePlan; // days -> meal ids

  Food? foodById(String id) {
    for (final f in foods) {
      if (f.id == id) return f;
    }
    return null;
  }

  Meal? mealById(String id) {
    for (final m in meals) {
      if (m.id == id) return m;
    }
    return null;
  }

  Diet? dietById(String id) {
    for (final d in diets) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Foods grouped by category, in display order.
  Map<String, List<Food>> foodsByCategory() {
    final map = <String, List<Food>>{};
    for (final cat in kFoodCategoryOrder) {
      map[cat] = foods.where((f) => f.category == cat).toList();
    }
    return map;
  }

  factory SeedData.fromJson(Map<String, dynamic> j) {
    final plan = <List<String>>[];
    final sp = j['samplePlan'] as Map<String, dynamic>?;
    if (sp != null) {
      for (final day in (sp['days'] as List)) {
        plan.add(((day as Map<String, dynamic>)['meals'] as List).cast<String>());
      }
    }
    return SeedData(
      version: (j['version'] as num?)?.toInt() ?? 1,
      foods: (j['foods'] as List)
          .map((e) => Food.fromJson(e as Map<String, dynamic>))
          .toList(),
      meals: (j['meals'] as List)
          .map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList(),
      diets: (j['diets'] as List)
          .map((e) => Diet.fromJson(e as Map<String, dynamic>))
          .toList(),
      samplePlan: plan,
    );
  }
}
