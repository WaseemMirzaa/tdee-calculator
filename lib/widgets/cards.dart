import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// The base surface for everything: soft card, warm hairline, low wide shadow.
class VitaCard extends StatelessWidget {
  const VitaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accent = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final card = AnimatedContainer(
      duration: VitaMotion.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: v.card,
        borderRadius: VitaRadius.cardR,
        border: Border.all(color: accent ? v.brand.withOpacity(0.4) : v.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(v.isDark ? 0.35 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -18,
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: VitaRadius.cardR, onTap: onTap, child: card),
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
