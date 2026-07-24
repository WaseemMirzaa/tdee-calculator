import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// Canonical macro colours (kept perceptually distinct).
Color macroColor(String macro) {
  switch (macro.toLowerCase()) {
    case 'protein':
      return VitaColors.protein;
    case 'carbs':
    case 'carb':
      return VitaColors.carbs;
    case 'fat':
    case 'fats':
      return VitaColors.fat;
    default:
      return VitaColors.emerald;
  }
}

class MacroDatum {
  const MacroDatum(this.label, this.grams);
  final String label;
  final double grams;
}

/// Three animated bars (protein / carbs / fat) with gram readouts.
class MacroBars extends StatelessWidget {
  const MacroBars({super.key, required this.protein, required this.carbs, required this.fat});
  final double protein;
  final double carbs;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final data = [MacroDatum('Protein', protein), MacroDatum('Carbs', carbs), MacroDatum('Fat', fat)];
    final maxG = data.map((d) => d.grams).fold(1.0, math.max);
    return Column(
      children: [
        for (final d in data) ...[
          _Bar(datum: d, fraction: (d.grams / maxG).clamp(0.05, 1.0)),
          if (d != data.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.datum, required this.fraction});
  final MacroDatum datum;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final c = macroColor(datum.label);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(datum.label, style: TextStyle(fontWeight: FontWeight.w700, color: v.ink, fontSize: 13.5)),
            Text('${datum.grams.round()} g', style: context.mono(size: 13, color: v.muted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(
            children: [
              Container(height: 8, color: v.lineSoft),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: reduce ? fraction : 0, end: fraction),
                duration: reduce ? Duration.zero : VitaMotion.slow,
                curve: VitaMotion.curve,
                builder: (context, f, _) => FractionallySizedBox(
                  widthFactor: f,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(99)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A macro donut (protein/carbs/fat by calorie share) for the macros cards.
class MacroDonut extends StatelessWidget {
  const MacroDonut({
    super.key,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    this.size = 72,
  });
  final double proteinG;
  final double carbG;
  final double fatG;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pCal = proteinG * 4, cCal = carbG * 4, fCal = fatG * 9;
    final total = (pCal + cCal + fCal).clamp(1, double.infinity);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          fractions: [pCal / total, cCal / total, fCal / total],
          colors: const [VitaColors.protein, VitaColors.carbs, VitaColors.fat],
          track: context.vita.lineSoft,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.fractions, required this.colors, required this.track});
  final List<double> fractions;
  final List<Color> colors;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius,
        Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = stroke);

    double start = -math.pi / 2;
    const gap = 0.06;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = 2 * math.pi * fractions[i] - gap;
      if (sweep <= 0) {
        start += 2 * math.pi * fractions[i];
        continue;
      }
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      start += 2 * math.pi * fractions[i];
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.fractions != fractions;
}

/// A tiny legend dot + label used beside donuts.
class MacroLegendDot extends StatelessWidget {
  const MacroLegendDot({super.key, required this.label, required this.grams});
  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: macroColor(label), shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(fontSize: 13, color: context.vita.inkSoft, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${grams.round()} g', style: context.mono(size: 13)),
      ],
    );
  }
}
