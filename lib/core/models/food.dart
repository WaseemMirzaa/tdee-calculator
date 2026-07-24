/// A single food from the seed DB. Macros are per 100 g edible portion.
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.kcalPer100g,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.diets,
  });

  final String id;
  final String name;
  final String category; // protein | carbs | fat | fruits | vegetables | dairy
  final double kcalPer100g;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> diets;

  bool allowedFor(String dietId) => diets.contains(dietId);

  factory Food.fromJson(Map<String, dynamic> j) => Food(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        kcalPer100g: (j['kcalPer100g'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: (j['carbs'] as num).toDouble(),
        fat: (j['fat'] as num).toDouble(),
        diets: (j['diets'] as List).cast<String>(),
      );
}

/// Human-facing labels for the food categories used in the preference screen.
const Map<String, String> kFoodCategoryLabels = {
  'protein': 'Protein',
  'carbs': 'Carbs',
  'fat': 'Fats',
  'fruits': 'Fruits',
  'vegetables': 'Vegetables',
  'dairy': 'Dairy & drinks',
};

const List<String> kFoodCategoryOrder = [
  'protein',
  'carbs',
  'fat',
  'fruits',
  'vegetables',
  'dairy',
];
