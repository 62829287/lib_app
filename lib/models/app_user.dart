import '../core/pb.dart';
import 'steam_profile.dart';

class AppUser {
  final String id;
  final String nickname;
  final String email;
  final String region;
  final SteamProfile steam;
  final DateTime? deletedAt;

  const AppUser({
    required this.id,
    required this.nickname,
    required this.email,
    required this.region,
    required this.steam,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get displayName => nickname;

  AppUser copyWith({
    String? id,
    String? nickname,
    String? email,
    String? region,
    SteamProfile? steam,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      region: region ?? this.region,
      steam: steam ?? this.steam,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'email': email,
    'region': region,
    'steam': steam.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: pbId(json['id']),
    nickname: json['nickname'] as String? ?? '',
    email: json['email'] as String? ?? '',
    region: json['region'] as String? ?? '',
    steam: SteamProfile.fromJson(
      json['steam'] is Map
          ? Map<String, dynamic>.from(json['steam'] as Map)
          : null,
    ),
    deletedAt: pbDate(json['deletedAt']),
  );
}
