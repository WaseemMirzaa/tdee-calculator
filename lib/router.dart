import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/app_providers.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/onboarding/profile_screen.dart';
import 'features/onboarding/activity_screen.dart';
import 'features/onboarding/calculating_screen.dart';
import 'features/results/energy_intake_screen.dart';
import 'features/results/macros_screen.dart';
import 'features/results/metric_detail_screen.dart';
import 'features/meals/diet_screen.dart';
import 'features/meals/food_prefs_screen.dart';
import 'features/meals/meal_plan_screen.dart';
import 'features/meals/meal_detail_screen.dart';
import 'features/paywall/paywall_screen.dart';
import 'shell.dart';

/// Route paths, in one place.
class Routes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const profile = '/onboarding/profile';
  static const activity = '/onboarding/activity';
  static const calculating = '/calculating';
  static const home = '/home';
  static const paywall = '/paywall';
  static const energy = '/energy';
  static const macros = '/macros';
  static const metric = '/metric'; // /metric/:type
  static const diet = '/diet';
  static const foodPrefs = '/food-prefs';
  static const mealPlan = '/meal-plan';
  static const meal = '/meal'; // /meal/:id
}

/// Which bottom-nav tab the home shell shows. Other screens can switch tabs.
final homeTabProvider = StateProvider<int>((ref) => 0);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        redirect: (context, state) {
          // Returning users (persisted profile) deep-link straight to Home.
          final hasProfile = ref.read(profileProvider).valueOrNull != null;
          return hasProfile ? Routes.home : Routes.welcome;
        },
      ),
      GoRoute(path: Routes.welcome, builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: Routes.profile, builder: (c, s) => const ProfileScreen()),
      GoRoute(path: Routes.activity, builder: (c, s) => const ActivityScreen()),
      GoRoute(path: Routes.calculating, builder: (c, s) => const CalculatingScreen()),
      GoRoute(path: Routes.home, builder: (c, s) => const HomeShell()),
      GoRoute(
        path: Routes.paywall,
        pageBuilder: (c, s) => const MaterialPage(fullscreenDialog: true, child: PaywallScreen()),
      ),
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
        builder: (c, s) => MealDetailScreen(mealId: s.pathParameters['id']!),
      ),
    ],
  );
});
