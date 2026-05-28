import 'game_enums.dart';

class GameHistoryEntry {
  final String id;
  final DateTime playedAt;
  final GameType gameType;
  final GameMode gameMode;
  final int roundCount;
  final List<GameHistoryResult> results; // sorted ascending (winner first)
  final int? durationMinutes;

  const GameHistoryEntry({
    required this.id,
    required this.playedAt,
    required this.gameType,
    required this.gameMode,
    required this.roundCount,
    required this.results,
    this.durationMinutes,
  });

  String get winnerName => results.isNotEmpty ? results.first.name : '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'playedAt': playedAt.millisecondsSinceEpoch,
        'gameType': gameType.name,
        'gameMode': gameMode.name,
        'roundCount': roundCount,
        'results': results.map((r) => r.toJson()).toList(),
        'durationMinutes': durationMinutes,
      };

  factory GameHistoryEntry.fromJson(Map<String, dynamic> json) => GameHistoryEntry(
        id: json['id'] as String,
        playedAt: DateTime.fromMillisecondsSinceEpoch(json['playedAt'] as int),
        gameType: GameType.values.firstWhere(
          (e) => e.name == json['gameType'],
          orElse: () => GameType.okey101,
        ),
        gameMode: GameMode.values.firstWhere(
          (e) => e.name == json['gameMode'],
          orElse: () => GameMode.solo,
        ),
        roundCount: json['roundCount'] as int,
        results: (json['results'] as List)
            .map((r) => GameHistoryResult.fromJson(r as Map<String, dynamic>))
            .toList(),
        durationMinutes: json['durationMinutes'] as int?,
      );
}

class GameHistoryResult {
  final String name;
  final int score;

  const GameHistoryResult({required this.name, required this.score});

  Map<String, dynamic> toJson() => {'name': name, 'score': score};

  factory GameHistoryResult.fromJson(Map<String, dynamic> json) => GameHistoryResult(
        name: json['name'] as String,
        score: json['score'] as int,
      );
}
