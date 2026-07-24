import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/tdee_engine.dart';
import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// S5 · Home / Results dashboard. The number is the hero: a glowing calorie
/// ring, macro bars, an interactive PAL accordion, entry cards, and the metric
/// grid. Everything is free — no locks.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(resultProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final v = context.vita;

    if (result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final maintainModerate = result.macroMatrix[CalorieMode.maintain]![CarbProfile.moderate]!;
    final greeting = profile?.name != null && profile!.name!.isNotEmpty
        ? 'Hi ${profile.name} 👋'
        : 'Your daily energy';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: context.vt.titleLarge),
                  Text('Here’s your metabolic snapshot',
                      style: TextStyle(color: v.muted, fontSize: 13)),
                ],
              ),
            ),
            _RoundIcon(
              icon: Icons.settings_rounded,
              onTap: () => ref.read(homeTabProvider.notifier).state = 3,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- TDEE hero: a bold brand-gradient spotlight ---
        VitaCard(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
          glow: v.brand,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [v.brandDeep, v.brand],
          ),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SectionLabel('Total daily energy · TDEE', color: Colors.white70),
                  SizedBox(width: 6),
                  Icon(Icons.info_outline_rounded, size: 15, color: Colors.white54),
                ],
              ),
              const SizedBox(height: 12),
              CalorieRing(
                value: result.tdee,
                size: 204,
                fraction: result.tdee / result.palBreakdown[ActivityLevel.extreme]!,
                trackColor: Colors.white.withOpacity(0.22),
                arcColors: [v.accent, Colors.white],
                textColor: Colors.white,
                labelColor: Colors.white70,
              ),
              const SizedBox(height: 6),
              Text('Maintenance · what holds your weight steady',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.5)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // --- Macros at maintenance ---
        VitaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SectionLabel('Macros at maintenance'),
                  const Spacer(),
                  Text('moderate carbs', style: TextStyle(color: v.muted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),
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
          child: const _RowCard(
            emoji: '🥗',
            title: 'Energy to lose or gain',
            subtitle: 'Targets for every rate of change',
          ),
        ),
        const SizedBox(height: 12),
        VitaCard(
          onTap: () => context.push(Routes.macros),
          child: const _RowCard(
            emoji: '🍽',
            title: 'Macronutrients',
            subtitle: 'Maintain · cutting · bulking splits',
          ),
        ),
        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 10),
          child: SectionLabel('Health metrics'),
        ),
        _MetricsGrid(result: result),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: v.card, shape: BoxShape.circle, border: Border.all(color: v.line)),
        child: Icon(icon, size: 20, color: v.inkSoft),
      ),
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
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [v.brand.withOpacity(0.16), v.brand.withOpacity(0.06)],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
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
            valueColor: AlwaysStoppedAnimation(v.brand),
          ),
        ),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.result});
  final TdeeResult result;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        MetricCard(
          label: 'BMI',
          value: result.bmi.toStringAsFixed(1),
          caption: _bmiLabel(result.bmiCategory),
          icon: Icons.speed_rounded,
          accentColor: VitaColors.fat,
          onTap: () => context.push('${Routes.metric}/bmi'),
        ),
        MetricCard(
          label: 'BMR',
          value: '${result.bmr.round()}',
          caption: 'kcal/day at rest',
          icon: Icons.local_fire_department_rounded,
          accentColor: VitaColors.ember,
          onTap: () => context.push('${Routes.metric}/bmr'),
        ),
        MetricCard(
          label: 'RMR',
          value: '${result.rmr.round()}',
          caption: 'kcal/day resting',
          icon: Icons.bedtime_rounded,
          accentColor: VitaColors.protein,
          onTap: () => context.push('${Routes.metric}/rmr'),
        ),
        MetricCard(
          label: 'IBW',
          value: '${result.ibw.minKg.round()}–${result.ibw.maxKg.round()}',
          caption: 'ideal range · kg',
          icon: Icons.straighten_rounded,
          accentColor: VitaColors.good,
          onTap: () => context.push('${Routes.metric}/ibw'),
        ),
      ],
    );
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
