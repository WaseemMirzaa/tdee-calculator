import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/meal.dart';
import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/vita.dart';

/// S12 · Meal detail. Ingredients / Making tabs + a macro summary header and a
/// serving scaler that recomputes grams & kcal live.
class MealDetailScreen extends ConsumerStatefulWidget {
  const MealDetailScreen({super.key, required this.mealId});
  final String mealId;

  @override
  ConsumerState<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends ConsumerState<MealDetailScreen> {
  int _tab = 0;
  double _servings = 1;

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider).valueOrNull;
    final meal = seed?.mealById(widget.mealId);
    final v = context.vita;
    if (meal == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? <String>{};
    final fav = favorites.contains(meal.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(meal.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: fav ? VitaColors.protein : v.muted),
            onPressed: () => ref.read(favoritesProvider.notifier).toggle(meal.id),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          // Macro summary header (scaled by servings)
          VitaCard(
            child: Row(
              children: [
                MacroDonut(
                  proteinG: meal.protein * _servings,
                  carbG: meal.carbs * _servings,
                  fatG: meal.fat * _servings,
                  size: 76,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${(meal.calories * _servings).round()} kcal', style: context.mono(size: 22)),
                      Text('${kMealTypeLabels[meal.type]} · ${meal.timeMinutes} min', style: TextStyle(color: v.muted, fontSize: 12.5)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 12, runSpacing: 4, children: [
                        _macroTag('Protein', meal.protein * _servings),
                        _macroTag('Carbs', meal.carbs * _servings),
                        _macroTag('Fat', meal.fat * _servings),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Serving scaler
          Row(
            children: [
              Text('Servings', style: TextStyle(fontWeight: FontWeight.w700, color: v.ink)),
              const Spacer(),
              _ScaleBtn(icon: Icons.remove_rounded, onTap: _servings > 0.5 ? () => setState(() => _servings -= 0.5) : null),
              SizedBox(width: 48, child: Center(child: Text(_servings.toStringAsFixed(1), style: context.mono(size: 17)))),
              _ScaleBtn(icon: Icons.add_rounded, onTap: _servings < 6 ? () => setState(() => _servings += 0.5) : null),
            ],
          ),
          const SizedBox(height: 14),

          VitaSegmented<int>(
            value: _tab,
            onChanged: (t) => setState(() => _tab = t),
            segments: const [VitaSegment(0, 'Ingredients'), VitaSegment(1, 'Making')],
          ),
          const SizedBox(height: 16),

          if (_tab == 0)
            _IngredientsList(meal: meal, servings: _servings)
          else
            _StepsList(meal: meal),
        ],
      ),
    );
  }

  Widget _macroTag(String label, double grams) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: macroColor(label), shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text('${grams.round()}g', style: context.mono(size: 12, color: context.vita.inkSoft)),
      ],
    );
  }
}

class _IngredientsList extends StatelessWidget {
  const _IngredientsList({required this.meal, required this.servings});
  final Meal meal;
  final double servings;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return VitaCard(
      child: Column(
        children: [
          for (var i = 0; i < meal.ingredients.length; i++) ...[
            if (i > 0) Divider(color: v.lineSoft, height: 20),
            Row(
              children: [
                Expanded(child: Text(meal.ingredients[i].name, style: TextStyle(color: v.ink, fontSize: 14.5))),
                Text(
                  _amount(meal.ingredients[i], servings),
                  style: context.mono(size: 13, color: v.muted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _amount(Ingredient ing, double s) {
    final kcal = (ing.kcal * s).round();
    if (ing.grams != null && ing.grams! > 0) {
      return '${(ing.grams! * s).round()} g · $kcal kcal';
    }
    return '${ing.amount} · $kcal kcal';
  }
}

class _StepsList extends StatelessWidget {
  const _StepsList({required this.meal});
  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < meal.steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26, height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: v.brand.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: Text('${i + 1}', style: context.mono(size: 13, color: v.brandDeep)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(meal.steps[i], style: TextStyle(color: v.inkSoft, height: 1.5, fontSize: 14.5))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScaleBtn extends StatelessWidget {
  const _ScaleBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: v.card, shape: BoxShape.circle, border: Border.all(color: v.line)),
        child: Icon(icon, size: 18, color: onTap == null ? v.muted.withValues(alpha: 0.4) : v.ink),
      ),
    );
  }
}
