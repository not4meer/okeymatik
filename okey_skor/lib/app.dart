import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'providers/game_provider.dart';
import 'screens/home_screen.dart';
import 'screens/score_screen.dart';

class OkeySkorApp extends ConsumerWidget {
  const OkeySkorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameSessionProvider);

    return MaterialApp(
      title: 'Okeymatik',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(),
      home: session != null ? const ScoreScreen() : const HomeScreen(),
    );
  }
}
