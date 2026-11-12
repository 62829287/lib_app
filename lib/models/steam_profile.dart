class SteamProfile {
  final String url;
  final String nickname;
  final int rating;

  const SteamProfile({
    required this.url,
    required this.nickname,
    required this.rating,
  });

  SteamProfile copyWith({
    String? url,
    String? nickname,
    int? rating,
  }) {
    return SteamProfile(
      url: url ?? this.url,
      nickname: nickname ?? this.nickname,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'nickname': nickname,
        'rating': rating,
      };

  factory SteamProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SteamProfile(url: '', nickname: '', rating: 0);
    }
    return SteamProfile(
      url: json['url'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
    );
  }
}
