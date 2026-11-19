import '../core/pb.dart';

class Build {
  final String id;
  final String title;
  final String code;
  final String patch;
  final int difficulty;
  final String heroId;
  final List<String> proPlayerIds;
  final List<String> roleIds;
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
    String? id,
    String? title,
    String? code,
    String? patch,
    int? difficulty,
    String? heroId,
    List<String>? proPlayerIds,
    List<String>? roleIds,
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
      proPlayerIds: proPlayerIds ?? List<String>.from(this.proPlayerIds),
      roleIds: roleIds ?? List<String>.from(this.roleIds),
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
    id: pbId(json['id']),
    title: json['title'] as String? ?? '',
    code: json['code'] as String? ?? '',
    patch: json['patch'] as String? ?? '',
    difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    heroId: pbId(json['heroId']),
    proPlayerIds: pbIdList(json['proPlayerIds']),
    roleIds: pbIdList(json['roleIds']),
    picks: (json['picks'] as num?)?.toInt() ?? 0,
    wins: (json['wins'] as num?)?.toInt() ?? 0,
    deletedAt: pbDate(json['deletedAt']),
  );
}
