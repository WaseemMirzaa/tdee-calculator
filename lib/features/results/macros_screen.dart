import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tdee_engine.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/vita.dart';

/// S8 · Macronutrients. Maintain / Cutting / Bulking tabs × Moderate / Lower /
/// High carb cards, each a donut + gram legend. Data from macroMatrix().
class MacrosScreen extends ConsumerStatefulWidget {
  const MacrosScreen({super.key});

  @override
  ConsumerState<MacrosScreen> createState() => _MacrosScreenState();
}

class _MacrosScreenState extends ConsumerState<MacrosScreen> {
  CalorieMode _mode = CalorieMode.maintain;

  static const _profiles = [
    (CarbProfile.moderate, 'Moderate carbs'),
    (CarbProfile.lower, 'Lower carbs'),
    (CarbProfile.high, 'High carbs'),
  ];

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(resultProvider);
    if (result == null) return const Scaffold(body: SizedBox.shrink());
    final byProfile = result.macroMatrix[_mode]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Macronutrients')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          VitaSegmented<CalorieMode>(
            value: _mode,
            onChanged: (m) => setState(() => _mode = m),
            segments: const [
              VitaSegment(CalorieMode.maintain, 'Maintain'),
              VitaSegment(CalorieMode.cutting, 'Cutting'),
              VitaSegment(CalorieMode.bulking, 'Bulking'),
            ],
          ),
          const SizedBox(height: 16),
          for (final p in _profiles) ...[
            _MacroCard(title: p.$2, macros: byProfile[p.$1]!),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({required this.title, required this.macros});
  final String title;
  final Macros macros;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return VitaCard(
      child: Row(
        children: [
          MacroDonut(proteinG: macros.proteinG, carbG: macros.carbG, fatG: macros.fatG, size: 88),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: v.ink))),
                    Text('${macros.calories.round()} kcal', style: context.mono(size: 13, color: v.muted)),
                  ],
                ),
                const SizedBox(height: 12),
                MacroLegendDot(label: 'Protein', grams: macros.proteinG),
                const SizedBox(height: 8),
                MacroLegendDot(label: 'Fat', grams: macros.fatG),
                const SizedBox(height: 8),
                MacroLegendDot(label: 'Carbs', grams: macros.carbG),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
