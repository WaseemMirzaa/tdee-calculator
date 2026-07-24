import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/food.dart';
import '../../core/tdee_engine.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// S10 · Food preference. Search + category sections with Select-All + chips.
/// Skip → a default plan ignoring the food filter. Generate → a plan balanced
/// to the goal's calorie target.
class FoodPrefsScreen extends ConsumerStatefulWidget {
  const FoodPrefsScreen({super.key});

  @override
  ConsumerState<FoodPrefsScreen> createState() => _FoodPrefsScreenState();
}

class _FoodPrefsScreenState extends ConsumerState<FoodPrefsScreen> {
  String _query = '';
  bool _busy = false;

  /// The goal-adjusted daily calorie target that meals balance toward.
  double _targetCalories(TdeeResult r, Goal goal) {
    switch (goal) {
      case Goal.loseWeight:
        return r.loseTargets['loss_0.5'] ?? r.maintenanceCalories;
      case Goal.gainWeight:
        return r.gainTargets['gain_0.5'] ?? r.maintenanceCalories;
      case Goal.maintainWeight:
        return r.maintenanceCalories;
    }
  }

  Future<void> _generate({required bool ignoreFilter}) async {
    final result = ref.read(resultProvider);
    final profile = ref.read(profileProvider).valueOrNull;
    if (result == null || profile == null) return;
    setState(() => _busy = true);
    await ref.read(planProvider.notifier).regenerate(
          targetCalories: _targetCalories(result, profile.goal),
          days: 7,
          ignoreFoodFilter: ignoreFilter,
        );
    if (mounted) {
      setState(() => _busy = false);
      context.go(Routes.mealPlan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final dietId = ref.watch(selectedDietProvider) ?? 'anything';
    final likes = ref.watch(foodPrefsProvider).valueOrNull ?? <String>{};
    final v = context.vita;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Foods you like'),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => _generate(ignoreFilter: true),
            child: Text('Skip', style: TextStyle(color: v.brand, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: seed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load foods: $e')),
        data: (data) {
          final byCat = <String, List<Food>>{};
          for (final cat in kFoodCategoryOrder) {
            final foods = data.foods
                .where((f) => f.category == cat && f.allowedFor(dietId))
                .where((f) => _query.isEmpty || f.name.toLowerCase().contains(_query.toLowerCase()))
                .toList();
            if (foods.isNotEmpty) byCat[cat] = foods;
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: TextField(
                  onChanged: (t) => setState(() => _query = t),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded, color: v.muted),
                    hintText: 'Search foods',
                    filled: true,
                    fillColor: v.isDark ? v.lineSoft : const Color(0xFFF0EEE4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                  children: [
                    for (final entry in byCat.entries) ...[
                      _CategorySection(
                        category: entry.key,
                        foods: entry.value,
                        likes: likes,
                        onToggle: (id) => ref.read(foodPrefsProvider.notifier).toggle(id),
                        onSelectAll: (ids, selectAll) {
                          final next = {...likes};
                          selectAll ? next.addAll(ids) : next.removeAll(ids);
                          ref.read(foodPrefsProvider.notifier).setAll(next);
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: VitaPrimaryButton(
                  label: likes.isEmpty ? 'Generate meals' : 'Generate meals · ${likes.length} liked',
                  icon: Icons.auto_awesome_rounded,
                  loading: _busy,
                  onPressed: () => _generate(ignoreFilter: false),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.foods,
    required this.likes,
    required this.onToggle,
    required this.onSelectAll,
  });
  final String category;
  final List<Food> foods;
  final Set<String> likes;
  final ValueChanged<String> onToggle;
  final void Function(Iterable<String> ids, bool selectAll) onSelectAll;

  @override
  Widget build(BuildContext context) {
    final ids = foods.map((f) => f.id).toList();
    final allSelected = ids.every(likes.contains);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(kFoodCategoryLabels[category] ?? category,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.vita.ink)),
            const Spacer(),
            GestureDetector(
              onTap: () => onSelectAll(ids, !allSelected),
              child: Text(allSelected ? 'Clear' : 'Select all',
                  style: TextStyle(color: context.vita.brand, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in foods)
              SelectChip(label: f.name, selected: likes.contains(f.id), onTap: () => onToggle(f.id)),
          ],
        ),
      ],
    );
  }
}
