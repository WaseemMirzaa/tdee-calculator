/// One line of a recipe. [foodId] is null for free-text seasonings (kcal 0).
class Ingredient {
  const Ingredient({
    this.foodId,
    required this.name,
    required this.amount,
    this.grams,
    required this.kcal,
  });

  final String? foodId;
  final String name;
  final String amount;
  final double? grams;
  final double kcal;

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        foodId: j['foodId'] as String?,
        name: j['name'] as String,
        amount: j['amount'] as String? ?? '',
        grams: (j['grams'] as num?)?.toDouble(),
        kcal: (j['kcal'] as num?)?.toDouble() ?? 0,
      );
}

/// A meal from the seed DB. Totals are derived from the food table.
class Meal {
  const Meal({
    required this.id,
    required this.title,
    required this.type,
    required this.diets,
    required this.timeMinutes,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String title;
  final String type; // breakfast | lunch | dinner | snack
  final List<String> diets;
  final int timeMinutes;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<Ingredient> ingredients;
  final List<String> steps;

  bool allowedFor(String dietId) => diets.contains(dietId);

  /// The set of foodIds this meal is built from (ignores free-text seasonings).
  Set<String> get foodIds =>
      ingredients.where((i) => i.foodId != null).map((i) => i.foodId!).toSet();

  factory Meal.fromJson(Map<String, dynamic> j) => Meal(
        id: j['id'] as String,
        title: j['title'] as String,
        type: j['type'] as String,
        diets: (j['diets'] as List).cast<String>(),
        timeMinutes: (j['timeMinutes'] as num?)?.toInt() ?? 0,
        calories: (j['calories'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        ingredients: (j['ingredients'] as List)
            .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (j['steps'] as List).cast<String>(),
      );
}

const Map<String, String> kMealTypeLabels = {
  'breakfast': 'Breakfast',
  'lunch': 'Lunch',
  'dinner': 'Dinner',
  'snack': 'Snack',
};

/// Order meals appear within a day.
const List<String> kMealTypeOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
