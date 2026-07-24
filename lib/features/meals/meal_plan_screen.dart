import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db/app_database.dart';
import '../../core/meal_planner.dart';
import '../../core/models/meal.dart';
import '../../core/tdee_engine.dart';
import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';
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
                if (!context.mounted) return;
                // Land on the Meals tab (start state), never a blank pushed screen.
                ref.read(homeTabProvider.notifier).state = 1;
                context.go(Routes.home);
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
    // Append one day; existing days are preserved untouched.
    final newDay = await ref.read(planProvider.notifier).appendDay(targetCalories: target);
    if (mounted) {
      setState(() {
        _busy = false;
        _day = newDay;
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
    final seed = ref.read(seedProvider).valueOrNull;
    final totals = <String, _ShopItem>{};
    for (final d in days) {
      for (final m in d.meals) {
        for (final ing in m.ingredients) {
          final cat = seed?.foodById(ing.foodId ?? '')?.category ?? 'other';
          final existing = totals[ing.name];
          if (existing == null) {
            totals[ing.name] = _ShopItem(ing.name, ing.grams ?? 0, cat);
          } else {
            existing.grams += ing.grams ?? 0;
          }
        }
      }
    }
    final items = totals.values.toList()
      ..sort((a, b) => a.category == b.category
          ? a.name.compareTo(b.name)
          : a.category.compareTo(b.category));

    final startMs = int.tryParse(ref.read(dbProvider).getSettingSync('plan_start') ?? '');
    final start = startMs != null ? DateTime.fromMillisecondsSinceEpoch(startMs) : DateTime.now();
    final finish = DateTime(start.year, start.month, start.day + days.length);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // critical — otherwise the sheet is tiny/clipped
      backgroundColor: context.vita.card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => _ShoppingSheet(items: items, planDays: days.length, finishDate: finish),
    );
  }
}

/// One aggregated shopping-list line (grams summed across the plan).
class _ShopItem {
  _ShopItem(this.name, this.grams, this.category);
  final String name;
  double grams;
  final String category;
}

/// An interactive shopping list backed by the persistent kitchen: tap an item
/// to mark it "already have" (it moves to your kitchen and is remembered).
/// Shows how long the plan lasts and can schedule a restock reminder.
class _ShoppingSheet extends ConsumerStatefulWidget {
  const _ShoppingSheet({required this.items, required this.planDays, required this.finishDate});
  final List<_ShopItem> items;
  final int planDays;
  final DateTime finishDate;

  @override
  ConsumerState<_ShoppingSheet> createState() => _ShoppingSheetState();
}

class _ShoppingSheetState extends ConsumerState<_ShoppingSheet> {
  late int _lead = int.tryParse(ref.read(dbProvider).getSettingSync('shop_lead_days') ?? '2') ?? 2;

  static String _catLabel(String c) {
    const labels = {
      'protein': 'Protein', 'carbs': 'Carbs', 'fat': 'Fats & oils',
      'fruits': 'Fruits', 'vegetables': 'Vegetables', 'dairy': 'Dairy & drinks',
      'other': 'Pantry & spices',
    };
    return labels[c] ?? 'Other';
  }

  DateTime get _remindWhen {
    final base = widget.finishDate.subtract(Duration(days: _lead));
    return DateTime(base.year, base.month, base.day, 18);
  }

  void _toast(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _setLead(int d) async {
    setState(() => _lead = d);
    await ref.read(dbProvider).setSetting('shop_lead_days', '$d');
    if (d == 0) {
      await NotificationService.instance.cancelRestockReminder();
      await ref.read(kitchenProvider.notifier).rescheduleReminders(); // cancels item reminders too
      _toast('Reminders turned off');
      return;
    }
    final granted = await NotificationService.instance.requestPermission();
    if (!granted) {
      _toast('Enable notifications to get reminders');
      return;
    }
    await NotificationService.instance
        .scheduleRestockReminder(when: _remindWhen, planDays: widget.planDays);
    await ref.read(kitchenProvider.notifier).rescheduleReminders(); // apply new lead to items
    _toast("We'll remind you on ${DateFormat('EEE, MMM d').format(_remindWhen)}");
  }

  /// Preset day-supply picker for a kitchen item.
  Future<void> _editDays(String name) async {
    final v = context.vita;
    final current = ref.read(kitchenProvider).valueOrNull?[name];
    const presets = [0, 3, 5, 7, 10, 14, 21, 30];
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: v.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How much $name do you have?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: v.ink)),
              const SizedBox(height: 4),
              Text('We deduct a day automatically and remind you before it runs out.',
                  style: TextStyle(color: v.muted, fontSize: 12.5)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final d in presets)
                    ChoiceChip(
                      label: Text(d == 0 ? 'Have it' : '$d days'),
                      selected: (current?.days ?? 0) == d,
                      onSelected: (_) => Navigator.pop(context, d),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) {
      await ref.read(kitchenProvider.notifier).setDays(name, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final kitchen = ref.watch(kitchenProvider).valueOrNull ?? const <String, KitchenItem>{};
    final toBuy = widget.items.where((i) => !kitchen.containsKey(i.name)).toList();
    final have = widget.items.where((i) => kitchen.containsKey(i.name)).toList();

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 2, 22, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shopping list', style: context.vt.titleLarge),
                        Text(
                          'Lasts ${widget.planDays} days · ends ${DateFormat('MMM d').format(widget.finishDate)}',
                          style: TextStyle(color: v.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 46, height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: v.brand.withOpacity(0.12), shape: BoxShape.circle),
                    child: const Text('🛒', style: TextStyle(fontSize: 22)),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                children: [
                  _ReminderCard(lead: _lead, remindWhen: _remindWhen, onLead: _setLead),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 16, 2, 4),
                    child: SectionLabel('To buy · ${toBuy.length}'),
                  ),
                  if (toBuy.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Everything is in your kitchen 🎉',
                          style: TextStyle(color: v.muted, fontSize: 14)),
                    )
                  else
                    ..._grouped(toBuy),
                  if (have.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 20, 2, 4),
                      child: SectionLabel('In your kitchen · ${have.length}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 4),
                      child: Text('Tap the days chip to set how long each lasts.',
                          style: TextStyle(color: v.muted, fontSize: 12)),
                    ),
                    for (final it in have) _kitchenRow(it, kitchen[it.name]!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _grouped(List<_ShopItem> items) {
    final rows = <Widget>[];
    String? lastCat;
    for (final it in items) {
      if (it.category != lastCat) {
        lastCat = it.category;
        rows.add(Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 4),
          child: Text(_catLabel(it.category),
              style: TextStyle(fontWeight: FontWeight.w700, color: context.vita.inkSoft, fontSize: 13)),
        ));
      }
      rows.add(_itemRow(it, inKitchen: false));
    }
    return rows;
  }

  Widget _itemRow(_ShopItem it, {required bool inKitchen}) {
    final v = context.vita;
    return InkWell(
      onTap: () => ref.read(kitchenProvider.notifier).toggle(it.name),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: VitaMotion.fast,
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: inKitchen ? v.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: inKitchen ? v.brand : v.line, width: 1.6),
              ),
              child: inKitchen ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(it.name,
                  style: TextStyle(
                    color: inKitchen ? v.muted : v.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: inKitchen ? TextDecoration.lineThrough : null,
                  )),
            ),
            if (it.grams > 0)
              Text('${it.grams.round()} g', style: context.mono(size: 13, color: v.muted)),
          ],
        ),
      ),
    );
  }

  /// A kitchen row: tick to remove, plus a supply-days chip that auto-deducts
  /// and drives the low-stock reminder.
  Widget _kitchenRow(_ShopItem it, KitchenItem k) {
    final v = context.vita;
    final tracked = k.tracked;
    final remaining = k.remainingDays();
    final out = tracked && remaining == 0;
    final low = tracked && remaining != null && remaining > 0 && remaining <= 2;
    final chipColor = out ? VitaColors.crit : (low ? VitaColors.warn : v.brand);
    final chipText = !tracked ? 'Set days' : (out ? 'Out' : '$remaining d left');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(kitchenProvider.notifier).toggle(it.name),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: v.brand,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: v.brand, width: 1.6),
              ),
              child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.name,
                    style: TextStyle(color: v.ink, fontSize: 15, fontWeight: FontWeight.w600)),
                if (tracked && !out)
                  Text('Runs out ${DateFormat('MMM d').format(k.runOutDate()!)}',
                      style: TextStyle(color: v.muted, fontSize: 11.5)),
                if (out)
                  const Text('Supply finished — restock soon',
                      style: TextStyle(color: VitaColors.crit, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _editDays(it.name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: chipColor.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tracked ? Icons.schedule_rounded : Icons.add_rounded, size: 14, color: chipColor),
                  const SizedBox(width: 5),
                  Text(chipText,
                      style: TextStyle(color: chipColor, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The restock-reminder control: choose how many days ahead to be reminded.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.lead, required this.remindWhen, required this.onLead});
  final int lead;
  final DateTime remindWhen;
  final ValueChanged<int> onLead;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: v.brand.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: v.brand.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded, size: 18, color: v.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Restock reminder',
                    style: TextStyle(fontWeight: FontWeight.w800, color: v.ink, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lead == 0
                ? "Off — we won't remind you."
                : "We'll notify you on ${DateFormat('EEE, MMM d').format(remindWhen)}.",
            style: TextStyle(color: v.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 12),
          VitaSegmented<int>(
            value: lead,
            onChanged: onLead,
            segments: const [
              VitaSegment(2, '2 days'),
              VitaSegment(1, '1 day'),
              VitaSegment(0, 'Off'),
            ],
          ),
        ],
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
              _IconTap(
                tooltip: isFavorite ? 'Remove favorite' : 'Add to favorites',
                icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? VitaColors.protein : v.muted,
                onTap: onFavorite,
              ),
              _IconTap(
                tooltip: 'Swap meal',
                icon: Icons.swap_horiz_rounded,
                color: v.brand,
                onTap: onSwap,
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

/// A 44×44 accessible icon button (meets the minimum tap-target guideline).
class _IconTap extends StatelessWidget {
  const _IconTap({required this.icon, required this.color, required this.onTap, required this.tooltip});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 26,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 21, color: color)),
        ),
      ),
    );
  }
}
