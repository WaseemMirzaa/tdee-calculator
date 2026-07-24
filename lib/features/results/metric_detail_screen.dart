import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/tdee_engine.dart';
import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// S7 · Health-metric detail. Value + category band + a plain-language
/// explainer. The deep explainer is a Pro feature (honest blurred preview).
class MetricDetailScreen extends ConsumerWidget {
  const MetricDetailScreen({super.key, required this.metric});
  final String metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(resultProvider);
    final isPremium = ref.watch(premiumProvider);
    if (result == null) return const Scaffold(body: SizedBox.shrink());

    final spec = _spec(metric, result);

    return Scaffold(
      appBar: AppBar(title: Text(spec.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          VitaCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                SectionLabel(spec.title),
                const SizedBox(height: 10),
                Text(spec.bigValue, style: context.mono(size: 42, color: context.vita.brand)),
                if (spec.caption != null) ...[
                  const SizedBox(height: 4),
                  Text(spec.caption!, style: TextStyle(color: context.vita.muted, fontSize: 14)),
                ],
                if (spec.gauge != null) ...[const SizedBox(height: 20), spec.gauge!],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (spec.rows.isNotEmpty) ...[
            VitaCard(
              child: Column(
                children: [
                  for (var i = 0; i < spec.rows.length; i++) ...[
                    if (i > 0) Divider(color: context.vita.lineSoft, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(spec.rows[i].$1, style: TextStyle(color: context.vita.inkSoft, fontSize: 14)),
                        Text(spec.rows[i].$2, style: context.mono(size: 14)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          LockedScrim(
            locked: !isPremium,
            onUnlock: () => context.push(Routes.paywall),
            child: VitaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 17, color: context.vita.brand),
                      const SizedBox(width: 8),
                      Text('What this means for you',
                          style: TextStyle(fontWeight: FontWeight.w800, color: context.vita.ink, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(spec.explainer, style: TextStyle(color: context.vita.inkSoft, height: 1.55, fontSize: 14.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _MetricSpec _spec(String metric, TdeeResult r) {
    switch (metric) {
      case 'bmr':
        return _MetricSpec(
          title: 'BMR',
          bigValue: '${r.bmr.round()}',
          caption: 'kcal/day — energy at complete rest',
          explainer:
              'Your basal metabolic rate is what your body burns just staying alive — breathing, circulation, cell repair — if you did nothing all day. Everything above this comes from movement and digestion. It anchors every calorie target in the app.',
        );
      case 'rmr':
        return _MetricSpec(
          title: 'RMR',
          bigValue: '${r.rmr.round()}',
          caption: 'kcal/day — resting metabolic rate',
          explainer:
              'Resting metabolic rate is measured under slightly less strict conditions than BMR, so in practice the two are within a rounding error. We compute them with the same validated equation and keep both for reference.',
        );
      case 'ibw':
        return _MetricSpec(
          title: 'Ideal body weight',
          bigValue: '${r.ibw.minKg.round()}–${r.ibw.maxKg.round()}',
          caption: 'kg — range across four formulas',
          rows: [
            ('Devine (1974)', '${r.ibw.devine.toStringAsFixed(1)} kg'),
            ('Robinson (1983)', '${r.ibw.robinson.toStringAsFixed(1)} kg'),
            ('Miller (1983)', '${r.ibw.miller.toStringAsFixed(1)} kg'),
            ('Hamwi (1964)', '${r.ibw.hamwi.toStringAsFixed(1)} kg'),
          ],
          explainer:
              'There is no single "correct" ideal weight — these four clinical formulas disagree, so we report the range. Treat it as a guide rail, not a verdict; body composition matters more than the scale alone.',
        );
      case 'bmi':
      default:
        return _MetricSpec(
          title: 'BMI',
          bigValue: r.bmi.toStringAsFixed(1),
          caption: '${_bmiLabel(r.bmiCategory)} · BMI prime ${r.bmiPrime.toStringAsFixed(2)}',
          gauge: _BmiGauge(bmi: r.bmi),
          rows: [
            ('Body fat (est.)', '${r.bodyFatPercent.toStringAsFixed(1)} %'),
            ('Lean mass', '${r.leanMassKg.toStringAsFixed(1)} kg'),
            ('Fat mass', '${r.fatMassKg.toStringAsFixed(1)} kg'),
          ],
          explainer:
              'BMI is a quick height-to-weight ratio — useful at a population level but blind to muscle. A lifter and a couch potato can share a BMI. Read it alongside your body-fat estimate and how your clothes fit.',
        );
    }
  }

  static String _bmiLabel(BmiCategory c) => switch (c) {
        BmiCategory.underweight => 'Underweight',
        BmiCategory.normal => 'Normal',
        BmiCategory.overweight => 'Overweight',
        BmiCategory.obese1 => 'Obese I',
        BmiCategory.obese2 => 'Obese II',
        BmiCategory.obese3 => 'Obese III',
      };
}

class _MetricSpec {
  _MetricSpec({
    required this.title,
    required this.bigValue,
    required this.explainer,
    this.caption,
    this.gauge,
    this.rows = const [],
  });
  final String title;
  final String bigValue;
  final String explainer;
  final String? caption;
  final Widget? gauge;
  final List<(String, String)> rows;
}

/// A horizontal BMI scale (15–40) with coloured zones and a marker at [bmi].
class _BmiGauge extends StatelessWidget {
  const _BmiGauge({required this.bmi});
  final double bmi;

  @override
  Widget build(BuildContext context) {
    const lo = 15.0, hi = 40.0;
    final t = ((bmi - lo) / (hi - lo)).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const Row(
                    children: [
                      Expanded(flex: 35, child: ColoredBox(color: VitaColors.fat, child: SizedBox(height: 10))),
                      Expanded(flex: 65, child: ColoredBox(color: VitaColors.emerald, child: SizedBox(height: 10))),
                      Expanded(flex: 50, child: ColoredBox(color: VitaColors.carbs, child: SizedBox(height: 10))),
                      Expanded(flex: 100, child: ColoredBox(color: VitaColors.crit, child: SizedBox(height: 10))),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: (w * t) - 8,
                top: 14,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: context.vita.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.vita.ink, width: 3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
