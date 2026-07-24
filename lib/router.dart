import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/app_providers.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/onboarding/calculating_screen.dart';
import 'features/results/energy_intake_screen.dart';
import 'features/results/macros_screen.dart';
import 'features/results/metric_detail_screen.dart';
import 'features/meals/diet_screen.dart';
import 'features/meals/food_prefs_screen.dart';
import 'features/meals/meal_plan_screen.dart';
import 'features/meals/meal_detail_screen.dart';
import 'shell.dart';

/// Route paths, in one place.
class Routes {
  static const welcome = '/welcome';
  static const onboard = '/onboarding';
  static const calculating = '/calculating';
  static const home = '/home';
  static const energy = '/energy';
  static const macros = '/macros';
  static const metric = '/metric'; // /metric/:type
  static const diet = '/diet';
  static const foodPrefs = '/food-prefs';
  static const mealPlan = '/meal-plan';
  static const meal = '/meal'; // /meal/:id

  /// Screens that are reachable before a profile exists.
  static const onboarding = {welcome, onboard, calculating};
}

/// Which bottom-nav tab the home shell shows. Other screens can switch tabs.
final homeTabProvider = StateProvider<int>((ref) => 0);

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects whenever the persisted profile appears/disappears
  // (onboarding completes, or "Reset all data" clears it).
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(profileProvider, (_, __) => refresh.value++);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    // Global guard: no profile ⇒ must be in onboarding; has profile ⇒ never
    // sit on the welcome screen. This makes relaunch and post-onboarding
    // navigation deterministic regardless of how a screen was reached.
    redirect: (context, state) {
      final hasProfile = ref.read(profileProvider).valueOrNull != null;
      final loc = state.matchedLocation;
      if (!hasProfile) {
        return Routes.onboarding.contains(loc) ? null : Routes.welcome;
      }
      if (loc == Routes.welcome) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.welcome, builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: Routes.onboard, builder: (c, s) => const OnboardingFlow()),
      GoRoute(path: Routes.calculating, builder: (c, s) => const CalculatingScreen()),
      GoRoute(path: Routes.home, builder: (c, s) => const HomeShell()),
      GoRoute(path: Routes.energy, builder: (c, s) => const EnergyIntakeScreen()),
      GoRoute(path: Routes.macros, builder: (c, s) => const MacrosScreen()),
      GoRoute(
        path: '${Routes.metric}/:type',
        builder: (c, s) => MetricDetailScreen(metric: s.pathParameters['type'] ?? 'bmi'),
      ),
      GoRoute(path: Routes.diet, builder: (c, s) => const DietScreen()),
      GoRoute(path: Routes.foodPrefs, builder: (c, s) => const FoodPrefsScreen()),
      GoRoute(path: Routes.mealPlan, builder: (c, s) => const MealPlanScreen()),
      GoRoute(
        path: '${Routes.meal}/:id',
        builder: (c, s) => MealDetailScreen(
          mealId: s.pathParameters['id']!,
          day: int.tryParse(s.uri.queryParameters['day'] ?? ''),
          slot: int.tryParse(s.uri.queryParameters['slot'] ?? ''),
        ),
      ),
    ],
  );
});
