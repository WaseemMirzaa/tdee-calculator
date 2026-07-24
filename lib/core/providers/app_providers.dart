import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../models/meal.dart';
import '../models/seed_data.dart';
import '../meal_planner.dart';
import '../seed_loader.dart';
import '../tdee_engine.dart';
import '../theme/vita_tokens.dart';
import '../util/units.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

final dbProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

/// The parsed seed database (foods, meals, diets). Loaded once.
final seedProvider = FutureProvider<SeedData>((ref) => SeedLoader.load());

// ---------------------------------------------------------------------------
// Profile  (the persisted UserProfile, or null before onboarding)
// ---------------------------------------------------------------------------

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() => ref.read(dbProvider).loadProfile();

  Future<void> save(UserProfile p) async {
    await ref.read(dbProvider).saveProfile(p);
    state = AsyncData(p);
  }

  Future<void> clear() async {
    await ref.read(dbProvider).clearAll();
    state = const AsyncData(null);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);

/// Everything the UI needs, computed once from the current profile.
/// Null until a profile exists.
final resultProvider = Provider<TdeeResult?>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile == null) return null;
  return TdeeCalculator.computeAll(profile);
});

/// Whether the user has completed onboarding (used for deep-linking to Home).
final hasProfileProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).valueOrNull != null;
});

// ---------------------------------------------------------------------------
// Unit system  (kg/cm ↔ lb/ft)  &  theme mode  — persisted preferences
// ---------------------------------------------------------------------------

class UnitNotifier extends Notifier<UnitSystem> {
  @override
  UnitSystem build() {
    // Synchronous read from the preloaded cache — no flash of the default.
    return ref.read(dbProvider).getSettingSync('units') == 'imperial'
        ? UnitSystem.imperial
        : UnitSystem.metric;
  }

  void toggle() => set(state == UnitSystem.metric ? UnitSystem.imperial : UnitSystem.metric);

  void set(UnitSystem u) {
    state = u;
    ref.read(dbProvider).setSetting('units', u.name);
  }
}

final unitSystemProvider = NotifierProvider<UnitNotifier, UnitSystem>(UnitNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    switch (ref.read(dbProvider).getSettingSync('theme')) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  void set(ThemeMode m) {
    state = m;
    ref.read(dbProvider).setSetting('theme', m.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// The selected premium accent scheme (persisted, read synchronously so there
/// is no flash of the default on launch).
class SchemeNotifier extends Notifier<VitaScheme> {
  @override
  VitaScheme build() => schemeById(ref.read(dbProvider).getSettingSync('scheme'));

  void select(VitaScheme s) {
    state = s;
    ref.read(dbProvider).setSetting('scheme', s.id);
  }
}

final schemeProvider = NotifierProvider<SchemeNotifier, VitaScheme>(SchemeNotifier.new);

// ---------------------------------------------------------------------------
// Meals: selected diet, food likes, generated plan, favorites
// ---------------------------------------------------------------------------

class DietNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(dbProvider).getSettingSync('diet');

  void select(String dietId) {
    state = dietId;
    ref.read(dbProvider).setSetting('diet', dietId);
  }
}

final selectedDietProvider = NotifierProvider<DietNotifier, String?>(DietNotifier.new);

class FoodPrefsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.read(dbProvider).loadFoodPrefs();

  Future<void> setAll(Set<String> ids) async {
    await ref.read(dbProvider).setFoodPrefs(ids);
    state = AsyncData(ids);
  }

  Future<void> toggle(String id) async {
    final current = {...?state.valueOrNull};
    current.contains(id) ? current.remove(id) : current.add(id);
    await setAll(current);
  }
}

final foodPrefsProvider =
    AsyncNotifierProvider<FoodPrefsNotifier, Set<String>>(FoodPrefsNotifier.new);

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.read(dbProvider).loadFavorites();

  Future<void> toggle(String mealId) async {
    await ref.read(dbProvider).toggleFavorite(mealId);
    state = AsyncData(await ref.read(dbProvider).loadFavorites());
  }
}

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

/// The generated meal plan. Rebuilds from persisted entries on launch;
/// [regenerate] creates a fresh plan from the current diet + likes + goal and
/// persists it.
class PlanNotifier extends AsyncNotifier<List<PlannedDay>> {
  @override
  Future<List<PlannedDay>> build() async {
    final seed = await ref.watch(seedProvider.future);
    final entries = await ref.read(dbProvider).loadPlan();
    if (entries.isEmpty) return const [];
    final byDay = <int, List<PlanEntry>>{};
    for (final e in entries) {
      byDay.putIfAbsent(e.day, () => []).add(e);
    }
    final days = <PlannedDay>[];
    final sortedDays = byDay.keys.toList()..sort();
    for (final d in sortedDays) {
      final meals = byDay[d]!
          .map((e) => seed.mealById(e.mealId))
          .whereType<Meal>()
          .toList();
      days.add(PlannedDay(dayNumber: d, meals: meals));
    }
    return days;
  }

  /// Generate [days] of meals for the given target and persist them.
  Future<void> regenerate({
    required double targetCalories,
    int days = 7,
    bool includeSnack = false,
    bool ignoreFoodFilter = false,
    int seed = 7,
  }) async {
    final seedData = await ref.read(seedProvider.future);
    final dietId = ref.read(selectedDietProvider) ?? 'anything';
    final likes = ref.read(foodPrefsProvider).valueOrNull ?? <String>{};
    final planned = MealPlanner.generate(
      allMeals: seedData.meals,
      dietId: dietId,
      likedFoodIds: likes,
      targetCalories: targetCalories,
      days: days,
      includeSnack: includeSnack,
      ignoreFoodFilter: ignoreFoodFilter,
      seed: seed,
    );
    await _persist(planned);
    state = AsyncData(planned);
  }

  /// Append a single new day to the existing plan, keeping all prior days
  /// exactly as they are. Returns the new day's number.
  Future<int> appendDay({required double targetCalories, bool includeSnack = false}) async {
    final existing = [...?state.valueOrNull];
    final seedData = await ref.read(seedProvider.future);
    final dietId = ref.read(selectedDietProvider) ?? 'anything';
    final likes = ref.read(foodPrefsProvider).valueOrNull ?? <String>{};
    final nextDay = existing.isEmpty ? 1 : existing.map((d) => d.dayNumber).reduce((a, b) => a > b ? a : b) + 1;
    // Vary the seed by day count so the new day differs from prior ones.
    final generated = MealPlanner.generate(
      allMeals: seedData.meals,
      dietId: dietId,
      likedFoodIds: likes,
      targetCalories: targetCalories,
      days: 1,
      includeSnack: includeSnack,
      seed: 100 + nextDay,
    );
    final newDay = PlannedDay(dayNumber: nextDay, meals: generated.first.meals);
    final updated = [...existing, newDay];
    await _persist(updated);
    state = AsyncData(updated);
    return nextDay;
  }

  /// Swap a single meal in [dayNumber] at [slot] for another candidate.
  Future<void> swapMeal(int dayNumber, int slot, Meal replacement) async {
    final days = [...?state.valueOrNull];
    final idx = days.indexWhere((d) => d.dayNumber == dayNumber);
    if (idx == -1) return;
    final meals = [...days[idx].meals];
    if (slot < 0 || slot >= meals.length) return;
    meals[slot] = replacement;
    days[idx] = PlannedDay(dayNumber: dayNumber, meals: meals);
    await _persist(days);
    state = AsyncData(days);
  }

  Future<void> reset() async {
    await ref.read(dbProvider).savePlan(const []);
    state = const AsyncData([]);
  }

  Future<void> _persist(List<PlannedDay> days) async {
    final entries = <PlanEntry>[];
    for (final d in days) {
      for (var slot = 0; slot < d.meals.length; slot++) {
        final m = d.meals[slot];
        entries.add(PlanEntry(day: d.dayNumber, slot: slot, mealId: m.id, type: m.type));
      }
    }
    await ref.read(dbProvider).savePlan(entries);
  }
}

final planProvider =
    AsyncNotifierProvider<PlanNotifier, List<PlannedDay>>(PlanNotifier.new);

// ---------------------------------------------------------------------------
// Journey: weigh-ins
// ---------------------------------------------------------------------------

class WeighInsNotifier extends AsyncNotifier<List<WeighIn>> {
  @override
  Future<List<WeighIn>> build() => ref.read(dbProvider).loadWeighIns();

  Future<void> add(DateTime date, double weightKg) async {
    await ref.read(dbProvider).addWeighIn(date, weightKg);
    state = AsyncData(await ref.read(dbProvider).loadWeighIns());
    // Keep the profile's current weight in step with the latest weigh-in.
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null) {
      await ref.read(profileProvider.notifier).save(profile.copyWith(weightKg: weightKg));
    }
  }

  Future<void> remove(int id) async {
    await ref.read(dbProvider).deleteWeighIn(id);
    state = AsyncData(await ref.read(dbProvider).loadWeighIns());
  }
}

final weighInsProvider =
    AsyncNotifierProvider<WeighInsNotifier, List<WeighIn>>(WeighInsNotifier.new);
