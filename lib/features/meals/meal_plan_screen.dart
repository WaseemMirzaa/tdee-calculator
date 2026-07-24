import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/meal_planner.dart';
import '../../core/models/meal.dart';
import '../../core/tdee_engine.dart';
import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// The goal-adjusted daily calorie target meals balance toward.
double goalTargetCalories(TdeeResult r, Goal goal) => switch (goal) {
      Goal.loseWeight => r.loseTargets['loss_0.5'] ?? r.maintenanceCalories,
      Goal.gainWeight => r.gainTargets['gain_0.5'] ?? r.maintenanceCalories,
      Goal.maintainWeight => r.maintenanceCalories,
    };

/// S11 · Meal plan (full screen — used after generation).
class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your meal plan')),
      body: const MealPlanBody(),
    );
  }
}

/// The scrollable plan body — reused by both the full screen and the Meals tab.
class MealPlanBody extends ConsumerStatefulWidget {
  const MealPlanBody({super.key});

  @override
  ConsumerState<MealPlanBody> createState() => _MealPlanBodyState();
}

class _MealPlanBodyState extends ConsumerState<MealPlanBody> {
  int _day = 1;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(planProvider);
    final result = ref.watch(resultProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? <String>{};
    final v = context.vita;

    return planAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (days) {
        if (days.isEmpty) return const SizedBox.shrink();
        _day = _day.clamp(1, days.length);
        final today = days.firstWhere((d) => d.dayNumber == _day, orElse: () => days.first);
        final target = result != null && profile != null
            ? goalTargetCalories(result, profile.goal)
            : today.calories;

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            // Day selector
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final n = days[i].dayNumber;
                  final sel = n == _day;
                  return GestureDetector(
                    onTap: () => setState(() => _day = n),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: sel ? v.brand : (v.isDark ? v.lineSoft : const Color(0xFFF0EEE4)),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('Day $n',
                          style: TextStyle(
                              color: sel ? Colors.white : v.inkSoft,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Day summary
            _DaySummary(day: today, target: target),
            const SizedBox(height: 16),

            for (var i = 0; i < today.meals.length; i++) ...[
              _MealCard(
                meal: today.meals[i],
                isFavorite: favorites.contains(today.meals[i].id),
                onOpen: () => context.push('${Routes.meal}/${today.meals[i].id}'),
                onFavorite: () => ref.read(favoritesProvider.notifier).toggle(today.meals[i].id),
                onSwap: () => _swap(today.dayNumber, i, today.meals[i]),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: VitaGhostButton(
                    label: 'Shopping list',
                    icon: Icons.receipt_long_rounded,
                    onPressed: () => _showShoppingList(days),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: VitaGhostButton(
                    label: 'Add day',
                    icon: Icons.add_rounded,
                    onPressed: _busy ? null : () => _addDay(days.length, target),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () async {
                await ref.read(planProvider.notifier).reset();
                ref.read(selectedDietProvider.notifier).select('anything');
                if (context.mounted) ref.read(homeTabProvider.notifier).state = 1;
              },
              icon: Icon(Icons.refresh_rounded, size: 18, color: v.muted),
              label: Text('Reset & start over', style: TextStyle(color: v.muted)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addDay(int current, double target) async {
    setState(() => _busy = true);
    await ref.read(planProvider.notifier).regenerate(
          targetCalories: target,
          days: current + 1,
          seed: 7 + current,
        );
    if (mounted) {
      setState(() {
        _busy = false;
        _day = current + 1;
      });
    }
  }

  void _swap(int day, int slot, Meal current) async {
    final seed = ref.read(seedProvider).valueOrNull;
    if (seed == null) return;
    final dietId = ref.read(selectedDietProvider) ?? 'anything';
    final pool = seed.meals
        .where((m) => m.type == current.type && m.allowedFor(dietId) && m.id != current.id)
        .toList();
    if (pool.isEmpty) return;
    // Pick the next candidate closest in calories for a gentle swap.
    pool.sort((a, b) => (a.calories - current.calories).abs().compareTo((b.calories - current.calories).abs()));
    await ref.read(planProvider.notifier).swapMeal(day, slot, pool.first);
  }

  void _showShoppingList(List<PlannedDay> days) {
    final totals = <String, double>{};
    for (final d in days) {
      for (final m in d.meals) {
        for (final ing in m.ingredients) {
          totals.update(ing.name, (g) => g + (ing.grams ?? 0), ifAbsent: () => ing.grams ?? 0);
        }
      }
    }
    final items = totals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.vita.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('Shopping list', style: context.vt.titleLarge),
            Text('${items.length} items across ${days.length} days',
                style: TextStyle(color: context.vita.muted, fontSize: 13)),
            const SizedBox(height: 14),
            for (final e in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Icon(Icons.circle_outlined, size: 16, color: context.vita.muted),
                    const SizedBox(width: 12),
                    Expanded(child: Text(e.key, style: TextStyle(color: context.vita.ink, fontSize: 14.5))),
                    if (e.value > 0)
                      Text('${e.value.round()} g', style: context.mono(size: 13, color: context.vita.muted)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.day, required this.target});
  final PlannedDay day;
  final double target;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final pct = (day.calories / target).clamp(0.0, 1.3);
    return VitaCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Day total'),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${day.calories.round()}', style: context.mono(size: 28)),
                      Text(' / ${target.round()} kcal', style: TextStyle(color: v.muted, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _MiniMacro('P', day.protein),
              _MiniMacro('C', day.carbs),
              _MiniMacro('F', day.fat),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct / 1.3,
              minHeight: 7,
              backgroundColor: v.lineSoft,
              valueColor: AlwaysStoppedAnimation(v.brand),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMacro extends StatelessWidget {
  const _MiniMacro(this.letter, this.grams);
  final String letter;
  final double grams;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14),
      child: Column(
        children: [
          Text('${grams.round()}', style: context.mono(size: 15, color: macroColor(_full(letter)))),
          Text(letter, style: TextStyle(fontSize: 11, color: context.vita.muted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _full(String l) => l == 'P' ? 'protein' : l == 'C' ? 'carbs' : 'fat';
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.isFavorite,
    required this.onOpen,
    required this.onFavorite,
    required this.onSwap,
  });
  final Meal meal;
  final bool isFavorite;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return VitaCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: v.brand.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(_mealEmoji(meal.type), style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((kMealTypeLabels[meal.type] ?? meal.type).toUpperCase(),
                    style: context.monoLabel(size: 10)),
                const SizedBox(height: 3),
                Text(meal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: v.ink)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${meal.calories.round()} kcal', style: context.mono(size: 12.5, color: v.muted)),
                    const SizedBox(width: 10),
                    Icon(Icons.schedule_rounded, size: 13, color: v.muted),
                    const SizedBox(width: 3),
                    Text('${meal.timeMinutes} min', style: TextStyle(color: v.muted, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: onFavorite,
                child: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20, color: isFavorite ? VitaColors.protein : v.muted),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: onSwap,
                child: Icon(Icons.swap_horiz_rounded, size: 20, color: v.brand),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _mealEmoji(String type) => switch (type) {
        'breakfast' => '🍳',
        'lunch' => '🥗',
        'dinner' => '🍽',
        _ => '🍎',
      };
}
