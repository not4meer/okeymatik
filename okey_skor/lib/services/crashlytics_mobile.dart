import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  // Firebase init olmadıysa Crashlytics.instance sync throw eder — hepsini guard'la
  static bool get _ready => Firebase.apps.isNotEmpty;

  static Future<void> initialize() async {
    if (!_ready) return;
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  static void recordError(Object error, StackTrace? stack, {bool fatal = false}) {
    if (!_ready) return;
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  }

  static ErrorCallback get onPlatformError => (error, stack) {
        if (!_ready) return true;
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
}
