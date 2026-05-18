import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import '../widgets/interstitial_ad_mobile.dart' as interstitial;

class AdsInitializer {
  static Future<void> initialize() async {
    await admob.MobileAds.instance.initialize();
    interstitial.InterstitialAd.preload();
  }
}
