import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// A compact metric tile (BMI / BMR / RMR / IBW) for the results grid.
/// [locked] blurs nothing here (value is shown free per spec) but shows a lock
/// glyph indicating the *detail view* is Pro. Tapping calls [onTap].
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.onTap,
    this.locked = false,
    this.accentColor,
  });

  final String label;
  final String value;
  final String? caption;
  final VoidCallback? onTap;
  final bool locked;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: v.card,
          borderRadius: VitaRadius.smR,
          border: Border.all(color: v.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: v.muted)),
                const Spacer(),
                Icon(locked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                    size: 14, color: locked ? v.muted : v.brand),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: context.mono(size: 18, color: accentColor ?? v.ink)),
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(caption!, style: TextStyle(fontSize: 11.5, color: v.muted)),
            ],
          ],
        ),
      ),
    );
  }
}
