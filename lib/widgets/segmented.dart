import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// A tactile segmented control (M/F, Maintain/Cut/Bulk, unit toggle, tabs).
class VitaSegmented<T> extends StatelessWidget {
  const VitaSegmented({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
  });

  final T value;
  final List<VitaSegment<T>> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: v.isDark ? v.lineSoft : const Color(0xFFEDEBE1),
        borderRadius: BorderRadius.circular(VitaRadius.pill),
      ),
      child: Row(
        children: [
          for (final s in segments)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(s.value),
                child: AnimatedContainer(
                  duration: VitaMotion.fast,
                  curve: VitaMotion.curve,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: s.value == value ? v.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(VitaRadius.pill),
                    border: s.value == value ? Border.all(color: v.line) : null,
                  ),
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: s.value == value ? v.ink : v.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VitaSegment<T> {
  const VitaSegment(this.value, this.label);
  final T value;
  final String label;
}
