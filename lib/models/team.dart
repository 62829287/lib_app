import '../core/pb.dart';

class Team {
  final String id;
  final String name;
  final String tag;
  final String region;
  final String description;
  final DateTime? deletedAt;

  const Team({
    required this.id,
    required this.name,
    this.tag = '',
    this.region = '',
    this.description = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;
  String get displayName => name;

  Team copyWith({
    String? id,
    String? name,
    String? tag,
    String? region,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      region: region ?? this.region,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tag': tag,
    'region': region,
    'description': description,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: pbId(json['id']),
    name: json['name'] as String? ?? '',
    tag: json['tag'] as String? ?? '',
    region: json['region'] as String? ?? '',
    description: json['description'] as String? ?? '',
    deletedAt: pbDate(json['deletedAt']),
  );
}
