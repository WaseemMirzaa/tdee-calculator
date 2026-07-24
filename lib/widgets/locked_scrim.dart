import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// Blurs its [child] and overlays a lock + "Unlock in Pro" — the honest,
/// store-review-safe gating pattern (preview the real value, don't bait).
class LockedScrim extends StatelessWidget {
  const LockedScrim({
    super.key,
    required this.child,
    required this.locked,
    this.onUnlock,
    this.message = 'Unlock in Pro',
  });

  final Widget child;
  final bool locked;
  final VoidCallback? onUnlock;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    final v = context.vita;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ClipRRect(
            borderRadius: VitaRadius.cardR,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(
                alignment: Alignment.center,
                color: v.card.withValues(alpha: 0.55),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(VitaRadius.pill),
                    onTap: onUnlock,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: v.brand.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(VitaRadius.pill),
                        border: Border.all(color: v.brand.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 15, color: v.brandDeep),
                          const SizedBox(width: 7),
                          Text(message,
                              style: TextStyle(
                                  color: v.brandDeep, fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
