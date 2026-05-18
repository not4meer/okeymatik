import 'dart:ui';

class CrashlyticsService {
  static Future<void> initialize() async {}
  static void recordError(Object error, StackTrace? stack, {bool fatal = false}) {}
  static ErrorCallback? get onPlatformError => null;
}
