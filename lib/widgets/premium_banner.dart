import 'package:flutter/material.dart';
import '../core/theme/vita_tokens.dart';
import '../core/theme/vita_theme.dart';

/// The "Go Pro" upsell banner. Shown only to free users (caller gates on
/// [premiumProvider]). Original copy — not the competitor's microcopy.
class PremiumBanner extends StatelessWidget {
  const PremiumBanner({super.key, required this.onTap, this.label = "You're on the free trial"});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [VitaColors.emeraldDeep, VitaColors.emerald],
            ),
          ),
          child: Row(
            children: [
              const Text('✦', style: TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Go Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
