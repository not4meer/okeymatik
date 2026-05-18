import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app.dart';
import 'providers/game_provider.dart';
import 'services/ads_initializer.dart';
import 'services/crashlytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase: Android uses google-services.json, iOS uses GoogleService-Info.plist
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      await CrashlyticsService.initialize();
      if (CrashlyticsService.onPlatformError != null) {
        PlatformDispatcher.instance.onError = CrashlyticsService.onPlatformError!;
      }
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
  }

  // AdMob (Android & iOS only — web uses stub)
  await AdsInitializer.initialize();

  try {
    await WakelockPlus.enable();
  } catch (_) {}

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080D18),
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const OkeySkorApp(),
    ),
  );
}
