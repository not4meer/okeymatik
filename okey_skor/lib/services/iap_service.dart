import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/config.dart';

/// Satın almanın neden kullanılamadığını ayırt eder — kullanıcıya genel
/// "bir sorun oluştu" yerine gerçek sebebi gösterebilmek için.
enum IapStatus {
  notInitialized,
  unavailable,     // cihazda/hesapta mağaza kapalı
  productMissing,  // mağazada ürün tanımlı değil ya da henüz onaylanmadı
  ready,
}

class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  final List<ProductDetails> _products = [];
  bool _loading = false;
  IapStatus _status = IapStatus.notInitialized;
  Future<void>? _initFuture;

  void Function(bool isPremium)? _onPremiumChange;
  void Function(String message)? _onError;

  bool get isAvailable => _available;
  bool get isLoading => _loading;
  IapStatus get status => _status;
  bool get isReady => _status == IapStatus.ready;
  ProductDetails? get monthlyProduct => _products.isEmpty ? null : _products.first;

  String get unavailableReason => switch (_status) {
        IapStatus.ready => '',
        IapStatus.productMissing =>
          'Abonelik mağazada henüz yayında değil. Kısa süre içinde açılacak.',
        IapStatus.unavailable =>
          'Cihazda mağaza satın almaları kapalı. App Store / Google Play hesabınızı kontrol edin.',
        IapStatus.notInitialized => 'Satın alma servisi hazırlanıyor, bir saniye.',
      };

  Future<void> initialize({
    required void Function(bool isPremium) onPremiumChange,
    void Function(String message)? onError,
  }) {
    _onPremiumChange = onPremiumChange;
    _onError = onError;
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('IAP: isAvailable threw: $e');
      _available = false;
    }

    if (!_available) {
      _status = IapStatus.unavailable;
      debugPrint('IAP: not available on this device');
      return;
    }

    _subscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        _subscription?.cancel();
        _subscription = null;
      },
      onError: (Object error) {
        _loading = false;
        debugPrint('IAP stream error: $error');
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap
          .queryProductDetails({AppConfig.premiumMonthlyProductId})
          .timeout(const Duration(seconds: 20));

      if (response.error != null) {
        debugPrint('IAP: query error: ${response.error}');
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP: product not found: ${response.notFoundIDs}');
      }

      _products
        ..clear()
        ..addAll(response.productDetails);
    } catch (e) {
      debugPrint('IAP: queryProductDetails threw: $e');
      _products.clear();
    }
    _status = _products.isEmpty ? IapStatus.productMissing : IapStatus.ready;
  }

  /// Ürün listesini yeniden dener — kullanıcı butona bastığında ilk yükleme
  /// henüz bitmemiş ya da başarısız olmuş olabilir.
  Future<bool> ensureReady() async {
    await initialize(
      onPremiumChange: _onPremiumChange ?? (_) {},
      onError: _onError,
    );
    if (!_available) return false;
    if (_products.isEmpty) await _loadProducts();
    return _products.isNotEmpty;
  }

  Future<bool> buyMonthly() async {
    if (!await ensureReady()) {
      _onError?.call(unavailableReason);
      return false;
    }
    _loading = true;
    try {
      final param = PurchaseParam(productDetails: _products.first);
      // Abonelikler için de buyNonConsumable doğru çağrı (iOS + Android).
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        _loading = false;
        _onError?.call('Satın alma başlatılamadı. Tekrar deneyin.');
      }
      return started;
    } catch (e) {
      _loading = false;
      debugPrint('IAP: buyNonConsumable threw: $e');
      _onError?.call('Satın alma başlatılamadı: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    await initialize(
      onPremiumChange: _onPremiumChange ?? (_) {},
      onError: _onError,
    );
    if (!_available) {
      _onError?.call(unavailableReason);
      return;
    }
    _loading = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAP: restorePurchases threw: $e');
      _onError?.call('Geri yükleme başarısız: $e');
    } finally {
      _loading = false;
    }
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
          _onError?.call(
              'Satın alma hatası: ${purchase.error?.message ?? 'bilinmeyen hata'}');
          break;
        case PurchaseStatus.canceled:
          _loading = false;
          break;
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (e) {
          debugPrint('IAP: completePurchase threw: $e');
        }
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
