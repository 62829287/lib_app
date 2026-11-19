import '../core/pb.dart';

class ProPlayer {
  final String id;
  final String nickname;
  final String realName;
  final String teamId;
  final int rating;
  final String country;
  final DateTime? deletedAt;

  const ProPlayer({
    required this.id,
    required this.nickname,
    required this.realName,
    required this.teamId,
    required this.rating,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get displayName => nickname;

  ProPlayer copyWith({
    String? id,
    String? nickname,
    String? realName,
    String? teamId,
    int? rating,
    String? country,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return ProPlayer(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      realName: realName ?? this.realName,
      teamId: teamId ?? this.teamId,
      rating: rating ?? this.rating,
      country: country ?? this.country,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'realName': realName,
    'teamId': teamId,
    'rating': rating,
    'country': country,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory ProPlayer.fromJson(Map<String, dynamic> json) => ProPlayer(
    id: pbId(json['id']),
    nickname: json['nickname'] as String? ?? '',
    realName: json['realName'] as String? ?? '',
    teamId: pbId(json['teamId']),
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    country: json['country'] as String? ?? '',
    deletedAt: pbDate(json['deletedAt']),
  );
}
