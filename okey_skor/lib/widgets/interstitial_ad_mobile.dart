import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../core/config.dart';

class InterstitialAd {
  static bool _loaded = false;
  static bool _loading = false;

  static String get _placementId {
    return Platform.isAndroid ? AppConfig.unityInterstitialAndroid : AppConfig.unityInterstitialIOS;
  }

  static void preload() {
    if (_loading || _loaded) return;
    _loading = true;
    UnityAds.load(
      placementId: _placementId,
      onComplete: (id) {
        _loaded = true;
        _loading = false;
        debugPrint('Interstitial loaded: $id');
      },
      onFailed: (id, error, message) {
        _loaded = false;
        _loading = false;
        debugPrint('Interstitial load failed: $id $error $message');
      },
    );
  }

  static Future<void> show(BuildContext context) async {
    if (!_loaded) {
      preload();
      return;
    }
    _loaded = false;
    UnityAds.showVideoAd(
      placementId: _placementId,
      onComplete: (id) {
        debugPrint('Interstitial complete: $id');
        preload();
      },
      onFailed: (id, error, message) {
        debugPrint('Interstitial show failed: $id $error $message');
        preload();
      },
      onStart: (id) => debugPrint('Interstitial started: $id'),
      onClick: (id) => debugPrint('Interstitial clicked: $id'),
      onSkipped: (id) {
        debugPrint('Interstitial skipped: $id');
        preload();
      },
    );
  }
}
