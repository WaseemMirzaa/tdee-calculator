import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/tdee_engine.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// S5 · Home / Results dashboard. The number is the hero: a calorie ring, macro
/// bars, an interactive PAL accordion, entry cards, and the metric grid.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(resultProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final isPremium = ref.watch(premiumProvider);
    final v = context.vita;

    if (result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final maintainModerate = result.macroMatrix[CalorieMode.maintain]![CarbProfile.moderate]!;
    final greeting = profile?.name != null && profile!.name!.isNotEmpty
        ? 'Hi ${profile.name},'
        : 'Your daily energy';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Row(
          children: [
            Expanded(child: Text(greeting, style: context.vt.titleLarge)),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: v.muted),
              onPressed: () => ref.read(homeTabProvider.notifier).state = 3,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!isPremium) ...[
          PremiumBanner(onTap: () => context.push(Routes.paywall)),
          const SizedBox(height: 16),
        ],

        // --- TDEE hero card ---
        VitaCard(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SectionLabel('Total daily energy · TDEE'),
                  const SizedBox(width: 6),
                  Icon(Icons.info_outline_rounded, size: 15, color: v.muted),
                ],
              ),
              const SizedBox(height: 8),
              CalorieRing(
                value: result.tdee,
                fraction: result.tdee / result.palBreakdown[ActivityLevel.extreme]!,
              ),
              const SizedBox(height: 18),
              MacroBars(
                protein: maintainModerate.proteinG,
                carbs: maintainModerate.carbG,
                fat: maintainModerate.fatG,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _PalAccordion(result: result),
        const SizedBox(height: 12),

        // --- Entry cards ---
        VitaCard(
          onTap: () => context.push(Routes.energy),
          child: _RowCard(
            emoji: '🥗',
            title: 'Energy to lose or gain',
            subtitle: 'Targets for every rate of change',
          ),
        ),
        const SizedBox(height: 12),
        VitaCard(
          onTap: () => context.push(Routes.macros),
          child: _RowCard(
            emoji: '🍽',
            title: 'Macronutrients',
            subtitle: 'Maintain · cutting · bulking splits',
          ),
        ),
        const SizedBox(height: 18),

        const SectionLabel('Health metrics'),
        const SizedBox(height: 10),
        _MetricsGrid(result: result, isPremium: isPremium),

        const SizedBox(height: 16),
        const Center(child: AdSlot()),
      ],
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({required this.emoji, required this.title, required this.subtitle});
  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Row(
      children: [
        Container(
          width: 46, height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: v.brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: v.ink)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: v.muted)),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_rounded, size: 18, color: v.brand),
      ],
    );
  }
}

class _PalAccordion extends StatefulWidget {
  const _PalAccordion({required this.result});
  final TdeeResult result;

  @override
  State<_PalAccordion> createState() => _PalAccordionState();
}

class _PalAccordionState extends State<_PalAccordion> {
  bool _open = false;

  static const _labels = {
    ActivityLevel.sedentary: 'Sedentary',
    ActivityLevel.light: 'Lightly active',
    ActivityLevel.moderate: 'Moderately active',
    ActivityLevel.veryActive: 'Very active',
    ActivityLevel.extreme: 'Extreme',
  };

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final pal = widget.result.palBreakdown;
    final maxV = pal[ActivityLevel.extreme]!;
    return VitaCard(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Calories by activity level',
                    style: TextStyle(fontWeight: FontWeight.w700, color: v.ink, fontSize: 15)),
              ),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: VitaMotion.fast,
                child: Icon(Icons.keyboard_arrow_down_rounded, color: v.muted),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: VitaMotion.base,
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  for (final level in ActivityLevel.values) ...[
                    _PalRow(label: _labels[level]!, value: pal[level]!, fraction: pal[level]! / maxV),
                    if (level != ActivityLevel.extreme) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PalRow extends StatelessWidget {
  const _PalRow({required this.label, required this.value, required this.fraction});
  final String label;
  final double value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontSize: 13.5, color: v.inkSoft, fontWeight: FontWeight.w600))),
            Text('${value.round()} kcal', style: context.mono(size: 13)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: v.lineSoft,
            valueColor: const AlwaysStoppedAnimation(_palColor),
          ),
        ),
      ],
    );
  }

  static const _palColor = Color(0xFF0E9E6E);
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.result, required this.isPremium});
  final TdeeResult result;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final bmiCat = _bmiLabel(result.bmiCategory);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.85,
      children: [
        // BMI is fully locked for free users → routes to paywall.
        MetricCard(
          label: 'BMI',
          value: result.bmi.toStringAsFixed(1),
          caption: bmiCat,
          locked: !isPremium,
          onTap: () => _openMetric(context, 'bmi'),
        ),
        MetricCard(
          label: 'BMR',
          value: '${result.bmr.round()}',
          caption: 'kcal/day at rest',
          locked: !isPremium,
          onTap: () => _openMetric(context, 'bmr'),
        ),
        MetricCard(
          label: 'RMR',
          value: '${result.rmr.round()}',
          caption: 'kcal/day resting',
          locked: !isPremium,
          onTap: () => _openMetric(context, 'rmr'),
        ),
        MetricCard(
          label: 'IBW',
          value: '${result.ibw.minKg.round()}–${result.ibw.maxKg.round()}',
          caption: 'ideal range · kg',
          locked: !isPremium,
          onTap: () => _openMetric(context, 'ibw'),
        ),
      ],
    );
  }

  void _openMetric(BuildContext context, String type) {
    // BMI card is fully gated: free users go straight to the paywall.
    if (!isPremium && type == 'bmi') {
      context.push(Routes.paywall);
      return;
    }
    context.push('${Routes.metric}/$type');
  }

  static String _bmiLabel(BmiCategory c) {
    switch (c) {
      case BmiCategory.underweight:
        return 'Underweight';
      case BmiCategory.normal:
        return 'Normal';
      case BmiCategory.overweight:
        return 'Overweight';
      case BmiCategory.obese1:
        return 'Obese I';
      case BmiCategory.obese2:
        return 'Obese II';
      case BmiCategory.obese3:
        return 'Obese III';
    }
  }
}
