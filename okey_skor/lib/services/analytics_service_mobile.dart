import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _fa = FirebaseAnalytics.instance;

  static Future<void> logGameStarted(String gameType) =>
      _fa.logEvent(name: 'game_started', parameters: {'game_type': gameType});

  static Future<void> logGameCompleted(String gameType, int rounds) =>
      _fa.logEvent(name: 'game_completed', parameters: {'game_type': gameType, 'round_count': rounds});

  static Future<void> logHakemQueried() =>
      _fa.logEvent(name: 'hakem_queried');

  static Future<void> logScreenshotTaken() =>
      _fa.logEvent(name: 'screenshot_taken');

  static Future<void> logPremiumTapped() =>
      _fa.logEvent(name: 'premium_tapped');
}
