import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_enums.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/round.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
});

final gameSessionProvider = StateNotifierProvider<GameSessionNotifier, GameSession?>((ref) {
  return GameSessionNotifier(ref.watch(storageServiceProvider));
});

final scoresHiddenProvider = StateProvider<bool>((_) => false);

class GameSessionNotifier extends StateNotifier<GameSession?> {
  final StorageService _storage;

  GameSessionNotifier(this._storage) : super(null) {
    state = _storage.loadSession();
  }

  void startGame({
    required GameType gameType,
    required GameMode gameMode,
    required List<String> playerNames,
    List<List<int>> pairs = const [],
    int? totalRounds,
  }) {
    final players = playerNames.asMap().entries.map((e) => Player(
          id: 'p${e.key}',
          name: e.value.trim().isEmpty ? 'Oyuncu ${e.key + 1}' : e.value.trim(),
        )).toList();

    final now = DateTime.now().millisecondsSinceEpoch;
    state = GameSession(
      id: now.toString(),
      gameType: gameType,
      gameMode: gameMode,
      players: players,
      pairs: pairs,
      totalRounds: totalRounds,
      startedAt: now,
    );
    _save();
    AnalyticsService.logGameStarted(gameType.name);
  }

  void addPenalty(String playerId, int amount) {
    if (state == null || amount == 0) return;
    final penaltyRound = RoundScore(
      deltas: {playerId: amount},
      winnerId: null,
      label: 'Ceza',
    );
    addRound(penaltyRound);
  }

  void addRound(RoundScore round) {
    if (state == null) return;
    final updatedPlayers = state!.players.map((p) {
      final delta = round.deltas[p.id] ?? 0;
      return p.copyWith(totalScore: p.totalScore + delta);
    }).toList();

    state = state!.copyWith(
      players: updatedPlayers,
      rounds: [...state!.rounds, round],
    );
    _save();
  }

  void replaceRound(int index, RoundScore newRound) {
    if (state == null || index < 0 || index >= state!.rounds.length) return;
    final rounds = List<RoundScore>.from(state!.rounds);
    rounds[index] = newRound;
    final updatedPlayers = state!.players.map((p) {
      int total = 0;
      for (final r in rounds) {
        total += r.deltas[p.id] ?? 0;
      }
      return p.copyWith(totalScore: total);
    }).toList();
    state = state!.copyWith(players: updatedPlayers, rounds: rounds);
    _save();
  }

  void undoLastRound() {
    if (state == null || state!.rounds.isEmpty) return;
    final last = state!.rounds.last;
    final updatedPlayers = state!.players.map((p) {
      final delta = last.deltas[p.id] ?? 0;
      return p.copyWith(totalScore: p.totalScore - delta);
    }).toList();

    state = state!.copyWith(
      players: updatedPlayers,
      rounds: state!.rounds.sublist(0, state!.rounds.length - 1),
    );
    _save();
  }

  void endGame() {
    state = null;
    _storage.clearSession();
  }

  void _save() {
    if (state != null) _storage.saveSession(state!);
  }
}
