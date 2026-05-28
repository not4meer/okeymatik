import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_enums.dart';
import '../models/game_history.dart';
import '../models/game_session.dart';
import 'game_provider.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, List<GameHistoryEntry>>((ref) {
  return HistoryNotifier(ref.watch(sharedPreferencesProvider));
});

class HistoryNotifier extends StateNotifier<List<GameHistoryEntry>> {
  final SharedPreferences _prefs;
  static const _key = 'game_history';
  static const _maxEntries = 50;

  HistoryNotifier(this._prefs) : super([]) {
    _load();
  }

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      state = list
          .map((e) => GameHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  void saveGame(GameSession session) {
    final roundCount = session.rounds.where((r) => r.label != 'Ceza').length;
    if (roundCount == 0) return;

    List<GameHistoryResult> results;
    if (session.gameMode == GameMode.paired && session.pairs.length == 2) {
      results = session.pairs.map((pair) {
        String name = session.players[pair[0]].name;
        if (name.endsWith(' 1') || name.endsWith(' 2')) {
          name = name.substring(0, name.length - 2).trim();
        }
        final score = pair.fold(0, (sum, i) => sum + session.players[i].totalScore);
        return GameHistoryResult(name: name, score: score);
      }).toList();
    } else {
      results = session.players
          .map((p) => GameHistoryResult(name: p.name, score: p.totalScore))
          .toList();
    }

    results.sort((a, b) => a.score.compareTo(b.score));

    final now = DateTime.now();
    int? durationMinutes;
    if (session.startedAt != null) {
      final diff = now.millisecondsSinceEpoch - session.startedAt!;
      durationMinutes = (diff / 60000).round().clamp(1, 9999);
    }

    final entry = GameHistoryEntry(
      id: session.id,
      playedAt: now,
      gameType: session.gameType,
      gameMode: session.gameMode,
      roundCount: roundCount,
      results: results,
      durationMinutes: durationMinutes,
    );

    final updated = [entry, ...state];
    state = updated.length > _maxEntries ? updated.sublist(0, _maxEntries) : updated;
    _prefs.setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  void clear() {
    state = [];
    _prefs.remove(_key);
  }
}
