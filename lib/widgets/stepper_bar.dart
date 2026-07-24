import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// A slim onboarding progress bar: [current] of [total] steps (1-indexed).
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({super.key, required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: VitaMotion.base,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: i <= current
                    ? LinearGradient(colors: [v.brand, v.accent])
                    : null,
                color: i <= current ? null : v.lineSoft,
              ),
            ),
          ),
          if (i != total) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
