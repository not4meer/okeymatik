import 'dart:convert';
import 'game_enums.dart';
import 'player.dart';
import 'round.dart';

class GameSession {
  final String id;
  final GameType gameType;
  final GameMode gameMode;
  final List<Player> players;
  final List<RoundScore> rounds;
  final List<List<int>> pairs;
  final int? totalRounds;
  final int? startedAt; // unix ms — when game started

  const GameSession({
    required this.id,
    required this.gameType,
    required this.gameMode,
    required this.players,
    this.rounds = const [],
    this.pairs = const [],
    this.totalRounds,
    this.startedAt,
  });

  GameSession copyWith({
    String? id,
    GameType? gameType,
    GameMode? gameMode,
    List<Player>? players,
    List<RoundScore>? rounds,
    List<List<int>>? pairs,
    int? totalRounds,
    int? startedAt,
    bool clearTotalRounds = false,
  }) {
    return GameSession(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      gameMode: gameMode ?? this.gameMode,
      players: players ?? this.players,
      rounds: rounds ?? this.rounds,
      pairs: pairs ?? this.pairs,
      totalRounds: clearTotalRounds ? null : (totalRounds ?? this.totalRounds),
      startedAt: startedAt ?? this.startedAt,
    );
  }

  // Returns the partner's player ID for a given player ID in paired mode
  String? partnerOf(String playerId) {
    if (gameMode != GameMode.paired) return null;
    final idx = players.indexWhere((p) => p.id == playerId);
    if (idx < 0) return null;
    for (final pair in pairs) {
      if (pair.contains(idx)) {
        final partnerIdx = pair.firstWhere((i) => i != idx);
        return players[partnerIdx].id;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gameType': gameType.name,
        'gameMode': gameMode.name,
        'players': players.map((p) => p.toJson()).toList(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
        'pairs': pairs,
        'totalRounds': totalRounds,
        'startedAt': startedAt,
      };

  factory GameSession.fromJson(Map<String, dynamic> json) => GameSession(
        id: json['id'] as String,
        gameType: GameType.values.firstWhere((e) => e.name == json['gameType']),
        gameMode: GameMode.values.firstWhere((e) => e.name == json['gameMode']),
        players: (json['players'] as List? ?? []).map((e) => Player.fromJson(e as Map<String, dynamic>)).toList(),
        rounds: (json['rounds'] as List? ?? []).map((e) => RoundScore.fromJson(e as Map<String, dynamic>)).toList(),
        pairs: (json['pairs'] as List? ?? []).map((p) => List<int>.from(p as List)).toList(),
        totalRounds: json['totalRounds'] as int?,
        startedAt: json['startedAt'] as int?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory GameSession.fromJsonString(String s) => GameSession.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
