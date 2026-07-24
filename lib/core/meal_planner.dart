import 'dart:math';

import 'models/meal.dart';

/// A generated day: an ordered list of meals (breakfast, lunch, dinner[, snack]).
class PlannedDay {
  const PlannedDay({required this.dayNumber, required this.meals});
  final int dayNumber;
  final List<Meal> meals;

  double get calories => meals.fold(0.0, (s, m) => s + m.calories);
  double get protein => meals.fold(0.0, (s, m) => s + m.protein);
  double get carbs => meals.fold(0.0, (s, m) => s + m.carbs);
  double get fat => meals.fold(0.0, (s, m) => s + m.fat);
}

/// Generates day plans from the seed meals, honouring the chosen diet, the
/// user's liked foods, and nudging each day toward the goal calorie target.
///
/// Pure Dart — no Flutter, no I/O — so it is unit-testable.
class MealPlanner {
  const MealPlanner._();

  /// Slots filled per day. Snack is included only when [includeSnack].
  static const List<String> _coreSlots = ['breakfast', 'lunch', 'dinner'];

  /// Generate [days] plans.
  ///
  /// * [allMeals]        every meal in the seed DB.
  /// * [dietId]          selected diet (membership filter).
  /// * [likedFoodIds]    liked foods; empty or [ignoreFoodFilter] = no filter.
  /// * [targetCalories]  the goal's daily calorie target (maintenance × factor).
  /// * [seed]            makes generation deterministic & reproducible.
  static List<PlannedDay> generate({
    required List<Meal> allMeals,
    required String dietId,
    required Set<String> likedFoodIds,
    required double targetCalories,
    int days = 7,
    bool includeSnack = false,
    bool ignoreFoodFilter = false,
    int seed = 7,
  }) {
    final slots = [..._coreSlots, if (includeSnack) 'snack'];

    // Candidate pool per slot, after diet + (optional) liked-food filtering.
    final pools = <String, List<Meal>>{};
    for (final slot in slots) {
      final byDiet = allMeals.where((m) => m.type == slot && m.allowedFor(dietId)).toList();
      List<Meal> pool = byDiet;
      if (!ignoreFoodFilter && likedFoodIds.isNotEmpty) {
        final liked = byDiet.where((m) => m.foodIds.intersection(likedFoodIds).isNotEmpty).toList();
        // Fall back to the full diet pool if likes are too restrictive to fill days.
        pool = liked.length >= 2 ? liked : byDiet;
      }
      pools[slot] = pool.isEmpty ? byDiet : pool;
    }

    final rng = Random(seed);
    // Per-slot share of the daily target (breakfast/lunch/dinner ~ 30/40/30).
    final shares = _slotShares(slots);

    final result = <PlannedDay>[];
    // Track recent picks to reduce back-to-back repeats.
    final recent = <String, List<String>>{for (final s in slots) s: <String>[]};

    for (var day = 1; day <= days; day++) {
      final chosen = <Meal>[];
      for (final slot in slots) {
        final pool = pools[slot]!;
        if (pool.isEmpty) continue;
        final slotTarget = targetCalories * shares[slot]!;
        final pick = _pickForSlot(pool, slotTarget, recent[slot]!, rng);
        chosen.add(pick);
        final ring = recent[slot]!;
        ring.add(pick.id);
        if (ring.length > 2) ring.removeAt(0);
      }
      result.add(PlannedDay(dayNumber: day, meals: chosen));
    }
    return result;
  }

  static Map<String, double> _slotShares(List<String> slots) {
    if (slots.contains('snack')) {
      return {'breakfast': 0.28, 'lunch': 0.34, 'dinner': 0.30, 'snack': 0.08};
    }
    return {'breakfast': 0.30, 'lunch': 0.40, 'dinner': 0.30};
  }

  /// Choose the meal whose calories sit closest to the slot target, avoiding
  /// recent repeats, with a little randomness among near-equal candidates.
  static Meal _pickForSlot(List<Meal> pool, double slotTarget, List<String> recent, Random rng) {
    final fresh = pool.where((m) => !recent.contains(m.id)).toList();
    final candidates = fresh.length >= 2 ? fresh : pool;

    final scored = candidates.toList()
      ..sort((a, b) => (a.calories - slotTarget).abs().compareTo((b.calories - slotTarget).abs()));

    // Pick from the best few to add variety day to day.
    final topN = min(3, scored.length);
    return scored[rng.nextInt(topN)];
  }
}
