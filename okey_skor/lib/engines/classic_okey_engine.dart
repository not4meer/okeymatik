import '../models/game_enums.dart';
import '../models/player.dart';
import '../models/round.dart';
import 'scoring_engine.dart';

/// Input keys:
///   'winnerId'    : String
///   'finishType'  : ClassicFinishType
///   'gosterge'    : bool (winner showed gösterge → +1 extra for others)
class ClassicOkeyEngine extends ScoringEngine {
  @override
  RoundScore calculate(Map<String, dynamic> input, List<Player> players) {
    final winnerId = input['winnerId'] as String;
    final finishType = input['finishType'] as ClassicFinishType;
    final gosterge = (input['gosterge'] as bool?) ?? false;

    final basePenalty = finishType.penalty;
    final deltas = <String, int>{};

    for (final p in players) {
      if (p.id == winnerId) {
        deltas[p.id] = 0;
      } else {
        deltas[p.id] = basePenalty + (gosterge ? 1 : 0);
      }
    }

    final gostergeStr = gosterge ? ' + Gösterge' : '';
    return RoundScore(
      deltas: deltas,
      winnerId: winnerId,
      label: '${finishType.label}$gostergeStr',
    );
  }
}
