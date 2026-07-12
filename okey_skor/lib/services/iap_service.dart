import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/config.dart';

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  final List<ProductDetails> _products = [];
  bool _loading = false;

  void Function(bool isPremium)? _onPremiumChange;
  void Function(String message)? _onError;

  bool get isAvailable => _available;
  bool get isLoading => _loading;
  ProductDetails? get monthlyProduct => _products.isEmpty ? null : _products.first;

  Future<void> initialize({
    required void Function(bool isPremium) onPremiumChange,
    void Function(String message)? onError,
  }) async {
    _onPremiumChange = onPremiumChange;
    _onError = onError;

    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('IAP: not available on this device');
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('IAP stream error: $error'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({AppConfig.premiumMonthlyProductId});
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: product not found: ${response.notFoundIDs}');
    }
    _products
      ..clear()
      ..addAll(response.productDetails);
  }

  Future<bool> buyMonthly() async {
    if (!_available || _products.isEmpty) {
      _onError?.call('Satın alma şu anda kullanılamıyor.');
      return false;
    }
    _loading = true;
    final param = PurchaseParam(productDetails: _products.first);
    // buyNonConsumable also works for subscriptions on both platforms
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (!_available) {
      _onError?.call('Satın alma servisi kullanılamıyor.');
      return;
    }
    _loading = true;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _loading = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _loading = false;
          if (purchase.productID == AppConfig.premiumMonthlyProductId) {
            _onPremiumChange?.call(true);
          }
          break;
        case PurchaseStatus.error:
          _loading = false;
          _onError?.call('Satın alma hatası: ${purchase.error?.message ?? 'bilinmeyen hata'}');
          break;
        case PurchaseStatus.canceled:
          _loading = false;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
