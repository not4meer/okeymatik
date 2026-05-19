import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import '../widgets/interstitial_ad_mobile.dart' as interstitial;

class AdsInitializer {
  static Future<void> initialize() async {
    // AdMob requires iOS 14+; skip on older versions to avoid crash
    if (Platform.isIOS) {
      final version = int.tryParse(Platform.operatingSystemVersion.split(' ').last.split('.').first) ?? 0;
      if (version < 14) return;
    }
    await admob.MobileAds.instance.initialize();
    interstitial.InterstitialAd.preload();
  }
}
