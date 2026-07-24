import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps Google Mobile Ads for the free tier. Premium users never see ads (the
/// single [isPremium] flag gates this). Uses Google's public TEST ad unit ids
/// by default — swap for your real unit ids before release.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;

  /// Google's official test banner unit ids (safe to ship in dev builds).
  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  String get bannerUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _testBannerIos : _testBannerAndroid;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdsService init failed: $e');
    }
  }

  /// Creates a fresh anchored adaptive banner. Caller owns disposal.
  BannerAd createBanner() {
    return BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner failed: $err');
          ad.dispose();
        },
      ),
    );
  }
}
