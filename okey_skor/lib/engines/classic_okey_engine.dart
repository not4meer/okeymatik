import '../models/player.dart';
import '../models/round.dart';
import 'scoring_engine.dart';

/// Input keys:
///   'winnerId' : String
///   'penalty'  : int  (2, 4, 6 or 8)
///   'gosterge' : bool (adds -1 extra to losers)
class ClassicOkeyEngine extends ScoringEngine {
  @override
  RoundScore calculate(Map<String, dynamic> input, List<Player> players) {
    final winnerId = input['winnerId'] as String;
    final penalty = input['penalty'] as int;
    final gosterge = (input['gosterge'] as bool?) ?? false;

    final deltas = <String, int>{};
    for (final p in players) {
      if (p.id == winnerId) {
        deltas[p.id] = 0;
      } else {
        deltas[p.id] = -(penalty + (gosterge ? 1 : 0));
      }
    }

    final label = '-$penalty${gosterge ? ' + Gösterge' : ''}';
    return RoundScore(deltas: deltas, winnerId: winnerId, label: label);
  }
}
