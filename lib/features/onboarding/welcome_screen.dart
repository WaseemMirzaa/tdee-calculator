import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vita_theme.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// S2 · Onboarding welcome. A premium, scheme-aware hero + one honest promise.
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
              const _HeroMark(),
              const Spacer(flex: 1),
              Text(
                'Know your numbers.\nEat toward your goal.',
                textAlign: TextAlign.center,
                style: context.vt.headlineMedium?.copyWith(fontSize: 31),
              ),
              const SizedBox(height: 16),
              Text(
                'Vita figures out exactly how much energy you burn — then turns it into a plan you can actually follow.',
                textAlign: TextAlign.center,
                style: TextStyle(color: v.inkSoft, fontSize: 15.5, height: 1.5),
              ),
              const Spacer(flex: 2),
              VitaPrimaryButton(
                label: 'Get started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push(Routes.onboard),
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

/// A scheme-aware hero: a glowing brand orb with a bright ring accent.
class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [v.accent.withOpacity(0.5), v.brand.withOpacity(0.12), Colors.transparent],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [v.brand, v.brandDeep],
              ),
              boxShadow: [BoxShadow(color: v.brand.withOpacity(0.45), blurRadius: 44, spreadRadius: 4)],
            ),
            alignment: Alignment.center,
            child: const Text('🔥', style: TextStyle(fontSize: 54)),
          ),
          const Positioned(top: 8, right: 30, child: Text('🥑', style: TextStyle(fontSize: 30))),
          const Positioned(bottom: 16, left: 22, child: Text('💪', style: TextStyle(fontSize: 30))),
          const Positioned(bottom: 34, right: 14, child: Text('🍓', style: TextStyle(fontSize: 26))),
        ],
      ),
    );
  }
}
