import '../core/pb.dart';

class DotaHero {
  final String id;
  final String name;
  final String primaryAttribute;
  final String attackType;
  final DateTime? deletedAt;

  const DotaHero({
    required this.id,
    required this.name,
    required this.primaryAttribute,
    required this.attackType,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  DotaHero copyWith({
    String? id,
    String? name,
    String? primaryAttribute,
    String? attackType,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return DotaHero(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryAttribute: primaryAttribute ?? this.primaryAttribute,
      attackType: attackType ?? this.attackType,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'primaryAttribute': primaryAttribute,
    'attackType': attackType,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory DotaHero.fromJson(Map<String, dynamic> json) => DotaHero(
    id: pbId(json['id']),
    name: json['name'] as String? ?? '',
    primaryAttribute: json['primaryAttribute'] as String? ?? '',
    attackType: json['attackType'] as String? ?? '',
    deletedAt: pbDate(json['deletedAt']),
  );
}
