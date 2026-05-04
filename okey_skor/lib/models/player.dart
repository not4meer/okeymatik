class Player {
  final String id;
  final String name;
  final int totalScore;

  const Player({
    required this.id,
    required this.name,
    this.totalScore = 0,
  });

  Player copyWith({String? id, String? name, int? totalScore}) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      totalScore: totalScore ?? this.totalScore,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalScore': totalScore,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      );
}
