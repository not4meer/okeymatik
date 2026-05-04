import '../models/game_enums.dart';
import '../models/game_session.dart';
import '../models/player.dart';
import '../models/round.dart';
import 'scoring_engine.dart';

/// Input keys:
///   'winnerId'      : String
///   'finishType'    : Okey101FinishType
///   'playerData'    : Map<String, PlayerRoundData101>
///   'partnerId'     : String? (winner's partner, paired mode only)
class Okey101Engine extends ScoringEngine {
  @override
  RoundScore calculate(Map<String, dynamic> input, List<Player> players) {
    final winnerId = input['winnerId'] as String;
    final finishType = input['finishType'] as Okey101FinishType;
    final playerData = input['playerData'] as Map<String, PlayerRoundData101>;
    final partnerId = input['partnerId'] as String?;

    final isElden = finishType == Okey101FinishType.elden || finishType == Okey101FinishType.eldenOkey;
    final usedOkey = finishType == Okey101FinishType.okeyAtarak || finishType == Okey101FinishType.eldenOkey;

    final deltas = <String, int>{};

    // --- Winner score ---
    int winnerDelta = _silerFor(finishType);
    // Winner işlek ceza
    final winnerData = playerData[winnerId];
    if (winnerData != null && winnerData.islikCeza) {
      winnerDelta += 101;
    }
    deltas[winnerId] = winnerDelta;

    // --- Other players ---
    for (final p in players) {
      if (p.id == winnerId) continue;

      final data = playerData[p.id] ?? PlayerRoundData101();

      // Partner of winner in paired mode: normal tile penalty is wiped
      final isPartner = p.id == partnerId;

      int penalty;

      if (isElden) {
        // Elden bitme: nobody opened, fixed penalties
        penalty = usedOkey ? 808 : 404;
      } else if (isPartner) {
        // Partner's tile penalty is zero in paired mode
        penalty = 0;
      } else if (data.elAcmadi) {
        penalty = 202;
      } else {
        int tiles = data.remainingTiles;
        // Çift açan: remaining × 2
        if (data.ciftActi) tiles *= 2;
        // Okey atarak bitiş: others × 2
        if (usedOkey) tiles *= 2;
        // Elde okey taşı: +101 extra
        if (data.hasOkeyInHand) tiles += 101;
        penalty = tiles;
      }

      // Individual işlek ceza (always applies, even for partner)
      if (data.islikCeza) penalty += 101;

      deltas[p.id] = penalty;
    }

    return RoundScore(
      deltas: deltas,
      winnerId: winnerId,
      label: finishType.label,
    );
  }

  int _silerFor(Okey101FinishType type) {
    switch (type) {
      case Okey101FinishType.normal:
        return -101;
      case Okey101FinishType.okeyAtarak:
        return -202;
      case Okey101FinishType.elden:
        return -202;
      case Okey101FinishType.eldenOkey:
        return -404;
    }
  }
}

class PlayerRoundData101 {
  final int remainingTiles;
  final bool elAcmadi;   // didn't open hand
  final bool ciftActi;   // opened with pairs → remaining ×2
  final bool islikCeza;  // threw an işlek tile → +101
  final bool hasOkeyInHand; // okey tile in hand → +101 extra

  const PlayerRoundData101({
    this.remainingTiles = 0,
    this.elAcmadi = false,
    this.ciftActi = false,
    this.islikCeza = false,
    this.hasOkeyInHand = false,
  });

  PlayerRoundData101 copyWith({
    int? remainingTiles,
    bool? elAcmadi,
    bool? ciftActi,
    bool? islikCeza,
    bool? hasOkeyInHand,
  }) {
    return PlayerRoundData101(
      remainingTiles: remainingTiles ?? this.remainingTiles,
      elAcmadi: elAcmadi ?? this.elAcmadi,
      ciftActi: ciftActi ?? this.ciftActi,
      islikCeza: islikCeza ?? this.islikCeza,
      hasOkeyInHand: hasOkeyInHand ?? this.hasOkeyInHand,
    );
  }
}
