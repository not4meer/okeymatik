import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsService {
  // Lazy init: Firebase init edilmediyse hiç dokunma
  // (aksi halde FirebaseAnalytics.instance sync throw eder, static final
  // bir kez fırladıysa her çağrıda tekrar fırlar → tüm handler'ları öldürür)
  static FirebaseAnalytics? _instance;
  static FirebaseAnalytics? get _fa {
    if (Firebase.apps.isEmpty) return null;
    return _instance ??= FirebaseAnalytics.instance;
  }

  static Future<void> logGameStarted(String gameType) async {
    await _fa?.logEvent(name: 'game_started', parameters: {'game_type': gameType});
  }

  static Future<void> logGameCompleted(String gameType, int rounds) async {
    await _fa?.logEvent(name: 'game_completed', parameters: {'game_type': gameType, 'round_count': rounds});
  }

  static Future<void> logHakemQueried() async {
    await _fa?.logEvent(name: 'hakem_queried');
  }

  static Future<void> logScreenshotTaken() async {
    await _fa?.logEvent(name: 'screenshot_taken');
  }

  static Future<void> logPremiumTapped() async {
    await _fa?.logEvent(name: 'premium_tapped');
  }
}
