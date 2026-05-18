import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_provider.dart';

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref.watch(sharedPreferencesProvider));
});

class PremiumNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'is_premium';

  PremiumNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> activate() async {
    await _prefs.setBool(_key, true);
    state = true;
  }

  Future<void> restore() async {
    state = _prefs.getBool(_key) ?? false;
  }
}
