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
    final testMode = kDebugMode || AppConfig.unityTestMode;

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
