import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/iap_service.dart';
import 'game_provider.dart';

final iapServiceProvider = Provider<IapService>((ref) {
  final service = IapService();
  ref.onDispose(service.dispose);
  return service;
});

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(
    ref.watch(sharedPreferencesProvider),
    ref.watch(iapServiceProvider),
  );
});

class PremiumNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  final IapService _iap;
  static const _key = 'is_premium';

  String? lastError;

  PremiumNotifier(this._prefs, this._iap) : super(_prefs.getBool(_key) ?? false) {
    _init();
  }

  Future<void> _init() async {
    await _iap.initialize(
      onPremiumChange: _setPremium,
      onError: (message) => lastError = message,
    );
  }

  ProductDetails? get product => _iap.monthlyProduct;
  bool get iapAvailable => _iap.isAvailable;
  bool get iapLoading => _iap.isLoading;

  Future<bool> buyMonthly() => _iap.buyMonthly();

  Future<void> restore() => _iap.restorePurchases();

  Future<void> _setPremium(bool value) async {
    await _prefs.setBool(_key, value);
    state = value;
  }
}
