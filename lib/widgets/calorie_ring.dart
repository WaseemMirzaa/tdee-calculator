import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// A number that counts up from 0 to [value] on first build. Tabular mono.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.size = 40,
    this.color,
    this.duration = VitaMotion.reveal,
    this.suffix = '',
  });

  final double value;
  final double size;
  final Color? color;
  final Duration duration;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? value : 0, end: value),
      duration: reduce ? Duration.zero : duration,
      curve: VitaMotion.curve,
      builder: (context, v, _) => Text(
        '${v.round()}$suffix',
        style: context.mono(size: size, weight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// The hero energy ring: an arc in the emerald→lime gradient with a value in
/// the centre. [fraction] fills the arc (0..1). Signal Lime is reserved here.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.value,
    this.label = 'kcal / day',
    this.fraction = 0.72,
    this.size = 190,
    this.emoji = '🔥',
    this.trackColor,
    this.arcColors,
    this.textColor,
    this.labelColor,
  });

  final double value;
  final String label;
  final double fraction;
  final double size;
  final String emoji;
  final Color? trackColor;
  final List<Color>? arcColors;
  final Color? textColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduce ? fraction : 0, end: fraction.clamp(0, 1)),
            duration: reduce ? Duration.zero : VitaMotion.slow,
            curve: VitaMotion.curve,
            builder: (context, f, _) => CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                fraction: f,
                track: trackColor ?? v.lineSoft,
                arc: arcColors ?? [v.brand, v.accent],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              CountUpText(value: value, size: size * 0.21, color: textColor),
              Text(label.toUpperCase(),
                  style: context.monoLabel(size: 10, color: labelColor ?? v.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.track, required this.arc});
  final double fraction;
  final Color track;
  final List<Color> arc;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.075;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * fraction;
    final arcPaint = Paint()
      ..shader = LinearGradient(colors: arc)
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.arc != arc;
}
