import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/meal_planner.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';
import 'meal_plan_screen.dart';

/// The Meals bottom-nav tab. Shows the generated plan when one exists,
/// otherwise a start CTA into the diet → likes → plan flow.
class MealsTab extends ConsumerWidget {
  const MealsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider).valueOrNull ?? const <PlannedDay>[];
    final v = context.vita;

    if (plan.isNotEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Row(
              children: [
                Text('Meal plan', style: context.vt.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(Routes.diet),
                  child: Text('New plan', style: TextStyle(color: v.brand, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Expanded(child: MealPlanBody()),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96, height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: v.brand.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🍽', style: TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 22),
            Text('Build your meal plan', style: context.vt.headlineMedium?.copyWith(fontSize: 24), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Pick a diet and the foods you love — Vita generates a week of meals balanced to your goal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: v.inkSoft, fontSize: 14.5, height: 1.5),
            ),
            const SizedBox(height: 24),
            VitaPrimaryButton(
              label: 'Get started',
              icon: Icons.arrow_forward_rounded,
              expand: false,
              onPressed: () => context.push(Routes.diet),
            ),
          ],
        ),
      ),
    );
  }
}
