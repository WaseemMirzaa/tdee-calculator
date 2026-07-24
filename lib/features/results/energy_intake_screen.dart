import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// S6 · Energy intake to lose or gain weight. Two cards; each rate row shows
/// kcal/day and % of maintenance as a mini bar. Rows hand off to the Journey
/// simulator, pre-set to that rate.
class EnergyIntakeScreen extends ConsumerWidget {
  const EnergyIntakeScreen({super.key});

  static const _loseRows = [
    ('mild_0.25', 'Mild loss', '0.25 kg / week'),
    ('loss_0.5', 'Weight loss', '0.5 kg / week'),
    ('extreme_1.0', 'Extreme loss', '1 kg / week'),
  ];
  static const _gainRows = [
    ('mild_0.25', 'Mild gain', '0.25 kg / week'),
    ('gain_0.5', 'Weight gain', '0.5 kg / week'),
    ('extreme_1.0', 'Extreme gain', '1 kg / week'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(resultProvider);
    if (result == null) return const Scaffold(body: SizedBox.shrink());
    final maint = result.maintenanceCalories;

    void openJourney() {
      context.pop();
      ref.read(homeTabProvider.notifier).state = 2;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Energy intake')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          _EnergyCard(
            title: 'To lose weight',
            color: VitaColors.emerald,
            rows: [
              for (final r in _loseRows)
                _RateData(r.$2, r.$3, result.loseTargets[r.$1]!, result.loseTargets[r.$1]! / maint),
            ],
            onTapRow: (_) => openJourney(),
          ),
          const SizedBox(height: 14),
          _EnergyCard(
            title: 'To gain weight',
            color: VitaColors.ember,
            rows: [
              for (final r in _gainRows)
                _RateData(r.$2, r.$3, result.gainTargets[r.$1]!, result.gainTargets[r.$1]! / maint),
            ],
            onTapRow: (_) => openJourney(),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Tap a rate to project it on your Journey',
                style: context.mono(size: 12, color: context.vita.muted)),
          ),
        ],
      ),
    );
  }
}

class _RateData {
  const _RateData(this.title, this.sub, this.kcal, this.pct);
  final String title;
  final String sub;
  final double kcal;
  final double pct;
}

class _EnergyCard extends StatelessWidget {
  const _EnergyCard({required this.title, required this.color, required this.rows, required this.onTapRow});
  final String title;
  final Color color;
  final List<_RateData> rows;
  final ValueChanged<_RateData> onTapRow;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: color)),
          const SizedBox(height: 4),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: v.lineSoft, height: 22),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTapRow(rows[i]),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].title, style: TextStyle(fontWeight: FontWeight.w700, color: v.ink, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(rows[i].sub, style: TextStyle(color: v.muted, fontSize: 12.5)),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: rows[i].pct.clamp(0, 1.4) / 1.4,
                            minHeight: 5,
                            backgroundColor: v.lineSoft,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${rows[i].kcal.round()}', style: context.mono(size: 18)),
                      Text('${(rows[i].pct * 100).round()}%', style: TextStyle(color: v.muted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
