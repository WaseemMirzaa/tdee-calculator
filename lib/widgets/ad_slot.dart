import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/services/ads_service.dart';
import '../core/theme/vita_theme.dart';

/// A full-width banner ad bar, pinned at the bottom of the app (above the nav).
/// The app is free and ad-supported, so this always shows once an ad loads;
/// it renders nothing while loading or if the ad fails (never blocks the UI).
class AdSlot extends ConsumerStatefulWidget {
  const AdSlot({super.key});

  @override
  ConsumerState<AdSlot> createState() => _AdSlotState();
}

class _AdSlotState extends ConsumerState<AdSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await AdsService.instance.init();
      final ad = AdsService.instance.createBanner();
      _ad = ad;
      await ad.load();
      if (mounted) setState(() => _loaded = true);
    } catch (_) {
      // Ads are best-effort; never block the UI.
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ad == null || !_loaded) return const SizedBox.shrink();
    final v = context.vita;
    return Container(
      width: double.infinity,
      height: _ad!.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: v.card,
        border: Border(bottom: BorderSide(color: v.lineSoft)),
      ),
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
