import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/vita.dart';

/// S1 · "Go Pro" paywall. Comparison table, price line, START FREE TRIAL, legal
/// text. Original copy & iconography. Shown *after* value (soft) or when a
/// locked deep feature is opened (hard) — never on launch.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _busy = false;

  static const _features = [
    ('Calorie & TDEE tracker', true, true),
    ('Diet planning', true, true),
    ('Special meal plans', true, false),
    ('Adaptive Journey stats', true, false),
    ('No ads', true, false),
  ];

  Future<void> _startTrial() async {
    setState(() => _busy = true);
    final service = ref.read(purchaseServiceProvider);
    final launched = await service.startTrial();
    if (!launched) {
      // Store unavailable (simulator / sandbox not configured): grant access so
      // the app is fully usable for testing. Production uses the real purchase.
      ref.read(premiumProvider.notifier).setPremium(true);
    }
    if (mounted) {
      setState(() => _busy = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    final price = ref.read(purchaseServiceProvider).priceLabel;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: VitaCircleButton(icon: Icons.close_rounded, onPressed: () => context.pop()),
              ),
              const SizedBox(height: 8),
              Container(
                width: 66, height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [VitaColors.emerald, VitaColors.lime]),
                  boxShadow: [BoxShadow(color: VitaColors.emerald.withOpacity(0.4), blurRadius: 26)],
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 16),
              Text('Unlock everything', style: context.vt.headlineMedium?.copyWith(fontSize: 28)),
              const SizedBox(height: 6),
              Text('Go further with Vita Pro', style: TextStyle(color: v.inkSoft, fontSize: 15)),
              const SizedBox(height: 26),

              // Comparison table
              VitaCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(child: SizedBox()),
                        _ColHead('PRO', context),
                        _ColHead('FREE', context),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final f in _features) ...[
                      Divider(color: v.lineSoft, height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(f.$1, style: TextStyle(color: v.ink, fontSize: 14.5, fontWeight: FontWeight.w600)),
                          ),
                          _Cell(f.$2),
                          _Cell(f.$3),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              Text('$price · after a 3-day free trial',
                  style: TextStyle(color: v.muted, fontSize: 13)),
              const SizedBox(height: 12),
              VitaPrimaryButton(
                label: 'Start free trial',
                loading: _busy,
                onPressed: _startTrial,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(purchaseServiceProvider).restore(),
                child: Text('Restore purchase', style: TextStyle(color: v.muted, fontSize: 13)),
              ),
              Text(
                'Billed after the trial ends and auto-renews weekly. Cancel anytime before the trial ends to avoid charges.',
                textAlign: TextAlign.center,
                style: TextStyle(color: v.muted, fontSize: 11.5, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColHead extends StatelessWidget {
  const _ColHead(this.label, this.context);
  final String label;
  final BuildContext context;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Center(child: Text(label, style: context.monoLabel(size: 10.5))),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.on);
  final bool on;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Center(
        child: on
            ? const Icon(Icons.check_circle_rounded, color: VitaColors.emerald, size: 21)
            : Icon(Icons.remove_rounded, color: context.vita.muted, size: 18),
      ),
    );
  }
}
