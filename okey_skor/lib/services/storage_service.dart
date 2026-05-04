import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_session.dart';

class StorageService {
  final SharedPreferences _prefs;
  static const _key = 'active_game_session';

  StorageService(this._prefs);

  GameSession? loadSession() {
    final json = _prefs.getString(_key);
    if (json == null) return null;
    try {
      return GameSession.fromJsonString(json);
    } catch (_) {
      return null;
    }
  }

  void saveSession(GameSession session) {
    unawaited(_prefs.setString(_key, session.toJsonString()));
  }

  void clearSession() {
    unawaited(_prefs.remove(_key));
  }
}
