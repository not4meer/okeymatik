import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/score_screen.dart';
import 'screens/splash_screen.dart';

class OkeySkorApp extends ConsumerWidget {
  const OkeySkorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    final settings = ref.watch(settingsProvider);

    final Widget afterSplash;
    if (settings.isFirstLaunch) {
      afterSplash = const OnboardingScreen();
    } else if (session != null) {
      afterSplash = const ScoreScreen();
    } else {
      afterSplash = const HomeScreen();
    }

    return MaterialApp(
      title: 'Okeymatik',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: SplashScreen(afterSplash: afterSplash),
    );
  }
}
