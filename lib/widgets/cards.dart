import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// The base surface for everything — a premium card with a barely-there vertical
/// gradient for depth, a hairline border, and a two-layer shadow (a tight
/// contact shadow + a wide soft ambient). Pass [glow] for a coloured halo
/// (hero cards) or [gradient] to override the surface entirely.
class VitaCard extends StatelessWidget {
  const VitaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accent = false,
    this.glow,
    this.gradient,
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool accent;
  final Color? glow;
  final Gradient? gradient;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final br = BorderRadius.circular(radius);

    final surface = gradient ??
        LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            // A subtle glass sheen: a touch lighter at the top, settling to card.
            v.isDark ? Color.lerp(v.card, Colors.white, 0.05)! : Colors.white,
            v.isDark ? v.card : Color.lerp(v.card, v.ground, 0.38)!,
          ],
        );

    final card = AnimatedContainer(
      duration: VitaMotion.fast,
      padding: padding,
      decoration: BoxDecoration(
        gradient: surface,
        borderRadius: br,
        border: Border.all(
          color: accent ? v.brand.withOpacity(0.45) : v.line,
          width: accent ? 1.4 : 1,
        ),
        boxShadow: [
          // Contact shadow — tight and close.
          BoxShadow(
            color: Colors.black.withOpacity(v.isDark ? 0.45 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: -4,
          ),
          // Ambient — wide and soft, tinted by [glow] when set.
          BoxShadow(
            color: glow != null
                ? glow!.withOpacity(v.isDark ? 0.34 : 0.24)
                : Colors.black.withOpacity(v.isDark ? 0.40 : 0.05),
            blurRadius: glow != null ? 36 : 42,
            offset: const Offset(0, 20),
            spreadRadius: glow != null ? -6 : -22,
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        splashColor: v.brand.withOpacity(0.06),
        highlightColor: v.brand.withOpacity(0.03),
        child: card,
      ),
    );
  }
}

/// A small uppercase mono section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: context.monoLabel(color: color ?? context.vita.muted));
  }
}

/// A screen section heading (title + optional subtitle).
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.vt.headlineMedium?.copyWith(fontSize: 26)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: TextStyle(color: v.inkSoft, fontSize: 15, height: 1.4)),
        ],
      ],
    );
  }
}
