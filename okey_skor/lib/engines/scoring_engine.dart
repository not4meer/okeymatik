import '../models/round.dart';
import '../models/player.dart';

abstract class ScoringEngine {
  RoundScore calculate(Map<String, dynamic> input, List<Player> players);
}
