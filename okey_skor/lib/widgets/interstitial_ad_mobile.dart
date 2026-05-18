import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;

class InterstitialAd {
  static admob.InterstitialAd? _ad;
  static bool _loading = false;

  static String get _adUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? const String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID', defaultValue: '')
        : const String.fromEnvironment('ADMOB_INTERSTITIAL_IOS', defaultValue: '');
  }

  static void preload() {
    if (_loading || _ad != null) return;
    _loading = true;
    admob.InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const admob.AdRequest(),
      adLoadCallback: admob.InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed: $error');
          _loading = false;
        },
      ),
    );
  }

  static Future<void> show(BuildContext context) async {
    if (_ad == null) {
      preload();
      return;
    }
    final ad = _ad!;
    _ad = null;
    ad.fullScreenContentCallback = admob.FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        preload();
      },
    );
    await ad.show();
  }
}
