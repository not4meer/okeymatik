import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static Future<void> initialize() async {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  static void recordError(Object error, StackTrace? stack, {bool fatal = false}) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  static ErrorCallback get onPlatformError => (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
