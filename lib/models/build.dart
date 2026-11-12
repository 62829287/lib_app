class Build {
  final int id;
  final String title;
  final String code;
  final String patch;
  final int difficulty;
  final int heroId;
  final List<int> proPlayerIds;
  final List<int> roleIds;
  final int picks;
  final int wins;
  final DateTime? deletedAt;

  const Build({
    required this.id,
    required this.title,
    required this.code,
    required this.patch,
    required this.difficulty,
    required this.heroId,
    required this.proPlayerIds,
    required this.roleIds,
    required this.picks,
    required this.wins,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Build copyWith({
    int? id,
    String? title,
    String? code,
    String? patch,
    int? difficulty,
    int? heroId,
    List<int>? proPlayerIds,
    List<int>? roleIds,
    int? picks,
    int? wins,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Build(
      id: id ?? this.id,
      title: title ?? this.title,
      code: code ?? this.code,
      patch: patch ?? this.patch,
      difficulty: difficulty ?? this.difficulty,
      heroId: heroId ?? this.heroId,
      proPlayerIds: proPlayerIds ?? List<int>.from(this.proPlayerIds),
      roleIds: roleIds ?? List<int>.from(this.roleIds),
      picks: picks ?? this.picks,
      wins: wins ?? this.wins,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'code': code,
        'patch': patch,
        'difficulty': difficulty,
        'heroId': heroId,
        'proPlayerIds': proPlayerIds,
        'roleIds': roleIds,
        'picks': picks,
        'wins': wins,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Build.fromJson(Map<String, dynamic> json) => Build(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        code: json['code'] as String? ?? '',
        patch: json['patch'] as String? ?? '',
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        heroId: (json['heroId'] as num?)?.toInt() ?? 0,
        proPlayerIds: _toIntList(json['proPlayerIds']),
        roleIds: _toIntList(json['roleIds']),
        picks: (json['picks'] as num?)?.toInt() ?? 0,
        wins: (json['wins'] as num?)?.toInt() ?? 0,
        deletedAt: _parseDate(json['deletedAt']),
      );
}

List<int> _toIntList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e is num ? e.toInt() : int.tryParse('$e'))
      .whereType<int>()
      .toList();
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
