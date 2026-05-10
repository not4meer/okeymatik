import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'providers/game_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/score_screen.dart';

class OkeySkorApp extends ConsumerWidget {
  const OkeySkorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);
    final settings = ref.watch(settingsProvider);

    Widget home;
    if (settings.isFirstLaunch) {
      home = const OnboardingScreen();
    } else if (session != null) {
      home = const ScoreScreen();
    } else {
      home = const HomeScreen();
    }

    return MaterialApp(
      title: 'Okeymatik',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: home,
    );
  }
}
