import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../core/config.dart';
import '../widgets/interstitial_ad_mobile.dart' as interstitial;

class AdsInitializer {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final gameId = Platform.isAndroid ? AppConfig.unityGameIdAndroid : AppConfig.unityGameIdIOS;
    if (gameId.isEmpty) {
      debugPrint('UnityAds: Game ID missing for ${Platform.operatingSystem}, ads disabled');
      return;
    }

    // Debug/development'ta test mode aktif, release'de kapalı
    const testMode = kDebugMode || AppConfig.unityTestMode;

    // GDPR/CCPA consent — Unity SDK bu ayarlar olmadan bazen ad servisi kısıtlıyor
    // Kullanıcıya explicit consent göstermediğimiz için "gösterme yetkisi var" varsayıyoruz
    // (uygulama Play Data Safety'de veri toplama beyanı verildi + privacy policy var)
    try {
      await UnityAds.setPrivacyConsent(PrivacyConsentType.gdpr, true);
      await UnityAds.setPrivacyConsent(PrivacyConsentType.ccpa, true);
      await UnityAds.setPrivacyConsent(PrivacyConsentType.pipl, true);
    } catch (e) {
      debugPrint('UnityAds consent set failed (plugin API mismatch): $e');
    }

    await UnityAds.init(
      gameId: gameId,
      testMode: testMode,
      onComplete: () {
        _initialized = true;
        debugPrint('UnityAds initialized');
        interstitial.InterstitialAd.preload();
      },
      onFailed: (error, message) {
        debugPrint('UnityAds init failed: $error $message');
      },
    );
  }
}
