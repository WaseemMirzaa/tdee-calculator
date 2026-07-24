import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// A multi-select chip (food preferences) or a static info chip.
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VitaMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? v.brand.withOpacity(0.14) : (v.isDark ? v.lineSoft : const Color(0xFFF0EEE4)),
          borderRadius: BorderRadius.circular(VitaRadius.pill),
          border: Border.all(color: selected ? v.brand : Colors.transparent, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 15, color: v.brand),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? v.brandDeep : v.inkSoft)),
          ],
        ),
      ),
    );
  }
}

/// A small static label chip (diet exclusions).
class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: v.isDark ? v.lineSoft : const Color(0xFFF0EEE4),
        borderRadius: BorderRadius.circular(VitaRadius.pill),
      ),
      child: Text(label, style: TextStyle(fontSize: 11.5, color: v.muted, fontWeight: FontWeight.w600)),
    );
  }
}
