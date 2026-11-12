class ProPlayer {
  final int id;
  final String nickname;
  final String realName;
  final String team;
  final int rating;
  final String country;
  final DateTime? deletedAt;

  const ProPlayer({
    required this.id,
    required this.nickname,
    required this.realName,
    required this.team,
    required this.rating,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get displayName => nickname;

  ProPlayer copyWith({
    int? id,
    String? nickname,
    String? realName,
    String? team,
    int? rating,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return ProPlayer(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      realName: realName ?? this.realName,
      team: team ?? this.team,
      rating: rating ?? this.rating,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'realName': realName,
        'team': team,
        'rating': rating,
        'country': country,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory ProPlayer.fromJson(Map<String, dynamic> json) => ProPlayer(
        id: (json['id'] as num?)?.toInt() ?? 0,
        nickname: json['nickname'] as String? ?? '',
        realName: json['realName'] as String? ?? '',
        team: json['team'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        country: json['country'] as String? ?? '',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse('${json['deletedAt']}'),
      );
}
