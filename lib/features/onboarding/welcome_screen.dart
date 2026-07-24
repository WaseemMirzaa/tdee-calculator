import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// S2 · Onboarding welcome. Original hero (an abstract energy bloom) + one
/// honest promise + a single Start CTA. Sets the calm, premium tone.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _EnergyBloom(),
              const Spacer(flex: 1),
              Text(
                'Know your numbers.\nEat toward your goal.',
                textAlign: TextAlign.center,
                style: context.vt.headlineMedium?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Vita figures out exactly how much energy you burn — then turns it into a plan you can actually follow.',
                textAlign: TextAlign.center,
                style: TextStyle(color: v.inkSoft, fontSize: 15.5, height: 1.5),
              ),
              const Spacer(flex: 2),
              VitaPrimaryButton(
                label: 'Start',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push(Routes.profile),
              ),
              const SizedBox(height: 12),
              Text('Takes about 30 seconds · no account needed',
                  style: TextStyle(color: v.muted, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// An original, license-free hero: a soft gradient bloom with an emoji cluster.
class _EnergyBloom extends StatelessWidget {
  const _EnergyBloom();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  VitaColors.lime.withOpacity(0.55),
                  VitaColors.emerald.withOpacity(0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [VitaColors.emerald, VitaColors.emeraldDeep],
              ),
              boxShadow: [
                BoxShadow(color: VitaColors.emerald.withOpacity(0.4), blurRadius: 40, spreadRadius: 4),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('🔥', style: TextStyle(fontSize: 52)),
          ),
          const Positioned(top: 8, right: 26, child: Text('🥑', style: TextStyle(fontSize: 30))),
          const Positioned(bottom: 14, left: 18, child: Text('💪', style: TextStyle(fontSize: 30))),
          const Positioned(bottom: 30, right: 10, child: Text('🍓', style: TextStyle(fontSize: 26))),
        ],
      ),
    );
  }
}
