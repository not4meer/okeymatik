import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/strings.dart';
import 'game_provider.dart';

class AppSettings {
  final String username;
  final String playerId;
  final ThemeMode themeMode;
  final String language;
  final int firstLaunchTimestamp;
  final bool ratingShown;
  final int completedGamesCount;

  const AppSettings({
    required this.username,
    required this.playerId,
    required this.themeMode,
    required this.language,
    required this.firstLaunchTimestamp,
    required this.ratingShown,
    required this.completedGamesCount,
  });

  bool get isFirstLaunch => username.isEmpty;

  bool get shouldShowRating => !ratingShown && completedGamesCount >= 5;

  AppSettings copyWith({
    String? username,
    String? playerId,
    ThemeMode? themeMode,
    String? language,
    int? firstLaunchTimestamp,
    bool? ratingShown,
    int? completedGamesCount,
  }) {
    return AppSettings(
      username: username ?? this.username,
      playerId: playerId ?? this.playerId,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      firstLaunchTimestamp: firstLaunchTimestamp ?? this.firstLaunchTimestamp,
      ratingShown: ratingShown ?? this.ratingShown,
      completedGamesCount: completedGamesCount ?? this.completedGamesCount,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(sharedPreferencesProvider));
});

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(settingsProvider).language;
  return lang == 'en' ? AppStrings.en : AppStrings.tr;
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  static const _keyUsername = 'settings_username';
  static const _keyPlayerId = 'settings_player_id';
  static const _keyTheme = 'settings_theme';
  static const _keyLanguage = 'settings_language';
  static const _keyFirstLaunch = 'settings_first_launch_ts';
  static const _keyRatingShown = 'settings_rating_shown';
  static const _keyCompletedGames = 'settings_completed_games';

  SettingsNotifier(this._prefs) : super(const AppSettings(
    username: '',
    playerId: '',
    themeMode: ThemeMode.dark,
    language: 'tr',
    firstLaunchTimestamp: 0,
    ratingShown: false,
    completedGamesCount: 0,
  )) {
    _load();
  }

  void _load() {
    final username = _prefs.getString(_keyUsername) ?? '';
    var playerId = _prefs.getString(_keyPlayerId) ?? '';
    if (playerId.isEmpty) {
      playerId = _generatePlayerId();
      _prefs.setString(_keyPlayerId, playerId);
    }
    final themeStr = _prefs.getString(_keyTheme) ?? 'dark';
    final themeMode = themeStr == 'light' ? ThemeMode.light : ThemeMode.dark;
    final language = _prefs.getString(_keyLanguage) ?? 'tr';

    var firstLaunchTs = _prefs.getInt(_keyFirstLaunch) ?? 0;
    if (firstLaunchTs == 0) {
      firstLaunchTs = DateTime.now().millisecondsSinceEpoch;
      _prefs.setInt(_keyFirstLaunch, firstLaunchTs);
    }
    final ratingShown = _prefs.getBool(_keyRatingShown) ?? false;
    final completedGamesCount = _prefs.getInt(_keyCompletedGames) ?? 0;

    state = AppSettings(
      username: username,
      playerId: playerId,
      themeMode: themeMode,
      language: language,
      firstLaunchTimestamp: firstLaunchTs,
      ratingShown: ratingShown,
      completedGamesCount: completedGamesCount,
    );
  }

  String _generatePlayerId() {
    const chars = '0123456789';
    final rng = Random();
    final number = List.generate(5, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'OKY-$number';
  }

  void setUsername(String name) {
    final trimmed = name.trim();
    _prefs.setString(_keyUsername, trimmed);
    state = state.copyWith(username: trimmed);
  }

  void setThemeMode(ThemeMode mode) {
    _prefs.setString(_keyTheme, mode == ThemeMode.light ? 'light' : 'dark');
    state = state.copyWith(themeMode: mode);
  }

  void setLanguage(String lang) {
    _prefs.setString(_keyLanguage, lang);
    state = state.copyWith(language: lang);
  }

  void markRatingShown() {
    _prefs.setBool(_keyRatingShown, true);
    state = state.copyWith(ratingShown: true);
  }

  void incrementCompletedGames() {
    final next = state.completedGamesCount + 1;
    _prefs.setInt(_keyCompletedGames, next);
    state = state.copyWith(completedGamesCount: next);
  }
}
