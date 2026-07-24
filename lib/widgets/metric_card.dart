import 'package:flutter/material.dart';
import '../core/theme/vita_theme.dart';
import 'cards.dart';

/// A premium metric tile (BMI / BMR / RMR / IBW) for the results grid: a
/// tinted icon chip, a mono value in the metric's accent colour, and a caption.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return VitaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const Spacer(),
              Icon(Icons.north_east_rounded, size: 15, color: v.muted),
            ],
          ),
          const SizedBox(height: 12),
          Text(label.toUpperCase(), style: context.monoLabel(size: 10)),
          const SizedBox(height: 3),
          Text(value, style: context.mono(size: 19, color: v.ink)),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(caption!, style: TextStyle(fontSize: 11.5, color: v.muted)),
          ],
        ],
      ),
    );
  }
}
