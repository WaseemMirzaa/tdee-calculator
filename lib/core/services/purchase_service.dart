import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Thin wrapper over [InAppPurchase] for the 3-day trial + weekly auto-renew.
///
/// Uses the real store (Google Play Billing / StoreKit). It degrades
/// gracefully when the store is unavailable (e.g. simulator, review sandbox),
/// so the app never crashes if billing isn't configured yet. Production must
/// set [kWeeklyProductId] to the real store product id.
class PurchaseService {
  PurchaseService();

  /// Configure this to your real store subscription product id.
  static const String kWeeklyProductId = 'vita_premium_weekly';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _available = false;
  ProductDetails? _weekly;

  /// Called once at startup. Returns whether the store is reachable.
  Future<bool> init({required void Function(bool isPremium) onEntitlement}) async {
    try {
      _available = await _iap.isAvailable();
      if (!_available) return false;

      final resp = await _iap.queryProductDetails({kWeeklyProductId});
      if (resp.productDetails.isNotEmpty) {
        _weekly = resp.productDetails.first;
      }

      _sub = _iap.purchaseStream.listen((purchases) {
        for (final pd in purchases) {
          if (pd.status == PurchaseStatus.purchased ||
              pd.status == PurchaseStatus.restored) {
            onEntitlement(true);
          }
          if (pd.pendingCompletePurchase) {
            _iap.completePurchase(pd);
          }
        }
      });
      return true;
    } catch (e) {
      debugPrint('PurchaseService init failed: $e');
      return false;
    }
  }

  ProductDetails? get weeklyProduct => _weekly;

  /// Human-facing price string from the store, or a fallback reference price.
  String get priceLabel => _weekly?.price ?? 'Rs 2,550/week';

  /// Start the trial + subscription purchase flow. Returns false if it could
  /// not be launched (store unavailable or product not found).
  Future<bool> startTrial() async {
    if (!_available || _weekly == null) return false;
    final param = PurchaseParam(productDetails: _weekly!);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    if (_available) await _iap.restorePurchases();
  }

  void dispose() => _sub?.cancel();
}
