class RoundScore {
  final Map<String, int> deltas; // playerId -> score change (positive = bad)
  final String? winnerId;
  final String label;

  const RoundScore({
    required this.deltas,
    this.winnerId,
    this.label = '',
  });

  Map<String, dynamic> toJson() => {
        'deltas': deltas,
        'winnerId': winnerId,
        'label': label,
      };

  factory RoundScore.fromJson(Map<String, dynamic> json) => RoundScore(
        deltas: Map<String, int>.from(
          (json['deltas'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt())),
        ),
        winnerId: json['winnerId'] as String?,
        label: json['label'] as String? ?? '',
      );
}
