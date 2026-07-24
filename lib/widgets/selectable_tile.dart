import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// A large tappable option row used for goal / activity / diet selection.
/// Selected state: emerald border + check. Unselected: soft filled surface.
class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: VitaMotion.fast,
          curve: VitaMotion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: selected ? v.brand.withValues(alpha: 0.08) : (v.isDark ? v.lineSoft : const Color(0xFFF0EEE4)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? v.brand : Colors.transparent,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 13)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: v.ink)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!, style: TextStyle(fontSize: 12.5, color: v.muted, height: 1.3)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (trailing != null)
                trailing!
              else
                AnimatedScale(
                  duration: VitaMotion.fast,
                  scale: selected ? 1 : 0.6,
                  child: AnimatedOpacity(
                    duration: VitaMotion.fast,
                    opacity: selected ? 1 : 0,
                    child: Container(
                      width: 26, height: 26,
                      decoration: const BoxDecoration(color: VitaColors.emerald, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, size: 17, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
