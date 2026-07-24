import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/vita_tokens.dart';
import '../../core/theme/vita_theme.dart';
import '../../router.dart';
import '../../widgets/vita.dart';

/// A branded interstitial (~1.4s) while the result settles — turning a
/// millisecond of compute into a moment of anticipation before the reveal.
class CalculatingScreen extends ConsumerStatefulWidget {
  const CalculatingScreen({super.key});

  @override
  ConsumerState<CalculatingScreen> createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends ConsumerState<CalculatingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _timer;
  int _msgIndex = 0;

  static const _messages = [
    'Applying Mifflin–St Jeor…',
    'Estimating body composition…',
    'Mapping your activity multiplier…',
    'Building your macro targets…',
  ];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _timer = Timer.periodic(const Duration(milliseconds: 350), (t) {
      if (!mounted) return;
      setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
    });
    Future.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) context.go(Routes.home);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _c,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [
                    VitaColors.emerald, VitaColors.lime, VitaColors.emerald,
                  ]),
                ),
                child: Center(
                  child: Container(
                    width: 74, height: 74,
                    decoration: BoxDecoration(color: v.ground, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('🔥', style: TextStyle(fontSize: 30)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Crunching your numbers', style: context.vt.titleLarge),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: VitaMotion.fast,
              child: Text(
                _messages[_msgIndex],
                key: ValueKey(_msgIndex),
                style: context.mono(size: 13, color: v.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
