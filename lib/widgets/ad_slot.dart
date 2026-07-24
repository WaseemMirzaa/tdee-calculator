import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/providers/app_providers.dart';
import '../core/services/ads_service.dart';
import '../core/theme/vita_theme.dart';

/// A banner ad slot for the free tier. Renders nothing for premium users — the
/// single [premiumProvider] flag removes all ads.
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
      ad.load().then((_) {
        if (mounted) setState(() => _loaded = true);
      });
      // Mark loaded via listener too (createBanner disposes on failure).
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
    final isPremium = ref.watch(premiumProvider);
    if (isPremium || _ad == null || !_loaded) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      height: _ad!.size.height.toDouble(),
      width: _ad!.size.width.toDouble(),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.vita.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AdWidget(ad: _ad!),
    );
  }
}
