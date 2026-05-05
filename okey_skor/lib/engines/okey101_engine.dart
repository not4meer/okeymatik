import '../models/game_enums.dart';
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

    final deltas = <String, int>{};

    // --- Winner score ---
    int winnerDelta = _silerFor(finishType);
    final winnerData = playerData[winnerId];
    if (winnerData != null && winnerData.islikCeza) winnerDelta += 101;
    deltas[winnerId] = winnerDelta;

    // --- Other players ---
    for (final p in players) {
      if (p.id == winnerId) continue;

      final data = playerData[p.id] ?? PlayerRoundData101();
      final isPartner = p.id == partnerId;

      int penalty;

      if (isPartner) {
        penalty = 0;
      } else if (data.elAcmadi) {
        penalty = _elAcmadiPenaltyFor(finishType);
      } else {
        int tiles = data.remainingTiles;
        if (data.ciftActi) tiles *= 2; // çift açan: kendi 2 katı
        penalty = tiles * _multiplierFor(finishType);
        if (data.hasOkeyInHand) penalty += 101;
      }

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
      case Okey101FinishType.elden:
      case Okey101FinishType.ciftBitis:
        return -202;
      case Okey101FinishType.eldenOkey:
      case Okey101FinishType.ciftOkeyBitis:
        return -404;
    }
  }

  int _multiplierFor(Okey101FinishType type) {
    switch (type) {
      case Okey101FinishType.normal:
        return 1;
      case Okey101FinishType.okeyAtarak:
      case Okey101FinishType.elden:
      case Okey101FinishType.ciftBitis:
        return 2;
      case Okey101FinishType.eldenOkey:
      case Okey101FinishType.ciftOkeyBitis:
        return 4;
    }
  }

  int _elAcmadiPenaltyFor(Okey101FinishType type) {
    switch (type) {
      case Okey101FinishType.normal:
        return 202;
      case Okey101FinishType.okeyAtarak:
      case Okey101FinishType.elden:
      case Okey101FinishType.ciftBitis:
        return 404;
      case Okey101FinishType.eldenOkey:
      case Okey101FinishType.ciftOkeyBitis:
        return 808;
    }
  }
}

class PlayerRoundData101 {
  final int remainingTiles;
  final bool elAcmadi;
  final bool ciftActi;
  final bool islikCeza;
  final bool hasOkeyInHand;

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
