import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
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

    // iOS 14+ App Tracking Transparency prompt — Unity Ads / IDFA için gerekli
    // Apple review bunu görmezse "no ATT prompt" ret verir
    if (Platform.isIOS) {
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          // iOS'un promptu göstermesi için kısa bekleme gerekir
          await Future.delayed(const Duration(milliseconds: 200));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (e) {
        debugPrint('ATT request failed: $e');
      }
    }

    // GDPR/CCPA consent — Unity SDK bu ayarlar olmadan bazen ad servisi kısıtlıyor
    try {
      await UnityAds.setPrivacyConsent(PrivacyConsentType.gdpr, true);
      await UnityAds.setPrivacyConsent(PrivacyConsentType.ccpa, true);
      await UnityAds.setPrivacyConsent(PrivacyConsentType.pipl, true);
    } catch (e) {
      debugPrint('UnityAds consent set failed (plugin API mismatch): $e');
    }

    // Debug/development'ta test mode aktif, release'de kapalı
    const testMode = kDebugMode || AppConfig.unityTestMode;

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
