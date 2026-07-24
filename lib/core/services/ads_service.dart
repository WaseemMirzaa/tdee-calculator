import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google Mobile Ads for the free, ad-supported app.
///
/// Production wiring is complete:
///  • Ad unit ids are injected via --dart-define (ADMOB_BANNER_ANDROID /
///    ADMOB_BANNER_IOS); they fall back to Google's official TEST ids so debug
///    builds never serve real ads.
///  • [bootstrap] requests iOS App Tracking Transparency, then gathers GDPR
///    consent via the UMP SDK, then initialises the SDK — the order stores
///    require. Everything is best-effort and never blocks the UI.
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  // Real ids come from CI/build: --dart-define=ADMOB_BANNER_ANDROID=ca-app-...
  static const String _bannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111', // Google test banner
  );
  static const String _bannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716', // Google test banner
  );

  bool _initialized = false;

  String get bannerUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS ? _bannerIos : _bannerAndroid;

  /// One-shot startup: ATT (iOS) → UMP consent → SDK init. Safe to call once.
  Future<void> bootstrap() async {
    try {
      await _requestAttIfNeeded();
      await _gatherConsent();
    } catch (e) {
      debugPrint('Ads consent/ATT skipped: $e');
    }
    await init();
  }

  Future<void> _requestAttIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  /// GDPR/UMP: request the latest consent info and show the form if required.
  Future<void> _gatherConsent() {
    final completer = Completer<void>();
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((formError) {
          if (formError != null) debugPrint('Consent form: ${formError.message}');
          if (!completer.isCompleted) completer.complete();
        });
      },
      (error) {
        debugPrint('Consent update failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdsService init failed: $e');
    }
  }

  /// Creates a fresh anchored banner. Caller owns disposal.
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
