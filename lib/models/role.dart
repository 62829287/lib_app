import '../core/pb.dart';

class Role {
  final String id;
  final String name;
  final String description;
  final DateTime? deletedAt;

  const Role({
    required this.id,
    required this.name,
    this.description = '',
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Role copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id: pbId(json['id']),
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    deletedAt: pbDate(json['deletedAt']),
  );
}
