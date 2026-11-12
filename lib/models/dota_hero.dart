class DotaHero {
  final int id;
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
    int? id,
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
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        primaryAttribute: json['primaryAttribute'] as String? ?? '',
        attackType: json['attackType'] as String? ?? '',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse('${json['deletedAt']}'),
      );
}
